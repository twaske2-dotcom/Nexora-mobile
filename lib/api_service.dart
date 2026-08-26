import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.237.208.37:8080/api";

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
}
