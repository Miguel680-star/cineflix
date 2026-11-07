from django.conf import settings
from django.middleware.csrf import CsrfViewMiddleware


class DevCsrfMiddleware(CsrfViewMiddleware):
    """Acepta cualquier Origin cuando DEBUG está activo.

    Cuando se accede a la app a través del proxy de la vista previa del
    editor, el navegador envía una cabecera Origin distinta a la que ve
    Django, y Django rechazaría los formularios (login, pago, etc.) con
    un error 403. En desarrollo permitimos cualquier origen; en producción
    (DEBUG=False) se mantiene la comprobación estricta normal.
    """

    def _origin_verified(self, request):
        if settings.DEBUG:
            return True
        return super()._origin_verified(request)
