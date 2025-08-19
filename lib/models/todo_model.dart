import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TodoItem with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? completedAt;

  TodoItem({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  void toggleCompleted() {
    isCompleted = !isCompleted;
    if (isCompleted) {
      completedAt = DateTime.now();
    } else {
      completedAt = null;
    }
    notifyListeners();
  }

  // 将TodoItem转换为Map用于存储
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // 从Map创建TodoItem实例
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}

class TodoModel with ChangeNotifier {
  final List<TodoItem> _todos = [];
  bool _initialized = false;

  List<TodoItem> get todos => _todos;

  List<TodoItem> get completedTodos =>
      _todos.where((todo) => todo.isCompleted).toList();

  List<TodoItem> get pendingTodos =>
      _todos.where((todo) => !todo.isCompleted).toList();

  // 在构造函数中自动加载数据
  TodoModel() {
    loadTodos();
  }

  // 初始化时从shared preferences加载数据
  Future<void> loadTodos() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('todos');
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _todos.clear();
        _todos.addAll(jsonList.map((e) => TodoItem.fromJson(e)).toList());
      } catch (e) {
        // 如果解析失败，清空列表
        _todos.clear();
        print('解析待办事项数据失败: $e');
      }
    } else {
      // 如果没有保存的数据，添加默认示例
      _todos.clear();
      _todos.add(TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '示例待办事项',
        description: '这是一个示例待办事项',
        isCompleted: false,
        createdAt: DateTime.now(),
      ));
    }
    
    _initialized = true;
    notifyListeners();
  }

  // 保存数据到shared preferences
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_todos.map((e) => e.toJson()).toList());
    await prefs.setString('todos', jsonString);
  }

  void addTodo(String title, String description) {
    final newTodo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    _todos.add(newTodo);
    _saveTodos();
    notifyListeners();
  }

  void removeTodo(String id) {
    _todos.removeWhere((todo) => todo.id == id);
    _saveTodos();
    notifyListeners();
  }

  TodoItem? getTodoById(String id) {
    try {
      return _todos.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  void toggleTodoCompleted(String id) {
    final todo = getTodoById(id);
    if (todo != null) {
      todo.toggleCompleted();
      _saveTodos();
      notifyListeners();
    }
  }
}