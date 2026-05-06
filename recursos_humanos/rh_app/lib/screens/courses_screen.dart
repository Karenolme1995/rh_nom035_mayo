import 'package:flutter/material.dart';
import '../services/notices_service.dart';
import 'package:rh_app/screens/quiz_intro_screen.dart';
import 'package:rh_app/screens/quiz_result_screen.dart';

// NOM-035 STPS --->
import 'package:rh_app/screens/nom035_admin_questions_screen.dart';
import 'package:rh_app/screens/nom035_admin_cycles_screen.dart';
import 'package:rh_app/screens/nom035_admin_preview_screen.dart';

class CoursesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int? initialTabIndex;

  const CoursesScreen({
    super.key,
    required this.userData,
    this.initialTabIndex,
  });

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> available = [];
  List<Map<String, dynamic>> completed = [];

  int get roleId => int.tryParse('${widget.userData['role_id'] ?? 3}') ?? 3;
  bool get isAdmin => roleId == 1 || roleId == 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isCompletedLikeStatus(String status) {
    final s = status.toLowerCase().trim();
    return s == 'submitted' ||
        s == 'reviewed' ||
        s == 'closed' ||
        s == 'inactive' ||
        s == 'disabled' ||
        s == 'completed' ||
        s == 'concluded';
  }

  String _uniqueKey(Map<String, dynamic> item) {
    final submissionId = item['submission_id']?.toString() ?? '';
    final formId = item['form_id']?.toString() ?? '';
    final type = item['type']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    return '$submissionId|$formId|$type|$title';
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final availableForms = await NoticesService.getAvailableForms();
      final completedForms = await NoticesService.getCompletedForms();

      if (!mounted) return;

      final forcedCompleted = availableForms.where((f) {
        final status = (f['status'] ?? '').toString();
        return _isCompletedLikeStatus(status);
      }).toList();

      final realAvailable = availableForms.where((f) {
        final status = (f['status'] ?? '').toString();
        return !_isCompletedLikeStatus(status);
      }).toList();

      final mergedCompleted = [
        ...completedForms,
        ...forcedCompleted,
      ];

      final Map<String, Map<String, dynamic>> uniqueCompleted = {};
      for (final item in mergedCompleted) {
        uniqueCompleted[_uniqueKey(item)] = item;
      }

      setState(() {
        available = realAvailable;
        completed = uniqueCompleted.values.toList();
        loading = false;
      });

      _showUrgentReminderIfNeeded();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _showUrgentReminderIfNeeded() {
    final now = DateTime.now();

    final urgentForms = available.where((f) {
      final status = (f['status'] ?? '').toString().toLowerCase();
      final dueAt = _parseDate(f['due_at']);

      if (dueAt == null) return false;
      if (status != 'available') return false;

      final diff = dueAt.difference(now).inDays;
      return diff <= 5 && diff >= 0;
    }).toList();

    if (urgentForms.isEmpty || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tienes cuestionarios próximos a vencer. Debes contestarlos.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'submitted':
      case 'completed':
      case 'concluded':
      case 'closed':
      case 'inactive':
      case 'disabled':
        return 'Concluido';
      case 'reviewed':
        return 'Revisado';
      case 'in_progress':
        return 'En curso';
      case 'available':
        return 'Disponible';
      case 'draft':
        return 'Borrador';
      case 'active':
        return 'Activo';
      default:
        return s.isEmpty ? 'Sin estatus' : s;
    }
  }

  String _displayTitle(String type, String title) {
    if (type.toLowerCase() == 'nom035') {
      return 'GUIA DE REFERENCIA NOM 035-STPS';
    }
    return title.isEmpty ? 'Cuestionario' : title;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _daysLeftLabel(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now);

    if (diff.inSeconds <= 0) {
      return 'Vencido';
    }

    if (diff.inHours < 24) {
      final hrs = diff.inHours;
      final mins = diff.inMinutes % 60;
      if (hrs <= 0) return 'Vence en $mins min';
      return 'Vence en ${hrs}h ${mins}m';
    }

    final days = (diff.inHours / 24).ceil();
    return 'Faltan $days día${days == 1 ? '' : 's'}';
  }

  Widget _buildCourseHeader(String title, int? year) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (year != null)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Text(
              '$year',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final label = _statusLabel(status);
    final s = status.toLowerCase();

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (s) {
      case 'submitted':
      case 'completed':
      case 'concluded':
      case 'closed':
      case 'inactive':
      case 'disabled':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_outline;
        break;
      case 'reviewed':
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade800;
        icon = Icons.verified_outlined;
        break;
      case 'in_progress':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.pending_actions_outlined;
        break;
      case 'available':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.play_circle_outline;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
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
                  )
                : DefaultTabController(
                    length: 2,
                    initialIndex: widget.initialTabIndex ?? 0,
                    child: Column(
                      children: [
                        isAdmin
                            ? _adminNom035Card(context)
                            : _coursesWelcomeCard(),
                        TabBar(
                          isScrollable: true,
                          tabs: [
                            Tab(text: 'Pendientes (${available.length})'),
                            Tab(text: 'Concluidos (${completed.length})'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _availableList(),
                              _completedList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _adminNom035Card(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: isSmallScreen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 28),
                    const SizedBox(height: 10),
                    const Text(
                      'Bienvenido a la sección de cursos.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'En este espacio se encuentran disponibles los programas de capacitación proporcionados por la empresa, diseñados para fortalecer sus conocimientos, habilidades y desempeño dentro de la organización.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Cada curso ha sido estructurado para facilitar la comprensión de los contenidos y contribuir al cumplimiento de los objetivos institucionales.',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Nom035AdminQuestionsScreen(
                                  userData: widget.userData,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.list_alt),
                          label: const Text('Preguntas (Admin)'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Nom035AdminPreviewScreen(
                                  userData: widget.userData,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.preview),
                          label: const Text('Vista previa guía'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Nom035AdminCyclesScreen(
                                  userData: widget.userData,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.event_note),
                          label: const Text('Ciclos (Admin)'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenido a la sección de cursos.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'En este espacio se encuentran disponibles los programas de capacitación proporcionados por la empresa, diseñados para fortalecer sus conocimientos, habilidades y desempeño dentro de la organización.',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cada curso ha sido estructurado para facilitar la comprensión de los contenidos y contribuir al cumplimiento de los objetivos institucionales.',
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Nom035AdminQuestionsScreen(
                                        userData: widget.userData,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.list_alt),
                                label: const Text('Preguntas (Admin)'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Nom035AdminPreviewScreen(
                                        userData: widget.userData,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.preview),
                                label: const Text('Vista previa guía'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Nom035AdminCyclesScreen(
                                        userData: widget.userData,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.event_note),
                                label: const Text('Ciclos (Admin)'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _coursesWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.menu_book_outlined, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Bienvenido a la sección de cursos.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'En este espacio se encuentran disponibles los programas de capacitación proporcionados por la empresa, diseñados para fortalecer sus conocimientos, habilidades y desempeño dentro de la organización.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Cada curso ha sido estructurado para facilitar la comprensión de los contenidos y contribuir al cumplimiento de los objetivos institucionales.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _availableList() {
    if (available.isEmpty) {
      return const Center(child: Text('No hay cuestionarios disponibles.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: available.length,
        itemBuilder: (context, i) {
          final f = available[i];

          final rawTitle = (f['title'] ?? '').toString();
          final type = (f['type'] ?? 'quiz').toString();
          final title = _displayTitle(type, rawTitle);

          final formId = f['form_id'];
          final status = (f['status'] ?? '').toString();
          final startAt = _parseDate(f['start_at']);
          final dueAt = _parseDate(f['due_at']);

          final year = startAt?.year ?? dueAt?.year;
          final dueLabel = dueAt != null ? _daysLeftLabel(dueAt) : '';

          bool showUrgent = false;

          if (dueAt != null && status.toLowerCase() == 'available') {
            final diff = dueAt.difference(DateTime.now());
            final days = diff.inDays;

            if (days <= 5 && days >= 0) {
              showUrgent = true;
            }
          }

          final cardColor = showUrgent ? Colors.red.shade50 : null;
          final cardBorderColor =
              showUrgent ? Colors.red.shade200 : Colors.transparent;

          return Card(
            elevation: 1.5,
            margin: const EdgeInsets.only(bottom: 12),
            color: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: cardBorderColor,
                width: showUrgent ? 1.2 : 0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseHeader(title, year),
                  const SizedBox(height: 10),
                  _buildStatusChip(status),
                  const SizedBox(height: 12),
                  Text('Tipo: $type'),
                  if (startAt != null) Text('Inicio: ${_formatDate(startAt)}'),
                  if (dueAt != null)
                    Text('Fecha límite: ${_formatDate(dueAt)}'),
                  if (dueLabel.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dueLabel,
                      style: TextStyle(
                        color: dueLabel == 'Vencido'
                            ? Colors.red
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (showUrgent) ...[
                    const SizedBox(height: 6),
                    Text(
                      '⚠️ Debes contestar este cuestionario',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        icon: Icon(
                          status.toLowerCase() == 'in_progress'
                              ? Icons.play_arrow
                              : Icons.login,
                          size: 16,
                        ),
                        label: Text(
                          status.toLowerCase() == 'in_progress'
                              ? 'Continuar'
                              : 'Iniciar',
                        ),
                        onPressed: () async {
                          try {
                            final started = await NoticesService.startFormByType(
                              formId,
                              type: type,
                            );

                            final submissionId = started['submission_id'];

                            final detail =
                                await NoticesService.getFormDetailByType(
                              formId,
                              type: type,
                            );

                            if (!mounted) return;

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizIntroScreen(
                                  userData: widget.userData,
                                  formDetail: detail,
                                  submissionId: submissionId,
                                ),
                              ),
                            );

                            await _load();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No se pudo abrir el curso: $e'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _completedList() {
    if (completed.isEmpty) {
      return const Center(child: Text('Aún no has concluido evaluaciones.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: completed.length,
      itemBuilder: (context, i) {
        final r = completed[i];

        final rawTitle = (r['title'] ?? '').toString();
        final submissionId = r['submission_id'];
        final type = (r['type'] ?? 'quiz').toString();
        final status = (r['status'] ?? '').toString();
        final dueAt = _parseDate(r['due_at']);
        final startAt = _parseDate(r['start_at']);
        final submittedDate = _parseDate(r['submitted_at']);

        final year = startAt?.year ?? dueAt?.year ?? submittedDate?.year;

        final displayTitle = _displayTitle(type, rawTitle);
        final isNom035 = type.toLowerCase() == 'nom035';

        return Card(
          elevation: 1.5,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseHeader(displayTitle, year),
                const SizedBox(height: 10),
                _buildStatusChip(status),
                const SizedBox(height: 12),
                Text('Tipo: $type'),
                if (submittedDate != null)
                  Text('Realizado: ${_formatDate(submittedDate)}'),
                if (dueAt != null)
                  Text('Cierre del ciclo: ${_formatDate(dueAt)}'),
                const SizedBox(height: 12),
                if (isAdmin && !isNom035 && submissionId != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizResultScreen(
                              submissionId: submissionId,
                              userData: widget.userData,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Ver evaluación'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}