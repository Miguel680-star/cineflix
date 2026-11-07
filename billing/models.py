from django.conf import settings
from django.db import models
from django.utils import timezone


class Plan(models.Model):
    """Plan de suscripción (p. ej. VIP mensual)."""

    name = models.CharField("Nombre", max_length=80)
    slug = models.SlugField("Slug", max_length=90, unique=True)
    description = models.CharField("Descripción", max_length=200, blank=True)
    price = models.DecimalField("Precio", max_digits=8, decimal_places=2)
    currency = models.CharField("Moneda", max_length=3, default="EUR")
    interval_days = models.PositiveIntegerField("Duración (días)", default=30)
    features = models.TextField(
        "Beneficios", blank=True,
        help_text="Un beneficio por línea.",
    )
    is_vip = models.BooleanField("Otorga VIP", default=True)
    is_active = models.BooleanField("Activo", default=True)
    order = models.PositiveIntegerField("Orden", default=0)
    stripe_price_id = models.CharField(
        "ID de precio en Stripe", max_length=120, blank=True,
        help_text="Opcional. Si se indica, se usa con Stripe Checkout.",
    )

    class Meta:
        verbose_name = "Plan"
        verbose_name_plural = "Planes"
        ordering = ["order", "price"]

    def __str__(self):
        return f"{self.name} ({self.price} {self.currency})"

    @property
    def feature_list(self):
        return [line.strip() for line in self.features.splitlines() if line.strip()]

    @property
    def price_display(self):
        return f"{self.price:.2f} {self.currency}"


class Subscription(models.Model):
    """Suscripción de un usuario. Si está activa, el usuario es VIP."""

    STATUS_CHOICES = [
        ("active", "Activa"),
        ("past_due", "Pago pendiente"),
        ("canceled", "Cancelada"),
        ("incomplete", "Incompleta"),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name="subscription", verbose_name="Usuario",
    )
    plan = models.ForeignKey(Plan, on_delete=models.PROTECT, verbose_name="Plan")
    status = models.CharField("Estado", max_length=20, choices=STATUS_CHOICES, default="incomplete")
    provider = models.CharField("Proveedor", max_length=20, default="demo")
    stripe_customer_id = models.CharField("Cliente Stripe", max_length=120, blank=True)
    stripe_subscription_id = models.CharField("Suscripción Stripe", max_length=120, blank=True)
    current_period_end = models.DateTimeField("Válida hasta", null=True, blank=True)
    created_at = models.DateTimeField("Creada", auto_now_add=True)
    updated_at = models.DateTimeField("Actualizada", auto_now=True)

    class Meta:
        verbose_name = "Suscripción"
        verbose_name_plural = "Suscripciones"

    def __str__(self):
        return f"{self.user} · {self.plan} · {self.get_status_display()}"

    @property
    def is_vip(self):
        """True si la suscripción está activa y dentro de su periodo."""
        if self.status != "active" or not self.plan.is_vip:
            return False
        if self.current_period_end and self.current_period_end < timezone.now():
            return False
        return True


class Payment(models.Model):
    """Registro de un intento de pago (auditoría). No guarda datos de tarjeta."""

    STATUS_CHOICES = [
        ("pending", "Pendiente"),
        ("succeeded", "Completado"),
        ("failed", "Fallido"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name="payments", verbose_name="Usuario",
    )
    plan = models.ForeignKey(Plan, on_delete=models.PROTECT, verbose_name="Plan")
    amount = models.DecimalField("Importe", max_digits=8, decimal_places=2)
    currency = models.CharField("Moneda", max_length=3, default="EUR")
    status = models.CharField("Estado", max_length=20, choices=STATUS_CHOICES, default="pending")
    provider = models.CharField("Proveedor", max_length=20, default="demo")
    provider_reference = models.CharField("Referencia", max_length=200, blank=True)
    created_at = models.DateTimeField("Fecha", auto_now_add=True)

    class Meta:
        verbose_name = "Pago"
        verbose_name_plural = "Pagos"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} · {self.amount} {self.currency} · {self.get_status_display()}"
