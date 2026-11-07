from django.contrib import admin
from django.utils.html import format_html

from .models import Genre, Movie


# Branding del panel de administración
admin.site.site_header = "CineFlix · Administración"
admin.site.site_title = "CineFlix Admin"
admin.site.index_title = "Panel de control"


@admin.register(Genre)
class GenreAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "movie_count")
    search_fields = ("name",)
    prepopulated_fields = {"slug": ("name",)}

    @admin.display(description="Películas")
    def movie_count(self, obj):
        return obj.movies.count()


@admin.register(Movie)
class MovieAdmin(admin.ModelAdmin):
    list_display = ("poster_tag", "title", "release_year", "rating", "is_featured", "is_published", "views")
    list_display_links = ("title",)
    list_filter = ("is_published", "is_featured", "genres", "release_year")
    search_fields = ("title", "synopsis")
    prepopulated_fields = {"slug": ("title",)}
    filter_horizontal = ("genres",)
    date_hierarchy = "created_at"
    list_editable = ("is_featured", "is_published")
    list_per_page = 20
    actions = ("mark_published", "mark_unpublished")

    fieldsets = (
        ("Información principal", {
            "fields": ("title", "slug", "synopsis", "genres"),
        }),
        ("Detalles", {
            "fields": ("release_year", "duration_minutes", "rating"),
        }),
        ("Imágenes", {
            "fields": ("poster", "backdrop"),
        }),
        ("Fuente de video", {
            "fields": ("video_file", "video_url"),
            "description": "Sube un archivo o indica una URL. Solo contenido con derechos.",
        }),
        ("Estado", {
            "fields": ("is_published", "is_featured", "views"),
        }),
    )

    @admin.display(description="Portada")
    def poster_tag(self, obj):
        if obj.poster:
            return format_html(
                '<img src="{}" style="height:60px;border-radius:6px;" />', obj.poster.url
            )
        return "—"

    @admin.action(description="Publicar películas seleccionadas")
    def mark_published(self, request, queryset):
        updated = queryset.update(is_published=True)
        self.message_user(request, f"{updated} película(s) publicada(s).")

    @admin.action(description="Despublicar películas seleccionadas")
    def mark_unpublished(self, request, queryset):
        updated = queryset.update(is_published=False)
        self.message_user(request, f"{updated} película(s) despublicada(s).")
