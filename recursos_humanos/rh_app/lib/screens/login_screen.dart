import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import 'app_shell.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // detección de plataforma
  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  // biometría disponible
  bool get biometricsAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.windows);

  final _formKey = GlobalKey<FormState>();

  final employeeController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    employeeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final data = await AuthService.login(
        employeeController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      // ✅ AQUI SACAMOS EL USERDATA CORRECTO
      // Si tu AuthService.login ya regresa el usuario directo, esto funciona también.
      final Map<String, dynamic> userData =
          Map<String, dynamic>.from(data['user'] ?? data);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppShell(userData: userData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void loginWithBiometrics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometría próximamente')),
    );
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // 🔝 CONTENIDO PRINCIPAL
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),

                            // LOGO
                            Center(
                              child: Image.asset(
                                'assets/images/favicon.png',
                                height: 120,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Bienvenido',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // EMPLEADO
                            TextFormField(
                              controller: employeeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Número de empleado',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Campo requerido'
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // PASSWORD
                            TextFormField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(
                                        () => showPassword = !showPassword);
                                  },
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Campo requerido'
                                  : null,
                            ),

                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('¿Olvidaste tu contraseña?'),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // BOTÓN LOGIN
                            ElevatedButton(
                              onPressed: loading ? null : login,
                              child: loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Ingresar'),
                            ),

                            const SizedBox(height: 16),

                            // 🔐 BIOMETRÍA
                            if (biometricsAvailable)
                              Center(
                                child: IconButton(
                                  onPressed: loginWithBiometrics,
                                  icon: const Icon(Icons.fingerprint),
                                  iconSize: 42,
                                  tooltip: 'Ingresar con huella',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ⬇️ FOOTER FIJO
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => openUrl(
                            'https://tusitio.com/terminos',
                          ),
                          child: const Text('Términos y Condiciones'),
                        ),
                        const Text('|'),
                        TextButton(
                          onPressed: () => openUrl(
                            'https://tusitio.com/aviso-privacidad',
                          ),
                          child: const Text('Aviso de Privacidad'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '© ${DateTime.now().year} Todos los derechos reservados.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}