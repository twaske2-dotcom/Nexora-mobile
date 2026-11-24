import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';
import 'app_background.dart';

// Concept: small data class - holds controllers for one experience entry
class _ExperienceEntry {
  final titleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final descCtrl = TextEditingController();
}

class _EducationEntry {
  final degreeCtrl = TextEditingController();
  final institutionCtrl = TextEditingController();
  final yearCtrl = TextEditingController();
}

class ResumeBuilderScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? prefill;
  const ResumeBuilderScreen({super.key, required this.token, this.prefill});

  @override
  State<ResumeBuilderScreen> createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final summaryCtrl = TextEditingController();
  final skillsCtrl = TextEditingController();

  // Concept: growable lists of form entries - user can add as many as needed
  final List<_ExperienceEntry> experiences = [_ExperienceEntry()];
  final List<_EducationEntry> educations = [_EducationEntry()];

  bool isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Concept: pre-filling text fields from data passed by the previous screen
    final p = widget.prefill;
    if (p != null) {
      nameCtrl.text = (p['name'] ?? '').toString();
      emailCtrl.text = (p['email'] ?? '').toString();
      phoneCtrl.text = (p['phone'] ?? '').toString();
      skillsCtrl.text = (p['skills'] ?? '').toString();
    }
  }

  Future<void> generateAndShare() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    setState(() => isGenerating = true);

    // Concept: building the JSON payload the backend expects
    final data = {
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'summary': summaryCtrl.text.trim(),
      'skills': skillsCtrl.text.trim(),
      'experience': experiences
          .where((e) => e.titleCtrl.text.trim().isNotEmpty)
          .map(
            (e) => {
              'title': e.titleCtrl.text.trim(),
              'company': e.companyCtrl.text.trim(),
              'duration': e.durationCtrl.text.trim(),
              'description': e.descCtrl.text.trim(),
            },
          )
          .toList(),
      'education': educations
          .where((e) => e.degreeCtrl.text.trim().isNotEmpty)
          .map(
            (e) => {
              'degree': e.degreeCtrl.text.trim(),
              'institution': e.institutionCtrl.text.trim(),
              'year': e.yearCtrl.text.trim(),
            },
          )
          .toList(),
    };

    final bytes = await ApiService.generateResume(widget.token, data);

    setState(() => isGenerating = false);

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate resume. Try again.'),
            backgroundColor: Color(0xFFB3382C),
          ),
        );
      }
      return;
    }

    // Concept: writing bytes to a temp file, then handing it to the OS share sheet
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/resume.pdf');
    await file.writeAsBytes(bytes);

    if (mounted) {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'My resume'),
      );
    }
  }

  void addExperience() => setState(() => experiences.add(_ExperienceEntry()));
  void addEducation() => setState(() => educations.add(_EducationEntry()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17130C),
        elevation: 0,
        title: const Text(
          'Build Resume',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _sectionLabel('Basic Info'),
              _field(nameCtrl, 'Full name'),
              _field(emailCtrl, 'Email'),
              _field(phoneCtrl, 'Phone'),
              _field(summaryCtrl, 'Short summary (2-3 lines)', maxLines: 3),

              const SizedBox(height: 20),
              _sectionLabel('Experience'),
              ...experiences.map((e) => _experienceCard(e)),
              _addButton('Add another experience', addExperience),

              const SizedBox(height: 20),
              _sectionLabel('Education'),
              ...educations.map((e) => _educationCard(e)),
              _addButton('Add another education', addEducation),

              const SizedBox(height: 20),
              _sectionLabel('Skills'),
              _field(skillsCtrl, 'e.g. Java, Spring Boot, SQL', maxLines: 2),

              const SizedBox(height: 30),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isGenerating ? null : generateAndShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: isGenerating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF1A1200),
                              ),
                            )
                          : const Text(
                              'Generate & Download PDF',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1200),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // Concept: reusable styled text field
  Widget _field(TextEditingController ctrl, String hint, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      );

  Widget _experienceCard(_ExperienceEntry e) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(
      children: [
        _field(e.titleCtrl, 'Job title'),
        _field(e.companyCtrl, 'Company'),
        _field(e.durationCtrl, 'Duration (e.g. Jan 2023 - Present)'),
        _field(
          e.descCtrl,
          'What did you do? (one point per line)',
          maxLines: 3,
        ),
      ],
    ),
  );

  Widget _educationCard(_EducationEntry e) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Column(
      children: [
        _field(e.degreeCtrl, 'Degree (e.g. B.Tech Computer Science)'),
        _field(e.institutionCtrl, 'Institution'),
        _field(e.yearCtrl, 'Year (e.g. 2024)'),
      ],
    ),
  );

  Widget _addButton(String label, VoidCallback onTap) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.add, color: Color(0xFFC48A0A), size: 18),
    label: Text(label, style: const TextStyle(color: Color(0xFFC48A0A))),
  );
}
