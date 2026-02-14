import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_config.dart';

class SettingsService with ChangeNotifier {
  static const String _providersKey = 'providers';
  static const String _modelKey = 'model'; // Current selected model ID
  static const String _providerIdKey = 'provider_id'; // Current selected provider ID
  static const String _promptKey = 'system_prompt';
  static const String _localeKey = 'locale';

  late SharedPreferences _prefs;
  bool _initialized = false;

  List<ProviderConfig> _providers = [];
  String _selectedModel = 'gpt-4o';
  String _selectedProviderId = 'openai';
  String _localeCode = 'zh'; // Default to Chinese
  String _systemPrompt = '';

  static const String _defaultPromptEn = '''
You are an expert tutor and problem solver.
When provided with an image of a problem (math, physics, chemistry, etc.):
1. Identify the problem clearly.
2. Solve the problem step-by-step, showing all work.
3. Provide the final answer clearly.
4. Explain the concepts used to solve it.
5. Use LaTeX formatting for all mathematical expressions (e.g., \$x^2\$).
''';

  static const String _defaultPromptZh = '''
你是一位专家级导师和解题能手。
当提供一张问题图片（数学、物理、化学等）时：
1. 清楚地识别问题。
2. 逐步解决问题，展示所有步骤。
3. 清晰地提供最终答案。
4. 解释解题所用的概念。
5. 所有数学表达式使用 LaTeX 格式（例如 \$x^2\$）。
请使用中文回答。
''';

  bool get initialized => _initialized;
  
  List<ProviderConfig> get providers => List.unmodifiable(_providers);
  String get model => _selectedModel;
  String get selectedProviderId => _selectedProviderId;
  
  // Backward compatibility getters
  String get apiKey => _currentProvider?.apiKey ?? '';
  String get baseUrl => _currentProvider?.baseUrl ?? '';
  
  ProviderConfig? get _currentProvider {
    try {
      return _providers.firstWhere((p) => p.id == _selectedProviderId);
    } catch (e) {
      if (_providers.isNotEmpty) return _providers.first;
      return null;
    }
  }

  String get systemPrompt => _systemPrompt;
  Locale get locale => Locale(_localeCode);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load providers
    final String? providersJson = _prefs.getString(_providersKey);
    if (providersJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(providersJson);
        _providers = decoded.map((item) => ProviderConfig.fromMap(item)).toList();
      } catch (e) {
        debugPrint('Error loading providers: $e');
        _initDefaultProviders();
      }
    } else {
      _initDefaultProviders();
      // Try to migrate old settings
      _migrateOldSettings();
    }
    
    // Always check for Doubao updates (name change, model updates)
    await _updateDoubaoConfig();
    // Always check for SiliconFlow updates
    await _updateSiliconFlowConfig();
    // Always check for Moonshot updates
    await _updateMoonshotConfig();
    // Remove deprecated DeepSeek
    await _removeDeprecatedDeepSeek();

    _selectedModel = _prefs.getString(_modelKey) ?? 'gpt-4o';
    _selectedProviderId = _prefs.getString(_providerIdKey) ?? 'openai';
    _localeCode = _prefs.getString(_localeKey) ?? 'zh';
    
    // Safety check: if selected provider is deepseek (which we just removed), reset to openai
    if (_selectedProviderId == 'deepseek') {
      _selectedProviderId = 'openai';
      _selectedModel = 'gpt-4o';
      await _prefs.setString(_providerIdKey, _selectedProviderId);
      await _prefs.setString(_modelKey, _selectedModel);
    }
    
    String? savedPrompt = _prefs.getString(_promptKey);
    if (savedPrompt != null && savedPrompt.isNotEmpty) {
      _systemPrompt = savedPrompt;
    } else {
      _systemPrompt = _localeCode == 'zh' ? _defaultPromptZh : _defaultPromptEn;
    }
    
    _initialized = true;
    notifyListeners();
  }

  void _initDefaultProviders() {
    _providers = [
      ProviderConfig(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        models: ['gpt-4o', 'gpt-4-turbo', 'gpt-3.5-turbo'],
      ),
      ProviderConfig(
        id: 'siliconflow',
        name: 'SiliconFlow',
        baseUrl: 'https://api.siliconflow.cn/v1',
        models: [
          'Pro/moonshotai/Kimi-K2.5',
          'Qwen/Qwen3-VL-32B-Instruct',
          'Qwen/Qwen3-VL-32B-Thinking',
          'Qwen/Qwen3-VL-235B-A22B-Instruct',
          'Qwen/Qwen3-VL-235B-A22B-Thinking',
        ],
      ),
      ProviderConfig(
        id: 'moonshot',
        name: 'Moonshot',
        baseUrl: 'https://api.moonshot.cn/v1',
        models: ['kimi-k2.5'],
      ),
      ProviderConfig(
        id: 'aliyun',
        name: 'Aliyun DashScope',
        baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
        models: ['qwen-plus', 'qwen-max', 'qwen-turbo'],
      ),
      ProviderConfig(
        id: 'gemini',
        name: 'Gemini',
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
        models: ['gemini-3-pro-preview', 'gemini-2.5-flash', 'gemini-2.5-flash-lite', 'gemini-2.5-pro'],
      ),
      ProviderConfig(
        id: 'doubao',
        name: 'Volcengine',
        baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
        models: [
          'doubao-seed-1-6-251015',
          'doubao-seed-1-6-lite-251015',
          'doubao-seed-1-6-flash-250828',
          'doubao-seed-1-8-251228',
        ],
      ),
    ];
  }

  Future<void> _migrateOldSettings() async {
    final String? oldApiKey = _prefs.getString('api_key');
    final String? oldBaseUrl = _prefs.getString('base_url');
    
    if (oldApiKey != null && oldApiKey.isNotEmpty) {
      // Assuming it was OpenAI or Custom
      // If BaseURL is default, put it in OpenAI
      // Otherwise, we might not know which one it is.
      // For simplicity, let's update OpenAI with these values if they exist.
      final index = _providers.indexWhere((p) => p.id == 'openai');
      if (index != -1) {
        _providers[index].apiKey = oldApiKey;
        if (oldBaseUrl != null) {
          _providers[index].baseUrl = oldBaseUrl;
        }
        await _saveProviders();
      }
    }
  }

  Future<void> _updateDoubaoConfig() async {
    final index = _providers.indexWhere((p) => p.id == 'doubao');
    if (index != -1) {
      final provider = _providers[index];
      
      // Update Name
      if (provider.name != 'Volcengine') {
         // Although ProviderConfig fields are final, we might need to replace the object or logic.
         // Actually ProviderConfig fields are NOT final in my search result (apiKey, baseUrl, models are not).
         // But 'name' IS final in the provided search result: `final String name;`
         // So we must replace the ProviderConfig object.
         
         // Let's create a new config with updated name and models
         final newConfig = ProviderConfig(
            id: provider.id,
            name: 'Volcengine',
            apiKey: provider.apiKey,
            baseUrl: provider.baseUrl,
            models: [
              'doubao-seed-1-6-251015',
              'doubao-seed-1-6-lite-251015',
              'doubao-seed-1-6-flash-250828',
              'doubao-seed-1-8-251228',
            ],
         );
         
         _providers[index] = newConfig;
         await _saveProviders();
         
         // Check if we need to update the selected model if it was invalid
         if (_selectedProviderId == 'doubao') {
             // If current selected model is not in the new list, reset it
             if (!newConfig.models.contains(_selectedModel)) {
                 await setModel(newConfig.models.first, 'doubao');
             }
         }
         return; // Done
      }

      // If name was already correct, check if models need update (e.g. user manually changed name but models are old?)
      // Or just standard model update check
      if (provider.models.contains('doubao-pro-4k') || provider.models.isEmpty) {
        provider.models = [
          'doubao-seed-1-6-251015',
          'doubao-seed-1-6-lite-251015',
          'doubao-seed-1-6-flash-250828',
          'doubao-seed-1-8-251228',
        ];
        await _saveProviders();
        
        // Fix selected model if needed
        if (_selectedProviderId == 'doubao') {
             if (!provider.models.contains(_selectedModel)) {
                 await setModel(provider.models.first, 'doubao');
             }
         }
      }
    }
  }

  Future<void> _updateSiliconFlowConfig() async {
    final index = _providers.indexWhere((p) => p.id == 'siliconflow');
    if (index != -1) {
      final provider = _providers[index];
      // Define the expected new models
      final newModels = [
          'Pro/moonshotai/Kimi-K2.5',
          'Qwen/Qwen3-VL-32B-Instruct',
          'Qwen/Qwen3-VL-32B-Thinking',
          'Qwen/Qwen3-VL-235B-A22B-Instruct',
          'Qwen/Qwen3-VL-235B-A22B-Thinking',
      ];
      
      // Check if models need update (simple check: if first model is different or length is different)
      // This logic ensures that if the user hasn't manually customized to something completely different, we update it.
      // Or we can just forcefully update the available models list while keeping API key/Base URL.
      // Since 'models' is a List<String> field in ProviderConfig, we can just update it.
      
      // Let's check if the current model list matches the new one.
      bool needsUpdate = false;
      if (provider.models.length != newModels.length) {
        needsUpdate = true;
      } else {
        for (int i = 0; i < newModels.length; i++) {
          if (provider.models[i] != newModels[i]) {
            needsUpdate = true;
            break;
          }
        }
      }

      if (needsUpdate) {
        provider.models = newModels;
        await _saveProviders();
        
        // Check if currently selected model for this provider is still valid
        if (_selectedProviderId == 'siliconflow') {
             if (!newModels.contains(_selectedModel)) {
                 // Reset to the first model if the selected one is no longer available
                 await setModel(newModels.first, 'siliconflow');
             }
         }
      }
    }
  }

  Future<void> _updateMoonshotConfig() async {
    final index = _providers.indexWhere((p) => p.id == 'moonshot');
    if (index != -1) {
      final provider = _providers[index];
      // Define the expected new models
      final newModels = ['kimi-k2.5'];
      
      // Check if models need update
      bool needsUpdate = false;
      if (provider.models.length != newModels.length) {
        needsUpdate = true;
      } else {
        for (int i = 0; i < newModels.length; i++) {
          if (provider.models[i] != newModels[i]) {
            needsUpdate = true;
            break;
          }
        }
      }

      if (needsUpdate) {
        provider.models = newModels;
        await _saveProviders();
        
        // Check if currently selected model for this provider is still valid
        if (_selectedProviderId == 'moonshot') {
             if (!newModels.contains(_selectedModel)) {
                 // Reset to the first model if the selected one is no longer available
                 await setModel(newModels.first, 'moonshot');
             }
         }
      }
    }
  }

  Future<void> _removeDeprecatedDeepSeek() async {
    final index = _providers.indexWhere((p) => p.id == 'deepseek');
    if (index != -1) {
      _providers.removeAt(index);
      await _saveProviders();
    }
  }

  Future<void> _saveProviders() async {
    final String jsonStr = jsonEncode(_providers.map((p) => p.toMap()).toList());
    await _prefs.setString(_providersKey, jsonStr);
    notifyListeners();
  }

  Future<void> updateProviderConfig(String id, {String? apiKey, String? baseUrl}) async {
    final index = _providers.indexWhere((p) => p.id == id);
    if (index != -1) {
      if (apiKey != null) _providers[index].apiKey = apiKey;
      if (baseUrl != null) _providers[index].baseUrl = baseUrl;
      await _saveProviders();
    }
  }

  Future<void> setModel(String model, String providerId) async {
    _selectedModel = model;
    _selectedProviderId = providerId;
    await _prefs.setString(_modelKey, model);
    await _prefs.setString(_providerIdKey, providerId);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_localeCode == languageCode) return;
    
    _localeCode = languageCode;
    await _prefs.setString(_localeKey, languageCode);
    
    _systemPrompt = languageCode == 'zh' ? _defaultPromptZh : _defaultPromptEn;
    await _prefs.setString(_promptKey, _systemPrompt);
    
    notifyListeners();
  }

  Future<void> setSystemPrompt(String value) async {
    _systemPrompt = value;
    await _prefs.setString(_promptKey, value);
    notifyListeners();
  }
}
