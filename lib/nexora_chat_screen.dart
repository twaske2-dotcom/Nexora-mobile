import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_background.dart';

/// Learn with Nexa — resume-aware mentor chat.
class NexoraChatScreen extends StatefulWidget {
  final String token;
  const NexoraChatScreen({super.key, required this.token});

  @override
  State<NexoraChatScreen> createState() => _NexoraChatScreenState();
}

class _ChatMsg {
  final String text;
  final bool fromUser;
  _ChatMsg(this.text, this.fromUser);
}

class _NexoraChatScreenState extends State<NexoraChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMsg> _messages = [
    _ChatMsg(
        "Hi, I'm Nexa 👋 I've got your resume in mind. Ask me anything about your skills, roadmap or interviews.",
        false),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMsg(text, true));
      _sending = true;
      _input.clear();
    });
    _scrollToEnd();
    try {
      final reply = await ApiService.mentorChat(widget.token, text);
      if (!mounted) return;
      setState(() => _messages.add(_ChatMsg(reply, false)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add(_ChatMsg(e.toString(), false)));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17130C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Learn with Nexa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (_sending && i == _messages.length) {
                      return _bubble(_ChatMsg('Nexa is typing…', false),
                          muted: true);
                    }
                    return _bubble(_messages[i]);
                  },
                ),
              ),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubble(_ChatMsg m, {bool muted = false}) {
    final isUser = m.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)])
              : null,
          color: isUser ? null : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: const Color(0xFF3A2F17)),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: muted ? Colors.white54 : (isUser ? const Color(0xFF1A1200) : Colors.white),
            fontSize: 13.5,
            height: 1.4,
            fontStyle: muted ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF14100A),
        border: Border(top: BorderSide(color: Color(0xFF3A2F17))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask Nexa anything…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8BA48)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)]),
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, color: Color(0xFF1A1200)),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Color(0xFF1A1200), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
