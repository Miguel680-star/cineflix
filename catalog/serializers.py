from rest_framework import serializers

from .models import Genre, Movie


class GenreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Genre
        fields = ["id", "name", "slug"]


class MovieSerializer(serializers.ModelSerializer):
    genres = GenreSerializer(many=True, read_only=True)
    poster_url = serializers.SerializerMethodField()
    backdrop_url = serializers.SerializerMethodField()
    video_source = serializers.SerializerMethodField()

    class Meta:
        model = Movie
        fields = [
            "id", "title", "slug", "synopsis",
            "poster_url", "backdrop_url",
            "release_year", "duration_minutes", "rating",
            "genres", "video_source", "views", "is_featured", "created_at",
        ]

    def _absolute(self, obj, field):
        image = getattr(obj, field)
        if not image:
            return None
        request = self.context.get("request")
        url = image.url
        return request.build_absolute_uri(url) if request else url

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
