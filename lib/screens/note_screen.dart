import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/note_model.dart';
import '../config/anime_theme.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  void _addNote() {
    _showNoteDialog();
  }

  void _editNote(Note note) {
    _showNoteDialog(note: note);
  }

  void _showNoteDialog({Note? note}) {
    _titleController.text = note?.title ?? '';
    _contentController.text = note?.content ?? '';

    bool isEditing = note != null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isEditing ? '编辑笔记' : '添加笔记',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AnimeTheme.textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
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
                const SizedBox(height: 15),
                TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AnimeTheme.primaryColor),
                    ),
                  ),
                  maxLines: 8,
                  style: const TextStyle(
                    color: AnimeTheme.textColor,
                  ),
                ),
              ],
            ),
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
                  if (isEditing) {
                    Provider.of<NoteModel>(context, listen: false).updateNote(
                      note.id,
                      _titleController.text,
                      _contentController.text,
                    );
                  } else {
                    Provider.of<NoteModel>(context, listen: false).addNote(
                      _titleController.text,
                      _contentController.text,
                    );
                  }
                  _titleController.clear();
                  _contentController.clear();
                  Navigator.of(context).pop();
                }
              },
              style: AnimeTheme.animeButtonStyle,
              child: Text(isEditing ? '更新' : '添加'),
            ),
          ],
        );
      },
    );
  }

  void _viewNote(Note note) {
    _titleController.text = note.title;
    _contentController.text = note.content;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            note.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AnimeTheme.textColor,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              note.content,
              style: const TextStyle(
                color: AnimeTheme.textColor,
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: AnimeTheme.animeButtonStyle,
              child: const Text('关闭'),
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
        title: const Text('记笔记'),
        backgroundColor: AnimeTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 5,
        shadowColor: AnimeTheme.primaryColor.withOpacity(0.5),
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
            child: Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                if (noteModel.notes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 80,
                          color: AnimeTheme.primaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '还没有笔记\n点击下方按钮添加',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: AnimeTheme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: noteModel.notes.length,
                  itemBuilder: (context, index) {
                    final note = noteModel.notes[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: AnimeTheme.cardColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AnimeTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AnimeTheme.primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          note.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AnimeTheme.textColor,
                          ),
                        ),
                        subtitle: Text(
                          note.content.length > 100
                              ? '${note.content.substring(0, 100)}...'
                              : note.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: AnimeTheme.textColor.withOpacity(0.8),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility,
                                color: AnimeTheme.primaryColor,
                              ),
                              onPressed: () => _viewNote(note),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AnimeTheme.secondaryColor,
                              ),
                              onPressed: () => _editNote(note),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AnimeTheme.accentColor,
                              ),
                              onPressed: () {
                                Provider.of<NoteModel>(context, listen: false)
                                    .removeNote(note.id);
                              },
                            ),
                          ],
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AnimeTheme.primaryColor.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _addNote,
          backgroundColor: AnimeTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(
            side: BorderSide(
              color: AnimeTheme.secondaryColor,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.add,
            size: 30,
          ),
        ),
      ),
    );
  }
}
