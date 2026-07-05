import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/ticket.dart';
import '../models/user.dart';
import '../models/notification.dart'; // 🔥 TAMBAHKAN INI
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Ticket>> getTickets() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/tickets'),
        headers: headers,
      );

      print('=== GET TICKETS RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('=============================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ticketsJson = data['data'] ?? [];
        return ticketsJson.map((json) => Ticket.fromJson(json)).toList();
      } else {
        String errorMessage = 'Gagal mengambil data tiket';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  Future<Ticket> getTicketDetail(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/tickets/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Ticket.fromJson(data['data']);
      } else {
        String errorMessage = 'Gagal mengambil detail tiket';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  Future<Map<String, dynamic>> createTicket({
    required String title,
    required String category,
    required String priority,
    required String description,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = jsonEncode({
        'title': title,
        'category': category,
        'priority': priority,
        'description': description,
      });

      print('=== CREATE TICKET REQUEST ===');
      print('Headers: $headers');
      print('Body: $body');
      print('==============================');

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/tickets'),
        headers: headers,
        body: body,
      );

      print('=== CREATE TICKET RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('================================');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Tiket berhasil dibuat',
          'ticketId': data['data']['id'] ?? 0,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal membuat tiket',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateTicketStatus(int id, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/tickets/$id'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Status tiket diperbarui',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal update status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteTicket(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/tickets/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Tiket berhasil dihapus',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal hapus tiket',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // ========== UPLOAD ATTACHMENT ==========
  Future<Map<String, dynamic>> uploadAttachment(int ticketId, Uint8List bytes, String fileName) async {
    try {
      print('=== UPLOAD ATTACHMENT ===');
      print('Ticket ID: $ticketId');
      print('File name: $fileName');
      print('Bytes size: ${bytes.length}');

      final token = await _authService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Constants.baseUrl}/tickets/$ticketId/attachments'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Upload response: $responseBody');

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'File berhasil diupload'};
      } else {
        final error = jsonDecode(responseBody);
        return {'success': false, 'message': error['message'] ?? 'Upload gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Koneksi gagal: $e'};
    }
  }

  // ========== USER MANAGEMENT (ADMIN ONLY) ==========

  Future<List<User>> getUsers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> usersJson = data['data'] ?? [];
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        String errorMessage = 'Gagal mengambil data user';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String username,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/users'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'User berhasil ditambahkan',
          'data': data['data'] ?? {},
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal menambahkan user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateUser({
    required int id,
    String? name,
    String? username,
    String? email,
    String? password,
    String? role,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (role != null) body['role'] = role;

      final response = await http.put(
        Uri.parse('${Constants.baseUrl}/users/$id'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'User berhasil diupdate',
          'data': data['data'] ?? {},
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal update user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${Constants.baseUrl}/users/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'User berhasil dihapus',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal hapus user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  // ========== 🔥 NOTIFICATIONS ==========

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/notifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        return list.map((json) => NotificationModel.fromJson(json)).toList();
      } else {
        String errorMessage = 'Gagal mengambil notifikasi';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Koneksi gagal: $e');
    }
  }

  Future<Map<String, dynamic>> markNotificationRead(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/notifications/$id/mark-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Notifikasi ditandai sudah dibaca',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal menandai notifikasi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }

  Future<Map<String, dynamic>> markAllNotificationsRead() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/notifications/mark-all-read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Semua notifikasi telah dibaca',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal menandai semua notifikasi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi gagal: $e',
      };
    }
  }
}