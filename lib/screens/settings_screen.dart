import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../models/provider_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _promptController;
  
  // Maps to store controllers for each provider
  final Map<String, TextEditingController> _apiKeyControllers = {};
  final Map<String, TextEditingController> _baseUrlControllers = {};

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _promptController = TextEditingController(text: settings.systemPrompt);
    
    // Initialize controllers for each provider
    for (var provider in settings.providers) {
      _apiKeyControllers[provider.id] = TextEditingController(text: provider.apiKey);
      _baseUrlControllers[provider.id] = TextEditingController(text: provider.baseUrl);
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    for (var controller in _apiKeyControllers.values) {
      controller.dispose();
    }
    for (var controller in _baseUrlControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      final settings = context.read<SettingsService>();
      
      // Save prompt
      await settings.setSystemPrompt(_promptController.text);
      
      // Save each provider config
      for (var provider in settings.providers) {
        final apiKey = _apiKeyControllers[provider.id]?.text.trim();
        final baseUrl = _baseUrlControllers[provider.id]?.text.trim();
        
        await settings.updateProviderConfig(
          provider.id,
          apiKey: apiKey,
          baseUrl: baseUrl,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('saved'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.get('language'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: settings.locale.languageCode,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text(l10n.get('english')),
                      ),
                      DropdownMenuItem(
                        value: 'zh',
                        child: Text(l10n.get('chinese')),
                      ),
                    ],
                    onChanged: (String? newValue) async {
                      if (newValue != null) {
                        await settings.setLocale(newValue);
                        if (mounted) {
                          setState(() {
                            _promptController.text = settings.systemPrompt;
                          });
                        }
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                l10n.get('apiConfig'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              ...settings.providers.map((provider) => _buildProviderCard(provider, l10n)),

              const SizedBox(height: 24),
              Text(
                l10n.get('systemPrompt'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _promptController,
                decoration: InputDecoration(
                  labelText: l10n.get('systemPrompt'),
                  border: const OutlineInputBorder(),
                  helperText: l10n.get('systemPromptHint'),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ProviderConfig provider, AppLocalizations l10n) {
    // Ensure controllers exist (in case new providers were added dynamically or hot reload)
    if (!_apiKeyControllers.containsKey(provider.id)) {
      _apiKeyControllers[provider.id] = TextEditingController(text: provider.apiKey);
      _baseUrlControllers[provider.id] = TextEditingController(text: provider.baseUrl);
    }

    final isConfigured = _apiKeyControllers[provider.id]?.text.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(provider.name),
        subtitle: Text(
          isConfigured ? l10n.get('configured') : l10n.get('notConfigured'),
          style: TextStyle(
            color: isConfigured ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        leading: Icon(
          Icons.api,
          color: isConfigured ? Colors.blue : Colors.grey,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextFormField(
                  controller: _apiKeyControllers[provider.id],
                  decoration: InputDecoration(
                    labelText: '${provider.name} ${l10n.get('apiKey')}',
                    border: const OutlineInputBorder(),
                    helperText: l10n.get('apiKeyHint'),
                  ),
                  obscureText: true,
                  onChanged: (value) {
                    setState(() {}); // Update subtitle
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _baseUrlControllers[provider.id],
                  decoration: InputDecoration(
                    labelText: l10n.get('baseUrl'),
                    border: const OutlineInputBorder(),
                    helperText: l10n.get('baseUrlHint'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
