import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/latex_builder.dart';

class KnowledgePointsSheet extends StatefulWidget {
  final String? existingPoints;
  final List<Map<String, dynamic>> chatHistory;
  final AIService aiService;
  final SettingsService settings;
  final Function(String) onLoaded;

  const KnowledgePointsSheet({
    super.key,
    this.existingPoints,
    required this.chatHistory,
    required this.aiService,
    required this.settings,
    required this.onLoaded,
  });

  @override
  State<KnowledgePointsSheet> createState() => _KnowledgePointsSheetState();
}

class _KnowledgePointsSheetState extends State<KnowledgePointsSheet> {
  String _content = '';
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.existingPoints != null && widget.existingPoints!.isNotEmpty) {
      _content = widget.existingPoints!;
    } else {
      // Use addPostFrameCallback to safely access inherited widgets like AppLocalizations
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyze();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _analyze() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context)!;
    
    // Construct messages
    // We use the existing chat history but append a request for knowledge points
    final messages = List<Map<String, dynamic>>.from(widget.chatHistory);
    
    // Determine language based on locale
    final isChinese = l10n.locale.languageCode == 'zh';
    final prompt = isChinese 
        ? '请分析上述题目和解答，提取其中涉及的关键知识点。请列出知识点名称和简要说明，以Markdown无序列表格式输出。不要包含其他废话。'
        : 'Please analyze the problem and solution above, and extract the key knowledge points (concepts). List them with a brief explanation in Markdown bullet points. Do not include other text.';

    messages.add({
      'role': 'user',
      'content': prompt,
    });

    try {
      _subscription = widget.aiService.streamChat(messages, widget.settings).listen(
        (chunk) {
          if (!mounted) return;
          setState(() {
            _content += chunk;
          });
        },
        onError: (e) {
          if (!mounted) return;
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          widget.onLoaded(_content);
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.lightbulb, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.get('knowledgePoints'),
                    style: theme.textTheme.titleLarge,
                  ),
                  if (_isLoading) ...[
                    const Spacer(),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const Divider(),
              Expanded(
                child: _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _analyze,
                              child: Text(l10n.get('retry')),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        controller: scrollController,
                        child: MarkdownBody(
                          data: _content.isEmpty && _isLoading 
                              ? l10n.get('analyzing') 
                              : _content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                            blockquoteDecoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                            blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          extensionSet: md.ExtensionSet(
                            [
                              ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                            ],
                            [
                              LatexSyntax(),
                              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                            ],
                          ),
                          builders: {
                            'latex': LatexElementBuilder(),
                          },
                          fitContent: false,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
