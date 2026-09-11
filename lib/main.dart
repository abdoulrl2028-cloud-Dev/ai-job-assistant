import 'package:flutter/material.dart';

import 'application_repository.dart';
import 'applications_page.dart';

void main() => runApp(const AiJobAssistantApp());

class AiJobAssistantApp extends StatelessWidget {
  const AiJobAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Job Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A7265),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F4),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ApplicationRepository _applicationRepository = ApplicationRepository();

  @override
  void dispose() {
    _applicationRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardPage(),
      ApplicationsPage(repository: _applicationRepository),
      _comingSoon('Documentos'),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showMessage('Adicao de candidatura em breve.'),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.work_outline), selectedIcon: Icon(Icons.work), label: 'Candidaturas'),
          NavigationDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: 'Documentos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _comingSoon(String title) => Center(child: Text(title, style: Theme.of(context).textTheme.titleLarge));

  void _showMessage(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage('web/icons/Neon Tech Portrait Avatar.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ola, Camille', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Sua busca esta ganhando ritmo.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Esta semana', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 acoes concluidas de 5', style: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: 0.6, minHeight: 8, color: const Color(0xFFE6B75F), backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.22)),
                const SizedBox(height: 12),
                Text('Faltam duas acoes para a sua meta.', style: TextStyle(color: colorScheme.onPrimary.withValues(alpha: 0.86))),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('A tratar', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          const ApplicationCard(company: 'Atelier Nova', role: 'Product Designer', detail: 'Entrevista amanha, 10:00', color: Color(0xFFE6B75F)),
          const SizedBox(height: 10),
          const ApplicationCard(company: 'Metrik', role: 'UX/UI Designer', detail: 'Follow-up na sexta-feira', color: Color(0xFF93B9F5)),
          const SizedBox(height: 10),
          const ApplicationCard(company: 'Lumen Studio', role: 'Brand Designer', detail: 'Candidatura ate 18 set.', color: Color(0xFFE89B8C)),
        ],
      ),
    );
  }
}

class ApplicationCard extends StatelessWidget {
  const ApplicationCard({super.key, required this.company, required this.role, required this.detail, required this.color});

  final String company;
  final String role;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: color, child: Text(company.substring(0, 1))),
        title: Text(company),
        subtitle: Text('$role\n$detail'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Set<String> _cloudSkills = {};
  final Map<String, String?> _answers = {};

  static const cloudOptions = [
    'Azure: App Service, Functions, Service Bus, Event Grid, Key Vault, Blob Storage, Application Insights',
    'AWS: ECS, EC2, S3, Lambda, RDS, Developer Tools',
    'GCP: Cloud Run, Compute Engine, Cloud SQL',
    'Kubernetes: AKS, EKS, GKE',
  ];

  static const questions = [
    _Question('CI/CD', 'Qual sua familiaridade com pipelines de CI/CD?', [
      'Nunca utilizei CI/CD',
      'Acompanho pipelines criados por outras pessoas',
      'Configuro pipelines simples: build, test e deploy basico',
      'Trabalho com pipelines, ambientes dev/staging/prod e gates de qualidade',
      'Configuro quality gates, blue-green, canary e rollback automatizado',
    ]),
    _Question('Testes', 'Qual sua experiencia com testes?', [
      'Escrevo testes pontuais apenas quando exigido pelo time',
      'Escrevo testes unitarios como rotina, sem integracao ou API',
      'Escrevo testes unitarios, integracao e API desde o desenho da solucao',
      'Pratico TDD em cenarios criticos e uso cobertura como parte do design',
    ]),
    _Question('Docker', 'Qual sua experiencia com Docker e containerizacao?', [
      'Nunca utilizei Docker',
      'Uso Docker apenas para rodar projetos localmente com docker-compose up',
      'Crio Dockerfiles, multi-stage builds e otimizo imagens para producao',
      'Trabalho com orquestracao, health checks, resource limits e redes',
      'Configuro build de imagens, seguranca de containers e otimizacao avancada',
    ]),
    _Question('PostgreSQL', 'Qual sua experiencia com PostgreSQL ou bancos relacionais?', [
      'Apenas CRUD basico com ORM',
      'Modelo tabelas e escrevo queries sem foco em performance',
      'Faco modelagem, indices, planos de execucao e otimizacao de queries',
      'Desenhei schemas, particionamento, replicas e escalabilidade',
      'Faco tuning, migracoes zero-downtime e monitoramento de queries lentas',
    ]),
    _Question('Observabilidade', 'Qual sua experiencia com observabilidade e monitoramento?', [
      'Configuro logs estruturados, metricas basicas e alertas simples',
      'Trabalho com APM, tracing distribuido e metricas customizadas',
      'Desenho observabilidade com RED/USE, SLOs, dashboards e post-mortems',
    ]),
    _Question('Eventos', 'Qual sua experiencia com arquitetura orientada a eventos e mensageria?', [
      'Trabalho com Service Bus, Event Grid, RabbitMQ ou Kafka em integracoes',
      'Desenho arquitetura event-driven com CQRS, DLQ e idempotencia',
      'Implemento streaming e processamento assincrono em larga escala',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundImage: AssetImage('web/icons/Neon Tech Portrait Avatar.png'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Perfil tecnico', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Informe suas experiencias para receber oportunidades mais relevantes.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Cloud e ambientes de deploy', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...cloudOptions.map((skill) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _cloudSkills.contains(skill),
                title: Text(skill),
                onChanged: (selected) => setState(() => selected == true ? _cloudSkills.add(skill) : _cloudSkills.remove(skill)),
              )),
          const Divider(height: 32),
          ...questions.map((question) => _ExperienceField(
                question: question,
                value: _answers[question.id],
                onChanged: (value) => setState(() => _answers[question.id] = value),
              )),
          const SizedBox(height: 4),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Salvar experiencias')),
        ],
      ),
    );
  }

  void _save() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencias salvas no seu perfil.')));
}

class _ExperienceField extends StatelessWidget {
  const _ExperienceField({required this.question, required this.value, required this.onChanged});

  final _Question question;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: question.label, border: const OutlineInputBorder()),
        items: question.options.map((option) => DropdownMenuItem(value: option, child: Text(option, maxLines: 2, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Question {
  const _Question(this.id, this.label, this.options);

  final String id;
  final String label;
  final List<String> options;
}
