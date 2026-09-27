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
  const NexoraInterviewScreen({super.key, required this.token});

  @override
  State<NexoraInterviewScreen> createState() => _NexoraInterviewScreenState();
}

class _NexoraInterviewScreenState extends State<NexoraInterviewScreen> {
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
    _cam?.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _setup() async {
    await [Permission.camera, Permission.microphone].request();
    await _initCamera();
    await _initTts();
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
    setState(() => _submitting = true);
    await _tts.stop();

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
      final feedback = await ApiService.getInterviewFeedback(
        widget.token,
        questions: _questions,
        videoBase64: videoB64,
        videoMime: 'video/mp4',
      );
      if (!mounted) return;
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
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1530),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Live Interview',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: AppBackground(child: SafeArea(child: _content())),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7B5CF0)),
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
                onPressed: _loadQuestions,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5CF0)),
                child: const Text('Try again',
                    style: TextStyle(color: Colors.white)),
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
            CircularProgressIndicator(color: Color(0xFF7B5CF0)),
            SizedBox(height: 16),
            Text('Nexa is reviewing your interview…',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      );
    }

    final total = _questions.length;
    final isLast = _index >= _questions.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          _selfView(),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('$_role  •  Question ${_index + 1} of $total',
                style: const TextStyle(
                    color: Color(0xFFB79CFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          _questionCard(),
          const SizedBox(height: 12),
          Expanded(child: _guidanceCard()),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _speaking ? null : _next,
              icon: Icon(
                  isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20),
              label: Text(
                _speaking
                    ? 'Nexa is asking…'
                    : (isLast ? 'Finish & get feedback' : 'Next question'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B5CF0),
                disabledBackgroundColor: const Color(0xFF3B3358),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selfView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: (_camReady && _cam != null)
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_cam!),
                  if (_recording)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _pill('● REC', const Color(0xFFE07A6A)),
                    ),
                  if (_speaking)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _pill('Nexa speaking…', const Color(0xFF7B5CF0)),
                    ),
                ],
              )
            : Container(
                color: Colors.white.withValues(alpha: 0.05),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off_rounded,
                          color: Colors.white38, size: 34),
                      SizedBox(height: 8),
                      Text('Camera unavailable — you can still practice',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _questionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2244)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _speaking ? null : _askCurrent,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)]),
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_questions[_index],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _guidanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2244)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _recording ? Icons.videocam_rounded : Icons.info_outline_rounded,
            color:
                _recording ? const Color(0xFF6FDB9A) : const Color(0xFFE0B84A),
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            _recording
                ? 'Look at the camera and answer clearly, then tap Next.'
                : 'Answer out loud, then tap Next.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 14.5, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'The whole interview is being recorded — Nexa\'s questions and your answers — so you get body-language and confidence feedback.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
