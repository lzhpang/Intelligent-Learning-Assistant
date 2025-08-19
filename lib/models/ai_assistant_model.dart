import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  // 替换为你的OpenAI API密钥
  static const String openAiApiKey = 'sk-7431d33599d94d33bf41f476392980f9'; 
  
  // OpenAI API URL
  static const String openAiApiUrl = 'https://api.deepseek.com/chat/completions';
}

const double temp = 0.5;

class AIAssistantModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  // 在构造函数中初始化
  AIAssistantModel() {
    _initializeWelcomeMessage();
  }

  // 初始化欢迎消息
  void _initializeWelcomeMessage() {
    if (_messages.isEmpty) {
      addMessage(ChatMessage(
        text:
            '您好！我是您的学习助手，我可以回答关于学习方法、记忆技巧、时间管理等方面的问题。您可以问我关于艾宾浩斯遗忘曲线、番茄工作法、如何制定学习计划等，当然也可以问我具体的问题，比如数学问题、物理问题或代码书写等。',
        isUser: false,
      ));
    }
  }

  // 添加新消息
  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  // 清除聊天记录
  void clearMessages() {
    _messages.clear();
    _initializeWelcomeMessage(); // 重新添加欢迎消息
    notifyListeners();
  }

  // 从OpenAI API获取回复（流式）
  Stream<String> getAIResponseStream(String userMessage) async* {
    try {
      // 添加系统提示词，让AI专注于学习相关问题
      final messages = [
        {
          'role': 'system',
          'content': '你是一个专业的学习助手，专门帮助用户解答学习方法、记忆技巧、时间管理等方面的问题，也能回答具体的学习上的问题，如解决数学问题、物理问题、代码书写等。请以教育者的身份，提供详细、准确且有帮助的回答。'
        },
        ..._messages.where((msg) => !msg.isUser).map((msg) => {
              'role': 'assistant',
              'content': msg.text
            }),
        ..._messages.where((msg) => msg.isUser).map((msg) => {
              'role': 'user',
              'content': msg.text
            }),
        {
          'role': 'user',
          'content': userMessage
        }
      ];

      final response = await http.post(
        Uri.parse(ApiConfig.openAiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
          'Accept': 'text/event-stream',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': temp,
          'stream': true, // 启用流式响应
        }),
      );

      if (response.statusCode == 200) {
        // 处理流式响应
        final lines = LineSplitter().convert(response.body);
        String accumulatedContent = '';
        
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') {
              break;
            }
            
            try {
              final json = jsonDecode(data);
              final content = json['choices'][0]['delta']['content'] as String?;
              if (content != null) {
                accumulatedContent += content;
                yield accumulatedContent;
              }
            } catch (e) {
              // 忽略解析错误
            }
          }
        }
      } else {
        // 如果API调用失败，返回错误信息
        yield '抱歉，我现在无法回答您的问题。请检查网络连接或稍后再试。错误代码: ${response.statusCode}';
      }
    } catch (e) {
      // 如果发生异常，返回错误信息
      yield '抱歉，我现在无法回答您的问题。请检查网络连接或稍后再试。错误信息: ${e.toString()}';
    }
  }

  // 从OpenAI API获取回复（原始方法保持不变，用于兼容性）
  Future<String> getAIResponse(String userMessage) async {
    try {
      // 添加系统提示词，让AI专注于学习相关问题
      final messages = [
        {
          'role': 'system',
          'content': '你是一个专业的学习助手，专门帮助用户解答学习方法、记忆技巧、时间管理等方面的问题，也能回答具体的学习上的问题，如解决数学问题、物理问题、代码书写等。请以教育者的身份，提供详细、准确且有帮助的回答。'
        },
        ..._messages.where((msg) => !msg.isUser).map((msg) => {
              'role': 'assistant',
              'content': msg.text
            }),
        ..._messages.where((msg) => msg.isUser).map((msg) => {
              'role': 'user',
              'content': msg.text
            }),
        {
          'role': 'user',
          'content': userMessage
        }
      ];

      final response = await http.post(
        Uri.parse(ApiConfig.openAiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': temp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        return aiResponse.trim();
      } else {
        // 如果API调用失败，返回错误信息
        return '抱歉，我现在无法回答您的问题。请检查网络连接或稍后再试。错误代码: ${response.statusCode}';
      }
    } catch (e) {
      // 如果发生异常，返回错误信息
      return '抱歉，我现在无法回答您的问题。请检查网络连接或稍后再试。错误信息: ${e.toString()}';
    }
  }
}

class ChatMessage {
  final String text;
  final DateTime timestamp;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  }) : timestamp = DateTime.now();
}