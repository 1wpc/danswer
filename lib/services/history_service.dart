import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/history_item.dart';
import 'package:path/path.dart' as path;

class HistoryService with ChangeNotifier {
  static const String _fileName = 'history.json';
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
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _items = jsonList.map((e) => HistoryItem.fromJson(e)).toList();
        // Sort by timestamp descending
        _items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_fileName');
      final jsonList = _items.map((e) => e.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> addRecord(File imageFile, String solution) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = path.join(directory.path, 'images', fileName);
      
      // Create images directory if it doesn't exist
      final imageDir = Directory(path.join(directory.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Copy image to permanent storage
      await imageFile.copy(newPath);

      final newItem = HistoryItem(
        id: const Uuid().v4(),
        imagePath: newPath,
        solution: solution,
        timestamp: DateTime.now(),
      );

      _items.insert(0, newItem);
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding history record: $e');
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
