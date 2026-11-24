import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'app_background.dart';
import 'resume_upload_screen.dart';
import 'resume_history_screen.dart';
import 'resume_analysis_screen.dart';
import 'resume_builder_screen.dart';
import 'cover_letter_screen.dart';
import 'external_jobs_screen.dart';
import 'progress_screen.dart';
import 'help_screen.dart';
import 'nexora_logo.dart';
import 'login_screen.dart';
import 'nexora_ascend_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _cacheKey = 'dash_top_jobs_v1';

  List<dynamic> jobs = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _showCached(); // instant: last known matches appear immediately
    loadData(); // then refresh live in the background
  }

  Future<void> _showCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || !mounted || jobs.isNotEmpty) return;
      final data = jsonDecode(raw);
      if (data is List && data.isNotEmpty) {
        setState(() {
          jobs = data;
          isLoading = false;
        });
      }
    } catch (_) {}
  }

  // Live top matches from the job provider, personalised from the resume
  // (backend builds the search from the resume's skills when `what` is empty).
  Future<void> loadData() async {
    try {
      final result = await ApiService.searchExternalJobs(
        widget.token,
        what: '',
      );
      final list = List<dynamic>.from(result);
      int pct(dynamic j) =>
          (j is Map && j['matchPercent'] is num)
              ? (j['matchPercent'] as num).round()
              : -1;
      list.sort((a, b) => pct(b).compareTo(pct(a)));
      final top = list.take(4).toList();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(top));
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        jobs = top;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false); // keep cached list if any
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF14100A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Log out?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, log out',
              style: TextStyle(
                color: Color(0xFFC48A0A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('auth_token');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Color _matchColor(int score) {
    if (score >= 70) {
      return const Color(0xFF6FDB9A);
    }

    if (score >= 40) {
      return const Color(0xFFE0B84A);
    }

    return const Color(0xFFE07A6A);
  }

  void _open(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFFE8BA48),
            backgroundColor: const Color(0xFF17130C),
            onRefresh: loadData,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        const Text(
                          "Let's get you\nhired.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            height: 1.15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildProgressTile(),
                        const SizedBox(height: 22),
                        _sectionDivider('Tools'),
                        const SizedBox(height: 14),
                        _buildToolsGrid(),
                        const SizedBox(height: 28),
                        _sectionDivider('Top matches for you'),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),
                _buildJobList(),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF17130C),
            border: Border.all(color: const Color(0xFF3A2F17)),
          ),
          child: CustomPaint(painter: NexoraLogoPainter()),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nexora',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Welcome back',
                style: TextStyle(color: Colors.white38, fontSize: 11.5),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _open(const HelpScreen()),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8BA48).withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const _AnimatedFeatureIcon(
              icon: Icons.auto_awesome,
              anim: IconAnim.twinkle,
              color: Color(0xFF1A1200),
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _open(SettingsScreen(onLogout: _confirmLogout)),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Color(0xFFF4D67A),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // The one feature that groups Resume score / Applied / Matches.
  // Tapping opens the Progress screen where those numbers live.
  Widget _buildProgressTile() {
    return GestureDetector(
      onTap: () => _open(ProgressScreen(token: widget.token)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8BA48).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x2E1A1200),
              ),
              child: const _AnimatedFeatureIcon(
                icon: Icons.insights_rounded,
                anim: IconAnim.twinkle,
                color: Color(0xFF1A1200),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Progress',
                    style: TextStyle(
                      color: Color(0xFF1A1200),
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Resume score, applications & job matches',
                    style: TextStyle(color: Color(0xB31A1200), fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A1200), size: 20),
          ],
        ),
      ),
    );
  }

  // Modern 2-column grid of feature tiles — the layout Tejas picked.
  Widget _buildToolsGrid() {
    final tools = [
      _Tool('Nexora Ascend', 'AI mentor Nexa', Icons.rocket_launch_rounded,
          IconAnim.twinkle, () => _open(NexoraAscendScreen(token: widget.token))),
      _Tool('Upload Resume', 'Add your resume', Icons.upload_rounded,
          IconAnim.bob, () => _open(ResumeUploadScreen(token: widget.token))),
      _Tool('Resume Analysis', 'Score & fixes', Icons.auto_awesome,
          IconAnim.twinkle, () => _open(ResumeAnalysisScreen(token: widget.token))),
      _Tool('Resume Builder', 'Create a resume', Icons.settings_suggest_rounded,
          IconAnim.spin, () => _open(ResumeBuilderScreen(token: widget.token))),
      _Tool('Cover Letter', 'AI-written letter', Icons.mail_outline_rounded,
          IconAnim.sway, () => _open(CoverLetterScreen(token: widget.token))),
      _Tool('Find Jobs', 'Search openings', Icons.work_outline_rounded,
          IconAnim.bob, () => _open(ExternalJobsScreen(token: widget.token))),
      _Tool('History', 'Past resumes', Icons.history_rounded,
          IconAnim.spin, () => _open(ResumeHistoryScreen(token: widget.token))),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.38,
      children: tools.map((t) => _ToolTile(tool: t)).toList(),
    );
  }

  Widget _sectionDivider(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  Widget _buildJobList() {
    if (isLoading && jobs.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          childCount: 3,
        ),
      );
    }

    if (jobs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
          child: GestureDetector(
            onTap: () => _open(ExternalJobsScreen(token: widget.token)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF3A2F17)),
              ),
              child: const Text(
                'Upload your resume to see live job matches here.',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final rawJob = jobs[index];
        if (rawJob is! Map) return const SizedBox.shrink();

        final title = (rawJob['title'] ?? '').toString();
        final company = (rawJob['company'] ?? '').toString();
        final location = (rawJob['location'] ?? '').toString();
        final pct = rawJob['matchPercent'];
        final score = pct is num ? pct.round().clamp(0, 100) : null;

        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
          child: GestureDetector(
            onTap: () => _open(ExternalJobsScreen(token: widget.token)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [company, location]
                              .where((e) => e.isNotEmpty)
                              .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (score != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _matchColor(score).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$score%',
                        style: TextStyle(
                          color: _matchColor(score),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }, childCount: jobs.length),
    );
  }
}

// Which animation an icon should loop.
enum IconAnim { bob, twinkle, spin, sway }

// A single feature in the tools grid.
class _Tool {
  final String title;
  final String subtitle;
  final IconData icon;
  final IconAnim anim;
  final VoidCallback onTap;

  const _Tool(this.title, this.subtitle, this.icon, this.anim, this.onTap);
}

// A modern grid tile with an animated icon, title and subtitle.
class _ToolTile extends StatelessWidget {
  final _Tool tool;

  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tool.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8BA48).withValues(alpha: 0.9),
                    const Color(0xFFC48A0A).withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: _AnimatedFeatureIcon(
                icon: tool.icon,
                anim: tool.anim,
                color: Color(0xFF1A1200),
                size: 19,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tool.subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// An icon that loops a small animation suited to the feature it represents.
class _AnimatedFeatureIcon extends StatefulWidget {
  final IconData icon;
  final IconAnim anim;
  final Color color;
  final double size;

  const _AnimatedFeatureIcon({
    required this.icon,
    required this.anim,
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedFeatureIcon> createState() => _AnimatedFeatureIconState();
}

class _AnimatedFeatureIconState extends State<_AnimatedFeatureIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon, color: widget.color, size: widget.size);

    // RepaintBoundary: each icon repaints on its own layer, so the animation
    // never forces the whole dashboard to redraw. Tickers also pause
    // automatically while another screen is open on top (TickerMode).
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = _c.value; // 0 -> 1
          switch (widget.anim) {
            case IconAnim.spin:
              return Transform.rotate(angle: t * 2 * math.pi, child: child);
            case IconAnim.bob:
              final dy = math.sin(t * 2 * math.pi * 3) * 3.0;
              return Transform.translate(offset: Offset(0, dy), child: child);
            case IconAnim.sway:
              final angle = math.sin(t * 2 * math.pi * 2) * 0.22;
              return Transform.rotate(angle: angle, child: child);
            case IconAnim.twinkle:
              final phase = 0.5 - 0.5 * math.cos(t * 2 * math.pi * 2.2);
              final scale = 1 + 0.18 * phase;
              return Transform.rotate(
                angle: 0.18 * phase,
                child: Transform.scale(scale: scale, child: child),
              );
          }
        },
        child: icon,
      ),
    );
  }
}
