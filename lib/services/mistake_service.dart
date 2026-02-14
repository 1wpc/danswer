import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../models/mistake_record.dart';

class MistakeService with ChangeNotifier {
  static const String _fileName = 'mistakes.json';
  static const String _prefsKey = 'mistake_data';
  List<MistakeRecord> _items = [];
  bool _initialized = false;

  List<MistakeRecord> get items => List.unmodifiable(_items);

  Future<void> init() async {
    if (_initialized) return;
    await _loadMistakes();
    _initialized = true;
  }

  Future<void> _loadMistakes() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString(_prefsKey);
        if (content != null) {
          final List<dynamic> jsonList = json.decode(content);
          _items = jsonList.map((e) => MistakeRecord.fromJson(e)).toList();
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_fileName');
        
        if (await file.exists()) {
          final content = await file.readAsString();
          final List<dynamic> jsonList = json.decode(content);
          _items = jsonList.map((e) => MistakeRecord.fromJson(e)).toList();
        }
      }
      
      _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading mistakes: $e');
    }
  }

  Future<void> _saveMistakes() async {
    try {
      final jsonList = _items.map((e) => e.toJson()).toList();
      final content = json.encode(jsonList);

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsKey, content);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_fileName');
        await file.writeAsString(content);
      }
    } catch (e) {
      debugPrint('Error saving mistakes: $e');
    }
  }

  Future<String> addMistake(
    Uint8List imageBytes, 
    String solution, 
    {
      String? model, 
      List<Map<String, dynamic>>? chatHistory, 
      String? knowledgePoints,
      String? note,
      List<String>? tags,
    }
  ) async {
    try {
      String imagePath;

      if (kIsWeb) {
        final base64 = base64Encode(imageBytes);
        imagePath = 'data:image/png;base64,$base64';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'mistake_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = path.join(directory.path, 'images', fileName);
        
        final imageDir = Directory(path.join(directory.path, 'images'));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        final file = File(newPath);
        await file.writeAsBytes(imageBytes);
        imagePath = newPath;
      }

      final newItem = MistakeRecord(
        id: const Uuid().v4(),
        imagePath: imagePath,
        solution: solution,
        timestamp: DateTime.now(),
        model: model,
        chatHistory: chatHistory,
        knowledgePoints: knowledgePoints,
        note: note,
        tags: tags,
      );

      _items.insert(0, newItem);
      await _saveMistakes();
      notifyListeners();
      
      return newItem.id;
    } catch (e) {
      debugPrint('Error adding mistake: $e');
      rethrow;
    }
  }

  Future<void> removeMistake(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = _items[index];
      _items.removeAt(index);
      await _saveMistakes();
      notifyListeners();
      
      // Optionally delete image file if not used elsewhere
      // But since we copy image bytes when adding, we own this file.
      if (!kIsWeb) {
        try {
          final file = File(item.imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting mistake image: $e');
        }
      }
    }
  }

  Future<void> clearMistakes() async {
    _items.clear();
    await _saveMistakes();
    notifyListeners();
    // In a real app, we should also delete all associated image files
  }
}
