import 'package:flutter/material.dart';
import './todo_screen.dart';
import './countdown_screen.dart';
import './focus_timer_screen.dart';
import './mind_map_screen.dart';
import './note_screen.dart';
import './countdown_event_screen.dart';
import './ai_assistant_screen.dart';
import '../config/anime_theme.dart';
import 'package:provider/provider.dart';
import '../models/wood_fish_model.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('多功能学习助手'),
        backgroundColor: AnimeTheme.primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/dalian_bridge.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            children: [
              _buildFeatureCard(
                context,
                title: '待办事项',
                icon: Icons.check_box,
                color: AnimeTheme.primaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TodoScreen()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: '倒计时',
                icon: Icons.timer,
                color: AnimeTheme.secondaryColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CountdownScreen()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: '专注计时',
                icon: Icons.access_time,
                color: AnimeTheme.accentColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FocusTimerScreen()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: '思维导图',
                icon: Icons.account_tree,
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MindMapScreen()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: '记笔记',
                icon: Icons.note,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NoteScreen()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: '倒数日',
                icon: Icons.calendar_today,
                color: Colors.pink,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CountdownEventScreen()),
                ),
              ),
              _buildFeatureCard(
                context,
                title: 'AI助手',
                icon: Icons.psychology,
                color: Colors.deepPurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AIAssistantScreen()),
                ),
              ),
              // 木鱼功能按钮
              const WoodFishFeatureCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      elevation: 6.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AnimeTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            // 添加一些装饰性元素
            const SizedBox(height: 5),
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WoodFishFeatureCard extends StatefulWidget {
  const WoodFishFeatureCard({super.key});

  @override
  State<WoodFishFeatureCard> createState() => _WoodFishFeatureCardState();
}

class _WoodFishFeatureCardState extends State<WoodFishFeatureCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // 初始化音频播放器
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _tapWoodFish() async {
    // 播放音效
    try {
      // 使用新的播放方式，创建独立的播放器实例
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/woodfish.mp3'));
      print('音效播放成功');
      
      // 延迟释放资源，确保音效播放完成
      Future.delayed(const Duration(seconds: 1), () {
        player.dispose();
      });
    } catch (e) {
      // 如果音效播放失败，至少保证计数功能正常工作
      print('音效播放失败: $e');
    }
    
    // 触发动画
    _controller.forward().then((_) {
      _controller.reverse();
    });
    
    // 更新计数
    Provider.of<WoodFishModel>(context, listen: false).tap();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WoodFishModel>(
      builder: (context, woodFishModel, child) {
        return Card(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(
              color: const Color(0xFFD32F2F).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: _tapWoodFish,
            borderRadius: BorderRadius.circular(20.0),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/woodfish.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '敲木鱼',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AnimeTheme.textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '功德+${woodFishModel.count}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AnimeTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}