import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'AI Homework Solver',
      'settings': 'Settings',
      'takePhoto': 'Take Photo',
      'pickGallery': 'Pick from Gallery',
      'cropProblem': 'Crop Problem',
      'solve': 'Solve',
      'solution': 'Solution',
      'thinking': 'Thinking...',
      'error': 'Error',
      'retry': 'Retry',
      'apiKeyRequired': 'Please set your API Key in Settings first.',
      'apiConfig': 'API Configuration',
      'apiKey': 'API Key',
      'apiKeyHint': 'Enter your OpenAI or compatible API Key',
      'baseUrl': 'Base URL',
      'baseUrlHint': 'e.g., https://api.openai.com/v1',
      'modelName': 'Model Name',
      'modelNameHint': 'e.g., gpt-4o, gpt-4-turbo',
      'systemPrompt': 'System Prompt',
      'systemPromptHint': 'Instructions for the AI tutor',
      'save': 'Save',
      'saved': 'Settings saved successfully',
      'rotate': 'Rotate',
      'failedToPick': 'Failed to pick image',
      'failedToCrop': 'Failed to crop image',
      'currentModel': 'Current Model',
      'language': 'Language',
      'english': 'English',
      'chinese': 'Chinese',
      'history': 'History',
      'noHistory': 'No history records found',
      'delete': 'Delete',
      'deleteConfirm': 'Are you sure you want to delete this record?',
      'clearHistoryConfirm': 'Are you sure you want to clear all history?',
      'cancel': 'Cancel',
      'welcomeMessage': 'Select a model and take a photo to solve',
      'quote': 'Quote',
    },
    'zh': {
      'appTitle': 'AI 作业助手',
      'settings': '设置',
      'takePhoto': '拍照',
      'pickGallery': '从相册选择',
      'cropProblem': '裁剪题目',
      'solve': '解答',
      'solution': '解答结果',
      'thinking': '思考中...',
      'error': '错误',
      'retry': '重试',
      'apiKeyRequired': '请先在设置中配置 API Key',
      'apiConfig': 'API 配置',
      'apiKey': 'API 密钥',
      'apiKeyHint': '请输入 OpenAI 或兼容的 API Key',
      'baseUrl': 'Base URL',
      'baseUrlHint': '例如：https://api.openai.com/v1',
      'modelName': '模型名称',
      'modelNameHint': '例如：gpt-4o, gpt-4-turbo',
      'systemPrompt': '系统提示词',
      'systemPromptHint': '给 AI 导师的指令',
      'save': '保存',
      'saved': '设置已保存',
      'rotate': '旋转',
      'failedToPick': '选择图片失败',
      'failedToCrop': '裁剪图片失败',
      'currentModel': '当前模型',
      'language': '语言',
      'english': '英文',
      'chinese': '中文',
      'history': '历史记录',
      'noHistory': '暂无历史记录',
      'delete': '删除',
      'deleteConfirm': '确定要删除这条记录吗？',
      'clearHistoryConfirm': '确定要清空所有历史记录吗？',
      'cancel': '取消',
      'welcomeMessage': '选择模型并拍照解题',
      'quote': '引用',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
