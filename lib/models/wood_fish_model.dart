import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WoodFishModel with ChangeNotifier {
  int _count = 0;
  final String _prefKey = 'wood_fish_count';
  final String _lastResetKey = 'wood_fish_last_reset';

  int get count => _count;

  WoodFishModel() {
    _loadCount();
  }

  void tap() {
    _count++;
    _saveCount();
    notifyListeners();
  }

  void reset() {
    _count = 0;
    _saveCount();
    notifyListeners();
  }

  Future<void> _saveCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, _count);
      await prefs.setString(_lastResetKey, DateTime.now().toIso8601String().split('T')[0]);
    } catch (e) {
      print('保存计数失败: $e');
    }
  }

  Future<void> _loadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt(_prefKey);
      final lastResetString = prefs.getString(_lastResetKey);
      
      if (lastResetString != null) {
        final lastResetDate = DateTime.parse(lastResetString);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        // 如果上次重置日期不是今天，则重置计数
        if (lastResetDate.isBefore(today)) {
          _count = 0;
        } else if (savedCount != null) {
          _count = savedCount;
        }
      } else if (savedCount != null) {
        _count = savedCount;
      }
      
      notifyListeners();
    } catch (e) {
      print('加载计数失败: $e');
    }
  }
}