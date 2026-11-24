import 'package:flutter/material.dart';
import 'api_service.dart';
import 'app_background.dart';
import 'resume_analysis_screen.dart';

class ResumeHistoryScreen extends StatefulWidget {
  final String token;
  const ResumeHistoryScreen({super.key, required this.token});

  @override
  State<ResumeHistoryScreen> createState() => _ResumeHistoryScreenState();
}

class _ResumeHistoryScreenState extends State<ResumeHistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final result = await ApiService.getResumeHistory(widget.token);
    setState(() {
      history = result;
      isLoading = false;
    });
  }

  // Concept: turns an ISO timestamp string into a short readable date
  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return iso;
    }
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF6FDB9A);
    if (score >= 50) return const Color(0xFFE0B84A);
    return const Color(0xFFE07A6A);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        title: const Text(
          'Resume History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF7B5CF0)),
                )
              : history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: Colors.white.withValues(alpha: 0.25),
                        size: 52,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No uploads yet',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF7B5CF0),
                  backgroundColor: const Color(0xFF1A1530),
                  onRefresh: loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final score = item['quality'] as int? ?? 0;
                      final rawId = item['resumeId'];
                      final resumeId = rawId is int
                          ? rawId
                          : int.tryParse(rawId?.toString() ?? '');
                      return GestureDetector(
                        onTap: resumeId == null
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ResumeAnalysisScreen(
                                      token: widget.token,
                                      resumeId: resumeId,
                                    ),
                                  ),
                                );
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF7B5CF0,
                                  ).withValues(alpha: 0.15),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFFB06AB3),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['fileName'] ?? 'Resume',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(item['uploadedAt'] ?? ''),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11.5,
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
                                  color: _scoreColor(
                                    score,
                                  ).withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$score/100',
                                  style: TextStyle(
                                    color: _scoreColor(score),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
