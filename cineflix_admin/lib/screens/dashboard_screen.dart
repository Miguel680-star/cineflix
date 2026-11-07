import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api_client.dart';
import '../config.dart';
import '../models.dart';
import '../widgets/stat_card.dart';

/// Panel de inicio con estadísticas y últimos pagos.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Stats> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getStats();
  }

  Future<void> _reload() async {
    setState(() => _future = ApiClient.instance.getStats());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kNetflixRed,
      onRefresh: _reload,
      child: FutureBuilder<Stats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kNetflixRed),
            );
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final stats = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('Resumen'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatCard(
                    label: 'Películas',
                    value: '${stats.moviesTotal}',
                    icon: Icons.movie,
                  ),
                  StatCard(
                    label: 'VIP activos',
                    value: '${stats.vipActive}',
                    icon: Icons.workspace_premium,
                    accent: Colors.amber,
                  ),
                  StatCard(
                    label: 'Suscripciones',
                    value: '${stats.subscriptionsTotal}',
                    icon: Icons.card_membership,
                  ),
                  StatCard(
                    label: 'Pagos',
                    value: '${stats.paymentsCount}',
                    icon: Icons.receipt_long,
                  ),
                  StatCard(
                    label: 'Ingresos',
                    value:
                        '${stats.incomeTotal.toStringAsFixed(2)} ${stats.currency}',
                    icon: Icons.euro,
                    accent: Colors.greenAccent,
                  ),
                  StatCard(
                    label: 'Géneros',
                    value: '${stats.genresTotal}',
                    icon: Icons.category,
                    accent: Colors.lightBlueAccent,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _sectionTitle('Últimos pagos'),
              const SizedBox(height: 8),
              if (stats.recentPayments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No hay pagos recientes.',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              else
                ...stats.recentPayments.map((p) => _RecentPaymentTile(pago: p)),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
}

class _RecentPaymentTile extends StatelessWidget {
  final Payment pago;

  const _RecentPaymentTile({required this.pago});

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pago.userEmail.isEmpty ? 'Sin usuario' : pago.userEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pago.planName} · ${pago.status}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${pago.amount} ${pago.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pago.createdAt != null)
                Text(
                  fmt.format(pago.createdAt!.toLocal()),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Vista de error reutilizable con botón de reintento.
class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: kNetflixRed, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
