import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'reset_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String employeeNumber;
  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.employeeNumber,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  final FocusNode _keyboardNode = FocusNode();
  int _currentIndex = 0;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _resending = false;

  String get code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startTimer();

    //
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyboardNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _keyboardNode.dispose();

    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> resendCode() async {
    if (!_canResend || _resending) return;

    setState(() => _resending = true);
    try {
      // ✅ tu API requiere employee + email
      await AuthService.forgotPassword(
        widget.employeeNumber.trim(),
        widget.email.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado')),
      );

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> verify() async {
    final pin = code.trim();
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa los 6 dígitos')),
      );
      return;
    }

    try {
      await AuthService.verifyCode(widget.employeeNumber.trim(), pin);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            employeeNumber: widget.employeeNumber.trim(),
            code: pin,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _handlePasteIfNeeded(String value) {
    final onlyDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = onlyDigits[i];
      }
      FocusScope.of(context).unfocus();
      setState(() {});
    }
  }

  void _onChanged(int index, String value) {
    _handlePasteIfNeeded(value);

    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
      _currentIndex = index + 1;
    }

    if (code.length == 6) {
      FocusScope.of(context).unfocus();
    }

    setState(() {});
  }

  void _onBackspaceDesktop() {
    final i = _currentIndex;
    if (i > 0 && _controllers[i].text.isEmpty) {
      _controllers[i - 1].clear();
      _nodes[i - 1].requestFocus();
      _currentIndex = i - 1;
      setState(() {});
    }
  }

  String get timerText =>
      'Reenviar en 00:${_secondsRemaining.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar código')),
      body: RawKeyboardListener(
        focusNode: _keyboardNode,
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            _onBackspaceDesktop();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ingresa el código de 6 dígitos',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      decoration: const InputDecoration(counterText: ''),
                      onTap: () => _currentIndex = i,
                      onChanged: (v) => _onChanged(i, v),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: verify,
                child: const Text('Continuar'),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: _canResend && !_resending ? resendCode : null,
                child: _resending
                    ? const Text('Reenviando...')
                    : Text(_canResend ? 'Reenviar código' : timerText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
