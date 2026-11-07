import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api_client.dart';
import '../config.dart';
import '../models.dart';

/// Listado de suscripciones (solo lectura).
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late Future<List<Subscription>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getSubscriptions();
  }

  void _reload() {
    setState(() => _future = ApiClient.instance.getSubscriptions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suscripciones')),
      body: RefreshIndicator(
        color: kNetflixRed,
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Subscription>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: kNetflixRed),
              );
            }
            if (snapshot.hasError) {
              return _message(
                Icons.cloud_off,
                snapshot.error.toString(),
                onRetry: _reload,
              );
            }
            final subs = snapshot.data ?? const <Subscription>[];
            if (subs.isEmpty) {
              return _message(
                Icons.card_membership_outlined,
                'No hay suscripciones.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subs.length,
              itemBuilder: (context, index) => _subTile(subs[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _subTile(Subscription s) {
    final DateFormat fmt = DateFormat('dd/MM/yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.userEmail.isEmpty ? 'Sin usuario' : s.userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (s.isVip)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'VIP',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.planName,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white38, size: 16),
              const SizedBox(width: 6),
              Text(
                s.status,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const Spacer(),
              if (s.currentPeriodEnd != null)
                Text(
                  'Hasta ${fmt.format(s.currentPeriodEnd!.toLocal())}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String text, {VoidCallback? onRetry}) {
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
                  text,
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
