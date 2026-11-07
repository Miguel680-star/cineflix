from django.contrib.auth import login
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.views import LoginView
from django.shortcuts import redirect, render
from django.urls import reverse


class CineFlixLoginView(LoginView):
    """Login del sitio: el personal va al panel y los usuarios al catálogo."""

    template_name = "registration/login.html"
    redirect_authenticated_user = True

    def get_success_url(self):
        # Respeta el parámetro ?next=... si viene de una página protegida.
        url = self.get_redirect_url()
        if url:
            return url
        if self.request.user.is_staff:
            return reverse("admin:index")
        return reverse("catalog:movie_list")


def register(request):
    """Registro de nuevos usuarios."""
    if request.user.is_authenticated:
        return redirect("catalog:movie_list")

    if request.method == "POST":
        form = UserCreationForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user)
            return redirect("billing:plans")
    else:
        form = UserCreationForm()

    return render(request, "accounts/register.html", {"form": form})
