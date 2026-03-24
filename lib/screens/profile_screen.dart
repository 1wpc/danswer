import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'auth_screen.dart';
import 'subscription_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final authService = context.watch<AuthService>();
    final isLoggedIn = authService.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('profile')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // User Info / Login Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                if (!isLoggedIn) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        isLoggedIn ? Icons.person : Icons.person_outline,
                        size: 32,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn 
                                ? (authService.user?.email ?? l10n.get('userInfo'))
                                : l10n.get('signInWithGoogle'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isLoggedIn) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.get('currentPlan'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isLoggedIn) const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Menu Items
          Text(
            l10n.get('settings'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(l10n.get('history')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: Text(l10n.get('subscriptionAndUsage')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (isLoggedIn) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l10n.get('settings')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          
          if (isLoggedIn) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.get('logout')),
                    content: Text(l10n.get('logoutConfirm')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.get('cancel')),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        child: Text(l10n.get('logout')),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await authService.signOut();
                }
              },
              icon: Icon(Icons.logout, color: colorScheme.error),
              label: Text(
                l10n.get('logout'),
                style: TextStyle(color: colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
