import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

static const bool isProduction = false;
//static const bool useVM = false;  //en local

static const bool useVM = false; //en la MV

static String get baseUrl {
  if (isProduction) {
    return 'http://185.28.22.148'; // VPS
  }

  if (useVM) {
    return 'http://10.1.1.17:8000'; // VM
  }

  return 'http://127.0.0.1:8000'; // local
}
  static String get apiBase => '$baseUrl/api/v1';

  static Future<Map<String, dynamic>> login(
    String employeeNumber,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_number': employeeNumber.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(jsonDecode(response.body));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token'] ?? '');
        await prefs.setString('user_data', jsonEncode(data));

        return data;
      } else {
        dynamic err;
        try {
          err = jsonDecode(response.body);
        } catch (_) {
          err = {'detail': response.body};
        }
        throw Exception(err['detail'] ?? 'Credenciales inválidas');
      }
    } catch (e) {
      throw Exception('Error en login: ${_friendlyNetworkError(e)}');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>?> getSavedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_data');
    if (raw == null || raw.isEmpty) return null;

    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
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
    } catch (e) {
      throw Exception('Error al obtener perfil: ${_friendlyNetworkError(e)}');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }

  static Future<void> forgotPassword(
    String employeeNumber,
    String contact,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBase/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_number': employeeNumber.trim(),
          'email': contact.trim(),
          'contact': contact.trim(),
        }),
      );

      if (response.statusCode == 200) return;

      dynamic err;
      try {
        err = jsonDecode(response.body);
      } catch (_) {
        err = {'detail': response.body};
      }

      throw Exception(err['detail'] ?? 'No se pudo enviar el código');
    } catch (e) {
      throw Exception('Error en recuperación: $e');
    }
  }

  static Future<void> verifyCode(String employeeNumber, String code) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_number': employeeNumber.trim(),
          'code': code.trim(),
        }),
      );

      if (res.statusCode != 200) {
        dynamic err;
        try {
          err = jsonDecode(res.body);
        } catch (_) {
          err = {'detail': res.body};
        }
        throw Exception(err['detail'] ?? 'Código inválido');
      }
    } catch (e) {
      throw Exception('Error al verificar código: ${_friendlyNetworkError(e)}');
    }
  }

  static Future<void> resetPassword(
    String employeeNumber,
    String code,
    String password,
  ) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_number': employeeNumber.trim(),
          'code': code.trim(),
          'new_password': password,
        }),
      );

      if (res.statusCode != 200) {
        dynamic err;
        try {
          err = jsonDecode(res.body);
        } catch (_) {
          err = {'detail': res.body};
        }
        throw Exception(err['detail'] ?? 'No se pudo restablecer la contraseña');
      }
    } catch (e) {
      throw Exception(
        'Error al restablecer contraseña: ${_friendlyNetworkError(e)}',
      );
    }
  }

  static String _friendlyNetworkError(Object e) {
    final text = e.toString().toLowerCase();

    if (text.contains('failed to fetch')) {
      return 'No se pudo conectar con el servidor.';
    }

    if (text.contains('clientexception')) {
      return 'Error de conexión con el servidor.';
    }

    if (text.contains('socketexception')) {
      return 'Sin conexión al servidor o a internet.';
    }

    if (text.contains('connection refused')) {
      return 'El servidor rechazó la conexión.';
    }

    return e.toString();
  }
}