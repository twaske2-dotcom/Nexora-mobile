import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'app_background.dart';
import 'notification_service.dart';

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

    NotificationService.syncFollowUps(apps);
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
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17130C),
        elevation: 0,
        title: const Text('My Progress', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE8BA48)),
                )
              : RefreshIndicator(
                  color: const Color(0xFFE8BA48),
                  backgroundColor: const Color(0xFF17130C),
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
                        'Application tracker',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap an application to update its stage. Companies do not share status with apps, so you update it here.',
                        style: TextStyle(
                            color: Colors.white38, fontSize: 11.5, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      if (applications.isNotEmpty) _pipeline(),
                      const SizedBox(height: 12),
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

  static const _stages = [
    ('APPLIED', 'Applied', Color(0xFF8FB8FF)),
    ('SHORTLISTED', 'Shortlisted', Color(0xFFE0B84A)),
    ('INTERVIEW', 'Interview', Color(0xFFC79BFF)),
    ('OFFER', 'Offer', Color(0xFF6FDB9A)),
    ('REJECTED', 'Rejected', Color(0xFFE07A6A)),
  ];

  (String, Color) _stageInfo(String status) {
    final key = status.toUpperCase() == 'INTERVIEWED' ? 'INTERVIEW' : status.toUpperCase();
    for (final (code, label, color) in _stages) {
      if (code == key) return (label, color);
    }
    return ('Applied', const Color(0xFF8FB8FF));
  }

  int _daysSince(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return 0;
    return DateTime.now().difference(d).inDays;
  }

  Widget _pipeline() {
    final counts = <String, int>{};
    for (final raw in applications) {
      if (raw is Map) {
        final label = _stageInfo((raw['status'] ?? 'APPLIED').toString()).$1;
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (_, label, color) in _stages)
            if ((counts[label] ?? 0) > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text('${counts[label]} $label',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
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
    final (label, color) = _stageInfo(status);
    final meta = [company, location].where((s) => s.isNotEmpty).join(' · ');
    final days = _daysSince((app['appliedAt'] ?? '').toString());
    final waiting = _daysSince((app['statusUpdatedAt'] ?? '').toString());
    final needsFollowUp = label == 'Applied' && waiting >= 7;
    final match = app['matchScore'];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openSheet(app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: needsFollowUp
                ? const Color(0xFFE0B84A).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.work_outline_rounded, color: color, size: 19),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              [
                days == 0 ? 'Applied today' : 'Applied $days d ago',
                if (match is num) '${match.round()}% match',
              ].join(' · '),
              style: const TextStyle(color: Colors.white38, fontSize: 11.5),
            ),
            if (needsFollowUp)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        size: 14, color: Color(0xFFE0B84A)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'No update for $waiting days. Time for a follow-up email.',
                        style: const TextStyle(
                            color: Color(0xFFE0B84A), fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            if ((app['notes'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(app['notes'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12, height: 1.35)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(Map<String, dynamic> app) async {
    final id = app['id'];
    if (id is! int) return;
    final notes = TextEditingController(text: (app['notes'] ?? '').toString());
    final current = _stageInfo((app['status'] ?? 'APPLIED').toString()).$1;
    String? chosen;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((app['title'] ?? 'Job').toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text((app['company'] ?? '').toString(),
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Stage',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (_, label, color) in _stages)
                    ChoiceChip(
                      label: Text(label),
                      selected: (chosen ?? current) == label,
                      selectedColor: color.withValues(alpha: 0.28),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: (chosen ?? current) == label
                            ? color
                            : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      onSelected: (_) => setSheet(() => chosen = label),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notes,
                maxLines: 3,
                minLines: 2,
                maxLength: 300,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Notes (recruiter name, next step...)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  counterStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if ((app['jobUrl'] ?? '').toString().startsWith('https'))
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(app['jobUrl'].toString()),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open job'),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ApiService.deleteApplication(widget.token, id);
                      if (mounted) _load();
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: Color(0xFFE07A6A)),
                    label: const Text('Remove',
                        style: TextStyle(color: Color(0xFFE07A6A))),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8BA48),
                      foregroundColor: const Color(0xFF1A1200),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      String? code;
                      for (final (c, l, _) in _stages) {
                        if (l == (chosen ?? current)) code = c;
                      }
                      final ok = await ApiService.updateApplication(
                        widget.token,
                        id,
                        status: code,
                        notes: notes.text.trim(),
                      );
                      if (!mounted) return;
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not save. Try again.')),
                        );
                      }
                      _load();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    notes.dispose();
  }
}
