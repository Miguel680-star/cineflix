import 'package:flutter/material.dart';

import '../api_client.dart';
import '../config.dart';
import '../models.dart';
import 'movie_form_screen.dart';

/// Listado de películas con buscador, alta, edición y borrado.
class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key});

  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final _searchController = TextEditingController();
  late Future<List<Movie>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = ApiClient.instance.getMovies(search: _searchController.text);
    });
  }

  Future<void> _openForm({Movie? movie}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => MovieFormScreen(movie: movie)),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(Movie movie) async {
    try {
      await ApiClient.instance.deleteMovie(movie.id);
      _showSnack('Película eliminada.');
      _reload();
    } on ApiException catch (e) {
      _showSnack(e.message);
      _reload();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                hintText: 'Buscar películas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _reload();
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kNetflixRed,
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<Movie>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kNetflixRed),
                    );
                  }
                  if (snapshot.hasError) {
                    return _MessageView(
                      icon: Icons.cloud_off,
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }
                  final movies = snapshot.data ?? const <Movie>[];
                  if (movies.isEmpty) {
                    return const _MessageView(
                      icon: Icons.movie_outlined,
                      message: 'No hay películas. Pulsa + para crear una.',
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: movies.length,
                    itemBuilder: (context, index) =>
                        _movieTile(movies[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movieTile(Movie movie) {
    final poster = resolveApiUrl(movie.posterUrl);
    return Dismissible(
      key: ValueKey(movie.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: kNetflixRed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Eliminar película'),
                content: Text(
                  '¿Seguro que quieres eliminar "${movie.title}"? '
                  'Esta acción no se puede deshacer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => _delete(movie),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 48,
              height: 68,
              child: poster == null
                  ? Container(
                      color: Colors.black26,
                      child: const Icon(Icons.movie, color: Colors.white38),
                    )
                  : Image.network(
                      poster,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black26,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white38),
                      ),
                    ),
            ),
          ),
          title: Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              [
                if (movie.releaseYear != null) '${movie.releaseYear}',
                '${movie.views} visitas',
                if (movie.genreNames.isNotEmpty)
                  movie.genreNames.take(2).join(', '),
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                movie.isPublished ? Icons.visibility : Icons.visibility_off,
                color: movie.isPublished ? Colors.greenAccent : Colors.white38,
                size: 20,
              ),
              if (movie.isFeatured) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, color: Colors.amber, size: 20),
              ],
            ],
          ),
          onTap: () => _openForm(movie: movie),
        ),
      ),
    );
  }
}

/// Vista informativa / de error simple con reintento opcional.
class _MessageView extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  const _MessageView({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Se envuelve en ListView para permitir el pull-to-refresh.
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              Icon(icon, color: Colors.white38, size: 48),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
