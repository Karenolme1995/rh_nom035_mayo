import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../services/nom035_profile_service.dart';
import 'nom035_admin_action_plan_screen.dart';
import 'nom035_admin_evidence_screen.dart';
import 'nom035_admin_stps_file_screen.dart';

class Nom035AuditScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int cycleId;
  final String? cycleTitle;
  final Map<String, dynamic> rawPayload;
  final List items;
  final List pendingUsers;
  final Map<int, String> areasMap;

  final bool embedded;
  final Future<void> Function()? onRefreshParent;

  const Nom035AuditScreen({
    super.key,
    required this.userData,
    required this.cycleId,
    required this.cycleTitle,
    required this.rawPayload,
    required this.items,
    required this.pendingUsers,
    required this.areasMap,
    this.embedded = false,
    this.onRefreshParent,
  });

  @override
  State<Nom035AuditScreen> createState() => _Nom035AuditScreenState();
}

class _Nom035AuditScreenState extends State<Nom035AuditScreen>
    with TickerProviderStateMixin {
  static const String _companyName = 'VITRACOAT PINTURAS EN POLVO SA DE CV';
  static const String _logoAsset = 'assets/images/vitracoat.png';
  static const String _policyAsset = 'assets/docs/POLITICA VITRACOAT.PDF';

  static const Color _primaryColor = Color(0xFF0D47A1);
  static const Color _secondaryColor = Color(0xFF1565C0);
  static const Color _accentColor = Color(0xFF42A5F5);
  static const Color _softBlue = Color(0xFFEAF3FF);
  static const Color _cardBorder = Color(0xFFD8E2EC);
  static const Color _textDark = Color(0xFF2C2C33);
  static const Color _pageBg = Color(0xFFF4F3F8);
  static const Color _mutedText = Color(0xFF6B7280);

static const List<String> _sexOptions = [
  'M',
  'F',
];

static const List<String> _ageRangeOptions = [
  '15 – 19',
  '20 – 24',
  '25 – 29',
  '30 – 34',
  '35 – 39',
  '40 – 44',
  '45 – 49',
  '50 – 54',
  '55 – 59',
  '60 – 64',
  '65 – 69',
  '70 o más',
];

static const List<String> _maritalStatusOptions = [
  'Casado',
  'Divorciado',
  'Soltero',
  'Viudo',
  'Unión libre',
];

static const List<String> _educationLevelOptions = [
  'Primaria terminada',
  'Primaria incompleta',
  'Secundaria terminada',
  'Secundaria incompleta',
  'Preparatoria/Bachillerato terminado',
  'Preparatoria/Bachillerato incompleto',
  'Técnico Superior terminado',
  'Técnico Superior incompleto',
  'Licenciatura terminada',
  'Licenciatura incompleta',
  'Maestría terminada',
  'Maestría incompleta',
  'Doctorado terminado',
  'Doctorado incompleto',
  'Sin formación',
];

static const List<String> _jobTypeOptions = [
  'operativo',
  'supervisor',
  'profesional_tecnico',
  'gerente',
];

static const List<String> _hiringTypeOptions = [
  'obra_proyecto',
  'indeterminado',
  'temporal',
  'honorarios',
];

static const List<String> _staffTypeOptions = [
  'sindicalizado',
  'confianza',
  'ninguno',
];

static const List<String> _workdayTypeOptions = [
  'fijo_nocturno',
  'fijo_mixto',
  'fijo_diurno',
];

static const List<String> _shiftRotationOptions = [
  'si',
  'no',
];

static const List<String> _timeOptions = [
  'Menos de 6 meses',
  'Entre 6 meses y 1 año',
  'Entre 1 a 4 años',
  'Entre 5 a 9 años',
  'Entre 10 a 14 años',
  'Entre 15 a 19 años',
  'Entre 20 a 24 años',
  '25 años o más',
];


  final GlobalKey _sexChartKey = GlobalKey();
  final GlobalKey _ageChartKey = GlobalKey();
  final GlobalKey _educationChartKey = GlobalKey();
  final GlobalKey _jobTypeChartKey = GlobalKey();
  final GlobalKey _maritalStatusChartKey = GlobalKey();
  final GlobalKey _hiringTypeChartKey = GlobalKey();
  final GlobalKey _staffTypeChartKey = GlobalKey();
  final GlobalKey _workdayTypeChartKey = GlobalKey();
  final GlobalKey _shiftRotationChartKey = GlobalKey();
  final GlobalKey _experienceChartKey = GlobalKey();
  final GlobalKey _currentPositionTimeChartKey = GlobalKey();

  final GlobalKey _riskPieKey = GlobalKey();
  final GlobalKey _departmentBarKey = GlobalKey();
  final GlobalKey _categoryBarKey = GlobalKey();
  final GlobalKey _domainBarKey = GlobalKey();
  final GlobalKey _heatmapKey = GlobalKey();

  late final AnimationController _pageAnimController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Map<String, dynamic> _profileStats = {};
  bool _loadingProfileStats = false;
  String? _profileStatsError;

  Map<String, int> _completeCountMap(
    Map<String, int> source,
    List<String> orderedOptions,
  ) {
    final out = <String, int>{};

    for (final option in orderedOptions) {
      out[option] = source[option] ?? 0;
    }

    for (final entry in source.entries) {
      out.putIfAbsent(entry.key, () => entry.value);
    }

    return out;
  }

  @override
  void initState() {
    super.initState();

    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _pageAnimController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pageAnimController.forward();
    _loadProfileStats();
  }

  @override
  void dispose() {
    _pageAnimController.dispose();
    super.dispose();
  }

  String _s(dynamic v) => v == null ? '' : v.toString();

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  bool _mapHasData(dynamic v) {
  if (v is Map) return v.isNotEmpty;
  return false;
  }

  bool _listHasData(dynamic v) {
    if (v is List) return v.isNotEmpty;
    return false;
  }

  bool _stringHasData(dynamic v) {
    if (v == null) return false;
    final text = v.toString().trim();
    return text.isNotEmpty;
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

  Map<String, dynamic> _summary() => _asMap(widget.rawPayload['summary']);

Future<void> _loadProfileStats() async {
  setState(() {
    _loadingProfileStats = true;
    _profileStatsError = null;
  });

  try {
    final data = await Nom035ProfileService.getProfileStats(widget.cycleId);

    if (!mounted) return;
    setState(() {
      _profileStats = Map<String, dynamic>.from(data);
      _loadingProfileStats = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _profileStats = <String, dynamic>{};
      _profileStatsError = e.toString();
      _loadingProfileStats = false;
    });
  }
}

List<Map<String, dynamic>> _profileList(String key) {
  if (!_mapHasData(_profileStats)) return <Map<String, dynamic>>[];

  final raw = _profileStats[key];

  if (raw is List) {
    return raw.map((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{};
    }).toList();
  }

  return <Map<String, dynamic>>[];
}

  Map<String, int> _profileCountMap(String key) {
    final list = _profileList(key);
    final out = <String, int>{};

    for (final item in list) {
      final label = _s(item['label']).trim().isEmpty
          ? 'Sin dato'
          : _s(item['label']).trim();
      final total = _asInt(item['total']);
      out[label] = total;
    }

    return out;
  }

  Map<String, double> _avgScoreMapFromList(String key) {
    final list = _profileList(key);
    final out = <String, double>{};

    for (final item in list) {
      final label = _s(item['label']).trim().isEmpty
          ? 'Sin dato'
          : _s(item['label']).trim();
      final score = _asDouble(item['avg_score']);
      out[label] = score;
    }

    return out;
  }

  String _resolveArea(dynamic raw) {
    if (raw == null) return '—';

    if (raw is Map) {
      final m = _asMap(raw);
      final preferred = [
        _s(m['letter']).trim(),
        _s(m['code']).trim(),
        _s(m['clave']).trim(),
        _s(m['area_letter']).trim(),
        _s(m['area_code']).trim(),
        _s(m['name']).trim(),
        _s(m['area_name']).trim(),
        _s(m['label']).trim(),
      ];

      for (final value in preferred) {
        if (value.isNotEmpty) return value;
      }

      final id = _asInt(m['id'] ?? m['area_id']);
      if (id > 0 && widget.areasMap.containsKey(id)) return widget.areasMap[id]!;
      return id > 0 ? 'Área $id' : '—';
    }

    final rawText = _s(raw).trim();
    if (rawText.isEmpty) return '—';

    final id = int.tryParse(rawText);
    if (id != null) return widget.areasMap[id] ?? 'Área $id';

    return rawText;
  }

  String _resolveDepartmentFromSummary(Map<String, dynamic> m) {
    final candidates = [
      _s(m['department_letter']).trim(),
      _s(m['department_code']).trim(),
      _s(m['department_name']).trim(),
      _s(m['department']).trim(),
      _s(m['name']).trim(),
      _s(m['label']).trim(),
    ];

    for (final value in candidates) {
      if (value.isNotEmpty) {
        final parsedId = int.tryParse(value);
        if (parsedId != null) return widget.areasMap[parsedId] ?? 'Área $parsedId';
        return value;
      }
    }

    final id = _asInt(m['department_id'] ?? m['area_id'] ?? m['id']);
    if (id > 0) return widget.areasMap[id] ?? 'Área $id';

    return '—';
  }

  int _assignedCount() {
    final total = _asInt(widget.rawPayload['total']);
    if (total > 0) return total;
    return widget.items.length + widget.pendingUsers.length;
  }

  int _submittedCount() {
    int count = 0;
    for (final item in widget.items) {
      final st = _s(_asMap(item)['status']).toLowerCase().trim();
      if (st == 'submitted') count++;
    }
    return count;
  }

  int _inProgressCount() {
    int count = 0;
    for (final item in widget.items) {
      final st = _s(_asMap(item)['status']).toLowerCase().trim();
      if (st == 'in_progress') count++;
    }
    for (final item in widget.pendingUsers) {
      final st = _s(_asMap(item)['status']).toLowerCase().trim();
      if (st == 'in_progress') count++;
    }
    return count;
  }

  int _pendingCount() => widget.pendingUsers.length;

  double _averageScore() {
    if (widget.items.isEmpty) return 0;

    double sum = 0;
    int count = 0;

    for (final item in widget.items) {
      final it = _asMap(item);
      final score = it['score_total'];
      if (score != null) {
        sum += _asDouble(score);
        count++;
      }
    }

    if (count == 0) return 0;
    return sum / count;
  }

  Map<String, int> _riskStats() {
    final summaryRisk = _asMap(_summary()['risk']);
    if (summaryRisk.isNotEmpty) {
      return {
        'Muy alto': _asInt(summaryRisk['muy_alto']),
        'Alto': _asInt(summaryRisk['alto']),
        'Medio': _asInt(summaryRisk['medio']),
        'Bajo': _asInt(summaryRisk['bajo']),
        'Nulo': _asInt(summaryRisk['nulo']),
      };
    }

    final stats = <String, int>{
      'Muy alto': 0,
      'Alto': 0,
      'Medio': 0,
      'Bajo': 0,
      'Nulo': 0,
    };

    for (final item in widget.items) {
      final it = _asMap(item);
      final riskLevel = _s(it['risk_level']).trim().toLowerCase();

      if (riskLevel == 'muy alto') {
        stats['Muy alto'] = stats['Muy alto']! + 1;
      } else if (riskLevel == 'alto') {
        stats['Alto'] = stats['Alto']! + 1;
      } else if (riskLevel == 'medio') {
        stats['Medio'] = stats['Medio']! + 1;
      } else if (riskLevel == 'bajo') {
        stats['Bajo'] = stats['Bajo']! + 1;
      } else {
        stats['Nulo'] = stats['Nulo']! + 1;
      }
    }

    return stats;
  }

  Map<String, int> _riskDistributionFromProfile() {
  if (!_mapHasData(_profileStats)) return _riskStats();

  final raw = _profileStats['risk_distribution'];
  if (raw is Map) {
    final m = Map<String, dynamic>.from(raw);
    return {
      'Muy alto': _asInt(m['Muy alto']),
      'Alto': _asInt(m['Alto']),
      'Medio': _asInt(m['Medio']),
      'Bajo': _asInt(m['Bajo']),
      'Nulo': _asInt(m['Nulo']),
    };
  }

  return _riskStats();
}

  Map<String, int> _departmentStats() {
    final summaryDepartments = _asList(_summary()['departments']);
    if (summaryDepartments.isNotEmpty) {
      final out = <String, int>{};
      for (final d in summaryDepartments) {
        final m = _asMap(d);
        final name = _resolveDepartmentFromSummary(m);
        if (name.trim().isEmpty || name.trim() == '—') continue;
        out[name] = _asInt(m['count']);
      }

      final sortedEntries = out.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {for (final e in sortedEntries) e.key: e.value};
    }

    final stats = <String, int>{};

    for (final item in widget.items) {
      final it = _asMap(item);
      final user = _asMap(it['user']);
      final area = _resolveArea(
        user['area'] ?? user['area_id'] ?? user['area_name'],
      );
      stats[area] = (stats[area] ?? 0) + 1;
    }

    final sortedEntries = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {for (final e in sortedEntries) e.key: e.value};
  }

 Map<String, int> _departmentTotalsFromProfile() {
  if (!_mapHasData(_profileStats)) return _departmentStats();

  final raw = _profileStats['department_results'];
  if (raw is List) {
    final out = <String, int>{};
    for (final item in raw) {
      final m = _asMap(item);
      final label = _s(m['department']).trim().isEmpty
          ? 'Sin área'
          : _s(m['department']).trim();
      out[label] = _asInt(m['total']);
    }
    return out;
  }

  return _departmentStats();
}

  Map<String, double> _departmentAvgScoreFromProfile() {
    final raw = _profileStats['department_results'];
    if (raw is List) {
      final out = <String, double>{};
      for (final item in raw) {
        final m = _asMap(item);
        final label = _s(m['department']).trim().isEmpty
            ? 'Sin área'
            : _s(m['department']).trim();
        out[label] = _asDouble(m['avg_score']);
      }
      return out;
    }
    return {};
  }

  Map<String, double> _categoryStats() {
    final summaryCategories = _asList(_summary()['categories']);
    if (summaryCategories.isNotEmpty) {
      final result = <String, double>{};
      for (final item in summaryCategories) {
        final m = _asMap(item);
        final name = _s(m['name'] ?? m['category_name'] ?? m['label']).trim();
        if (name.isEmpty) continue;
        result[name] = _asDouble(m['avg_score'] ?? m['score'] ?? m['value']);
      }
      final sorted = result.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return {for (final e in sorted) e.key: e.value};
    }

    final Map<String, List<double>> bucket = {};

    for (final item in widget.items) {
      final it = _asMap(item);
      final rawCategories = it['category_results'] ?? it['categories'];

      if (rawCategories is List) {
        for (final c in rawCategories) {
          final m = _asMap(c);
          final name = _s(m['category_name'] ?? m['name'] ?? m['label']).trim();
          if (name.isEmpty) continue;

          final value = _asDouble(
            m['score'] ?? m['score_total'] ?? m['value'] ?? m['total'],
          );

          bucket.putIfAbsent(name, () => []);
          bucket[name]!.add(value);
        }
      }
    }

    final result = <String, double>{};
    bucket.forEach((key, values) {
      if (values.isNotEmpty) {
        result[key] = values.reduce((a, b) => a + b) / values.length;
      }
    });

    final sorted = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  Map<String, double> _categoryAvgFromProfile() {
    return _avgScoreMapFromList('category_scores');
  }

  Map<String, double> _domainStats() {
    final summaryDomains = _asList(_summary()['domains']);
    if (summaryDomains.isNotEmpty) {
      final result = <String, double>{};
      for (final item in summaryDomains) {
        final m = _asMap(item);
        final name = _s(m['name'] ?? m['domain_name'] ?? m['label']).trim();
        if (name.isEmpty) continue;
        result[name] = _asDouble(m['avg_score'] ?? m['score'] ?? m['value']);
      }
      final sorted = result.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return {for (final e in sorted) e.key: e.value};
    }

    final Map<String, List<double>> bucket = {};

    for (final item in widget.items) {
      final it = _asMap(item);
      final rawDomains = it['domain_results'] ?? it['domains'];

      if (rawDomains is List) {
        for (final d in rawDomains) {
          final m = _asMap(d);
          final name = _s(m['domain_name'] ?? m['name'] ?? m['label']).trim();
          if (name.isEmpty) continue;

          final value = _asDouble(
            m['score'] ?? m['score_total'] ?? m['value'] ?? m['total'],
          );

          bucket.putIfAbsent(name, () => []);
          bucket[name]!.add(value);
        }
      }
    }

    final result = <String, double>{};
    bucket.forEach((key, values) {
      if (values.isNotEmpty) {
        result[key] = values.reduce((a, b) => a + b) / values.length;
      }
    });

    final sorted = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  Map<String, double> _domainAvgFromProfile() {
    return _avgScoreMapFromList('domain_scores');
  }

  Map<String, Map<String, int>> _riskHeatmap() {
    final summaryHeatmap = _asList(_summary()['heatmap']);
    if (summaryHeatmap.isNotEmpty) {
      final out = <String, Map<String, int>>{};
      for (final row in summaryHeatmap) {
        final m = _asMap(row);
        final dept = _resolveDepartmentFromSummary(m);
        if (dept.isEmpty || dept == '—') continue;

        out[dept] = {
          'Muy alto': _asInt(m['muy_alto']),
          'Alto': _asInt(m['alto']),
          'Medio': _asInt(m['medio']),
          'Bajo': _asInt(m['bajo']),
          'Nulo': _asInt(m['nulo']),
        };
      }
      return out;
    }

    final Map<String, Map<String, int>> heatmap = {};

    for (final item in widget.items) {
      final it = _asMap(item);
      final user = _asMap(it['user']);
      final area = _resolveArea(
        user['area'] ?? user['area_id'] ?? user['area_name'],
      );

      String riskLabel = _s(it['risk_level']).trim();
      if (riskLabel.isEmpty) riskLabel = 'Nulo';

      heatmap.putIfAbsent(area, () {
        return {
          'Muy alto': 0,
          'Alto': 0,
          'Medio': 0,
          'Bajo': 0,
          'Nulo': 0,
        };
      });

      final normalized = riskLabel.toLowerCase().trim();
      if (normalized == 'muy alto') {
        heatmap[area]!['Muy alto'] = heatmap[area]!['Muy alto']! + 1;
      } else if (normalized == 'alto') {
        heatmap[area]!['Alto'] = heatmap[area]!['Alto']! + 1;
      } else if (normalized == 'medio') {
        heatmap[area]!['Medio'] = heatmap[area]!['Medio']! + 1;
      } else if (normalized == 'bajo') {
        heatmap[area]!['Bajo'] = heatmap[area]!['Bajo']! + 1;
      } else {
        heatmap[area]!['Nulo'] = heatmap[area]!['Nulo']! + 1;
      }
    }

    final entries = heatmap.entries.toList()
      ..sort((a, b) {
        final totalA = a.value.values.fold<int>(0, (p, e) => p + e);
        final totalB = b.value.values.fold<int>(0, (p, e) => p + e);
        return totalB.compareTo(totalA);
      });

    return {for (final e in entries) e.key: e.value};
  }

Map<String, Map<String, int>> _departmentHeatmapFromProfile() {
  if (!_mapHasData(_profileStats)) return _riskHeatmap();

  final raw = _profileStats['department_heatmap'];
  if (raw is List) {
    final out = <String, Map<String, int>>{};
    for (final item in raw) {
      final m = _asMap(item);
      final dept = _s(m['department']).trim().isEmpty
          ? 'Sin área'
          : _s(m['department']).trim();

      out[dept] = {
        'Muy alto': _asInt(m['Muy alto']),
        'Alto': _asInt(m['Alto']),
        'Medio': _asInt(m['Medio']),
        'Bajo': _asInt(m['Bajo']),
        'Nulo': _asInt(m['Nulo']),
      };
    }
    return out;
  }

  return _riskHeatmap();
}

  Color _riskSolidColor(String risk) {
    final r = risk.toLowerCase().trim();
    if (r == 'muy alto') return Colors.red.shade700;
    if (r == 'alto') return Colors.orange.shade700;
    if (r == 'medio') return Colors.amber.shade700;
    if (r == 'bajo') return Colors.green.shade600;
    if (r == 'nulo' || r == 'sin riesgo') return _secondaryColor;
    return Colors.grey;
  }

  String _companyActivity() {
    return 'Vitracoat se dedica a desarrollar, fabricar y vender recubrimientos en polvo de uso industrial, que sirven para dar acabado, protección y durabilidad a distintos productos.';
  }

  String _appObjective() {
    return 'Identificar, analizar y prevenir los factores de riesgo psicosocial en el trabajo, así como promover un entorno organizacional favorable en los centros de trabajo.';
  }

  String _mainActivities() {
    return 'Fabricación de pinturas en polvo, operación de líneas de producción, control de calidad, almacenamiento, logística, embarques, mantenimiento y actividades administrativas vinculadas al proceso productivo.';
  }

  String _usedMethod() {
    return 'Aplicación digital de cuestionarios NOM-035 y concentración de resultados por colaborador, categoría, dominio y nivel de riesgo, conforme a la información capturada en el ciclo vigente.';
  }

  String _qualificationMedium() {
    return 'Medio digital mediante plataforma interna, con procesamiento automatizado de respuestas y generación de métricas consolidadas.';
  }

  String _finalScoreFormula() {
    return '''La calificación final del ciclo se integra con base en la información entregada:

• score_total por colaborador
• risk_level asignado
• resultados por categoría
• resultados por dominio

Proceso visual utilizado en esta pantalla:
1. Se toma el score_total de cada submission enviada.
2. Se calcula el promedio general del ciclo con los cuestionarios contestados.
3. Se consolidan resultados por categoría y dominio.
4. Se visualiza la distribución de niveles de riesgo y la concentración por departamento.''';
  }

  String _categoriesDescription() {
    return 'Las categorías consideradas corresponden a la estructura de evaluación NOM-035 configurada en el sistema para las guías aplicables del ciclo.';
  }

  String _domainsDescription() {
    return 'Los dominios mostrados provienen de la clasificación asociada a las preguntas contestadas en las guías evaluables del ciclo.';
  }

  String _decisionCriteria() {
    return 'La toma de decisión se basa en la calificación obtenida, el nivel de riesgo identificado, la concentración de resultados por categoría y dominio, y la distribución del riesgo por área o departamento.';
  }

  String _obtainedResultsText(Map<String, int> riskStats, Map<String, int> departmentStats) {
    final submitted = _profileStats.isNotEmpty
        ? _asInt(_asMap(_profileStats['final_study_data'])['total_submissions'])
        : _submittedCount();

    final topDepartment = departmentStats.entries.isEmpty
        ? 'Sin área'
        : (departmentStats.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return 'Se analizaron $submitted cuestionarios enviados. '
        'La distribución de riesgo obtenida permite identificar áreas prioritarias de intervención. '
        'El departamento con mayor concentración de registros es: $topDepartment. '
        'Los niveles de riesgo observados fueron: '
        'Muy alto ${riskStats['Muy alto'] ?? 0}, '
        'Alto ${riskStats['Alto'] ?? 0}, '
        'Medio ${riskStats['Medio'] ?? 0}, '
        'Bajo ${riskStats['Bajo'] ?? 0} y '
        'Nulo ${riskStats['Nulo'] ?? 0}.';
  }

  String _sampleConsideredText() {
    final total = _profileStats.isNotEmpty
        ? _asInt(_asMap(_profileStats['final_study_data'])['total_submissions'])
        : _submittedCount();
    return '$total colaboradores con cuestionario enviado en el ciclo evaluado.';
  }

  String _finalGeneralScoreText() {
    final avg = _profileStats.isNotEmpty
        ? _asDouble(_asMap(_profileStats['final_study_data'])['avg_score'])
        : _averageScore();
    return avg.toStringAsFixed(2);
  }

  String _categoryScoreText(Map<String, double> data) {
    if (data.isEmpty) return 'Sin información disponible.';
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(8)
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
        .join('\n');
  }

  String _domainScoreText(Map<String, double> data) {
    if (data.isEmpty) return 'Sin información disponible.';
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(8)
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
        .join('\n');
  }

  String _recommendationsText(Map<String, int> riskStats) {
    final veryHigh = riskStats['Muy alto'] ?? 0;
    final high = riskStats['Alto'] ?? 0;

    final buffer = StringBuffer();
    buffer.writeln('• Mantener seguimiento periódico de resultados NOM-035 por ciclo.');
    buffer.writeln('• Revisar áreas con mayor concentración de riesgo y priorizar acciones correctivas.');
    buffer.writeln('• Fortalecer comunicación interna, liderazgo y claridad de funciones.');
    buffer.writeln('• Implementar o actualizar plan de acción y evidencia documental.');
    buffer.writeln('• Promover capacitación, prevención y atención oportuna.');

    if (veryHigh > 0 || high > 0) {
      buffer.writeln(
        '• Debido a la presencia de niveles Alto/Muy alto, se recomienda intervención prioritaria en las áreas impactadas.',
      );
    }

    return buffer.toString().trim();
  }

  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final context = key.currentContext;
      if (context == null) return null;

      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _printCharts() async {
    final images = <Uint8List>[];
    final keys = [
      _sexChartKey,
      _ageChartKey,
      _educationChartKey,
      _jobTypeChartKey,
      _maritalStatusChartKey,
      _hiringTypeChartKey,
      _staffTypeChartKey,
      _workdayTypeChartKey,
      _shiftRotationChartKey,
      _experienceChartKey,
      _currentPositionTimeChartKey,
      _riskPieKey,
      _departmentBarKey,
      _categoryBarKey,
      _domainBarKey,
      _heatmapKey,
    ];

    for (final key in keys) {
      final img = await _captureWidget(key);
      if (img != null) images.add(img);
    }

    if (images.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron capturar las gráficas.')),
      );
      return;
    }

    await Printing.layoutPdf(
      onLayout: (format) async {
        final regularFontData = await rootBundle.load(
          'assets/fonts/Roboto-Regular.ttf',
        );
        final boldFontData = await rootBundle.load(
          'assets/fonts/Roboto-Bold.ttf',
        );

        final regularFont = pw.Font.ttf(regularFontData);
        final boldFont = pw.Font.ttf(boldFontData);

        final doc = pw.Document();

        doc.addPage(
          pw.MultiPage(
            theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
            build: (pw.Context context) {
              return [
                pw.Text(
                  'Expediente STPS NOM-035 - ${widget.cycleTitle ?? ''}',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
                pw.SizedBox(height: 12),
                ...images.map(
                  (img) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 14),
                    child: pw.Image(pw.MemoryImage(img)),
                  ),
                ),
              ];
            },
          ),
        );

        return doc.save();
      },
    );
  }

  Future<void> _openPolicyPdf() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _Nom035AssetPdfScreen(
          title: 'Política Vitracoat',
          assetPath: _policyAsset,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

final hasProfileStats = _mapHasData(_profileStats);

final riskStats = hasProfileStats
    ? _riskDistributionFromProfile()
    : _riskStats();

final departmentStats = hasProfileStats
    ? _departmentTotalsFromProfile()
    : _departmentStats();

final categoryStats = hasProfileStats
    ? _categoryAvgFromProfile()
    : _categoryStats();

final domainStats = hasProfileStats
    ? _domainAvgFromProfile()
    : _domainStats();

final heatmap = hasProfileStats
    ? _departmentHeatmapFromProfile()
    : _riskHeatmap();

  final sexStats = _completeCountMap(
  _profileCountMap('sex'),
  _sexOptions,
);

final ageStats = _completeCountMap(
  _profileCountMap('age_range'),
  _ageRangeOptions,
);

final educationStats = _completeCountMap(
  _profileCountMap('education_level'),
  _educationLevelOptions,
);

final jobTypeStats = _completeCountMap(
  _profileCountMap('job_type'),
  _jobTypeOptions,
);

final maritalStats = _completeCountMap(
  _profileCountMap('marital_status'),
  _maritalStatusOptions,
);

final hiringStats = _completeCountMap(
  _profileCountMap('hiring_type'),
  _hiringTypeOptions,
);

final staffStats = _completeCountMap(
  _profileCountMap('staff_type'),
  _staffTypeOptions,
);

final workdayStats = _completeCountMap(
  _profileCountMap('workday_type'),
  _workdayTypeOptions,
);

final rotationStats = _completeCountMap(
  _profileCountMap('shift_rotation'),
  _shiftRotationOptions,
);

final experienceStats = _completeCountMap(
  _profileCountMap('total_work_experience'),
  _timeOptions,
);

final currentPositionStats = _completeCountMap(
  _profileCountMap('time_current_position'),
  _timeOptions,
);


    return Scaffold(
      backgroundColor: _pageBg,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _sectionCard(
                title: 'Acciones',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Nom035AdminStpsFileScreen(
                              userData: widget.userData,
                              cycleId: widget.cycleId,
                              cycleTitle: _s(widget.cycleTitle),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.folder_shared_outlined),
                      label: const Text('Expediente STPS'),
                    ),
                   
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: const BorderSide(color: _primaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _openPolicyPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Ver política'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _sectionCard(
                title: 'Resumen del ciclo',
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _miniStatCard(
                      title: 'Total registros',
                      value: '${_assignedCount()}',
                      icon: Icons.people_alt_outlined,
                    ),
                    _miniStatCard(
                      title: 'Enviados',
                      value: '${_submittedCount()}',
                      icon: Icons.assignment_turned_in_outlined,
                    ),
                    _miniStatCard(
                      title: 'En curso',
                      value: '${_inProgressCount()}',
                      icon: Icons.timelapse_outlined,
                    ),
                    _miniStatCard(
                      title: 'Pendientes',
                      value: '${_pendingCount()}',
                      icon: Icons.pending_actions_outlined,
                    ),
                    _miniStatCard(
                      title: 'Promedio score',
                      value: _finalGeneralScoreText(),
                      icon: Icons.analytics_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _companyHeaderCard(),
              const SizedBox(height: 14),

              _sectionCard(
                title: 'Datos del centro de trabajo',
                child: Column(
                  children: [
                    _auditDataField(title: 'Empresa', value: _companyName),
                    _auditDataField(
                      title: 'Actividad principal de la empresa',
                      value: _companyActivity(),
                    ),
                    _auditDataField(
                      title: 'Objetivo de la aplicación',
                      value: _appObjective(),
                    ),
                    _auditDataField(
                      title: 'Principales actividades realizadas por el centro de trabajo',
                      value: _mainActivities(),
                    ),
                    _auditDataField(
                      title: 'Método utilizado',
                      value: _usedMethod(),
                    ),
                    _auditDataField(
                      title: 'Medio de calificación',
                      value: _qualificationMedium(),
                    ),
                    _auditDataField(
                      title: 'Fórmulas para calificación final',
                      value: _finalScoreFormula(),
                    ),
                    _auditDataField(
                      title: 'Categoría',
                      value: _categoriesDescription(),
                    ),
                    _auditDataField(
                      title: 'Dominio',
                      value: _domainsDescription(),
                    ),
                    _auditDataField(
                      title: 'Criterio para la toma de decisión',
                      value: _decisionCriteria(),
                    ),
                    _auditDataField(
                      title: 'Resultados obtenidos',
                      value: _obtainedResultsText(riskStats, departmentStats),
                    ),
                    _auditDataField(
                      title: 'Muestra considerada',
                      value: _sampleConsideredText(),
                    ),
                    _auditDataField(
                      title: 'Calificación final general',
                      value: _finalGeneralScoreText(),
                    ),
                    _auditDataField(
                      title: 'Calificación por categoría',
                      value: _categoryScoreText(categoryStats),
                    ),
                    _auditDataField(
                      title: 'Calificación por dominio',
                      value: _domainScoreText(domainStats),
                    ),
                    _auditDataField(
                      title: 'Recomendaciones',
                      value: _recommendationsText(riskStats),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

             _sectionCard(
  title: 'Gráficas',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_loadingProfileStats)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),

      if (_profileStatsError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            _profileStatsError!,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

      _responsiveChartGrid([
        _chartCard(
          title: '1. Por sexo',
          child: RepaintBoundary(
            key: _sexChartKey,
            child: Column(
              children: [
                _responsivePieChart(sexStats),
                _totalFooter(sexStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '2. Por edad',
          child: RepaintBoundary(
            key: _ageChartKey,
            child: Column(
              children: [
                _responsivePieChart(ageStats),
                _totalFooter(ageStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '3. Por nivel educativo',
          child: RepaintBoundary(
            key: _educationChartKey,
            child: Column(
              children: [
                _responsivePieChart(educationStats),
                _totalFooter(educationStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '4. Tipo de puesto',
          child: RepaintBoundary(
            key: _jobTypeChartKey,
            child: Column(
              children: [
                _responsivePieChart(jobTypeStats),
                _totalFooter(jobTypeStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '5. Estado civil',
          child: RepaintBoundary(
            key: _maritalStatusChartKey,
            child: Column(
              children: [
                _responsivePieChart(maritalStats),
                _totalFooter(maritalStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '6. Tipo de contrato',
          child: RepaintBoundary(
            key: _hiringTypeChartKey,
            child: Column(
              children: [
                _responsivePieChart(hiringStats),
                _totalFooter(hiringStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '7. Tipo de personal',
          child: RepaintBoundary(
            key: _staffTypeChartKey,
            child: Column(
              children: [
                _responsivePieChart(staffStats),
                _totalFooter(staffStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '8. Tipo de jornada de trabajo',
          child: RepaintBoundary(
            key: _workdayTypeChartKey,
            child: Column(
              children: [
                _responsivePieChart(workdayStats),
                _totalFooter(workdayStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '9. Realiza rotación de turnos',
          child: RepaintBoundary(
            key: _shiftRotationChartKey,
            child: Column(
              children: [
                _responsivePieChart(rotationStats),
                _totalFooter(rotationStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '10. Experiencia laboral',
          child: RepaintBoundary(
            key: _experienceChartKey,
            child: Column(
              children: [
                _responsivePieChart(experienceStats),
                _totalFooter(experienceStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '11. Tiempo de permanencia en el puesto actual',
          child: RepaintBoundary(
            key: _currentPositionTimeChartKey,
            child: Column(
              children: [
                _responsivePieChart(currentPositionStats),
                _totalFooter(currentPositionStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '12. Datos de estudio final',
          child: _auditDataField(
            title: 'Resumen final',
            value: (() {
              final finalStudy = _asMap(_profileStats['final_study_data']);
              return 'Total submissions: ${_asInt(finalStudy['total_submissions'])}\n'
                  'Promedio score: ${_asDouble(finalStudy['avg_score']).toStringAsFixed(2)}';
            })(),
          ),
        ),
        _chartCard(
          title: '13. Reporte sintetizado general',
          child: _auditDataField(
            title: 'Síntesis general',
            value: (() {
              final general = _asMap(_profileStats['general_synthesized_report']);
              return 'Promedio general del ciclo: ${_asDouble(general['avg_score']).toStringAsFixed(2)}\n'
                  'Cuestionarios considerados: ${_asInt(general['total_submissions'])}';
            })(),
          ),
        ),
        _chartCard(
          title: '14. Por dominio',
          child: RepaintBoundary(
            key: _domainBarKey,
            child: Column(
              children: [
                SizedBox(
                  height: 390,
                  child: _scoreBarChart(
                    data: domainStats,
                    emptyLabel: 'No hay datos de dominios.',
                  ),
                ),
                _totalFooterScore(domainStats, label: 'Promedio general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '15. Por categoría',
          child: RepaintBoundary(
            key: _categoryBarKey,
            child: Column(
              children: [
                SizedBox(
                  height: 390,
                  child: _scoreBarChart(
                    data: categoryStats,
                    emptyLabel: 'No hay datos de categorías.',
                  ),
                ),
                _totalFooterScore(categoryStats, label: 'Promedio general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '16. Distribución de niveles de riesgo',
          child: RepaintBoundary(
            key: _riskPieKey,
            child: Column(
              children: [
                SizedBox(
                  height: 420,
                  child: _riskPieChart(riskStats),
                ),
                _totalFooter(riskStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '17. Resultados por departamento',
          child: RepaintBoundary(
            key: _departmentBarKey,
            child: Column(
              children: [
                SizedBox(
                  height: 390,
                  child: _departmentBarChart(departmentStats),
                ),
                _totalFooter(departmentStats, label: 'Total general'),
              ],
            ),
          ),
        ),
        _chartCard(
          title: '18. Heatmap por departamento',
          child: RepaintBoundary(
            key: _heatmapKey,
            child: _heatmapTable(heatmap),
          ),
        ),
      ]),
    ],
  ),
),
              const SizedBox(height: 24),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Nom035AdminEvidenceScreen(
                            userData: widget.userData,
                            cycleId: widget.cycleId,
                            cycleTitle: _s(widget.cycleTitle),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.upload_file_outlined),
                    label: const Text('Evidencias'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Nom035AdminActionPlanScreen(
                            userData: widget.userData,
                            cycleId: widget.cycleId,
                            cycleTitle: _s(widget.cycleTitle),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Plan de acción'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _companyHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EEF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5D0D7)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 560;

          final logoBox = Container(
            width: 82,
            height: 82,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCFC9D0)),
            ),
            child: Image.asset(
              _logoAsset,
              fit: BoxFit.contain,
            ),
          );

          final textBox = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _companyName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expediente STPS NOM-035',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logoBox,
                const SizedBox(height: 12),
                textBox,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              logoBox,
              const SizedBox(width: 16),
              textBox,
            ],
          );
        },
      ),
    );
  }


  Widget _responsiveChartGrid(List<Widget> children) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 1100;
      final isMedium = constraints.maxWidth >= 720;

      if (isWide) {
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children.map((child) {
            return SizedBox(
              width: (constraints.maxWidth - 14) / 2,
              child: child,
            );
          }).toList(),
        );
      }

      if (isMedium) {
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children.map((child) {
            return SizedBox(
              width: (constraints.maxWidth - 14) / 2,
              child: child,
            );
          }).toList(),
        );
      }

      return Column(
        children: children
            .map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: child,
                ))
            .toList(),
      );
    },
  );
}

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard({
    required String title,
    required String value,
    required IconData icon,
    double width = 180,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF4F8FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: _primaryColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditDataField({
    required String title,
    required String value,
    bool pending = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pending ? Colors.orange.shade50 : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pending ? Colors.orange.shade200 : _cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: pending ? Colors.orange.shade800 : _primaryColor,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              height: 1.55,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard({
    required String title,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF7FBFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

Widget _riskPieChart(Map<String, int> riskStats) {
  final entries = [
    MapEntry('Muy alto', riskStats['Muy alto'] ?? 0),
    MapEntry('Alto', riskStats['Alto'] ?? 0),
    MapEntry('Medio', riskStats['Medio'] ?? 0),
    MapEntry('Bajo', riskStats['Bajo'] ?? 0),
    MapEntry('Nulo', riskStats['Nulo'] ?? 0),
  ];

  final total = entries.fold<int>(0, (sum, e) => sum + e.value);

  if (total == 0) {
    return const Center(child: Text('No hay datos para mostrar.'));
  }

  final colors = [
    Colors.red.shade700,
    Colors.orange.shade700,
    Colors.amber.shade700,
    Colors.green.shade600,
    _secondaryColor,
  ];

  return Column(
    children: [
      Expanded(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, anim, _) {
            return PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 48,
                pieTouchData: PieTouchData(enabled: true),
                sections: List.generate(entries.length, (i) {
                  final item = entries[i];
                  final pct = total == 0 ? 0.0 : (item.value / total) * 100;

                  return PieChartSectionData(
                    value: item.value.toDouble() * anim,
                    title: '${pct.toStringAsFixed(1)}%\n(${item.value})',
                    radius: 60,
                    color: colors[i],
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: List.generate(entries.length, (i) {
          final item = entries[i];
          final pct = total == 0 ? 0.0 : (item.value / total) * 100;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _cardBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.key}: ${item.value} (${pct.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ],
  );
}

Widget _departmentBarChart(Map<String, int> data) {
  if (data.isEmpty) {
    return const Center(child: Text('No hay datos para mostrar.'));
  }

  final entries = data.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top = entries.take(10).toList();
  final total = top.fold<int>(0, (sum, e) => sum + e.value);

  final maxValue = top
      .map((e) => e.value)
      .reduce((a, b) => a > b ? a : b)
      .toDouble();

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 950),
    curve: Curves.easeOutCubic,
    builder: (context, anim, _) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue + 3,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = top[group.x.toInt()];
                final pct = total == 0 ? 0.0 : (item.value / total) * 100;

                return BarTooltipItem(
                  '${item.key}\n'
                  'Total: ${item.value}\n'
                  'Porcentaje: ${pct.toStringAsFixed(1)}%',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= top.length) {
                    return const SizedBox.shrink();
                  }

                  final item = top[index];
                  final pct = total == 0 ? 0.0 : (item.value / total) * 100;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${item.value}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 34),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= top.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 84,
                      child: Text(
                        top[index].key,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(top.length, (index) {
            final e = top[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: e.value.toDouble() * anim,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [_primaryColor, _accentColor],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      );
    },
  );
}

  Widget _scoreBarChart({
  required Map<String, double> data,
  required String emptyLabel,
}) {
  if (data.isEmpty) return Center(child: Text(emptyLabel));

  final entries = data.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final top = entries.take(10).toList();
  final total = top.fold<double>(0, (sum, e) => sum + e.value);
  final maxValue = top
      .map((e) => e.value)
      .reduce((a, b) => a > b ? a : b);

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutExpo,
    builder: (context, anim, _) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue <= 0 ? 10 : maxValue + (maxValue * 0.20),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = top[group.x.toInt()];
                final pct = total == 0 ? 0.0 : (item.value / total) * 100;

                return BarTooltipItem(
                  '${item.key}\n'
                  'Score: ${item.value.toStringAsFixed(2)}\n'
                  'Peso: ${pct.toStringAsFixed(1)}%',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= top.length) {
                    return const SizedBox.shrink();
                  }

                  final item = top[index];
                  final pct = total == 0 ? 0.0 : (item.value / total) * 100;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.value.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 70,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= top.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 90,
                      child: Text(
                        top[index].key,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(top.length, (index) {
            final e = top[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: e.value * anim,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [_secondaryColor, _accentColor],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      );
    },
  );
}

Widget _responsivePieChart(
  Map<String, int> data, {
  String emptyLabel = 'No hay datos para mostrar.',
}) {
  if (data.isEmpty) {
    return Center(child: Text(emptyLabel));
  }

  final entries = data.entries.toList();
  final total = entries.fold<int>(0, (sum, e) => sum + e.value);

  if (total == 0) {
    return Center(child: Text(emptyLabel));
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 760;

      final chart = SizedBox(
        height: 260,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, anim, _) {
            return PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                pieTouchData: PieTouchData(enabled: false),
                sections: List.generate(entries.length, (i) {
                  final e = entries[i];
                  final percentage = total == 0 ? 0.0 : (e.value / total) * 100;

                  return PieChartSectionData(
                    value: e.value.toDouble() * anim,
                    title: e.value == 0
                        ? ''
                        : '${percentage.toStringAsFixed(1)}%\n(${e.value})',
                    radius: 62,
                    color: Colors.primaries[i % Colors.primaries.length],
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  );
                }),
              ),
            );
          },
        ),
      );

      final legend = Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Opciones',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 10),
            ...entries.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final percentage = total == 0 ? 0.0 : (item.value / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: Colors.primaries[i % Colors.primaries.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );

      if (isSmall) {
        return Column(
          children: [
            chart,
            const SizedBox(height: 14),
            legend,
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: chart),
          const SizedBox(width: 14),
          Expanded(flex: 4, child: legend),
        ],
      );
    },
  );
}


Widget _totalFooter(
  Map<String, int> data, {
  String label = 'Total general',
}) {
  final total = data.values.fold<int>(0, (sum, v) => sum + v);

  return Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
   
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        Text(
          '$total',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _primaryColor,
          ),
        ),
      ],
    ),
  );
}

Widget _totalFooterScore(
  Map<String, double> data, {
  String label = 'Promedio general',
}) {
  if (data.isEmpty) return const SizedBox();

  final avg = data.values.fold<double>(0, (sum, v) => sum + v) / data.length;

  return Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F8FD),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _cardBorder),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        Text(
          avg.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _primaryColor,
          ),
        ),
      ],
    ),
  );
}


  Widget _heatmapTable(Map<String, Map<String, int>> heatmap) {
    if (heatmap.isEmpty) {
      return const Text('No hay datos para construir el heatmap.');
    }

    final rows = heatmap.entries.take(12).toList();
    const riskCols = ['Muy alto', 'Alto', 'Medio', 'Bajo', 'Nulo'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStatePropertyAll(_softBlue),
        columnSpacing: 18,
        columns: const [
          DataColumn(label: Text('Departamento')),
          DataColumn(label: Text('Muy alto')),
          DataColumn(label: Text('Alto')),
          DataColumn(label: Text('Medio')),
          DataColumn(label: Text('Bajo')),
          DataColumn(label: Text('Nulo')),
        ],
        rows: rows.map((entry) {
          final area = entry.key;
          final values = entry.value;

          return DataRow(
            cells: [
              DataCell(
                SizedBox(
                  width: 170,
                  child: Text(
                    area,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ...riskCols.map((risk) {
                final value = values[risk] ?? 0;
                return DataCell(_heatCell(risk, value));
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _heatCell(String risk, int value) {
    final color = _riskSolidColor(risk);
    final opacity = value <= 0
        ? 0.08
        : value == 1
            ? 0.18
            : value == 2
                ? 0.30
                : value == 3
                    ? 0.45
                    : 0.60;

    return Container(
      alignment: Alignment.center,
      width: 54,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: _textDark,
        ),
      ),
    );
  }
}

class _Nom035AssetPdfScreen extends StatelessWidget {
  final String title;
  final String assetPath;

  const _Nom035AssetPdfScreen({
    required this.title,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _Nom035AuditScreenState._primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.asset(assetPath),
    );
  }
}