import 'package:flutter/material.dart';

import 'app_background.dart';
import 'nexora_roadmap_screen.dart';
import 'nexora_chat_screen.dart';
import 'nexora_interview_screen.dart';
import 'nexora_text_interview_screen.dart';

/// Nexora Ascend — the AI mentor hub. Everything inside is personalized to the
/// user's uploaded resume (role/domain detected by Nexa). Real-time.
class NexoraAscendScreen extends StatelessWidget {
  final String token;
  const NexoraAscendScreen({super.key, required this.token});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Nexora Ascend',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)]),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF7B5CF0).withValues(alpha: 0.45),
                              blurRadius: 22)
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meet Nexa',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text('Your AI mentor — tuned to your resume',
                              style: TextStyle(color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _AscendCard(
                  icon: Icons.route_rounded,
                  title: 'My Roadmap',
                  subtitle:
                      'A step-by-step path built from your resume — Foundation, Growth, Top-tier, plus insider resources.',
                  onTap: () =>
                      _open(context, NexoraRoadmapScreen(token: token)),
                ),
                const SizedBox(height: 14),
                _AscendCard(
                  icon: Icons.forum_rounded,
                  title: 'Learn with Nexa',
                  subtitle:
                      'Ask anything about your career, skills or interviews. Nexa answers based on your resume.',
                  onTap: () => _open(context, NexoraChatScreen(token: token)),
                ),
                const SizedBox(height: 14),
                _AscendCard(
                  icon: Icons.videocam_rounded,
                  title: 'Live Interview',
                  subtitle:
                      'A real mock interview: camera on, Nexa asks aloud, you answer by voice. Get body-language + confidence feedback.',
                  onTap: () =>
                      _open(context, NexoraInterviewScreen(token: token)),
                ),
                const SizedBox(height: 14),
                _AscendCard(
                  icon: Icons.keyboard_rounded,
                  title: 'Text Interview',
                  subtitle:
                      'Prefer typing? Answer Nexa\'s questions in text and still get a full scored report.',
                  onTap: () =>
                      _open(context, NexoraTextInterviewScreen(token: token)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AscendCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AscendCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2244)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)]),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12.5, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
