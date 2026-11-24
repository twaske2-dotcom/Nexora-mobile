import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl =
      'https://resumeapp-backend-uo3n.onrender.com/api';

  // The free Render server sleeps when idle and can take ~50s to wake up,
  // so the timeout is long; otherwise the first request fails with a network error.
  static const Duration requestTimeout = Duration(seconds: 60);

  // File upload and PDF parsing can take a little longer.
  static const Duration uploadTimeout = Duration(seconds: 90);

  // AI (Gemini) calls generate text: cover letter, feedback, chat.
  // The backend read timeout is 60s plus a possible Render cold start,
  // so there is extra buffer here to keep slow replies from timing out.
  static const Duration aiTimeout = Duration(seconds: 120);

  // Called when the app opens. Wakes the sleeping Render server so it is
  // ready by the time the user finishes typing their login.
  // Fire-and-forget: failures are ignored silently.
  static Future<void> wakeUpServer() async {
    try {
      await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 90));
    } catch (_) {
      // Ignore - this is only a warm-up
    }
  }

  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['token'] is String) {
          return data['token'];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> register(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/auth/register');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'role': role,
            }),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data is Map && data['token'] is String) {
          return data['token'];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getJobs(String token) async {
    final url = Uri.parse('$baseUrl/jobs');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        if (data is Map && data['content'] is List) {
          return data['content'];
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String> chatWithAi(String message) async {
    final url = Uri.parse('$baseUrl/ai/chat');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(aiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['reply'] is String) {
          return data['reply'];
        }

        return "Sorry, I couldn't understand that.";
      }

      // Show the server's own explanation (e.g. AI key / quota problem)
      // instead of hiding it behind a generic message.
      try {
        final err = jsonDecode(response.body);
        if (err is Map && err['reply'] is String &&
            (err['reply'] as String).trim().isNotEmpty) {
          return err['reply'] as String;
        }
      } catch (_) {}
      return 'Something went wrong (server code ${response.statusCode}). Please try again.';
    } catch (e) {
      return "Couldn't reach the server. Check your internet connection. If you are online, the server may be waking up, so try again in a minute.";
    }
  }

  static Future<Map<String, dynamic>?> uploadResume(
    String token,
    String filePath,
    String fileName,
  ) async {
    final url = Uri.parse('$baseUrl/resume/upload');

    try {
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );

      final streamedResponse = await request.send().timeout(uploadTimeout);

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> getMatchScores(String token) async {
    final url = Uri.parse('$baseUrl/jobs/match-scores');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      return {};
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>?> getMatchDetail(
    String token,
    int jobId,
  ) async {
    final url = Uri.parse('$baseUrl/jobs/$jobId/match-detail');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<String>> getResumeFeedback(String token) async {
    final url = Uri.parse('$baseUrl/resume/feedback');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(aiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['tips'] is List) {
          return List<String>.from(data['tips']);
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getResumeAnalysis(String token) async {
    final url = Uri.parse('$baseUrl/resume/analysis');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Analysis for ONE specific past upload (tapped in History), computed live
  // on the backend from that resume's own text — so every resume shows its
  // own score, breakdown and fixes, not just the latest one.
  static Future<Map<String, dynamic>?> getResumeAnalysisById(
    String token,
    int resumeId,
  ) async {
    final url = Uri.parse('$baseUrl/resume/analysis/$resumeId');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List?> generateResume(
    String token,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/resume/generate');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(data),
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Generates a cover letter. Returns the letter on success; otherwise throws
  // the backend's real error message as an ApiException so the screen does not
  // show a misleading "upload a resume" message.
  static Future<String> generateCoverLetter(
    String token,
    String jobTitle,
    String companyName,
  ) async {
    final url = Uri.parse('$baseUrl/resume/cover-letter');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'jobTitle': jobTitle,
              'companyName': companyName,
            }),
          )
          .timeout(aiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is Map && data['letter'] is String) {
          return data['letter'] as String;
        }
        throw ApiException('The AI returned an unexpected response.');
      }

      // Backend sends {"error": "..."} — show that instead of a guess.
      if (data is Map && data['error'] is String) {
        throw ApiException(data['error'] as String);
      }
      throw ApiException('Server error (${response.statusCode}). Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        "Couldn't reach the server. It may be waking up — try again in a moment.",
      );
    }
  }

  // ---- Nexora Ascend (AI mentor "Nexa") ----
  // Resume-adaptive roadmap. Backend detects role/domain from the resume and
  // returns {role, level, summary, stages[], insiderEdge[]}. Always returns a
  // usable map (backend sends a general fallback if AI/resume is unavailable).
  static Future<Map<String, dynamic>> getMentorRoadmap(String token) async {
    final url = Uri.parse('$baseUrl/mentor/roadmap');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(aiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (response.statusCode == 404) {
        throw ApiException(
            "Nexora Ascend isn't live on the server yet. Redeploy the backend, then try again.");
      }
      if (data is Map && data['error'] is String) {
        throw ApiException(data['error'] as String);
      }
      throw ApiException('Server error (${response.statusCode}). Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        "Couldn't build your roadmap. The server may be waking up — try again in a moment.",
      );
    }
  }

  // Learn with Nexa: resume-aware mentor chat. Returns the reply text.
  static Future<String> mentorChat(String token, String message) async {
    final url = Uri.parse('$baseUrl/mentor/chat');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(aiTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data is Map && data['reply'] is String) {
        return data['reply'] as String;
      }
      if (response.statusCode == 404) {
        throw ApiException(
            "Nexora Ascend isn't live on the server yet. Redeploy the backend, then try again.");
      }
      if (data is Map && data['error'] is String) {
        throw ApiException(data['error'] as String);
      }
      throw ApiException('Server error (${response.statusCode}). Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        "Couldn't reach Nexa right now. The server may be waking up — try again in a moment.",
      );
    }
  }

  // Interview questions tailored to the resume. Returns {role, questions:[...]}.
  static Future<Map<String, dynamic>> getInterviewQuestions(String token) async {
    final url = Uri.parse('$baseUrl/mentor/interview/questions');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(aiTimeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (response.statusCode == 404) {
        throw ApiException(
            "Nexora Ascend isn't live on the server yet. Redeploy the backend, then try again.");
      }
      if (data is Map && data['error'] is String) {
        throw ApiException(data['error'] as String);
      }
      throw ApiException('Server error (${response.statusCode}). Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        "Couldn't start the interview. The server may be waking up — try again in a moment.",
      );
    }
  }

  // Sends the transcript (+ optional webcam snapshot) and returns structured
  // feedback: {overall, body, confidence, qa[]}.
  static Future<Map<String, dynamic>> mentorPlacementRequest(
    String token,
    String path, {
    Map<String, String>? body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mentor/$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ).timeout(aiTimeout);
      if (response.statusCode == 404) {
        throw ApiException('This Nexora feature is unavailable on the server.');
      }
      final data = jsonDecode(response.body);
      if (data is Map && response.statusCode == 200) {
        return Map<String, dynamic>.from(data);
      }
      throw ApiException(
        data is Map && data['error'] is String
            ? data['error'] as String
            : 'Nexa could not complete the request. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not load Nexa data. Please try again.');
    }
  }

  static Future<Map<String, dynamic>> getInterviewFeedback(
    String token, {
    List<Map<String, String>> transcript = const [],
    String? imageBase64,
    String? audioBase64,
    String? audioMime,
    String? videoBase64,
    String? videoMime,
    List<String> questions = const [],
  }) async {
    final url = Uri.parse('$baseUrl/mentor/interview/feedback');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'transcript': transcript,
              if (questions.isNotEmpty) 'questions': questions,
              if (imageBase64 != null && imageBase64.isNotEmpty)
                'imageBase64': imageBase64,
              if (audioBase64 != null && audioBase64.isNotEmpty) ...{
                'audioBase64': audioBase64,
                'audioMime': audioMime ?? 'audio/aac',
              },
              if (videoBase64 != null && videoBase64.isNotEmpty) ...{
                'videoBase64': videoBase64,
                'videoMime': videoMime ?? 'video/mp4',
              },
            }),
          )
          .timeout(aiTimeout);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (response.statusCode == 404) {
        throw ApiException(
            "Nexora Ascend isn't live on the server yet. Redeploy the backend, then try again.");
      }
      if (data is Map && data['error'] is String) {
        throw ApiException(data['error'] as String);
      }
      throw ApiException('Server error (${response.statusCode}). Please try again.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        "Couldn't build your feedback. The server may be waking up — try again in a moment.",
      );
    }
  }

  // One live turn of the spoken interview: sends the conversation so far and
  // gets Nexa's next spoken line back ({reply, closing}).
  static Future<Map<String, dynamic>> interviewReply(
    String token, {
    required List<Map<String, String>> history,
    required int turn,
    int maxTurns = 6,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/mentor/interview/reply'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'history': history,
              'turn': turn,
              'maxTurns': maxTurns,
            }),
          )
          .timeout(const Duration(seconds: 40));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      throw ApiException('Nexa could not reply. Please try again.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Nexa is taking a moment. Please try again.');
    }
  }

  static Future<List<dynamic>> searchExternalJobs(
    String token, {
    String what = '',
    String? where,
    String country = 'in',
  }) async {
    final params = <String, String>{'what': what, 'country': country};

    if (where != null && where.trim().isNotEmpty) {
      params['where'] = where.trim();
    }

    final url = Uri.parse(
      '$baseUrl/external-jobs/search',
    ).replace(queryParameters: params);

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }
      }

      if (response.statusCode == 401) {
        throw ApiException('Session expired. Please log in again.');
      }
      throw ApiException(
        'Could not fetch live jobs right now. Please try again in a moment.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Server is waking up or offline. Please try again in 30 seconds.',
      );
    }
  }

  static Future<List<dynamic>> getResumeHistory(String token) async {
    final url = Uri.parse('$baseUrl/resume/history');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        if (data is Map && data['content'] is List) {
          return data['content'];
        }

        if (data is Map && data['resumes'] is List) {
          return data['resumes'];
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Saves one application after the user taps "Apply Now".
  // Fire-and-forget style: returns true on success, false on any failure,
  // so a tracking hiccup never blocks the user from opening the job link.
  static Future<bool> recordApplication(
    String token, {
    required String title,
    String? company,
    String? location,
    String? jobUrl,
    double? matchScore,
  }) async {
    final url = Uri.parse('$baseUrl/applications');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'title': title,
              'company': company,
              'location': location,
              'jobUrl': jobUrl,
              'matchScore': matchScore,
            }),
          )
          .timeout(requestTimeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // Returns the user's applied jobs, newest first.
  // Each item: {id, title, company, location, jobUrl, matchScore, status, appliedAt}
  static Future<List<dynamic>> getApplications(String token) async {
    final url = Uri.parse('$baseUrl/applications');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        }

        if (data is Map && data['content'] is List) {
          return data['content'];
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  // Moves an application to a new stage and/or saves notes.
  static Future<bool> updateApplication(
    String token,
    int id, {
    String? status,
    String? notes,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/applications/$id'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (status != null) 'status': status,
              if (notes != null) 'notes': notes,
            }),
          )
          .timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Removes an application from the tracker.
  static Future<bool> deleteApplication(String token, int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/applications/$id'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Nexa explains why a live job matches the resume and plans the missing skills.
  // Returns {why: String, plan: List<String>}. Throws ApiException with a readable message.
  static Future<Map<String, dynamic>> jobInsight(
    String token, {
    required String title,
    required String company,
    required String description,
    required List<String> matched,
    required List<String> missing,
    num? match,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/mentor/job-insight'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'title': title,
              'company': company,
              'description': description,
              'matched': matched,
              'missing': missing,
              'match': match,
            }),
          )
          .timeout(const Duration(seconds: 45));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      if (data is Map && data['error'] is String) {
        throw ApiException(data['error'] as String);
      }
      throw ApiException('Nexa could not explain this job. Please try again.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
          'Could not reach the server. Check your connection and try again.');
    }
  }
}
