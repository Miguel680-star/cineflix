"""Siembra el catálogo con contenido de ejemplo de licencia abierta.

Los videos son las demos abiertas de la Blender Foundation / Google
(Creative Commons), por lo que su uso y distribución es legal.

Uso:  python manage.py seed_demo
"""

from django.core.management.base import BaseCommand

from catalog.models import Genre, Movie

GENRES = ["Animación", "Ciencia ficción", "Fantasía", "Acción", "Cortometraje"]

# (titulo, sinopsis, anio, duracion, rating, generos, url_video)
MOVIES = [
    (
        "Big Buck Bunny",
        "Un conejo bonachón trama su venganza contra tres roedores que lo atormentaban. "
        "Cortometraje de animación de código abierto de la Blender Foundation.",
        2008, 10, 8.2, ["Animación", "Cortometraje"],
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    ),
    (
        "Elephants Dream",
        "Dos personajes exploran un mundo mecánico surrealista. Primera película de código "
        "abierto producida con software libre por la Blender Foundation.",
        2006, 11, 7.5, ["Animación", "Ciencia ficción"],
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    ),
    (
        "Sintel",
        "Una joven guerrera cruza tierras hostiles en busca de un dragón al que crió. "
        "Cortometraje épico de fantasía de código abierto.",
        2010, 15, 8.8, ["Animación", "Fantasía", "Cortometraje"],
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    ),
    (
        "Tears of Steel",
        "Un futuro donde la humanidad convive con robots. Cortometraje de ciencia ficción "
        "con efectos visuales creados con herramientas abiertas.",
        2012, 12, 7.9, ["Ciencia ficción", "Acción", "Cortometraje"],
        "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
    ),
]


class Command(BaseCommand):
    help = "Crea géneros y películas de ejemplo (contenido de licencia abierta)."

    def handle(self, *args, **options):
        for name in GENRES:
            Genre.objects.get_or_create(name=name)
        self.stdout.write(self.style.SUCCESS(f"Géneros listos: {len(GENRES)}"))

        created = 0
        for title, synopsis, year, duration, rating, genres, url in MOVIES:
            movie, was_created = Movie.objects.get_or_create(
                title=title,
                defaults={
                    "synopsis": synopsis,
                    "release_year": year,
                    "duration_minutes": duration,
                    "rating": rating,
                    "video_url": url,
                    "is_featured": title == "Sintel",
                },
            )
            if was_created:
                movie.genres.set(Genre.objects.filter(name__in=genres))
                created += 1
        self.stdout.write(self.style.SUCCESS(f"Películas creadas: {created}"))
