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
  String _country = 'in';
  List<dynamic> jobs = [];
  bool isLoading = false;

  // Concept: Adzuna country codes - one key works across all of these
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
    search();
  }

  Future<void> search() async {
    setState(() => isLoading = true);
    final results = await ApiService.searchExternalJobs(
      widget.token,
      what: _searchController.text.trim().isEmpty
          ? 'software developer'
          : _searchController.text.trim(),
      country: _country,
    );
    setState(() {
      jobs = results;
      isLoading = false;
    });
  }

  Future<void> _openJob(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D14),
        title: const Text(
          'Explore Jobs',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Role, e.g. Android developer',
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: search,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B5CF0), Color(0xFFB06AB3)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: countries.entries.map((e) {
                      final selected = _country == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _country = e.key);
                            search();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(
                                      0xFF7B5CF0,
                                    ).withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF7B5CF0)
                                    : Colors.white12,
                              ),
                            ),
                            child: Text(
                              e.value,
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
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B5CF0)),
                  )
                : jobs.isEmpty
                ? const Center(
                    child: Text(
                      'No jobs found. Try a different search.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final matchPercent = job['matchPercent'] as int?;
                      final missing = List<String>.from(
                        job['missingSkills'] ?? [],
                      );

                      return GestureDetector(
                        onTap: () => _openJob(job['redirectUrl']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.045),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          job['title'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${job['company'] ?? ''} · ${job['location'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.white24,
                                    size: 16,
                                  ),
                                ],
                              ),
                              if (matchPercent != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      color: matchPercent >= 60
                                          ? const Color(0xFF6FDB9A)
                                          : const Color(0xFFE0A94F),
                                      size: 15,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$matchPercent% match',
                                      style: TextStyle(
                                        color: matchPercent >= 60
                                            ? const Color(0xFF6FDB9A)
                                            : const Color(0xFFE0A94F),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (missing.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: missing.take(4).map((s) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFE0A94F,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            color: Color(0xFFE0A94F),
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
