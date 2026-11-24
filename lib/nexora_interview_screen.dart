import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'api_service.dart';
import 'app_background.dart';
import 'nexora_interview_feedback_screen.dart';

/// Live mock interview with Nexa, like a real call:
/// Nexa speaks -> you answer out loud -> your speech is turned into text ->
/// Nexa reacts to what you actually said and asks the next question.
/// The whole call is recorded (video + audio) for body-language and
/// confidence feedback at the end.
/// Everything degrades gracefully: if the mic cannot be recognised you can
/// type the answer, so the call never dead-ends.
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
  static const int _maxTurns = 6;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);
  final DateTime _callStart = DateTime.now();

  CameraController? _cam;
  bool _camReady = false;
  bool _recording = false;
  XFile? _recFile;

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _sttReady = false;

  bool _loading = true;
  String? _error;
  bool _submitting = false;

  bool _speaking = false; // Nexa is talking
  bool _listening = false; // mic is open for the candidate
  bool _thinking = false; // waiting for Nexa's next line
  bool _processing = false; // guards against double-handling one answer
  bool _ended = false;
  String _heard = ''; // live words the candidate is saying
  String _hint = '';

  int _turn = 1;
  String _nexaLine = '';
  final List<Map<String, String>> _history = []; // {role: nexa|user, text}

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void dispose() {
    _ended = true;
    _pulse.dispose();
    _cam?.dispose();
    _tts.stop();
    _stt.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- setup

  Future<void> _setup() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await [Permission.camera, Permission.microphone].request();
    if (!mounted) return;
    await _initCamera();
    if (!mounted) return;
    await _initTts();
    await _initStt();
    if (!mounted) return;
    if (widget.returnFeedback && !_camReady) {
      setState(() {
        _loading = false;
        _error = 'Camera and microphone access are required for this round.';
      });
      return;
    }
    await _beginCall();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller =
          CameraController(front, ResolutionPreset.low, enableAudio: false);
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

  Future<void> _initStt() async {
    try {
      _sttReady = await _stt.initialize(
        onStatus: _onSttStatus,
        onError: (_) {
          if (!mounted || _processing) return;
          setState(() {
            _listening = false;
            _hint = 'I could not hear you. Tap the mic, or type your answer.';
          });
        },
      );
    } catch (_) {
      _sttReady = false;
    }
  }

  Future<void> _beginCall() async {
    _history.clear();
    _turn = 1;
    await _startRecording();
    if (!mounted) return;
    if (widget.returnFeedback && !_recording) {
      setState(() {
        _loading = false;
        _error = 'The camera could not start recording. Please try again.';
      });
      return;
    }
    setState(() => _loading = false);
    await _nexaTurn();
  }

  Future<void> _startRecording() async {
    try {
      if (_camReady && _cam != null && !_cam!.value.isRecordingVideo) {
        await _cam!.startVideoRecording();
        if (mounted) setState(() => _recording = true);
      }
    } catch (_) {
      _recording = false;
    }
  }

  // ------------------------------------------------------- conversation loop

  // Nexa's turn: get her next line from the server, speak it, then listen.
  Future<void> _nexaTurn() async {
    if (_ended || !mounted) return;
    setState(() {
      _thinking = true;
      _hint = '';
      _heard = '';
    });

    String line;
    bool closing = _turn >= _maxTurns;
    try {
      final data = await ApiService.interviewReply(
        widget.token,
        history: _history,
        turn: _turn,
        maxTurns: _maxTurns,
      );
      line = (data['reply'] ?? '').toString().trim();
      closing = data['closing'] == true || closing;
      if (line.isEmpty) throw ApiException('empty');
    } catch (_) {
      line = _history.isEmpty
          ? "Hi, I'm Nexa. Let's begin. Tell me a little about yourself."
          : (closing
              ? 'Thank you, that is all from my side. Let me prepare your feedback.'
              : 'Thanks for sharing that. Can you tell me about a project you are proud of?');
    }
    if (_ended || !mounted) return;

    _history.add({'role': 'nexa', 'text': line});
    setState(() {
      _nexaLine = line;
      _thinking = false;
      _speaking = true;
    });
    try {
      await _tts.speak(line).timeout(const Duration(seconds: 45));
    } catch (_) {}
    if (_ended || !mounted) return;
    setState(() => _speaking = false);

    if (closing) {
      await _finish();
    } else {
      await _listen();
    }
  }

  Future<void> _listen() async {
    if (_ended || !mounted) return;
    _processing = false;
    if (!_sttReady) {
      setState(() => _hint =
          'Voice recognition is not available. Please type your answer.');
      return;
    }
    setState(() {
      _heard = '';
      _hint = '';
      _listening = true;
    });
    try {
      await _stt.listen(
        onResult: (r) {
          if (!mounted) return;
          setState(() => _heard = r.recognizedWords);
          if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
            _onAnswer(r.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 90),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _listening = false;
          _hint = 'Mic problem. Tap the mic again, or type your answer.';
        });
      }
    }
  }

  void _onSttStatus(String status) {
    if (!mounted || _processing || _ended) return;
    if (status == 'done' || status == 'notListening') {
      if (_listening) {
        setState(() => _listening = false);
        if (_heard.trim().isNotEmpty) {
          _onAnswer(_heard);
        } else {
          setState(() => _hint = "I didn't catch that. Tap the mic and try again.");
        }
      }
    }
  }

  // The candidate finished an answer -> record it and let Nexa respond.
  Future<void> _onAnswer(String text) async {
    final answer = text.trim();
    if (answer.isEmpty || _processing || _ended) return;
    _processing = true;
    try {
      await _stt.stop();
    } catch (_) {}
    if (!mounted) return;
    _history.add({'role': 'user', 'text': answer});
    setState(() {
      _listening = false;
      _heard = answer;
      _turn++;
    });
    await _nexaTurn();
  }

  // Tap the mic: start listening, or stop and send what was heard.
  Future<void> _toggleMic() async {
    if (_speaking || _thinking || _submitting) return;
    if (_listening) {
      try {
        await _stt.stop();
      } catch (_) {}
      if (_heard.trim().isNotEmpty) {
        await _onAnswer(_heard);
      } else if (mounted) {
        setState(() => _listening = false);
      }
    } else {
      await _listen();
    }
  }

  Future<void> _typeAnswer() async {
    if (_speaking || _thinking || _submitting) return;
    try {
      await _stt.stop();
    } catch (_) {}
    if (!mounted) return;
    setState(() => _listening = false);
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14100A),
        title: const Text('Type your answer',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Your answer…',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      _processing = false;
      await _onAnswer(text);
    }
  }

  // ----------------------------------------------------------------- finish

  Future<void> _finish() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
      _listening = false;
    });
    try {
      await _tts.stop();
      await _stt.stop();
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

    // Real Q&A pairs from the live conversation, so feedback can quote them.
    final questions = <String>[];
    final transcript = <Map<String, String>>[];
    for (int i = 0; i < _history.length; i++) {
      final m = _history[i];
      if (m['role'] == 'nexa') {
        questions.add(m['text'] ?? '');
        final next = i + 1 < _history.length ? _history[i + 1] : null;
        if (next != null && next['role'] == 'user') {
          transcript.add({
            'question': m['text'] ?? '',
            'answer': next['text'] ?? '',
          });
        }
      }
    }

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
        transcript: transcript,
        questions: questions,
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

  // --------------------------------------------------------------------- UI

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
                    : (!_camReady ? _setup : _beginCall),
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

  String _statusText() {
    if (_speaking) return 'Speaking';
    if (_thinking) return 'Thinking…';
    if (_listening) return 'Listening to you…';
    return 'Your turn';
  }

  Color _statusColor() {
    if (_speaking || _thinking) return const Color(0xFFF4D67A);
    return const Color(0xFF6FDB9A);
  }

  Widget _callView() {
    final canAnswer = !_speaking && !_thinking && !_submitting;

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

        // Nexa
        Positioned.fill(
          child: Align(
            alignment: const Alignment(0, -0.55),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _mentorAvatar(),
                const SizedBox(height: 12),
                const Text('Nexa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text('HR Interviewer',
                    style: TextStyle(color: Colors.white54, fontSize: 12.5)),
                const SizedBox(height: 8),
                StreamBuilder<int>(
                  stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                  builder: (context, _) => Text(
                    '${_statusText()}  •  ${_elapsed()}',
                    style: TextStyle(
                      color: _statusColor(),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Your camera
        Positioned(top: 8, right: 4, child: _selfWindow()),

        // Captions + controls
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
                    const Text('NEXA',
                        style: TextStyle(
                            color: Color(0xFFF4D67A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    Text(
                      _thinking ? '…' : _nexaLine,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600),
                    ),
                    if (_heard.isNotEmpty || _hint.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(_heard.isNotEmpty ? 'YOU' : 'TIP',
                          style: const TextStyle(
                              color: Color(0xFF6FDB9A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6)),
                      const SizedBox(height: 4),
                      Text(
                        _heard.isNotEmpty ? _heard : _hint,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white
                                .withValues(alpha: _heard.isNotEmpty ? 0.9 : 0.6),
                            fontSize: 13.5,
                            height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _roundButton(
                    icon: Icons.keyboard_alt_outlined,
                    color: Colors.white.withValues(alpha: 0.12),
                    iconColor: Colors.white,
                    onTap: canAnswer ? _typeAnswer : null,
                  ),
                  const SizedBox(width: 22),
                  GestureDetector(
                    onTap: canAnswer ? _toggleMic : null,
                    child: Opacity(
                      opacity: canAnswer ? 1 : 0.45,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _listening
                              ? const LinearGradient(
                                  colors: [Color(0xFF6FDB9A), Color(0xFF3E9C63)])
                              : const LinearGradient(
                                  colors: [Color(0xFFF4D67A), Color(0xFFC48A0A)]),
                          boxShadow: [
                            BoxShadow(
                              color: (_listening
                                      ? const Color(0xFF6FDB9A)
                                      : const Color(0xFFE8BA48))
                                  .withValues(alpha: 0.4),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Icon(
                          _listening ? Icons.stop_rounded : Icons.mic_rounded,
                          color: const Color(0xFF1A1200),
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  _roundButton(
                    icon: Icons.call_end_rounded,
                    color: const Color(0xFFE05545),
                    iconColor: Colors.white,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _listening
                    ? 'Speak naturally. Tap stop when you are done.'
                    : (canAnswer
                        ? 'Tap the mic to answer'
                        : 'Nexa is talking…'),
                style: const TextStyle(color: Colors.white38, fontSize: 11.5),
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
    final active = _speaking;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = active ? _pulse.value : 0.0;
        return SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (active) ...[
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
