import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../models/countdown_model.dart';
import '../models/note_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;
  late AnimationController _textController;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // 图标动画控制器
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );

    // 文本动画控制器
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    );

    // 启动动画
    _iconController.forward();
    _textController.forward();

    // 3秒后跳转到主页面
    Future.delayed(const Duration(seconds: 3), () async {
      // 确保所有模型数据加载完成后再跳转
      await _loadAllData();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  // 加载所有模型数据
  Future<void> _loadAllData() async {
    try {
      await Provider.of<TodoModel>(context, listen: false).loadTodos();
      await Provider.of<CountdownModel>(context, listen: false).loadEvents();
      await Provider.of<NoteModel>(context, listen: false).loadNotes();
    } catch (e) {
      print('加载模型数据时出错: $e');
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            color: Colors.blue.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 带动画的应用图标
                  ScaleTransition(
                    scale: _iconAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apps,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 带动画的应用名称
                  FadeTransition(
                    opacity: _textAnimation,
                    child: const Column(
                      children: [
                        Text(
                          '知不足而奋进',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 3,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '望远山而前行',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2),
                                blurRadius: 3,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 加载指示器
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}