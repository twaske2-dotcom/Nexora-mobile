import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'api_service.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  final String token;

  // When set, analyse THIS specific past upload (opened from History).
  // When null, analyse the latest resume (opened from dashboard/upload).
  final int? resumeId;

  const ResumeAnalysisScreen({super.key, required this.token, this.resumeId});

  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> {
  bool isLoading = true;
  Map<String, dynamic>? data;
  String? errorText;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = widget.resumeId != null
          ? await ApiService.getResumeAnalysisById(widget.token, widget.resumeId!)
          : await ApiService.getResumeAnalysis(widget.token);

      if (!mounted) return;

      if (result != null && result['score'] != null) {
        setState(() {
          data = Map<String, dynamic>.from(result);
          isLoading = false;
          errorText = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorText = "Couldn't load analysis. Upload a resume first.";
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorText = "Couldn't load analysis. Please try again.";
      });
    }
  }

  Color _scoreColor(int score, int max) {
    final ratio = score / max;

    if (ratio >= 0.75) {
      return const Color(0xFF5DCAA5);
    }

    if (ratio >= 0.4) {
      return const Color(0xFFEF9F27);
    }

    return const Color(0xFFF09595);
  }

  Color get _mainColor {
    final currentData = data;

    if (currentData == null) {
      return const Color(0xFFE8BA48);
    }

    final rawScore = currentData['score'];

    final score = rawScore is int
        ? rawScore
        : int.tryParse(rawScore.toString()) ?? 0;

    if (score >= 85) {
      return const Color(0xFF5DCAA5);
    }

    if (score >= 65) {
      return const Color(0xFFEF9F27);
    }

    return const Color(0xFFF09595);
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'contact':
        return Icons.contact_page_outlined;

      case 'experience':
        return Icons.work_outline_rounded;

      case 'impact':
        return Icons.bar_chart_rounded;

      case 'skills':
        return Icons.code_rounded;

      case 'formatting':
        return Icons.view_list_rounded;

      default:
        return Icons.circle;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return const Color(0xFFF09595);

      case 'medium':
        return const Color(0xFFEF9F27);

      default:
        return const Color(0xFF8B93A8);
    }
  }

  IconData _severityIcon(String severity) {
    return severity == 'high'
        ? Icons.error_outline_rounded
        : Icons.info_outline_rounded;
  }

  int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0804),
        elevation: 0,
        title: const Text(
          'Resume Analysis',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8BA48)),
            )
          : errorText != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: Colors.white38,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorText = null;
                          });

                          load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8BA48),
                          foregroundColor: Color(0xFF1A1200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFFE8BA48),
              backgroundColor: const Color(0xFF17130C),
              onRefresh: load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _fileChip(),
                    const SizedBox(height: 18),
                    _scoreHeader(),
                    const SizedBox(height: 14),
                    _statsRow(),
                    const SizedBox(height: 26),
                    _breakdownSection(),
                    const SizedBox(height: 26),
                    _fixesSection(),
                    const SizedBox(height: 22),
                    _AnimatedTapCard(
                      onTap: () {},
                      color: const Color(0xFFE8BA48),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Center(
                          child: Text(
                            'Rewrite with AI',
                            style: TextStyle(
                              color: Color(0xFF1A1200),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _fileChip() {
    final currentData = data;

    final fileName = currentData?['fileName']?.toString() ?? 'Resume';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE8BA48).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          fileName,
          style: const TextStyle(color: Color(0xFFF4D67A), fontSize: 10.5),
        ),
      ),
    );
  }

  Widget _scoreHeader() {
    final currentData = data;

    final score = _intValue(currentData?['score']);

    final label = currentData?['label']?.toString() ?? 'Resume score';

    final dynamic rawDelta = currentData?['delta'];

    final int? delta = rawDelta == null ? null : _intValue(rawDelta);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _DonutPainter(
              percent: (score / 100).clamp(0.0, 1.0),
              color: _mainColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      color: _mainColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'of 100',
                    style: TextStyle(color: Colors.white38, fontSize: 9.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (delta != null) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      delta >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: delta >= 0
                          ? const Color(0xFF5DCAA5)
                          : const Color(0xFFF09595),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${delta >= 0 ? '+' : ''}$delta since last upload',
                      style: TextStyle(
                        color: delta >= 0
                            ? const Color(0xFF5DCAA5)
                            : const Color(0xFFF09595),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statsRow() {
    final currentData = data;

    final ats = _intValue(currentData?['atsScore']);

    final words = _intValue(currentData?['wordCount']);

    final secs = _intValue(currentData?['readSeconds']);

    return Row(
      children: [
        Expanded(
          child: _statTile(
            'ATS readiness',
            '$ats',
            ats >= 70 ? 'parses clean' : 'may get filtered',
            _scoreColor(ats, 100),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statTile(
            'Read time',
            '${secs}s',
            '$words words',
            Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, String sub, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10.5),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  sub,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownSection() {
    final currentData = data;

    final rawCategories = currentData?['categories'];

    final categories = rawCategories is List
        ? rawCategories
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Score breakdown',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        ...categories.map((c) {
          final score = _intValue(c['score']);

          final max = _intValue(c['max']) == 0 ? 100 : _intValue(c['max']);

          final color = _scoreColor(score, max);

          final icon = c['icon']?.toString() ?? '';

          final name = c['name']?.toString() ?? 'Category';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(_iconFor(icon), color: Colors.white38, size: 15),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                          Text(
                            '$score/$max',
                            style: TextStyle(color: color, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (score / max).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _fixesSection() {
    final currentData = data;

    final rawFixes = currentData?['fixes'];

    final fixes = rawFixes is List
        ? rawFixes
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];

    if (fixes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF5DCAA5).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF5DCAA5),
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'No major issues found - nice work!',
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Priority fixes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'sorted by impact',
              style: TextStyle(color: Colors.white30, fontSize: 10.5),
            ),
          ],
        ),
        const SizedBox(height: 11),
        ...fixes.map((f) {
          final severity = f['severity']?.toString() ?? 'low';

          final color = _severityColor(severity);

          final title = f['title']?.toString() ?? 'Improvement';

          final detail = f['detail']?.toString() ?? '';

          final gain = f['gain']?.toString() ?? '0';

          return _AnimatedTapCard(
            onTap: () {},
            color: color,
            margin: const EdgeInsets.only(bottom: 9),
            background: color.withValues(alpha: 0.08),
            border: color.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_severityIcon(severity), color: color, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF5DCAA5,
                          ).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+$gain',
                          style: const TextStyle(
                            color: Color(0xFF5DCAA5),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 23),
                    child: Text(
                      detail,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _AnimatedTapCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final Color? background;
  final Color? border;
  final EdgeInsets? margin;

  const _AnimatedTapCard({
    required this.child,
    required this.onTap,
    required this.color,
    this.background,
    this.border,
    this.margin,
  });

  @override
  State<_AnimatedTapCard> createState() => _AnimatedTapCardState();
}

class _AnimatedTapCardState extends State<_AnimatedTapCard> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          scale = 0.97;
        });
      },
      onTapUp: (_) {
        setState(() {
          scale = 1.0;
        });
      },
      onTapCancel: () {
        setState(() {
          scale = 1.0;
        });
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.background ?? widget.color,
            borderRadius: BorderRadius.circular(13),
            border: widget.border != null
                ? Border.all(color: widget.border!)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;
  final Color color;

  _DonutPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = size.width / 2 - 8;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percent,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}
