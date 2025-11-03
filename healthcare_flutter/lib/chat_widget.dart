import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_config.dart'; // 💡 Cấu hình backend

/// 💬 ChatWidget — Chat với AI (Gemini backend)
class ChatWidget extends StatefulWidget {
  final String userId;
  final String token;
  final String role; // 🆕 Vai trò của người dùng (patient / doctor / admin)

  const ChatWidget({
    super.key,
    required this.userId,
    required this.token,
    required this.role,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  bool _isOpen = false;
  bool _loading = false;
  bool _aiTyping = false;

  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  /// 🌐 URL backend — ChatController hiện đang ở /api/ai/chat
  final String _chatUrl = '${AppConfig.ai}/chat';

  Future<void> _sendMessage() async {
    final msg = _controller.text.trim();
    if (msg.isEmpty || _loading) return;

    setState(() {
      _messages.add({"from": "user", "text": msg});
      _controller.clear();
      _loading = true;
      _aiTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_chatUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          // Nếu endpoint yêu cầu xác thực:
          // 'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'message': msg,
          'userId': widget.userId,
        }),
      );

      String reply;
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(body);
        reply = decoded['reply'] ?? '🤖 AI không phản hồi.';
      } else {
        reply = '❌ Server lỗi (${response.statusCode})';
      }

      setState(() {
        _messages.add({"from": "ai", "text": reply});
        _loading = false;
        _aiTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'from': 'ai',
          'text': '⚠️ Lỗi kết nối backend: ${e.toString()}',
        });
        _loading = false;
        _aiTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Nếu không phải bệnh nhân => ẩn hoàn toàn chat box
    if (widget.role.toLowerCase() != 'patient') {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Nút mở chat
        Positioned(
          bottom: 30,
          right: 30,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.blueAccent,
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(_isOpen ? "Đóng Chat" : "Tư vấn AI"),
            onPressed: () => setState(() => _isOpen = !_isOpen),
          ),
        ),

        // Hộp chat chính
        if (_isOpen)
          Positioned(
            bottom: 90,
            right: 30,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 360,
              height: 460,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.support_agent, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Bác sĩ AI tư vấn 🤖",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nội dung chat
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length + (_aiTyping ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (_aiTyping && i == _messages.length) {
                            return const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: _TypingIndicator(),
                              ),
                            );
                          }

                          final msg = _messages[i];
                          final isUser = msg['from'] == 'user';
                          return Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isUser
                                    // ignore: deprecated_member_use
                                    ? Colors.blueAccent.withOpacity(0.15)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Thanh loading
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(6),
                      child: LinearProgressIndicator(
                        color: Colors.blueAccent,
                        minHeight: 3,
                      ),
                    ),

                  // Ô nhập liệu
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: "Nhập câu hỏi về sức khoẻ...",
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.blueAccent),
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// 🔹 Hiệu ứng “AI đang gõ...”
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final dots = (3 * _controller.value).round().clamp(0, 3);
        return Text(
          "AI đang phản hồi${'.' * dots}",
          style: const TextStyle(
              color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13),
        );
      },
    );
  }
}
