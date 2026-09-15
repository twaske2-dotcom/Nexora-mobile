import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';

class CoverLetterScreen extends StatefulWidget {
  final String token;
  const CoverLetterScreen({super.key, required this.token});

  @override
  State<CoverLetterScreen> createState() => _CoverLetterScreenState();
}

class _CoverLetterScreenState extends State<CoverLetterScreen> {
  final jobTitleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  String? letter;
  bool isGenerating = false;
  String? errorText;

  Future<void> generate() async {
    if (jobTitleCtrl.text.trim().isEmpty) {
      setState(() => errorText = 'Enter a job title first');
      return;
    }
    setState(() {
      isGenerating = true;
      errorText = null;
    });

    final result = await ApiService.generateCoverLetter(
      widget.token,
      jobTitleCtrl.text.trim(),
      companyCtrl.text.trim(),
    );

    setState(() {
      isGenerating = false;
      if (result != null) {
        letter = result;
      } else {
        errorText = "Couldn't generate a cover letter. Make sure you've uploaded a resume.";
      }
    });
  }

  void copyToClipboard() {
    if (letter == null) return;
    Clipboard.setData(ClipboardData(text: letter!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), backgroundColor: Color(0xFF3E9C63)),
    );
  }

  Future<void> shareLetter() async {
    if (letter == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cover_letter.txt');
    await file.writeAsString(letter!);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'My cover letter'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        title: const Text('Cover Letter', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D14), Color(0xFF1A1530), Color(0xFF0D0D14)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Concept: header row with copy/share icons, only meaningful once a letter exists
                Row(
                  children: [
                    const Text(
                      'Your letter',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (letter != null) ...[
                      _iconButton(Icons.copy_rounded, copyToClipboard),
                      const SizedBox(width: 8),
                      _iconButton(Icons.share_rounded, shareLetter),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                // Concept: hero preview card - the letter is the visual focus of the page
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  constraints: const BoxConstraints(minHeight: 140),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF7B5CF0).withValues(alpha: 0.14),
                        const Color(0xFFB06AB3).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF7B5CF0).withValues(alpha: 0.28)),
                  ),
                  child: isGenerating
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(color: Color(0xFF7B5CF0)),
                          ),
                        )
                      : Text(
                          letter ?? 'Your generated cover letter will appear here.',
                          style: TextStyle(
                            color: letter != null ? Colors.white.withValues(alpha: 0.85) : Colors.white38,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _field(jobTitleCtrl, 'Job title')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(companyCtrl, 'Company (optional)')),
                  ],
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Color(0xFFE07A6A), fontSize: 12.5)),
                ],
                const SizedBox(height: 14),
                // Concept: TweenAnimationBuilder gives the button a quick press-scale feel
                _AnimatedPressButton(
                  onPressed: isGenerating ? null : generate,
                  label: letter == null ? 'Generate letter' : 'Regenerate',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: const Color(0xFFB06AB3), size: 16),
        ),
      );

  Widget _field(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

// Concept: StatefulWidget that scales down briefly on tap - gives buttons a tactile "press" feel
class _AnimatedPressButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  const _AnimatedPressButton({required this.onPressed, required this.label});

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.96),
      onTapUp: (_) => setState(() => scale = 1.0),
      onTapCancel: () => setState(() => scale = 1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.onPressed == null
                  ? [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.08)]
                  : [const Color(0xFF7B5CF0), const Color(0xFFB06AB3)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
        ),
      ),
    );
  }
}