import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'app_background.dart';
import 'resume_builder_screen.dart';
import 'cover_letter_screen.dart';
import 'resume_analysis_screen.dart';

class ResumeUploadScreen extends StatefulWidget {
  final String token;

  const ResumeUploadScreen({super.key, required this.token});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  PlatformFile? selectedFile;
  bool isUploading = false;

  // Concept: after a successful upload we only show the "what next" tiles.
  // Preview, skills, quality and AI feedback are no longer shown inline here;
  // each opens in its own feature screen.
  bool uploaded = false;

  // Kept only to prefill the resume builder — never shown on this screen.
  Map<String, dynamic>? _extracted;

  Future<void> pickFile() async {
    try {
      final List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (result.isEmpty || !mounted) return;

      final file = result.first;

      if (file.path == null || file.path!.isEmpty) {
        _snack('Could not access the selected file.', const Color(0xFFB3382C));
        return;
      }

      setState(() {
        selectedFile = file;
        uploaded = false;
        _extracted = null;
      });
    } catch (e) {
      if (!mounted) return;
      _snack('Could not select the file. Please try again.', const Color(0xFFB3382C));
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null ||
        selectedFile!.path == null ||
        selectedFile!.path!.isEmpty ||
        isUploading) {
      return;
    }

    setState(() => isUploading = true);

    final file = selectedFile!;

    try {
      final result = await ApiService.uploadResume(
        widget.token,
        file.path!,
        file.name,
      );

      if (!mounted) return;

      if (result != null) {
        final dynamic extractedData = result['extracted'];
        setState(() {
          isUploading = false;
          uploaded = true;
          _extracted = extractedData is Map
              ? Map<String, dynamic>.from(extractedData)
              : null;
        });
        _snack('Resume uploaded successfully!', const Color(0xFF3E9C63));
      } else {
        setState(() => isUploading = false);
        _snack('Upload failed. Try again.', const Color(0xFFB3382C));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isUploading = false);
      _snack('Upload failed. Check your connection and try again.',
          const Color(0xFFB3382C));
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void openResumeBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResumeBuilderScreen(token: widget.token, prefill: _extracted),
      ),
    );
  }

  void openResumeAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResumeAnalysisScreen(token: widget.token),
      ),
    );
  }

  void openCoverLetter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoverLetterScreen(token: widget.token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17130C),
        elevation: 0,
        title: const Text('Upload Resume', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: isUploading ? null : pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFE8BA48).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)],
                            ),
                          ),
                          child: const Icon(Icons.upload_file_rounded,
                              color: Color(0xFF1A1200), size: 30),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedFile == null
                              ? 'Tap to select your resume'
                              : selectedFile!.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('PDF or DOCX',
                            style: TextStyle(color: Colors.white38, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        (selectedFile == null || isUploading) ? null : uploadFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: selectedFile == null
                              ? [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.08),
                                ]
                              : const [Color(0xFFE8BA48), Color(0xFFC48A0A)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: isUploading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.2, color: Color(0xFF1A1200)),
                              )
                            : Text(
                                uploaded ? 'Upload a different resume' : 'Upload Resume',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selectedFile == null ? Colors.white54 : const Color(0xFF1A1200),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                // Concept: post-upload, only a confirmation + tiles that OPEN
                // the real detail inside each feature — nothing dumped inline.
                if (uploaded) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6FDB9A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF6FDB9A).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF6FDB9A), size: 22),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Resume saved. Open a tool below to see the details.',
                            style: TextStyle(color: Colors.white, fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _featureTile(
                    icon: Icons.insights_rounded,
                    title: 'Resume Analysis',
                    subtitle: 'Score, ATS check and fixes',
                    onTap: openResumeAnalysis,
                    highlight: true,
                  ),
                  const SizedBox(height: 12),
                  _featureTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Cover Letter',
                    subtitle: 'Generate one from your resume',
                    onTap: openCoverLetter,
                  ),
                  const SizedBox(height: 12),
                  _featureTile(
                    icon: Icons.edit_document,
                    title: 'Resume Builder',
                    subtitle: 'Build or improve a resume',
                    onTap: openResumeBuilder,
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: highlight
              ? LinearGradient(colors: [
                  const Color(0xFFE8BA48).withValues(alpha: 0.18),
                  const Color(0xFFC48A0A).withValues(alpha: 0.12),
                ])
              : null,
          color: highlight ? null : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? const Color(0xFFE8BA48).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8BA48).withValues(alpha: 0.18),
              ),
              child: Icon(icon, color: const Color(0xFFC48A0A), size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
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
