import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'dart:ui';
import '../models/countdown_model.dart';
import '../config/anime_theme.dart';

class CountdownEventScreen extends StatefulWidget {
  const CountdownEventScreen({super.key});

  @override
  _CountdownEventScreenState createState() => _CountdownEventScreenState();
}

class _CountdownEventScreenState extends State<CountdownEventScreen> {
  late CountdownModel _countdownModel;

  @override
  void initState() {
    super.initState();
    _countdownModel = Provider.of<CountdownModel>(context, listen: false);
    _countdownModel.loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('倒数日'),
        backgroundColor: AnimeTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 5,
        shadowColor: AnimeTheme.primaryColor.withOpacity(0.5),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
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
            color: AnimeTheme.backgroundColor.withOpacity(0.7),
            child: Consumer<CountdownModel>(
              builder: (context, model, child) {
                if (model.events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 80,
                          color: AnimeTheme.primaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '还没有倒数日事件\n点击右上角 + 添加',
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

                // 按天数排序，最近的在前面
                final sortedEvents = List<CountdownEvent>.from(model.events)
                  ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: sortedEvents.length,
                  itemBuilder: (context, index) {
                    final event = sortedEvents[index];
                    return _buildEventCard(event);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(CountdownEvent event) {
    final daysRemaining = event.daysRemaining;
    Color cardColor;
    String statusText;

    if (daysRemaining < 0) {
      cardColor = Colors.grey;
      statusText = '已过期 ${(-daysRemaining)} 天';
    } else if (daysRemaining == 0) {
      cardColor = AnimeTheme.accentColor;
      statusText = '今天就是目标日！';
    } else if (daysRemaining <= 7) {
      cardColor = AnimeTheme.accentColor;
      statusText = '还剩 $daysRemaining 天';
    } else if (daysRemaining <= 30) {
      cardColor = AnimeTheme.secondaryColor;
      statusText = '还剩 $daysRemaining 天';
    } else {
      cardColor = AnimeTheme.primaryColor;
      statusText = '还剩 $daysRemaining 天';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AnimeTheme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(
          event.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AnimeTheme.textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              '目标日期: ${event.targetDate.year}-${event.targetDate.month.toString().padLeft(2, '0')}-${event.targetDate.day.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 16,
                color: AnimeTheme.textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cardColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert,
            color: AnimeTheme.primaryColor,
          ),
          onSelected: (String result) {
            if (result == 'delete') {
              _confirmDeleteEvent(event);
            } else if (result == 'sync') {
              _syncEventToCalendar(event);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'sync',
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AnimeTheme.primaryColor),
                  SizedBox(width: 10),
                  Text('同步到日历'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AnimeTheme.accentColor),
                  SizedBox(width: 10),
                  Text('删除'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                '添加倒数日事件',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AnimeTheme.textColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '事件名称',
                      hintText: '请输入事件名称',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AnimeTheme.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AnimeTheme.primaryColor.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: const Text(
                        '选择日期',
                        style: TextStyle(
                          color: AnimeTheme.textColor,
                        ),
                      ),
                      subtitle: Text(
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: AnimeTheme.textColor,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: AnimeTheme.primaryColor,
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
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
                    if (titleController.text.isNotEmpty) {
                      final newEvent = CountdownEvent(
                        id: const Uuid().v4(),
                        title: titleController.text,
                        targetDate: selectedDate,
                        createdAt: DateTime.now(),
                      );
                      _countdownModel.addEvent(newEvent);
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
      },
    );
  }

  void _confirmDeleteEvent(CountdownEvent event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '确认删除',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AnimeTheme.textColor,
            ),
          ),
          content: Text(
            '确定要删除 "${event.title}" 吗？',
            style: const TextStyle(
              color: AnimeTheme.textColor,
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
                _countdownModel.removeEvent(event.id);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AnimeTheme.accentColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _syncEventToCalendar(CountdownEvent event) async {
    final Event newEvent = Event(
      title: event.title,
      description: '倒数日提醒：${event.title}',
      location: '',
      startDate: event.targetDate,
      endDate: event.targetDate.add(const Duration(hours: 1)),
      allDay: true,
    );

    try {
      await Add2Calendar.addEvent2Cal(newEvent);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '事件已同步到日历',
              style: TextStyle(color: AnimeTheme.textColor),
            ),
            backgroundColor: AnimeTheme.cardColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '同步失败: $e',
              style: const TextStyle(color: AnimeTheme.textColor),
            ),
            backgroundColor: AnimeTheme.cardColor,
          ),
        );
      }
    }
  }
}
