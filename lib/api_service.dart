import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://resumeapp-backend-uo3n.onrender.com/api";

  static Future<String?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'];
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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['token'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> getJobs(String token) async {
    final url = Uri.parse('$baseUrl/jobs');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<String> chatWithAi(String message) async {
    final url = Uri.parse('$baseUrl/ai/chat');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? "Sorry, I couldn't understand that.";
      }
      return "Something went wrong. Please try again.";
    } catch (e) {
      return "Couldn't reach the server. Check your connection.";
    }
  }

  // Concept: multipart file upload with authentication header
  static Future<Map<String, dynamic>?> uploadResume(
    String token,
    String filePath,
    String fileName,
  ) async {
    final url = Uri.parse('$baseUrl/resume/upload');
    try {
      // Concept: MultipartRequest - special request type for file uploads
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      // Concept: attaching the actual file bytes from disk to the request
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath, filename: fileName),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Concept: fetches {jobId: matchPercent} map from the backend
  static Future<Map<String, dynamic>> getMatchScores(String token) async {
    final url = Uri.parse('$baseUrl/jobs/match-scores');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // Concept: fetches score + matched/missing skill lists for one job
  static Future<Map<String, dynamic>?> getMatchDetail(String token, int jobId) async {
    final url = Uri.parse('$baseUrl/jobs/$jobId/match-detail');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Concept: sends the user's saved resume text to Gemini, gets back 4 short tips
  static Future<List<String>> getResumeFeedback(String token) async {
    final url = Uri.parse('$baseUrl/resume/feedback');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['tips'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Concept: builds a formatted resume PDF from structured form data, returns raw PDF bytes
  static Future<Uint8List?> generateResume(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/resume/generate');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Concept: sends jobTitle + companyName, backend returns {"letter": "..."} - we unwrap it here
  static Future<String?> generateCoverLetter(
    String token,
    String jobTitle,
    String companyName,
  ) async {
    final url = Uri.parse('$baseUrl/resume/cover-letter');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'jobTitle': jobTitle, 'companyName': companyName}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['letter'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Concept: fetches real, live jobs from Adzuna (worldwide) with resume match % per job
  static Future<List<dynamic>> searchExternalJobs(
    String token, {
    String what = 'software developer',
    String? where,
    String country = 'in',
  }) async {
    final params = {
      'what': what,
      'country': country,
      if (where != null && where.isNotEmpty) 'where': where,
    };
    final url = Uri.parse('$baseUrl/external-jobs/search').replace(queryParameters: params);
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}