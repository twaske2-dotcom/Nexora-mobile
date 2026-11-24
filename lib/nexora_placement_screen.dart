import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'nexora_interview_feedback_screen.dart';
import 'nexora_interview_screen.dart';

const ascendInk = Color(0xFFF6F0E4);
const ascendMuted = Color(0xFFB5AA93);
const ascendGold = Color(0xFFF4D476);
const ascendGradient = LinearGradient(colors: [ascendGold, Color(0xFFCC970E)]);

class AscendPage extends StatelessWidget {
  final String title;
  final Widget child;
  const AscendPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: ascendGold),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF100F0C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF151411),
          foregroundColor: ascendInk,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.25, 0.25),
              radius: 0.85,
              colors: [Color(0xFF302613), Color(0xFF100F0C)],
            ),
          ),
          child: SafeArea(child: SizedBox.expand(child: child)),
        ),
      ),
    );
  }
}

Map<String, dynamic> _object(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<Map<String, dynamic>> _objects(Object? value) =>
    value is List ? value.whereType<Map<String, dynamic>>().toList() : [];

List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList() : [];

String _text(Object? value) => value is String ? value.trim() : '';

class CareerPulseScreen extends StatefulWidget {
  final String token;
  const CareerPulseScreen({super.key, required this.token});

  @override
  State<CareerPulseScreen> createState() => _CareerPulseScreenState();
}

class _CareerPulseScreenState extends State<CareerPulseScreen> {
  late Future<Map<String, dynamic>> _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = ApiService.mentorPlacementRequest(widget.token, 'blueprint');
  }

  void _reload({bool refresh = false}) {
    setState(() {
      _pulse = ApiService.mentorPlacementRequest(
        widget.token,
        refresh ? 'blueprint?refresh=true' : 'blueprint',
      );
    });
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this resource.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AscendPage(
      title: 'Career Pulse',
      child: FutureBuilder<Map<String, dynamic>>(
        future: _pulse,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: ascendGold),
                  SizedBox(height: 14),
                  Text('Preparing your career pulse\u2026',
                      style: TextStyle(color: ascendMuted, fontSize: 13)),
                ],
              ),
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return _Retry(message: snapshot.error.toString(), retry: _reload);
          }
          final forYou = _object(data['forYou']);
          final trends = _object(data['trends']);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              _pulseHeader(data),
              _chipGroup('Your strengths', Icons.thumb_up_alt_outlined,
                  _strings(forYou['strengths']), const Color(0xFF4CC38A)),
              _chipGroup('Skills to improve', Icons.trending_up_rounded,
                  _strings(forYou['gaps']), const Color(0xFFE8A23A)),
              _stepsGroup('Next steps', _strings(forYou['moves'])),
              _chipGroup('Trending skills', Icons.local_fire_department_outlined,
                  _strings(trends['hotSkills']), ascendGold),
              _chipGroup('Trending roles', Icons.work_outline_rounded,
                  _strings(trends['hotRoles']), ascendGold),
              _bulletGroup('What\u2019s happening', [
                ..._strings(trends['whatsHappening']),
                if (_text(trends['note']).isNotEmpty) _text(trends['note']),
              ]),
              _resources(
                'Where to learn',
                _objects(data['learn']),
                learning: true,
              ),
              _resources('What to follow', _objects(data['stayUpdated'])),
              _detailGroup('Placement essentials', [
                for (final item in _objects(data['essentials']))
                  (_text(item['title']), _text(item['detail'])),
              ]),
              _detailGroup('Insider tips', [
                for (final item in _objects(data['secrets']))
                  (_text(item['secret']), _text(item['why'])),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _pulseHeader(Map<String, dynamic> data) {
    final level = _text(data['level']);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4B4026)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2110), Color(0xFF17130C)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: ascendGold, size: 18),
              const SizedBox(width: 8),
              const Text('YOUR CAREER PULSE',
                  style: TextStyle(
                      color: ascendGold,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Refresh',
                onPressed: () => _reload(refresh: true),
                icon: const Icon(Icons.refresh_rounded,
                    color: ascendMuted, size: 20),
              ),
            ],
          ),
          Text(_text(data['role']),
              style: const TextStyle(
                  color: ascendInk, fontSize: 24, fontWeight: FontWeight.w800)),
          if (level.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x26E8BA48),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(level,
                  style: const TextStyle(
                      color: ascendGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
          const SizedBox(height: 10),
          Text(_text(data['intro']),
              style: const TextStyle(
                  color: ascendMuted, fontSize: 13.5, height: 1.45)),
        ],
      ),
    );
  }

  Widget _chipGroup(
      String label, IconData icon, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Group(
      title: label.toUpperCase(),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Text(item,
                    style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _stepsGroup(String label, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Group(
      title: label.toUpperCase(),
      children: [
        for (final (i, item) in items.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, gradient: ascendGradient),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Color(0xFF1A1200),
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(item,
                      style: const TextStyle(
                          color: ascendInk, fontSize: 14, height: 1.4)),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _bulletGroup(String label, List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Group(
      title: label.toUpperCase(),
      children: [
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7, right: 10),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: ascendGold, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(item,
                    style: const TextStyle(
                        color: ascendInk, fontSize: 14, height: 1.4)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _detailGroup(String label, List<(String, String)> items) {
    final shown = items.where((e) => e.$1.isNotEmpty).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return _Group(
      title: label.toUpperCase(),
      children: [
        for (final (i, e) in shown.indexed) ...[
          if (i > 0) const Divider(height: 8, color: Color(0xFF3A2F17)),
          Text(e.$1,
              style: const TextStyle(
                  color: ascendInk, fontSize: 14, fontWeight: FontWeight.w700)),
          if (e.$2.isNotEmpty)
            Text(e.$2,
                style: const TextStyle(
                    color: ascendMuted, fontSize: 13, height: 1.4)),
        ],
      ],
    );
  }

  Widget _resources(
    String label,
    List<Map<String, dynamic>> items, {
    bool learning = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Group(
      title: label.toUpperCase(),
      children: [
        for (final item in items)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openLink(_text(item['url'])),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF100D07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3A2F17)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x22E8BA48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      learning
                          ? Icons.school_outlined
                          : Icons.bookmark_border_rounded,
                      color: ascendGold,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_text(item[learning ? 'resource' : 'name']),
                            style: const TextStyle(
                                color: ascendInk,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          learning
                              ? '${_text(item['skill'])} \u00b7 ${_text(item['platform'])}${item['free'] == true ? ' \u00b7 Free' : ''}'
                              : _text(item['what']),
                          style: const TextStyle(
                              color: ascendMuted, fontSize: 12, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      size: 16, color: ascendMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Question {
  final String prompt;
  final List<String> options;
  final int correct;
  final String explanation;

  const _Question(this.prompt, this.options, this.correct, this.explanation);

  static List<_Question> read(Object? value) {
    final questions = <_Question>[];
    for (final item in _objects(value)) {
      final options = _strings(item['options']);
      final correct = item['answer'];
      final prompt = _text(item['q']);
      if (prompt.isNotEmpty &&
          options.length == 4 &&
          correct is int &&
          correct >= 0 &&
          correct < options.length) {
        questions.add(
          _Question(prompt, options, correct, _text(item['explanation'])),
        );
      }
    }
    if (questions.isEmpty) {
      throw ApiException('No questions were available. Please try again.');
    }
    return questions;
  }
}

enum _PlacementStage { intro, aptitude, technical, interview, report }

class MockPlacementScreen extends StatefulWidget {
  final String token;
  const MockPlacementScreen({super.key, required this.token});

  @override
  State<MockPlacementScreen> createState() => _MockPlacementScreenState();
}

class _MockPlacementScreenState extends State<MockPlacementScreen> {
  _PlacementStage _stage = _PlacementStage.intro;
  final _code = TextEditingController();
  final _aptitudeAnswers = <int, int>{};
  final _technicalAnswers = <int, int>{};
  List<_Question> _aptitude = [];
  List<_Question> _technical = [];
  Map<String, dynamic> _task = {};
  Map<String, dynamic> _codingReview = {};
  Map<String, dynamic> _interviewFeedback = {};
  String? _recordingPath;
  bool _busy = false;
  String? _error;
  String _level = 'MNC'; // Startup | MNC | Top-tier, sent to the backend live

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _advance(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _advance(() async {
    final data = await ApiService.mentorPlacementRequest(
      widget.token,
      'exam/aptitude',
      body: {'difficulty': _level},
    );
    final questions = _Question.read(data['questions']);
    if (!mounted) return;
    setState(() {
      _aptitude = questions;
      _stage = _PlacementStage.aptitude;
    });
  });

  Future<void> _loadTechnical() => _advance(() async {
    final data = await ApiService.mentorPlacementRequest(
      widget.token,
      'exam/technical',
      body: {'difficulty': _level},
    );
    final questions = _Question.read(data['mcqs']);
    final task = _object(data['coding']);
    if (_text(task['prompt']).isEmpty) {
      throw ApiException('No coding task was available. Please try again.');
    }
    if (!mounted) return;
    setState(() {
      _technical = questions;
      _task = task;
      _code.text = _text(task['starter']);
      _stage = _PlacementStage.technical;
    });
  });

  Future<void> _reviewCode() => _advance(() async {
    final code = _code.text.trim();
    final review = await ApiService.mentorPlacementRequest(
      widget.token,
      'exam/coding-review',
      body: {
        'question': _text(_task['prompt']),
        'language': _text(_task['language']),
        'code': code == _text(_task['starter']) ? '' : code,
      },
    );
    if (!mounted) return;
    setState(() {
      _codingReview = review;
      _stage = _PlacementStage.interview;
    });
  });

  Future<void> _interview() => _advance(() async {
    final result = await Navigator.of(context)
        .push<({Map<String, dynamic> feedback, String? recordingPath})>(
          MaterialPageRoute(
            builder: (_) => NexoraInterviewScreen(
              token: widget.token,
              returnFeedback: true,
            ),
          ),
        );
    if (!mounted || result == null) return;
    setState(() {
      _interviewFeedback = result.feedback;
      _recordingPath = result.recordingPath;
      _stage = _PlacementStage.report;
    });
  });

  @override
  Widget build(BuildContext context) {
    final content = switch (_stage) {
      _PlacementStage.intro => [
        _stepper(-1),
        _hero(),
        const SizedBox(height: 22),
        const Text(
          'Select difficulty',
          style: TextStyle(
              color: ascendInk, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _levelPicker(),
        _button('Begin assessment', _start),
      ],
      _PlacementStage.aptitude => [
        _stepper(0),
        ..._quiz('Aptitude Round', _aptitude, _aptitudeAnswers),
        _button('Continue to Technical Round', _loadTechnical),
      ],
      _PlacementStage.technical => [
        _stepper(1),
        ..._quiz('Technical Round', _technical, _technicalAnswers),
        _Group(
          title: 'Coding task · ${_text(_task['title'])}',
          children: [
            Text(_text(_task['prompt']),
                style: const TextStyle(color: ascendInk, height: 1.4)),
            if (_text(_task['language']).isNotEmpty)
              Text('Language: ${_text(_task['language'])}',
                  style: const TextStyle(color: ascendMuted, fontSize: 12)),
            if (_text(_task['hint']).isNotEmpty)
              Text('Hint: ${_text(_task['hint'])}',
                  style: const TextStyle(color: ascendMuted, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: _code,
              enabled: !_busy,
              minLines: 8,
              maxLines: 16,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 13, color: ascendInk),
              decoration: InputDecoration(
                hintText: 'Write your solution here',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0E0B06),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3A2F17)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3A2F17)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ascendGold),
                ),
              ),
            ),
          ],
        ),
        _button('Submit Technical Round', _reviewCode),
      ],
      _PlacementStage.interview => [
        _stepper(2),
        _Group(
          title: 'Live video interview',
          children: const [
            Text(
              'You will speak with Nexa, an HR interviewer, over a live video call. Camera and microphone access are required. Your recording is analysed to prepare feedback when the call ends.',
              style: TextStyle(color: ascendMuted, height: 1.4),
            ),
          ],
        ),
        _button('Start Video Interview', _interview),
      ],
      _PlacementStage.report => _report(),
    };

    return AscendPage(
      title: _stage == _PlacementStage.report
          ? 'Placement Report'
          : 'Mock Placement',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ...content,
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: ascendGold)),
        ],
      ),
    );
  }

  Widget _levelPicker() {
    const levels = [
      ('Startup', 'Easy'),
      ('MNC', 'Moderate'),
      ('Top-tier', 'Hard'),
    ];
    return Row(
      children: [
        for (final (name, hint) in levels)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: name == 'Top-tier' ? 0 : 8),
              child: GestureDetector(
                onTap: _busy ? null : () => setState(() => _level = name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _level == name
                        ? ascendGold
                        : const Color(0xFF17130C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _level == name
                          ? ascendGold
                          : const Color(0xFF3A2F17),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: _level == name
                              ? const Color(0xFF1A1200)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(
                          color: _level == name
                              ? const Color(0xB31A1200)
                              : Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _button(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _busy ? null : ascendGradient,
          color: _busy ? const Color(0xFF3A2F17) : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextButton(
          onPressed: _busy ? null : action,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1A1200),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
    ),
  );

  Widget _stepper(int active) {
    const labels = ['Aptitude', 'Technical', 'Interview'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= active
                            ? ascendGold
                            : const Color(0xFF3A2F17),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Round ${i + 1} · ${labels[i]}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == active
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: i <= active ? ascendInk : ascendMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hero() {
    const rows = [
      (Icons.psychology_alt_outlined, 'Aptitude', 'Logical and quantitative reasoning'),
      (Icons.code_rounded, 'Technical', 'Core concepts and a coding task'),
      (Icons.videocam_outlined, 'Video interview', 'Live HR round with Nexa'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF17130C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3A2F17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mock placement drive',
            style: TextStyle(
                color: ascendInk, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Three rounds, one detailed report with explanations.',
            style: TextStyle(color: ascendMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          for (final (icon, title, sub) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0x22E8BA48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: ascendGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: ascendInk,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(sub,
                            style: const TextStyle(
                                color: ascendMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _option(String letter, String text, bool selected, VoidCallback? onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? const Color(0x22E8BA48) : const Color(0xFF100D07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? ascendGold : const Color(0xFF3A2F17),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? ascendGold : const Color(0xFF2A2214),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xFF1A1200) : ascendMuted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: ascendInk, fontSize: 14, height: 1.3)),
              ),
            ],
          ),
        ),
      );

  List<Widget> _quiz(
    String title,
    List<_Question> questions,
    Map<int, int> answers,
  ) => [
    Text(
      title,
      style: const TextStyle(
          color: ascendInk, fontSize: 22, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 6),
    Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: questions.isEmpty ? 0 : answers.length / questions.length,
              minHeight: 6,
              backgroundColor: const Color(0xFF3A2F17),
              color: ascendGold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${answers.length}/${questions.length}',
            style: const TextStyle(color: ascendMuted, fontSize: 12)),
      ],
    ),
    const SizedBox(height: 6),
    for (final (index, question) in questions.indexed)
      _Group(
        title: 'Question ${index + 1}',
        children: [
          Text(question.prompt,
              style: const TextStyle(
                  color: ascendInk,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
          const SizedBox(height: 4),
          for (final (option, text) in question.options.indexed)
            _option(
              String.fromCharCode(65 + option),
              text,
              answers[index] == option,
              _busy ? null : () => setState(() => answers[index] = option),
            ),
        ],
      ),
  ];

  Widget _tile(String label, String value) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF17130C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A2F17)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: ascendGold, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: ascendMuted, fontSize: 11)),
        ],
      ),
    ),
  );

  int _correctCount(List<_Question> qs, Map<int, int> a) =>
      qs.indexed.where((e) => a[e.$1] == e.$2.correct).length;

  List<Widget> _report() {
    final score = _codingReview['score'];
    final verdict = _text(_codingReview['verdict']);
    final overall = _object(_interviewFeedback['overall']);
    return [
      Row(
        children: [
          _tile('Aptitude',
              '${_correctCount(_aptitude, _aptitudeAnswers)}/${_aptitude.length}'),
          _tile('Technical',
              '${_correctCount(_technical, _technicalAnswers)}/${_technical.length}'),
          _tile('Coding',
              score is num && verdict != 'Submitted' ? '$score' : '—'),
        ],
      ),
      const SizedBox(height: 10),
      _review('Aptitude', _aptitude, _aptitudeAnswers),
      _review('Technical', _technical, _technicalAnswers),
      _Group(
        title: 'Coding review',
        children: [
          if (score is num && verdict != 'Submitted')
            Text('$score / 100',
                style: const TextStyle(
                    color: ascendGold,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          Text(verdict, style: const TextStyle(color: ascendInk)),
          Text(_text(_codingReview['feedback']),
              style: const TextStyle(color: ascendMuted, height: 1.4)),
          Text(_text(_codingReview['idealApproach']),
              style: const TextStyle(color: ascendMuted, height: 1.4)),
        ],
      ),
      _Group(
        title: 'Video interview',
        children: [
          Text(_text(overall['summary']),
              style: const TextStyle(color: ascendMuted, height: 1.4)),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NexoraInterviewFeedbackScreen(
                  feedback: _interviewFeedback,
                  recordingPath: _recordingPath,
                ),
              ),
            ),
            child: const Text('View interview feedback'),
          ),
        ],
      ),
    ];
  }

  Widget _review(
    String title,
    List<_Question> questions,
    Map<int, int> answers,
  ) {
    final correct = _correctCount(questions, answers);
    return _Group(
      title: '$title review · $correct / ${questions.length} correct',
      children: [
        for (final (index, q) in questions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  answers[index] == q.correct
                      ? Icons.check_circle
                      : Icons.cancel,
                  size: 18,
                  color: answers[index] == q.correct
                      ? const Color(0xFF4CC38A)
                      : const Color(0xFFE5645A),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text('${index + 1}. ${q.prompt}',
                          style: const TextStyle(
                              color: ascendInk,
                              fontWeight: FontWeight.w600,
                              height: 1.3)),
                      Text(
                        'Your answer: ${answers[index] == null ? 'Skipped' : q.options[answers[index]!]}',
                        style: const TextStyle(
                            color: ascendMuted, fontSize: 12.5),
                      ),
                      Text('Correct answer: ${q.options[q.correct]}',
                          style: const TextStyle(
                              color: ascendMuted, fontSize: 12.5)),
                      if (q.explanation.isNotEmpty)
                        Text(q.explanation,
                            style: const TextStyle(
                                color: ascendMuted,
                                fontSize: 12.5,
                                height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF17130C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A2F17)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ascendGold,
              fontSize: 12,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const _Retry({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            TextButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
