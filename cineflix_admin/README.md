# CineFlix Admin

App móvil de **administración** de la plataforma de streaming **CineFlix**,
desarrollada en Flutter. Consume la API REST del backend Django (`/api/admin/...`).

## Funcionalidades

- **Inicio**: tarjetas de estadísticas (películas, VIP activos, suscripciones,
  ingresos y pagos) y listado de pagos recientes.
- **Películas**: buscador, listado con miniatura, estado publicado/destacado,
  creación, edición y borrado (deslizando con confirmación).
- **Planes**: creación, edición, activación/desactivación de planes.
- **Pagos**: listado paginado con total acumulado.
- **Cuenta**: datos del usuario, acceso a suscripciones y cierre de sesión.

> Este repositorio contiene **solo código fuente**. Las carpetas de plataforma
> (`ios/`, `android/`, `web/`, ...) se generan con `flutter create .`.

## Requisitos

1. Instalar el **Flutter SDK**: <https://docs.flutter.dev/get-started/install>
2. Tener configurado el entorno de la plataforma objetivo (Xcode para iOS,
   Android Studio / SDK para Android).

## Puesta en marcha

```bash
# 1. Entra en la carpeta del proyecto
cd cineflix_admin

# 2. Genera las carpetas de plataforma (iOS, Android, web, etc.)
flutter create .

# 3. Descarga las dependencias
flutter pub get
```

### Configurar la URL del backend

Edita `lib/config.dart` y cambia la constante `apiBaseUrl` por la IP o el
dominio de tu servidor:

```dart
// Emulador Android contra tu máquina local:
const String apiBaseUrl = 'http://10.0.2.2:8000';

// Dispositivo físico en tu red local:
const String apiBaseUrl = 'http://192.168.1.100:8000';

// Producción:
const String apiBaseUrl = 'https://api.cineflix.com';
```

### Ejecutar en un dispositivo o emulador

```bash
flutter run
```

Inicia sesión con las credenciales de un usuario administrador del backend.
La autenticación usa token: tras el login se guarda en el dispositivo y se
envía en cada petición con la cabecera `Authorization: Token <token>`.

## Compilar el `.ipa` para iPhone

Requiere un **Mac con Xcode** y una **cuenta de Apple Developer**.

```bash
flutter build ipa --release
```

El archivo resultante queda en:

```
build/ios/ipa/*.ipa
```

**Alternativa con Xcode:** abre `ios/Runner.xcworkspace` y usa
**Product > Archive**.

> La firma de iOS (certificados y perfiles de aprovisionamiento) se gestiona en
> Xcode, en la pestaña **Signing & Capabilities** del target `Runner`. Selecciona
> ahí tu equipo (Team), el bundle identifier y deja que Xcode gestione la firma
> automática si lo prefieres.

## Compilar para Android

```bash
flutter build apk --release
```

El archivo resultante queda en:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Estructura del proyecto

```
lib/
├── config.dart                 # URL base de la API y paleta de colores
├── models.dart                 # Modelos (AdminUser, Stats, Movie, Genre, Plan, ...)
├── api_client.dart             # Cliente HTTP y gestión de token
├── main.dart                   # Arranque y tema (estética Netflix)
├── widgets/
│   └── stat_card.dart          # Tarjeta de estadística reutilizable
└── screens/
    ├── login_screen.dart       # Inicio de sesión
    ├── home_screen.dart        # Navegación inferior (5 pestañas)
    ├── dashboard_screen.dart   # Estadísticas y pagos recientes
    ├── movies_screen.dart      # Listado de películas
    ├── movie_form_screen.dart  # Alta/edición de película
    ├── plans_screen.dart       # Gestión de planes
    ├── payments_screen.dart    # Listado de pagos
    ├── subscriptions_screen.dart # Listado de suscripciones
    └── account_screen.dart     # Cuenta y cierre de sesión
```

## Notas sobre la subida de archivos

El formulario de películas permite subir **imagen de portada**, **imagen de
fondo** y **archivo de vídeo** indicando **rutas locales** de archivos. La API
los envía por `multipart/form-data`. Si dejas esos campos vacíos, no se sube
ningún archivo y se conservan los existentes (o se usa `video_url`).
