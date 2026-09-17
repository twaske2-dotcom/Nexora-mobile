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

  static const Duration requestTimeout = Duration(seconds: 30);

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
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['reply'] is String) {
          return data['reply'];
        }

        return "Sorry, I couldn't understand that.";
      }

      return 'Something went wrong. Please try again.';
    } catch (e) {
      return "Couldn't reach the server. Check your connection.";
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

      final streamedResponse = await request.send().timeout(requestTimeout);

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
          .timeout(requestTimeout);

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

  static Future<String?> generateCoverLetter(
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
          .timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data['letter'] is String) {
          return data['letter'];
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<dynamic>> searchExternalJobs(
    String token, {
    String what = 'software developer',
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

      return [];
    } catch (e) {
      return [];
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
}
