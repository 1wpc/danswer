import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mistake_record.dart';
import '../services/mistake_service.dart';
import '../l10n/app_localizations.dart';
import 'result_screen.dart';

class MistakeBookScreen extends StatelessWidget {
  const MistakeBookScreen({super.key});

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('data:')) {
      final base64String = path.split(',').last;
      return MemoryImage(base64Decode(base64String));
    } else {
      return FileImage(File(path));
    }
  }

  Future<Uint8List> _getImageBytes(String path) async {
    if (path.startsWith('data:')) {
      final base64String = path.split(',').last;
      return base64Decode(base64String);
    } else {
      return await File(path).readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('mistakeBook')),
      ),
      body: Consumer<MistakeService>(
        builder: (context, mistakeService, child) {
          if (mistakeService.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get('noMistakes'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: mistakeService.items.length,
            itemBuilder: (context, index) {
              final item = mistakeService.items[index];
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(l10n.get('delete')),
                        content: Text(l10n.get('deleteConfirm')),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l10n.get('cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              l10n.get('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  mistakeService.removeMistake(item.id);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: SizedBox(
                      width: 50,
                      height: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image(
                          image: _getImageProvider(item.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image);
                          },
                        ),
                      ),
                    ),
                    title: Text(
                      item.note?.isNotEmpty == true 
                          ? item.note! 
                          : item.solution.split('\n').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMd().add_jm().format(item.timestamp),
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (item.tags != null && item.tags!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 4,
                              children: item.tags!.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      // Load image bytes before navigation
                      try {
                        final bytes = await _getImageBytes(item.imagePath);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ResultScreen(
                                imageBytes: bytes,
                                initialSolution: item.solution,
                                initialModel: item.model,
                                initialChatHistory: item.chatHistory,
                                initialKnowledgePoints: item.knowledgePoints,
                                // We will add support for mistakeId later to enable editing
                                // mistakeId: item.id,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error loading image: $e')),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
