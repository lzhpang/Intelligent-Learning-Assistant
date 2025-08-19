import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:volume_controller/volume_controller.dart';
import '../config/anime_theme.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  _FocusTimerScreenState createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  // 默认专注时长25分钟
  Duration _focusDuration = const Duration(minutes: 25);
  // 默认休息时长5分钟
  Duration _breakDuration = const Duration(minutes: 5);
  Duration _timeLeft = Duration.zero;

  Timer? _timer;
  bool _isRunning = false;
  bool _isFocusTime = true; // true表示专注时间，false表示休息时间
  int _completedSessions = 0;

  // 添加全屏横屏选项
  bool _enableFullScreen = false;

  // 锁机功能状态
  bool _isLocked = false;

  // 原始系统设置值
  double _originalVolume = 0.5;
  StreamSubscription<double>? _volumeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeSystemSettings();
    // 初始化音量控制器
    VolumeController().showSystemUI = false;
  }

  // 初始化系统设置
  void _initializeSystemSettings() async {
    try {
      _originalVolume = await VolumeController().getVolume();
    } catch (e) {
      // 如果无法获取当前设置，使用默认值
      _originalVolume = 0.5;
    }
  }

  // 应用锁机设置
  void _applyLockSettings() async {
    if (!_isLocked) return;

    try {
      // 锁机功能已启用，但不调整系统设置
    } catch (e) {
      // 忽略设置失败的情况
    }
  }

  // 恢复原始系统设置
  void _restoreSystemSettings() async {
    try {
      // 不再恢复任何系统设置
    } catch (e) {
      // 忽略恢复失败的情况
    }
  }

  void _startTimer() {
    if (!_isRunning) {
      setState(() {
        if (_timeLeft.inSeconds == 0) {
          _timeLeft = _isFocusTime ? _focusDuration : _breakDuration;
        }
        _isRunning = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = Duration(seconds: _timeLeft.inSeconds - 1);
          } else {
            _isRunning = false;
            timer.cancel();

            // 计时结束自动解锁
            if (_isLocked) {
              _isLocked = false;
              _restoreSystemSettings();
            }

            if (_isFocusTime) {
              // 专注时间结束，增加完成的会话数
              _completedSessions++;
            }

            // 切换状态（专注时间 <-> 休息时间）
            _isFocusTime = !_isFocusTime;
            _showCompletionDialog();
          }
        });
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;

      // 停止计时器时自动解锁
      if (_isLocked) {
        _isLocked = false;
        _restoreSystemSettings();
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = _focusDuration;
      _isRunning = false;
      _isFocusTime = true;
      _completedSessions = 0;

      // 重置计时器时自动解锁
      if (_isLocked) {
        _isLocked = false;
        _restoreSystemSettings();
      }
    });
  }

  void _showCompletionDialog() {
    String title = _isFocusTime ? '休息时间结束' : '专注时间结束';
    String content = _isFocusTime ? '休息时间结束，开始新的专注时间吧！' : '专注时间结束，休息一下吧！';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 自动开始下一个阶段
                _timeLeft = _isFocusTime ? _focusDuration : _breakDuration;
                _startTimer();
              },
              style: AnimeTheme.animeButtonStyle,
              child: const Text('继续'),
            ),
          ],
        );
      },
    );
  }

  void _setFocusTime() {
    _showTimeSettingDialog('设置专注时间', _focusDuration, (newDuration) {
      setState(() {
        _focusDuration = newDuration;
        if (_isFocusTime && !_isRunning) {
          _timeLeft = _focusDuration;
        }
      });
    });
  }

  void _setBreakTime() {
    _showTimeSettingDialog('设置休息时间', _breakDuration, (newDuration) {
      setState(() {
        _breakDuration = newDuration;
        if (!_isFocusTime && !_isRunning) {
          _timeLeft = _breakDuration;
        }
      });
    });
  }

  void _showTimeSettingDialog(
      String title, Duration initialDuration, Function(Duration) onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int hours = initialDuration.inHours;
        int minutes = initialDuration.inMinutes.remainder(60);
        int seconds = initialDuration.inSeconds.remainder(60);

        final hoursController = TextEditingController(text: hours.toString());
        final minutesController =
            TextEditingController(text: minutes.toString());
        final secondsController =
            TextEditingController(text: seconds.toString());

        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: '小时',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: minutesController,
                decoration: const InputDecoration(
                  labelText: '分钟',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: secondsController,
                decoration: const InputDecoration(
                  labelText: '秒',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
                int newHours = int.tryParse(hoursController.text) ?? 0;
                int newMinutes = int.tryParse(minutesController.text) ?? 0;
                int newSeconds = int.tryParse(secondsController.text) ?? 0;

                Duration newDuration = Duration(
                  hours: newHours,
                  minutes: newMinutes,
                  seconds: newSeconds,
                );

                onConfirm(newDuration);
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

    if (!_isLocked) {
      // 解锁时恢复设置
      _restoreSystemSettings();
    }
  }

  // 尝试解锁
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
      '现在退出会打断你的专注时间，可能影响你的计划哦！',
      '专注时间马上就要完成了，不如再坚持一下？',
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
                        _stopTimer();
                        _restoreSystemSettings(); // 恢复原始系统设置
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
    _volumeSubscription?.cancel();
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
                        '$minutes:$seconds',
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
                          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 12.0),
                          textStyle: const TextStyle(
                            fontSize: 18,
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
                    flex: 9, // 增加数字显示区域的比例
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  // 仅保留必要的按钮
                  Expanded(
                    flex: 1, // 减少按钮区域的比例
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 锁机按钮（仅在专注时间运行时显示）
                        if (_isFocusTime && _isRunning) ...[
                          TextButton(
                            onPressed: _toggleLock,
                            style: TextButton.styleFrom(
                              backgroundColor: _isLocked 
                                ? Colors.red.withOpacity(0.2) 
                                : AnimeTheme.lightPrimaryColor.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20.0, vertical: 8.0),
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
                        ],
                        // 退出全屏按钮
                        TextButton(
                          onPressed: _exitFullScreen,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 8.0),
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
          title: const Text('专注计时'),
          backgroundColor: AnimeTheme.primaryColor,
          foregroundColor: Colors.white,
          leading: _isLocked && _isRunning && _isFocusTime
              ? IconButton(
                  icon: const Icon(Icons.lock, color: Colors.white),
                  onPressed: _attemptUnlock,
                  tooltip: '解锁',
                )
              : null,
          actions: [
            // 锁机按钮（仅在专注时间运行时显示）
            if (_isFocusTime && _isRunning) ...[
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
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
            child: Container(
              color: AnimeTheme.backgroundColor.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 显示当前是专注还是休息时间
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            _isFocusTime ? AnimeTheme.primaryColor : AnimeTheme.lightAccentColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (_isFocusTime
                                    ? AnimeTheme.primaryColor
                                    : AnimeTheme.lightAccentColor)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _isFocusTime ? '专注时间' : '休息时间',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 显示已完成的会话数
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: AnimeTheme.cardColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AnimeTheme.primaryColor.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '已完成 $_completedSessions 个会话',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AnimeTheme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // 显示时间
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: AnimeTheme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AnimeTheme.primaryColor.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        '$minutes:$seconds',
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
                          onPressed: _isRunning ? _stopTimer : _startTimer,
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
                          onPressed: _resetTimer,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _setFocusTime,
                          style: TextButton.styleFrom(
                            backgroundColor: AnimeTheme.cardColor.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 12.0),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            '设置专注时间',
                            style: TextStyle(color: AnimeTheme.textColor),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _setBreakTime,
                          style: TextButton.styleFrom(
                            backgroundColor: AnimeTheme.cardColor.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 12.0),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            '设置休息时间',
                            style: TextStyle(color: AnimeTheme.textColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}