"""Lógica de pagos de CineFlix.

- Si hay claves de Stripe configuradas → se usa Stripe Checkout (pago real,
  con el formulario de tarjeta alojado por Stripe; nunca tocamos los datos
  de la tarjeta).
- Si no → MODO DEMO: se simula el pago para poder probar el flujo.
"""

from datetime import timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.utils import timezone

from .models import Payment, Plan, Subscription


def stripe_enabled():
    """True si hay claves de Stripe configuradas (pagos reales)."""
    return bool(settings.STRIPE_SECRET_KEY)


def activate_subscription(user, plan, provider, reference="", customer_id="", amount=None):
    """Activa (o extiende) la suscripción VIP del usuario y registra el pago."""
    sub, _ = Subscription.objects.get_or_create(user=user, defaults={"plan": plan})
    sub.plan = plan
    sub.status = "active"
    sub.provider = provider
    if customer_id:
        sub.stripe_customer_id = customer_id

    start = timezone.now()
    if sub.current_period_end and sub.current_period_end > start:
        start = sub.current_period_end  # renovación: extiende el periodo
    sub.current_period_end = start + timedelta(days=plan.interval_days)
    sub.save()

    Payment.objects.create(
        user=user,
        plan=plan,
        amount=amount if amount is not None else plan.price,
        currency=plan.currency,
        status="succeeded",
        provider=provider,
        provider_reference=reference,
    )
    return sub


def create_checkout_url(request, plan):
    """Devuelve la URL de pago a la que redirigir al usuario."""
    if stripe_enabled():
        import stripe

        stripe.api_key = settings.STRIPE_SECRET_KEY
        success_url = request.build_absolute_uri(reverse("billing:success")) + "?session_id={CHECKOUT_SESSION_ID}"
        cancel_url = request.build_absolute_uri(reverse("billing:cancel"))
        session = stripe.checkout.Session.create(
            mode="payment",
            payment_method_types=["card"],
            line_items=[
                {
                    "price_data": {
                        "currency": plan.currency.lower(),
                        "unit_amount": int(plan.price * 100),
                        "product_data": {"name": f"{plan.name} — CineFlix"},
                    },
                    "quantity": 1,
                }
            ],
            success_url=success_url,
            cancel_url=cancel_url,
            customer_email=request.user.email or None,
            metadata={"user_id": request.user.id, "plan_id": plan.id},
        )
        return session.url, "stripe", session.id

    # Modo demo: formulario de pago simulado en nuestra propia página.
    return reverse("billing:demo_checkout", args=[plan.slug]), "demo", ""


def fulfill_stripe_session(session_id):
    """Marca la suscripción como activa tras un pago correcto en Stripe."""
    import stripe

    stripe.api_key = settings.STRIPE_SECRET_KEY
    session = stripe.checkout.Session.retrieve(session_id)
    if session.payment_status != "paid":
        return None, "El pago aún no se ha completado."

    # Evita duplicar la suscripción si el usuario recarga la página.
    if Payment.objects.filter(
        provider="stripe", provider_reference=session.id, status="succeeded"
    ).exists():
        return Subscription.objects.filter(user_id=session.metadata["user_id"]).first(), None

    user = get_user_model().objects.filter(pk=session.metadata["user_id"]).first()
    plan = Plan.objects.filter(pk=session.metadata["plan_id"]).first()
    if not user or not plan:
        return None, "No se pudo identificar el usuario o el plan."

    sub = activate_subscription(
        user, plan, "stripe",
        reference=session.id,
        customer_id=session.customer or "",
        amount=(session.amount_total or 0) / 100,
    )
    return sub, None
