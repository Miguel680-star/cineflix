import 'package:flutter/material.dart';

/// URL base del backend de CineFlix.
///
/// Cámbiala por la IP o el dominio de tu servidor antes de compilar.
/// Ejemplos:
///   - Emulador Android contra tu máquina: 'http://10.0.2.2:8000'
///   - Dispositivo físico en tu red local: 'http://192.168.1.100:8000'
///   - Producción: 'https://api.cineflix.com'
const String apiBaseUrl = 'http://127.0.0.1:8000';

/// Convierte una URL relativa devuelta por la API (p. ej. "/media/x.jpg")
/// en una URL absoluta usando [apiBaseUrl]. Si ya es absoluta la deja igual.
String? resolveApiUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return '$apiBaseUrl$url';
}

// ---------------------------------------------------------------------------
// Paleta de colores con estética Netflix.
// ---------------------------------------------------------------------------

/// Rojo característico de Netflix.
const Color kNetflixRed = Color(0xFFE50914);

/// Fondo oscuro principal de la aplicación.
const Color kDarkBackground = Color(0xFF141414);

/// Color de las tarjetas y superficies.
const Color kCardColor = Color(0xFF1F1F1F);
