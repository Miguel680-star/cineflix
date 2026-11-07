import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api_client.dart';
import '../config.dart';
import '../models.dart';

/// Listado paginado de pagos con total acumulado.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late Future<List<Payment>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getPayments();
  }

  void _reload() {
    setState(() => _future = ApiClient.instance.getPayments());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kNetflixRed,
      onRefresh: () async => _reload(),
      child: FutureBuilder<List<Payment>>(
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
          final payments = snapshot.data ?? const <Payment>[];
          if (payments.isEmpty) {
            return _message(Icons.receipt_long_outlined, 'No hay pagos.');
          }

          // Total acumulado (se calcula solo si los importes son numéricos).
          double total = 0;
          String currency = '';
          for (final p in payments) {
            final value = double.tryParse(p.amount);
            if (value != null) total += value;
            if (currency.isEmpty) currency = p.currency;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.euro, color: Colors.greenAccent, size: 32),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)} $currency',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${payments.length} pagos',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...payments.map(_paymentTile),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentTile(Payment p) {
    final DateFormat fmt = DateFormat('dd/MM/yyyy HH:mm');
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
                  p.userEmail.isEmpty ? 'Sin usuario' : p.userEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${p.amount} ${p.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _statusChip(p.status),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.planName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
              if (p.createdAt != null)
                Text(
                  fmt.format(p.createdAt!.toLocal()),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'succeeded':
      case 'paid':
      case 'completed':
        color = Colors.greenAccent;
        break;
      case 'pending':
        color = Colors.orangeAccent;
        break;
      case 'failed':
      case 'refunded':
        color = kNetflixRed;
        break;
      default:
        color = Colors.white54;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.isEmpty ? 'desconocido' : status,
        style: TextStyle(color: color, fontSize: 11),
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
