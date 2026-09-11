import 'package:flutter/material.dart';

import 'application_repository.dart';

class ApplicationDetailPage extends StatefulWidget {
  const ApplicationDetailPage({super.key, required this.application, required this.repository});

  final JobApplication application;
  final ApplicationRepository repository;

  @override
  State<ApplicationDetailPage> createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  late final TextEditingController _company = TextEditingController(text: widget.application.company);
  late final TextEditingController _role = TextEditingController(text: widget.application.role);
  late ApplicationStatus _status = widget.application.status;
  bool _saving = false;

  @override
  void dispose() {
    _company.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Detalhes da candidatura')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              TextField(controller: _company, decoration: const InputDecoration(labelText: 'Empresa', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _role, decoration: const InputDecoration(labelText: 'Cargo', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<ApplicationStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ApplicationStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.label))).toList(),
                onChanged: (value) => setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 12),
              Text('Criada em ${_formatDate(widget.application.createdAt)}'),
              const SizedBox(height: 28),
              FilledButton(onPressed: _saving ? null : _save, child: const Text('Salvar alteracoes')),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _saving ? null : _remove, icon: const Icon(Icons.delete_outline), label: const Text('Remover candidatura')),
            ]),
          ),
        ),
      );

  Future<void> _save() async {
    if (_company.text.trim().isEmpty || _role.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.repository.update(widget.application.copyWith(company: _company.text.trim(), role: _role.text.trim(), status: _status));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nao foi possivel salvar a candidatura.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _saving = true);
    try {
      await widget.repository.remove(widget.application.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nao foi possivel remover a candidatura.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}