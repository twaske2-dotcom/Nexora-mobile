import 'package:flutter/material.dart';
import 'api_service.dart';
import 'resume_upload_screen.dart';

// Concept: StatefulWidget - token receive karta hai aur jobs load karta hai
class DashboardScreen extends StatefulWidget {
  final String token;
  const DashboardScreen({super.key, required this.token});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> jobs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadJobs();
  }

  Future<void> loadJobs() async {
    final result = await ApiService.getJobs(widget.token);
    setState(() {
      jobs = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      // Concept: FloatingActionButton - navigates to the resume upload screen
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF7B5CF0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResumeUploadScreen(token: widget.token),
            ),
          );
        },
        child: const Icon(Icons.upload_file_rounded, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : jobs.isEmpty
          ? const Center(child: Text('No jobs found'))
          : ListView.builder(
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(job['title'] ?? ''),
                    subtitle: Text(
                      '${job['location'] ?? ''} • ${job['experienceRequired'] ?? 0} yrs',
                    ),
                    trailing: Text(job['status'] ?? ''),
                  ),
                );
              },
            ),
    );
  }
}
