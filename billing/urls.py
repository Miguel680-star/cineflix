from django.urls import path

from . import views

app_name = "billing"

urlpatterns = [
    path("vip/", views.plan_list, name="plans"),
    path("vip/pagar/<slug:slug>/", views.checkout, name="checkout"),
    path("vip/demo/<slug:slug>/", views.demo_checkout, name="demo_checkout"),
    path("vip/exito/", views.success, name="success"),
    path("vip/cancelado/", views.cancel, name="cancel"),
    path("vip/cuenta/", views.account, name="account"),
    path("vip/webhook/", views.stripe_webhook, name="webhook"),
]
