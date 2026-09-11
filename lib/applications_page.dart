import 'package:flutter/material.dart';

import 'application_detail_page.dart';
import 'application_repository.dart';

class ApplicationsPage extends StatelessWidget {
  const ApplicationsPage({super.key, required this.repository});

  final ApplicationRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<JobApplication>>(
        stream: repository.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _ApplicationsError();
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final applications = snapshot.data!;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('Candidaturas', style: Theme.of(context).textTheme.headlineSmall)),
                        IconButton(tooltip: 'Nova candidatura', onPressed: () => _openCreate(context), icon: const Icon(Icons.add)),
                      ],
                    ),
                  ),
                  if (applications.isEmpty)
                    const Expanded(child: _EmptyApplications())
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        itemCount: applications.length,
                        itemBuilder: (context, index) => _JobApplicationTile(
                          application: applications[index],
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ApplicationDetailPage(application: applications[index], repository: repository),
                          )),
                        ),
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    final company = TextEditingController();
    final role = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova candidatura'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: company, autofocus: true, decoration: const InputDecoration(labelText: 'Empresa')),
          TextField(controller: role, decoration: const InputDecoration(labelText: 'Cargo')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (company.text.trim().isEmpty || role.text.trim().isEmpty) return;
              try {
                await repository.create(company: company.text.trim(), role: role.text.trim());
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (_) {
                if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Nao foi possivel criar a candidatura.')));
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    company.dispose();
    role.dispose();
  }
}

class _JobApplicationTile extends StatelessWidget {
  const _JobApplicationTile({required this.application, required this.onTap});

  final JobApplication application;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(child: Text(application.company.substring(0, 1).toUpperCase())),
      title: Text(application.company),
      subtitle: Text('${application.role}\n${application.status.label}'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _ApplicationsError extends StatelessWidget {
  const _ApplicationsError();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off_outlined, size: 42),
        SizedBox(height: 12),
        Text('Nao foi possivel carregar as candidaturas.', textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.work_outline, size: 42),
        SizedBox(height: 12),
        Text('Nenhuma candidatura encontrada.'),
        SizedBox(height: 4),
        Text('Adicione a primeira oportunidade para acompanha-la aqui.', textAlign: TextAlign.center),
      ]),
    ),
  );
}
