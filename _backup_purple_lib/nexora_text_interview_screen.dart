import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_background.dart';
import 'nexora_interview_feedback_screen.dart';

/// Text-based mock interview. No camera/mic — just Nexa's questions and
/// typed answers, so it works on any device the moment the backend is live.
class NexoraTextInterviewScreen extends StatefulWidget {
  final String token;
  const NexoraTextInterviewScreen({super.key, required this.token});

  @override
  State<NexoraTextInterviewScreen> createState() =>
      _NexoraTextInterviewScreenState();
}

class _NexoraTextInterviewScreenState extends State<NexoraTextInterviewScreen> {
  final TextEditingController _answer = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _submitting = false;

  String _role = 'Candidate';
  List<String> _questions = [];
  final List<Map<String, String>> _transcript = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getInterviewQuestions(widget.token);
      final qs = (data['questions'] is List)
          ? (data['questions'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : <String>[];
      if (!mounted) return;
      setState(() {
        _role = (data['role'] ?? 'Candidate').toString();
        _questions = qs;
        _loading = false;
        if (qs.isEmpty) {
          _error = 'Nexa couldn\'t prepare questions right now. Please try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _next() async {
    final text = _answer.text.trim();
    if (text.isEmpty || _submitting) return;

    _transcript.add({'question': _questions[_index], 'answer': text});
    _answer.clear();

    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    setState(() => _submitting = true);
    try {
      final feedback = await ApiService.getInterviewFeedback(
        widget.token,
        transcript: _transcript,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NexoraInterviewFeedbackScreen(feedback: feedback),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Text Interview',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: AppBackground(
        child: SafeArea(child: _content()),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B5CF0)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE07A6A), size: 40),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5CF0)),
                child: const Text('Try again',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_submitting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF7B5CF0)),
            SizedBox(height: 16),
            Text('Nexa is reviewing your answers…',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    }

    final total = _questions.length;
    final progress = (_index + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$_role  •  Question ${_index + 1} of $total',
                  style: const TextStyle(
                      color: Color(0xFFB79CFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFF2A2244),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF7B5CF0)),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2244)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)]),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_questions[_index],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.4,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: TextField(
              controller: _answer,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: 'Type your answer…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7B5CF0)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CF0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _index < _questions.length - 1
                    ? 'Next question'
                    : 'Finish & get feedback',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
