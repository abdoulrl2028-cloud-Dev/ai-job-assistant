import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.planId,
    required this.status,
    this.startsAt,
    this.expiresAt,
  });

  final String planId;
  final String status;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  bool get hasPremiumAccess => status == 'active' && (planId == 'premium' || planId == 'pro');

  factory SubscriptionInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SubscriptionInfo(planId: 'free', status: 'free');
    return SubscriptionInfo(
      planId: json['plan_id'] as String? ?? 'free',
      status: json['status'] as String? ?? 'free',
      startsAt: DateTime.tryParse(json['current_period_start'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['current_period_end'] as String? ?? ''),
    );
  }
}

class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  Stream<SubscriptionInfo> watchCurrentSubscription() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const SubscriptionInfo(planId: 'free', status: 'free'));
    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) => SubscriptionInfo.fromJson(rows.isEmpty ? null : rows.first));
  }

  Future<void> startCheckout(String planId) async {
    if (_client.auth.currentUser == null) throw StateError('Entre na sua conta para assinar.');
    final response = await _client.functions.invoke('create-checkout', body: {'planId': planId});
    final checkoutUrl = response.data['checkoutUrl'] as String?;
    if (checkoutUrl == null || !await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication)) {
      throw StateError('Nao foi possivel abrir o pagamento.');
    }
  }

  Future<void> openCustomerPortal() async {
    if (_client.auth.currentUser == null) throw StateError('Entre na sua conta para gerenciar a assinatura.');
    final response = await _client.functions.invoke('customer-portal');
    final portalUrl = response.data['portalUrl'] as String?;
    if (portalUrl == null || !await launchUrl(Uri.parse(portalUrl), mode: LaunchMode.externalApplication)) {
      throw StateError('Nao foi possivel abrir o gerenciamento da assinatura.');
    }
  }
}