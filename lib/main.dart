import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'application_repository.dart';
import 'applications_page.dart';
import 'auth_page.dart';
import 'documents_page.dart';
import 'job_repository.dart';
import 'jobs_page.dart';
import 'plans_page.dart';
import 'subscription_repository.dart';
import 'resume_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isNotEmpty && key.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: key);
  }
  runApp(AiJobAssistantApp(client: url.isEmpty || key.isEmpty ? null : Supabase.instance.client));
}

class AiJobAssistantApp extends StatelessWidget {
  const AiJobAssistantApp({super.key, this.client});

  final SupabaseClient? client;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'AI Job Assistant',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7265)),
      scaffoldBackgroundColor: const Color(0xFFF6F7F4),
      useMaterial3: true,
    ),
    home: client == null ? const BackendSetupPage() : AuthGate(client: client!),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.client});

  final SupabaseClient client;

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: client.auth.onAuthStateChange,
    builder: (context, _) => client.auth.currentSession == null ? AuthPage(client: client) : HomePage(client: client),
  );
}

class BackendSetupPage extends StatelessWidget {
  const BackendSetupPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Configure SUPABASE_URL e SUPABASE_ANON_KEY para conectar sua conta, candidaturas e assinaturas.', textAlign: TextAlign.center),
        ),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.client});

  final SupabaseClient client;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final ApplicationRepository _applications = ApplicationRepository(widget.client);
  late final SubscriptionRepository _subscriptions = SubscriptionRepository(widget.client);
  late final JobRepository _jobs = JobRepository(widget.client);
  late final ResumeRepository _resumes = ResumeRepository(widget.client);

  static const _destinations = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard, 'Inicio'),
    (Icons.travel_explore_outlined, Icons.travel_explore, 'Vagas'),
    (Icons.work_outline, Icons.work, 'Candidaturas'),
    (Icons.description_outlined, Icons.description, 'Documentos'),
    (Icons.person_outline, Icons.person, 'Perfil'),
    (Icons.workspace_premium_outlined, Icons.workspace_premium, 'Planos'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardPage(),
      JobsPage(repository: _jobs, resumeRepository: _resumes),
      ApplicationsPage(repository: _applications),
      DocumentsPage(repository: _resumes),
      const ProfilePage(),
      PlansPage(repository: _subscriptions),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final content = IndexedStack(index: _selectedIndex, children: pages);
        return Scaffold(
          body: compact ? content : Row(children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: _select,
              destinations: _destinations.map((item) => NavigationRailDestination(icon: Icon(item.$1), selectedIcon: Icon(item.$2), label: Text(item.$3))).toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ]),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  destinations: _destinations.map((item) => NavigationDestination(icon: Icon(item.$1), selectedIcon: Icon(item.$2), label: item.$3)).toList(),
                )
              : null,
        );
      },
    );
  }

  void _select(int index) => setState(() => _selectedIndex = index);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Text('AI Job Assistant', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Organize candidaturas, acompanhe oportunidades e desenvolva seu perfil profissional.'),
        ]),
      ),
    ),
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Set<String> _cloudSkills = {};
  final Map<String, String?> _answers = {};

  static const _cloudOptions = [
    'Azure: App Service, Functions, Service Bus, Event Grid, Key Vault, Blob Storage, Application Insights',
    'AWS: ECS, EC2, S3, Lambda, RDS, Developer Tools',
    'GCP: Cloud Run, Compute Engine, Cloud SQL',
    'Kubernetes: AKS, EKS, GKE',
  ];

  static const _questions = [
    ('CI/CD', 'Qual sua familiaridade com pipelines de CI/CD?', ['Nunca utilizei CI/CD', 'Acompanho pipelines criados por outras pessoas', 'Configuro pipelines simples: build, test e deploy basico', 'Trabalho com pipelines, ambientes dev/staging/prod e gates de qualidade', 'Configuro quality gates, blue-green, canary e rollback automatizado']),
    ('Testes', 'Qual sua experiencia com testes?', ['Escrevo testes pontuais apenas quando exigido pelo time', 'Escrevo testes unitarios como rotina, sem integracao ou API', 'Escrevo testes unitarios, integracao e API desde o desenho da solucao', 'Pratico TDD em cenarios criticos e uso cobertura como parte do design']),
    ('Docker', 'Qual sua experiencia com Docker e containerizacao?', ['Nunca utilizei Docker', 'Uso Docker apenas para rodar projetos localmente com docker-compose up', 'Crio Dockerfiles, multi-stage builds e otimizo imagens para producao', 'Trabalho com orquestracao, health checks, resource limits e redes', 'Configuro build de imagens, seguranca de containers e otimizacao avancada']),
    ('PostgreSQL', 'Qual sua experiencia com PostgreSQL ou bancos relacionais?', ['Apenas CRUD basico com ORM', 'Modelo tabelas e escrevo queries sem foco em performance', 'Faco modelagem, indices, planos de execucao e otimizacao de queries', 'Desenhei schemas, particionamento, replicas e escalabilidade', 'Faco tuning, migracoes zero-downtime e monitoramento de queries lentas']),
    ('Observabilidade', 'Qual sua experiencia com observabilidade e monitoramento?', ['Configuro logs estruturados, metricas basicas e alertas simples', 'Trabalho com APM, tracing distribuido e metricas customizadas', 'Desenho observabilidade com RED/USE, SLOs, dashboards e post-mortems']),
    ('Eventos', 'Qual sua experiencia com arquitetura orientada a eventos e mensageria?', ['Trabalho com Service Bus, Event Grid, RabbitMQ ou Kafka em integracoes', 'Desenho arquitetura event-driven com CQRS, DLQ e idempotencia', 'Implemento streaming e processamento assincrono em larga escala']),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const CircleAvatar(radius: 32, backgroundImage: AssetImage('web/icons/Neon Tech Portrait Avatar.png')),
          const SizedBox(height: 16),
          Text('Perfil tecnico', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Mantenha suas experiencias atualizadas para receber oportunidades mais relevantes.'),
          const SizedBox(height: 24),
          Text('Cloud e ambientes de deploy', style: Theme.of(context).textTheme.titleMedium),
          ..._cloudOptions.map((skill) => CheckboxListTile(contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: _cloudSkills.contains(skill), title: Text(skill), onChanged: (selected) => setState(() => selected == true ? _cloudSkills.add(skill) : _cloudSkills.remove(skill)))),
          const Divider(height: 32),
          ..._questions.map((question) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: DropdownButtonFormField<String>(
              initialValue: _answers[question.$1],
              isExpanded: true,
              decoration: InputDecoration(labelText: question.$2, border: const OutlineInputBorder()),
              items: question.$3.map((option) => DropdownMenuItem(value: option, child: Text(option, maxLines: 2, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (value) => setState(() => _answers[question.$1] = value),
            ),
          )),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check), label: const Text('Salvar experiencias')),
        ]),
      ),
    ),
  );

  void _save() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Experiencias salvas no seu perfil.')));
}
