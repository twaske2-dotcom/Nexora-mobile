import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'resume_builder_screen.dart';
import 'cover_letter_screen.dart';

class ResumeUploadScreen extends StatefulWidget {
  final String token;
  const ResumeUploadScreen({super.key, required this.token});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  // Concept: nullable state - no file selected yet
  PlatformFile? selectedFile;
  bool isUploading = false;
  String? previewText;
  int? qualityScore;
  List<dynamic> qualityTips = [];
  Map<String, dynamic>? extracted;
  bool isFetchingFeedback = false;
  List<String>? aiFeedback;

  // Concept: opens the native file picker, restricted to pdf/docx
  Future<void> pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (files.isNotEmpty) {
      setState(() {
        selectedFile = files.first;
        previewText = null;
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null || selectedFile!.path == null) return;

    setState(() => isUploading = true);

    final result = await ApiService.uploadResume(
      widget.token,
      selectedFile!.path!,
      selectedFile!.name,
    );

    setState(() => isUploading = false);

    if (result != null) {
      setState(() {
        previewText = result['preview'];
        final quality = result['quality'];
        qualityScore = quality != null ? quality['score'] : null;
        qualityTips = quality != null ? (quality['tips'] ?? []) : [];
        extracted = result['extracted'] != null
            ? Map<String, dynamic>.from(result['extracted'])
            : null;
        aiFeedback = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded successfully!'),
            backgroundColor: Color(0xFF3E9C63),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Try again.'),
            backgroundColor: Color(0xFFB3382C),
          ),
        );
      }
    }
  }

  Future<void> fetchFeedback() async {
    setState(() => isFetchingFeedback = true);
    final tips = await ApiService.getResumeFeedback(widget.token);
    setState(() {
      isFetchingFeedback = false;
      aiFeedback = tips;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        title: const Text(
          'Upload Resume',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D14), Color(0xFF1A1530), Color(0xFF0D0D14)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // Concept: GestureDetector wrapping a dashed-style drop zone
                GestureDetector(
                  onTap: pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF7B5CF0).withValues(alpha: 0.4),
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
                              colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
                            ),
                          ),
                          child: const Icon(
                            Icons.upload_file_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
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
                        const Text(
                          'PDF or DOCX',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Concept: gradient upload button, disabled until a file is picked
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (selectedFile == null || isUploading)
                        ? null
                        : uploadFile,
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
                              : [
                                  const Color(0xFF7B5CF0),
                                  const Color(0xFFB06AB3),
                                ],
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
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Upload Resume',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                if (previewText != null) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Extracted preview',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          previewText!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (extracted != null && (extracted!['skills'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Detected skills',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  // Concept: Wrap - lays chips out and flows to the next line automatically
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: extracted!['skills']
                        .toString()
                        .split(RegExp(r'[,•|]'))
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty && s.length < 30)
                        .map((skill) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B5CF0).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(color: Color(0xFFB9A8F5), fontSize: 12.5),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                if (qualityScore != null) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Resume Quality',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              '$qualityScore/100',
                              style: TextStyle(
                                color: _scoreColor(qualityScore!),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Concept: ClipRRect + LinearProgressIndicator - rounded score bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: qualityScore! / 100,
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            color: _scoreColor(qualityScore!),
                          ),
                        ),
                        if (qualityTips.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ...qualityTips.map((tip) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.circle, size: 5, color: Colors.white38),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip.toString(),
                                        style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                        if (qualityScore! < 80) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ResumeBuilderScreen(
                                    token: widget.token,
                                    prefill: extracted,
                                  ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF7B5CF0).withValues(alpha: 0.15),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Build a professional resume instead',
                                style: TextStyle(color: Color(0xFFB06AB3), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (previewText != null) ...[
                  const SizedBox(height: 20),
                  // Concept: gradient card with a subtle glow - visually distinct "premium" feature
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF7B5CF0).withValues(alpha: 0.18),
                          const Color(0xFFB06AB3).withValues(alpha: 0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF7B5CF0).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFFB06AB3), size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Resume Feedback',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Get specific, AI-written suggestions to improve your resume',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 14),
                        if (aiFeedback == null)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: isFetchingFeedback ? null : fetchFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: isFetchingFeedback
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          '✨ Get AI Feedback',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5),
                                        ),
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: aiFeedback!
                                .map((tip) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('✨ ', style: TextStyle(fontSize: 13)),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
                if (previewText != null) ...[
                  const SizedBox(height: 16),
                  // Concept: quick-access card linking to the Cover Letter generator
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CoverLetterScreen(token: widget.token),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7B5CF0).withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.mail_outline_rounded, color: Color(0xFFB06AB3), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Generate a Cover Letter',
                              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white38),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Concept: color-coding the score - red/yellow/green like a traffic light
  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF6FDB9A);
    if (score >= 50) return const Color(0xFFE0B84A);
    return const Color(0xFFE07A6A);
  }
}