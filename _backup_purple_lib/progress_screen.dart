import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_background.dart';

// The single feature that groups Resume score / Applied / Matches.
// Opened from the dashboard "My Progress" tile.
class ProgressScreen extends StatefulWidget {
  final String token;

  const ProgressScreen({super.key, required this.token});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool isLoading = true;

  int resumeScore = 0;
  int appliedCount = 0;
  int matchesCount = 0;
  List<dynamic> applications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Map<String, dynamic> scores = {};
    List<dynamic> history = [];
    List<dynamic> apps = [];

    try {
      scores = await ApiService.getMatchScores(widget.token);
    } catch (_) {}
    try {
      history = await ApiService.getResumeHistory(widget.token);
    } catch (_) {}
    try {
      apps = await ApiService.getApplications(widget.token);
    } catch (_) {}

    // Resume score = quality of the latest uploaded resume (newest first).
    int score = 0;
    for (final item in history) {
      if (item is Map) {
        final q = item['quality'] ?? item['score'] ?? item['qualityScore'];
        if (q is num) {
          score = q.round().clamp(0, 100);
          break;
        }
        if (q is String) {
          final parsed = num.tryParse(q);
          if (parsed != null) {
            score = parsed.round().clamp(0, 100);
            break;
          }
        }
      }
    }

    // Matches = jobs scoring 60% or higher.
    int matches = 0;
    for (final value in scores.values) {
      if (value is num && value >= 60) {
        matches++;
      } else if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null && parsed >= 60) matches++;
      }
    }

    if (!mounted) return;
    setState(() {
      resumeScore = score;
      matchesCount = matches;
      applications = apps;
      appliedCount = apps.length;
      isLoading = false;
    });
  }

  Color _scoreColor(int s) {
    if (s >= 80) return const Color(0xFF6FDB9A);
    if (s >= 50) return const Color(0xFFE0B84A);
    return const Color(0xFFE07A6A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        title: const Text('My Progress', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7B5CF0)),
                )
              : RefreshIndicator(
                  color: const Color(0xFF7B5CF0),
                  backgroundColor: const Color(0xFF1A1530),
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _statCard('$resumeScore',
                                'Resume score', _scoreColor(resumeScore)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statCard('$appliedCount', 'Applied',
                                Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statCard('$matchesCount', 'Matches',
                                const Color(0xFFE0B84A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Your applications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (applications.isEmpty)
                        _emptyApplications()
                      else
                        ...applications.map(_applicationCard),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: double.parse(value)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${v.round()}',
              style: TextStyle(
                color: color,
                fontSize: 26,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _emptyApplications() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        children: [
          Icon(Icons.work_off_outlined, color: Colors.white38, size: 30),
          SizedBox(height: 10),
          Text(
            "You haven't applied to any jobs yet.\nApply from Find Jobs to see them here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _applicationCard(dynamic raw) {
    if (raw is! Map) return const SizedBox.shrink();
    final app = Map<String, dynamic>.from(raw);
    final title = (app['title'] ?? 'Job').toString();
    final company = (app['company'] ?? '').toString();
    final location = (app['location'] ?? '').toString();
    final status = (app['status'] ?? 'APPLIED').toString();
    final meta = [company, location].where((s) => s.isNotEmpty).join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
              ),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    )),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF6FDB9A).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF6FDB9A),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
