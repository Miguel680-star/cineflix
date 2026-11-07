import 'package:flutter/material.dart';

import '../api_client.dart';
import '../config.dart';
import '../models.dart';

/// Listado y gestión de planes de suscripción.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  late Future<List<Plan>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient.instance.getPlans();
  }

  void _reload() {
    setState(() => _future = ApiClient.instance.getPlans());
  }

  Future<void> _toggleActive(Plan plan, bool value) async {
    try {
      await ApiClient.instance.updatePlan(plan.id, {'is_active': value});
      _reload();
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _openForm({Plan? plan}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PlanDialog(plan: plan),
    );
    if (saved == true) _reload();
  }

  void _snack(String message) {
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
      body: RefreshIndicator(
        color: kNetflixRed,
        onRefresh: () async => _reload(),
        child: FutureBuilder<List<Plan>>(
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
            final plans = snapshot.data ?? const <Plan>[];
            if (plans.isEmpty) {
              return _message(
                Icons.card_membership_outlined,
                'No hay planes. Pulsa + para crear uno.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: plans.length,
              itemBuilder: (context, index) => _planTile(plans[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _planTile(Plan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.isVip ? Colors.amber : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (plan.isVip)
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
            '${plan.price} ${plan.currency} · cada ${plan.intervalDays} días',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              plan.description,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.toggle_on, color: Colors.white38, size: 18),
              const SizedBox(width: 6),
              Text(
                plan.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  color: plan.isActive ? Colors.greenAccent : Colors.white38,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openForm(plan: plan),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editar'),
              ),
              Switch(
                value: plan.isActive,
                activeColor: kNetflixRed,
                onChanged: (v) => _toggleActive(plan, v),
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

/// Diálogo para crear o editar un plan.
class _PlanDialog extends StatefulWidget {
  final Plan? plan;

  const _PlanDialog({this.plan});

  @override
  State<_PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<_PlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _intervalDays;
  late final TextEditingController _features;

  bool _isVip = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.plan != null;

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price ?? '');
    _currency = TextEditingController(text: p?.currency ?? 'EUR');
    _intervalDays =
        TextEditingController(text: (p?.intervalDays ?? 30).toString());
    _features = TextEditingController(text: p?.features ?? '');
    _isVip = p?.isVip ?? false;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _price,
      _currency,
      _intervalDays,
      _features,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': _price.text.trim(),
      'currency': _currency.text.trim(),
      'interval_days': int.tryParse(_intervalDays.text.trim()) ?? 30,
      'features': _features.text,
      'is_vip': _isVip,
      'is_active': _isActive,
    };
    try {
      if (_isEditing) {
        await ApiClient.instance.updatePlan(widget.plan!.id, data);
      } else {
        await ApiClient.instance.createPlan(data);
      }
      if (!mounted) return;
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
    return AlertDialog(
      backgroundColor: kCardColor,
      title: Text(_isEditing ? 'Editar plan' : 'Nuevo plan'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  _name,
                  'Nombre',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Requerido'
                      : null,
                ),
                _field(_description, 'Descripción', maxLines: 2),
                _field(
                  _price,
                  'Precio',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return double.tryParse(v.trim()) == null ? 'Inválido' : null;
                  },
                ),
                _field(_currency, 'Moneda'),
                _field(
                  _intervalDays,
                  'Días de intervalo',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return int.tryParse(v.trim()) == null ? 'Inválido' : null;
                  },
                ),
                _field(_features, 'Características (una por línea)', maxLines: 3),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Es VIP'),
                  value: _isVip,
                  activeColor: kNetflixRed,
                  onChanged: (v) => setState(() => _isVip = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activo'),
                  value: _isActive,
                  activeColor: kNetflixRed,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
