import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:markdown/markdown.dart' as md;
import '../services/ai_service.dart';
import '../services/settings_service.dart';
import '../l10n/app_localizations.dart';
import '../services/history_service.dart';
import '../services/mistake_service.dart';
import '../widgets/knowledge_points_sheet.dart';
import '../utils/latex_builder.dart';

class ResultScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? initialSolution;
  final String? initialModel;
  final String? historyId;
  final List<Map<String, dynamic>>? initialChatHistory;
  final String? initialKnowledgePoints;

  const ResultScreen({
    super.key, 
    required this.imageBytes,
    this.initialSolution,
    this.initialModel,
    this.historyId,
    this.initialChatHistory,
    this.initialKnowledgePoints,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();

  static Widget buildMarkdown(BuildContext context, String data) {
    final theme = Theme.of(context);
    return SelectionArea(
      child: MarkdownBody(
        data: data,
        selectable: false,
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
        fitContent: true,
      ),
    );
  }
}

class _ResultScreenState extends State<ResultScreen> {
  final AIService _aiService = AIService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _chatController = TextEditingController();
  
  // ignore: cancel_subscriptions
  StreamSubscription? _subscription;
  
  String _solutionText = '';
  bool _isLoading = true;
  String? _errorMessage;
  
  // Chat state
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isChatActive = false;
  bool _isSendingFollowUp = false;
  String? _quotedText;
  
  // Model info
  String _currentModel = '';
  String? _currentHistoryId;
  String? _knowledgePoints;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.initialModel ?? '';
    _currentHistoryId = widget.historyId;
    _knowledgePoints = widget.initialKnowledgePoints;
    
    if (widget.initialSolution != null) {
      _initializeWithSolution(widget.initialSolution!);
    } else {
      _startSolving();
    }
  }

  Future<void> _initializeWithSolution(String solution) async {
    setState(() {
      _solutionText = solution;
      _isLoading = false;
      _isChatActive = true;
    });

    final settings = context.read<SettingsService>();
    
    // Use stored chat history if available
    if (widget.initialChatHistory != null && widget.initialChatHistory!.isNotEmpty) {
      setState(() {
        _chatHistory = List<Map<String, dynamic>>.from(widget.initialChatHistory!);
      });
      return;
    }

    try {
      final base64Image = base64Encode(widget.imageBytes);
      final String mimeType = 'image/jpeg';

      setState(() {
        _chatHistory = [
          {
            'role': 'system',
            'content': settings.systemPrompt,
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Please solve the problem in this image. Use standard LaTeX for math formulas (e.g., \$E=mc^2\$ for inline, \$\$E=mc^2\$\$ for block).',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
            ],
          },
          {
            'role': 'assistant',
            'content': solution,
          },
        ];
      });
    } catch (e) {
      // If image fails to load, we still show the text but chat might be limited
      setState(() {
        _errorMessage = 'Warning: Image could not be loaded for context. $e';
        // Still keep the solution visible
        _chatHistory = [
           {
            'role': 'system',
            'content': settings.systemPrompt,
          },
          {
            'role': 'assistant',
            'content': solution,
          },
        ];
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _startSolving() async {
    final settings = context.read<SettingsService>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _solutionText = '';
      _isChatActive = false;
      _chatHistory = [];
      _currentModel = settings.model;
    });

    // Initialize chat history with system prompt and user image message
    // We need to construct the initial messages here to save them
    try {
      final base64Image = base64Encode(widget.imageBytes);
      final String mimeType = 'image/jpeg';

      _chatHistory = [
        {
          'role': 'system',
          'content': settings.systemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text': 'Please solve the problem in this image. Use standard LaTeX for math formulas (e.g., \$E=mc^2\$ for inline, \$\$E=mc^2\$\$ for block).',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image',
              },
            },
          ],
        },
      ];
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process image: $e';
        _isLoading = false;
      });
      return;
    }

    _subscription?.cancel();
    // We can use the generic streamChat method now, or keep using streamSolveProblem
    // Since streamSolveProblem constructs the message itself, we should use streamChat 
    // to ensure consistency with our _chatHistory.
    
    _subscription = _aiService.streamChat(_chatHistory, settings).listen(
      (chunk) {
        if (!mounted) return;
        setState(() {
          _solutionText += chunk;
          _isLoading = false; 
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _isChatActive = true;
          // Add the complete solution to history
          _chatHistory.add({
            'role': 'assistant',
            'content': _solutionText,
          });
        });
        // Save history when solution is complete
        context.read<HistoryService>().addRecord(
          widget.imageBytes, 
          _solutionText,
          model: _currentModel,
          chatHistory: _chatHistory,
        ).then((id) {
          if (mounted) {
            setState(() {
              _currentHistoryId = id;
            });
          }
        });
      },
    );
  }

  void _sendFollowUp() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    
    // Include quoted text in context if available
    String messageContent = text;
    if (_quotedText != null) {
      final l10n = AppLocalizations.of(context)!;
      messageContent = '${l10n.get('quotePrefix')}\n> ${_quotedText!.replaceAll('\n', '\n> ')}\n\n$text';
    }

    setState(() {
      _quotedText = null; // Clear quote
      
      _chatHistory.add({
        'role': 'user',
        'content': messageContent,
      });
      _chatHistory.add({
        'role': 'assistant',
        'content': '', // Placeholder for streaming response
      });
      _isSendingFollowUp = true;
    });

    final settings = context.read<SettingsService>();
    
    // Create a list for API without the last empty assistant message
    final messagesToSend = List<Map<String, dynamic>>.from(_chatHistory.sublist(0, _chatHistory.length - 1));

    _subscription?.cancel();
    _subscription = _aiService.streamChat(messagesToSend, settings).listen(
      (chunk) {
        if (!mounted) return;
        setState(() {
          // Update the last message (assistant response)
          final lastMsg = _chatHistory.last;
          lastMsg['content'] = (lastMsg['content'] as String) + chunk;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
           // Maybe append error to the message or show snackbar
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: $error')),
           );
           _isSendingFollowUp = false;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isSendingFollowUp = false;
        });
        
        // Update history with new chat messages if we have an ID
        if (_currentHistoryId != null) {
          context.read<HistoryService>().updateRecord(
            _currentHistoryId!,
            chatHistory: _chatHistory,
          );
        }
      },
    );
  }

  void _showKnowledgePoints() {
    final settings = context.read<SettingsService>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => KnowledgePointsSheet(
        existingPoints: _knowledgePoints,
        chatHistory: _chatHistory,
        aiService: _aiService,
        settings: settings,
        onLoaded: (content) {
          setState(() {
            _knowledgePoints = content;
          });
          
          // Save knowledge points to history if we have an ID
          if (_currentHistoryId != null) {
            context.read<HistoryService>().updateRecord(
              _currentHistoryId!,
              knowledgePoints: content,
            );
          }
        },
      ),
    );
  }

  Future<void> _addToMistakeBook() async {
    final l10n = AppLocalizations.of(context)!;
    final mistakeService = context.read<MistakeService>();
    
    try {
      await mistakeService.addMistake(
        widget.imageBytes,
        _solutionText,
        model: _currentModel,
        chatHistory: _chatHistory,
        knowledgePoints: _knowledgePoints,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('addedToMistakeBook'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SelectionArea(
              contextMenuBuilder: (context, selectableRegionState) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems: [
                    ...selectableRegionState.contextMenuButtonItems,
                    ContextMenuButtonItem(
                      onPressed: () async {
                        selectableRegionState.copySelection(SelectionChangedCause.toolbar);
                        final data = await Clipboard.getData(Clipboard.kTextPlain);
                        final text = data?.text;
                        if (text != null && text.isNotEmpty) {
                          setState(() {
                            _quotedText = text;
                          });
                          selectableRegionState.hideToolbar();
                        }
                      },
                      label: l10n.get('quote'),
                    ),
                  ],
                );
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    expandedHeight: 300.0,
                    floating: false,
                    pinned: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.bookmark_border),
                        tooltip: l10n.get('addToMistakeBook'),
                        onPressed: _addToMistakeBook,
                      ),
                      IconButton(
                        icon: const Icon(Icons.lightbulb_outline),
                        tooltip: l10n.get('viewKnowledgePoints'),
                        onPressed: _showKnowledgePoints,
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          GestureDetector(
                            onTap: () => _openFullScreenImage(context),
                            child: Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IgnorePointer(
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black54],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildSliverBody(l10n),
                ],
              ),
            ),
          ),
          if (_isChatActive) _buildChatInput(l10n),
        ],
      ),
    );
  }

  Widget _buildSliverBody(AppLocalizations l10n) {
    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  '${l10n.get('error')}: $_errorMessage',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startSolving,
                  child: Text(l10n.get('retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_solutionText.isEmpty && _isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.get('thinking')),
            ],
          ),
        ),
      );
    }

    // Build the list of content widgets
    List<Widget> contentWidgets = [];
    
    // 1. Always show the initial solution using the document style
    contentWidgets.add(ResultScreen.buildMarkdown(context, _solutionText));
    
    // 2. Show chat history (follow-ups) if available
    if (_chatHistory.isNotEmpty) {
      final firstAssistantIndex = _chatHistory.indexWhere((msg) => msg['role'] == 'assistant');
      
      // If we have an assistant message and there are messages after it
      if (firstAssistantIndex != -1 && firstAssistantIndex < _chatHistory.length - 1) {
        final followUpMessages = _chatHistory.sublist(firstAssistantIndex + 1);
        
        contentWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.chat_bubble_outline, size: 16, color: Theme.of(context).disabledColor),
                ),
                Expanded(child: Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.2))),
              ],
            ),
          ),
        );
        
        contentWidgets.addAll(followUpMessages.map((msg) {
          final role = msg['role'];
          return _buildChatMessage(msg, role == 'user');
        }));
      }
    }

    contentWidgets.add(const SizedBox(height: 80));

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate(contentWidgets),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: MemoryImage(widget.imageBytes),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 4,
          ),
        ),
      ),
    );
  }


  Widget _buildChatMessage(Map<String, dynamic> msg, bool isUser) {
    final content = msg['content'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) 
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              radius: 16,
              child: Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).primaryColor),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isUser
                  ? Text(
                      content,
                      style: const TextStyle(color: Colors.white),
                    )
                  : ResultScreen.buildMarkdown(context, content),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 16,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildChatInput(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_quotedText != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _quotedText!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _quotedText = null),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: InputDecoration(
                      hintText: 'Ask a follow-up question...', // Could be localized
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendFollowUp(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSendingFollowUp ? null : _sendFollowUp,
                  icon: _isSendingFollowUp 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.send, color: Theme.of(context).primaryColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
