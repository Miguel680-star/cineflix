"""Crea los planes VIP de ejemplo.

Uso:  python manage.py seed_plans
"""

from decimal import Decimal

from django.core.management.base import BaseCommand

from billing.models import Plan

FEATURES = [
    "Sin anuncios",
    "Calidad hasta 4K Ultra HD",
    "Descargas para ver sin conexión",
    "Reproducción en 4 dispositivos",
    "Estrenos exclusivos",
]

PLANS = [
    {
        "name": "VIP Mensual", "slug": "vip-mensual",
        "description": "Acceso VIP durante 30 días.",
        "price": Decimal("9.99"), "interval_days": 30, "order": 0,
    },
    {
        "name": "VIP Trimestral", "slug": "vip-trimestral",
        "description": "Ahorra un 16% con el plan de 90 días.",
        "price": Decimal("24.99"), "interval_days": 90, "order": 1,
    },
    {
        "name": "VIP Anual", "slug": "vip-anual",
        "description": "El mejor precio: 365 días de VIP.",
        "price": Decimal("79.99"), "interval_days": 365, "order": 2,
    },
]


class Command(BaseCommand):
    help = "Crea los planes VIP de ejemplo."

    def handle(self, *args, **options):
        created = 0
        for data in PLANS:
            plan, was_created = Plan.objects.update_or_create(
                slug=data["slug"],
                defaults={
                    "name": data["name"],
                    "description": data["description"],
                    "price": data["price"],
                    "currency": "EUR",
                    "interval_days": data["interval_days"],
                    "order": data["order"],
                    "is_vip": True,
                    "is_active": True,
                    "features": "\n".join(FEATURES),
                },
            )
            created += 1 if was_created else 0
            self.stdout.write(f"  · {plan.name} — {plan.price_display} / {plan.interval_days} días")

        self.stdout.write(self.style.SUCCESS(f"Planes listos ({created} nuevos)."))
