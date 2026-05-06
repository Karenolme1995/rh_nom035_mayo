import 'package:flutter/material.dart';

import '../services/notices_service.dart';
import 'evaluations_builder_screen.dart';
import 'evaluation_admin_submissions_screen.dart';
import 'evaluation_quiz_screen.dart';

class EvaluationsScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final int? roleId;

  const EvaluationsScreen({
    super.key,
    this.userData,
    this.roleId,
  });

  @override
  State<EvaluationsScreen> createState() => _EvaluationsScreenState();
}

class _EvaluationsScreenState extends State<EvaluationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _completed = [];
  List<Map<String, dynamic>> _areas = [];

  int? _selectedAreaId;
  String _selectedAreaName = 'Todas';

  bool get _isAdmin {
    final role = widget.roleId ??
        int.tryParse(
          '${widget.userData?['role_id'] ?? widget.userData?['roleId'] ?? 0}',
        );

    return role == 1 || role == 2;
  }

  List<Map<String, dynamic>> get _filteredPending => _filterByArea(_pending);

  List<Map<String, dynamic>> get _filteredCompleted =>
      _filterByArea(_completed);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isTrue(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _areaName(Map<String, dynamic> area) {
    return '${area['name'] ?? area['area'] ?? area['nombre'] ?? 'Área'}';
  }

  List<int> _extractIdList(dynamic value) {
    if (value is List) {
      return value
          .map((e) {
            if (e is Map) {
              return _asInt(e['id'] ?? e['area_id'] ?? e['position_id']);
            }
            return _asInt(e);
          })
          .where((e) => e > 0)
          .toList();
    }

    return <int>[];
  }

  List<Map<String, dynamic>> _filterByArea(List<Map<String, dynamic>> source) {
    if (!_isAdmin || _selectedAreaId == null) return source;

    return source.where((item) {
      final allAreas = _isTrue(item['all_areas']);
      if (allAreas) return true;

      final directAreaId = _asInt(item['area_id']);
      if (directAreaId == _selectedAreaId) return true;

      final areaIds = _extractIdList(item['area_ids']);
      if (areaIds.contains(_selectedAreaId)) return true;

      final areaName = '${item['area_name'] ?? item['area'] ?? ''}'
          .toLowerCase()
          .trim();

      final selectedName = _selectedAreaName.toLowerCase().trim();

      if (selectedName == 'todas') return true;
      if (areaName.isEmpty) return false;

      return areaName.contains(selectedName);
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {

        List<Map<String, dynamic>> pending = [];
        List<Map<String, dynamic>> completed = [];

        if (_isAdmin) {
        final all = await NoticesService.getAdminEvaluations();

        pending = all.where((e) => e['status'] != 'completed').toList();
        completed = all.where((e) => e['status'] == 'completed').toList();
        } else {
        pending = await NoticesService.getAvailableEvaluations();
        completed = await NoticesService.getCompletedEvaluations();
        }

      List<Map<String, dynamic>> areas = [];
      if (_isAdmin) {
        areas = await NoticesService.fetchAreas();
      }

      if (!mounted) return;

      setState(() {
        _pending = pending;
        _completed = completed;
        _areas = areas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openBuilder() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EvaluationsBuilderScreen(),
      ),
    );

    if (ok == true) {
      _loadData();
    }
  }

  Future<void> _editEvaluation(Map<String, dynamic> item) async {
    final evaluationId = int.tryParse('${item['evaluation_id'] ?? item['id']}');

    if (evaluationId == null) {
      _showSnack('No se encontró el ID de la evaluación.');
      return;
    }

    try {
      final detail = await NoticesService.getAdminEvaluationDetail(evaluationId);

      if (!mounted) return;

      final ok = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EvaluationsBuilderScreen(
            evaluationId: evaluationId,
            initialData: detail,
          ),
        ),
      );

      if (ok == true) {
        _loadData();
      }
    } catch (e) {
      _showSnack('Error al abrir edición: $e');
    }
  }

  Future<void> _toggleEvaluation(Map<String, dynamic> item) async {
    final evaluationId = int.tryParse('${item['evaluation_id'] ?? item['id']}');

    if (evaluationId == null) {
      _showSnack('No se encontró el ID de la evaluación.');
      return;
    }

    final current = item['is_active'];
    final isActive = _isTrue(current);

    try {
      await NoticesService.toggleEvaluationActive(evaluationId, !isActive);
      _showSnack(!isActive ? 'Evaluación activada.' : 'Evaluación desactivada.');
      _loadData();
    } catch (e) {
      _showSnack('Error cambiando estado: $e');
    }
  }

  Future<void> _deleteEvaluation(Map<String, dynamic> item) async {
    final evaluationId = int.tryParse('${item['evaluation_id'] ?? item['id']}');

    if (evaluationId == null) {
      _showSnack('No se encontró el ID de la evaluación.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evaluación'),
        content: const Text('¿Seguro que deseas eliminar esta evaluación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await NoticesService.deleteEvaluation(evaluationId);
      _showSnack('Evaluación eliminada.');
      _loadData();
    } catch (e) {
      _showSnack('Error eliminando evaluación: $e');
    }
  }

  Future<void> _openPendingEvaluation(Map<String, dynamic> item) async {
    final evaluationId = int.tryParse('${item['evaluation_id'] ?? item['id']}');

    if (evaluationId == null) {
      _showSnack('No se encontró el ID de la evaluación.');
      return;
    }

    if (_isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EvaluationAdminSubmissionsScreen(
            evaluationId: evaluationId,
            evaluationName:
                '${item['name'] ?? item['title'] ?? item['evaluation_name'] ?? 'Evaluación'}',
          ),
        ),
      );
      return;
    }

    try {
      final start = await NoticesService.startEvaluation(evaluationId);
      final submissionId = int.tryParse('${start['submission_id']}');

      if (submissionId == null) {
        _showSnack('No se pudo iniciar la evaluación.');
        return;
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EvaluationQuizScreen(
            evaluationId: evaluationId,
            submissionId: submissionId,
          ),
        ),
      ).then((_) => _loadData());
    } catch (e) {
      _showSnack('Error al abrir evaluación: $e');
    }
  }

  Future<void> _openCompletedEvaluation(Map<String, dynamic> item) async {
    if (_isAdmin) {
      final evaluationId =
          int.tryParse('${item['evaluation_id'] ?? item['id']}');

      if (evaluationId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EvaluationAdminSubmissionsScreen(
              evaluationId: evaluationId,
              evaluationName:
                  '${item['name'] ?? item['title'] ?? item['evaluation_name'] ?? 'Evaluación'}',
            ),
          ),
        );
      }
      return;
    }

    final submissionId = int.tryParse('${item['submission_id'] ?? item['id']}');

    if (submissionId == null) {
      _showSnack('No se encontró el resultado.');
      return;
    }

    try {
      final result = await NoticesService.getEvaluationResult(submissionId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resultado'),
          content: SingleChildScrollView(
            child: Text(
              'Evaluación: ${item['name'] ?? item['title'] ?? 'Evaluación'}\n'
              'Estado: ${item['status'] ?? '-'}\n'
              'Fecha: ${item['completed_at'] ?? item['submitted_at'] ?? '-'}\n'
              'Calificación: ${result['score'] ?? item['score'] ?? '-'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnack('Error al cargar resultado: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Evaluaciones'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.pending_actions),
              text: 'Pendientes',
            ),
            Tab(
              icon: Icon(Icons.check_circle_outline),
              text: 'Concluidos',
            ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openBuilder,
              icon: const Icon(Icons.add),
              label: const Text('Crear'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_isAdmin) _buildAreaFilter(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _EvaluationList(
                items: _filteredPending,
                emptyText: 'No tienes evaluaciones pendientes.',
                completed: false,
                isAdmin: _isAdmin,
                onTap: _openPendingEvaluation,
                onEdit: _editEvaluation,
                onToggle: _toggleEvaluation,
                onDelete: _deleteEvaluation,
              ),
              _EvaluationList(
                items: _filteredCompleted,
                emptyText: 'No tienes evaluaciones concluidas.',
                completed: true,
                isAdmin: _isAdmin,
                onTap: _openCompletedEvaluation,
                onEdit: _editEvaluation,
                onToggle: _toggleEvaluation,
                onDelete: _deleteEvaluation,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAreaFilter() {
    final safeAreas = _areas.where((a) => a.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<int?>(
            value: _selectedAreaId,
            decoration: const InputDecoration(
              labelText: 'Filtrar por área',
              prefixIcon: Icon(Icons.filter_alt_outlined),
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<int?>>[
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Todas las áreas'),
              ),
              ...safeAreas.map<DropdownMenuItem<int?>>((area) {
                final id = _asInt(area['id'] ?? area['area_id']);
                final name = _areaName(area);

                return DropdownMenuItem<int?>(
                  value: id,
                  child: Text(name),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedAreaId = value;

                if (value == null) {
                  _selectedAreaName = 'Todas';
                } else {
                  final found = safeAreas.firstWhere(
                    (a) => _asInt(a['id'] ?? a['area_id']) == value,
                    orElse: () => <String, dynamic>{},
                  );

                  _selectedAreaName = found.isEmpty ? '' : _areaName(found);
                }
              });
            },
          ),
        ),
      ),
    );
  }
}

class _EvaluationList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String emptyText;
  final bool completed;
  final bool isAdmin;
  final void Function(Map<String, dynamic> item) onTap;
  final Future<void> Function(Map<String, dynamic> item)? onEdit;
  final Future<void> Function(Map<String, dynamic> item)? onToggle;
  final Future<void> Function(Map<String, dynamic> item)? onDelete;

  const _EvaluationList({
    required this.items,
    required this.emptyText,
    required this.completed,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];

        return _EvaluationCard(
          item: item,
          completed: completed,
          isAdmin: isAdmin,
          onTap: () => onTap(item),
          onEdit: onEdit,
          onToggle: onToggle,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool completed;
  final bool isAdmin;
  final VoidCallback onTap;
  final Future<void> Function(Map<String, dynamic> item)? onEdit;
  final Future<void> Function(Map<String, dynamic> item)? onToggle;
  final Future<void> Function(Map<String, dynamic> item)? onDelete;

  const _EvaluationCard({
    required this.item,
    required this.completed,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onToggle,
    this.onDelete,
  });

  bool _isActiveValue(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  bool _isTrue(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title =
        '${item['name'] ?? item['title'] ?? item['evaluation_name'] ?? 'Evaluación'}';
    final type = '${item['type'] ?? 'general'}';
    final status = '${item['status'] ?? (completed ? 'completed' : 'pending')}';
    final score = item['score'];
    final completedAt = item['completed_at'] ?? item['submitted_at'];
    final createdAt = item['created_at'] ?? '-';

    final allAreas = _isTrue(item['all_areas']);
    final allPositions = _isTrue(item['all_positions']);

    final department = allAreas
        ? 'Todas las áreas'
        : '${item['area_name'] ?? item['department'] ?? item['area'] ?? 'Sin área'}';

    final positions = allPositions
        ? 'Todos los puestos'
        : '${item['position_name'] ?? item['position'] ?? 'Sin puesto'}';

    final isActive = _isActiveValue(item['is_active'] ?? 1);

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: completed
              ? Colors.green.withOpacity(0.15)
              : Theme.of(context).colorScheme.primary.withOpacity(0.15),
          child: Icon(
            completed ? Icons.check : Icons.assignment_outlined,
            color: completed
                ? Colors.green
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: isAdmin
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo: $type'),
                    Text('Área: $department'),
                    Text('Puesto: $positions'),
                    Text('Creado: $createdAt'),
                    const SizedBox(height: 4),
                    Text(
                      completed
                          ? 'Ver usuarios que contestaron y faltantes'
                          : 'Ver avance de usuarios',
                    ),
                  ],
                )
              : Text(
                  completed
                      ? 'Tipo: $type\nEstado: $status\nFecha: ${completedAt ?? '-'}\nCalificación: ${score ?? '-'}'
                      : 'Tipo: $type\nEstado: $status',
                ),
        ),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                icon: const Icon(Icons.settings),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call(item);
                      break;
                    case 'toggle':
                      onToggle?.call(item);
                      break;
                    case 'delete':
                      onDelete?.call(item);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 10),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.visibility_off : Icons.visibility,
                        ),
                        const SizedBox(width: 10),
                        Text(isActive ? 'Desactivar' : 'Activar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              )
            : Icon(
                completed ? Icons.visibility_outlined : Icons.arrow_forward_ios,
                size: 20,
              ),
        onTap: onTap,
      ),
    );
  }
}
