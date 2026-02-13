import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8080';
    return 'http://10.0.2.2:8080';
  }

  static String get apiBase => '$baseUrl/api/v1';

  static Future<Map<String, dynamic>> login(
    String employeeNumber,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$apiBase/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_number': employeeNumber,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);

      return Map<String, dynamic>.from(data);
    } else {
      dynamic err;
      try {
        err = jsonDecode(response.body);
      } catch (_) {
        err = {'detail': response.body};
      }
      throw Exception(err['detail'] ?? 'Credenciales inválidas');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$apiBase/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<void> forgotPassword(String employeeNumber, String email) async {
    final res = await http.post(
      Uri.parse('$apiBase/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_number': employeeNumber,
        'email': email,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail']);
    }
  }

  static Future<void> verifyCode(String employeeNumber, String code) async {
    final res = await http.post(
      Uri.parse('$apiBase/auth/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_number': employeeNumber,
        'code': code,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail']);
    }
  }

  static Future<void> resetPassword(
    String employeeNumber,
    String code,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$apiBase/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'employee_number': employeeNumber,
        'code': code,
        'new_password': password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)['detail']);
    }
  }
}