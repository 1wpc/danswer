import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/history_item.dart';
import 'package:path/path.dart' as path;

class HistoryService with ChangeNotifier {
  static const String _fileName = 'history.json';
  static const String _prefsKey = 'history_data';
  List<HistoryItem> _items = [];
  bool _initialized = false;

  List<HistoryItem> get items => List.unmodifiable(_items);

  Future<void> init() async {
    if (_initialized) return;
    await _loadHistory();
    _initialized = true;
  }

  Future<void> _loadHistory() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final content = prefs.getString(_prefsKey);
        if (content != null) {
          final List<dynamic> jsonList = json.decode(content);
          _items = jsonList.map((e) => HistoryItem.fromJson(e)).toList();
        }
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_fileName');
        
        if (await file.exists()) {
          final content = await file.readAsString();
          final List<dynamic> jsonList = json.decode(content);
          _items = jsonList.map((e) => HistoryItem.fromJson(e)).toList();
        }
      }
      
      _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
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
      debugPrint('Error saving history: $e');
    }
  }

  Future<String> addRecord(Uint8List imageBytes, String solution, {String? model, List<Map<String, dynamic>>? chatHistory, String? knowledgePoints}) async {
    try {
      String imagePath;

      if (kIsWeb) {
        final base64 = base64Encode(imageBytes);
        imagePath = 'data:image/png;base64,$base64';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String newPath = path.join(directory.path, 'images', fileName);
        
        final imageDir = Directory(path.join(directory.path, 'images'));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        final file = File(newPath);
        await file.writeAsBytes(imageBytes);
        imagePath = newPath;
      }

      final newItem = HistoryItem(
        id: const Uuid().v4(),
        imagePath: imagePath,
        solution: solution,
        timestamp: DateTime.now(),
        model: model,
        chatHistory: chatHistory,
        knowledgePoints: knowledgePoints,
      );

      _items.insert(0, newItem);
      await _saveHistory();
      notifyListeners();
      return newItem.id;
    } catch (e) {
      debugPrint('Error adding history record: $e');
      return '';
    }
  }

  Future<void> updateRecord(String id, {String? solution, List<Map<String, dynamic>>? chatHistory, String? knowledgePoints}) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final oldItem = _items[index];
        final newItem = HistoryItem(
          id: oldItem.id,
          imagePath: oldItem.imagePath,
          solution: solution ?? oldItem.solution,
          timestamp: oldItem.timestamp,
          model: oldItem.model,
          chatHistory: chatHistory ?? oldItem.chatHistory,
          knowledgePoints: knowledgePoints ?? oldItem.knowledgePoints,
        );
        
        _items[index] = newItem;
        await _saveHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating history record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final item = _items[index];
        // Try to delete the image file
        final file = File(item.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
        
        _items.removeAt(index);
        await _saveHistory();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting history record: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      // Delete all image files
      for (var item in _items) {
        final file = File(item.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _items.clear();
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }
}
