import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'app_background.dart';

/// Nexa's interview report. Shows Overall + three sections the user asked for:
/// Body, Confidence, and Questions & Answers. Every field is parsed
/// defensively so a partial/odd payload still renders instead of crashing.
class NexoraInterviewFeedbackScreen extends StatelessWidget {
  final Map<String, dynamic> feedback;

  /// Path to the recorded call audio (live interview only). When present, the
  /// student can share/save the recording from the report.
  final String? recordingPath;

  const NexoraInterviewFeedbackScreen({
    super.key,
    required this.feedback,
    this.recordingPath,
  });

  int _score(dynamic node) {
    if (node is Map && node['score'] != null) {
      final v = node['score'];
      if (v is num) return v.round().clamp(0, 100);
      return int.tryParse(v.toString())?.clamp(0, 100) ?? 0;
    }
    return 0;
  }

  String _text(dynamic node, String key) {
    if (node is Map && node[key] != null) return node[key].toString();
    return '';
  }

  Color _scoreColor(int s) {
    if (s >= 75) return const Color(0xFF6FDB9A);
    if (s >= 50) return const Color(0xFFE0B84A);
    return const Color(0xFFE07A6A);
  }

  @override
  Widget build(BuildContext context) {
    final overall = feedback['overall'];
    final body = feedback['body'];
    final confidence = feedback['confidence'];
    final qa = (feedback['qa'] is List) ? feedback['qa'] as List : const [];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Your Interview Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _overallCard(_score(overall), _text(overall, 'summary')),
              if (recordingPath != null) ...[
                const SizedBox(height: 12),
                _recordingBar(),
              ],
              const SizedBox(height: 16),
              _sectionCard(
                icon: Icons.accessibility_new_rounded,
                title: 'Body Language',
                score: _score(body),
                notes: _text(body, 'notes'),
              ),
              const SizedBox(height: 12),
              _sectionCard(
                icon: Icons.record_voice_over_rounded,
                title: 'Confidence',
                score: _score(confidence),
                notes: _text(confidence, 'notes'),
              ),
              const SizedBox(height: 20),
              const Text('Questions & Answers',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (qa.isEmpty)
                Text(
                  'No per-question notes this time — try another round for a detailed breakdown.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                )
              else
                ...qa.map((item) => _qaCard(item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overallCard(int score, String summary) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _scoreRing(score, Colors.white, Colors.white24, big: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  summary.isEmpty ? 'Great effort — keep practicing!' : summary,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordingBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2244)),
      ),
      child: Row(
        children: [
          const Icon(Icons.multitrack_audio_rounded,
              color: Color(0xFF6FDB9A), size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Your full interview recording is saved.',
                style: TextStyle(color: Colors.white, fontSize: 13.5)),
          ),
          TextButton.icon(
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(recordingPath!)],
                  text: 'My Nexora mock interview recording',
                ),
              );
            },
            icon: const Icon(Icons.ios_share_rounded,
                color: Color(0xFFB79CFF), size: 18),
            label: const Text('Share',
                style: TextStyle(color: Color(0xFFB79CFF))),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required int score,
    required String notes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFB79CFF), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700)),
              ),
              _scoreRing(score, _scoreColor(score),
                  _scoreColor(score).withValues(alpha: 0.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            notes.isEmpty ? 'No notes for this section.' : notes,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13.5, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _qaCard(dynamic item) {
    final q = _text(item, 'question');
    final a = _text(item, 'answer');
    final fb = _text(item, 'feedback');
    final s = _score(item);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(q.isEmpty ? 'Question' : q,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35)),
              ),
              const SizedBox(width: 10),
              _scoreRing(s, _scoreColor(s),
                  _scoreColor(s).withValues(alpha: 0.2), small: true),
            ],
          ),
          if (a.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Your answer: $a',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12.5,
                    height: 1.4,
                    fontStyle: FontStyle.italic)),
          ],
          if (fb.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFF7B5CF0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_rounded,
                      color: Color(0xFFB79CFF), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(fb,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreRing(int score, Color color, Color track,
      {bool big = false, bool small = false}) {
    final size = big ? 62.0 : (small ? 40.0 : 50.0);
    final fontSize = big ? 18.0 : (small ? 12.0 : 15.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100.0,
              strokeWidth: big ? 5 : 4,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text('$score',
              style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
