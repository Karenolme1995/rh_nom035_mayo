import 'package:flutter/material.dart';

class EvaluationsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const EvaluationsScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Pantalla de Evaluaciones'),
    );
  }
}