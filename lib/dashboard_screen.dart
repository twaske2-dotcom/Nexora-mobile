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
import 'match_detail_screen.dart';
import 'nexora_ascend_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String token;

  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> jobs = [];

  bool isLoading = true;

  Map<String, dynamic> matchScores = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // Dashboard sirf grid + job feed dikhata hai. Resume score / applied /
  // matches ab "My Progress" feature ke andar khulte hain, yaha inline nahi.
  Future<void> loadData() async {
    List<dynamic> jobResult = [];
    Map<String, dynamic> scores = {};

    try {
      jobResult = await ApiService.getJobs(widget.token);
    } catch (_) {
      jobResult = [];
    }

    try {
      scores = await ApiService.getMatchScores(widget.token);
    } catch (_) {
      scores = {};
    }

    if (!mounted) return;

    setState(() {
      jobs = jobResult;
      matchScores = scores;
      isLoading = false;
    });
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15102A),
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
                color: Color(0xFFB06AB3),
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

  int? _scoreForJob(dynamic job) {
    if (job is! Map) {
      return null;
    }

    final jobId = job['jobId'];

    if (jobId == null) {
      return null;
    }

    final value = matchScores[jobId.toString()];

    if (value is num) {
      return value.round().clamp(0, 100);
    }

    if (value is String) {
      final parsed = num.tryParse(value);

      if (parsed != null) {
        return parsed.round().clamp(0, 100);
      }
    }

    return null;
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
      backgroundColor: const Color(0xFF0D0D14),
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF7B5CF0),
            backgroundColor: const Color(0xFF1A1530),
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
                          "Let's get you\nhired, Tejas.",
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
                        _sectionDivider('For you'),
                        const SizedBox(height: 14),
                        _buildTipCard(),
                        const SizedBox(height: 8),
                        if (!isLoading && jobs.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _sectionDivider('Top job matches'),
                        ],
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
            color: const Color(0xFF151022),
            border: Border.all(color: const Color(0xFF2A2244)),
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
                colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B5CF0).withValues(alpha: 0.35),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const _AnimatedFeatureIcon(
              icon: Icons.auto_awesome,
              anim: IconAnim.twinkle,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _confirmLogout,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white70,
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
            colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B5CF0).withValues(alpha: 0.35),
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
                color: Colors.white.withValues(alpha: 0.18),
              ),
              child: const _AnimatedFeatureIcon(
                icon: Icons.insights_rounded,
                anim: IconAnim.twinkle,
                color: Colors.white,
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
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Resume score, applications & job matches',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x3D7B5CF0), Color(0x1AB06AB3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4D7B5CF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _AnimatedFeatureIcon(
                icon: Icons.tips_and_updates_outlined,
                anim: IconAnim.twinkle,
                color: Color(0xFFB06AB3),
                size: 15,
              ),
              SizedBox(width: 7),
              Text(
                'TIP OF THE DAY',
                style: TextStyle(
                  color: Color(0xFFB06AB3),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Add measurable results (like "boosted sales by 20%"). '
            'Recruiters scan for numbers first.',
            style: TextStyle(
              color: Color(0xFFE7E2F5),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList() {
    if (isLoading || jobs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final rawJob = jobs[index];

        if (rawJob is! Map) {
          return const SizedBox.shrink();
        }

        final job = Map<String, dynamic>.from(rawJob);
        final status = (job['status'] ?? '').toString();
        final isOpen = status.toUpperCase() == 'OPEN';
        final score = _scoreForJob(job);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: GestureDetector(
            onTap: () {
              final jobId = job['jobId'];
              if (jobId == null) return;
              _open(
                MatchDetailScreen(
                  token: widget.token,
                  jobId: jobId,
                  jobTitle: job['title'] ?? 'Job',
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
                          ),
                        ),
                        child: const Icon(
                          Icons.work_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (job['title'] ?? '').toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${job['location'] ?? ''} · ${job['experienceRequired'] ?? 0} yrs exp',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isOpen
                                      ? const Color(0xFF3E9C63)
                                      : const Color(0xFF8A8A8A))
                                  .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isOpen
                                ? const Color(0xFF6FDB9A)
                                : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (score != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _matchColor(score).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt,
                                size: 12,
                                color: _matchColor(score),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$score% match',
                                style: TextStyle(
                                  color: _matchColor(score),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((job['requiredSkills'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job['requiredSkills'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12.5,
                        height: 1.4,
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
                    const Color(0xFF7B5CF0).withValues(alpha: 0.9),
                    const Color(0xFFB06AB3).withValues(alpha: 0.9),
                  ],
                ),
              ),
              child: _AnimatedFeatureIcon(
                icon: tool.icon,
                anim: tool.anim,
                color: Colors.white,
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

    return AnimatedBuilder(
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
    );
  }
}