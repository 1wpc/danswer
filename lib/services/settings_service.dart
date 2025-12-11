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

    _selectedModel = _prefs.getString(_modelKey) ?? 'gpt-4o';
    _selectedProviderId = _prefs.getString(_providerIdKey) ?? 'openai';
    _localeCode = _prefs.getString(_localeKey) ?? 'zh';
    
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
        id: 'deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com',
        models: ['deepseek-chat', 'deepseek-coder'],
      ),
      ProviderConfig(
        id: 'siliconflow',
        name: 'SiliconFlow',
        baseUrl: 'https://api.siliconflow.cn/v1',
        models: ['Qwen/Qwen2.5-7B-Instruct', 'Qwen/Qwen2.5-72B-Instruct', 'deepseek-ai/DeepSeek-V2.5'],
      ),
      ProviderConfig(
        id: 'moonshot',
        name: 'Moonshot',
        baseUrl: 'https://api.moonshot.cn/v1',
        models: ['moonshot-v1-8k', 'moonshot-v1-32k'],
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
        name: 'Doubao (Volcengine)',
        baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
        models: ['doubao-pro-4k', 'doubao-lite-4k', 'doubao-pro-32k', 'doubao-lite-32k'],
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
