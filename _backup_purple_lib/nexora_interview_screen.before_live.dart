import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'api_service.dart';
import 'app_background.dart';
import 'nexora_interview_feedback_screen.dart';

/// Live mock interview with Nexa.
/// - Student's camera is ON (front self-view) and the WHOLE call is recorded
///   as a video with audio. Nexa speaks each question on the loudspeaker, so
///   the recording captures BOTH voices plus the student's face/body.
/// - On finish, the recording goes to Nexa, who watches it to score body
///   language, listens for confidence, and reviews each answer.
/// Everything degrades gracefully so the screen never dead-ends.
class NexoraInterviewScreen extends StatefulWidget {
  final String token;
  final bool returnFeedback;
  const NexoraInterviewScreen({
    super.key,
    required this.token,
    this.returnFeedback = false,
  });

  @override
  State<NexoraInterviewScreen> createState() => _NexoraInterviewScreenState();
}

class _NexoraInterviewScreenState extends State<NexoraInterviewScreen>
    with SingleTickerProviderStateMixin {
  // Drives the pulsing rings around Nexa while she is speaking.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  final DateTime _callStart = DateTime.now();

  CameraController? _cam;
  bool _camReady = false;

  final FlutterTts _tts = FlutterTts();
  bool _speaking = false;
  bool _recording = false;
  XFile? _recFile;

  bool _loading = true;
  String? _error;
  bool _submitting = false;

  String _role = 'Candidate';
  List<String> _questions = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _cam?.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _setup() async {
    await [Permission.camera, Permission.microphone].request();
    if (!mounted) return;
    await _initCamera();
    if (!mounted) return;
    await _initTts();
    if (!mounted) return;
    if (widget.returnFeedback && !_camReady) {
      setState(() {
        _loading = false;
        _error = 'Camera and microphone access are required for this round.';
      });
      return;
    }
    await _loadQuestions();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      // low res + audio on → small file, both voices captured.
      final controller =
          CameraController(front, ResolutionPreset.low, enableAudio: true);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _cam = controller;
        _camReady = true;
      });
    } catch (_) {
      _camReady = false;
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
      _index = 0;
    });
    try {
      final data = await ApiService.getInterviewQuestions(widget.token);
      final qs = (data['questions'] is List)
          ? (data['questions'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : <String>[];
      if (!mounted) return;
      setState(() {
        _role = (data['role'] ?? 'Candidate').toString();
        _questions = qs;
        _loading = false;
        if (qs.isEmpty) {
          _error = 'Nexa couldn\'t prepare questions right now. Please try again.';
        }
      });
      if (qs.isNotEmpty) {
        await _startRecording();
        if (!mounted) return;
        if (widget.returnFeedback && !_recording) {
          setState(() => _error =
              'The camera could not start recording. Please try again.');
          return;
        }
        await _askCurrent();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (_camReady && _cam != null && !_cam!.value.isRecordingVideo) {
        await _cam!.startVideoRecording();
        if (mounted) setState(() => _recording = true);
      }
    } catch (_) {
      _recording = false; // recording failed — interview still runs
    }
  }

  Future<void> _askCurrent() async {
    if (_index >= _questions.length) return;
    setState(() => _speaking = true);
    try {
      await _tts.speak(_questions[_index]);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _speaking = false);
  }

  Future<void> _next() async {
    if (_submitting || _speaking) return;
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      await _askCurrent();
      return;
    }
    await _finish();
  }

  Future<void> _finish() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _tts.stop();
    } catch (_) {}
    if (!mounted) return;

    String? videoB64;
    try {
      if (_recording && _cam != null && _cam!.value.isRecordingVideo) {
        _recFile = await _cam!.stopVideoRecording();
        _recording = false;
      }
      if (_recFile != null && File(_recFile!.path).existsSync()) {
        final bytes = await File(_recFile!.path).readAsBytes();
        if (bytes.isNotEmpty) videoB64 = base64Encode(bytes);
      }
    } catch (_) {}

    try {
      if (!mounted) return;
      if (widget.returnFeedback && videoB64 == null) {
        _recFile = null;
        throw ApiException(
          'No recording was captured. Please retry the video round.',
        );
      }
      final feedback = await ApiService.getInterviewFeedback(
        widget.token,
        questions: _questions,
        videoBase64: videoB64,
        videoMime: 'video/mp4',
      );
      if (!mounted) return;
      if (widget.returnFeedback) {
        Navigator.pop(context, (
          feedback: feedback,
          recordingPath: _recFile?.path,
        ));
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NexoraInterviewFeedbackScreen(
            feedback: feedback,
            recordingPath: _recFile?.path,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17130C),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Live Interview Call',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: AppBackground(child: SafeArea(child: _content())),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE8BA48)),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE07A6A), size: 40),
              const SizedBox(height: 14),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _recFile != null
                    ? _finish
                    : widget.returnFeedback && !_camReady
                    ? _setup
                    : _loadQuestions,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8BA48)),
                child: const Text('Try again',
                    style: TextStyle(color: Color(0xFF1A1200))),
              ),
            ],
          ),
        ),
      );
    }
    if (_submitting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFE8BA48)),
            SizedBox(height: 16),
            Text('Nexa is reviewing your interview…',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    }

    return _callView();
  }

  String _elapsed() {
    final d = DateTime.now().difference(_callStart);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  // A real video-call layout: Nexa (the mentor) fills the screen, the
  // student's own camera sits in a small window, and the current question
  // appears as a live caption while Nexa speaks it out loud.
  Widget _callView() {
    final total = _questions.length;
    final isLast = _index >= total - 1;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B1608), Color(0xFF0A0804)],
              ),
            ),
          ),
        ),

        // Mentor
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mentorAvatar(),
                const SizedBox(height: 16),
                const Text('Nexa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('HR Interviewer  •  $_role',
                    style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                const SizedBox(height: 8),
                StreamBuilder<int>(
                  stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                  builder: (context, _) => Text(
                    '${_speaking ? 'Speaking' : 'Listening'}  •  ${_elapsed()}',
                    style: TextStyle(
                      color: _speaking
                          ? const Color(0xFFF4D67A)
                          : const Color(0xFF6FDB9A),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Your own camera (small window, like a real call)
        Positioned(top: 8, right: 4, child: _selfWindow()),

        // Caption + controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3A2F17)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question ${_index + 1} of $total',
                        style: const TextStyle(
                            color: Color(0xFFF4D67A),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4)),
                    const SizedBox(height: 6),
                    Text(_questions[_index],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roundButton(
                    icon: Icons.replay_rounded,
                    color: Colors.white.withValues(alpha: 0.12),
                    iconColor: Colors.white,
                    onTap: _speaking ? null : _askCurrent,
                  ),
                  const SizedBox(width: 18),
                  GestureDetector(
                    onTap: _speaking ? null : _next,
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      decoration: BoxDecoration(
                        gradient: _speaking
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFFF4D67A), Color(0xFFC48A0A)]),
                        color: _speaking ? const Color(0xFF3A2F17) : null,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          _speaking
                              ? 'Nexa is asking…'
                              : (isLast ? 'Finish' : 'Next question'),
                          style: const TextStyle(
                              color: Color(0xFF1A1200),
                              fontSize: 15,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _roundButton(
                    icon: Icons.call_end_rounded,
                    color: const Color(0xFFE05545),
                    iconColor: Colors.white,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }

  Widget _mentorAvatar() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _speaking ? _pulse.value : 0.0;
        return SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_speaking) ...[
                Container(
                  width: 190 + 60 * t,
                  height: 190 + 60 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8BA48)
                          .withValues(alpha: 0.55 * (1 - t)),
                      width: 3,
                    ),
                  ),
                ),
                Container(
                  width: 190 + 30 * t,
                  height: 190 + 30 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8BA48)
                          .withValues(alpha: 0.35 + 0.3 * t),
                      width: 2,
                    ),
                  ),
                ),
              ],
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8BA48), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8BA48).withValues(alpha: 0.35),
              blurRadius: 28,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/hr_avatar.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded,
                color: Color(0xFFE8BA48), size: 90),
          ),
        ),
      ),
    );
  }

  Widget _selfWindow() {
    const w = 104.0;
    const h = 148.0;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8BA48), width: 1.5),
        color: const Color(0xFF17130C),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.5),
        child: (_camReady && _cam != null && _cam!.value.previewSize != null)
            ? Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cam!.value.previewSize!.height,
                      height: _cam!.value.previewSize!.width,
                      child: CameraPreview(_cam!),
                    ),
                  ),
                  if (_recording)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _pill('● REC', const Color(0xFFE07A6A)),
                    ),
                ],
              )
            : const Center(
                child: Icon(Icons.videocam_off_rounded,
                    color: Colors.white38, size: 26),
              ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}
