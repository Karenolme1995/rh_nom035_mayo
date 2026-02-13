import 'package:flutter/material.dart';

class CoursesScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const CoursesScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Pantalla de Cursos'),
    );
  }
}