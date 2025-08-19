import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'config/anime_theme.dart';
import 'package:provider/provider.dart';
import 'models/wood_fish_model.dart';
import 'models/todo_model.dart';
import 'models/countdown_model.dart';
import 'models/note_model.dart';
import 'models/ai_assistant_model.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WoodFishModel()),
        ChangeNotifierProvider(create: (context) => TodoModel()),
        ChangeNotifierProvider(create: (context) => CountdownModel()),
        ChangeNotifierProvider(create: (context) => NoteModel()),
        ChangeNotifierProvider(create: (context) => AIAssistantModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '多功能学习助手',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}