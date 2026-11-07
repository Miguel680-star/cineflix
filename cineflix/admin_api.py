"""API de administración para la app nativa (iOS/Android).

Todos los endpoints viven bajo `/api/admin/` y requieren un usuario *staff*.
La app móvil se autentica con un token:

    POST /api/admin/login/   {username, password}  ->  {token, user}

y luego envía la cabecera `Authorization: Token <token>` en cada petición.
"""

from django.contrib.auth import authenticate
from django.db.models import Q, Sum
from django.utils import timezone
from rest_framework import filters, serializers, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response
from rest_framework.routers import DefaultRouter
from rest_framework.views import APIView

from billing.models import Payment, Plan, Subscription
from catalog.models import Genre, Movie


# --------------------------------------------------------------------------
# Serializers
# --------------------------------------------------------------------------
class AdminGenreSerializer(serializers.ModelSerializer):
    movie_count = serializers.SerializerMethodField()

    class Meta:
        model = Genre
        fields = ["id", "name", "slug", "movie_count"]
        read_only_fields = ["slug"]

    def get_movie_count(self, obj):
        return obj.movies.count()


class AdminMovieSerializer(serializers.ModelSerializer):
    genres = serializers.PrimaryKeyRelatedField(
        queryset=Genre.objects.all(), many=True, required=False
    )
    genre_names = serializers.SerializerMethodField()
    poster_url = serializers.SerializerMethodField()
    backdrop_url = serializers.SerializerMethodField()
    video_source = serializers.SerializerMethodField()

    class Meta:
        model = Movie
        fields = [
            "id", "title", "slug", "synopsis",
            "poster", "poster_url", "backdrop", "backdrop_url",
            "release_year", "duration_minutes", "rating",
            "genres", "genre_names",
            "video_file", "video_url", "video_source",
            "is_published", "is_featured", "views",
            "created_at", "updated_at",
        ]
        read_only_fields = ["slug", "views", "created_at", "updated_at"]

    def get_genre_names(self, obj):
        return [g.name for g in obj.genres.all()]

    def _absolute(self, obj, field):
        image = getattr(obj, field)
        if not image:
            return None
        request = self.context.get("request")
        return request.build_absolute_uri(image.url) if request else image.url

    def get_poster_url(self, obj):
        return self._absolute(obj, "poster")

    def get_backdrop_url(self, obj):
        return self._absolute(obj, "backdrop")

    def get_video_source(self, obj):
        source = obj.video_source
        if not source:
            return None
        request = self.context.get("request")
        if request and source.startswith("/"):
            return request.build_absolute_uri(source)
        return source


class AdminPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = Plan
        fields = [
            "id", "name", "slug", "description", "price", "currency",
            "interval_days", "features", "is_vip", "is_active", "order",
            "stripe_price_id",
        ]
        read_only_fields = ["slug"]


class AdminSubscriptionSerializer(serializers.ModelSerializer):
    user_email = serializers.SerializerMethodField()
    plan_name = serializers.CharField(source="plan.name", read_only=True)
    is_vip = serializers.BooleanField(read_only=True)

    class Meta:
        model = Subscription
        fields = [
            "id", "user", "user_email", "plan", "plan_name", "status",
            "provider", "current_period_end", "is_vip", "created_at", "updated_at",
        ]

    def get_user_email(self, obj):
        return obj.user.email or obj.user.username


class AdminPaymentSerializer(serializers.ModelSerializer):
    user_email = serializers.SerializerMethodField()
    plan_name = serializers.CharField(source="plan.name", read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id", "user", "user_email", "plan", "plan_name", "amount",
            "currency", "status", "provider", "provider_reference", "created_at",
        ]

    def get_user_email(self, obj):
        return obj.user.email or obj.user.username


# --------------------------------------------------------------------------
# Login
# --------------------------------------------------------------------------
class AdminLoginView(APIView):
    """Devuelve un token para un usuario staff. `POST /api/admin/login/`"""

    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        username = request.data.get("username", "")
        password = request.data.get("password", "")
        user = authenticate(request, username=username, password=password)
        if user is None or not user.is_staff:
            return Response(
                {"detail": "Usuario o contraseña incorrectos, o sin permisos de administración."},
                status=400,
            )
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            "token": token.key,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_superuser": user.is_superuser,
            },
        })


# --------------------------------------------------------------------------
# Estadísticas del panel
# --------------------------------------------------------------------------
class AdminStatsView(APIView):
    """Resumen para la pantalla de inicio de la app. `GET /api/admin/stats/`"""

    permission_classes = [IsAdminUser]

    def get(self, request):
        now = timezone.now()

        active_subs = Subscription.objects.filter(status="active", plan__is_vip=True).filter(
            Q(current_period_end__isnull=True) | Q(current_period_end__gte=now)
        )
        paid = Payment.objects.filter(status="succeeded")
        total_income = paid.aggregate(total=Sum("amount"))["total"] or 0

        recent = Payment.objects.select_related("user", "plan")[:8]

        return Response({
            "movies_total": Movie.objects.count(),
            "movies_published": Movie.objects.filter(is_published=True).count(),
            "genres_total": Genre.objects.count(),
            "plans_total": Plan.objects.filter(is_active=True).count(),
            "subscriptions_total": Subscription.objects.count(),
            "vip_active": active_subs.count(),
            "payments_count": paid.count(),
            "income_total": float(total_income),
            "currency": Plan.objects.first().currency if Plan.objects.exists() else "EUR",
            "recent_payments": AdminPaymentSerializer(recent, many=True, context={"request": request}).data,
        })


# --------------------------------------------------------------------------
# ViewSets (CRUD)
# --------------------------------------------------------------------------
class AdminGenreViewSet(viewsets.ModelViewSet):
    queryset = Genre.objects.all()
    serializer_class = AdminGenreSerializer
    permission_classes = [IsAdminUser]


class AdminMovieViewSet(viewsets.ModelViewSet):
    queryset = Movie.objects.all().prefetch_related("genres").order_by("-created_at")
    serializer_class = AdminMovieSerializer
    permission_classes = [IsAdminUser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["title", "synopsis"]
    ordering_fields = ["created_at", "title", "views"]


class AdminPlanViewSet(viewsets.ModelViewSet):
    queryset = Plan.objects.all()
    serializer_class = AdminPlanSerializer
    permission_classes = [IsAdminUser]


class AdminSubscriptionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Subscription.objects.select_related("user", "plan")
    serializer_class = AdminSubscriptionSerializer
    permission_classes = [IsAdminUser]


class AdminPaymentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Payment.objects.select_related("user", "plan").order_by("-created_at")
    serializer_class = AdminPaymentSerializer
    permission_classes = [IsAdminUser]


router = DefaultRouter()
router.register("genres", AdminGenreViewSet, basename="admin-genre")
router.register("movies", AdminMovieViewSet, basename="admin-movie")
router.register("plans", AdminPlanViewSet, basename="admin-plan")
router.register("subscriptions", AdminSubscriptionViewSet, basename="admin-subscription")
router.register("payments", AdminPaymentViewSet, basename="admin-payment")
