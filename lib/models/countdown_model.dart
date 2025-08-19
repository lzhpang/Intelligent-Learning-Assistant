import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CountdownEvent {
  final String id;
  final String title;
  final DateTime targetDate;
  final DateTime createdAt;

  CountdownEvent({
    required this.id,
    required this.title,
    required this.targetDate,
    required this.createdAt,
  });

  // 计算距离目标日期的天数
  int get daysRemaining {
    final now = DateTime.now();
    // 使用日期比较而不是简单的天数差
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final difference = targetDay.difference(today);
    return difference.inDays;
  }

  // 将CountdownEvent转换为Map用于存储
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'targetDate': targetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 从Map创建CountdownEvent实例
  factory CountdownEvent.fromJson(Map<String, dynamic> json) {
    return CountdownEvent(
      id: json['id'],
      title: json['title'],
      targetDate: DateTime.parse(json['targetDate']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class CountdownModel with ChangeNotifier {
  final List<CountdownEvent> _events = [];

  List<CountdownEvent> get events => _events;

  // 在构造函数中自动加载数据
  CountdownModel() {
    loadEvents();
  }

  // 初始化时从shared preferences加载数据
  Future<void> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('countdown_events');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _events.clear();
      _events.addAll(
        jsonList.map((json) => CountdownEvent.fromJson(json)).toList(),
      );
      notifyListeners();
    }
  }

  // 保存数据到shared preferences
  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_events.map((e) => e.toJson()).toList());
    await prefs.setString('countdown_events', jsonString);
    notifyListeners();
  }

  // 添加新的倒数日事件
  Future<void> addEvent(CountdownEvent event) async {
    _events.add(event);
    await _saveEvents();
  }

  // 删除倒数日事件
  Future<void> removeEvent(String id) async {
    _events.removeWhere((event) => event.id == id);
    await _saveEvents();
  }

  // 更新倒数日事件
  Future<void> updateEvent(CountdownEvent updatedEvent) async {
    final index = _events.indexWhere((event) => event.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      await _saveEvents();
    }
  }
}