// Modelos de datos que mapean las respuestas JSON de la API de CineFlix.
// Las conversiones son tolerantes para evitar fallos por tipos inesperados
// (por ejemplo, importes enviados como string desde el backend).

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

double _asDouble(dynamic v, {double fallback = 0}) =>
    _asDoubleOrNull(v) ?? fallback;

String _asString(dynamic v) => v == null ? '' : v.toString();

String? _asStringOrNull(dynamic v) => v == null ? null : v.toString();

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) return v.toLowerCase() == 'true' || v == '1';
  return false;
}

DateTime? _asDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

List<int> _asIntList(dynamic v) {
  if (v is List) return v.map((e) => _asInt(e)).toList();
  return const <int>[];
}

List<String> _asStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return const <String>[];
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map<String, dynamic> ? v : <String, dynamic>{};

/// Usuario administrador autenticado.
class AdminUser {
  final int id;
  final String username;
  final String email;
  final bool isSuperuser;

  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.isSuperuser,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: _asInt(json['id']),
        username: _asString(json['username']),
        email: _asString(json['email']),
        isSuperuser: _asBool(json['is_superuser']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'username': username,
        'email': email,
        'is_superuser': isSuperuser,
      };
}

/// Estadísticas globales del panel (endpoint /api/admin/stats/).
class Stats {
  final int moviesTotal;
  final int moviesPublished;
  final int genresTotal;
  final int plansTotal;
  final int subscriptionsTotal;
  final int vipActive;
  final int paymentsCount;
  final double incomeTotal;
  final String currency;
  final List<Payment> recentPayments;

  const Stats({
    required this.moviesTotal,
    required this.moviesPublished,
    required this.genresTotal,
    required this.plansTotal,
    required this.subscriptionsTotal,
    required this.vipActive,
    required this.paymentsCount,
    required this.incomeTotal,
    required this.currency,
    required this.recentPayments,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        moviesTotal: _asInt(json['movies_total']),
        moviesPublished: _asInt(json['movies_published']),
        genresTotal: _asInt(json['genres_total']),
        plansTotal: _asInt(json['plans_total']),
        subscriptionsTotal: _asInt(json['subscriptions_total']),
        vipActive: _asInt(json['vip_active']),
        paymentsCount: _asInt(json['payments_count']),
        incomeTotal: _asDouble(json['income_total']),
        currency: _asString(json['currency']),
        recentPayments: (json['recent_payments'] as List?)
                ?.map((e) => Payment.fromJson(_asMap(e)))
                .toList() ??
            const <Payment>[],
      );
}

/// Película del catálogo.
class Movie {
  final int id;
  final String title;
  final String slug;
  final String synopsis;
  final String? posterUrl;
  final String? backdropUrl;
  final int? releaseYear;
  final int? durationMinutes;
  final double? rating;
  final List<int> genres;
  final List<String> genreNames;
  final String? videoUrl;
  final String videoSource;
  final bool isPublished;
  final bool isFeatured;
  final int views;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Movie({
    required this.id,
    required this.title,
    required this.slug,
    required this.synopsis,
    required this.posterUrl,
    required this.backdropUrl,
    required this.releaseYear,
    required this.durationMinutes,
    required this.rating,
    required this.genres,
    required this.genreNames,
    required this.videoUrl,
    required this.videoSource,
    required this.isPublished,
    required this.isFeatured,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Movie.fromJson(Map<String, dynamic> json) => Movie(
        id: _asInt(json['id']),
        title: _asString(json['title']),
        slug: _asString(json['slug']),
        synopsis: _asString(json['synopsis']),
        posterUrl: _asStringOrNull(json['poster_url']),
        backdropUrl: _asStringOrNull(json['backdrop_url']),
        releaseYear: _asIntOrNull(json['release_year']),
        durationMinutes: _asIntOrNull(json['duration_minutes']),
        rating: _asDoubleOrNull(json['rating']),
        genres: _asIntList(json['genres']),
        genreNames: _asStringList(json['genre_names']),
        videoUrl: _asStringOrNull(json['video_url']),
        videoSource: _asString(json['video_source']),
        isPublished: _asBool(json['is_published']),
        isFeatured: _asBool(json['is_featured']),
        views: _asInt(json['views']),
        createdAt: _asDate(json['created_at']),
        updatedAt: _asDate(json['updated_at']),
      );
}

/// Género del catálogo.
class Genre {
  final int id;
  final String name;
  final String slug;
  final int movieCount;

  const Genre({
    required this.id,
    required this.name,
    required this.slug,
    required this.movieCount,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: _asInt(json['id']),
        name: _asString(json['name']),
        slug: _asString(json['slug']),
        movieCount: _asInt(json['movie_count']),
      );
}

/// Plan de suscripción.
class Plan {
  final int id;
  final String name;
  final String slug;
  final String description;

  /// Se mantiene como texto para no perder precisión en los decimales.
  final String price;
  final String currency;
  final int intervalDays;
  final String features;
  final bool isVip;
  final bool isActive;
  final int order;
  final String stripePriceId;

  const Plan({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.currency,
    required this.intervalDays,
    required this.features,
    required this.isVip,
    required this.isActive,
    required this.order,
    required this.stripePriceId,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
        id: _asInt(json['id']),
        name: _asString(json['name']),
        slug: _asString(json['slug']),
        description: _asString(json['description']),
        price: _asString(json['price']),
        currency: _asString(json['currency']),
        intervalDays: _asInt(json['interval_days']),
        features: _asString(json['features']),
        isVip: _asBool(json['is_vip']),
        isActive: _asBool(json['is_active']),
        order: _asInt(json['order']),
        stripePriceId: _asString(json['stripe_price_id']),
      );
}

/// Suscripción de un usuario a un plan (solo lectura).
class Subscription {
  final int id;
  final int? userId;
  final String userEmail;
  final int? planId;
  final String planName;
  final String status;
  final String provider;
  final DateTime? currentPeriodEnd;
  final bool isVip;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.planId,
    required this.planName,
    required this.status,
    required this.provider,
    required this.currentPeriodEnd,
    required this.isVip,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: _asInt(json['id']),
        userId: _asIntOrNull(json['user']),
        userEmail: _asString(json['user_email']),
        planId: _asIntOrNull(json['plan']),
        planName: _asString(json['plan_name']),
        status: _asString(json['status']),
        provider: _asString(json['provider']),
        currentPeriodEnd: _asDate(json['current_period_end']),
        isVip: _asBool(json['is_vip']),
        createdAt: _asDate(json['created_at']),
        updatedAt: _asDate(json['updated_at']),
      );
}

/// Pago registrado (solo lectura).
class Payment {
  final int id;
  final int? userId;
  final String userEmail;
  final int? planId;
  final String planName;
  final String amount;
  final String currency;
  final String status;
  final String provider;
  final String providerReference;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.planId,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.provider,
    required this.providerReference,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: _asInt(json['id']),
        userId: _asIntOrNull(json['user']),
        userEmail: _asString(json['user_email']),
        planId: _asIntOrNull(json['plan']),
        planName: _asString(json['plan_name']),
        amount: _asString(json['amount']),
        currency: _asString(json['currency']),
        status: _asString(json['status']),
        provider: _asString(json['provider']),
        providerReference: _asString(json['provider_reference']),
        createdAt: _asDate(json['created_at']),
      );
}
