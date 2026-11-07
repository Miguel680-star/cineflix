from django.conf import settings
from django.contrib import messages
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, redirect, render

from .models import Payment, Plan
from .services import (
    activate_subscription,
    create_checkout_url,
    fulfill_stripe_session,
    stripe_enabled,
)


def plan_list(request):
    """Página de planes VIP con precios y beneficios."""
    plans = list(Plan.objects.filter(is_active=True))
    current = None
    if request.user.is_authenticated:
        current = getattr(request.user, "subscription", None)
    featured = max(plans, key=lambda p: p.price, default=None)
    return render(request, "billing/plans.html", {
        "plans": plans,
        "current": current,
        "featured_id": featured.id if featured else None,
        "demo_mode": not stripe_enabled(),
    })


@login_required
def checkout(request, slug):
    """Inicia el pago: redirige a Stripe (real) o al formulario demo."""
    plan = get_object_or_404(Plan, slug=slug, is_active=True)
    url, _provider, _ref = create_checkout_url(request, plan)
    return redirect(url)


@login_required
def demo_checkout(request, slug):
    """Formulario de pago SIMULADO (modo demo, sin cobros reales)."""
    if stripe_enabled():
        return redirect("billing:checkout", slug=slug)

    plan = get_object_or_404(Plan, slug=slug, is_active=True)

    if request.method == "POST":
        activate_subscription(request.user, plan, "demo", reference="DEMO-" + plan.slug.upper())
        messages.success(request, "¡Pago simulado correctamente! Ya eres VIP.")
        return redirect("billing:success")

    return render(request, "billing/demo_checkout.html", {"plan": plan})


@login_required
def success(request):
    """Página de éxito. Si venimos de Stripe, activa la suscripción."""
    session_id = request.GET.get("session_id")
    error = None
    if session_id and stripe_enabled():
        _sub, error = fulfill_stripe_session(session_id)

    return render(request, "billing/success.html", {
        "error": error,
        "subscription": getattr(request.user, "subscription", None),
    })


def cancel(request):
    """El usuario canceló el pago."""
    return render(request, "billing/cancel.html")


@login_required
def account(request):
    """Área de cuenta: estado VIP e historial de pagos."""
    subscription = getattr(request.user, "subscription", None)
    payments = Payment.objects.filter(user=request.user)
    return render(request, "billing/account.html", {
        "subscription": subscription,
        "payments": payments,
    })


def stripe_webhook(request):
    """Recibe eventos de Stripe (requiere STRIPE_WEBHOOK_SECRET)."""
    import stripe

    if not stripe_enabled() or not settings.STRIPE_WEBHOOK_SECRET:
        return HttpResponse(status=400)

    payload = request.body
    sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")
    try:
        event = stripe.Webhook.construct_event(payload, sig_header, settings.STRIPE_WEBHOOK_SECRET)
    except (ValueError, stripe.error.SignatureVerificationError):
        return HttpResponse(status=400)

    if event["type"] == "checkout.session.completed":
        session = event["data"]["object"]
        if session.get("payment_status") == "paid":
            fulfill_stripe_session(session["id"])

    return HttpResponse(status=200)
