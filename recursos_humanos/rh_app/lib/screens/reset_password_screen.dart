import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String employeeNumber;
  final String code;

  const ResetPasswordScreen({
    super.key,
    required this.employeeNumber,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();

  void reset() async {
    try {
      await AuthService.resetPassword(
        widget.employeeNumber,
        widget.code,
        passwordController.text,
      );

      Navigator.popUntil(context, (r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña actualizada")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nueva contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: "Nueva contraseña"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: reset,
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }
}
