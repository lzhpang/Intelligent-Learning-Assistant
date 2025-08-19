import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../config/anime_theme.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _addTodo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加待办事项'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AnimeTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                if (_titleController.text.isNotEmpty) {
                  Provider.of<TodoModel>(context, listen: false).addTodo(
                    _titleController.text,
                    _descriptionController.text,
                  );
                  _titleController.clear();
                  _descriptionController.clear();
                  Navigator.of(context).pop();
                }
              },
              style: AnimeTheme.animeButtonStyle,
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待办事项'),
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(
            color: AnimeTheme.backgroundColor.withOpacity(0.7),
            child: Consumer<TodoModel>(
              builder: (context, todoModel, child) {
                return ListView.builder(
                  itemCount: todoModel.todos.length,
                  itemBuilder: (context, index) {
                    final todo = todoModel.todos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      color: AnimeTheme.cardColor.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: todo.isCompleted
                              ? AnimeTheme.secondaryColor.withOpacity(0.3)
                              : AnimeTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Transform.scale(
                          scale: 1.3,
                          child: Checkbox(
                            value: todo.isCompleted,
                            onChanged: (value) {
                              // 使用传入的todoModel实例调用toggleTodoCompleted以确保状态更新
                              todoModel.toggleTodoCompleted(todo.id);
                            },
                            activeColor: AnimeTheme.primaryColor,
                            checkColor: Colors.white,
                            shape: const CircleBorder(),
                          ),
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AnimeTheme.textColor,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(
                          todo.description,
                          style: TextStyle(
                            color: AnimeTheme.textColor.withOpacity(0.8),
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 28),
                          onPressed: () {
                            todoModel.removeTodo(todo.id);
                          },
                          color: AnimeTheme.accentColor,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        backgroundColor: AnimeTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(
            color: AnimeTheme.secondaryColor,
            width: 2,
          ),
        ),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

// 需要导入dart:ui以使用ImageFilter
