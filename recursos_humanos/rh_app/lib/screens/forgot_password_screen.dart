import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final employeeController = TextEditingController();
  final emailController = TextEditingController();
  bool loading = false;

  Future<void> sendCode() async {
    setState(() => loading = true);
    try {
      await AuthService.forgotPassword(
        employeeController.text,
        emailController.text,
      );

      if (!mounted) return;

     Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => VerifyCodeScreen(
      employeeNumber: employeeController.text.trim(),
      email: emailController.text.trim(),
    ),
  ),
);


    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar contraseña")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [

              // 🔝 CONTENIDO
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          const SizedBox(height: 24),

                          // LOGO
                          Center(
                            child: Image.asset(
                              'assets/images/favicon.png',
                              height: 120,
                            ),
                          ),

                          const SizedBox(height: 16),

                         TextField(
                            controller: employeeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Número de empleado",
                              prefixIcon: Icon(Icons.badge),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Correo registrado",
                              prefixIcon: Icon(Icons.email),
                            ),
                          ),

                          const SizedBox(height: 24),

                          loading
                              ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                              : ElevatedButton(
                                  onPressed: sendCode,
                                  child: const Text("Enviar código"),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ⬇ FOOTER
              Text(
                '© ${DateTime.now().year} Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
