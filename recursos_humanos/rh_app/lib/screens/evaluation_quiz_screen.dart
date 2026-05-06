import 'package:flutter/material.dart';
import '../services/notices_service.dart';

class EvaluationQuizScreen extends StatefulWidget {
  final int evaluationId;
  final int submissionId;

  const EvaluationQuizScreen({
    super.key,
    required this.evaluationId,
    required this.submissionId,
  });

  @override
  State<EvaluationQuizScreen> createState() => _EvaluationQuizScreenState();
}

class _EvaluationQuizScreenState extends State<EvaluationQuizScreen> {
  bool loading = true;

  List<Map<String, dynamic>> sections = [];

  /// respuestas: question_id -> valor
  final Map<int, dynamic> answers = {};

  @override
  void initState() {
    super.initState();
    loadEvaluation();
  }

  Future<void> loadEvaluation() async {
    try {
      final data = await NoticesService.getEvaluationDetail(
        widget.evaluationId,
      );

      setState(() {
        sections = List<Map<String, dynamic>>.from(data['sections'] ?? []);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando evaluación: $e')),
      );
    }
  }

  Future<void> submit() async {
    // Validación
    for (final section in sections) {
      final questions =
          List<Map<String, dynamic>>.from(section['questions'] ?? []);

      for (final q in questions) {
        final qId = int.parse('${q['id']}');

        if ((q['is_required'] == 1 || q['is_required'] == true) &&
            answers[qId] == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Falta responder: ${q['question_text']}',
              ),
            ),
          );
          return;
        }
      }
    }

    try {
      await NoticesService.submitEvaluationAnswers(
        widget.submissionId,
        answers,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación enviada')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enviando: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluación'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ...sections.map((section) {
                  return _buildSection(section, isDark);
                }).toList(),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: submit,
        label: const Text('Enviar'),
        icon: const Icon(Icons.send),
      ),
    );
  }

  Widget _buildSection(Map<String, dynamic> section, bool isDark) {
    final questions =
        List<Map<String, dynamic>>.from(section['questions'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section['title'] ?? 'Sección',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ...questions.map((q) => _buildQuestion(q)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> q) {
    final qId = int.parse('${q['id']}');
    final type = q['question_type'];
    final options = List<Map<String, dynamic>>.from(q['options'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q['question_text'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),

        /// SINGLE
        if (type == 'single')
          ...options.map((opt) {
            return RadioListTile(
              value: opt['id'],
              groupValue: answers[qId],
              onChanged: (v) {
                setState(() {
                  answers[qId] = v;
                });
              },
              title: Text(opt['option_text']),
            );
          }),

        /// MULTI
        if (type == 'multi')
          ...options.map((opt) {
            final selected =
                (answers[qId] ?? <int>[]).contains(opt['id']);

            return CheckboxListTile(
              value: selected,
              onChanged: (v) {
                setState(() {
                  final list =
                      List<int>.from(answers[qId] ?? []);

                  if (v == true) {
                    list.add(opt['id']);
                  } else {
                    list.remove(opt['id']);
                  }

                  answers[qId] = list;
                });
              },
              title: Text(opt['option_text']),
            );
          }),

        /// YES NO
        if (type == 'yes_no')
          Row(
            children: [
              Expanded(
                child: RadioListTile(
                  value: 1,
                  groupValue: answers[qId],
                  onChanged: (v) {
                    setState(() => answers[qId] = v);
                  },
                  title: const Text('Sí'),
                ),
              ),
              Expanded(
                child: RadioListTile(
                  value: 0,
                  groupValue: answers[qId],
                  onChanged: (v) {
                    setState(() => answers[qId] = v);
                  },
                  title: const Text('No'),
                ),
              ),
            ],
          ),

        /// TEXT
        if (type == 'text')
          TextField(
            onChanged: (v) {
              answers[qId] = v;
            },
            decoration: const InputDecoration(
              hintText: 'Escribe tu respuesta',
            ),
          ),

        const SizedBox(height: 10),
      ],
    );
  }
}