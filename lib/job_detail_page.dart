import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'job_repository.dart';
import 'resume_repository.dart';

class JobDetailPage extends StatefulWidget {
  const JobDetailPage({super.key, required this.job, required this.repository, required this.resumeRepository});
  final JobPosting job;
  final JobRepository repository;
  final ResumeRepository resumeRepository;
  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  bool? _saved;
  @override
  void initState() { super.initState(); _loadSaved(); }
  Future<void> _loadSaved() async { final saved = await widget.repository.isSaved(widget.job.id); if (mounted) setState(() => _saved = saved); }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Detalhes da vaga')), body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: ListView(padding: const EdgeInsets.all(24), children: [
    Text(widget.job.title, style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 6), Text(widget.job.company, style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 12), Text('${widget.job.location} | ${widget.job.workMode}${widget.job.salary == null ? '' : ' | ${widget.job.salary}'}'),
    if (widget.job.technologies.isNotEmpty) ...[const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: widget.job.technologies.map((item) => Chip(label: Text(item))).toList())],
    const SizedBox(height: 24), Text('Descricao', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), SelectableText(widget.job.description),
    const SizedBox(height: 24), FilledButton.icon(onPressed: _applyOnOfficialSite, icon: const Icon(Icons.open_in_new), label: const Text('Candidatar-me no site oficial')),
    const SizedBox(height: 12), OutlinedButton.icon(onPressed: _saved == null ? null : _toggleSaved, icon: Icon(_saved! ? Icons.bookmark : Icons.bookmark_border), label: Text(_saved! ? 'Vaga salva' : 'Salvar vaga')),
    const SizedBox(height: 12), OutlinedButton.icon(onPressed: _analyzeResume, icon: const Icon(Icons.analytics_outlined), label: const Text('Analisar meu CV para esta vaga')),
    const SizedBox(height: 12), OutlinedButton.icon(onPressed: _startInterview, icon: const Icon(Icons.record_voice_over_outlined), label: const Text('Fazer entrevista com IA')),
  ]))));
  Future<void> _toggleSaved() async { if (_saved == true) { await widget.repository.removeSaved(widget.job.id); } else { await widget.repository.save(widget.job.id); } if (mounted) setState(() => _saved = !_saved!); }
  Future<void> _applyOnOfficialSite() async { final uri = Uri.tryParse(widget.job.sourceUrl); if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nao foi possivel abrir a candidatura oficial.'))); } }
  Future<void> _analyzeResume() async {
    try {
      final response = await widget.resumeRepository.analyzeLatestForJob(widget.job.id);
      final result = response['result'] as Map<String, dynamic>? ?? const {};
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: Text('Compatibilidade estimada: ${response['estimated_match_percentage'] ?? 0}%'),
        content: SingleChildScrollView(child: Text(result['disclaimer'] as String? ?? 'Avaliacao gerada pelo backend.')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _startInterview() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A entrevista sera liberada quando o provedor de IA estiver configurado no backend.')));
  }
}