//QuizResultScreen
//consulta el detalle de una evaluación enviada
//muestra resultado, calificación y observaciones
import 'package:flutter/material.dart';
import 'package:rh_app/services/notices_service.dart';

class QuizResultScreen extends StatefulWidget {
  final int submissionId;
  final Map<String, dynamic> userData;

  const QuizResultScreen({
    super.key,
    required this.submissionId,
    required this.userData,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool loading = true;
  String? error;
  Map<String, dynamic>? data;

  int get roleId => int.tryParse('${widget.userData['role_id'] ?? 3}') ?? 3;
  bool get canSeeResults => roleId == 1 || roleId == 2;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      data = null;
    });
//print('Loading quiz result for submission ID: ${widget.submissionId}');
//print('User role ID: $roleId, can see results: $canSeeResults');

    try {
      final result = await NoticesService.getSubmissionDetail(widget.submissionId);

      if (!mounted) return;
      setState(() {
        data = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _statusLabel(String status) {
    switch (status) {
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

  String _displayTitle(Map<String, dynamic> d) {
    final title = (d['title'] ?? 'Evaluación').toString();
    final type = (d['type'] ?? '').toString().toLowerCase();

    if (type == 'nom035') {
      return title.isNotEmpty && title != 'Evaluación' ? title : 'NOM-035-2026';
    }

    return title;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evaluación')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error:\n$error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }

    final d = data ?? {};
    final title = _displayTitle(d);
    final status = (d['status'] ?? '').toString();
    final startedAt = (d['started_at'] ?? '').toString();
    final submittedAt = (d['submitted_at'] ?? '').toString();
    final reviewedAt = (d['reviewed_at'] ?? '').toString();
    final score = d['score'];
    final observations = (d['observations'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(canSeeResults ? 'Evaluación' : 'Cuestionario realizado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!canSeeResults) ...[
                      _row('Tipo', title),
                      if (submittedAt.isNotEmpty)
                        _row('Realizado', submittedAt)
                      else if (startedAt.isNotEmpty)
                        _row('Realizado', startedAt),
                      _row('Estatus', _statusLabel(status)),
                    ] else ...[
                      _row('Estado', _statusLabel(status)),
                      if (startedAt.isNotEmpty) _row('Iniciado', startedAt),
                      if (submittedAt.isNotEmpty) _row('Enviado', submittedAt),
                      if (reviewedAt.isNotEmpty) _row('Revisado', reviewedAt),
                    ],
                  ],
                ),
              ),
            ),

            if (canSeeResults) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resultado', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _row('Calificación', score == null ? 'Pendiente' : score.toString()),
                      const SizedBox(height: 8),
                      const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(observations.isEmpty ? 'Sin observaciones.' : observations),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}