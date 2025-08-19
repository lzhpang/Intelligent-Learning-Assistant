import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui';
import '../models/ai_assistant_model.dart';
import '../config/anime_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  _AIAssistantScreenState createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  // 用于存储当前正在接收的流式消息
  ChatMessage? _streamingMessage;

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final aiModel = Provider.of<AIAssistantModel>(context, listen: false);

    // 添加用户消息
    aiModel.addMessage(ChatMessage(text: text, isUser: true));
    _textController.clear();

    setState(() {
      _isSending = true;
    });

    // 获取AI回复流
    final responseStream = aiModel.getAIResponseStream(text);

    // 监听流并逐步更新消息
    await for (final partialResponse in responseStream) {
      if (mounted) {
        setState(() {
          _streamingMessage = ChatMessage(text: partialResponse, isUser: false);
        });
        
        // 滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    // 添加完整消息到模型
    if (_streamingMessage != null) {
      aiModel.addMessage(_streamingMessage!);
    }

    setState(() {
      _isSending = false;
      _streamingMessage = null;
    });

    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI学习助手'),
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
            child: Consumer<AIAssistantModel>(
              builder: (context, aiModel, child) {
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            aiModel.messages.length + 
                            (_streamingMessage != null ? 1 : 0) + 
                            (_isSending && _streamingMessage == null ? 1 : 0),
                        itemBuilder: (context, index) {
                          // 处理流式消息显示
                          if (_streamingMessage != null && 
                              index == aiModel.messages.length) {
                            return _buildMessageBubble(_streamingMessage!);
                          }
                          
                          // 处理"正在输入"指示器
                          if (index >= aiModel.messages.length) {
                            return _buildLoadingIndicator();
                          }

                          final message = aiModel.messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
                    ),
                    _buildInputArea(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          // 如果是AI的消息，才允许复制
          if (!isUser) {
            Clipboard.setData(ClipboardData(text: message.text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '已复制到剪贴板',
                  style: TextStyle(color: AnimeTheme.textColor),
                ),
                backgroundColor: AnimeTheme.cardColor,
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isUser
                ? AnimeTheme.primaryColor.withOpacity(0.8)
                : AnimeTheme.cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(20),
            ),
            border: Border.all(
              color: isUser
                  ? AnimeTheme.primaryColor.withOpacity(0.5)
                  : AnimeTheme.secondaryColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isUser
                    ? AnimeTheme.primaryColor.withOpacity(0.3)
                    : AnimeTheme.secondaryColor.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isUser
              ? Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                )
              : MarkdownBody(
                  data: message.text,
                  selectable: true, // 允许选择文本
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(
                      color: AnimeTheme.textColor,
                      fontSize: 16,
                    ),
                    h1: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AnimeTheme.textColor,
                    ),
                    h2: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AnimeTheme.textColor,
                    ),
                    strong: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AnimeTheme.textColor,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AnimeTheme.cardColor.withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(
            color: AnimeTheme.secondaryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AnimeTheme.secondaryColor.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              color: AnimeTheme.secondaryColor,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              '正在思考...',
              style: TextStyle(
                color: AnimeTheme.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AnimeTheme.cardColor.withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        border: Border.all(
          color: AnimeTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AnimeTheme.primaryColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: '请输入您的问题...',
                  hintStyle: TextStyle(
                    color: AnimeTheme.textColor.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(
                  color: AnimeTheme.textColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AnimeTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AnimeTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
                shape: const CircleBorder(),
                elevation: 0,
              ),
              child: const Icon(
                Icons.send,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}