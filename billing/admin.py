from django.contrib import admin
from django.db.models import Count, Sum

from .models import Payment, Plan, Subscription


@admin.register(Plan)
class PlanAdmin(admin.ModelAdmin):
    list_display = ("name", "price", "currency", "interval_days", "is_vip", "is_active", "order")
    list_editable = ("price", "is_vip", "is_active", "order")
    prepopulated_fields = {"slug": ("name",)}
    search_fields = ("name",)


@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "plan", "status", "provider", "is_vip", "current_period_end", "created_at")
    list_filter = ("status", "provider", "plan")
    search_fields = ("user__username", "user__email", "stripe_customer_id", "stripe_subscription_id")
    readonly_fields = ("created_at", "updated_at", "stripe_customer_id", "stripe_subscription_id")

    @admin.display(boolean=True, description="VIP")
    def is_vip(self, obj):
        return obj.is_vip


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ("user", "plan", "amount", "currency", "status", "provider", "created_at")
    list_filter = ("status", "provider", "currency")
    search_fields = ("user__username", "provider_reference")
    readonly_fields = ("created_at",)
    change_list_template = "admin/billing/payment/change_list.html"

    def changelist_view(self, request, extra_context=None):
        """Añade el total de ingresos (pagos completados) al encabezado."""
        succeeded = self.get_queryset(request).filter(status="succeeded")
        totals = succeeded.aggregate(total=Sum("amount"), n=Count("id"))
        extra_context = extra_context or {}
        extra_context["revenue_total"] = totals["total"] or 0
        extra_context["revenue_count"] = totals["n"] or 0
        return super().changelist_view(request, extra_context=extra_context)
