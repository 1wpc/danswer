import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mistake_service.dart';
import '../models/mistake_record.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final List<int> _ebbinghausIntervals = [1, 2, 4, 7, 15, 30];
  bool _isFlipped = false;
  int _currentIndex = 0;
  List<MistakeRecord> _reviewList = [];
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _loadReviewList();
      _isInit = true;
    }
  }

  void _loadReviewList() {
    final mistakeService = Provider.of<MistakeService>(context, listen: false);
    final now = DateTime.now();
    setState(() {
      // Filter items that are due for review (nextReviewTime is before or equal to now)
      _reviewList = mistakeService.items.where((item) {
        return item.nextReviewTime.isBefore(now) || 
               item.nextReviewTime.isAtSameMomentAs(now);
      }).toList();
      _currentIndex = 0;
      _isFlipped = false;
    });
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('data:')) {
      final base64String = path.split(',').last;
      return MemoryImage(base64Decode(base64String));
    } else {
      return FileImage(File(path));
    }
  }

  void _handleReview(bool remembered) async {
    if (_reviewList.isEmpty) return;

    final currentItem = _reviewList[_currentIndex];
    final mistakeService = Provider.of<MistakeService>(context, listen: false);

    int newReviewCount;
    DateTime newNextReviewTime;

    if (remembered) {
      newReviewCount = currentItem.reviewCount + 1;
      final intervalIndex = newReviewCount < _ebbinghausIntervals.length 
          ? newReviewCount 
          : _ebbinghausIntervals.length - 1;
      final daysToAdd = _ebbinghausIntervals[intervalIndex];
      newNextReviewTime = DateTime.now().add(Duration(days: daysToAdd));
    } else {
      newReviewCount = 0;
      // If forgotten, review again tomorrow
      newNextReviewTime = DateTime.now().add(const Duration(days: 1));
    }

    final updatedRecord = currentItem.copyWith(
      reviewCount: newReviewCount,
      nextReviewTime: newNextReviewTime,
    );

    await mistakeService.updateMistake(updatedRecord);

    setState(() {
      _currentIndex++;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('dailyReview')),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _reviewList.isEmpty 
                    ? '0/0' 
                    : '${_currentIndex + 1}/${_reviewList.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: _reviewList.isEmpty || _currentIndex >= _reviewList.length
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get('reviewCompleted'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('comeBackTomorrow'),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.get('finish')),
                  )
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        if (!_isFlipped) {
                          setState(() {
                            _isFlipped = true;
                          });
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final rotateAnim = Tween(begin: 3.1415926, end: 0.0).animate(animation);
                          return AnimatedBuilder(
                            animation: rotateAnim,
                            builder: (context, child) {
                              final isUnder = (ValueKey(_isFlipped) != child!.key);
                              final value = isUnder ? min(rotateAnim.value, 3.1415926 / 2) : rotateAnim.value;
                              return Transform(
                                transform: Matrix4.rotationY(value),
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                            child: child,
                          );
                        },
                        child: _isFlipped ? _buildBack(l10n) : _buildFront(l10n),
                      ),
                    ),
                  ),
                ),
                if (_isFlipped)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleReview(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(l10n.get('forgot')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _handleReview(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(l10n.get('remembered')),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.get('tapToFlip'),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFront(AppLocalizations l10n) {
    final currentItem = _reviewList[_currentIndex];
    return Card(
      key: const ValueKey(false),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${l10n.get('mistakeBook')} - 问题',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const Divider(),
            Expanded(
              child: InteractiveViewer(
                child: Image(
                  image: _getImageProvider(currentItem.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack(AppLocalizations l10n) {
    final currentItem = _reviewList[_currentIndex];
    return Card(
      key: const ValueKey(true),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                '解答 / 笔记',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentItem.note != null && currentItem.note!.isNotEmpty) ...[
                      Text(
                        '📝 ${l10n.get('note')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(currentItem.note!),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],
                    if (currentItem.knowledgePoints != null && currentItem.knowledgePoints!.isNotEmpty) ...[
                      Text(
                        '💡 ${l10n.get('knowledgePoints')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(data: currentItem.knowledgePoints!),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],
                    Text(
                      '📖 ${l10n.get('solution')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(data: currentItem.solution),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
