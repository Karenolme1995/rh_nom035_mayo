import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/notices_service.dart';
import '../utils/export_csv.dart';

class Nom035AdminSubmissionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int submissionId;

  const Nom035AdminSubmissionDetailScreen({
    super.key,
    required this.userData,
    required this.submissionId,
  });

  @override
  State<Nom035AdminSubmissionDetailScreen> createState() =>
      _Nom035AdminSubmissionDetailScreenState();
}

class _Nom035AdminSubmissionDetailScreenState
    extends State<Nom035AdminSubmissionDetailScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? detail;

  late final Map<String, dynamic> form;
  late List<Map<String, dynamic>> sections;

  final Map<String, Map<String, dynamic>> _guideSectionMap = {};
  List<String> _answeredGuidesCache = const [];
  GuideRiskResult? _guideIIResultCache;
  GuideRiskResult? _guideIIIResultCache;

  Map<int, String> _areasMap = {};
  Map<int, String> _positionsMap = {};

  int page = 0;

  @override
  void initState() {
    super.initState();
    form = {};
    sections = [];
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await Future.wait([
        NoticesService.adminNom035GetSubmissionDetail(
          submissionId: widget.submissionId,
        ),
        _loadCatalogsSafe(),
      ]);

      final data = results[0] as Map<String, dynamic>;

      final rawSections =
          _asList(data['sections']).map((e) => _asMap(e)).toList();

      final builtPages = _buildPages(rawSections);
      final guideSectionMap = _buildGuideSectionMap(builtPages);
      final answeredGuides = _computeAnsweredGuideCodes(builtPages);

      final guideIIResult = _guideResultFromSectionMap(guideSectionMap, 'II');
      final guideIIIResult = _guideResultFromSectionMap(guideSectionMap, 'III');

      setState(() {
        detail = data;
        sections = builtPages;

        _guideSectionMap
          ..clear()
          ..addAll(guideSectionMap);

        _answeredGuidesCache = answeredGuides;
        _guideIIResultCache = guideIIResult;
        _guideIIIResultCache = guideIIIResult;

        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadCatalogsSafe() async {
    try {
      final areasMap = await NoticesService().getAreasMap();
      final positionsMap = await NoticesService().getPositionsMap();

      _areasMap = Map<int, String>.from(areasMap);
      _positionsMap = Map<int, String>.from(positionsMap);
    } catch (_) {
      _areasMap = {};
      _positionsMap = {};
    }
  }

  String _asString(dynamic v) => (v ?? '').toString();

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List _asList(dynamic v) {
    if (v is List) return v;
    return <dynamic>[];
  }

  String _formatDateTime(dynamic raw) {
    final s = _asString(raw).trim();
    if (s.isEmpty) return '';

    try {
      final dt = DateTime.parse(s.replaceFirst(' ', 'T'));
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return s;
    }
  }

  String _sanitizeFilePart(String input) {
    var s = input.trim().toLowerCase();
    s = s
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^_|_$'), '');
    return s.isEmpty ? 'usuario' : s;
  }

  String _buildFilename(String fmt) {
    final d = detail ?? {};
    final user = _asMap(d['user']);
    final cycle = _asMap(d['cycle']);

    final safeName = _sanitizeFilePart(_asString(user['name']));
    final safeCycle = _sanitizeFilePart(_asString(cycle['title']));

    if (safeCycle.isNotEmpty) {
      return '${safeName}_$safeCycle.$fmt';
    }
    return '${safeName}_nom035.$fmt';
  }

  String _normalizeGuideValue(dynamic raw) {
    final s = _asString(raw).trim().toUpperCase();
    if (s.isEmpty) return 'GENERAL';

    var x = s.replaceAll('GUÍA', '').replaceAll('GUIA', '').trim();
    x = x.replaceAll('-', '').replaceAll('_', '').trim();

    const numMap = {
      '1': 'I',
      '2': 'II',
      '3': 'III',
      '4': 'IV',
      '5': 'V',
    };

    if (numMap.containsKey(x)) return numMap[x]!;
    if (const ['I', 'II', 'III', 'IV', 'V'].contains(x)) return x;

    return s;
  }

  int _guideSortOrder(String guide) {
    switch (guide.toUpperCase()) {
      case 'I':
        return 1;
      case 'II':
        return 2;
      case 'III':
        return 3;
      case 'IV':
        return 4;
      case 'V':
        return 5;
      default:
        return 99;
    }
  }

  String _resolveArea(dynamic raw) {
    if (raw == null) return '—';

    if (raw is Map) {
      final m = _asMap(raw);
      final name = _asString(m['name']).trim().isNotEmpty
          ? _asString(m['name']).trim()
          : _asString(m['area_name']).trim();
      if (name.isNotEmpty) return name;

      final id = _asInt(m['id'] ?? m['area_id']);
      if (id > 0 && _areasMap.containsKey(id)) return _areasMap[id]!;
      return '—';
    }

    final rawText = _asString(raw).trim();
    if (rawText.isEmpty) return '—';

    final id = int.tryParse(rawText);
    if (id != null) return _areasMap[id] ?? '—';

    return rawText;
  }

  String _resolvePosition(dynamic raw) {
    if (raw == null) return '—';

    if (raw is Map) {
      final m = _asMap(raw);
      final name = _asString(m['name']).trim().isNotEmpty
          ? _asString(m['name']).trim()
          : _asString(m['position_name'] ?? m['job_title']).trim();
      if (name.isNotEmpty) return name;

      final id = _asInt(m['id'] ?? m['position_id'] ?? m['job_position_id']);
      if (id > 0 && _positionsMap.containsKey(id)) return _positionsMap[id]!;
      return '—';
    }

    final rawText = _asString(raw).trim();
    if (rawText.isEmpty) return '—';

    final id = int.tryParse(rawText);
    if (id != null) return _positionsMap[id] ?? '—';

    return rawText;
  }

  List<Map<String, dynamic>> _flattenSections(List<Map<String, dynamic>> raw) {
    final out = <Map<String, dynamic>>[];

    for (final s in raw) {
      final title = _asString(s['title']);
      final desc = _asString(s['description']);
      final ins = _asString(s['instructions']);

      final hasGroups = s.containsKey('groups') && s['groups'] is List;
      final hasQuestions = s.containsKey('questions') && s['questions'] is List;

      if (hasGroups) {
        if (ins.trim().isNotEmpty ||
            desc.trim().isNotEmpty ||
            title.trim().isNotEmpty) {
          out.add({
            'title': title,
            'description': desc,
            'instructions': ins,
            'questions': const <dynamic>[],
            '_kind': 'doc',
          });
        }

        for (final gAny in _asList(s['groups'])) {
          final g = _asMap(gAny);
          out.add({
            'title': _asString(g['title']),
            'description': '',
            'instructions': _asString(g['instructions']),
            'questions': _asList(g['questions']),
            '_kind': 'questions',
          });
        }
        continue;
      }

      if (hasQuestions) {
        final qs = _asList(s['questions']);
        out.add({
          'title': title,
          'description': desc,
          'instructions': ins,
          'questions': qs,
          '_kind': (qs.isEmpty && ins.trim().isNotEmpty) ? 'doc' : 'questions',
        });
        continue;
      }

      out.add({
        'title': title.isEmpty ? 'Guía' : title,
        'description': desc,
        'instructions': ins,
        'questions': const <dynamic>[],
        '_kind': (ins.trim().isNotEmpty || desc.trim().isNotEmpty)
            ? 'doc'
            : 'questions',
      });
    }

    if (out.isEmpty) {
      out.add(const {
        'title': 'Sin guías',
        'description': 'El backend no envió secciones.',
        'instructions': '',
        'questions': <dynamic>[],
        '_kind': 'doc',
      });
    }

    return out;
  }

List<Map<String, dynamic>> _groupGuidePages(List<Map<String, dynamic>> raw) {
  final flat = _flattenSections(raw);

  const guideOrder = ['I', 'II', 'III', 'IV', 'V'];

  final Map<String, List<Map<String, dynamic>>> guideQuestions = {
    for (final g in guideOrder) g: <Map<String, dynamic>>[],
  };

  final Map<String, String> guideInstructions = {
    for (final g in guideOrder) g: '',
  };

  for (final sec in flat) {
    final questions = _asList(sec['questions']);
    final sectionInstructions = _asString(sec['instructions']).trim();

    for (final qAny in questions) {
      final q = _asMap(qAny);
      final meta = _asMap(q['meta']);

      final guide = _normalizeGuideValue(
        q['guide'] ?? meta['guide'] ?? sec['guide_code'],
      );

      if (!guideQuestions.containsKey(guide)) continue;

      guideQuestions[guide]!.add(q);

      if (guideInstructions[guide]!.isEmpty && sectionInstructions.isNotEmpty) {
        guideInstructions[guide] = sectionInstructions;
      }
    }
  }

  final pages = <Map<String, dynamic>>[];

  for (final g in guideOrder) {
    pages.add({
      'title': 'GUÍA DE REFERENCIA $g',
      'guide_code': g,
      'description': '',
      'instructions': guideInstructions[g] ?? '',
      'questions': guideQuestions[g] ?? <dynamic>[],
      '_kind': 'questions',
    });
  }

  return pages;
}

  List<Map<String, dynamic>> _buildPages(List<Map<String, dynamic>> rawSections) {
    final guidePages = _groupGuidePages(rawSections);

    final pages = <Map<String, dynamic>>[
      const {
        'title': 'Resumen general',
        'description': 'Datos del empleado y evaluación NOM-035',
        'instructions': '',
        'questions': <dynamic>[],
        '_kind': 'summary',
      }
    ];

    pages.addAll(guidePages);
    return pages;
  }

  Map<String, Map<String, dynamic>> _buildGuideSectionMap(
    List<Map<String, dynamic>> pages,
  ) {
    final out = <String, Map<String, dynamic>>{};
    for (final sec in pages) {
      final guideCode = _asString(sec['guide_code']).trim().toUpperCase();
      if (guideCode.isNotEmpty) {
        out[guideCode] = sec;
      }
    }
    return out;
  }

  List<dynamic> _parseOptions(dynamic rawOpts) {
    if (rawOpts == null) return const <dynamic>[];
    if (rawOpts is List) return rawOpts;

    if (rawOpts is Map) {
      return rawOpts.entries
          .map((e) => {'value': e.key, 'label': e.value})
          .toList(growable: false);
    }

    if (rawOpts is String) {
      final s = rawOpts.trim();
      if (s.isEmpty) return const <dynamic>[];
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return decoded.entries
              .map((e) => {'value': e.key, 'label': e.value})
              .toList(growable: false);
        }
      } catch (_) {}
    }

    return const <dynamic>[];
  }

  String _normalizedQuestionType(Map<String, dynamic> q) {
    final rt = _asString(q['response_type']).trim().toLowerCase();
    final qt = _asString(q['question_type']).trim().toLowerCase();
    final t = rt.isNotEmpty ? rt : qt;

    if (t == 'open') return 'text';
    if (t == 'yes_no') return 'single';
    if (t == 'likert') return 'single';
    if (t == 'multiple') return 'multi';
    if (t == 'single' || t == 'multi' || t == 'text') return t;

    return 'single';
  }

  bool _isDocPage(Map<String, dynamic> sec) {
    final kind = _asString(sec['_kind']);
    if (kind == 'doc') return true;
    final questions = _asList(sec['questions']);
    final ins = _asString(sec['instructions']);
    final desc = _asString(sec['description']);
    return questions.isEmpty &&
        (ins.trim().isNotEmpty || desc.trim().isNotEmpty);
  }

  bool _isSummaryPage(Map<String, dynamic> sec) {
    return _asString(sec['_kind']) == 'summary';
  }

  bool _isGuideVAutoLockedQuestion(int qid) {
    return qid == 188 || qid == 189 || qid == 194 || qid == 195;
  }

  List<String> _computeAnsweredGuideCodes(List<Map<String, dynamic>> sourceSections) {
    final codes = <String>{};

    for (final sec in sourceSections) {
      final guideCode = _asString(sec['guide_code']);
      final questions = _asList(sec['questions']);

      bool hasAnswer = false;
      for (final qAny in questions) {
        final q = _asMap(qAny);
        final answer = q['answer_value'];
        if (answer == null) continue;

        final s = _asString(answer).trim();
        if (s.isNotEmpty && s != '[]') {
          hasAnswer = true;
          break;
        }
      }

      if (hasAnswer && guideCode.isNotEmpty && guideCode != 'GENERAL') {
        codes.add(guideCode);
      }
    }

    final list = codes.toList()
      ..sort((a, b) => _guideSortOrder(a).compareTo(_guideSortOrder(b)));
    return list;
  }

  List<String> _answeredGuideCodes() => _answeredGuidesCache;

  String _answeredGuidesText() {
    final guides = _answeredGuideCodes();
    if (guides.isEmpty) return 'Este usuario no tiene respuestas registradas.';
    if (guides.length == 1) {
      return 'Este usuario contestó la guía: ${guides.first}.';
    }
    return 'Este usuario contestó las guías: ${guides.join(', ')}.';
  }

  String _nom035Guide23Text() {
    return 'Guías II y III:\n'
        '• Cada respuesta Likert se convierte en valor numérico.\n'
        '• Nunca=0, Casi nunca=1, Algunas veces=2, Casi siempre=3, Siempre=4.\n'
        '• Si una pregunta tiene reverse_scoring=1, el valor se invierte con la fórmula: 4 - valor original.\n'
        '• Después se suman todas las preguntas de la guía.\n'
        '• Con la suma total se determina el nivel de riesgo y su color.\n'
        '• Para reportes masivos, este cálculo debe hacerse en backend y guardarse por submission.';
  }

  Color _riskColor(String risk) {
    switch (risk.trim().toLowerCase()) {
      case 'muy alto':
        return Colors.red;
      case 'alto':
        return Colors.orange;
      case 'medio':
        return Colors.yellow.shade700;
      case 'bajo':
        return const Color(0xFF39FF14);
      case 'nulo':
        return Colors.lightBlue;
      case 'sin contestar':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _riskRecommendation(String risk) {
    switch (risk.trim().toLowerCase()) {
      case 'muy alto':
        return 'Se requiere realizar el análisis de cada categoría y dominio para establecer las acciones de intervención apropiadas, mediante un Programa de intervención que deberá incluir evaluaciones específicas y contemplar campañas de sensibilización, revisar la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral, así como reforzar su aplicación y difusión.';
      case 'alto':
        return 'Se requiere realizar un análisis de cada categoría y dominio, de manera que se puedan determinar las acciones de intervención apropiadas a través de un Programa de intervención, que podrá incluir una evaluación específica y deberá incluir una campaña de sensibilización, revisar la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral, así como reforzar su aplicación y difusión.';
      case 'medio':
        return 'Se requiere revisar la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral, así como reforzar su aplicación y difusión, mediante un Programa de intervención.';
      case 'bajo':
        return 'Es necesaria una mayor difusión de la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral.';
      case 'nulo':
        return 'El riesgo resulta despreciable por lo que no se requieren medidas adicionales.';
      case 'sin contestar':
        return 'Esta guía no fue contestada por el usuario.';
      default:
        return 'Sin recomendación específica disponible.';
    }
  }

  int _parseLikertValue(dynamic answerValue) {
    if (answerValue == null) return 0;

    if (answerValue is int) {
      if (answerValue < 0) return 0;
      if (answerValue > 4) return 4;
      return answerValue;
    }

    if (answerValue is num) {
      final n = answerValue.toInt();
      if (n < 0) return 0;
      if (n > 4) return 4;
      return n;
    }

    final s = answerValue.toString().trim().toLowerCase();

    switch (s) {
      case 'nunca':
      case '0':
        return 0;
      case 'casi nunca':
      case '1':
        return 1;
      case 'a veces':
      case 'algunas veces':
      case '2':
        return 2;
      case 'casi siempre':
      case '3':
        return 3;
      case 'siempre':
      case '4':
        return 4;
      default:
        final parsed = int.tryParse(s);
        if (parsed == null) return 0;
        if (parsed < 0) return 0;
        if (parsed > 4) return 4;
        return parsed;
    }
  }

  bool _questionReverseScoring(Map<String, dynamic> q) {
    final meta = _asMap(q['meta']);

    final direct = q['reverse_scoring'];
    final metaValue = meta['reverse_scoring'];

    bool parseBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      if (v is int) return v == 1;
      final s = v.toString().trim().toLowerCase();
      return s == '1' || s == 'true';
    }

    return parseBool(direct) || parseBool(metaValue);
  }

  int _questionScore(Map<String, dynamic> q) {
    final baseValue = _parseLikertValue(q['answer_value']);
    final reverse = _questionReverseScoring(q);
    return reverse ? (4 - baseValue) : baseValue;
  }

  int _guideScore(List<dynamic> questions) {
    int total = 0;

    for (final item in questions) {
      final q = _asMap(item);

      final responseType = _asString(
        q['response_type'] ?? _asMap(q['meta'])['response_type'],
      ).toLowerCase();

      if (responseType == 'likert') {
        total += _questionScore(q);
      }
    }

    return total;
  }

  bool _hasAnsweredLikertQuestions(List<dynamic> questions) {
    for (final item in questions) {
      final q = _asMap(item);

      final responseType = _asString(
        q['response_type'] ?? _asMap(q['meta'])['response_type'],
      ).toLowerCase();

      if (responseType != 'likert') continue;

      final raw = q['answer_value'];
      final s = _asString(raw).trim();

      if (s.isNotEmpty && s != '[]') {
        return true;
      }
    }
    return false;
  }

  GuideRiskResult? _guideResultFromSectionMap(
    Map<String, Map<String, dynamic>> sectionMap,
    String guideCode,
  ) {
    final section = sectionMap[guideCode.toUpperCase()];
    if (section == null) return null;

    final questions = _asList(section['questions']);
    if (questions.isEmpty) return null;

    final hasAnswers = _hasAnsweredLikertQuestions(questions);
    if (!hasAnswers) {
      return GuideRiskResult(
        guideCode: guideCode.toUpperCase(),
        score: 0,
        level: 'Sin contestar',
        color: Colors.red,
        legend: 'Esta guía no fue contestada por el usuario.',
      );
    }

    final score = _guideScore(questions);
    return _evaluateGuideRisk(guideCode, score);
  }

  GuideRiskResult _evaluateGuideRisk(String guideCode, int score) {
    final g = guideCode.toUpperCase();

    if (g == 'II') {
      if (score >= 0 && score <= 19) {
        return GuideRiskResult(
          guideCode: 'II',
          score: score,
          level: 'Nulo',
          color: Colors.lightBlue,
          legend:
              'El riesgo resulta despreciable por lo que no se requieren medidas adicionales.',
        );
      }
      if (score >= 20 && score <= 44) {
        return GuideRiskResult(
          guideCode: 'II',
          score: score,
          level: 'Bajo',
          color: const Color(0xFF39FF14),
          legend:
              'Es necesaria una mayor difusión de la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral.',
        );
      }
      if (score >= 45 && score <= 69) {
        return GuideRiskResult(
          guideCode: 'II',
          score: score,
          level: 'Medio',
          color: Colors.yellow.shade700,
          legend:
              'Se requiere revisar la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral, así como reforzar su aplicación y difusión, mediante un Programa de intervención.',
        );
      }
      if (score >= 70 && score <= 89) {
        return GuideRiskResult(
          guideCode: 'II',
          score: score,
          level: 'Alto',
          color: Colors.orange,
          legend:
              'Se requiere realizar un análisis de cada categoría y dominio, de manera que se puedan determinar las acciones de intervención apropiadas a través de un Programa de intervención, que podrá incluir una evaluación específica y deberá incluir una campaña de sensibilización, revisar la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral, así como reforzar su aplicación y difusión.',
        );
      }
      return GuideRiskResult(
        guideCode: 'II',
        score: score,
        level: 'Muy alto',
        color: Colors.red,
        legend:
            'Se requiere realizar el análisis de cada categoría y dominio para establecer las acciones de intervención apropiadas, mediante un Programa de intervención que deberá incluir evaluaciones específicas y contemplar campañas de sensibilización, revisar la política de prevención de riesgos psicosociales y programas para la prevención de los factores de riesgo psicosocial, la promoción de un entorno organizacional favorable y la prevención de la violencia laboral, así como reforzar su aplicación y difusión.',
      );
    }

    if (g == 'III') {
      if (score >= 0 && score <= 49) {
        return GuideRiskResult(
          guideCode: 'III',
          score: score,
          level: 'Nulo',
          color: Colors.lightBlue,
          legend:
              'Riesgo bajo o despreciable en la Guía III. Puedes ajustar estos rangos si manejas otros criterios internos.',
        );
      }
      if (score >= 50 && score <= 74) {
        return GuideRiskResult(
          guideCode: 'III',
          score: score,
          level: 'Bajo',
          color: const Color(0xFF39FF14),
          legend:
              'Riesgo bajo en la Guía III. Puedes ajustar estos rangos si manejas otros criterios internos.',
        );
      }
      if (score >= 75 && score <= 98) {
        return GuideRiskResult(
          guideCode: 'III',
          score: score,
          level: 'Medio',
          color: Colors.yellow.shade700,
          legend:
              'Riesgo medio en la Guía III. Puedes ajustar estos rangos si manejas otros criterios internos.',
        );
      }
      if (score >= 99 && score <= 139) {
        return GuideRiskResult(
          guideCode: 'III',
          score: score,
          level: 'Alto',
          color: Colors.orange,
          legend:
              'Riesgo alto en la Guía III. Puedes ajustar estos rangos si manejas otros criterios internos.',
        );
      }
      return GuideRiskResult(
        guideCode: 'III',
        score: score,
        level: 'Muy alto',
        color: Colors.red,
        legend:
            'Riesgo muy alto en la Guía III. Puedes ajustar estos rangos si manejas otros criterios internos.',
      );
    }

    return GuideRiskResult(
      guideCode: g,
      score: score,
      level: 'Sin clasificación',
      color: Colors.grey,
      legend: 'Esta guía no tiene reglas configuradas.',
    );
  }

  void _next() {
    if (page < sections.length - 1) {
      setState(() => page++);
    }
  }

  void _back() {
    if (page > 0) {
      setState(() => page--);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'submitted':
        return 'Concluido';
      case 'in_progress':
        return 'En curso';
      case 'available':
        return 'Disponible';
      case 'reviewed':
        return 'Revisado';
      default:
        return status.isEmpty ? 'Sin estatus' : status;
    }
  }

  Future<void> _showExportMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Exportar PDF'),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
              ListTile(
                leading: const Icon(Icons.grid_on),
                title: const Text('Exportar Excel'),
                onTap: () => Navigator.pop(context, 'xlsx'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Exportar Word'),
                onTap: () => Navigator.pop(context, 'docx'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected.isNotEmpty) {
      await _export(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = detail;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle #${widget.submissionId}'),
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _error()
              : d == null
                  ? const Center(child: Text('Sin datos'))
                  : _content(d),
    );
  }

  Widget _error() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error:\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _riskBox(GuideRiskResult result) {
    final isWithoutAnswers = result.level.trim().toLowerCase() == 'sin contestar';
    final boxColor = isWithoutAnswers ? Colors.red : result.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: boxColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: boxColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: boxColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Guía ${result.guideCode} • Nivel: ${result.level}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: boxColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Calificación total: ${result.score}',
            style: TextStyle(
              color: isWithoutAnswers ? Colors.red.shade700 : null,
              fontWeight: isWithoutAnswers ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.legend,
            style: TextStyle(
              color: isWithoutAnswers ? Colors.red.shade700 : null,
              fontWeight: isWithoutAnswers ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPage(Map<String, dynamic> d) {
    final user = _asMap(d['user']);
    final cycle = _asMap(d['cycle']);
    final sub = _asMap(d['submission']);

    final title = _asString(cycle['title']).isNotEmpty
        ? _asString(cycle['title'])
        : 'NOM-035';
    final name = _asString(user['name']);
    final emp = _asString(user['employee_number']);

    final area = _resolveArea(
      user['area'] ?? user['area_id'] ?? user['area_name'],
    );

    final position = _resolvePosition(
      user['position'] ??
          user['position_id'] ??
          user['position_name'] ??
          user['job_title'] ??
          user['job_position_id'],
    );

    final statusRaw = _asString(sub['status']);
    final status = _statusLabel(statusRaw);
    final risk = _asString(sub['risk_level']);
    final score = sub['score_total'] ?? sub['score'];
    final startedAt = _formatDateTime(sub['started_at']);
    final submittedAt = _formatDateTime(sub['submitted_at']);
    final reviewedAt = _formatDateTime(sub['reviewed_at']);

    final answeredGuides = _answeredGuidesCache;
    final riskColor = _riskColor(risk);
    final riskText = _riskRecommendation(risk);

    final guideIIResult = _guideIIResultCache;
    final guideIIIResult = _guideIIIResultCache;

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Resumen general',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Exportar',
                        onPressed: _showExportMenu,
                        icon: const Icon(Icons.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Datos del empleado',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _infoRow('Cuestionario', title),
                              _infoRow(
                                'Empleado',
                                name.isEmpty
                                    ? '-'
                                    : '$name${emp.isEmpty ? '' : ' (# $emp)'}',
                              ),
                              _infoRow('Área', area),
                              _infoRow('Puesto', position),
                              _infoRow(
                                'Guías',
                                answeredGuides.isEmpty
                                    ? 'Sin respuestas'
                                    : answeredGuides.join(', '),
                              ),
                              _infoRow(
                                'Total guías',
                                answeredGuides.length.toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Evaluación',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _infoRow('Estado', status.isEmpty ? '-' : status),
                              _infoRow(
                                'Calificación',
                                score == null ? '-' : score.toString(),
                              ),
                              _infoRow(
                                'Nivel riesgo',
                                risk.isEmpty ? '-' : risk,
                              ),
                              if (startedAt.isNotEmpty)
                                _infoRow('Iniciado', startedAt),
                              if (submittedAt.isNotEmpty)
                                _infoRow('Enviado', submittedAt),
                              if (reviewedAt.isNotEmpty)
                                _infoRow('Revisado', reviewedAt),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      _answeredGuidesText(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explicación de evaluación Guía II y III',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(_nom035Guide23Text()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (risk.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: riskColor.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: riskColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Nivel de riesgo general: $risk',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: riskColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(riskText),
                        ],
                      ),
                    ),
                  if (guideIIResult != null) ...[
                    const SizedBox(height: 10),
                    _riskBox(guideIIResult),
                  ],
                  if (guideIIIResult != null) ...[
                    const SizedBox(height: 10),
                    _riskBox(guideIIIResult),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(Map<String, dynamic> d) {
    final current = sections[page];
    final guideTitle = _asString(current['title']);
    final guideDesc = _asString(current['description']);
    final guideIns = _asString(current['instructions']);
    final questions = _asList(current['questions']);
    final totalPages = sections.length;
    final isLast = page == totalPages - 1;
    final isDoc = _isDocPage(current);
    final isSummary = _isSummaryPage(current);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Página ${page + 1} de $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  value: totalPages == 0 ? 0 : (page + 1) / totalPages,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isSummary
                ? _summaryPage(d)
                : Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                guideTitle.isEmpty ? 'Guía' : guideTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (guideDesc.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  guideDesc,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.deepPurple.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                              if (guideIns.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  guideIns,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              if (!isDoc) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Preguntas en esta guía: ${questions.length}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: isDoc
                            ? SingleChildScrollView(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Text(
                                      guideIns.trim().isNotEmpty
                                          ? guideIns
                                          : (guideDesc.trim().isNotEmpty
                                              ? guideDesc
                                              : 'Documento sin contenido.'),
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                key: PageStorageKey('guide_page_$page'),
                                itemCount: questions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 0),
                                itemBuilder: (context, idx) {
                                  final q = _asMap(questions[idx]);
                                  return _ReadonlyQuestionCard(
                                    key: ValueKey(
                                      'q_${_asInt(q['id'], fallback: idx)}_$page',
                                    ),
                                    question: q,
                                    numberInGuide: idx + 1,
                                    optionsParser: _parseOptions,
                                    autoLocked: _isGuideVAutoLockedQuestion(
                                      _asInt(q['id'], fallback: -1),
                                    ),
                                    normalizedType: _normalizedQuestionType(q),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: page == 0 ? null : _back,
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLast ? () => Navigator.pop(context) : _next,
                  child: Text(isLast ? 'Cerrar' : 'Siguiente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _export(String fmt) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generando export $fmt...')),
      );

      final bytes = await NoticesService.adminNom035ExportSubmission(
        submissionId: widget.submissionId,
        format: fmt,
      );

      final filename = _buildFilename(fmt);

      final mimeType = (fmt == 'pdf')
          ? 'application/pdf'
          : (fmt == 'xlsx')
              ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
              : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      await exportCsv(
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo listo: $filename')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error export: $e')),
      );
    }
  }
}

class GuideRiskResult {
  final String guideCode;
  final int score;
  final String level;
  final Color color;
  final String legend;

  GuideRiskResult({
    required this.guideCode,
    required this.score,
    required this.level,
    required this.color,
    required this.legend,
  });
}

class _ReadonlyQuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int numberInGuide;
  final List<dynamic> Function(dynamic raw) optionsParser;
  final bool autoLocked;
  final String normalizedType;

  const _ReadonlyQuestionCard({
    super.key,
    required this.question,
    required this.numberInGuide,
    required this.optionsParser,
    required this.autoLocked,
    required this.normalizedType,
  });

  String _asString(dynamic v) => (v ?? '').toString();

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  String? _normalizeSingleAnswer(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;

    if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
      return s.substring(1, s.length - 1).trim();
    }

    return s;
  }

  List<String> _normalizeMultiAnswerValues(dynamic v) {
    if (v == null) return const <String>[];

    if (v is List) {
      return v
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }

    final s = v.toString().trim();
    if (s.isEmpty) return const <String>[];

    if (s.startsWith('[') && s.endsWith(']')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        }
      } catch (_) {}
    }

    return [s];
  }

  dynamic _optValue(dynamic optionAny, int index) {
    if (optionAny is Map) {
      final m = Map<String, dynamic>.from(optionAny);
      return m['value'] ?? m['id'] ?? (index + 1);
    }

    final label = _asString(optionAny).trim().toLowerCase();
    if (label == 'sí' || label == 'si') return 1;
    if (label == 'no') return 2;

    return index + 1;
  }

  String _optLabel(dynamic optionAny) {
    if (optionAny is Map) {
      final m = Map<String, dynamic>.from(optionAny);
      return _asString(
        m['label'] ?? m['option_text'] ?? m['text'] ?? m['value'],
      );
    }
    return _asString(optionAny);
  }

  List<dynamic> _optionsFromQuestion() {
    final raw = question['options'] ?? question['options_json'];
    final opts = optionsParser(raw);

    final rt = _asString(question['response_type']).trim().toLowerCase();
    if (rt == 'yes_no' && opts.isEmpty) {
      return const [
        {'label': 'Sí', 'value': 1},
        {'label': 'No', 'value': 2},
      ];
    }

    return opts;
  }

  bool _matchesSingleAnswer(String? answer, dynamic optionAny, int index) {
    if (answer == null || answer.isEmpty) return false;

    final optionValue = _optValue(optionAny, index).toString().trim();
    final optionLabel = _optLabel(optionAny).trim().toLowerCase();
    final normalizedAnswer = answer.trim().toLowerCase();

    return normalizedAnswer == optionValue.toLowerCase() ||
        normalizedAnswer == optionLabel;
  }

  bool _matchesMultiAnswer(List<String> answers, dynamic optionAny, int index) {
    final optionValue =
        _optValue(optionAny, index).toString().trim().toLowerCase();
    final optionLabel = _optLabel(optionAny).trim().toLowerCase();

    for (final a in answers) {
      final aa = a.trim().toLowerCase();
      if (aa == optionValue || aa == optionLabel) {
        return true;
      }
    }
    return false;
  }

  Color _domainColor(String domain) {
    final d = domain.trim().toLowerCase();

    if (d.contains('liderazgo')) return Colors.indigo;
    if (d.contains('carga')) return Colors.deepOrange;
    if (d.contains('control')) return Colors.teal;
    if (d.contains('jornada')) return Colors.purple;
    if (d.contains('violencia')) return Colors.red;
    if (d.contains('relaciones')) return Colors.blue;
    if (d.contains('entorno')) return Colors.green;
    return Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
    final text = _asString(question['question_text']);
    final meta = _asMap(question['meta']);
    final helpText = _asString(
      question['help_text'] ??
          question['instruction_text'] ??
          meta['help_text'] ??
          meta['instruction_text'],
    );

    final domain = _asString(
      question['domain'] ??
          meta['domain'] ??
          meta['domain_name'] ??
          meta['dominio'],
    ).trim();

    final category = _asString(
      question['category'] ??
          meta['category'] ??
          meta['category_name'] ??
          meta['categoria'],
    ).trim();

    final rawAnswer = question['answer_value'];
    final answerValue = _normalizeSingleAnswer(rawAnswer);
    final multiAnswerValues = _normalizeMultiAnswerValues(rawAnswer);
    final options = _optionsFromQuestion();

    final bool hasNoAnswer = _asString(rawAnswer).trim().isEmpty ||
        _asString(rawAnswer).trim() == '[]';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (domain.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _domainColor(domain).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _domainColor(domain).withOpacity(0.35),
                  ),
                ),
                child: Text(
                  'Dominio: $domain',
                  style: TextStyle(
                    color: _domainColor(domain),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            if (category.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blueGrey.shade200,
                  ),
                ),
                child: Text(
                  'Categoría: $category',
                  style: TextStyle(
                    color: Colors.blueGrey.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            Text(
              '$numberInGuide. $text',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            if (autoLocked) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Valor autollenado',
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (helpText.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                helpText,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (normalizedType == 'text')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasNoAnswer ? Colors.red.shade300 : Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: hasNoAnswer ? Colors.red.shade50 : null,
                ),
                child: SelectableText(
                  hasNoAnswer ? 'Sin contestar' : _asString(rawAnswer),
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (options.isNotEmpty)
              ...List<Widget>.generate(options.length, (i) {
                final label = _optLabel(options[i]);
                final selected = normalizedType == 'multi'
                    ? _matchesMultiAnswer(multiAnswerValues, options[i], i)
                    : _matchesSingleAnswer(answerValue, options[i], i);

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? Colors.blue.shade200
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        normalizedType == 'multi'
                            ? (selected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank)
                            : (selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off),
                        size: 20,
                        color: selected
                            ? Colors.blue.shade700
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? Colors.red.shade700
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasNoAnswer ? Colors.red.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: hasNoAnswer
                      ? Border.all(color: Colors.red.shade200)
                      : null,
                ),
                child: Text(
                  hasNoAnswer
                      ? 'Sin contestar'
                      : 'Respuesta: ${_asString(rawAnswer)}',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}