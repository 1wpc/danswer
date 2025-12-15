import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tobias/tobias.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authService = context.watch<AuthService>();
    final profile = authService.profile;
    final currentTier = profile?['subscription_tier'] ?? 'free';
    final usageCount = profile?['usage_count'] ?? 0;
    final usageLimit = profile?['usage_limit'] ?? 5;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('subscriptionAndUsage'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Usage Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(l10n.get('currentUsage'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: usageCount / usageLimit),
                    const SizedBox(height: 8),
                    Text('$usageCount / $usageLimit ${l10n.get('queriesUsed')}'),
                    const SizedBox(height: 8),
                    Text('${l10n.get('currentTier')}: ${currentTier.toUpperCase()}', 
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.get('upgradePlan'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            _buildPlanCard(
              context,
              l10n,
              title: l10n.get('basicPlan'),
              price: '¥35/${l10n.get('month')}',
              features: ['100 ${l10n.get('queriesPerMonth')}', l10n.get('standardSpeed'), l10n.get('accessGemini')],
              priceId: 'basic', 
              isCurrent: currentTier == 'basic',
            ),
            _buildPlanCard(
              context,
              l10n,
              title: l10n.get('premiumPlan'),
              price: '¥140/${l10n.get('month')}',
              features: ['500 ${l10n.get('queriesPerMonth')}', l10n.get('fastSpeed'), l10n.get('prioritySupport')],
              priceId: 'premium', 
              isCurrent: currentTier == 'premium',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, AppLocalizations l10n, {
    required String title,
    required String price,
    required List<String> features,
    required String priceId,
    required bool isCurrent,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent ? BorderSide(color: Theme.of(context).primaryColor, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(f),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(onPressed: null, child: Text(l10n.get('currentPlan')))
                  : FilledButton(
                      onPressed: () => _subscribe(context, l10n, priceId),
                      child: Text(l10n.get('subscribe')),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribe(BuildContext context, AppLocalizations l10n, String priceId) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'create-alipay-order',
        body: {
          'priceId': priceId,
        },
      );
      
      final data = res.data;
      if (data != null && data['orderStr'] != null) {
        final orderStr = data['orderStr'];
        // Call Alipay
        final result = await Tobias().pay(orderStr);
        
        if (!context.mounted) return;

        // Result status 9000 means success
        if (result['resultStatus'] == '9000') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('paymentSuccess'))),
          );
          // Trigger a refresh of the user profile if possible
          context.read<AuthService>().refreshProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.get('paymentFailed')}${result['memo']}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.get('error')}: $e')));
      }
    }
  }
}
