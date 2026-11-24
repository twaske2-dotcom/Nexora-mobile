import 'package:flutter/material.dart';

import 'app_background.dart';
import 'help_screen.dart';
import 'nexora_theme.dart';

/// Settings page opened from the gear icon on the dashboard.
/// Keeps things simple: AI help, about, and log out.
class SettingsScreen extends StatelessWidget {
  /// Called after this screen closes, to run the dashboard's log-out flow.
  final VoidCallback onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.bg,
      appBar: AppBar(
        backgroundColor: NexoraColors.bg,
        foregroundColor: Colors.white,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _SettingsTile(
                icon: Icons.auto_awesome,
                title: 'AI Career Assistant',
                subtitle: 'Ask Nexa about your resume, skills or interviews',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Nexora',
                subtitle: 'One platform. Three career paths.',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Nexora',
                  applicationVersion: '1.0.0',
                  applicationLegalese:
                      'AI career assistant for resume building, analysis, '
                      'mock interviews and job matching.',
                ),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                subtitle: 'Sign out of your account',
                onTap: () {
                  Navigator.pop(context);
                  onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NexoraColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NexoraColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: NexoraColors.goldGradient,
              ),
              child: Icon(icon, color: NexoraColors.onGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
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
