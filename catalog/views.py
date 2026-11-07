from django.db.models import F
from django.views.generic import DetailView, ListView

from .models import Genre, Movie


class MovieListView(ListView):
    """Página principal estilo Netflix.

    - Sin filtros: billboard destacado + filas horizontales por categoría.
    - Con búsqueda o género: cuadrícula de resultados.
    """

    model = Movie
    template_name = "catalog/movie_list.html"
    context_object_name = "movies"
    paginate_by = 12

    def get_queryset(self):
        qs = Movie.objects.filter(is_published=True).prefetch_related("genres")
        self.search = self.request.GET.get("q", "").strip()
        self.genre_slug = self.request.GET.get("genre", "").strip()
        if self.search:
            qs = qs.filter(title__icontains=self.search)
        if self.genre_slug:
            qs = qs.filter(genres__slug=self.genre_slug)
        return qs

    def _build_rows(self):
        """Construye las filas horizontales del catálogo."""
        published = Movie.objects.filter(is_published=True)
        rows = []

        trending = published.order_by("-views")[:12]
        if trending:
            rows.append({"title": "Tendencias ahora", "movies": trending})

        featured = published.filter(is_featured=True)
        if featured:
            rows.append({"title": "Destacadas en CineFlix", "movies": featured})

        recientes = published.order_by("-created_at")[:12]
        if recientes:
            rows.append({"title": "Añadidas recientemente", "movies": recientes})

        for genre in Genre.objects.all():
            items = published.filter(genres=genre)[:12]
            if items:
                rows.append({"title": genre.name, "movies": items})
        return rows

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["genres"] = Genre.objects.all()
        ctx["search"] = self.search
        ctx["active_genre"] = self.genre_slug
        ctx["is_browse"] = not self.search and not self.genre_slug

        if ctx["is_browse"]:
            published = Movie.objects.filter(is_published=True)
            ctx["billboard"] = (
                published.filter(is_featured=True).first() or published.first()
            )
            ctx["rows"] = self._build_rows()
        return ctx


class MovieDetailView(DetailView):
    """Ficha de película con reproductor, estilo Netflix."""

    model = Movie
    template_name = "catalog/movie_detail.html"
    context_object_name = "movie"
    slug_field = "slug"

    def get_queryset(self):
        return Movie.objects.filter(is_published=True).prefetch_related("genres")

    def get_object(self, queryset=None):
        movie = super().get_object(queryset)
        Movie.objects.filter(pk=movie.pk).update(views=F("views") + 1)
        movie.refresh_from_db()
        return movie

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        related = (
            Movie.objects.filter(is_published=True, genres__in=self.object.genres.all())
            .exclude(pk=self.object.pk)
            .distinct()[:12]
        )
        ctx["related"] = related
        ctx["related_rows"] = [{"title": "Títulos similares", "movies": related}] if related else []
        return ctx
