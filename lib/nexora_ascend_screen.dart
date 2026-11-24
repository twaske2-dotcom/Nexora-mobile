import 'package:flutter/material.dart';

import 'nexora_roadmap_screen.dart';
import 'nexora_chat_screen.dart';
import 'nexora_placement_screen.dart';

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
    return AscendPage(
      title: 'Nexora Ascend',
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
                    gradient: ascendGradient,
                    boxShadow: [
                      BoxShadow(
                        color: ascendGold.withValues(alpha: 0.45),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF231A07),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meet Nexa',
                        style: TextStyle(
                          color: ascendInk,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your AI mentor — tuned to your resume',
                        style: TextStyle(color: ascendMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _AscendCard(
              icon: Icons.workspace_premium_rounded,
              title: 'Career Pulse',
              subtitle:
                  'Your insider playbook — trending skills, where to learn (with links), what to follow daily, and secrets top-college students know. All tailored to YOUR resume.',
              onTap: () => _open(context, CareerPulseScreen(token: token)),
            ),
            const SizedBox(height: 14),
            _AscendCard(
              icon: Icons.route_rounded,
              title: 'My Roadmap',
              subtitle:
                  'A step-by-step path built from your resume — Foundation, Growth, Top-tier, plus insider resources.',
              onTap: () => _open(context, NexoraRoadmapScreen(token: token)),
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
              icon: Icons.military_tech_rounded,
              title: 'Mock Placement',
              subtitle:
                  'A full 3-round drive tuned to your resume — Aptitude, a Technical round with a real coding task, and a video-call interview. Ends with a report that explains every answer.',
              onTap: () => _open(context, MockPlacementScreen(token: token)),
            ),
          ],
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
          color: ascendGold.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF4B4026)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: ascendGradient,
              ),
              child: Icon(icon, color: const Color(0xFF231A07), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: ascendInk,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ascendMuted,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: ascendMuted),
          ],
        ),
      ),
    );
  }
}
