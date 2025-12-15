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
      'appTitle': 'Danswer - Your AI Tutor',
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
      'quotePrefix': 'Based on the following text:',
      'knowledgePoints': 'Knowledge Points',
      'viewKnowledgePoints': 'View Knowledge Points',
      'analyzing': 'Analyzing...',
      'crossPageCapture': 'Cross-page Capture',
      'addAnotherPage': 'Add another page?',
      'pageAdded': 'Page added. Total: ',
      'addPage': 'Add Page',
      'finish': 'Finish',
      'stitching': 'Stitching images...',
      'failedToStitch': 'Failed to stitch images',
      'subscriptionAndUsage': 'Subscription & Usage',
      'currentUsage': 'Current Usage',
      'queriesUsed': 'queries used',
      'currentTier': 'Current Tier',
      'upgradePlan': 'Upgrade Plan',
      'basicPlan': 'Basic Plan',
      'premiumPlan': 'Premium Plan',
      'month': 'month',
      'queriesPerMonth': 'Queries / Month',
      'standardSpeed': 'Standard Speed',
      'accessGemini': 'Access to Gemini 1.5 Pro',
      'fastSpeed': 'Fast Speed',
      'prioritySupport': 'Priority Support',
      'currentPlan': 'Current Plan',
      'subscribe': 'Subscribe',
      'paymentSuccess': 'Payment Successful! Please refresh to see changes.',
      'paymentFailed': 'Payment Failed: ',
    },
    'zh': {
      'appTitle': '答达——你的AI家教',
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
      'quotePrefix': '基于以下内容：',
      'knowledgePoints': '知识点',
      'viewKnowledgePoints': '查看知识点',
      'analyzing': '分析中...',
      'crossPageCapture': '拍跨页题',
      'addAnotherPage': '添加下一页？',
      'pageAdded': '已添加。共 ',
      'addPage': '添加页',
      'finish': '完成',
      'stitching': '正在拼合图片...',
      'failedToStitch': '拼合图片失败',
      'subscriptionAndUsage': '订阅与用量',
      'currentUsage': '当前用量',
      'queriesUsed': '次已使用',
      'currentTier': '当前等级',
      'upgradePlan': '升级计划',
      'basicPlan': '基础版',
      'premiumPlan': '高级版',
      'month': '月',
      'queriesPerMonth': '次查询 / 月',
      'standardSpeed': '标准速度',
      'accessGemini': '使用 Gemini 1.5 Pro',
      'fastSpeed': '快速响应',
      'prioritySupport': '优先支持',
      'currentPlan': '当前计划',
      'subscribe': '订阅',
      'paymentSuccess': '支付成功！请刷新查看变更。',
      'paymentFailed': '支付失败：',
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
