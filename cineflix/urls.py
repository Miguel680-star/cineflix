"""URLs principales del proyecto CineFlix."""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path, re_path
from django.views.static import serve
from rest_framework.routers import DefaultRouter

from catalog.api import GenreViewSet, MovieViewSet
from accounts.views import CineFlixLoginView
from cineflix.admin_api import AdminLoginView, AdminStatsView
from cineflix.admin_api import router as admin_router

# API REST (consumida por la web y la app móvil)
router = DefaultRouter()
router.register("movies", MovieViewSet, basename="movie")
router.register("genres", GenreViewSet, basename="genre")

urlpatterns = [
    path("admin/", admin.site.urls),
    # API de administración (app nativa)
    path("api/admin/login/", AdminLoginView.as_view(), name="admin-api-login"),
    path("api/admin/stats/", AdminStatsView.as_view(), name="admin-api-stats"),
    path("api/admin/", include(admin_router.urls)),
    path("api/", include(router.urls)),
    path("api-auth/", include("rest_framework.urls")),
    path("cuentas/", include("accounts.urls")),
    path("cuentas/login/", CineFlixLoginView.as_view(), name="login"),
    path("cuentas/", include("django.contrib.auth.urls")),
    path("", include("billing.urls")),
    path("", include("catalog.urls")),
]

# Archivos subidos (portadas y vídeos): se sirven siempre, ya que en el
# hosting gratuito no hay un CDN. Los estáticos los sirve WhiteNoise.
urlpatterns += [
    re_path(r"^media/(?P<path>.*)$", serve, {"document_root": settings.MEDIA_ROOT}),
]

# En desarrollo también se sirven los estáticos desde Django.
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
