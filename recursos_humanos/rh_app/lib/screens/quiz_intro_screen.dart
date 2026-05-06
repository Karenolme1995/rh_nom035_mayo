// lib/screens/quiz_intro_screen.dart
// Pantalla de introducción antes de responder el cuestionario.

import 'package:flutter/material.dart';
import 'package:rh_app/screens/quiz_runner_screen.dart';
import 'package:rh_app/screens/quiz_result_screen.dart';
import 'package:rh_app/services/notices_service.dart';

class QuizIntroScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> formDetail;
  final int submissionId;

  const QuizIntroScreen({
    super.key,
    required this.userData,
    required this.formDetail,
    required this.submissionId,
  });

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  String _areaName = '—';
  String _positionName = '—';

  /// true = muestra contenido extendido
  bool _showMoreNom035 = true;

  String _s(dynamic v) => (v == null) ? '' : v.toString();

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  int _countQuestions(Map<String, dynamic> detail) {
    final q1 = detail['questions'];
    if (q1 is List) return q1.length;

    final form = detail['form'];
    if (form is Map && form['questions'] is List) {
      return (form['questions'] as List).length;
    }

    final secs = detail['sections'];
    if (secs is List) {
      int total = 0;
      for (final s in secs) {
        if (s is Map && s['questions'] is List) {
          total += (s['questions'] as List).length;
        }
      }
      if (total > 0) return total;
    }

    return 0;
  }

  Future<void> _loadCatalogNames() async {
    try {
      final user = widget.userData;

      dynamic areaVal = user['area'] ??
          user['area_id'] ??
          user['areaId'] ??
          user['area_name'] ??
          user['areaName'];

      dynamic posVal = user['position'] ??
          user['position_id'] ??
          user['positionId'] ??
          user['position_name'] ??
          user['positionName'];

      if (areaVal is Map) {
        areaVal = areaVal['id'] ??
            areaVal['area_id'] ??
            areaVal['name'] ??
            areaVal['area_name'];
      }

      if (posVal is Map) {
        posVal = posVal['id'] ??
            posVal['position_id'] ??
            posVal['name'] ??
            posVal['position_name'];
      }

      final areaRaw = _s(areaVal).trim();
      final posRaw = _s(posVal).trim();

      final looksLikeIdArea = int.tryParse(areaRaw) != null;
      final looksLikeIdPos = int.tryParse(posRaw) != null;

      if (!looksLikeIdArea && areaRaw.isNotEmpty) _areaName = areaRaw;
      if (!looksLikeIdPos && posRaw.isNotEmpty) _positionName = posRaw;

      if (looksLikeIdArea || looksLikeIdPos) {
        final areaId = _asInt(areaVal);
        final positionId = _asInt(posVal);

        final areasMap = await NoticesService().getAreasMap();
        final posMap = await NoticesService().getPositionsMap();

        final aName = areasMap[areaId];
        final pName = posMap[positionId];

        if (!mounted) return;
        setState(() {
          _areaName = (aName == null || aName.trim().isEmpty) ? '—' : aName;
          _positionName =
              (pName == null || pName.trim().isEmpty) ? '—' : pName;
        });
      } else {
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint('No se pudieron cargar catálogos (áreas/puestos): $e');

      final user = widget.userData;

      dynamic areaVal = user['area'] ??
          user['area_id'] ??
          user['areaId'] ??
          user['area_name'] ??
          user['areaName'];

      dynamic posVal = user['position'] ??
          user['position_id'] ??
          user['positionId'] ??
          user['position_name'] ??
          user['positionName'];

      if (areaVal is Map) {
        areaVal = areaVal['name'] ??
            areaVal['area_name'] ??
            areaVal['id'] ??
            areaVal['area_id'];
      }

      if (posVal is Map) {
        posVal = posVal['name'] ??
            posVal['position_name'] ??
            posVal['id'] ??
            posVal['position_id'];
      }

      final areaRaw = _s(areaVal).trim();
      final posRaw = _s(posVal).trim();

      if (!mounted) return;
      setState(() {
        if (areaRaw.isNotEmpty) {
          _areaName = int.tryParse(areaRaw) != null ? 'ID: $areaRaw' : areaRaw;
        }
        if (posRaw.isNotEmpty) {
          _positionName = int.tryParse(posRaw) != null ? 'ID: $posRaw' : posRaw;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCatalogNames();
  }

  void _handleStart(String formType) {
    final status = (widget.formDetail['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final lockedRaw = widget.formDetail['locked'];
    final locked = lockedRaw == 1 || lockedRaw == true || '$lockedRaw' == '1';

    if (status == 'submitted' || locked) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            submissionId: widget.submissionId,
            userData: widget.userData,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizRunnerScreen(
          userData: widget.userData,
          formDetail: widget.formDetail,
          submissionId: widget.submissionId,
          formType: formType,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard({
    required BuildContext context,
    required String name,
    required String emp,
    required String position,
    required String area,
    required DateTime now,
    required String formType,
    required int totalQuestions,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 1 : 3,
      color: theme.cardColor,
      shadowColor: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER CON ICONO DE USUARIO
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Datos del empleado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text('Nombre: $name', style: theme.textTheme.bodyMedium),
            Text('No. empleado: $emp', style: theme.textTheme.bodyMedium),
            Text('Puesto: $position', style: theme.textTheme.bodyMedium),
            Text('Área: $area', style: theme.textTheme.bodyMedium),
            Text(
              'Fecha/Hora inicio: ${now.toString()}',
              style: theme.textTheme.bodyMedium,
            ),

            if (formType.isNotEmpty)
              Text('Tipo: $formType', style: theme.textTheme.bodyMedium),

            if (totalQuestions > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Total de preguntas: $totalQuestions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 1 : 4,
      color: theme.cardColor,
      shadowColor: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule_folder_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Recomendaciones antes de comenzar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _tipItem(
              context,
              Icons.check_circle_outline,
              'Lee cada pregunta con calma antes de responder.',
            ),
            _tipItem(
              context,
              Icons.check_circle_outline,
              'Contesta con sinceridad para obtener resultados más útiles.',
            ),
            _tipItem(
              context,
              Icons.check_circle_outline,
              'Procura responder en un lugar tranquilo y sin interrupciones.',
            ),
            _tipItem(
              context,
              Icons.check_circle_outline,
              'Verifica que tus datos mostrados sean correctos antes de iniciar.',
            ),
            _tipItem(
              context,
              Icons.check_circle_outline,
              'Recuerda que este cuestionario ayuda a identificar factores de riesgo psicosocial en el trabajo.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedNom035Card(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color cardBg = isDark
        ? const Color(0xFF162033)
        : const Color(0xFFF2F7FF);

    final Color cardBorder = isDark
        ? cs.primary.withOpacity(0.28)
        : cs.primary.withOpacity(0.18);

    final Color iconBox = isDark
        ? cs.primary.withOpacity(0.16)
        : cs.primary.withOpacity(0.10);

    final Color infoBox = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.82);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: isDark ? 2 : 6,
        shadowColor: Colors.black.withOpacity(isDark ? 0.30 : 0.18),
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: iconBox,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.health_and_safety_outlined,
                      color: cs.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOM-035-STPS',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Norma oficial mexicana orientada a identificar, analizar y prevenir factores de riesgo psicosocial en el trabajo.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface,
                            height: 1.38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: infoBox,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Su propósito es promover un entorno organizacional favorable, prevenir el estrés laboral y proteger la salud emocional del personal.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 280),
                crossFadeState: _showMoreNom035
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen de la norma',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La NOM-035-STPS permite detectar condiciones laborales que podrían afectar el bienestar de las y los trabajadores, como cargas excesivas de trabajo, falta de control sobre las actividades, jornadas extensas, violencia laboral o experiencias traumáticas severas.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'También impulsa acciones para mejorar el ambiente de trabajo, fortalecer la comunicación, disminuir factores de tensión y fomentar prácticas organizacionales más saludables.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Responder este cuestionario ayuda a la empresa a conocer áreas de oportunidad y a implementar medidas preventivas que favorezcan la seguridad, la salud y el desempeño laboral.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'En resumen, esta norma sirve para cuidar a las personas dentro del centro de trabajo y para construir un entorno más estable, respetuoso y productivo.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showMoreNom035 = !_showMoreNom035;
                    });
                  },
                  icon: Icon(
                    _showMoreNom035
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: cs.primary,
                  ),
                  label: Text(
                    'Ver más',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final form = Map<String, dynamic>.from(widget.formDetail['form'] ?? {});
    final title =
        (form['title'] ?? widget.formDetail['title'] ?? '').toString();
    final formType =
        (widget.formDetail['type'] ?? form['type'] ?? '').toString();

    final name = (widget.userData['name'] ?? '').toString();
    final emp = (widget.userData['employee_number'] ?? '').toString();
    final area = _areaName;
    final position = _positionName;
    final now = DateTime.now();
    final totalQuestions = _countQuestions(widget.formDetail);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instrucciones'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  Text(
                    title.isEmpty ? 'Cuestionario' : title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEmployeeCard(
                    context: context,
                    name: name,
                    emp: emp,
                    position: position,
                    area: area,
                    now: now,
                    formType: formType,
                    totalQuestions: totalQuestions,
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendationsCard(context),
                  const SizedBox(height: 16),
                  _buildAnimatedNom035Card(context),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleStart(formType),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'Comenzar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}