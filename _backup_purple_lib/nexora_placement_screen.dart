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
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return _Retry(message: snapshot.error.toString(), retry: _reload);
          }
          final forYou = _object(data['forYou']);
          final trends = _object(data['trends']);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _text(data['role']),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ascendInk,
                ),
              ),
              Text(
                _text(data['level']),
                style: const TextStyle(color: ascendGold),
              ),
              Text(_text(data['intro'])),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _reload(refresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ),
              _section('Your strengths', _strings(forYou['strengths'])),
              _section('Skills to improve', _strings(forYou['gaps'])),
              _section('Next steps', _strings(forYou['moves'])),
              _section('Trending skills', _strings(trends['hotSkills'])),
              _section('Trending roles', _strings(trends['hotRoles'])),
              _section('What’s happening', [
                ..._strings(trends['whatsHappening']),
                if (_text(trends['note']).isNotEmpty) _text(trends['note']),
              ]),
              _resources(
                'Where to learn',
                _objects(data['learn']),
                learning: true,
              ),
              _resources('What to follow', _objects(data['stayUpdated'])),
              _section('Placement essentials', [
                for (final item in _objects(data['essentials']))
                  '${_text(item['title'])} — ${_text(item['detail'])}',
              ]),
              _section('Insider tips', [
                for (final item in _objects(data['secrets']))
                  '${_text(item['secret'])} — ${_text(item['why'])}',
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _resources(
    String label,
    List<Map<String, dynamic>> items, {
    bool learning = false,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return _Group(
      title: label,
      children: [
        for (final item in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_text(item[learning ? 'resource' : 'name'])),
            subtitle: Text(
              learning
                  ? '${_text(item['skill'])} · ${_text(item['platform'])}${item['free'] == true ? ' · Free' : ''}'
                  : _text(item['what']),
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openLink(_text(item['url'])),
          ),
      ],
    );
  }

  Widget _section(String label, List<String> items) => items.isEmpty
      ? const SizedBox.shrink()
      : _Group(
          title: label,
          children: [for (final item in items) Text('• $item')],
        );
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
        const Text(
          'Aptitude, technical and coding, then a video interview. Review your answers at the end.',
        ),
        _button('Start aptitude', _start),
      ],
      _PlacementStage.aptitude => [
        ..._quiz('Round 1 · Aptitude', _aptitude, _aptitudeAnswers),
        _button('Continue to technical', _loadTechnical),
      ],
      _PlacementStage.technical => [
        ..._quiz('Round 2 · Technical', _technical, _technicalAnswers),
        _Group(
          title: _text(_task['title']),
          children: [
            Text(_text(_task['prompt'])),
            if (_text(_task['language']).isNotEmpty)
              Text(_text(_task['language'])),
            if (_text(_task['hint']).isNotEmpty)
              Text('Hint · ${_text(_task['hint'])}'),
            TextField(
              controller: _code,
              enabled: !_busy,
              minLines: 5,
              maxLines: 12,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(labelText: 'Your code'),
            ),
          ],
        ),
        _button('Submit technical round', _reviewCode),
      ],
      _PlacementStage.interview => [
        const Text('Round 3 · Video interview'),
        const Text(
          'Camera and microphone access are required. Your recording is sent to Nexa for feedback when you finish.',
        ),
        _button('Start video interview', _interview),
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

  Widget _button(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: FilledButton(onPressed: _busy ? null : action, child: Text(label)),
  );

  List<Widget> _quiz(
    String title,
    List<_Question> questions,
    Map<int, int> answers,
  ) => [
    Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
    Text('${answers.length} of ${questions.length} answered'),
    for (final (index, question) in questions.indexed)
      _Group(
        title: '${index + 1}. ${question.prompt}',
        children: [
          for (final (option, text) in question.options.indexed)
            ChoiceChip(
              label: Text(text),
              selected: answers[index] == option,
              onSelected: _busy
                  ? null
                  : (_) => setState(() => answers[index] = option),
            ),
        ],
      ),
  ];

  List<Widget> _report() {
    final score = _codingReview['score'];
    final verdict = _text(_codingReview['verdict']);
    final overall = _object(_interviewFeedback['overall']);
    return [
      _review('Aptitude', _aptitude, _aptitudeAnswers),
      _review('Technical', _technical, _technicalAnswers),
      _Group(
        title: 'Coding review',
        children: [
          if (score is num && verdict != 'Submitted') Text('$score / 100'),
          Text(verdict),
          Text(_text(_codingReview['feedback'])),
          Text(_text(_codingReview['idealApproach'])),
        ],
      ),
      _Group(
        title: 'Video interview',
        children: [
          Text(_text(overall['summary'])),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    NexoraInterviewFeedbackScreen(
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
    final correct = questions.indexed
        .where((entry) => answers[entry.$1] == entry.$2.correct)
        .length;
    return _Group(
      title: '$title · $correct / ${questions.length}',
      children: [
        for (final (index, q) in questions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${q.prompt}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Your answer · ${answers[index] == null ? 'Skipped' : q.options[answers[index]!]}',
                ),
                Text('Correct answer · ${q.options[q.correct]}'),
                if (q.explanation.isNotEmpty) Text(q.explanation),
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
    return Card(
      color: const Color(0xFF251E12),
      margin: const EdgeInsets.symmetric(vertical: 7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ascendInk,
                fontWeight: FontWeight.bold,
              ),
            ),
            ...children,
          ],
        ),
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
