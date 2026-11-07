import 'package:flutter/material.dart';

import '../api_client.dart';
import '../config.dart';
import 'login_screen.dart';
import 'subscriptions_screen.dart';

/// Pantalla de cuenta: datos del usuario y cierre de sesión.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await ApiClient.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClient.instance.currentUser;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: kCardColor,
            child: Text(
              (user?.username.isNotEmpty ?? false)
                  ? user!.username[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            user?.username ?? 'Usuario',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (user != null && user.email.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                user.email,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        if (user?.isSuperuser == true)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: Chip(
                backgroundColor: kNetflixRed,
                label: Text(
                  'Superusuario',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: const Icon(Icons.card_membership, color: Colors.white),
            title: const Text(
              'Suscripciones',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Ver usuarios suscritos',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: kNetflixRed),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: kNetflixRed),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: kNetflixRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
