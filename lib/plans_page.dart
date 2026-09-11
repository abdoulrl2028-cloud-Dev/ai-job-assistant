import 'package:flutter/material.dart';

import 'subscription_repository.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key, required this.repository});

  final SubscriptionRepository? repository;

  @override
  Widget build(BuildContext context) {
    if (repository == null) return const _BillingConfigurationRequired();
    return StreamBuilder<SubscriptionInfo>(
      stream: repository!.watchCurrentSubscription(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _BillingError(message: 'Nao foi possivel consultar sua assinatura.');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return _PlansContent(subscription: snapshot.data!, repository: repository!);
      },
    );
  }
}

class _PlansContent extends StatelessWidget {
  const _PlansContent({required this.subscription, required this.repository});

  final SubscriptionInfo subscription;
  final SubscriptionRepository repository;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Text('Planos e assinatura', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          _SubscriptionStatus(subscription: subscription),
          const SizedBox(height: 24),
          const _PlanCard(title: 'Plano Gratis', price: 'R\$ 0', features: ['Cadastro gratuito', 'Compatibilidade de vagas', 'Mensagem para recrutador', 'Acompanhamento de candidatura', '5 candidaturas visualizadas']),
          const SizedBox(height: 12),
          _PlanCard(title: 'Plano Premium', price: 'R\$ 19,90/mes', highlighted: true, features: const ['Mais candidaturas', 'Alertas de novas vagas', 'Filtros avancados', 'Recursos de IA', 'Analise de curriculo', 'Mensagens para recrutadores'], onSubscribe: () => _subscribe(context, 'premium')),
          const SizedBox(height: 12),
          _PlanCard(title: 'Plano Pro', price: 'R\$ 39,90/mes', features: const ['Tudo do Premium', 'IA para adaptar curriculo', 'Compatibilidade com a vaga', 'Candidatura automatica', 'Relatorios de desempenho'], onSubscribe: () => _subscribe(context, 'pro')),
          if (subscription.planId != 'free') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => _manage(context), icon: const Icon(Icons.settings), label: const Text('Gerenciar assinatura')),
          ],
          const SizedBox(height: 24),
          Text('Recursos bloqueados', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...['Analise de curriculo por IA', 'Filtros avancados', 'Alertas de novas vagas'].map((feature) => ListTile(leading: Icon(subscription.hasPremiumAccess ? Icons.check_circle : Icons.lock_outline), title: Text(feature))),
        ],
      ),
    );
  }

  Future<void> _subscribe(BuildContext context, String planId) async {
    try {
      await repository.startCheckout(planId);
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _manage(BuildContext context) async {
    try {
      await repository.openCustomerPortal();
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.title, required this.price, required this.features, this.highlighted = false, this.onSubscribe});
  final String title;
  final String price;
  final List<String> features;
  final bool highlighted;
  final VoidCallback? onSubscribe;
  @override
  Widget build(BuildContext context) => Card(
    color: highlighted ? Theme.of(context).colorScheme.primaryContainer : null,
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge), Text(price, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 10),
      ...features.map((feature) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text('• $feature'))),
      if (onSubscribe != null) ...[const SizedBox(height: 12), FilledButton(onPressed: onSubscribe, child: const Text('Assinar Premium'))],
    ])),
  );
}

class _SubscriptionStatus extends StatelessWidget {
  const _SubscriptionStatus({required this.subscription});
  final SubscriptionInfo subscription;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Status: ${subscription.status}', style: Theme.of(context).textTheme.titleMedium),
    Text('Plano atual: ${subscription.planId.toUpperCase()}'),
    if (subscription.startsAt != null) Text('Inicio: ${_date(subscription.startsAt!)}'),
    if (subscription.expiresAt != null) Text('Vencimento: ${_date(subscription.expiresAt!)}'),
  ])));
  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _BillingConfigurationRequired extends StatelessWidget {
  const _BillingConfigurationRequired();
  @override
  Widget build(BuildContext context) => const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Assinaturas indisponiveis ate o backend seguro ser configurado.')));
}

class _BillingError extends StatelessWidget {
  const _BillingError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}