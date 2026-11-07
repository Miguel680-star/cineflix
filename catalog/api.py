from rest_framework import filters, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from django.db.models import F

from .models import Genre, Movie
from .serializers import GenreSerializer, MovieSerializer


class GenreViewSet(viewsets.ReadOnlyModelViewSet):
    """Lista y detalle de géneros. `/api/genres/`"""

    queryset = Genre.objects.all()
    serializer_class = GenreSerializer
    lookup_field = "slug"


class MovieViewSet(viewsets.ReadOnlyModelViewSet):
    """Catálogo de películas publicadas. `/api/movies/`

    Filtros: `?genre=<slug>`, `?featured=1`, `?search=<texto>`
    """

    serializer_class = MovieSerializer
    lookup_field = "slug"
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["title", "synopsis"]
    ordering_fields = ["created_at", "release_year", "rating", "views"]

    def get_queryset(self):
        qs = Movie.objects.filter(is_published=True).prefetch_related("genres")
        genre = self.request.query_params.get("genre")
        if genre:
            qs = qs.filter(genres__slug=genre)
        featured = self.request.query_params.get("featured")
        if featured in ("1", "true", "True"):
            qs = qs.filter(is_featured=True)
        return qs

    @action(detail=True, methods=["post"])
    def play(self, request, slug=None):
        """Registra una reproducción y devuelve la fuente de video."""
        movie = self.get_object()
        Movie.objects.filter(pk=movie.pk).update(views=F("views") + 1)
        movie.refresh_from_db()
        serializer = self.get_serializer(movie)
        return Response(serializer.data)
