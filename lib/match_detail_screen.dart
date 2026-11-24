import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'api_service.dart';
import 'app_background.dart';
import 'cover_letter_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final String token;
  final int jobId;
  final String jobTitle;
  const MatchDetailScreen({
    super.key,
    required this.token,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool isLoading = true;
  int score = 0;
  List<String> matchedSkills = [];
  List<String> missingSkills = [];
  String? errorText;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final result = await ApiService.getMatchDetail(widget.token, widget.jobId);
    setState(() {
      isLoading = false;
      if (result != null && result['score'] != null) {
        score = result['score'];
        matchedSkills = List<String>.from(result['matchedSkills'] ?? []);
        missingSkills = List<String>.from(result['missingSkills'] ?? []);
      } else {
        errorText = "Couldn't load match details. Upload a resume first.";
      }
    });
  }

  Color get scoreColor {
    if (score >= 70) return const Color(0xFF6FDB9A);
    if (score >= 40) return const Color(0xFFE0B84A);
    return const Color(0xFFE07A6A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17130C),
        elevation: 0,
        title: Text(
          widget.jobTitle,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE8BA48)),
                )
              : errorText != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Concept: CustomPaint - drawing a donut chart directly with no chart library
                      Center(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: CustomPaint(
                            painter: _DonutPainter(
                              percent: score / 100,
                              color: scoreColor,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$score%',
                                    style: TextStyle(
                                      color: scoreColor,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'match',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (matchedSkills.isNotEmpty) ...[
                        _skillSection(
                          'Matched skills',
                          matchedSkills,
                          const Color(0xFF6FDB9A),
                          Icons.check_circle_outline,
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (missingSkills.isNotEmpty)
                        _skillSection(
                          'Missing skills',
                          missingSkills,
                          const Color(0xFFE07A6A),
                          Icons.cancel_outlined,
                        ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CoverLetterScreen(token: widget.token),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                'Write a cover letter for this role',
                                style: TextStyle(
                                  color: Color(0xFF1A1200),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _skillSection(
    String title,
    List<String> skills,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills
              .map(
                (s) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(color: color, fontSize: 12.5),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// Concept: CustomPainter - manually draws two arcs (background ring + progress ring) to form a donut chart
class _DonutPainter extends CustomPainter {
  final double percent;
  final Color color;
  _DonutPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}
