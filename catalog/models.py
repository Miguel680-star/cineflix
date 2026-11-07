from django.db import models
from django.urls import reverse
from django.utils.text import slugify


def unique_slug(instance, value, slug_field="slug"):
    """Genera un slug único para el modelo dado."""
    base = slugify(value) or "item"
    slug = base
    model = instance.__class__
    counter = 1
    while model.objects.filter(**{slug_field: slug}).exclude(pk=instance.pk).exists():
        counter += 1
        slug = f"{base}-{counter}"
    return slug


class Genre(models.Model):
    """Género o categoría de película."""

    name = models.CharField("Nombre", max_length=60, unique=True)
    slug = models.SlugField("Slug", max_length=70, unique=True, blank=True)

    class Meta:
        verbose_name = "Género"
        verbose_name_plural = "Géneros"
        ordering = ["name"]

    def __str__(self):
        return self.name

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = unique_slug(self, self.name)
        super().save(*args, **kwargs)


class Movie(models.Model):
    """Película del catálogo.

    El contenido se gestiona desde el panel de administración. Solo debe
    publicarse contenido con derechos (dominio público, Creative Commons,
    propio o licenciado).
    """

    title = models.CharField("Título", max_length=200)
    slug = models.SlugField("Slug", max_length=220, unique=True, blank=True)
    synopsis = models.TextField("Sinopsis", blank=True)
    poster = models.ImageField("Portada", upload_to="posters/", blank=True)
    backdrop = models.ImageField("Imagen de fondo", upload_to="backdrops/", blank=True)
    release_year = models.PositiveIntegerField("Año", null=True, blank=True)
    duration_minutes = models.PositiveIntegerField("Duración (min)", null=True, blank=True)
    rating = models.DecimalField(
        "Puntuación", max_digits=3, decimal_places=1, null=True, blank=True,
        help_text="De 0.0 a 10.0",
    )
    genres = models.ManyToManyField(Genre, verbose_name="Géneros", related_name="movies", blank=True)

    # Fuente del video: se puede usar un archivo subido o una URL externa.
    video_file = models.FileField("Archivo de video", upload_to="videos/", blank=True)
    video_url = models.URLField(
        "URL del video", blank=True,
        help_text="Enlace directo a un .mp4/.webm o a un reproductor embebible.",
    )

    is_published = models.BooleanField("Publicada", default=True)
    is_featured = models.BooleanField("Destacada", default=False)
    views = models.PositiveIntegerField("Reproducciones", default=0)

    created_at = models.DateTimeField("Creada", auto_now_add=True)
    updated_at = models.DateTimeField("Actualizada", auto_now=True)

    class Meta:
        verbose_name = "Película"
        verbose_name_plural = "Películas"
        ordering = ["-created_at"]

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = unique_slug(self, self.title)
        super().save(*args, **kwargs)

    def get_absolute_url(self):
        return reverse("catalog:movie_detail", args=[self.slug])

    @property
    def video_source(self):
        """Devuelve el mejor origen de video disponible (archivo o URL)."""
        if self.video_file:
            return self.video_file.url
        return self.video_url

    @property
    def is_direct_video(self):
        """True si la fuente es un archivo de video reproducible con <video>."""
        if self.video_file:
            return True
        source = (self.video_url or "").lower()
        return source.endswith((".mp4", ".webm", ".ogg", ".ogv", ".m4v", ".mov"))
