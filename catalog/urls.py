from django.urls import path

from . import views

app_name = "catalog"

urlpatterns = [
    path("", views.MovieListView.as_view(), name="movie_list"),
    path("pelicula/<slug:slug>/", views.MovieDetailView.as_view(), name="movie_detail"),
]
