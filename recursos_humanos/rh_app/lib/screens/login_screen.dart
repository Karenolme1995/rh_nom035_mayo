import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import 'app_shell.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'terminos_screen.dart';
import 'aviso_privacidad_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  bool get biometricsAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final _formKey = GlobalKey<FormState>();

  final employeeController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool hasSavedSession = false;

  @override
  void initState() {
    super.initState();
    checkSavedSession();
  }

  @override
  void dispose() {
    employeeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final rawUserData = prefs.getString('user_data');

    if (!mounted) return;

    setState(() {
      hasSavedSession =
          token != null &&
          token.isNotEmpty &&
          rawUserData != null &&
          rawUserData.isNotEmpty;
    });
  }

  Map<String, dynamic> _mergeUserData(
    Map<String, dynamic> loginData,
    Map<String, dynamic>? profileData,
  ) {
    final loginUser = (loginData['user'] is Map)
        ? Map<String, dynamic>.from(loginData['user'])
        : <String, dynamic>{};

    final profile = profileData ?? <String, dynamic>{};

    return <String, dynamic>{
      ...loginData,
      ...loginUser,
      ...profile,
      'access_token': loginData['access_token'],
    };
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final loginData = await AuthService.login(
        employeeController.text.trim(),
        passwordController.text,
      );

      final profileData = await AuthService.getUserProfile();

      final Map<String, dynamic> userData =
          _mergeUserData(loginData, profileData);

      if (!mounted) return;

      await checkSavedSession();

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

  Future<void> loginWithBiometrics() async {
    try {
      final bool isSupported = await auth.isDeviceSupported();
      final bool canCheck = await auth.canCheckBiometrics;

      if (!isSupported || !canCheck) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La biometría no está disponible en este dispositivo'),
          ),
        );
        return;
      }

      final bool authenticated = await auth.authenticate(
        localizedReason: 'Usa tu huella para iniciar sesión',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final rawUserData = prefs.getString('user_data');

      if (token == null ||
          token.isEmpty ||
          rawUserData == null ||
          rawUserData.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero inicia sesión manualmente al menos una vez'),
          ),
        );
        return;
      }

      Map<String, dynamic> savedLoginData;
      try {
        savedLoginData = Map<String, dynamic>.from(jsonDecode(rawUserData));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo recuperar la sesión guardada'),
          ),
        );
        return;
      }

      Map<String, dynamic>? profileData;
      try {
        profileData = await AuthService.getUserProfile();
      } catch (_) {
        profileData = null;
      }

      final userData = _mergeUserData(savedLoginData, profileData);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppShell(userData: userData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al usar biometría: $e')),
      );
    }
  }

  Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF0B1E4B);
    const yellow = Color(0xFFFFC400);

    final baseTheme = Theme.of(context);
    final isDark = baseTheme.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F7FB);
    final inputFill = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.92);
    final inputBorderColor =
        isDark ? Colors.white24 : Colors.grey.shade300;
    final secondaryTextColor =
        isDark ? Colors.white70 : Colors.grey.shade700;
    final biometricBg = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.85);
    final buttonShadowColor = isDark
        ? Colors.black.withOpacity(0.6)
        : navy.withOpacity(0.22);
    final iconColor = isDark ? Colors.white70 : navy;
    final footerTextColor = isDark ? Colors.white60 : Colors.black87;

    return Theme(
      data: baseTheme.copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: navy,
          secondary: yellow,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: inputFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: inputBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: inputBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: navy, width: 1.6),
          ),
          labelStyle: TextStyle(color: secondaryTextColor),
          prefixIconColor: iconColor,
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
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: isDark ? yellow : navy,
          ),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            _CornerBackground(
              navy: navy,
              yellow: yellow,
              bg: bg,
              isDark: isDark,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        tooltip: isDark
                            ? 'Cambiar a tema claro'
                            : 'Cambiar a tema oscuro',
                        onPressed: () {
                          MyApp.of(context)?.toggleTheme();
                        },
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) =>
                              RotationTransition(
                            turns: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            key: ValueKey(isDark),
                            color: isDark ? yellow : navy,
                          ),
                        ),
                      ),
                    ),
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
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Image.asset(
                                      'assets/images/vitracoat.png',
                                      height: 210,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Bienvenido',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : null,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Inicia sesión para continuar',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 34),
                                  TextFormField(
                                    controller: employeeController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Número de empleado',
                                      prefixIcon: Icon(Icons.badge),
                                    ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Campo requerido'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: passwordController,
                                    obscureText: !showPassword,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon: const Icon(Icons.lock),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          showPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: iconColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            showPassword = !showPassword;
                                          });
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
                                      child: const Text(
                                        '¿Olvidaste tu contraseña?',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: buttonShadowColor,
                                          blurRadius: 18,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
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
                                          : const Text(
                                              'Ingresar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (biometricsAvailable)
                                    Center(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 350),
                                        decoration: BoxDecoration(
                                          color: biometricBg,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.12),
                                              blurRadius: 14,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          onPressed: loginWithBiometrics,
                                          icon:
                                              const Icon(Icons.fingerprint),
                                          color: isDark ? yellow : navy,
                                          iconSize: 42,
                                          tooltip: 'Ingresar con huella',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TerminosScreen(),
                                    ),
                                  );
                                },
                                child:
                                    const Text('Términos y Condiciones'),
                              ),
                              Text(
                                '|',
                                style: TextStyle(color: footerTextColor),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AvisoPrivacidadScreen(),
                                    ),
                                  );
                                },
                                child:
                                    const Text('Aviso de Privacidad'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '© ${DateTime.now().year} Todos los derechos reservados.',
                            style: TextStyle(
                              fontSize: 10,
                              color: footerTextColor,
                            ),
                          ),
                        ],
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

class _CornerBackground extends StatelessWidget {
  final Color navy;
  final Color yellow;
  final Color bg;
  final bool isDark;

  const _CornerBackground({
    required this.navy,
    required this.yellow,
    required this.bg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            decoration: BoxDecoration(
              color: bg,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF0B1E4B),
                        bg,
                      ]
                    : [
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
            child: Container(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : navy.withOpacity(0.08),
            ),
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