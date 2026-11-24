import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class ExternalJobsScreen extends StatefulWidget {
  final String token;

  const ExternalJobsScreen({super.key, required this.token});

  @override
  State<ExternalJobsScreen> createState() => _ExternalJobsScreenState();
}

class _ExternalJobsScreenState extends State<ExternalJobsScreen> {
  final TextEditingController _searchController = TextEditingController(
    text: 'software developer',
  );

  final TextEditingController _whereController = TextEditingController();

  String _country = 'in';

  List<dynamic> jobs = [];

  bool isLoading = false;

  String? errorMessage;

  final Map<String, String> countries = const {
    'in': 'India',
    'us': 'United States',
    'gb': 'United Kingdom',
    'ca': 'Canada',
    'au': 'Australia',
    'de': 'Germany',
    'sg': 'Singapore',
    'nl': 'Netherlands',
  };

  @override
  void initState() {
    super.initState();
    // search() uses FocusScope.of(context), which is not allowed inside
    // initState. Run it after the first frame instead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) search();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _whereController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = _searchController.text.trim().isEmpty
        ? ''
        : _searchController.text.trim();

    final where = _whereController.text.trim();

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await ApiService.searchExternalJobs(
        widget.token,
        what: query,
        where: where.isEmpty ? null : where,
        country: _country,
      );

      if (!mounted) return;

      setState(() {
        jobs = results;
        isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        jobs = [];
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        jobs = [];
        errorMessage = 'Something went wrong while loading jobs.';
        isLoading = false;
      });
    }
  }

  Future<void> _openJob(String? url) async {
    if (url == null || url.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application link is not available for this job.'),
        ),
      );

      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid application link.')),
      );

      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the application link.')),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the application link.')),
      );
    }
  }

  String _text(dynamic value) {
    if (value == null) return '';

    return value.toString().trim();
  }

  // Records the application (best-effort) and then opens the job link.
  // Recording failures are silent so they never block opening the job.
  Future<void> _applyToJob({
    required String title,
    required String company,
    required String location,
    required String url,
  }) async {
    ApiService.recordApplication(
      widget.token,
      title: title.isEmpty ? 'Job application' : title,
      company: company.isEmpty ? null : company,
      location: location.isEmpty ? null : location,
      jobUrl: url,
    );

    await _openJob(url);
  }

  String _salaryText(dynamic min, dynamic max) {
    final minValue = _number(min);
    final maxValue = _number(max);

    if (minValue == null && maxValue == null) {
      return 'Salary not specified';
    }

    if (minValue != null && maxValue != null) {
      return '${_formatNumber(minValue)} - ${_formatNumber(maxValue)}';
    }

    if (minValue != null) {
      return 'From ${_formatNumber(minValue)}';
    }

    return 'Up to ${_formatNumber(maxValue!)}';
  }

  num? _number(dynamic value) {
    if (value is num) return value;

    if (value is String) {
      return num.tryParse(value);
    }

    return null;
  }

  String _formatNumber(num value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  int? _matchPercent(dynamic value) {
    final number = _number(value);

    if (number == null) return null;

    return number.round().clamp(0, 100);
  }

  List<String> _skills(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  String _dateText(dynamic value) {
    final raw = _text(value);

    if (raw.isEmpty) {
      return 'Date not available';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  Color _matchColor(int percent) {
    if (percent >= 75) {
      return const Color(0xFF6FDB9A);
    }

    if (percent >= 50) {
      return const Color(0xFFE0C35A);
    }

    return const Color(0xFFE0A94F);
  }

  void _showJobDetails(Map<String, dynamic> job) {
    final title = _text(job['title']);
    final company = _text(job['company']);
    final location = _text(job['location']);
    final description = _text(job['description']);
    final category = _text(job['category']);
    final contractType = _text(job['contractType']);
    final contractTime = _text(job['contractTime']);
    final created = job['created'];
    final redirectUrl = _text(job['redirectUrl']);

    final salary = _salaryText(job['salaryMin'], job['salaryMax']);

    final match = _matchPercent(job['matchPercent']);

    final matchedSkills = _skills(job['matchedSkills']);

    final missingSkills = _skills(job['missingSkills']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14100A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.86,
            minChildSize: 0.55,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Text(
                      title.isEmpty ? 'Job Details' : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),

                    if (company.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        company,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (location.isNotEmpty)
                          _infoChip(Icons.location_on_outlined, location),
                        if (contractTime.isNotEmpty)
                          _infoChip(
                            Icons.schedule_outlined,
                            _prettyValue(contractTime),
                          ),
                        if (contractType.isNotEmpty)
                          _infoChip(
                            Icons.work_outline_rounded,
                            _prettyValue(contractType),
                          ),
                        if (category.isNotEmpty)
                          _infoChip(Icons.category_outlined, category),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _detailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Salary',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            salary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    _detailCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white54,
                            size: 17,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Posted: ${_dateText(created)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (match != null) ...[
                      const SizedBox(height: 16),
                      _detailCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: Color(0xFFF4D67A),
                                  size: 19,
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  'Resume Match',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$match%',
                                  style: TextStyle(
                                    color: _matchColor(match),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: match / 100,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.08,
                                ),
                                color: _matchColor(match),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (matchedSkills.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Skills you already have',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: matchedSkills.map((skill) {
                          return _skillChip(skill, const Color(0xFF6FDB9A));
                        }).toList(),
                      ),
                    ],

                    if (missingSkills.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'Skills to improve',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: missingSkills.map((skill) {
                          return _skillChip(skill, const Color(0xFFE0A94F));
                        }).toList(),
                      ),
                    ],

                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      const Text(
                        'About this job',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      _detailCard(
                        child: Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    _detailCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How to apply',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Use the application button below. '
                            'It opens the original job listing '
                            'provided by the live job service.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: redirectUrl.isEmpty
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                _applyToJob(
                                  title: title,
                                  company: company,
                                  location: location,
                                  url: redirectUrl,
                                );
                              },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text(
                          'Apply Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8BA48),
                          foregroundColor: Color(0xFF1A1200),
                          disabledBackgroundColor: Colors.white10,
                          disabledForegroundColor: Colors.white30,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Center(
                      child: Text(
                        'Source: Adzuna job listing',
                        style: TextStyle(color: Colors.white30, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _prettyValue(String value) {
    if (value.isEmpty) return '';

    final normalized = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();

    if (normalized.isEmpty) {
      return value;
    }

    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}'
              '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _detailCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: child,
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillChip(String skill, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _jobCard(Map<String, dynamic> job) {
    final title = _text(job['title']);
    final company = _text(job['company']);
    final location = _text(job['location']);
    final category = _text(job['category']);
    final contractTime = _text(job['contractTime']);

    final match = _matchPercent(job['matchPercent']);

    final missingSkills = _skills(job['missingSkills']);

    final salary = _salaryText(job['salaryMin'], job['salaryMax']);

    final created = job['created'];

    return GestureDetector(
      onTap: () => _showJobDetails(job),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty ? 'Job opening' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8BA48).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white54,
                    size: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (location.isNotEmpty)
                  _smallTag(Icons.location_on_outlined, location),
                _smallTag(Icons.payments_outlined, salary),
                if (contractTime.isNotEmpty)
                  _smallTag(
                    Icons.schedule_outlined,
                    _prettyValue(contractTime),
                  ),
                if (category.isNotEmpty)
                  _smallTag(Icons.category_outlined, category),
              ],
            ),

            if (match != null) ...[
              const SizedBox(height: 13),
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: _matchColor(match), size: 17),
                  const SizedBox(width: 5),
                  Text(
                    '$match% resume match',
                    style: TextStyle(
                      color: _matchColor(match),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'View details',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: match / 100,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  color: _matchColor(match),
                ),
              ),
            ],

            if (missingSkills.isNotEmpty) ...[
              const SizedBox(height: 11),
              Text(
                'Improve: ${missingSkills.take(4).join(', ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE0A94F),
                  fontSize: 10.8,
                ),
              ),
            ],

            const SizedBox(height: 11),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.white30,
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  _dateText(created),
                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                ),
                const Spacer(),
                const Text(
                  'Tap for full details',
                  style: TextStyle(color: Colors.white30, fontSize: 10.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallTag(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white38, size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => search(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Role, e.g. Android developer',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white38,
                      size: 19,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading ? null : search,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: isLoading
                        ? null
                        : const LinearGradient(
                            colors: [Color(0xFFE8BA48), Color(0xFFC48A0A)],
                          ),
                    color: isLoading ? Colors.white10 : null,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        )
                      : const Icon(Icons.search, color: Color(0xFF1A1200), size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          TextField(
            controller: _whereController,
            onSubmitted: (_) => search(),
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'Location, e.g. Bengaluru, Mumbai, Remote',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Colors.white54,
                size: 18,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.045),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: countries.entries.map((entry) {
                final selected = _country == entry.key;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () {
                            if (_country == entry.key) {
                              return;
                            }

                            setState(() {
                              _country = entry.key;
                            });

                            search();
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE8BA48).withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFE8BA48)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white54,
                          fontSize: 11.5,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE8BA48).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFF4D67A),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load live jobs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Please try again in a moment.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: search,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.045),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work_outline_rounded,
                color: Colors.white38,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No jobs found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Try another job title or location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchController.text = 'software developer';
                _whereController.clear();
                search();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Search'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF4D67A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: [
          Text(
            '${jobs.length} live ${jobs.length == 1 ? 'job' : 'jobs'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(Icons.bolt_rounded, color: Color(0xFF6FDB9A), size: 15),
          const SizedBox(width: 4),
          const Text(
            'Live listings',
            style: TextStyle(color: Colors.white38, fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    await search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0804),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0804),
        elevation: 0,
        title: const Text(
          'Explore Jobs',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: isLoading ? null : search,
            tooltip: 'Refresh jobs',
            icon: const Icon(Icons.refresh_rounded, size: 21),
          ),
        ],
      ),
      body: Column(
        children: [
          _searchArea(),
          Expanded(
            child: isLoading && jobs.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE8BA48)),
                  )
                : errorMessage != null && jobs.isEmpty
                ? _errorView()
                : jobs.isEmpty
                ? _emptyView()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: const Color(0xFFE8BA48),
                    backgroundColor: const Color(0xFF17130C),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: jobs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _resultsHeader();
                        }

                        final rawJob = jobs[index - 1];

                        if (rawJob is! Map) {
                          return const SizedBox.shrink();
                        }

                        final job = Map<String, dynamic>.from(rawJob);

                        return _jobCard(job);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
