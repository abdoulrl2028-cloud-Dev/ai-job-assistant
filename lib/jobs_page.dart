import 'package:flutter/material.dart';

import 'job_detail_page.dart';
import 'job_repository.dart';
import 'resume_repository.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key, required this.repository, required this.resumeRepository});
  final JobRepository repository;
  final ResumeRepository resumeRepository;
  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final _query = TextEditingController();
  final _country = TextEditingController();
  final _city = TextEditingController();
  final _language = TextEditingController();
  final _salary = TextEditingController();
  final _experience = TextEditingController();
  String _mode = 'all';
  int _visible = 20;

  @override
  void dispose() {
    _query.dispose();
    _country.dispose();
    _city.dispose();
    _language.dispose();
    _salary.dispose();
    _experience.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: StreamBuilder<List<JobPosting>>(
    stream: widget.repository.watchJobs(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const _JobError();
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final terms = _query.text.toLowerCase().trim().split(RegExp(r'\s+')).where((term) => term.isNotEmpty);
      final country = _country.text.trim().toLowerCase();
      final city = _city.text.trim().toLowerCase();
      final language = _language.text.trim().toLowerCase();
      final experience = _experience.text.trim().toLowerCase();
      final salary = double.tryParse(_salary.text.trim());
      final jobs = snapshot.data!.where((job) {
        final searchable = '${job.title} ${job.company} ${job.location} ${job.country ?? ''} ${job.city ?? ''} ${job.technologies.join(' ')} ${job.languages.join(' ')}'.toLowerCase();
        final salaryText = job.salary?.toLowerCase() ?? '';
        return (_mode == 'all' || job.workMode == _mode) &&
        terms.every(searchable.contains) &&
        (country.isEmpty || (job.country?.toLowerCase().contains(country) ?? false) || searchable.contains(country)) &&
        (city.isEmpty || (job.city?.toLowerCase().contains(city) ?? false) || searchable.contains(city)) &&
        (language.isEmpty || job.languages.any((item) => item.toLowerCase().contains(language)) || searchable.contains(language)) &&
        (experience.isEmpty || (job.experienceLevel?.toLowerCase().contains(experience) ?? false) || searchable.contains(experience)) &&
        (salary == null || salaryText.contains(salary.toStringAsFixed(0)));
      }).toList();
      return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1100), child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vagas internacionais', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          TextField(controller: _query, onChanged: (_) => setState(() => _visible = 20), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cargo, tecnologia, empresa, pais ou cidade', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegmentedButton<String>(segments: const [ButtonSegment(value: 'all', label: Text('Todas')), ButtonSegment(value: 'remote', label: Text('Remoto')), ButtonSegment(value: 'hybrid', label: Text('Hibrido')), ButtonSegment(value: 'onsite', label: Text('Presencial'))], selected: {_mode}, onSelectionChanged: (selection) => setState(() { _mode = selection.first; _visible = 20; }))),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Mais filtros'),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _filterField(_country, 'Pais'),
                  _filterField(_city, 'Cidade'),
                  _filterField(_language, 'Idioma'),
                  _filterField(_experience, 'Nivel'),
                  _filterField(_salary, 'Salario minimo'),
                ],
              ),
            ],
          ),
        ])),
        Expanded(child: jobs.isEmpty ? const _EmptyJobs() : ListView.separated(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), itemCount: jobs.length > _visible ? _visible + 1 : jobs.length, itemBuilder: (context, index) {
          if (index == _visible) return Center(child: TextButton(onPressed: () => setState(() => _visible += 20), child: const Text('Carregar mais vagas')));
          final job = jobs[index];
          return _JobTile(job: job, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => JobDetailPage(job: job, repository: widget.repository, resumeRepository: widget.resumeRepository))));
        }, separatorBuilder: (_, _) => const SizedBox(height: 10))),
      ])));
    },
  ));

  Widget _filterField(TextEditingController controller, String label) => SizedBox(
        width: 220,
        child: TextField(
          controller: controller,
          onChanged: (_) => setState(() => _visible = 20),
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );
}

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job, required this.onTap});
  final JobPosting job;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, title: Text(job.title), subtitle: Text('${job.company} | ${job.location}\n${job.workMode}${job.salary == null ? '' : ' | ${job.salary}'}'), isThreeLine: true, trailing: const Icon(Icons.chevron_right)));
}

class _EmptyJobs extends StatelessWidget {
  const _EmptyJobs();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.travel_explore, size: 42), SizedBox(height: 12), Text('Nenhuma vaga encontrada.'), SizedBox(height: 4), Text('As vagas aparecem aqui assim que uma fonte autorizada for sincronizada.', textAlign: TextAlign.center)])));
}

class _JobError extends StatelessWidget {
  const _JobError();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Nao foi possivel carregar as vagas. Verifique sua conexao e tente novamente.', textAlign: TextAlign.center)));
}