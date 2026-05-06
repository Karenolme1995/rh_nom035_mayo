// lib/screens/nom035_reference_screen.dart
import 'package:flutter/material.dart';
import '../services/notices_service.dart';
import 'package:rh_app/screens/quiz_intro_screen.dart';

class Nom035ReferenceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const Nom035ReferenceScreen({super.key, required this.userData});

  @override
  State<Nom035ReferenceScreen> createState() => _Nom035ReferenceScreenState();
}

class _Nom035ReferenceScreenState extends State<Nom035ReferenceScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> available = [];
  List<Map<String, dynamic>> completed = [];

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
      final a = await NoticesService.getNom035AvailableForms();
      final c = await NoticesService.getNom035CompletedForms();

      setState(() {
        available = a;
        completed = c;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOM-035 (Guía de referencia)'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _guideCard(),
                      const SizedBox(height: 12),
                      const Text('Pendientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (available.isEmpty)
                        const Text('No hay ciclos activos pendientes.'),
                      for (final f in available) _cycleCard(f, isCompleted: false),
                      const SizedBox(height: 14),
                      const Text('Concluidos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (completed.isEmpty)
                        const Text('Aún no has concluido un ciclo de NOM-035.'),
                      for (final f in completed) _cycleCard(f, isCompleted: true),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
    );
  }

    Widget _errorView() {
    return Center(
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
    );
  }

  Widget _guideCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.shield_outlined),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guía de referencia NOM-035-STPS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '• Se aplica por ciclo anual.\n'
              '• Una vez enviado el cuestionario queda bloqueado.\n'
              '• RH (roles 1 y 2) puede ver resultados globales.\n'
              '• Empleados (rol 3) solo ven sus resultados.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _cycleCard(Map<String, dynamic> f, {required bool isCompleted}) {
    final title = (f['title'] ?? 'NOM-035').toString();
    final dueAt = (f['due_at'] ?? '').toString();
    final status = (f['status'] ?? '').toString(); // available / in_progress / submitted
    final submissionId = f['submission_id'];
    final cycleId = int.parse('${f['form_id'] ?? f['cycle_id'] ?? 0}');

    final btnText = isCompleted
        ? 'Ver (bloqueado)'
        : (status == 'in_progress' ? 'Continuar' : 'Iniciar');

        return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            if (dueAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Fecha límite: $dueAt'),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isCompleted) {
                        // o a un result específico de NOM-035.
                        Navigator.pop(context);
                        return;
                      }

                      final started = await NoticesService.startNom035Form(cycleId);
                      final sid = started['submission_id'];
                      final detail = await NoticesService.getNom035FormDetail(cycleId);

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizIntroScreen(
                            userData: widget.userData,
                            formDetail: detail,
                            submissionId: sid,
                          ),
                        ),
                      );

                      await _load();
                    },
                    child: Text(btnText),
                  ),
                ),
                const SizedBox(width: 10),
                if (submissionId != null)
                  OutlinedButton(
                    onPressed: () async {
                      // Aquí podrías abrir una pantalla de resultado NOM035.
                      final r = await NoticesService.getNom035Result(int.parse('$submissionId'));
                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Resultado NOM-035'),
                          content: Text(
                            'Nivel: ${r['risk_level'] ?? '-'}\n'
                            'Score: ${r['score_total'] ?? '-'}\n'
                            'Obs: ${r['observations'] ?? ''}',
                          ),
                          actions: [
                            TextButton(onPressed: () {}, child: const Text('Cerrar')),
                          ],
                        ),
                      );
                    },
                    child: const Text('Resultado'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }


  
}


 