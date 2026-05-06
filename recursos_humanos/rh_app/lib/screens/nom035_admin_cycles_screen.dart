import 'package:flutter/material.dart';
import '../services/notices_service.dart';
import 'nom035_admin_submissions_screen.dart';

class Nom035AdminCyclesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const Nom035AdminCyclesScreen({super.key, required this.userData});

  @override
  State<Nom035AdminCyclesScreen> createState() => _Nom035AdminCyclesScreenState();
}

class _Nom035AdminCyclesScreenState extends State<Nom035AdminCyclesScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> cycles = [];
  List<Map<String, dynamic>> questions = [];

  int get roleId => int.tryParse('${widget.userData['role_id'] ?? 3}') ?? 3;
  bool get isAdmin => roleId == 1 || roleId == 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final c = await NoticesService.adminGetCycles();
      final q = await NoticesService.adminGetQuestions();
      setState(() {
        cycles = c;
        questions = q;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _fmtDt(DateTime? dt) {
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:00';
  }

  DateTime? _parseDt(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;

    try {
      return DateTime.parse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  Future<DateTime?> _pickDateTime(BuildContext context, {DateTime? initial}) async {
    final now = DateTime.now();
    final base = initial ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(now.year),
      lastDate: DateTime(now.year + 10),
    );

    if (date == null) return null;
    if (!mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _confirmDeleteCycle(Map<String, dynamic> cycle) async {
    final id = int.tryParse('${cycle['id']}');
    final title = (cycle['title'] ?? 'NOM-035').toString();
    final year = (cycle['year'] ?? '').toString();

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar el ciclo.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar ciclo'),
        content: Text(
          '¿Estás seguro de eliminar el ciclo "$title${year.isNotEmpty ? ' ($year)' : ''}"?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await NoticesService.adminDeleteCycle(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ciclo eliminado correctamente')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar ciclo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return const Scaffold(
        body: Center(child: Text('No autorizado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOM-035 Ciclos (Admin)'),
        actions: [
          IconButton(
            onPressed: () => _openCycleEditor(null),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? Center(child: Text('Error:\n$error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cycles.length,
                    itemBuilder: (_, i) {
                      final c = cycles[i];
                      final id = c['id'];
                      final year = c['year'];
                      final title = (c['title'] ?? '').toString();
                      final status = (c['status'] ?? '').toString();
                      final startAt = (c['start_at'] ?? '').toString();
                      final dueAt = (c['due_at'] ?? '').toString();

                      return Card(
                        child: ListTile(
                          title: Text('$title ($year)'),
                          subtitle: Text(
                            'Estado: $status\nInicio: $startAt\nLímite: $dueAt',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'results') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Nom035AdminSubmissionsScreen(
                                      userData: widget.userData,
                                      cycleId: int.parse('$id'),
                                      cycleTitle: title.isNotEmpty ? title : 'NOM-035',
                                    ),
                                  ),
                                );
                              } else if (v == 'edit') {
                                _openCycleEditor(c);
                              } else if (v == 'questions') {
                                _openQuestionsPicker(int.parse('$id'));
                              } else if (v == 'delete') {
                                await _confirmDeleteCycle(c);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'results',
                                child: Text('Resultados (usuarios)'),
                              ),
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar ciclo'),
                              ),
                              PopupMenuItem(
                                value: 'questions',
                                child: Text('Asignar preguntas'),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar ciclo'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _openCycleEditor(Map<String, dynamic>? existing) async {
    final now = DateTime.now();
    final currentYear = now.year;
    final years = List.generate(11, (i) => currentYear + i);

    int selectedYear =
        int.tryParse('${existing?['year'] ?? currentYear}') ?? currentYear;

    final titleCtrl = TextEditingController(
      text: (existing?['title'] ?? 'NOM-035 $selectedYear').toString(),
    );

    DateTime? startDt = _parseDt(existing?['start_at']);
    DateTime? dueDt = _parseDt(existing?['due_at']);

    String selectedStatus = (existing?['status'] ?? 'draft').toString();
    if (!['draft', 'active', 'closed'].contains(selectedStatus)) {
      selectedStatus = 'draft';
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSB) {
          return AlertDialog(
            title: Text(existing == null ? 'Nuevo ciclo' : 'Editar ciclo'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Año',
                      border: OutlineInputBorder(),
                    ),
                    items: years
                        .map(
                          (y) => DropdownMenuItem<int>(
                            value: y,
                            child: Text('$y'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setSB(() {
                        selectedYear = v;
                        if (titleCtrl.text.trim().isEmpty ||
                            titleCtrl.text.startsWith('NOM-035 ')) {
                          titleCtrl.text = 'NOM-035 $selectedYear';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDateTime(context, initial: startDt);
                      if (picked == null) return;
                      setSB(() => startDt = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Inicio',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      child: Text(
                        startDt == null
                            ? 'Selecciona fecha y hora'
                            : _fmtDt(startDt),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await _pickDateTime(
                        context,
                        initial: dueDt ?? startDt,
                      );
                      if (picked == null) return;
                      setSB(() => dueDt = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Límite',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.event_available),
                      ),
                      child: Text(
                        dueDt == null
                            ? 'Selecciona fecha y hora'
                            : _fmtDt(dueDt),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('draft')),
                      DropdownMenuItem(value: 'active', child: Text('active')),
                      DropdownMenuItem(value: 'closed', child: Text('closed')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setSB(() => selectedStatus = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El título es obligatorio')),
                    );
                    return;
                  }

                  if (startDt == null || dueDt == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Selecciona inicio y límite')),
                    );
                    return;
                  }

                  if (dueDt!.isBefore(startDt!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La fecha límite no puede ser menor al inicio'),
                      ),
                    );
                    return;
                  }

                  final payload = <String, dynamic>{
                    'year': selectedYear,
                    'title': titleCtrl.text.trim(),
                    'start_at': _fmtDt(startDt),
                    'due_at': _fmtDt(dueDt),
                    'status': selectedStatus,
                  };

                  try {
                    if (existing == null) {
                      await NoticesService.adminCreateCycle(payload);
                    } else {
                      await NoticesService.adminUpdateCycle(
                        int.parse('${existing['id']}'),
                        payload,
                      );
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                    await _load();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openQuestionsPicker(int cycleId) async {
    final selected = <int>{};

    try {
      final detail = await NoticesService.getNom035FormDetail(cycleId);
      final sections = (detail['sections'] ?? []) as List;

      for (final secAny in sections) {
        final sec = (secAny is Map<String, dynamic>)
            ? secAny
            : Map<String, dynamic>.from(secAny as Map);

        final qs = (sec['questions'] ?? []) as List;
        for (final qAny in qs) {
          final q = (qAny is Map<String, dynamic>)
              ? qAny
              : Map<String, dynamic>.from(qAny as Map);
          final idAny = q['id'] ?? q['question_id'];
          if (idAny != null) selected.add(int.parse('$idAny'));
        }

        final groups = (sec['groups'] ?? []) as List;
        for (final gAny in groups) {
          final g = (gAny is Map<String, dynamic>)
              ? gAny
              : Map<String, dynamic>.from(gAny as Map);
          final gqs = (g['questions'] ?? []) as List;
          for (final qAny in gqs) {
            final q = (qAny is Map<String, dynamic>)
                ? qAny
                : Map<String, dynamic>.from(qAny as Map);
            final idAny = q['id'] ?? q['question_id'];
            if (idAny != null) selected.add(int.parse('$idAny'));
          }
        }
      }
    } catch (_) {}

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setSB) {
          final activeQuestions = questions
              .where((q) => (q['is_active'] ?? 1).toString() == '1')
              .toList();

          final allSelected = activeQuestions.isNotEmpty &&
              activeQuestions.every((q) => selected.contains(int.parse('${q['id']}')));

          return AlertDialog(
            title: Text('Asignar preguntas a ciclo $cycleId'),
            content: SizedBox(
              width: double.maxFinite,
              height: 460,
              child: Column(
                children: [
                  CheckboxListTile(
                    value: allSelected,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Seleccionar todas'),
                    onChanged: (v) {
                      setSB(() {
                        if (v == true) {
                          for (final q in activeQuestions) {
                            selected.add(int.parse('${q['id']}'));
                          }
                        } else {
                          for (final q in activeQuestions) {
                            selected.remove(int.parse('${q['id']}'));
                          }
                        }
                      });
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions.length,
                      itemBuilder: (_, i) {
                        final q = questions[i];
                        final id = int.parse('${q['id']}');
                        final text = (q['question_text'] ?? '').toString();
                        final guide = (q['guide'] ?? '').toString();
                        final active = (q['is_active'] ?? 1).toString() == '1';
                        if (!active) return const SizedBox.shrink();

                        return CheckboxListTile(
                          value: selected.contains(id),
                          onChanged: (v) => setSB(() {
                            if (v == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                          title: Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text('Guía: $guide'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await NoticesService.adminSetCycleQuestions(
                      cycleId: cycleId,
                      questionIds: selected.toList(),
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preguntas asignadas')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}