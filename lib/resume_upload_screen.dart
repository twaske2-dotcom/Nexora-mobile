import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
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
  String? previewText;

  int? qualityScore;
  List<dynamic> qualityTips = [];

  Map<String, dynamic>? extracted;

  bool isFetchingFeedback = false;
  List<String>? aiFeedback;
  String? aiFeedbackError;

  Future<void> pickFile() async {
    try {
      final List<PlatformFile> result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
      );

      if (result.isEmpty || !mounted) {
        return;
      }

      final file = result.first;

      if (file.path == null || file.path!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access the selected file.'),
            backgroundColor: Color(0xFFB3382C),
          ),
        );
        return;
      }

      setState(() {
        selectedFile = file;
        previewText = null;
        qualityScore = null;
        qualityTips = [];
        extracted = null;
        aiFeedback = null;
        aiFeedbackError = null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not select the file. Please try again.'),
          backgroundColor: Color(0xFFB3382C),
        ),
      );
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null ||
        selectedFile!.path == null ||
        selectedFile!.path!.isEmpty ||
        isUploading) {
      return;
    }

    setState(() {
      isUploading = true;
      aiFeedback = null;
      aiFeedbackError = null;
    });

    final file = selectedFile!;

    try {
      final result = await ApiService.uploadResume(
        widget.token,
        file.path!,
        file.name,
      );

      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      if (result != null) {
        final dynamic quality = result['quality'];
        final dynamic extractedData = result['extracted'];

        int? score;

        if (quality is Map && quality['score'] != null) {
          final dynamic rawScore = quality['score'];

          if (rawScore is int) {
            score = rawScore;
          } else {
            score = int.tryParse(rawScore.toString());
          }
        }

        List<dynamic> tips = [];

        if (quality is Map && quality['tips'] is List) {
          tips = List<dynamic>.from(quality['tips']);
        }

        Map<String, dynamic>? extractedMap;

        if (extractedData is Map) {
          extractedMap = Map<String, dynamic>.from(extractedData);
        }

        setState(() {
          previewText = result['preview']?.toString();
          qualityScore = score;
          qualityTips = tips;
          extracted = extractedMap;
          aiFeedback = null;
          aiFeedbackError = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resume uploaded successfully!'),
            backgroundColor: Color(0xFF3E9C63),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Try again.'),
            backgroundColor: Color(0xFFB3382C),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Check your connection and try again.'),
          backgroundColor: Color(0xFFB3382C),
        ),
      );
    }
  }

  Future<void> fetchFeedback() async {
    if (isFetchingFeedback) {
      return;
    }

    setState(() {
      isFetchingFeedback = true;
      aiFeedbackError = null;
    });

    try {
      final tips = await ApiService.getResumeFeedback(widget.token);

      if (!mounted) return;

      if (tips.isEmpty) {
        setState(() {
          isFetchingFeedback = false;
          aiFeedback = null;
          aiFeedbackError = 'AI feedback could not be generated right now.';
        });
        return;
      }

      setState(() {
        isFetchingFeedback = false;
        aiFeedback = tips;
        aiFeedbackError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isFetchingFeedback = false;
        aiFeedback = null;
        aiFeedbackError = 'Could not get AI feedback. Please try again.';
      });
    }
  }

  void openResumeBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ResumeBuilderScreen(token: widget.token, prefill: extracted),
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

                GestureDetector(
                  onTap: isUploading ? null : pickFile,
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
                              : const [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
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

                if (extracted != null &&
                    (extracted!['skills'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Detected skills',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: extracted!['skills']
                        .toString()
                        .split(RegExp(r'[,•|]'))
                        .map((s) => s.trim())
                        .where((s) => s.isNotEmpty && s.length < 30)
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF7B5CF0,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                color: Color(0xFFB9A8F5),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        )
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
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Resume Quality',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (qualityScore! / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            color: _scoreColor(qualityScore!),
                          ),
                        ),

                        if (qualityTips.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ...qualityTips.map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: Colors.white38,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tip.toString(),
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        if (qualityScore! < 80) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: openResumeBuilder,
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF7B5CF0,
                                ).withValues(alpha: 0.15),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Build a professional resume instead',
                                style: TextStyle(
                                  color: Color(0xFFB06AB3),
                                  fontWeight: FontWeight.w600,
                                ),
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
                      border: Border.all(
                        color: const Color(0xFF7B5CF0).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFB06AB3),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Resume Feedback',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Get specific, AI-written suggestions to improve your resume',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 14),

                        if (isFetchingFeedback)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Generating feedback...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (aiFeedbackError != null)
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFB3382C,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFB3382C,
                                    ).withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  aiFeedbackError!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: fetchFeedback,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7B5CF0),
                                          Color(0xFFB06AB3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Retry AI Feedback',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (aiFeedback == null)
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: fetchFeedback,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7B5CF0),
                                      Color(0xFFB06AB3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '✨ Get AI Feedback',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...aiFeedback!
                                  .map(
                                    (tip) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '✨ ',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: OutlinedButton(
                                  onPressed: fetchFeedback,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFB06AB3,
                                      ).withValues(alpha: 0.45),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Regenerate Feedback',
                                    style: TextStyle(
                                      color: Color(0xFFB9A8F5),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],

                // -------------------------------------------------
                // FULL RESUME ANALYSIS
                // -------------------------------------------------
                if (previewText != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: openResumeAnalysis,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7B5CF0).withValues(alpha: 0.18),
                            const Color(0xFFB06AB3).withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF7B5CF0).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFF7B5CF0,
                              ).withValues(alpha: 0.2),
                            ),
                            child: const Icon(
                              Icons.insights_rounded,
                              color: Color(0xFFB06AB3),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'View Full Analysis',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // -------------------------------------------------
                // COVER LETTER
                // -------------------------------------------------
                if (previewText != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: openCoverLetter,
                    child: Container(
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
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xFF7B5CF0,
                              ).withValues(alpha: 0.15),
                            ),
                            child: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFFB06AB3),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Generate a Cover Letter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
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

  Color _scoreColor(int score) {
    if (score >= 80) {
      return const Color(0xFF6FDB9A);
    }

    if (score >= 50) {
      return const Color(0xFFE0B84A);
    }

    return const Color(0xFFE07A6A);
  }
}
