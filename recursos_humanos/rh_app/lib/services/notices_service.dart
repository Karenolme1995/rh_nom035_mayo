// services/ notices_service.dart 
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
// lib/screens/nom035_reference_screen.dart
//import 'package:flutter/material.dart';
//import 'package:rh_app/screens/quiz_intro_screen.dart';


class NoticesService {
 
  static String get baseUrl => AuthService.baseUrl;
  static String get apiBase => '$baseUrl/api/v1';

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();

    final h = <String, String>{'Accept': 'application/json'};
    if (json) h['Content-Type'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }

    return h;
  }

// =====================  JSON robustos =====================
static dynamic _decodeBody(String body) {
  try {
    return jsonDecode(body);
  } catch (e) {
    throw Exception('Respuesta no es JSON válido. Body: $body');
  }
}

static List<dynamic> _extractList(dynamic decoded) {
  if (decoded is List) return decoded;

  if (decoded is Map) {
    final map = Map<String, dynamic>.from(decoded);
    for (final key in const ['items', 'data', 'results', 'rows']) {
      final v = map[key];
      if (v is List) return v;
    }
  }
  return <dynamic>[];
}

static Map<String, dynamic> _asStringMap(dynamic x) {
  if (x is Map<String, dynamic>) return x;
  if (x is Map) return x.map((k, v) => MapEntry(k.toString(), v));
  return <String, dynamic>{};
}

static List<Map<String, dynamic>> _asListOfStringMaps(dynamic decoded) {
  final list = _extractList(decoded);
  return list.map(_asStringMap).where((m) => m.isNotEmpty).toList();
}

 

// ===================== Birthdays =====================

Future<List<Map<String, dynamic>>> getBirthdaysToday() async {
  final uri = Uri.parse('$apiBase/birthdays/today');
  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 10),
  );

  print('GET /birthdays/today => ${res.statusCode} ${res.body}');

  if (res.statusCode != 200) {
    throw Exception('GET /birthdays/today => ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return _asListOfStringMaps(decoded);
}

Future<List<Map<String, dynamic>>> getBirthdaysCurrentMonth() async {
  final uri = Uri.parse('$apiBase/birthdays/month');
  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 10),
  );

  print('GET /birthdays/month => ${res.statusCode} ${res.body}');

  if (res.statusCode != 200) {
    throw Exception('GET /birthdays/month => ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return _asListOfStringMaps(decoded);
}


  // ===================== USERS =====================
Future<List<Map<String, dynamic>>> getUsers() async {
  final res = await http.get(
    Uri.parse('$apiBase/users/'),
    headers: await _headers(),
  );

  if (res.statusCode != 200) {
    throw Exception('GET /users => ${res.statusCode}');
  }

  final decoded = _decodeBody(res.body);
  return _asListOfStringMaps(decoded);
}
   Future<void> createUser(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$apiBase/users/'),
      headers: await _headers(json: true),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('POST /users => ${res.statusCode}');
    }
  }

  Future<void> updateUser(dynamic id, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse('$apiBase/users/$id'),
      headers: await _headers(json: true),
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      throw Exception('PUT /users/$id => ${res.statusCode}');
    }
  }

 Future<void> deleteUser(dynamic id) async {
    final res = await http.delete(
      Uri.parse('$apiBase/users/$id'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('DELETE /users/$id => ${res.statusCode}');
    }
  }


  // ===================== AREAS / POSITIONS  =====================

static List<Map<String, dynamic>>? _areasCache;
static Map<int, String>? _areasMapCache;

static List<Map<String, dynamic>>? _positionsListCache; 
static Map<int, String>? _positionsMapCache;

static int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

static String _asString(dynamic v) => v == null ? '' : v.toString();

static Future<List<Map<String, dynamic>>> fetchAreas({bool force = false}) async {
  if (!force && _areasCache != null) return _areasCache!;

  final uri = Uri.parse('$apiBase/areas/').replace(queryParameters: {'active': '1'});
  final headers = await _headers(json: false);

  final res = await http.get(uri, headers: headers);
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error obteniendo áreas: ${res.statusCode} ${res.body}');
  }

  final data = jsonDecode(res.body);
  final list = (data is List) ? data : (data['items'] ?? data['data'] ?? data['rows'] ?? []);
  if (list is! List) throw Exception('Respuesta inválida de áreas');

  final rows = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

  _areasCache = rows;
  _areasMapCache = {
    for (final r in rows)
      _asInt(r['id'] ?? r['area_id']): _asString(r['name'] ?? r['area'] ?? r['nombre'])
  };

  return rows;
}

static Future<List<Map<String, dynamic>>> fetchPositions({int? areaId, bool force = false}) async {
  if (!force && _positionsListCache != null && areaId == null) return _positionsListCache!;

  final qp = <String, String>{'active': '1'};
  if (areaId != null) qp['area_id'] = areaId.toString();

  final uri = Uri.parse('$apiBase/positions/').replace(queryParameters: qp); // ✅ slash final
  final headers = await _headers(json: false);

  final res = await http.get(uri, headers: headers);
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error obteniendo puestos: ${res.statusCode} ${res.body}');
  }

  final data = jsonDecode(res.body);
  final list = (data is List) ? data : (data['items'] ?? data['data'] ?? data['rows'] ?? []);
  if (list is! List) throw Exception('Respuesta inválida de puestos');

  final rows = list.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();

  if (areaId == null) {
    _positionsListCache = rows;
    _positionsMapCache = {
      for (final r in rows)
        _asInt(r['id'] ?? r['position_id']): _asString(r['name'] ?? r['position'] ?? r['nombre'])
    };
  }

  return rows;
}

Future<Map<int, String>> getAreasMap() async {
  final headers = await _headers();

  final res = await http.get(
    Uri.parse('$apiBase/areas/'),
    headers: headers,
  );

  if (res.statusCode != 200) {
    throw Exception('Error cargando áreas: ${res.body}');
  }

  final List data = jsonDecode(res.body);

  final Map<int, String> map = {};
  for (final item in data) {
    final id = (item['id'] as num?)?.toInt();
    final name = item['name']?.toString();
    if (id != null && name != null) {
      map[id] = name;
    }
  }

  return map;
}


Future<Map<int, String>> getPositionsMap() async {
  final headers = await _headers();

  final res = await http.get(
    Uri.parse('$apiBase/positions/'),
    headers: headers,
  );

  if (res.statusCode != 200) {
    throw Exception('Error cargando puestos: ${res.body}');
  }

  final List data = jsonDecode(res.body);

  final Map<int, String> map = {};
  for (final item in data) {
    final id = (item['id'] as num?)?.toInt();
    final name = item['name']?.toString();
    if (id != null && name != null) {
      map[id] = name;
    }
  }

  return map;
}
static void clearCatalogCache() {
  _areasCache = null;
  _areasMapCache = null;
  _positionsListCache = null; 
  _positionsMapCache = null;
}

// ===================== AREAS / POSITIONS (wrappers) =====================


Future<List<Map<String, dynamic>>> getAreas({bool force = false}) async {
  return await NoticesService.fetchAreas(force: force);
}

Future<List<Map<String, dynamic>>> getPositions({int? areaId, bool force = false}) async {
  return await NoticesService.fetchPositions(areaId: areaId, force: force);
}


 


Future<String?> _getToken() async {
  return await AuthService.getToken();
}

  Map<String, String> _headersWithAuth(String? token) {
    if (token == null || token.isEmpty) return {};
    return {"Authorization": "Bearer $token"};
  }


// =============================
// 🔹 MI PERFIL
// =============================

// GET /api/v1/profile/
Future<Map<String, dynamic>> getMyProfile() async {
  final res = await http.get(
    Uri.parse('$apiBase/profile/'),
    headers: await _headers(),
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
  return Map<String, dynamic>.from(jsonDecode(res.body));
}

// PUT /api/v1/profile/

Future<void> updateMyProfile(Map<String, dynamic> payload) async {
  final res = await http.put(
    Uri.parse('$apiBase/profile/'),
    headers: await _headers(json: true),
    body: jsonEncode(payload),
  );
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP ${res.statusCode}: ${res.body}');
  }
}



// POST /api/v1/profile/avatar
Future<String> uploadMyAvatar(File file) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$apiBase/profile/avatar'),
  );

  request.headers.addAll(await _headers());
  request.files.add(await http.MultipartFile.fromPath('file', file.path));

  final response = await request.send();
  final respStr = await response.stream.bytesToString();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('HTTP ${response.statusCode}: $respStr');
  }

  final data = jsonDecode(respStr);
  final url = (data['avatar'] ?? data['avatar_url'] ?? data['url'] ?? data['path'])
      ?.toString()
      .trim();

  if (url == null || url.isEmpty) {
    throw Exception('Respuesta sin URL de avatar: $data');
  }

  return url;
}




Future<String> uploadMyAvatarWeb(Uint8List bytes, String filename) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$apiBase/profile/avatar'),
  );

  request.headers.addAll(await _headers());
  request.files.add(
    http.MultipartFile.fromBytes('file', bytes, filename: filename),
  );

  final response = await request.send();
  final respStr = await response.stream.bytesToString();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('HTTP ${response.statusCode}: $respStr');
  }

  final data = jsonDecode(respStr);
  final url = (data['avatar'] ?? data['avatar_url'] ?? data['url'] ?? data['path'])
      ?.toString()
      .trim();

  if (url == null || url.isEmpty) {
    throw Exception('Respuesta sin URL de avatar: $data');
  }

  return url;
}



 // =============================
  // 🔹 SUBIR AVATAR (OTRO USUARIO) (Móvil: File)
  // =============================
Future<String> uploadUserAvatar(int userId, File file) async {
  final token = await _getToken();
  if (token == null || token.isEmpty) {
    throw Exception('No hay token');
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$apiBase/users/$userId/avatar'),
  );

  request.headers.addAll(_headersWithAuth(token));

  request.files.add(
    await http.MultipartFile.fromPath('file', file.path),
  );

  final response = await request.send();
  final respStr = await response.stream.bytesToString();
  
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('HTTP ${response.statusCode}: $respStr');
  }

  final data = jsonDecode(respStr);

  final url = (data['avatar_url'] ?? data['url'] ?? data['avatar'] ?? data['path'])?.toString();
  if (url == null || url.isEmpty) {
    throw Exception('Respuesta sin URL de avatar: $data');
  }

  return url;
}


  // =============================

Future<String> uploadUserAvatarWeb(int userId, Uint8List bytes, String filename) async {
  final token = await _getToken();
  if (token == null || token.isEmpty) {
    throw Exception('No hay token');
  }

  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$apiBase/users/$userId/avatar'),
  );

  request.headers.addAll(_headersWithAuth(token));

  request.files.add(
    http.MultipartFile.fromBytes('file', bytes, filename: filename),
  );

  final response = await request.send();
  final respStr = await response.stream.bytesToString();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('HTTP ${response.statusCode}: $respStr');
  }

  final data = jsonDecode(respStr);

  final url = (data['avatar_url'] ?? data['url'] ?? data['avatar'] ?? data['path'])?.toString();
  if (url == null || url.isEmpty) {
    throw Exception('Respuesta sin URL de avatar: $data');
  }

  return url;
}

// =====================================================


static Future<Map<String, dynamic>> getSubmissionDetail(dynamic submissionId) async {
  final uri = Uri.parse('$apiBase/submissions/$submissionId');
  final res = await http.get(uri, headers: await _headers()).timeout(
        const Duration(seconds: 10),
      );

  print('GET /submissions/$submissionId => ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('GET /submissions/$submissionId => ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return Map<String, dynamic>.from(decoded as Map);
}

static Future<void> saveAnswers(dynamic submissionId, List<Map<String, dynamic>> answers) async {
  final uri = Uri.parse('$apiBase/submissions/$submissionId/answers');
  final res = await http
      .put(
        uri,
        headers: await _headers(json: true),
        body: jsonEncode({'answers': answers}),
      )
      .timeout(const Duration(seconds: 10));

  print('PUT /submissions/$submissionId/answers => ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('PUT /submissions/$submissionId/answers => ${res.statusCode} ${res.body}');
  }
}



// ===================== FORMS / SUBMISSIONS PARA CURSOS=====================

// ===================== FORMS / SUBMISSIONS PARA CURSOS =====================

// 1) Lista de disponibles (pendientes / en curso)
static Future<List<Map<String, dynamic>>> getAvailableForms() async {
  // GENERAL
  final uri = Uri.parse('$apiBase/forms/available');
  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 10),
  );

  print('GET /forms/available => ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('GET /forms/available => ${res.statusCode} ${res.body}');
  }

  final general = _asListOfStringMaps(_decodeBody(res.body));

  // NOM035
  final nom = await getNom035AvailableForms();

  // Merge
  final out = <Map<String, dynamic>>[];
  out.addAll(general);
  out.addAll(nom);
  return out;
}

// 2) Lista de concluidos
static Future<List<Map<String, dynamic>>> getCompletedForms() async {
  // GENERAL
  final uri = Uri.parse('$apiBase/forms/completed');
  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 10),
  );

  print('GET /forms/completed => ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('GET /forms/completed => ${res.statusCode} ${res.body}');
  }

  final general = _asListOfStringMaps(_decodeBody(res.body));

  // NOM035
  final nom = await getNom035CompletedForms();

  // Merge
  final out = <Map<String, dynamic>>[];
  out.addAll(general);
  out.addAll(nom);
  return out;
}
// ==========================================
  // NOM-035 ENDPOINTS
  // ========================================


static Map<String, dynamic> _normalizeNom035Item(Map<String, dynamic> f) {
  // Algunos backends mandan cycle_id en vez de form_id
  final dynamic cycleId = f['form_id'] ?? f['cycle_id'] ?? f['id'];

  final title = (f['title'] ?? 'NOM-035').toString();

  // Defaults seguros (si backend aún no manda flags)
  final canStart = f['can_start'] == true;
  final canPreview = f['can_preview'] == true;
  final reasonLocked = (f['reason_locked'] ?? '').toString();

  // status submission: available|in_progress|submitted
  final status = (f['status'] ?? 'available').toString();

  return <String, dynamic>{
    ...f,
    'type': 'nom035',
    'title': title,
    'form_id': cycleId,
    'status': status,
    'can_start': canStart,
    'can_preview': canPreview,
    'reason_locked': reasonLocked,
  };
}


// 1) Disponibles NOM035
static Future<List<Map<String, dynamic>>> getNom035AvailableForms() async {
  final res = await http.get(
    Uri.parse('$apiBase/nom035/forms/available'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 10));

  print('GET /nom035/forms/available => ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('Error NOM035 available: ${res.statusCode} ${res.body}');
  }

  final list = _asListOfStringMaps(_decodeBody(res.body));
  return list.map(_normalizeNom035Item).toList();
}

// 2) Concluidos NOM035
static Future<List<Map<String, dynamic>>> getNom035CompletedForms() async {
  final res = await http.get(
    Uri.parse('$apiBase/nom035/forms/completed'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 10));

  print('GET /nom035/forms/completed => ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('Error NOM035 completed: ${res.statusCode} ${res.body}');
  }

  final list = _asListOfStringMaps(_decodeBody(res.body));

  return list.map(_normalizeNom035Item).toList();
}

//3
 static Future<Map<String, dynamic>> startNom035Form(int cycleId) async {
    final res = await http.post(
      Uri.parse('$apiBase/nom035/forms/$cycleId/start'),
      headers: await _headers(json: true),
    );

    if (res.statusCode != 200) {
      throw Exception('Error start');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

//4
static Future<Map<String, dynamic>> getNom035FormDetail(int cycleId) async {
  final res = await http.get(
    Uri.parse('$apiBase/nom035/forms/$cycleId/detail'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 10));

  if (res.statusCode != 200) {
    throw Exception('Error NOM035 detail: ${res.statusCode} ${res.body}');
  }

  final raw = _asStringMap(_decodeBody(res.body));

  final normalized = normalizeNom035DetailToQuiz(raw);

  
  normalized['type'] = 'nom035';
  normalized['form'] = Map<String, dynamic>.from(normalized['form'] ?? {});
  normalized['form']['type'] = 'nom035';

  return normalized;
}
//5

static Future<Map<String, dynamic>> submitNom035Answer({
  required int submissionId,
  required int questionId,
  required dynamic answerValue,
  Map<String, dynamic>? guideVProfile,
}) async {
  final res = await http.post(
    Uri.parse('$apiBase/nom035/submissions/$submissionId/answer'),
    headers: await _headers(json: true),
    body: jsonEncode({
      'question_id': questionId,
      'answer_value': answerValue,
      if (guideVProfile != null) 'guide_v_profile': guideVProfile,
    }),
  );
  if (res.statusCode != 200) {
    throw Exception('Error NOM035 answer: ${res.statusCode} ${res.body}');
  }
  return _asStringMap(_decodeBody(res.body));
}

static Future<Map<String, dynamic>> submitNom035Form(
  int submissionId, {
  Map<String, dynamic>? guideVProfile,
}) async {
  final res = await http.post(
    Uri.parse('$apiBase/nom035/submissions/$submissionId/submit'),
    headers: await _headers(json: true),
    body: jsonEncode({
      if (guideVProfile != null) 'guide_v_profile': guideVProfile,
    }),
  );
  if (res.statusCode != 200) {
    throw Exception('Error NOM035 submit: ${res.statusCode} ${res.body}');
  }
  return _asStringMap(_decodeBody(res.body));
}

  static Future<Map<String, dynamic>> getNom035Result(int submissionId) async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035/submissions/$submissionId/result'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Error result');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }
  
  // ===========================================================================
                        // ADMIN NOM-035 (role_id 1 y 2)
//1
   static Future<List<Map<String, dynamic>>> adminGetCycles() async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035/admin/cycles'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Error NOM035 admin cycles: ${res.statusCode} ${res.body}');
    }
    return _asListOfStringMaps(_decodeBody(res.body));
  }
  //2
  static Future<Map<String, dynamic>> adminCreateCycle(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$apiBase/nom035/admin/cycles'),
      headers: await _headers(json: true),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Error NOM035 admin create cycle: ${res.statusCode} ${res.body}');
    }
    return _asStringMap(_decodeBody(res.body));
  }

  //3

   static Future<Map<String, dynamic>> adminUpdateCycle(int cycleId, Map<String, dynamic> payload) async {
    final res = await http.put(
      Uri.parse('$apiBase/nom035/admin/cycles/$cycleId'),
      headers: await _headers(json: true),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Error NOM035 admin update cycle: ${res.statusCode} ${res.body}');
    }
    return _asStringMap(_decodeBody(res.body));
  }

//4
   static Future<List<Map<String, dynamic>>> adminGetQuestions() async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035/admin/questions'),
      headers: await _headers(),
    );
    if (res.statusCode != 200) {
      throw Exception('Error NOM035 admin questions: ${res.statusCode} ${res.body}');
    }
    return _asListOfStringMaps(_decodeBody(res.body));
  }
//5

static Future<List<Map<String, dynamic>>> adminGetSections() async {
  final res = await http.get(
    Uri.parse('$apiBase/nom035/admin/sections'),
    headers: await _headers(),
  );

  // Si el backend aún no lo implementa, regresa lista vacía y no truena la app
  if (res.statusCode == 404) {
    return <Map<String, dynamic>>[];
  }

  if (res.statusCode != 200) {
    throw Exception('Error NOM035 admin sections: ${res.statusCode} ${res.body}');
  }

  return _asListOfStringMaps(_decodeBody(res.body));
}

 static Future<Map<String, dynamic>> adminUpsertQuestion(Map<String, dynamic> payload) async {
    final res = await http.post(
      Uri.parse('$apiBase/nom035/admin/questions'),
      headers: await _headers(json: true),
      body: jsonEncode(payload),
    );
    if (res.statusCode != 200) {
      throw Exception('Error NOM035 admin upsert question: ${res.statusCode} ${res.body}');
    }
    return _asStringMap(_decodeBody(res.body));
  }

  //6


static Future<Map<String, dynamic>> adminSetCycleQuestions({
    required int cycleId,
    required List<int> questionIds,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBase/nom035/admin/cycles/$cycleId/questions'),
      headers: await _headers(json: true),
      body: jsonEncode({'question_ids': questionIds}),
    );
    if (res.statusCode != 200) {
      throw Exception('Error NOM035 admin cycle questions: ${res.statusCode} ${res.body}');
    }
    return _asStringMap(_decodeBody(res.body));
  }


// =========================
//  guardar respuestas y submit generales s
static Future<void> _saveAnswersGeneral(int submissionId, List<Map<String, dynamic>> payload) async {
  final res = await http.post(
    Uri.parse('$apiBase/forms/submissions/$submissionId/answers'),
    headers: await _headers(json: true),
    body: jsonEncode({'answers': payload}),
  );
  if (res.statusCode != 200) {
    throw Exception('Error saveAnswers general: ${res.statusCode} ${res.body}');
  }
}

static Future<Map<String, dynamic>> _submitGeneral(int submissionId) async {
  final res = await http.post(
    Uri.parse('$apiBase/forms/submissions/$submissionId/submit'),
    headers: await _headers(json: true),
    body: jsonEncode({}),
  );
  if (res.statusCode != 200) {
    throw Exception('Error submit general: ${res.statusCode} ${res.body}');
  }
  return _asStringMap(_decodeBody(res.body));
}

// =========================
///   unificada  QuizRunner ya usa

static Future<List<Map<String, dynamic>>> getSubmissionAnswers(
  int submissionId, {
  String? type,
}) async {
  try {
    final dynamic data = (type == 'nom035')
        ? await getNom035SubmissionAnswers(submissionId)
        : await getSubmissionAnswersGeneral(submissionId);

    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map && data['data'] is Map && (data['data']['answers'] is List)) {
      raw = List<dynamic>.from(data['data']['answers']);
    } else if (data is Map && data['answers'] is List) {
      raw = List<dynamic>.from(data['answers']);
    } else {
      raw = <dynamic>[];
    }

    return raw.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{};
    }).toList();
  } catch (_) {
    return <Map<String, dynamic>>[];
  }
}
//
static Future<void> saveSingleAnswerByType(
  int submissionId, {
  required int questionId,
  required dynamic answerValue,
  String? type,
  Map<String, dynamic>? guideVProfile,
}) async {
  final body = jsonEncode({
    'question_id': questionId,
    'answer_value': answerValue,
    if (guideVProfile != null) 'guide_v_profile': guideVProfile,
  });

  final uri = (type == 'nom035')
      ? Uri.parse('$apiBase/nom035/submissions/$submissionId/answer')
      : Uri.parse('$apiBase/forms/submissions/$submissionId/answer');

  final res = await http.post(
    uri,
    headers: await _headers(json: true),
    body: body,
  );

  if (res.statusCode != 200) {
    throw Exception('Error saveSingleAnswerByType: ${res.statusCode} ${res.body}');
  }
}

   // ----------------------------
  // GENERAL - LEER RESPUESTAS
  // ----------------------------
static Future<dynamic> getSubmissionAnswersGeneral(int submissionId) async {
  final res = await http.get(
    Uri.parse('$apiBase/forms/submissions/$submissionId/answers'),
    headers: await _headers(json: true),
  );

  if (res.statusCode != 200) {
    throw Exception('Error getSubmissionAnswers general: ${res.statusCode} ${res.body}');
  }

  return _decodeBody(res.body); // puede regresar Map o List
}

// ----------------------------
  // NOM035 - LEER RESPUESTAS
  // ----------------------------
static Future<dynamic> getNom035SubmissionAnswers(int submissionId) async {
  final res = await http.get(
    Uri.parse('$apiBase/nom035/submissions/$submissionId/answers'),
    headers: await _headers(json: true),
  );

  if (res.statusCode != 200) {
    throw Exception('Error getNom035SubmissionAnswers: ${res.statusCode} ${res.body}');
  }

  return _decodeBody(res.body); // puede regresar Map o List
}

static Future<void> saveAnswersByType(
  int submissionId,
  List<Map<String, dynamic>> payload, {
  String? type,
  Map<String, dynamic>? guideVProfile,
}) async {
  if (type == 'nom035') {
    for (final a in payload) {
      final qid = int.parse('${a['question_id']}');

      dynamic answerValue;
      if (a.containsKey('option_id')) {
        answerValue = a['option_id'];
      } else if (a.containsKey('option_ids')) {
        answerValue = a['option_ids'];
      } else if (a.containsKey('answer_text')) {
        answerValue = a['answer_text'];
      } else {
        continue;
      }

      await submitNom035Answer(
        submissionId: submissionId,
        questionId: qid,
        answerValue: answerValue,
        guideVProfile: guideVProfile,
      );
    }
    return;
  }

  await saveAnswers(submissionId, payload);
}

static Future<Map<String, dynamic>> submitFormByType(
  int submissionId, {
  String? type,
  Map<String, dynamic>? guideVProfile,
}) async {
  if (type == 'nom035') {
    return await submitNom035Form(
      submissionId,
      guideVProfile: guideVProfile,
    );
  }

  final uri = Uri.parse('$apiBase/submissions/$submissionId/submit');
  final res = await http.post(uri, headers: await _headers()).timeout(
    const Duration(seconds: 10),
  );

  print('POST /submissions/$submissionId/submit => ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('POST /submissions/$submissionId/submit => ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return Map<String, dynamic>.from(decoded as Map);
}

static Future<Map<String, dynamic>> startFormByType(dynamic formId, {String? type}) async {
  if (type == 'nom035') {
    return startNom035Form(int.parse(formId.toString()));
  }

  // GENERAL
  final uri = Uri.parse('$apiBase/forms/$formId/start');
  final res = await http.post(uri, headers: await _headers()).timeout(
    const Duration(seconds: 10),
  );

  if (res.statusCode != 200 && res.statusCode != 201) {
    throw Exception('POST /forms/$formId/start => ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return Map<String, dynamic>.from(decoded as Map);
}

static Future<Map<String, dynamic>> getFormDetailByType(dynamic formId, {String? type}) async {
  if (type == 'nom035') {
    return getNom035FormDetail(int.parse(formId.toString()));
  }

  // GENERAL
  final uri = Uri.parse('$apiBase/forms/$formId');
  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 10),
  );

  if (res.statusCode != 200) {
    throw Exception('GET /forms/$formId => ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return Map<String, dynamic>.from(decoded as Map);
}


 /// 1) LISTA submissions por ciclo (admin)
static Future<Map<String, dynamic>> getCycleSubmissions({
    required int cycleId,
    String? status,
  }) async {
    final uri = Uri.parse('$apiBase/nom035/admin/cycles/$cycleId/submissions')
        .replace(queryParameters: {
      if (status != null) 'status': status,
    });

    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode != 200) {
      throw Exception('Error cycle submissions');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }


  /// 3) EXPORT (admin) - retorna bytes para guardar/compartir
  static Future<Uint8List> exportSubmission(int submissionId) async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035/admin/submissions/$submissionId/export'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Error export');
    }

    return res.bodyBytes;
  }

  /// 4) METRICS por ciclo (admin)
 static Future<Map<String, dynamic>> getCycleMetrics(int cycleId) async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035/admin/cycles/$cycleId/metrics'),
      headers: await _headers(),
    );

    if (res.statusCode != 200) {
      throw Exception('Error metrics');
    }

    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  ///5) elimina ciclio (admin)
static Future<void> adminDeleteCycle(int cycleId) async {
  final res = await http.delete(
    Uri.parse('$apiBase/nom035/admin/cycles/$cycleId'),
    headers: await _headers(),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(
      'Error NOM035 admin delete cycle: ${res.statusCode} ${res.body}',
    );
  }
}

  /// 1) LISTA submissions por ciclo (administrador)
static Future<Map<String, dynamic>> adminNom035GetCycleSubmissions({
  required int cycleId,
  String? status,
  String? q,
  String? risk,
  int page = 1,
  int pageSize = 25,
}) async {
  final uri = Uri.parse('$apiBase/nom035/admin/cycles/$cycleId/submissions').replace(
    queryParameters: <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (risk != null && risk.trim().isNotEmpty) 'risk': risk.trim(),
    },
  );

  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 15),
  );

  print('GET /nom035/admin/cycles/$cycleId/submissions => ${res.statusCode} ${res.body}');
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return _asStringMap(decoded);
}

/// 2) DETALLE submission (admin) - guía respondida
static Future<Map<String, dynamic>> adminNom035GetSubmissionDetail({
  required int submissionId,
}) async {
  final uri = Uri.parse('$apiBase/nom035/admin/submissions/$submissionId');

  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 15),
  );

  print('GET /nom035/admin/submissions/$submissionId => ${res.statusCode} ${res.body}');
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return _asStringMap(decoded);
}

/// 3) EXPORT (admin) - retorna bytes para guardar/compartir
static Future<Uint8List> adminNom035ExportSubmission({
  required int submissionId,
  String format = 'pdf', // pdf|xlsx|docx
}) async {
  final uri = Uri.parse('$apiBase/nom035/admin/submissions/$submissionId/export')
      .replace(queryParameters: {'format': format});

  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 30),
  );

  print('GET /nom035/admin/submissions/$submissionId/export?format=$format => ${res.statusCode} bytes=${res.bodyBytes.length}');
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error ${res.statusCode}: ${utf8.decode(res.bodyBytes)}');
  }

  return res.bodyBytes;
}

/// 4) METRICS por ciclo (admin)
static Future<Map<String, dynamic>> adminNom035GetCycleMetrics({
  required int cycleId,
}) async {
  final uri = Uri.parse('$apiBase/nom035/admin/cycles/$cycleId/metrics');

  final res = await http.get(uri, headers: await _headers()).timeout(
    const Duration(seconds: 15),
  );

  print('GET /nom035/admin/cycles/$cycleId/metrics => ${res.statusCode} ${res.body}');
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return _asStringMap(decoded);
}


// ================================
// NOM-035: NORMALIZAR DETAIL A FORMATO "QUIZ" (para QuizIntroScreen)
// ================================
static Map<String, dynamic> normalizeNom035DetailToQuiz(Map<String, dynamic> d) {
  final out = <String, dynamic>{};

  final form = (d['form'] is Map) ? Map<String, dynamic>.from(d['form']) : <String, dynamic>{};
  out['title'] = (form['title'] ?? d['title'] ?? 'NOM-035').toString();

  final sectionsAny = (d['sections'] is List) ? (d['sections'] as List) : <dynamic>[];
  final sections = <Map<String, dynamic>>[];

  for (final sAny in sectionsAny) {
    if (sAny is! Map) continue;
    final s = Map<String, dynamic>.from(sAny);

    final secTitle = (s['title'] ?? s['name'] ?? 'Sección').toString();
    final secDesc = (s['description'] ?? s['instructions'] ?? '').toString();

    final secQuestions = <Map<String, dynamic>>[];

    final qList = (s['questions'] is List) ? (s['questions'] as List) : <dynamic>[];
    for (final qAny in qList) {
      final q = _normalizeNom035Question(qAny);
      if (q != null) secQuestions.add(q);
    }

    final groups = (s['groups'] is List) ? (s['groups'] as List) : <dynamic>[];
    for (final gAny in groups) {
      if (gAny is! Map) continue;
      final g = Map<String, dynamic>.from(gAny);
      final gTitle = (g['title'] ?? '').toString();

      final gQs = (g['questions'] is List) ? (g['questions'] as List) : <dynamic>[];
      for (final qAny in gQs) {
        final q = _normalizeNom035Question(qAny);
        if (q == null) continue;

        if (gTitle.trim().isNotEmpty) {
          q['question_text'] = '[$gTitle] ${q['question_text']}';
        }
        secQuestions.add(q);
      }
    }

    sections.add({
      'title': secTitle,
      'description': secDesc,
      'questions': secQuestions,
    });
  }

  out['sections'] = sections;
  return out;
}
// helper privado
static Map<String, dynamic>? _normalizeNom035Question(dynamic qAny) {
  if (qAny is! Map) return null;
  final q = Map<String, dynamic>.from(qAny);

  final id = q['id'];
  final text = (q['question_text'] ?? q['text'] ?? '').toString();
  if (text.trim().isEmpty) return null;

  final rt = (q['response_type'] ?? q['question_type'] ?? 'yes_no').toString();

  dynamic raw = q['options'] ?? q['options_json'];
  List<dynamic> opts = <dynamic>[];

  if (raw is List) {
    opts = raw;
  } else if (raw is Map) {
    opts = raw.entries.map((e) => {'option_text': '${e.value}', 'value': '${e.key}'}).toList();
  } else if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) opts = decoded;
      if (decoded is Map) {
        opts = decoded.entries.map((e) => {'option_text': '${e.value}', 'value': '${e.key}'}).toList();
      }
    } catch (_) {}
  }

  final options = opts.map((o) {
    if (o is Map) {
      final m = Map<String, dynamic>.from(o);
      final label = (m['option_text'] ?? m['label'] ?? m['text'] ?? m['value'] ?? '').toString();
      return {'option_text': label};
    }
    return {'option_text': o.toString()};
  }).toList();

  String qt = 'single';
  if (rt == 'open' || rt == 'text') qt = 'text';
  if (rt == 'multiple' || rt == 'multi') qt = 'multi';
  if (rt == 'yes_no' || rt == 'likert' || rt == 'single') qt = 'single';

  return {
    'id': id,
    'question_text': text,
    'question_type': qt,
    'options': options,
  };
}


// =====================================================
// NOM-035 AUDITORÍA
// =====================================================

Future<Map<String, dynamic>> getNom035AuditCompliance(int cycleId) async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035-audit/compliance/$cycleId'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Error compliance NOM035 audit: ${res.statusCode} ${res.body}',
      );
    }

    return _asStringMap(_decodeBody(res.body));
  }

  Future<Map<String, dynamic>> getNom035AuditStpsFile(int cycleId) async {
    final headers = await _headers();
    final res = await http.get(
      Uri.parse('$apiBase/nom035-audit/stps-file/$cycleId'),
      headers: headers,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }

    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> rebuildNom035AuditFile({
    required int cycleId,
    int? generatedByUserId,
    String? notes,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/nom035-audit/audit-file/rebuild/$cycleId'),
    );

    request.headers.addAll(await _headers());

    if (generatedByUserId != null) {
      request.fields['generated_by_user_id'] = generatedByUserId.toString();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      request.fields['notes'] = notes.trim();
    }

    final response = await request.send().timeout(const Duration(seconds: 20));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error rebuild expediente STPS: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

Future<Map<String, dynamic>> getNom035ActionPlans(int cycleId) async {
  final res = await http.get(
    Uri.parse('$apiBase/nom035-audit/action-plans/cycle/$cycleId'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 15));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error obteniendo planes de acción: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}

  Future<Map<String, dynamic>> createNom035ActionPlan({
    required int cycleId,
    int? departmentId,
    String? departmentName,
    String? riskLevel,
    required String actionTitle,
    String? actionDescription,
    String? responsibleName,
    int? responsibleUserId,
    String? dueDate,
    int? createdByUserId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/nom035-audit/action-plans'),
    );

    request.headers.addAll(await _headers());

    request.fields['cycle_id'] = cycleId.toString();
    request.fields['action_title'] = actionTitle.trim();

    if (departmentId != null) {
      request.fields['department_id'] = departmentId.toString();
    }
    if (departmentName != null && departmentName.trim().isNotEmpty) {
      request.fields['department_name'] = departmentName.trim();
    }
    if (riskLevel != null && riskLevel.trim().isNotEmpty) {
      request.fields['risk_level'] = riskLevel.trim();
    }
    if (actionDescription != null && actionDescription.trim().isNotEmpty) {
      request.fields['action_description'] = actionDescription.trim();
    }
    if (responsibleName != null && responsibleName.trim().isNotEmpty) {
      request.fields['responsible_name'] = responsibleName.trim();
    }
    if (responsibleUserId != null) {
      request.fields['responsible_user_id'] = responsibleUserId.toString();
    }
    if (dueDate != null && dueDate.trim().isNotEmpty) {
      request.fields['due_date'] = dueDate.trim();
    }
    if (createdByUserId != null) {
      request.fields['created_by_user_id'] = createdByUserId.toString();
    }

    final response = await request.send().timeout(const Duration(seconds: 20));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error creando plan de acción: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

  Future<Map<String, dynamic>> updateNom035ActionPlan({
    required int planId,
    int? cycleId,
    int? departmentId,
    String? departmentName,
    String? riskLevel,
    required String actionTitle,
    String? actionDescription,
    String? responsibleName,
    int? responsibleUserId,
    String? dueDate,
    required String status,
    required double progressPercent,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$apiBase/nom035-audit/action-plans/$planId'),
    );

    request.headers.addAll(await _headers());

    if (cycleId != null) {
      request.fields['cycle_id'] = cycleId.toString();
    }

    request.fields['status'] = status.trim();
    request.fields['progress_percent'] = progressPercent.toString();
    request.fields['action_title'] = actionTitle.trim();

    if (departmentId != null) {
      request.fields['department_id'] = departmentId.toString();
    }
    if (departmentName != null && departmentName.trim().isNotEmpty) {
      request.fields['department_name'] = departmentName.trim();
    }
    if (riskLevel != null && riskLevel.trim().isNotEmpty) {
      request.fields['risk_level'] = riskLevel.trim();
    }
    if (actionDescription != null && actionDescription.trim().isNotEmpty) {
      request.fields['action_description'] = actionDescription.trim();
    }
    if (responsibleName != null && responsibleName.trim().isNotEmpty) {
      request.fields['responsible_name'] = responsibleName.trim();
    }
    if (responsibleUserId != null) {
      request.fields['responsible_user_id'] = responsibleUserId.toString();
    }
    if (dueDate != null && dueDate.trim().isNotEmpty) {
      request.fields['due_date'] = dueDate.trim();
    }

    final response = await request.send().timeout(const Duration(seconds: 20));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error actualizando plan de acción: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

  Future<Map<String, dynamic>> deleteNom035ActionPlan(int planId) async {
    final res = await http.delete(
      Uri.parse('$apiBase/nom035-audit/action-plans/$planId'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Error eliminando plan de acción: ${res.statusCode} ${res.body}',
      );
    }

    return _asStringMap(_decodeBody(res.body));
  }

    Future<Map<String, dynamic>> getNom035Evidences(int cycleId) async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035-evidences').replace(
        queryParameters: {
          'cycle_id': cycleId.toString(),
        },
      ),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Error obteniendo evidencias: ${res.statusCode} ${res.body}',
      );
    }

    return _asStringMap(_decodeBody(res.body));
  }



// ================= CACHE EVIDENCIAS =================

static final Map<int, List<Map<String, dynamic>>> _planAttachmentsCache = {};
static final Map<int, Future<List<Map<String, dynamic>>>> _pendingPlanAttachments = {};

// Evidencias por plan
static final Map<int, List<Map<String, dynamic>>> _evidencesByPlanCache = {};
static final Map<int, Future<List<Map<String, dynamic>>>> _pendingEvidencesByPlan = {};

// Archivo binario de evidencia
static final Map<int, Uint8List> _evidenceFileBytesCache = {};
static final Map<int, Future<Uint8List>> _pendingEvidenceFileBytes = {};
static void clearNom035Caches() {
  _planAttachmentsCache.clear();
  _pendingPlanAttachments.clear();
  _evidencesByPlanCache.clear();
  _pendingEvidencesByPlan.clear();
  _evidenceFileBytesCache.clear();
  _pendingEvidenceFileBytes.clear();
}


static void clearPlanAttachmentsCache([int? planId]) {
  if (planId == null) {
    _planAttachmentsCache.clear();
    _pendingPlanAttachments.clear();
    return;
  }
  _planAttachmentsCache.remove(planId);
  _pendingPlanAttachments.remove(planId);
}


static void clearEvidencesByPlanCache([int? planId]) {
  if (planId == null) {
    _evidencesByPlanCache.clear();
    _pendingEvidencesByPlan.clear();
    return;
  }
  _evidencesByPlanCache.remove(planId);
  _pendingEvidencesByPlan.remove(planId);
}

static void clearEvidenceFileCache([int? evidenceId]) {
  if (evidenceId == null) {
    _evidenceFileBytesCache.clear();
    _pendingEvidenceFileBytes.clear();
    return;
  }
  _evidenceFileBytesCache.remove(evidenceId);
  _pendingEvidenceFileBytes.remove(evidenceId);
}



Future<List<Map<String, dynamic>>> getNom035EvidencesByPlanFast(
  int planId, {
  bool forceRefresh = false,
}) async {
  if (!forceRefresh && _evidencesByPlanCache.containsKey(planId)) {
    return _evidencesByPlanCache[planId]!;
  }

  if (!forceRefresh && _pendingEvidencesByPlan.containsKey(planId)) {
    return _pendingEvidencesByPlan[planId]!;
  }

  final future = () async {
    final res = await http.get(
      Uri.parse('$apiBase/nom035-evidences/by-plan/$planId'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Error obteniendo evidencias por plan: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = _asStringMap(_decodeBody(res.body));
    final items = _asListOfStringMaps(decoded['items'] ?? decoded);

    _evidencesByPlanCache[planId] = items;
    _pendingEvidencesByPlan.remove(planId);
    return items;
  }();

  _pendingEvidencesByPlan[planId] = future;
  return future;
}

Future<Map<String, dynamic>> getNom035EvidencesByPlan(
  int planId, {
  bool forceRefresh = false,
}) async {
  final items = await getNom035EvidencesByPlanFast(
    planId,
    forceRefresh: forceRefresh,
  );
  return {'items': items};
}

   Future<Map<String, dynamic>> createNom035Evidence({
    required int cycleId,
    int? actionPlanId,
    required String evidenceType,
    required String title,
    required File file,
    int? uploadedByUserId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/nom035-evidences'),
    );

    request.headers.addAll(await _headers());

    request.fields['cycle_id'] = cycleId.toString();
    request.fields['evidence_type'] = evidenceType.trim();
    request.fields['title'] = title.trim();

    if (actionPlanId != null) {
      request.fields['action_plan_id'] = actionPlanId.toString();
    }
    if (uploadedByUserId != null) {
      request.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final response = await request.send().timeout(const Duration(seconds: 40));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error creando evidencia: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

Future<Map<String, dynamic>> createNom035EvidenceWeb({
    required int cycleId,
    int? actionPlanId,
    required String evidenceType,
    required String title,
    required Uint8List bytes,
    required String filename,
    int? uploadedByUserId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/nom035-evidences'),
    );

    request.headers.addAll(await _headers());

    request.fields['cycle_id'] = cycleId.toString();
    request.fields['evidence_type'] = evidenceType.trim();
    request.fields['title'] = title.trim();

    if (actionPlanId != null) {
      request.fields['action_plan_id'] = actionPlanId.toString();
    }
    if (uploadedByUserId != null) {
      request.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final response = await request.send().timeout(const Duration(seconds: 40));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error creando evidencia web: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

Future<Map<String, dynamic>> updateNom035Evidence({
    required int evidenceId,
    required int cycleId,
    int? actionPlanId,
    required String evidenceType,
    required String title,
    int? uploadedByUserId,
    File? file,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$apiBase/nom035-evidences/$evidenceId'),
    );

    request.headers.addAll(await _headers());

    request.fields['cycle_id'] = cycleId.toString();
    request.fields['evidence_type'] = evidenceType.trim();
    request.fields['title'] = title.trim();

    if (actionPlanId != null) {
      request.fields['action_plan_id'] = actionPlanId.toString();
    }
    if (uploadedByUserId != null) {
      request.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    if (file != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );
    }

    final response = await request.send().timeout(const Duration(seconds: 40));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error actualizando evidencia: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }


   Future<Map<String, dynamic>> updateNom035EvidenceWeb({
    required int evidenceId,
    required int cycleId,
    int? actionPlanId,
    required String evidenceType,
    required String title,
    int? uploadedByUserId,
    Uint8List? bytes,
    String? filename,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$apiBase/nom035-evidences/$evidenceId'),
    );

    request.headers.addAll(await _headers());

    request.fields['cycle_id'] = cycleId.toString();
    request.fields['evidence_type'] = evidenceType.trim();
    request.fields['title'] = title.trim();

    if (actionPlanId != null) {
      request.fields['action_plan_id'] = actionPlanId.toString();
    }
    if (uploadedByUserId != null) {
      request.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    if (bytes != null && filename != null && filename.trim().isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
    }

    final response = await request.send().timeout(const Duration(seconds: 40));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error actualizando evidencia web: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

  Future<Map<String, dynamic>> uploadNom035Evidence({
    required int cycleId,
    int? actionPlanId,
    required String evidenceType,
    required String title,
    required String filePath,
    int? uploadedByUserId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/nom035-audit/evidences'),
    );

    request.headers.addAll(await _headers());

    request.fields['cycle_id'] = cycleId.toString();
    request.fields['evidence_type'] = evidenceType.trim();
    request.fields['title'] = title.trim();

    if (actionPlanId != null) {
      request.fields['action_plan_id'] = actionPlanId.toString();
    }
    if (uploadedByUserId != null) {
      request.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send().timeout(const Duration(seconds: 40));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error subiendo evidencia: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

  Future<Map<String, dynamic>> uploadNom035EvidenceWeb({
    required int cycleId,
    int? actionPlanId,
    required String evidenceType,
    required String title,
    required Uint8List bytes,
    required String filename,
    int? uploadedByUserId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiBase/nom035-audit/evidences'),
    );

    request.headers.addAll(await _headers());

    request.fields['cycle_id'] = cycleId.toString();
    request.fields['evidence_type'] = evidenceType.trim();
    request.fields['title'] = title.trim();

    if (actionPlanId != null) {
      request.fields['action_plan_id'] = actionPlanId.toString();
    }
    if (uploadedByUserId != null) {
      request.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final response = await request.send().timeout(const Duration(seconds: 40));
    final body = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error subiendo evidencia web: ${response.statusCode} $body');
    }

    return _asStringMap(_decodeBody(body));
  }

Future<Map<String, dynamic>> deleteNom035Evidence(int evidenceId) async {
  final res = await http.delete(
    Uri.parse('$apiBase/nom035-evidences/$evidenceId'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 15));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(
      'Error eliminando evidencia: ${res.statusCode} ${res.body}',
    );
  }

  clearEvidenceFileCache(evidenceId);

  return _asStringMap(_decodeBody(res.body));
}


Future<Uint8List> downloadNom035Evidence(
  int evidenceId, {
  bool forceRefresh = false,
}) async {
  return downloadNom035EvidenceBytesFast(
    evidenceId,
    forceRefresh: forceRefresh,
  );
}

String getNom035EvidenceDownloadUrl(int evidenceId) {
  return '$apiBase/nom035-evidences/$evidenceId/download';
}

 Future<List<Map<String, dynamic>>> getNom035ActionPlanAttachmentsFast(
  int planId, {
  bool forceRefresh = false,
}) async {
  if (!forceRefresh && _planAttachmentsCache.containsKey(planId)) {
    return _planAttachmentsCache[planId]!;
  }

  if (!forceRefresh && _pendingPlanAttachments.containsKey(planId)) {
    return _pendingPlanAttachments[planId]!;
  }

  final future = () async {
    final uri = Uri.parse('$apiBase/nom035-audit/action-plans/$planId/attachments');
    final res = await http.get(uri, headers: await _headers()).timeout(
      const Duration(seconds: 15),
    );

    if (res.statusCode == 404) {
      _planAttachmentsCache[planId] = <Map<String, dynamic>>[];
      _pendingPlanAttachments.remove(planId);
      return _planAttachmentsCache[planId]!;
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Error al cargar adjuntos: ${res.statusCode} ${res.body}');
    }

    final decoded = _asStringMap(_decodeBody(res.body));
    final items = _asListOfStringMaps(decoded['items'] ?? decoded);

    _planAttachmentsCache[planId] = items;
    _pendingPlanAttachments.remove(planId);
    return items;
  }();

  _pendingPlanAttachments[planId] = future;
  return future;
}

Future<Map<String, dynamic>> getNom035ActionPlanAttachments(
  int planId, {
  bool forceRefresh = false,
}) async {
  final items = await getNom035ActionPlanAttachmentsFast(
    planId,
    forceRefresh: forceRefresh,
  );
  return {'items': items};
}

  Future<Map<String, dynamic>> uploadNom035ActionPlanAttachment({
    required int planId,
    required File file,
    required String fileName,
    int? uploadedByUserId,
  }) async {
    final uri = Uri.parse('$apiBase/nom035-audit/action-plans/$planId/attachments');
    final req = http.MultipartRequest('POST', uri);

    req.headers.addAll(await _headers());

    if (uploadedByUserId != null) {
      req.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    req.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
      ),
    );

    final streamed = await req.send().timeout(const Duration(seconds: 40));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _asStringMap(_decodeBody(res.body));
    }

    throw Exception('Error al subir archivo: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> uploadNom035ActionPlanAttachmentWeb({
    required int planId,
    required Uint8List bytes,
    required String fileName,
    int? uploadedByUserId,
  }) async {
    final uri = Uri.parse('$apiBase/nom035-audit/action-plans/$planId/attachments');
    final req = http.MultipartRequest('POST', uri);

    req.headers.addAll(await _headers());

    if (uploadedByUserId != null) {
      req.fields['uploaded_by_user_id'] = uploadedByUserId.toString();
    }

    req.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamed = await req.send().timeout(const Duration(seconds: 40));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _asStringMap(_decodeBody(res.body));
    }

    throw Exception('Error al subir archivo web: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> deleteNom035ActionPlanAttachment(
    int attachmentId,
  ) async {
    final uri = Uri.parse('$apiBase/nom035-audit/action-plan-attachments/$attachmentId');
    final res = await http.delete(uri, headers: await _headers()).timeout(
      const Duration(seconds: 15),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _asStringMap(_decodeBody(res.body));
    }

    throw Exception('Error al eliminar adjunto: ${res.statusCode} ${res.body}');
  }

  String getNom035AttachmentDownloadUrl(int attachmentId) {
    return '$apiBase/nom035-audit/action-plan-attachments/$attachmentId/download';
  }

  Future<Uint8List> downloadNom035ActionPlanPdf(int planId) async {
    final uri = Uri.parse('$apiBase/nom035-audit/action-plans/$planId/pdf');

    final res = await http.get(
      uri,
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }

    throw Exception(
      'Error al descargar PDF del plan: ${res.statusCode} ${res.body}',
    );
  }

  String getNom035ActionPlanPdfUrl(int planId) {
    return '$apiBase/nom035-audit/action-plans/$planId/pdf';
  }

  
  Future<Uint8List> downloadNom035ActionPlanAttachment(int attachmentId) async {
    final uri = Uri.parse(
      '$apiBase/nom035-audit/action-plan-attachments/$attachmentId/download',
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }

    throw Exception(
      'Error al descargar adjunto: ${res.statusCode} ${res.body}',
    );
  }


String getNom035ActionPlansCyclePdfUrl(int cycleId) {
    return '$apiBase/nom035-audit/action-plans/cycle/$cycleId/pdf';
  }


Future<Uint8List> downloadNom035ActionPlansCyclePdf(int cycleId) async {
    final uri = Uri.parse(
      '$apiBase/nom035-audit/action-plans/cycle/$cycleId/pdf',
    );

    final res = await http.get(
      uri,
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }

    throw Exception(
      'Error al descargar PDF del ciclo: ${res.statusCode} ${res.body}',
    );
  }

Future<Uint8List> downloadNom035EvidenceBytesFast(
  int evidenceId, {
  bool forceRefresh = false,
}) async {
  if (!forceRefresh && _evidenceFileBytesCache.containsKey(evidenceId)) {
    return _evidenceFileBytesCache[evidenceId]!;
  }

  if (!forceRefresh && _pendingEvidenceFileBytes.containsKey(evidenceId)) {
    return _pendingEvidenceFileBytes[evidenceId]!;
  }

  final future = () async {
    final uri = Uri.parse('$apiBase/nom035-evidences/$evidenceId/download');

    final res = await http.get(
      uri,
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Error al descargar evidencia: ${res.statusCode} ${res.body}',
      );
    }

    _evidenceFileBytesCache[evidenceId] = res.bodyBytes;
    _pendingEvidenceFileBytes.remove(evidenceId);
    return res.bodyBytes;
  }();

  _pendingEvidenceFileBytes[evidenceId] = future;
  return future;
}

Future<Map<String, dynamic>> downloadNom035EvidenceFile(
  int evidenceId, {
  bool forceRefresh = false,
}) async {
  final uri = Uri.parse('$apiBase/nom035-evidences/$evidenceId/download');

  final res = await http.get(
    uri,
    headers: await _headers(),
  ).timeout(const Duration(seconds: 30));

  if (res.statusCode >= 200 && res.statusCode < 300) {
    _evidenceFileBytesCache[evidenceId] = res.bodyBytes;

    String fileName = 'evidencia_$evidenceId';
    final contentType =
        res.headers['content-type'] ?? 'application/octet-stream';

    final disposition = res.headers['content-disposition'] ?? '';
    final match = RegExp("filename\\*?=(?:UTF-8'')?\"?([^\";]+)\"?")
        .firstMatch(disposition);

    if (match != null && match.groupCount >= 1) {
      fileName = Uri.decodeFull(match.group(1)!.trim());
    }

    return {
      'bytes': res.bodyBytes,
      'file_name': fileName,
      'content_type': contentType,
    };
  }

  throw Exception(
    'Error al descargar evidencia: ${res.statusCode} ${res.body}',
  );
}

//ANIVERSARIO WORK
Future<List<Map<String, dynamic>>> getWorkAnniversariesToday() async {
  final uri = Uri.parse('$apiBase/work_anniversaries/today');

  final res = await http.get(
    uri,
    headers: await _headers(),
  ).timeout(const Duration(seconds: 30));

  if (res.statusCode == 200) {
    final List data = jsonDecode(res.body);
    return data.map((e) => Map<String, dynamic>.from(e)).toList();
  } else {
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }
}

Future<List<Map<String, dynamic>>> getBirthdaysMonth() async {
  final headers = await _headers(json: false);

  final now = DateTime.now();
  final month = now.month.toString();

  final uri = Uri.parse('$apiBase/birthdays/month').replace(
    queryParameters: {
      'month': month,
    },
  );

  final res = await http.get(uri, headers: headers);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception(
      'Error obteniendo cumpleaños del mes: ${res.statusCode} ${res.body}',
    );
  }

  final data = jsonDecode(res.body);

  final list = (data is List)
      ? data
      : (data['items'] ?? data['data'] ?? data['rows'] ?? []);

  if (list is! List) {
    throw Exception('Respuesta inválida de cumpleaños del mes');
  }

  return list
      .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
      .toList();
}



   // ===================== NOTICES =====================

static Future<List<Map<String, dynamic>>> getActiveNotices() async {
  final res = await http.get(
    Uri.parse('$apiBase/notices'),
    headers: await _headers(),
  );

  if (res.statusCode != 200) {
    throw Exception('GET /notices => ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  final map = _asStringMap(decoded);
  return _asListOfStringMaps(map['items'] ?? decoded);
}


  static Future<Map<String, dynamic>?> getBadge() async {
  
    return null;
  }

static Future<void> createNotice({
  required String title,
  required String body,
  File? image,
}) async {
  final req = http.MultipartRequest(
    'POST',
    Uri.parse('$apiBase/notices'),
  );

  req.headers.addAll(await _headers());
  req.fields['title'] = title;
  req.fields['body'] = body;

  if (image != null) {
    req.files.add(await http.MultipartFile.fromPath('image', image.path));
  }

  final resp = await req.send();
  final respBody = await resp.stream.bytesToString();

  if (resp.statusCode != 200 && resp.statusCode != 201) {
    throw Exception('POST /notices => ${resp.statusCode} $respBody');
  }
}
static Future<Map<String, dynamic>?> getLatestNotice() async {
  final uri = Uri.parse('$apiBase/notices/latest');
  final res = await http.get(
    uri,
    headers: await _headers(),
  ).timeout(const Duration(seconds: 10));

  print('GET /notices/latest => ${res.statusCode} ${res.body}');

  if (res.statusCode == 404) return null;

  if (res.statusCode != 200) {
    throw Exception('GET /notices/latest => ${res.statusCode} ${res.body}');
  }

  final decoded = NoticesService._decodeBody(res.body);
  final map = NoticesService._asStringMap(decoded);

  final notice = map['notice'];
  if (notice == null) return null;

  return _asStringMap(notice);
}


// 🔹 ELIMINAR
static Future<void> deleteNotice(int id) async {
  final res = await http.delete(
    Uri.parse('$apiBase/notices/$id'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 15));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error al eliminar aviso: ${res.statusCode} ${res.body}');
  }
}



// 🔹 ACTUALIZAR
static Future<void> updateNotice({
  required int id,
  required String title,
  required String body,
  required bool active,
  required List<int> areaIds,
  String? plant,
}) async {
  final res = await http.put(
    Uri.parse('$apiBase/notices/$id'),
    headers: await _headers(json: true),
    body: jsonEncode({
      'title': title,
      'body': body,
      'active': active,
      'area_ids': areaIds,
      if (plant != null) 'plant': plant,
    }),
  ).timeout(const Duration(seconds: 15));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error al actualizar aviso: ${res.statusCode} ${res.body}');
  }
}



static Future<List<Map<String, dynamic>>> getNotices() async {
  final res = await http.get(
    Uri.parse('$apiBase/notices'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 15));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error al obtener avisos: ${res.statusCode} ${res.body}');
  }

  final decoded = _decodeBody(res.body);
  return _asListOfStringMaps(decoded);
}


static Future<void> markNoticeViewed(int id) async {
  final res = await http.post(
    Uri.parse('$apiBase/notices/$id/view'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 15));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error al marcar aviso visto: ${res.statusCode} ${res.body}');
  }
}



static Future<int> getUnreadNoticeCount() async {
  final res = await http.get(
    Uri.parse('$apiBase/notices/unread-count'),
    headers: await _headers(),
  );

  if (res.statusCode != 200) {
    throw Exception(
      'GET /notices/unread-count => ${res.statusCode} ${res.body}',
    );
  }

  final decoded = _asStringMap(_decodeBody(res.body));
  return (decoded['count'] as num?)?.toInt() ?? 0;
}

static Future<void> createNoticeAdvanced({
  required String title,
  required String body,
  String? plant,
  List<int> areaIds = const [],
  File? mainImage,
  List<File> images = const [],
  File? pdf,
}) async {
  final req = http.MultipartRequest(
    'POST',
    Uri.parse('$apiBase/notices'),
  );

  req.headers.addAll(await _headers());

  req.fields['title'] = title;
  req.fields['body'] = body;

  if (plant != null && plant.trim().isNotEmpty) {
    req.fields['plant'] = plant.trim();
  }

  if (areaIds.isNotEmpty) {
    req.fields['area_ids'] = jsonEncode(areaIds);
  }

  if (mainImage != null) {
    req.files.add(await http.MultipartFile.fromPath('image', mainImage.path));
  }

  for (final img in images) {
    req.files.add(await http.MultipartFile.fromPath('images', img.path));
  }

  if (pdf != null) {
    req.files.add(await http.MultipartFile.fromPath('pdf', pdf.path));
  }

  final resp = await req.send();
  final respBody = await resp.stream.bytesToString();

  if (resp.statusCode != 200 && resp.statusCode != 201) {
    throw Exception('POST /notices => ${resp.statusCode} $respBody');
  }
}

static Future<void> createNoticeAdvancedWeb({
  required String title,
  required String body,
  required List<int> areaIds,
  Uint8List? mainImageBytes,
  String? mainImageName,
  List<Map<String, dynamic>> images = const [],
  Uint8List? pdfBytes,
  String? pdfName,
  String? plant,
}) async {
  final req = http.MultipartRequest(
    'POST',
    Uri.parse('$apiBase/notices'),
  );

  req.headers.addAll(await _headers());

  req.fields['title'] = title;
  req.fields['body'] = body;
  req.fields['area_ids'] = jsonEncode(areaIds);
  if (plant != null && plant.trim().isNotEmpty) {
    req.fields['plant'] = plant.trim();
  }

  if (mainImageBytes != null && mainImageName != null) {
    req.files.add(
      http.MultipartFile.fromBytes(
        'image',
        mainImageBytes,
        filename: mainImageName,
      ),
    );
  }

  for (final img in images) {
    final bytes = img['bytes'] as Uint8List?;
    final name = img['name'] as String?;
    if (bytes != null && name != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'images',
          bytes,
          filename: name,
        ),
      );
    }
  }

  if (pdfBytes != null && pdfName != null) {
    req.files.add(
      http.MultipartFile.fromBytes(
        'pdf',
        pdfBytes,
        filename: pdfName,
      ),
    );
  }

  final response = await req.send().timeout(const Duration(seconds: 40));
  final bodyText = await response.stream.bytesToString();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Error al crear aviso web: ${response.statusCode} $bodyText');
  }
}



////updateNoticeAdvanced

static Future<void> updateNoticeAdvanced({
  required int id,
  String? title,
  String? body,
  bool? active,
  String? plant,
  List<int>? areaIds,
  bool replaceMainImage = false,
  bool removeMainImage = false,
  bool replacePdf = false,
  bool removePdf = false,
  List<String> removeExtraImages = const [],
  File? mainImage,
  List<File> images = const [],
  File? pdf,
  Uint8List? mainImageBytes,
  String? mainImageName,
  List<Map<String, dynamic>> imageWebFiles = const [],
  Uint8List? pdfBytes,
  String? pdfName,
}) async {
  final uri = Uri.parse('$apiBase/notices/$id');
  final req = http.MultipartRequest('PUT', uri);

  req.headers.addAll(await _headers());

  if (title != null) req.fields['title'] = title;
  if (body != null) req.fields['body'] = body;
  if (active != null) req.fields['active'] = active.toString();
  if (plant != null) req.fields['plant'] = plant;
  if (areaIds != null) req.fields['area_ids'] = jsonEncode(areaIds);

  req.fields['replace_main_image'] = replaceMainImage.toString();
  req.fields['remove_main_image'] = removeMainImage.toString();
  req.fields['replace_pdf'] = replacePdf.toString();
  req.fields['remove_pdf'] = removePdf.toString();

  if (removeExtraImages.isNotEmpty) {
    req.fields['remove_extra_images'] = jsonEncode(removeExtraImages);
  }

  if (kIsWeb) {
    if (mainImageBytes != null && mainImageName != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'image',
          mainImageBytes,
          filename: mainImageName,
        ),
      );
    }

    for (final img in imageWebFiles) {
      final bytes = img['bytes'] as Uint8List?;
      final name = img['name'] as String?;
      if (bytes != null && name != null) {
        req.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: name,
          ),
        );
      }
    }

    if (pdfBytes != null && pdfName != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'pdf',
          pdfBytes,
          filename: pdfName,
        ),
      );
    }
  } else {
    if (mainImage != null) {
      req.files.add(
        await http.MultipartFile.fromPath('image', mainImage.path),
      );
    }

    for (final img in images) {
      req.files.add(
        await http.MultipartFile.fromPath('images', img.path),
      );
    }

    if (pdf != null) {
      req.files.add(
        await http.MultipartFile.fromPath('pdf', pdf.path),
      );
    }
  }

  final response = await req.send().timeout(const Duration(seconds: 40));
  final bodyText = await response.stream.bytesToString();

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Error al actualizar aviso: ${response.statusCode} - $bodyText');
  }
}

// ===================== EVALUATIONS ADMIN Y EMPLEADO=====================

static Future<Map<String, dynamic>> createEvaluation(
  Map<String, dynamic> payload,
) async {
  final res = await http.post(
    Uri.parse('$apiBase/evaluations/admin'),
    headers: await _headers(json: true),
    body: jsonEncode(payload),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error creando evaluación: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}

static Future<List<Map<String, dynamic>>> getAdminEvaluations() async {
  final res = await http.get(
    Uri.parse('$apiBase/evaluations/admin'),
    headers: await _headers(),
  ).timeout(const Duration(seconds: 15));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error listando evaluaciones: ${res.statusCode} ${res.body}');
  }

  final data = _decodeBody(res.body);

  // 🔥 AJUSTE CLAVE
  return List<Map<String, dynamic>>.from(data['items'] ?? []);
}

static Future<void> deleteEvaluation(int evaluationId) async {
  final res = await http.delete(
    Uri.parse('$apiBase/evaluations/admin/$evaluationId'),
    headers: await _headers(),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error eliminando evaluación: ${res.statusCode} ${res.body}');
  }
}

static Future<void> toggleEvaluationActive(
  int evaluationId,
  bool isActive,
) async {
  final res = await http.put(
    Uri.parse('$apiBase/evaluations/admin/$evaluationId/status'),
    headers: await _headers(json: true),
    body: jsonEncode({'is_active': isActive ? 1 : 0}),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error cambiando estado: ${res.statusCode} ${res.body}');
  }
}


static Future<List<Map<String, dynamic>>> getAvailableEvaluations() async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/v1/evaluations/available'),
    headers: await _headers(),
  );

  if (res.statusCode != 200) {
    throw Exception('Error al cargar evaluaciones disponibles');
  }

  final data = jsonDecode(res.body);

  // 
  return List<Map<String, dynamic>>.from(data['evaluations'] ?? []);
}

static Future<List<Map<String, dynamic>>> getCompletedEvaluations() async {
  final res = await http.get(
    Uri.parse('$baseUrl/api/v1/evaluations/completed'),
    headers: await _headers(),
  );

  if (res.statusCode != 200) {
    throw Exception('Error al cargar evaluaciones completadas');
  }

  final data = jsonDecode(res.body);

  // 🔥 AQUÍ TAMBIÉN ESTABA MAL
  return List<Map<String, dynamic>>.from(data['items'] ?? []);
}
static Future<Map<String, dynamic>> startEvaluation(int evaluationId) async {
  final res = await http.post(
    Uri.parse('$apiBase/evaluations/$evaluationId/start'),
    headers: await _headers(json: true),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error iniciar evaluación: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}

static Future<Map<String, dynamic>> getEvaluationResult(int submissionId) async {
  final res = await http.get(
    Uri.parse('$apiBase/evaluations/submissions/$submissionId/result'),
    headers: await _headers(),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error resultado evaluación: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}

static Future<Map<String, dynamic>> adminGetEvaluationSubmissions(
  int evaluationId,
) async {
  final res = await http.get(
    Uri.parse('$apiBase/evaluations/admin/$evaluationId/submissions'),
    headers: await _headers(),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error submissions evaluación: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}

static Future<Map<String, dynamic>> adminGetEvaluationSubmissionDetail(
  int submissionId,
) async {
  final res = await http.get(
    Uri.parse('$apiBase/evaluations/admin/submissions/$submissionId'),
    headers: await _headers(),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error detalle respuestas: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}

static Future<Map<String, dynamic>> getEvaluationDetail(
  int evaluationId,
) async {
  final res = await http.get(
    Uri.parse('$apiBase/evaluations/$evaluationId/detail'),
    headers: await _headers(),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error cargando evaluación');
  }

  return _asStringMap(_decodeBody(res.body));
}

static Future<void> submitEvaluationAnswers(
  int submissionId,
  Map<int, dynamic> answers,
) async {
  final res = await http.post(
    Uri.parse('$apiBase/evaluations/submissions/$submissionId/answers'),
    headers: await _headers(json: true),
    body: jsonEncode({'answers': answers}),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error enviando respuestas');
  }
}

static Future<Map<String, dynamic>> getAdminEvaluationDetail(
  int evaluationId,
) async {
  final res = await http.get(
    Uri.parse('$apiBase/evaluations/admin/$evaluationId'),
    headers: await _headers(),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error detalle evaluación: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}


static Future<Map<String, dynamic>> updateEvaluation(
  int evaluationId,
  Map<String, dynamic> payload,
) async {
  final res = await http.put(
    Uri.parse('$apiBase/evaluations/admin/$evaluationId'),
    headers: await _headers(json: true),
    body: jsonEncode(payload),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('Error actualizando evaluación: ${res.statusCode} ${res.body}');
  }

  return _asStringMap(_decodeBody(res.body));
}


}
