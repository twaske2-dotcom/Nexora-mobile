import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'resume_upload_screen.dart';
import 'resume_history_screen.dart';
import 'external_jobs_screen.dart';
import 'help_screen.dart';
import 'nexora_logo.dart';
import 'login_screen.dart';
import 'match_detail_screen.dart';

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
    loadJobs();
  }

  Future<void> loadJobs() async {
    try {
      final result = await ApiService.getJobs(widget.token);

      Map<String, dynamic> scores = {};

      try {
        scores = await ApiService.getMatchScores(widget.token);
      } catch (_) {
        scores = {};
      }

      if (!mounted) return;

      setState(() {
        jobs = result;
        matchScores = scores;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        jobs = [];
        matchScores = {};
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final openCount = jobs.where((j) {
      if (j is! Map) return false;

      final status = (j['status'] ?? '').toString().toUpperCase();

      return status == 'OPEN';
    }).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7B5CF0),
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResumeUploadScreen(token: widget.token),
            ),
          );
        },
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D0D14),
                  Color(0xFF1A1530),
                  Color(0xFF0D0D14),
                ],
              ),
            ),
          ),

          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B5CF0).withValues(alpha: 0.25),
                    const Color(0xFF7B5CF0).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF7B5CF0),
              backgroundColor: const Color(0xFF1A1530),
              onRefresh: loadJobs,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF151022),
                                  border: Border.all(
                                    color: const Color(0xFF2A2244),
                                  ),
                                ),
                                child: CustomPaint(
                                  painter: NexoraLogoPainter(),
                                ),
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
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HelpScreen(),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7B5CF0),
                                        Color(0xFFB06AB3),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF7B5CF0,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResumeHistoryScreen(
                                        token: widget.token,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.history_rounded,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExternalJobsScreen(
                                        token: widget.token,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.travel_explore_rounded,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              GestureDetector(
                                onTap: _logout,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'Find your next role',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  label: 'Open roles',
                                  value: '$openCount',
                                  icon: Icons.work_outline_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  label: 'Total listed',
                                  value: '${jobs.length}',
                                  icon: Icons.grid_view_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
                      child: Row(
                        children: [
                          const Text(
                            'Open positions',
                            style: TextStyle(
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
                      ),
                    ),
                  ),

                  if (isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7B5CF0),
                          ),
                        ),
                      ),
                    )
                  else if (jobs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.work_off_outlined,
                                color: Colors.white.withValues(alpha: 0.25),
                                size: 52,
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No jobs found yet',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
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

                              if (jobId == null) {
                                return;
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MatchDetailScreen(
                                    token: widget.token,
                                    jobId: jobId,
                                    jobTitle: job['title'] ?? 'Job',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.045),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF7B5CF0),
                                              Color(0xFFB06AB3),
                                            ],
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                            color: _matchColor(
                                              score,
                                            ).withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
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
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFB06AB3), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
