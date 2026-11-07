import 'package:flutter/material.dart';

import '../api_client.dart';
import '../config.dart';
import '../models.dart';

/// Formulario para crear o editar una película.
///
/// Nota sobre archivos (imagen de portada, fondo y vídeo): no se añaden
/// dependencias de selección de archivos, así que los campos de archivo son
/// opcionales y se introducen como rutas locales del dispositivo. Si se dejan
/// vacíos, no se sube ningún archivo y se conservan los existentes.
class MovieFormScreen extends StatefulWidget {
  final Movie? movie;

  const MovieFormScreen({super.key, this.movie});

  @override
  State<MovieFormScreen> createState() => _MovieFormScreenState();
}

class _MovieFormScreenState extends State<MovieFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _synopsis;
  late final TextEditingController _releaseYear;
  late final TextEditingController _duration;
  late final TextEditingController _rating;
  late final TextEditingController _videoUrl;
  late final TextEditingController _posterPath;
  late final TextEditingController _backdropPath;
  late final TextEditingController _videoPath;

  bool _isPublished = true;
  bool _isFeatured = false;
  bool _saving = false;
  final Set<int> _selectedGenres = <int>{};
  late Future<List<Genre>> _genresFuture;

  bool get _isEditing => widget.movie != null;

  @override
  void initState() {
    super.initState();
    final m = widget.movie;
    _title = TextEditingController(text: m?.title ?? '');
    _synopsis = TextEditingController(text: m?.synopsis ?? '');
    _releaseYear =
        TextEditingController(text: m?.releaseYear?.toString() ?? '');
    _duration =
        TextEditingController(text: m?.durationMinutes?.toString() ?? '');
    _rating = TextEditingController(text: m?.rating?.toString() ?? '');
    _videoUrl = TextEditingController(text: m?.videoUrl ?? '');
    _posterPath = TextEditingController();
    _backdropPath = TextEditingController();
    _videoPath = TextEditingController();

    _isPublished = m?.isPublished ?? true;
    _isFeatured = m?.isFeatured ?? false;
    if (m != null) _selectedGenres.addAll(m.genres);

    _genresFuture = ApiClient.instance.getGenres();
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _synopsis,
      _releaseYear,
      _duration,
      _rating,
      _videoUrl,
      _posterPath,
      _backdropPath,
      _videoPath,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'title': _title.text.trim(),
      'synopsis': _synopsis.text.trim(),
      'is_published': _isPublished,
      'is_featured': _isFeatured,
      'genres': _selectedGenres.toList(),
    };
    if (_releaseYear.text.trim().isNotEmpty) {
      data['release_year'] = _releaseYear.text.trim();
    }
    if (_duration.text.trim().isNotEmpty) {
      data['duration_minutes'] = _duration.text.trim();
    }
    if (_rating.text.trim().isNotEmpty) {
      data['rating'] = _rating.text.trim();
    }
    if (_videoUrl.text.trim().isNotEmpty) {
      data['video_url'] = _videoUrl.text.trim();
    }

    try {
      if (_isEditing) {
        await ApiClient.instance.updateMovie(
          widget.movie!.id,
          data,
          posterPath: _posterPath.text.trim(),
          backdropPath: _backdropPath.text.trim(),
          videoPath: _videoPath.text.trim(),
        );
      } else {
        await ApiClient.instance.createMovie(
          data,
          posterPath: _posterPath.text.trim(),
          backdropPath: _backdropPath.text.trim(),
          videoPath: _videoPath.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Película actualizada.'
              : 'Película creada correctamente.'),
        ),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar película' : 'Nueva película'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _label('Título'),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(hintText: 'Título de la película'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            _label('Sinopsis'),
            TextFormField(
              controller: _synopsis,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Descripción...'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Año'),
                      TextFormField(
                        controller: _releaseYear,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '2024'),
                        validator: _numberValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Duración (min)'),
                      TextFormField(
                        controller: _duration,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '120'),
                        validator: _numberValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Puntuación'),
                      TextFormField(
                        controller: _rating,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: '8.5'),
                        validator: _decimalValidator,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Géneros'),
            const SizedBox(height: 6),
            _buildGenres(),
            const SizedBox(height: 16),
            _label('URL del vídeo'),
            TextFormField(
              controller: _videoUrl,
              decoration: const InputDecoration(
                hintText: 'https://... (o deja vacío para subir un archivo)',
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Publicada'),
              subtitle: const Text('Visible en el catálogo'),
              value: _isPublished,
              activeColor: kNetflixRed,
              onChanged: (v) => setState(() => _isPublished = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Destacada'),
              subtitle: const Text('Aparece en el carrusel destacado'),
              value: _isFeatured,
              activeColor: kNetflixRed,
              onChanged: (v) => setState(() => _isFeatured = v),
            ),
            const SizedBox(height: 8),
            _label('Archivos (opcional)'),
            const SizedBox(height: 6),
            Text(
              'Indica rutas locales de archivos para subirlos por multipart. '
              'Si las dejas vacías no se modifica el archivo actual.',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _posterPath,
              decoration: const InputDecoration(
                labelText: 'Ruta imagen de portada',
                hintText: '/ruta/a/poster.jpg',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _backdropPath,
              decoration: const InputDecoration(
                labelText: 'Ruta imagen de fondo',
                hintText: '/ruta/a/backdrop.jpg',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _videoPath,
              decoration: const InputDecoration(
                labelText: 'Ruta archivo de vídeo',
                hintText: '/ruta/a/pelicula.mp4',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Guardar cambios' : 'Crear película',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );

  Widget _buildGenres() {
    return FutureBuilder<List<Genre>>(
      future: _genresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kNetflixRed,
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              const Expanded(
                child: Text(
                  'No se pudieron cargar los géneros.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _genresFuture = ApiClient.instance.getGenres();
                }),
                child: const Text('Reintentar'),
              ),
            ],
          );
        }
        final genres = snapshot.data ?? const <Genre>[];
        if (genres.isEmpty) {
          return const Text(
            'No hay géneros disponibles.',
            style: TextStyle(color: Colors.white54),
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: genres.map((g) {
            final selected = _selectedGenres.contains(g.id);
            return FilterChip(
              label: Text(g.name),
              selected: selected,
              backgroundColor: kCardColor,
              selectedColor: kNetflixRed,
              checkmarkColor: Colors.white,
              labelStyle: const TextStyle(color: Colors.white),
              onSelected: (v) => setState(() {
                if (v) {
                  _selectedGenres.add(g.id);
                } else {
                  _selectedGenres.remove(g.id);
                }
              }),
            );
          }).toList(),
        );
      },
    );
  }

  String? _numberValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return int.tryParse(v.trim()) == null ? 'Número inválido' : null;
  }

  String? _decimalValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.trim()) == null ? 'Número inválido' : null;
  }
}
