import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';
import 'models.dart';

/// Excepción lanzada cuando la API devuelve un error o no es accesible.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Cliente HTTP para consumir la API de administración de CineFlix.
///
/// Es un singleton: usa [ApiClient.instance] desde cualquier pantalla.
class ApiClient {
  ApiClient._();

  /// Instancia única compartida por toda la aplicación.
  static final ApiClient instance = ApiClient._();

  static const String _tokenKey = 'cineflix_token';
  static const String _userKey = 'cineflix_user';

  static const String _connError =
      'No se pudo conectar con el servidor. Revisa tu conexión y la URL del '
      'backend en lib/config.dart.';

  String? _token;
  AdminUser? _currentUser;

  String? get token => _token;
  AdminUser? get currentUser => _currentUser;

  /// Indica si hay un token de sesión cargado.
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Persistencia de la sesión
  // ---------------------------------------------------------------------------

  /// Carga el token y el usuario guardados en el dispositivo.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        _currentUser =
            AdminUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Autenticación
  // ---------------------------------------------------------------------------

  /// Inicia sesión y guarda el token + usuario en el dispositivo.
  Future<AdminUser> login(String username, String password) async {
    final uri = Uri.parse('$apiBaseUrl/api/admin/login/');
    final res = await _safe(http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    ));
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body, isLogin: true);

    final userJson = body['user'];
    _currentUser = userJson is Map<String, dynamic>
        ? AdminUser.fromJson(userJson)
        : AdminUser(id: 0, username: username, email: '', isSuperuser: false);
    _token = body['token']?.toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token ?? '');
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

    return _currentUser!;
  }

  /// Cierra sesión y borra las credenciales guardadas.
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ---------------------------------------------------------------------------
  // Estadísticas
  // ---------------------------------------------------------------------------

  Future<Stats> getStats() async {
    final res = await _safe(http.get(
      Uri.parse('$apiBaseUrl/api/admin/stats/'),
      headers: _headers,
    ));
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body);
    return Stats.fromJson(body);
  }

  // ---------------------------------------------------------------------------
  // Películas
  // ---------------------------------------------------------------------------

  Future<List<Movie>> getMovies({String? search}) async {
    final query = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final items = await _getPaged(
      '/api/admin/movies/',
      query: query.isEmpty ? null : query,
    );
    return items.map(Movie.fromJson).toList();
  }

  Future<Movie> getMovie(int id) async {
    final res = await _safe(http.get(
      Uri.parse('$apiBaseUrl/api/admin/movies/$id/'),
      headers: _headers,
    ));
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body);
    return Movie.fromJson(body);
  }

  /// Crea una película. Los archivos son opcionales.
  Future<Movie> createMovie(
    Map<String, dynamic> data, {
    String? posterPath,
    String? backdropPath,
    String? videoPath,
  }) {
    return _saveMovie(
      null,
      data,
      posterPath: posterPath,
      backdropPath: backdropPath,
      videoPath: videoPath,
    );
  }

  /// Actualiza (PUT) una película. Los archivos son opcionales.
  Future<Movie> updateMovie(
    int id,
    Map<String, dynamic> data, {
    String? posterPath,
    String? backdropPath,
    String? videoPath,
  }) {
    return _saveMovie(
      id,
      data,
      posterPath: posterPath,
      backdropPath: backdropPath,
      videoPath: videoPath,
    );
  }

  Future<void> deleteMovie(int id) async {
    final res = await _safe(http.delete(
      Uri.parse('$apiBaseUrl/api/admin/movies/$id/'),
      headers: _headers,
    ));
    if (!_isOk(res)) throw _error(res, _decode(res));
  }

  /// Envía la película por multipart/form-data (POST o PUT).
  Future<Movie> _saveMovie(
    int? id,
    Map<String, dynamic> data, {
    String? posterPath,
    String? backdropPath,
    String? videoPath,
  }) async {
    final url = id == null
        ? '$apiBaseUrl/api/admin/movies/'
        : '$apiBaseUrl/api/admin/movies/$id/';
    final method = id == null ? 'POST' : 'PUT';

    final request = http.MultipartRequest(method, Uri.parse(url));
    request.headers.addAll(_headers);

    data.forEach((key, value) {
      if (value == null) return;
      if (value is List) {
        // Los géneros se envían como campos repetidos (DRF los lee con getlist).
        for (final item in value) {
          request.files.add(
            http.MultipartFile.fromString(key, item.toString()),
          );
        }
      } else if (value is bool) {
        request.fields[key] = value ? 'true' : 'false';
      } else {
        request.fields[key] = value.toString();
      }
    });

    if (posterPath != null && posterPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('poster', posterPath));
    }
    if (backdropPath != null && backdropPath.isNotEmpty) {
      request.files
          .add(await http.MultipartFile.fromPath('backdrop', backdropPath));
    }
    if (videoPath != null && videoPath.isNotEmpty) {
      request.files
          .add(await http.MultipartFile.fromPath('video_file', videoPath));
    }

    final res = await _sendMultipart(request);
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body);
    return Movie.fromJson(body);
  }

  // ---------------------------------------------------------------------------
  // Géneros
  // ---------------------------------------------------------------------------

  Future<List<Genre>> getGenres() async {
    final items = await _getPaged('/api/admin/genres/');
    return items.map(Genre.fromJson).toList();
  }

  Future<Genre> createGenre(String name) async {
    final res = await _safe(http.post(
      Uri.parse('$apiBaseUrl/api/admin/genres/'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name}),
    ));
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body);
    return Genre.fromJson(body);
  }

  Future<Genre> updateGenre(int id, {String? name}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    final res = await _safe(http.patch(
      Uri.parse('$apiBaseUrl/api/admin/genres/$id/'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    ));
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body);
    return Genre.fromJson(body);
  }

  Future<void> deleteGenre(int id) async {
    final res = await _safe(http.delete(
      Uri.parse('$apiBaseUrl/api/admin/genres/$id/'),
      headers: _headers,
    ));
    if (!_isOk(res)) throw _error(res, _decode(res));
  }

  // ---------------------------------------------------------------------------
  // Planes
  // ---------------------------------------------------------------------------

  Future<List<Plan>> getPlans() async {
    final items = await _getPaged('/api/admin/plans/');
    return items.map(Plan.fromJson).toList();
  }

  Future<Plan> createPlan(Map<String, dynamic> data) async {
    final res = await _safe(http.post(
      Uri.parse('$apiBaseUrl/api/admin/plans/'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    ));
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body);
    return Plan.fromJson(body);
  }

  Future<Plan> updatePlan(int id, Map<String, dynamic> data) async {
    final res = await _safe(http.patch(
      Uri.parse('$apiBaseUrl/api/admin/plans/$id/'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    ));
    final body = _decode(res);
    if (!_isOk(res)) throw _error(res, body);
    return Plan.fromJson(body);
  }

  Future<void> deletePlan(int id) async {
    final res = await _safe(http.delete(
      Uri.parse('$apiBaseUrl/api/admin/plans/$id/'),
      headers: _headers,
    ));
    if (!_isOk(res)) throw _error(res, _decode(res));
  }

  // ---------------------------------------------------------------------------
  // Suscripciones y pagos (solo lectura)
  // ---------------------------------------------------------------------------

  Future<List<Subscription>> getSubscriptions() async {
    final items = await _getPaged('/api/admin/subscriptions/');
    return items.map(Subscription.fromJson).toList();
  }

  Future<List<Payment>> getPayments() async {
    final items = await _getPaged('/api/admin/payments/');
    return items.map(Payment.fromJson).toList();
  }

  // ---------------------------------------------------------------------------
  // Utilidades internas
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers {
    final headers = <String, String>{'Accept': 'application/json'};
    if (isLoggedIn) headers['Authorization'] = 'Token $_token';
    return headers;
  }

  Map<String, String> get _jsonHeaders =>
      <String, String>{..._headers, 'Content-Type': 'application/json'};

  /// Realiza una petición HTTP gestionando errores de red.
  Future<http.Response> _safe(Future<http.Response> future) async {
    try {
      return await future;
    } on SocketException {
      throw ApiException(_connError);
    } on http.ClientException {
      throw ApiException(_connError);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  /// Envía una petición multipart gestionando errores de red.
  Future<http.Response> _sendMultipart(http.MultipartRequest request) async {
    try {
      final streamed = await request.send();
      return await http.Response.fromStream(streamed);
    } on SocketException {
      throw ApiException(_connError);
    } on http.ClientException {
      throw ApiException(_connError);
    } catch (e) {
      throw ApiException('Error inesperado: $e');
    }
  }

  /// Decodifica el cuerpo de la respuesta. Si es una lista, la envuelve
  /// bajo la clave 'data'.
  Map<String, dynamic> _decode(http.Response res) {
    if (res.bodyBytes.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'data': decoded};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  bool _isOk(http.Response res) =>
      res.statusCode >= 200 && res.statusCode < 300;

  /// Recorre todas las páginas de un endpoint paginado de DRF.
  Future<List<Map<String, dynamic>>> _getPaged(
    String path, {
    Map<String, String>? query,
  }) async {
    final items = <Map<String, dynamic>>[];
    Uri? uri = Uri.parse('$apiBaseUrl$path');
    if (query != null) uri = uri.replace(queryParameters: query);

    var guard = 0;
    while (uri != null && guard < 200) {
      guard++;
      final res = await _safe(http.get(uri, headers: _headers));
      final body = _decode(res);
      if (!_isOk(res)) throw _error(res, body);

      final results = body['results'] ?? body['data'];
      if (results is List) {
        items.addAll(results.whereType<Map<String, dynamic>>());
      }

      final next = body['next'];
      uri = (next is String && next.isNotEmpty) ? Uri.parse(next) : null;
    }
    return items;
  }

  /// Construye una [ApiException] con un mensaje legible.
  ApiException _error(
    http.Response res,
    Map<String, dynamic> body, {
    bool isLogin = false,
  }) {
    final code = res.statusCode;
    if (code == 401) {
      return ApiException(
        isLogin
            ? 'Usuario o contraseña incorrectos.'
            : 'Sesión expirada. Inicia sesión de nuevo.',
        statusCode: 401,
      );
    }
    if (code == 403) {
      return ApiException(
        'No tienes permisos para realizar esta acción.',
        statusCode: 403,
      );
    }
    if (code == 404) {
      return ApiException('Recurso no encontrado.', statusCode: 404);
    }

    String msg = 'Error del servidor ($code).';
    if (body.isNotEmpty) {
      final detail = body['detail'] ?? body['error'] ?? body['message'];
      if (detail != null) {
        msg = detail.toString();
      } else {
        final key = body.keys.first;
        final value = body[key];
        msg = value is List ? '$key: ${value.join(', ')}' : '$key: $value';
      }
    }
    return ApiException(msg, statusCode: code);
  }
}
