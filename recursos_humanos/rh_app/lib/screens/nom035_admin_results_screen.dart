//Nom035AdminResultsScreen
import 'package:flutter/material.dart';
import '../services/notices_service.dart';

class Nom035AdminResultsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const Nom035AdminResultsScreen({super.key, required this.userData});

  @override
  State<Nom035AdminResultsScreen> createState() => _Nom035AdminResultsScreenState();
}

class _Nom035AdminResultsScreenState extends State<Nom035AdminResultsScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> cycles = [];
  int? cycleId;

  bool loadingSubs = false;
  Map<String, dynamic>? subsResp;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final c = await NoticesService.adminGetCycles();

      int? defaultCycle;
      if (c.isNotEmpty) {
        final active = c.where((x) => (x['status'] ?? '').toString() == 'active').toList();
        final pick = active.isNotEmpty ? active.first : c.first;
        defaultCycle = int.tryParse('${pick['id']}');
      }

      setState(() {
        cycles = c;
        cycleId = defaultCycle;
        loading = false;
      });

      if (cycleId != null) {
        await _loadSubmissions();
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadSubmissions() async {
    if (cycleId == null) return;

    setState(() {
      loadingSubs = true;
      subsResp = null;
    });

    try {
      final resp = await NoticesService.adminNom035GetCycleSubmissions(
        cycleId: cycleId!,
        page: 1,
        pageSize: 200,
      );

      setState(() {
        subsResp = resp;
        loadingSubs = false;
      });
    } catch (e) {
      setState(() {
        loadingSubs = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando resultados: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _answeredItems {
    final r = subsResp;
    if (r == null) return [];

    final raw = r['items'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  List<Map<String, dynamic>> get _pendingItems {
    final r = subsResp;
    if (r == null) return [];

    final raw = r['pending_users'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<void> _openDetail(int submissionId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final d = await NoticesService.adminNom035GetSubmissionDetail(
        submissionId: submissionId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 950,
            height: 700,
            child: _SubmissionReadonlyView(detail: d),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error detalle: $e')),
      );
    }
  }

  Future<void> _exportPdf(int submissionId) async {
    try {
      final bytes = await NoticesService.adminNom035ExportSubmission(
        submissionId: submissionId,
        format: 'pdf',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generado correctamente (${bytes.length} bytes).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exportando PDF: $e')),
      );
    }
  }

  String _safeText(dynamic v) => (v ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resultados NOM-035 (Admin)')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error:\n$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadCycles,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final answered = _answeredItems;
    final pending = _pendingItems;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultados NOM-035 (Admin)'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Contestados (${answered.length})'),
              Tab(text: 'Pendientes (${pending.length})'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: cycleId,
                      items: cycles.map((c) {
                        final id = int.tryParse('${c['id']}') ?? 0;
                        final title = (c['title'] ?? 'Ciclo $id').toString();
                        final st = (c['status'] ?? '').toString();
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('$title ${st.isEmpty ? '' : '($st)'}'),
                        );
                      }).toList(),
                      onChanged: (v) async {
                        setState(() => cycleId = v);
                        await _loadSubmissions();
                      },
                      decoration: const InputDecoration(
                        labelText: 'Selecciona ciclo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: loadingSubs ? null : _loadSubmissions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: loadingSubs
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        answered.isEmpty
                            ? const Center(child: Text('No hay usuarios que hayan contestado en este ciclo.'))
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                itemCount: answered.length,
                                itemBuilder: (context, i) {
                                  final r = answered[i];
                                  final submissionId = int.tryParse('${r['submission_id'] ?? 0}') ?? 0;
                                  final user = Map<String, dynamic>.from((r['user'] ?? {}) as Map);
                                  final userName = _safeText(user['name']).isEmpty ? 'Usuario' : _safeText(user['name']);
                                  final employee = _safeText(user['employee_number']);
                                  final area = _safeText(user['area']);
                                  final position = _safeText(user['position']);
                                  final status = _safeText(r['status']);
                                  final risk = _safeText(r['risk_level']);
                                  final score = r['score_total'];
                                  final submittedAt = _safeText(r['submitted_at']);

                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      userName,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (employee.isNotEmpty) Text('No. empleado: $employee'),
                                                    if (area.isNotEmpty) Text('Área: $area'),
                                                    if (position.isNotEmpty) Text('Puesto: $position'),
                                                    if (submittedAt.isNotEmpty) Text('Respondió: $submittedAt'),
                                                  ],
                                                ),
                                              ),
                                              _statusChip(status),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'Score: ${score ?? '—'}',
                                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: _riskBg(risk),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    'Riesgo: ${risk.isEmpty ? '—' : risk}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: _riskFg(risk),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: submissionId == 0 ? null : () => _openDetail(submissionId),
                                                  icon: const Icon(Icons.visibility),
                                                  label: const Text('Ver respuestas'),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: submissionId == 0 ? null : () => _exportPdf(submissionId),
                                                  icon: const Icon(Icons.picture_as_pdf),
                                                  label: const Text('Exportar PDF'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        pending.isEmpty
                            ? const Center(child: Text('Todos los usuarios ya contestaron este ciclo.'))
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                itemCount: pending.length,
                                itemBuilder: (context, i) {
                                  final u = pending[i];
                                  final name = _safeText(u['name']).isEmpty ? 'Usuario' : _safeText(u['name']);
                                  final employee = _safeText(u['employee_number']);
                                  final area = _safeText(u['area']);
                                  final position = _safeText(u['position']);

                                  return Card(
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.person_outline),
                                      ),
                                      title: Text(name),
                                      subtitle: Text(
                                        [
                                          if (employee.isNotEmpty) 'No. empleado: $employee',
                                          if (area.isNotEmpty) 'Área: $area',
                                          if (position.isNotEmpty) 'Puesto: $position',
                                        ].join('\n'),
                                      ),
                                      isThreeLine: true,
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Pendiente',
                                          style: TextStyle(
                                            color: Colors.orange.shade900,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text) {
    final t = text.toLowerCase();
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade900;

    if (t.contains('submitted')) {
      bg = Colors.green.shade100;
      fg = Colors.green.shade900;
    } else if (t.contains('in_progress')) {
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade900;
    } else if (t.contains('available')) {
      bg = Colors.blueGrey.shade100;
      fg = Colors.blueGrey.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _riskBg(String risk) {
    final r = risk.toLowerCase();
    if (r.contains('muy alto')) return Colors.red.shade100;
    if (r.contains('alto')) return Colors.orange.shade100;
    if (r.contains('medio')) return Colors.amber.shade100;
    if (r.contains('bajo')) return Colors.green.shade100;
    return Colors.grey.shade200;
  }

  Color _riskFg(String risk) {
    final r = risk.toLowerCase();
    if (r.contains('muy alto')) return Colors.red.shade900;
    if (r.contains('alto')) return Colors.orange.shade900;
    if (r.contains('medio')) return Colors.amber.shade900;
    if (r.contains('bajo')) return Colors.green.shade900;
    return Colors.grey.shade900;
  }
}

class _SubmissionReadonlyView extends StatelessWidget {
  final Map<String, dynamic> detail;

  const _SubmissionReadonlyView({required this.detail});

  String _safe(dynamic v) => (v ?? '').toString();

  @override
  Widget build(BuildContext context) {
    final submission = Map<String, dynamic>.from((detail['submission'] ?? {}) as Map);
    final cycle = Map<String, dynamic>.from((detail['cycle'] ?? {}) as Map);
    final user = Map<String, dynamic>.from((detail['user'] ?? {}) as Map);

    final rawSections = (detail['sections'] ?? []) as List;
    final sections = rawSections.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Detalle de respuestas'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _safe(user['name']).isEmpty ? 'Usuario' : _safe(user['name']),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('No. empleado: ${_safe(user['employee_number'])}'),
                  Text('Área: ${_safe(user['area'])}'),
                  Text('Puesto: ${_safe(user['position'])}'),
                  Text('Ciclo: ${_safe(cycle['title'])}'),
                  Text('Score: ${_safe(submission['score_total'])}'),
                  Text('Riesgo: ${_safe(submission['risk_level'])}'),
                  Text('Respondió: ${_safe(submission['submitted_at'])}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          for (final sec in sections) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safe(sec['title']),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (_safe(sec['instructions']).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _safe(sec['instructions']),
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 10),

                    if (sec['questions'] is List)
                      ...((sec['questions'] as List).map((qAny) {
                        final q = Map<String, dynamic>.from(qAny as Map);
                        return _ReadonlyQuestionTile(q: q);
                      })),

                    if (sec['groups'] is List)
                      ...((sec['groups'] as List).map((gAny) {
                        final g = Map<String, dynamic>.from(gAny as Map);
                        final gQuestions = (g['questions'] ?? []) as List;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_safe(g['title']).isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                _safe(g['title']),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                            if (_safe(g['instructions']).isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _safe(g['instructions']),
                                style: const TextStyle(fontStyle: FontStyle.italic),
                              ),
                            ],
                            const SizedBox(height: 8),
                            ...gQuestions.map((qAny) {
                              final q = Map<String, dynamic>.from(qAny as Map);
                              return _ReadonlyQuestionTile(q: q);
                            }),
                          ],
                        );
                      })),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ]
        ],
      ),
    );
  }
}

class _ReadonlyQuestionTile extends StatelessWidget {
  final Map<String, dynamic> q;

  const _ReadonlyQuestionTile({required this.q});

  String _safe(dynamic v) => (v ?? '').toString();

  String _answerText(Map<String, dynamic> q) {
    final answer = _safe(q['answer_value']);
    final optionsRaw = q['options'];

    if (optionsRaw is List) {
      for (final item in optionsRaw) {
        if (item is Map) {
          final id = '${item['id'] ?? ''}';
          final text = '${item['option_text'] ?? ''}';
          if (id == answer) {
            return text;
          }
        }
      }
    }

    return answer.isEmpty ? 'Sin respuesta' : answer;
  }

  @override
  Widget build(BuildContext context) {
    final questionText = _safe(q['question_text']);
    final answerText = _answerText(q);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            answerText,
            style: TextStyle(color: Colors.blueGrey.shade900),
          ),
        ],
      ),
    );
  }
}