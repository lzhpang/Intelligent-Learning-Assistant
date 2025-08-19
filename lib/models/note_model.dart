import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  // 将Note转换为Map用于存储
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 从Map创建Note实例
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class NoteModel with ChangeNotifier {
  final List<Note> _notes = [];
  bool _initialized = false;

  List<Note> get notes => _notes;

  // 在构造函数中自动加载数据
  NoteModel() {
    loadNotes();
  }

  // 初始化时从shared preferences加载数据
  Future<void> loadNotes() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notes');
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _notes.clear();
        _notes.addAll(jsonList.map((e) => Note.fromJson(e)).toList());
      } catch (e) {
        // 如果解析失败，清空列表
        _notes.clear();
        print('解析笔记数据失败: $e');
      }
    } else {
      // 如果没有保存的数据，添加默认示例
      _notes.clear();
      _notes.add(Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '示例笔记',
        content: '这是一个示例笔记',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
    
    _initialized = true;
    notifyListeners();
  }

  // 保存数据到shared preferences
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_notes.map((e) => e.toJson()).toList());
    await prefs.setString('notes', jsonString);
  }

  void addNote(String title, String content) {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _notes.add(newNote);
    _saveNotes();
    notifyListeners();
  }

  void updateNote(String id, String title, String content) {
    final index = _notes.indexWhere((note) => note.id == id);
    if (index != -1) {
      _notes[index] = Note(
        id: id,
        title: title,
        content: content,
        createdAt: _notes[index].createdAt,
        updatedAt: DateTime.now(),
      );
      _saveNotes();
      notifyListeners();
    }
  }

  void removeNote(String id) {
    _notes.removeWhere((note) => note.id == id);
    _saveNotes();
    notifyListeners();
  }

  Note? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }
}