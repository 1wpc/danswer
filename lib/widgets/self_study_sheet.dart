import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/latex_builder.dart';

class SelfStudySheet extends StatefulWidget {
  final String? existingContent;
  final List<Map<String, dynamic>> chatHistory;
  final AIService aiService;
  final SettingsService settings;
  final Function(String) onLoaded;

  const SelfStudySheet({
    super.key,
    this.existingContent,
    required this.chatHistory,
    required this.aiService,
    required this.settings,
    required this.onLoaded,
  });

  @override
  State<SelfStudySheet> createState() => _SelfStudySheetState();
}

class _SelfStudySheetState extends State<SelfStudySheet> {
  String _content = '';
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;
  
  String _contentBuffer = '';
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    if (widget.existingContent != null && widget.existingContent!.isNotEmpty) {
      _content = widget.existingContent!;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _analyze();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _analyze() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final l10n = AppLocalizations.of(context)!;
    
    // We only take the problem image/text as context, or we can take the full history.
    // For a good lecture, the full history including the solution might be helpful.
    final messages = List<Map<String, dynamic>>.from(widget.chatHistory);
    
    final isChinese = l10n.locale.languageCode == 'zh';
    
    final prompt = isChinese 
        ? '''你现在是一位顶尖的、极具耐心且擅长启发学生的老师。
你的学生现在遇到了上面这道题，但他/她完全没有学过这门课的基础知识，是个零基础的小白。
请你设计一堂系统性的课程，从零开始，把解答这道题所需要的所有底层知识点和前置概念，用讲课的方式清清楚楚地讲明白。

要求：
1. 不要只是罗列知识点，要像一堂精心设计的真实讲课一样，有引入、有过渡、有总结。
2. 从最基础的概念开始讲起，循序渐进地构建知识体系，直到能够支撑解决这道题的难度。
3. 尽量使用生活中简单易懂的类比来解释抽象概念。
4. 语气要亲切、鼓励，多用互动式的语言（例如“你能想象吗？”、“我们来看看”）。
5. 所有的数学公式必须使用标准的 LaTeX 格式。
6. 在讲课的最后，将学到的这些知识点串联起来，简单回顾一下它们是如何应用到原题目中的。
7. 请使用 Markdown 格式排版，让内容易于阅读。'''
        : '''You are a top-tier, incredibly patient, and inspiring teacher.
Your student has encountered the problem above, but they are a complete beginner with zero foundational knowledge of this subject.
Please design a systematic lecture from scratch, clearly explaining all the underlying knowledge points and prerequisite concepts needed to solve this problem, in a teaching format.

Requirements:
1. Do not just list the knowledge points. Structure it like a well-planned, real lecture with an introduction, smooth transitions, and a conclusion.
2. Start from the most basic concepts and gradually build up the knowledge system until it reaches the level required to solve the problem.
3. Use simple, everyday analogies to explain abstract concepts whenever possible.
4. Keep the tone friendly, encouraging, and conversational (e.g., "Can you imagine?", "Let's take a look").
5. All mathematical formulas MUST use standard LaTeX formatting.
6. At the end of the lecture, connect all the learned concepts and briefly review how they apply to the original problem.
7. Use Markdown formatting to make the content easy to read.''';

    messages.add({
      'role': 'user',
      'content': prompt,
    });

    try {
      _contentBuffer = '';
      _subscription = widget.aiService.streamChat(messages, widget.settings).listen(
        (chunk) {
          if (!mounted) return;
          _contentBuffer += chunk;
          if (_updateTimer == null || !_updateTimer!.isActive) {
            _updateTimer = Timer(const Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _content = _contentBuffer;
                });
              }
            });
          }
        },
        onError: (e) {
          if (!mounted) return;
          _updateTimer?.cancel();
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        },
        onDone: () {
          _updateTimer?.cancel();
          if (!mounted) return;
          setState(() {
            _content = _contentBuffer;
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
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                  Icon(Icons.school, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    l10n.get('viewSelfStudy'),
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
