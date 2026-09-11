import 'dart:async';

import 'package:flutter/material.dart';

import 'application_repository.dart';

class ApplicationsPage extends StatefulWidget {
  const ApplicationsPage({super.key, required this.repository});

  final ApplicationRepository repository;

  @override
  State<ApplicationsPage> createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  static const _pollInterval = Duration(seconds: 15);
  Timer? _pollTimer;
  bool _loading = true;
  Object? _connectionError;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(showLoading: false));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      await widget.repository.refresh();
      if (mounted) setState(() => _connectionError = null);
    } catch (error) {
      if (mounted) setState(() => _connectionError = error);
    } finally {
      if (showLoading && mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<JobApplication>>(
        stream: widget.repository.changes,
        builder: (context, snapshot) {
          final applications = snapshot.data ?? const <JobApplication>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Candidaturas', style: Theme.of(context).textTheme.headlineSmall)),
                    IconButton(tooltip: 'Atualizar', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
                  ],
                ),
              ),
              if (_connectionError != null)
                _ConnectionError(onRetry: _load)
              else if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (applications.isEmpty)
                const Expanded(child: _EmptyApplications())
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      itemCount: applications.length,
                      itemBuilder: (context, index) => _JobApplicationTile(
                        application: applications[index],
                        onEdit: () => _editApplication(applications[index]),
                        onDelete: () => widget.repository.remove(applications[index].id),
                      ),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(onPressed: _addApplication, icon: const Icon(Icons.add), label: const Text('Nova candidatura')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addApplication() async {
    final draft = await _showApplicationDialog();
    if (draft == null) return;
    await widget.repository.create(company: draft.company, role: draft.role);
  }

  Future<void> _editApplication(JobApplication application) async {
    final draft = await _showApplicationDialog(application: application);
    if (draft == null) return;
    await widget.repository.update(application.copyWith(company: draft.company, role: draft.role));
  }

  Future<_ApplicationDraft?> _showApplicationDialog({JobApplication? application}) {
    final companyController = TextEditingController(text: application?.company);
    final roleController = TextEditingController(text: application?.role);
    return showDialog<_ApplicationDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(application == null ? 'Nova candidatura' : 'Editar candidatura'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: companyController, autofocus: true, decoration: const InputDecoration(labelText: 'Empresa')),
            TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Cargo')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ApplicationDraft(companyController.text.trim(), roleController.text.trim())),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class _JobApplicationTile extends StatelessWidget {
  const _JobApplicationTile({required this.application, required this.onEdit, required this.onDelete});

  final JobApplication application;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        title: Text(application.company),
        subtitle: Text('${application.role}\n${application.status.label}'),
        isThreeLine: true,
        leading: CircleAvatar(child: Text(application.company.substring(0, 1).toUpperCase())),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(onTap: onEdit, child: const Text('Editar')),
            PopupMenuItem(onTap: onDelete, child: const Text('Remover')),
          ],
        ),
      ),
    );
  }
}

class _ConnectionError extends StatelessWidget {
  const _ConnectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 12),
              Text('Nao foi possivel atualizar as candidaturas.', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline, size: 42),
            const SizedBox(height: 12),
            Text('Nenhuma candidatura encontrada.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Adicione a primeira oportunidade para acompanha-la aqui.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ApplicationDraft {
  const _ApplicationDraft(this.company, this.role);

  final String company;
  final String role;
}