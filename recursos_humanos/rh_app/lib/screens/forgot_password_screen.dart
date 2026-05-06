import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'verify_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final employeeController = TextEditingController();
  final contactController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    employeeController.dispose();
    contactController.dispose();
    super.dispose();
  }

  bool _isEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value);
  }

  bool _isPhone(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length >= 10;
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('failed to fetch') ||
        msg.contains('clientexception') ||
        msg.contains('socketexception') ||
        msg.contains('connection refused')) {
      return 'No fue posible conectar con el servidor. Verifica tu conexión o intenta más tarde.';
    }

    if (msg.contains('404')) {
      return 'La ruta de recuperación no existe en el servidor.';
    }

    if (msg.contains('500')) {
      return 'El servidor presentó un error interno.';
    }

    return 'No se pudo enviar el código. Verifica los datos.';
  }

  Future<void> sendCode() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final emp = employeeController.text.trim();
    final contact = contactController.text.trim();

    setState(() => loading = true);

    try {
      await AuthService.forgotPassword(emp, contact);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPhone(contact)
                ? 'Código enviado por mensaje.'
                : 'Código enviado por correo.',
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyCodeScreen(
            employeeNumber: emp,
            email: contact,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyError(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B1E4B);
    const yellow = Color(0xFFFFC400);
    const bg = Color(0xFFF5F7FB);

    final baseTheme = Theme.of(context);

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: navy,
          secondary: yellow,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: navy, width: 1.6),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          prefixIconColor: navy,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recuperar contraseña'),
          backgroundColor: bg,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: Stack(
          children: [
            const _ForgotBackground(navy: navy, yellow: yellow, bg: bg),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.94),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Image.asset(
                                        'assets/images/favicon.png',
                                        height: 110,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    const Text(
                                      'Recupera tu acceso',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ingresa tu número de empleado y tu correo o teléfono registrado.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 26),

                                    TextFormField(
                                      controller: employeeController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Número de empleado',
                                        prefixIcon: Icon(Icons.badge),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Ingresa tu número de empleado';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    TextFormField(
                                      controller: contactController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Correo o teléfono registrado',
                                        prefixIcon: Icon(Icons.email_outlined),
                                        hintText: 'ejemplo@correo.com o 8123456789',
                                      ),
                                      validator: (value) {
                                        final v = value?.trim() ?? '';
                                        if (v.isEmpty) {
                                          return 'Ingresa tu correo o teléfono';
                                        }
                                        if (!_isEmail(v) && !_isPhone(v)) {
                                          return 'Escribe un correo o teléfono válido';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 24),

                                    ElevatedButton(
                                      onPressed: loading ? null : sendCode,
                                      child: loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Enviar código',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),

                                    const SizedBox(height: 14),

                                    Text(
                                      'El código puede enviarse por correo electrónico o mensaje, según la información registrada.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '© ${DateTime.now().year} Todos los derechos reservados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotBackground extends StatelessWidget {
  final Color navy;
  final Color yellow;
  final Color bg;

  const _ForgotBackground({
    required this.navy,
    required this.yellow,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bg,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  bg,
                ],
              ),
            ),
          ),
          ClipPath(
            clipper: _TopRightCornerClipper(),
            child: Container(color: navy),
          ),
          ClipPath(
            clipper: _TopRightBandClipper(),
            child: Container(color: yellow),
          ),
          ClipPath(
            clipper: _BottomLeftCornerClipper(),
            child: Container(color: navy.withOpacity(0.08)),
          ),
        ],
      ),
    );
  }
}

class _TopRightCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final p = Path()
      ..moveTo(w * 0.58, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.30)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TopRightBandClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final p = Path()
      ..moveTo(w * 0.54, 0)
      ..lineTo(w * 0.62, 0)
      ..lineTo(w, h * 0.22)
      ..lineTo(w, h * 0.14)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomLeftCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final p = Path()
      ..moveTo(0, h)
      ..lineTo(w * 0.45, h)
      ..lineTo(0, h * 0.70)
      ..close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}