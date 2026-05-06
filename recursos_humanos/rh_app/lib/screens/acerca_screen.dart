import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AcercaScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AcercaScreen({super.key, this.userData});

  @override
  State<AcercaScreen> createState() => _AcercaScreenState();
}

class _AcercaScreenState extends State<AcercaScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgGradient = isDark
        ? const [Color(0xFF0B1220), Color(0xFF162033), Color(0xFF1E293B)]
        : const [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)];

    final overlayColor = isDark
        ? Colors.black.withOpacity(0.18)
        : Colors.white.withOpacity(0.30);

    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor =
        isDark ? Colors.white70 : const Color(0xFF4B5563);

    return Scaffold(
      
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: bgGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.08 : 0.12,
              child: Image.asset(
                'assets/images/vitracoat.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: PowderParticlesPainter(
                      progress: _bgController.value,
                      isDark: isDark,
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned.fill(
            child: Container(color: overlayColor),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  AnimatedReveal(
                    delay: 0,
                    child: _HeaderCard(
                      isDark: isDark,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  AnimatedReveal(
                    delay: 120,
                    child: HoverInfoCard(
                      title: 'Nosotros',
                      icon: Icons.groups_rounded,
                      content:
                          'Somos una empresa comprometida con la excelencia en recubrimientos y soluciones de pintura en polvo, ofreciendo productos de alta calidad, innovación constante y atención enfocada en las necesidades de nuestros clientes.',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  AnimatedReveal(
                    delay: 240,
                    child: HoverInfoCard(
                      title: 'Objetivo',
                      icon: Icons.track_changes_rounded,
                      content:
                          'Brindar soluciones eficientes y confiables en pintura en polvo, superando las expectativas de nuestros clientes mediante procesos de calidad, mejora continua y un servicio profesional.',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  AnimatedReveal(
                    delay: 360,
                    child: HoverInfoCard(
                      title: 'Misión y Visión',
                      icon: Icons.visibility_rounded,
                      content:
                          'Misión: Desarrollar y ofrecer recubrimientos en pintura en polvo con altos estándares de calidad, innovación y sustentabilidad.\n\n'
                          'Visión: Ser una empresa líder y referente en el mercado de pintura en polvo, reconocida por su tecnología, servicio y compromiso con la satisfacción del cliente.',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  AnimatedReveal(
                    delay: 480,
                    child: HoverInfoCard(
                      title: 'Políticas',
                      icon: Icons.verified_user_rounded,
                      content:
                          'Trabajamos bajo principios de calidad, seguridad, responsabilidad, mejora continua y compromiso con nuestros clientes y colaboradores, cumpliendo con los estándares establecidos en cada uno de nuestros procesos.',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 28),

                  AnimatedReveal(
                    delay: 600,
                    child: Text(
                      '© 2026 Vitracoat',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;

  const _HeaderCard({
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? const Color(0xCC111827) : Colors.white.withOpacity(0.92);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: cardColor,
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.28 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(
              'assets/images/vitracoat.png',
              height: 160,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Vitracoat Pinturas en Polvo SA de CV',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Innovación y calidad en pintura en polvo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class HoverInfoCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String content;
  final bool isDark;

  const HoverInfoCard({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    required this.isDark,
  });

  @override
  State<HoverInfoCard> createState() => _HoverInfoCardState();
}

class _HoverInfoCardState extends State<HoverInfoCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isWebDesktop = kIsWeb;

    final cardColor = widget.isDark
        ? (_hovering
            ? const Color(0xFF1F2A3D)
            : const Color(0xCC111827))
        : (_hovering ? const Color(0xFFF8FBFF) : Colors.white.withOpacity(0.95));

    final textColor = widget.isDark ? Colors.white : const Color(0xFF1F2937);
    final borderColor = widget.isDark
        ? (_hovering ? const Color(0xFF60A5FA) : Colors.white10)
        : (_hovering ? const Color(0xFF93C5FD) : const Color(0xFFE5E7EB));

    final iconBoxColor = widget.isDark
        ? const Color(0xFF60A5FA).withOpacity(0.20)
        : const Color(0xFFDBEAFE);

    final iconColor = widget.isDark
        ? const Color(0xFF93C5FD)
        : const Color(0xFF1D4ED8);

    return MouseRegion(
      onEnter: (_) {
        if (isWebDesktop) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (isWebDesktop) setState(() => _hovering = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(0.0, _hovering ? -6.0 : 0.0)
          ..scale(_hovering ? 1.01 : 1.0),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: _hovering ? 1.4 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.30 : 0.08),
              blurRadius: _hovering ? 22 : 12,
              offset: Offset(0, _hovering ? 10 : 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBoxColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _hovering
                    ? [
                        BoxShadow(
                          color: iconColor.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                color: iconColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark
                          ? Colors.white
                          : const Color(0xFF1E3A5F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.content,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.55,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedReveal extends StatefulWidget {
  final Widget child;
  final int delay;

  const AnimatedReveal({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOut,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        child: widget.child,
      ),
    );
  }
}

class PowderParticlesPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  PowderParticlesPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final particles = List.generate(28, (i) => i);

    for (final i in particles) {
      final seed = i + 1.0;
      final baseX = ((seed * 37.0) % 100) / 100;
      final baseY = ((seed * 19.0) % 100) / 100;

      final dx = size.width *
          (baseX + 0.08 * math.sin((progress * 2 * math.pi) + seed));
      final dy = size.height *
          ((baseY + progress * (0.18 + (i % 5) * 0.015)) % 1.1);

      final radius = 2.0 + (i % 4) * 1.6;

      final color = _particleColor(i).withOpacity(
        isDark ? 0.18 + (i % 3) * 0.04 : 0.14 + (i % 3) * 0.04,
      );

      final paint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }

    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          (isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6))
              .withOpacity(0.06),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final shift = size.width * progress;
    canvas.save();
    canvas.translate(shift - size.width, 0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.8, size.height),
      sweepPaint,
    );
    canvas.restore();
  }

  Color _particleColor(int i) {
    const palette = [
      Color(0xFF60A5FA),
      Color(0xFFF59E0B),
      Color(0xFF38BDF8),
      Color(0xFFEAB308),
      Color(0xFF93C5FD),
    ];
    return palette[i % palette.length];
  }

  @override
  bool shouldRepaint(covariant PowderParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}