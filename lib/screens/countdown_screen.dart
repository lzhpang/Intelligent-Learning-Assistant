import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../config/anime_theme.dart';

class CountdownScreen extends StatefulWidget {
  const CountdownScreen({super.key});

  @override
  _CountdownScreenState createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> {
  Duration _duration = const Duration(minutes: 1);
  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _isLocked = false;
  bool _enableFullScreen = false;

  void _startCountdown() {
    if (!_isRunning) {
      setState(() {
        _timeLeft = _duration;
        _isRunning = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = Duration(seconds: _timeLeft.inSeconds - 1);
          } else {
            _isRunning = false;
            _isLocked = false; // 倒计时结束时自动解锁
            timer.cancel();
            _showCompletionDialog();
          }
        });
      });
    }
  }

  void _stopCountdown() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isLocked = false; // 停止时解锁
    });
  }

  void _resetCountdown() {
    _timer?.cancel();
    setState(() {
      _timeLeft = _duration;
      _isRunning = false;
      _isLocked = false; // 重置时解锁
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('倒计时完成'),
          content: const Text('设定的时间已到！'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: AnimeTheme.animeButtonStyle,
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _setTime() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedHours = 0;
        int selectedMinutes = 1;
        int selectedSeconds = 0;

        return AlertDialog(
          title: const Text('设置倒计时'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: '小时',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  selectedHours = int.tryParse(value) ?? 0;
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: '分钟',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  selectedMinutes = int.tryParse(value) ?? 1;
                },
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: '秒',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  selectedSeconds = int.tryParse(value) ?? 0;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _duration = Duration(
                    hours: selectedHours,
                    minutes: selectedMinutes,
                    seconds: selectedSeconds,
                  );
                  _timeLeft = _duration;
                });
                Navigator.of(context).pop();
              },
              style: AnimeTheme.animeButtonStyle,
              child: const Text('设置'),
            ),
          ],
        );
      },
    );
  }

  // 切换全屏选项
  void _toggleFullScreenOption() {
    setState(() {
      _enableFullScreen = !_enableFullScreen;
    });
  }

  // 退出全屏模式
  void _exitFullScreen() {
    setState(() {
      _enableFullScreen = false;
    });
  }

  // 切换锁机状态
  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
  }

  // 尝试解锁（三次确认）
  void _attemptUnlock() {
    if (!_isLocked) return;
    
    _showUnlockConfirmation(1);
  }

  // 显示解锁确认对话框
  void _showUnlockConfirmation(int step) {
    List<String> titles = [
      '', // 占位符
      '确定要退出吗？', 
      '再想想看？', 
      '真的要放弃吗？'
    ];
    
    List<String> messages = [
      '', // 占位符
      '现在退出会打断你的倒计时，可能影响你的计划哦！',
      '倒计时马上就要完成了，不如再坚持一下？',
      '马上就要完成了，放弃会很可惜，要不要再考虑一下？'
    ];
    
    if (step <= 3) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false, // 禁止通过返回键关闭对话框
            child: AlertDialog(
              title: Text(titles[step]),
              content: Text(messages[step]),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (step < 3) {
                      _showUnlockConfirmation(step + 1);
                    } else {
                      // 三次确认完成，解锁并停止计时
                      setState(() {
                        _isLocked = false;
                        _stopCountdown();
                      });
                    }
                  },
                  style: AnimeTheme.animeButtonStyle,
                  child: step < 3 ? const Text('确定') : const Text('确认退出'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  // 处理返回按钮事件
  Future<bool> _onWillPop() async {
    if (_isLocked) {
      // 锁定状态下不允许通过返回键退出
      _attemptUnlock();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 恢复默认屏幕方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String hours = _timeLeft.inHours.toString().padLeft(2, '0');
    String minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    // 如果启用了锁机且处于锁定状态，则显示锁机界面
    if (_isLocked) {
      return WillPopScope(
        onWillPop: () async => false, // 完全阻止返回操作
        child: Scaffold(
          body: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 显示时间（尽可能放大）
                  Expanded(
                    flex: 8, // 增加数字显示区域的比例
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$hours:$minutes:$seconds',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  // 解锁按钮区域
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: TextButton(
                        onPressed: _attemptUnlock,
                        style: TextButton.styleFrom(
                          backgroundColor: AnimeTheme.lightPrimaryColor.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '解锁',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 如果启用了全屏则显示全屏计时器（无论是否运行）
    if (_enableFullScreen) {
      // 强制横屏
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 显示时间（尽可能放大）
                  Expanded(
                    flex: 8, // 增加数字显示区域的比例
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$hours:$minutes:$seconds',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  // 仅保留必要的按钮
                  if (_isRunning) ...[
                    Expanded(
                      flex: 1, // 减少按钮区域的比例
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 锁机按钮（仅在计时运行时显示）
                          TextButton(
                            onPressed: _toggleLock,
                            style: TextButton.styleFrom(
                              backgroundColor: _isLocked 
                                ? Colors.red.withOpacity(0.2) 
                                : AnimeTheme.lightPrimaryColor.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _isLocked ? '已锁定' : '锁定',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // 退出全屏按钮
                          TextButton(
                            onPressed: _exitFullScreen,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 10.0),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              '退出全屏',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 计时未运行时只显示退出全屏按钮
                    Expanded(
                      flex: 1, // 减少按钮区域的比例
                      child: TextButton(
                        onPressed: _exitFullScreen,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 10.0),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          '退出全屏',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // 恢复所有屏幕方向
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    // 使用WillPopScope包装整个界面以处理返回键
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('倒计时'),
          backgroundColor: AnimeTheme.secondaryColor,
          foregroundColor: Colors.white,
          // 在锁定状态下显示解锁按钮
          leading: _isLocked && _isRunning
              ? IconButton(
                  icon: const Icon(Icons.lock, color: Colors.white),
                  onPressed: _attemptUnlock,
                  tooltip: '解锁',
                )
              : null,
          actions: [
            // 锁机按钮（仅在计时运行时显示）
            if (_isRunning) ...[
              IconButton(
                icon: Icon(
                  _isLocked ? Icons.lock : Icons.lock_open,
                  color: _isLocked ? Colors.red.shade200 : Colors.white,
                ),
                onPressed: _toggleLock,
                tooltip: _isLocked ? '已锁定' : '锁定',
              ),
            ],
            // 添加全屏选项按钮
            IconButton(
              icon: Icon(
                _enableFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white,
              ),
              onPressed: _toggleFullScreenOption,
              tooltip: _enableFullScreen ? '关闭全屏模式' : '开启全屏模式',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/dalian_bridge.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 添加动漫风格的计时器显示
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: AnimeTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AnimeTheme.secondaryColor.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    '$hours:$minutes:$seconds',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AnimeTheme.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _isRunning ? _stopCountdown : _startCountdown,
                      style: TextButton.styleFrom(
                        backgroundColor: _isRunning
                            ? AnimeTheme.lightAccentColor.withOpacity(0.8)
                            : AnimeTheme.lightPrimaryColor.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25.0, vertical: 15.0),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isRunning ? '暂停' : '开始',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    TextButton(
                      onPressed: _resetCountdown,
                      style: TextButton.styleFrom(
                        backgroundColor: AnimeTheme.lightSecondaryColor.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25.0, vertical: 15.0),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        '重置',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _setTime,
                  style: TextButton.styleFrom(
                    backgroundColor: AnimeTheme.cardColor.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25.0, vertical: 15.0),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '设置时间',
                    style: TextStyle(color: AnimeTheme.textColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}