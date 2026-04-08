import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/app_models.dart';

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String getDefaultBaseUrl() {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kDebugMode) {
      return 'http://127.0.0.1:8000';
    }
    return 'https://hsebook.pythonanywhere.com';
  }

  // ==================== Authentication ====================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerAdmin({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String projectName,
    required String projectArea,
    required String projectDuration,
    String? role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register/admin/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'project_name': projectName,
        'project_area': projectArea,
        'project_duration': projectDuration,
        if (role != null && role.isNotEmpty) 'role': role,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body).toString());
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerStaff({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String projectName,
    required String accessCode,
    String? role,
  }) async {
    final body = {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'project_name': projectName,
      'access_code': accessCode,
      if (role != null && role.isNotEmpty) 'role': role,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/api/register/staff/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body).toString());
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/user/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get profile: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String token, {
    String? firstName,
    String? lastName,
    String? email,
    String? bio,
    http.MultipartFile? profilePicture,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseUrl/api/user/profile/update/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    if (firstName != null) request.fields['first_name'] = firstName;
    if (lastName != null) request.fields['last_name'] = lastName;
    if (email != null) request.fields['email'] = email;
    if (bio != null) request.fields['bio'] = bio;
    if (profilePicture != null) request.files.add(profilePicture);
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== Admin User Management ====================

  Future<List<Map<String, dynamic>>> getProjectUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/users/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get users: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> deleteUser(String token, int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/admin/users/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'user_id': userId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.body}');
    }
  }

  Future<void> changeUserRole(String token, int userId, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/change-role/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, 'role': role}),
    );
    if (response.statusCode != 200) throw Exception('Failed to change role');
  }

  Future<void> assignUserArea(String token, int userId, String area) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/assign-area/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId, 'assigned_area': area}),
    );
    if (response.statusCode != 200) throw Exception('Failed to assign area');
  }

  Future<void> updateProjectColors(String token, String primaryColor, String secondaryColor) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/project/settings/update-colors/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'primary_color': primaryColor, 'secondary_color': secondaryColor}),
    );
    if (response.statusCode != 200) throw Exception('Failed to update colors');
  }

  // ==================== Project ====================

  Future<Map<String, dynamic>> getProject(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/project/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get project: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> regenerateProjectKey(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/project/regenerate-key/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to regenerate key: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<ProjectMember>> getProjectMembers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/project/members/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get members: ${response.body}');
    }
    final data = jsonDecode(response.body);
    final list = data is List ? data : [];
    return list.map((e) => ProjectMember.fromJson(e)).toList();
  }

  // ==================== Project Settings ====================

  Future<Map<String, dynamic>> getProjectSettings(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/project/settings/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get settings: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> updateProjectSettings(
    String token, {
    String? appName,
    String? theme,
    String? projectArea,
    String? projectDuration,
    int? manHours,
    int? equipmentCount,
    Uint8List? logoBytes,
    String? logoName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/project/settings/'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      if (appName != null) request.fields['app_name'] = appName;
      if (theme != null) request.fields['theme'] = theme;
      if (projectArea != null) request.fields['project_area'] = projectArea;
      if (projectDuration != null) {
        request.fields['project_duration'] = projectDuration;
      }
      if (manHours != null) request.fields['man_hours'] = manHours.toString();
      if (equipmentCount != null) {
        request.fields['equipment_count'] = equipmentCount.toString();
      }
      if (logoBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            logoBytes,
            filename: logoName ?? 'logo.jpg',
          ),
        );
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception('Failed to update settings: ${response.body}');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      // Return null on error instead of crashing
      return null;
    }
  }

  // ==================== Profile (PATCH endpoint) ====================

  Future<Map<String, dynamic>> updateProfilePatch(
    String token, {
    String? firstName,
    String? lastName,
    String? email,
    String? bio,
    Uint8List? profilePictureBytes,
    String? profilePictureName,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$baseUrl/api/user/profile/update/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    if (firstName != null) request.fields['first_name'] = firstName;
    if (lastName != null) request.fields['last_name'] = lastName;
    if (email != null) request.fields['email'] = email;
    if (bio != null) request.fields['bio'] = bio;
    if (profilePictureBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_picture',
          profilePictureBytes,
          filename: profilePictureName ?? 'profile.jpg',
        ),
      );
    }
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== Messages ====================

  Future<List<Message>> getMessages(String token, int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/messages/?user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get messages: ${response.body}');
    }
    final data = jsonDecode(response.body);
    final list = data is List ? data : [];
    return list.map((e) => Message.fromJson(e)).toList();
  }

  Future<Message> sendMessage(
    String token, {
    required int recipientId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/messages/send/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'recipient_id': recipientId, 'content': content}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
    return Message.fromJson(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> getConversations(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/messages/conversations/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get conversations: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<int> getUnreadMessageCount(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/messages/unread-count/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get unread count: ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['unread_count'] ?? 0;
  }

  // ==================== Posts ====================

  Future<List<PostModel>> fetchPosts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load posts: ${response.body}');
    }
    final data = jsonDecode(response.body);
    final list = data is List
        ? data
        : (data['results'] as List<dynamic>? ?? <dynamic>[]);
    return list
        .whereType<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList();
  }

  Future<PostModel> createPost({
    required String token,
    required int projectId,
    required String postType,
    required String incidentType,
    required String observation,
    required String description,
    required String rectification,
    String severity = 'Medium',
    String location = '',
    List<Uint8List>? imageBytes,
    List<String>? imageNames,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/posts/'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['project'] = projectId.toString();
    request.fields['post_type'] = postType;
    request.fields['incident_type'] = incidentType;
    request.fields['observation'] = observation;
    request.fields['description'] = description;
    request.fields['rectification'] = rectification;
    request.fields['severity'] = severity;
    request.fields['location'] = location;
    request.fields['category'] = incidentType; // For legacy support
    request.fields['status'] = 'Pending'; // Default to Pending (matches backend model choices)

    if (imageBytes != null && imageBytes.isNotEmpty) {
      for (var i = 0; i < imageBytes.length; i++) {
        final filename = (imageNames != null && i < imageNames.length)
            ? imageNames[i]
            : 'image_$i.jpg';
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            imageBytes[i],
            filename: filename,
          ),
        );
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 201) {
      throw Exception('Failed to create post: ${response.body}');
    }
    return PostModel.fromJson(jsonDecode(response.body));
  }

  Future<void> deletePost(String token, int postId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/posts/$postId/delete/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  Future<void> updatePostStatus(String token, int postId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/posts/$postId/status/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update post: ${response.body}');
    }
  }

  // ==================== Safety Intelligence ====================

  Future<Map<String, dynamic>> getProjectStats(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/project/stats/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get project stats: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<int>> exportIncidentReport(
    String token,
    String formatType, {
    String? month,
  }) async {
    final body = <String, dynamic>{};
    if (month != null) body['month'] = month;
    final response = await http.post(
      Uri.parse('$baseUrl/api/intelligence/export/$formatType/'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Export failed: ${response.body}');
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> getRiskTrends(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/intelligence/risk-trends/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get risk trends: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateHIP(
    String token,
    String taskName,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/intelligence/hip-generator/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'task_name': taskName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to generate HIP: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== Social Auth ====================

  Future<Map<String, dynamic>> socialAuthCallback({
    required String provider,
    required String email,
    String? firstName,
    String? lastName,
    String? projectName,
    String? accessCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/social/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'email': email,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'project_name': projectName,
        'access_code': accessCode,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body).toString());
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== AI Statistics & Safety Dashboard ====================

  Future<Map<String, dynamic>> getAIStats(String token) async {
    // Use project stats endpoint as fallback for AI stats
    final response = await http.get(
      Uri.parse('$baseUrl/api/project/stats/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get AI stats: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ==================== Comments ====================

  Future<List<Comment>> getComments(String token, int postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/posts/$postId/comments/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to get comments: ${response.body}');
    }
    final data = jsonDecode(response.body);
    final list = data is List ? data : [];
    return list.map((e) => Comment.fromJson(e)).toList();
  }

  Future<Comment> addComment(String token, int postId, String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/posts/$postId/comments/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add comment: ${response.body}');
    }
    return Comment.fromJson(jsonDecode(response.body));
  }
}
