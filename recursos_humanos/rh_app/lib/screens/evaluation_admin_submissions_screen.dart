import 'package:flutter/material.dart';
import '../services/notices_service.dart';

class EvaluationAdminSubmissionsScreen extends StatefulWidget {
  final int evaluationId;
  final String evaluationName;

  const EvaluationAdminSubmissionsScreen({
    super.key,
    required this.evaluationId,
    required this.evaluationName,
  });

  @override
  State<EvaluationAdminSubmissionsScreen> createState() =>
      _EvaluationAdminSubmissionsScreenState();
}

class _EvaluationAdminSubmissionsScreenState
    extends State<EvaluationAdminSubmissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool loading = true;
  List<Map<String, dynamic>> completed = [];
  List<Map<String, dynamic>> pending = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final data = await NoticesService.adminGetEvaluationSubmissions(
        widget.evaluationId,
      );

      setState(() {
        completed = List<Map<String, dynamic>>.from(data['completed'] ?? []);
        pending = List<Map<String, dynamic>>.from(data['pending'] ?? []);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evaluationName),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Contestaron (${completed.length})'),
            Tab(text: 'Faltan (${pending.length})'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(completed, answered: true),
                _buildList(pending, answered: false),
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required bool answered}) {
    if (items.isEmpty) {
      return Center(
        child: Text(answered ? 'Nadie ha contestado.' : 'Nadie pendiente.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final user = items[index];

        return Card(
          elevation: 3,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: answered ? Colors.green : Colors.orange,
              child: Icon(
                answered ? Icons.check : Icons.schedule,
                color: Colors.white,
              ),
            ),

            
            title: Text(
              '${user['user_name'] ?? user['name'] ?? 'Usuario'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            // 
            subtitle: Text(
              answered
                  ? 'Área: ${user['area'] ?? '-'}\n'
                      'Puesto: ${user['position'] ?? '-'}\n'
                      'Calificación: ${user['score'] ?? '-'}\n'
                      'Fecha: ${user['completed_at'] ?? '-'}'
                  : 'Área: ${user['area'] ?? '-'}\n'
                      'Puesto: ${user['position'] ?? '-'}\n'
                      'Pendiente por contestar',
            ),

            trailing: answered
                ? const Icon(Icons.visibility_outlined)
                : null,

            onTap: answered
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvaluationSubmissionDetailScreen(
                          submissionId:
                              int.parse('${user['submission_id']}'),
                        ),
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }
}

class EvaluationSubmissionDetailScreen extends StatelessWidget {
  final int submissionId;

  const EvaluationSubmissionDetailScreen({
    super.key,
    required this.submissionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respuestas'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future:
            NoticesService.adminGetEvaluationSubmissionDetail(submissionId),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final answers =
              List<Map<String, dynamic>>.from(data['answers'] ?? []);

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: answers.length,
            itemBuilder: (_, index) {
              final a = answers[index];

              return Card(
                child: ListTile(
                  title: Text('${a['question_text'] ?? 'Pregunta'}'),
                  subtitle: Text(
                    '${a['answer_text'] ?? a['option_text'] ?? '-'}',
                  ),
                  trailing: Text('${a['points'] ?? 0} pts'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}