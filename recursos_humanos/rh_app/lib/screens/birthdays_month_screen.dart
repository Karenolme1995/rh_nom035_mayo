import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/notices_service.dart';
import '../services/auth_service.dart';

class BirthdaysMonthScreen extends StatefulWidget {
  const BirthdaysMonthScreen({super.key});

  @override
  State<BirthdaysMonthScreen> createState() => _BirthdaysMonthScreenState();
}

class _BirthdaysMonthScreenState extends State<BirthdaysMonthScreen>
    with SingleTickerProviderStateMixin {
  Map<int, String> positionsMap = {};
  List<Map<String, dynamic>> birthdays = [];

  bool loadingCatalogs = true;
  bool loadingData = true;

  AnimationController? _sceneController;

  @override
  void initState() {
    super.initState();

    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _init();
  }

  @override
  void dispose() {
    _sceneController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await initializeDateFormatting('es_MX', null);

    try {
      final positions = await NoticesService().getPositionsMap();
      final monthUsers = await NoticesService().getBirthdaysMonth();

      debugPrint('Cumpleaños del mes: $monthUsers');

      if (!mounted) return;

      setState(() {
        positionsMap = positions;
        birthdays = monthUsers;
        loadingCatalogs = false;
        loadingData = false;
      });
    } catch (e) {
      debugPrint('Error cargando cumpleaños del mes: $e');

      if (!mounted) return;

      setState(() {
        loadingCatalogs = false;
        loadingData = false;
      });
    }
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _asString(dynamic v) => v == null ? '' : v.toString();

  dynamic _rawBirthday(Map<String, dynamic> u) {
    return u['birth_date'] ??
        u['birthday'] ??
        u['fecha_nacimiento'] ??
        u['birthdate'] ??
        u['date_of_birth'] ??
        u['fecha'] ??
        u['dob'];
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;

    final mysql = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (mysql != null) return mysql;

    final formats = [
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
    ];

    for (final f in formats) {
      try {
        return f.parse(raw);
      } catch (_) {}
    }

    return null;
  }

  String _formatBirthday(dynamic dateValue) {
    final dt = _parseDate(dateValue);
    if (dt == null) return 'Sin fecha';
    return DateFormat('dd MMMM', 'es_MX').format(dt).toLowerCase();
  }

  bool _isTodayBirthday(dynamic dateValue) {
    final dt = _parseDate(dateValue);
    if (dt == null) return false;

    final now = DateTime.now();
    return dt.day == now.day && dt.month == now.month;
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _resolvePosition(Map<String, dynamic> u) {
    final rawPos = u['position_id'] ?? u['id_position'] ?? u['position'];
    final posId = _asInt(rawPos);

    if (posId != 0) {
      return positionsMap[posId] ?? rawPos.toString();
    }

    final fallback = _asString(
      u['position_name'] ?? u['puesto'] ?? u['job_title'] ?? u['position'],
    );

    return fallback.isEmpty ? 'Sin puesto' : fallback;
  }

  String _resolveAvatar(Map<String, dynamic> u) {
    final raw = _asString(u['photo_url'] ?? u['avatar'] ?? u['image']);
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '${AuthService.baseUrl}$raw';
  }

  String _resolveName(Map<String, dynamic> u) {
    final fullName = _asString(
      u['full_name'] ??
          u['name'] ??
          u['employee_name'] ??
          '${_asString(u['first_name'])} ${_asString(u['last_name'])}'.trim(),
    );

    return fullName.isEmpty ? 'Sin nombre' : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 380;

    final horizontalPadding = isSmallMobile ? 10.0 : (isMobile ? 14.0 : 92.0);
    final bottomPadding = isMobile ? 190.0 : 170.0;

    final avatarSize = isSmallMobile ? 58.0 : (isMobile ? 64.0 : 72.0);
    final avatarRadius = isSmallMobile ? 24.0 : (isMobile ? 27.0 : 30.0);
    final cardPadding = isSmallMobile ? 12.0 : (isMobile ? 13.0 : 14.0);
    final nameFontSize = isSmallMobile ? 12.5 : (isMobile ? 13.0 : 14.0);
    final positionFontSize = isSmallMobile ? 11.0 : 12.0;
    final birthdayFontSize = isSmallMobile ? 12.0 : 13.0;
    final trailingIconBox = isSmallMobile ? 36.0 : (isMobile ? 38.0 : 42.0);
    final trailingIconSize = isSmallMobile ? 18.0 : (isMobile ? 20.0 : 22.0);
    final spaceAfterAvatar = isSmallMobile ? 10.0 : (isMobile ? 12.0 : 14.0);
    final trailingGap = isSmallMobile ? 6.0 : 10.0;

    final list = [...birthdays];
    list.sort((a, b) {
      final da = _parseDate(_rawBirthday(a));
      final db = _parseDate(_rawBirthday(b));

      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;

      if (da.month != db.month) return da.month.compareTo(db.month);
      return da.day.compareTo(db.day);
    });

    final pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF7F7FA);
    final cardColor = isDark ? const Color(0xFF162033) : Colors.white;
    final todayCardColor =
        isDark ? const Color(0xFF3A2814) : const Color(0xFFFFFBF3);
    final borderColor =
        isDark ? const Color(0xFF2A3954) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF1F2A44);
    final subtitleColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF76829C);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final avatarBg = isDark ? const Color(0xFF243146) : const Color(0xFFF1F5F9);
    final badgeBg = isDark ? const Color(0xFF243146) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cumpleañeros del mes',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 18 : 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '🎂',
              style: TextStyle(
                fontSize: isDark ? 24 : 22,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: pageBg,
        foregroundColor: titleColor,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sceneController ?? const AlwaysStoppedAnimation(0),
                builder: (context, child) {
                  final progress = _sceneController?.value ?? 0.0;
                  return CustomPaint(
                    painter: FestiveBirthdayPainter(
                      progress: progress,
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                  );
                },
              ),
            ),
          ),
          (loadingCatalogs || loadingData)
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          'No hay cumpleaños este mes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final u = list[index];

                        final fullName = _resolveName(u);
                        final positionName = _resolvePosition(u);
                        final avatarUrl = _resolveAvatar(u);
                        final birthdayRaw = _rawBirthday(u);
                        final birthdayText = _formatBirthday(birthdayRaw);
                        final isToday = _isTodayBirthday(birthdayRaw);

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: EdgeInsets.all(cardPadding),
                          decoration: BoxDecoration(
                            color: isToday ? todayCardColor : cardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isToday
                                  ? Colors.orange.shade400
                                  : borderColor,
                              width: isToday ? 1.4 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.28 : 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isToday
                                        ? Colors.orange
                                        : const Color(0xFFF4B526),
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: avatarBg,
                                  backgroundImage: avatarUrl.isNotEmpty
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl.isEmpty
                                      ? Text(
                                          _getInitials(fullName),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: isSmallMobile ? 15 : 18,
                                            color: titleColor,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(width: spaceAfterAvatar),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: isMobile
                                                ? screenWidth * 0.42
                                                : screenWidth * 0.50,
                                          ),
                                          child: Text(
                                            fullName.toUpperCase(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: nameFontSize,
                                              fontWeight: FontWeight.w800,
                                              color: titleColor,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                        if (isToday)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Hoy',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      positionName.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: positionFontSize,
                                        color: subtitleColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.08)
                                                : const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_month_rounded,
                                              size: 15,
                                              color: Colors.orange.shade400,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              birthdayText,
                                              style: TextStyle(
                                                fontSize: birthdayFontSize,
                                                color: mutedColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: trailingGap),
                              Container(
                                width: trailingIconBox,
                                height: trailingIconBox,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : const Color(0xFFFFF8E7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.cake_rounded,
                                  color: Colors.orange.shade400,
                                  size: trailingIconSize,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

class FestiveBirthdayPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final bool isMobile;

  FestiveBirthdayPainter({
    required this.progress,
    required this.isDark,
    required this.isMobile,
  });

  static const List<Color> _confettiColors = [
    Color(0xFFFFB84D),
    Color(0xFFFD79A8),
    Color(0xFF74B9FF),
    Color(0xFF55EFC4),
    Color(0xFFA29BFE),
    Color(0xFFFF7675),
    Color(0xFFFDCB6E),
    Color(0xFF6C5CE7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawConfetti(canvas, size);
    _drawSideBalloons(canvas, size);
    _drawSideCakes(canvas, size);
  }

  void _drawConfetti(Canvas canvas, Size size) {
    final random = math.Random(21);

    final totalConfetti = isMobile ? 80 : 120;
    for (int i = 0; i < totalConfetti; i++) {
      final baseX = random.nextDouble() * size.width;
      final speed = 0.25 + random.nextDouble() * 0.9;
      final offset = random.nextDouble();
      final y = ((progress * size.height * speed * 1.15) +
              (offset * size.height)) %
          (size.height + 40);

      final sway = math.sin((progress * math.pi * 2) + i) *
          (4 + random.nextDouble() * 10);
      final x = baseX + sway;

      final paint = Paint()
        ..color = _confettiColors[i % _confettiColors.length]
            .withOpacity(isDark ? 0.85 : 0.80);

      final type = i % 4;

      if (type == 0) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(progress * 6 + i);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: isMobile ? 5 : 6,
            height: isMobile ? 10 : 12,
          ),
          paint,
        );
        canvas.restore();
      } else if (type == 1) {
        canvas.drawCircle(Offset(x, y), isMobile ? 2.4 : 3, paint);
      } else if (type == 2) {
        final path = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 8, y + 8, x, y + 16)
          ..quadraticBezierTo(x - 8, y + 24, x, y + 32);

        final stroke = Paint()
          ..color = paint.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, stroke);
      } else {
        final diamond = Path()
          ..moveTo(x, y - 4)
          ..lineTo(x + 4, y)
          ..lineTo(x, y + 4)
          ..lineTo(x - 4, y)
          ..close();
        canvas.drawPath(diamond, paint);
      }
    }
  }

  void _drawSideBalloons(Canvas canvas, Size size) {
    final floatY = math.sin(progress * math.pi * 2) * 8;
    final leftX = isMobile ? 28.0 : 52.0;
    final rightX = isMobile ? size.width - 28.0 : size.width - 52.0;

    _drawBalloon(
      canvas,
      center: Offset(leftX, 150 + floatY),
      balloonColor: const Color(0xFFA97CF5),
      scale: isMobile ? 0.72 : 1.05,
    );
    _drawBalloon(
      canvas,
      center: Offset(leftX + (isMobile ? 6 : 10), 240 - floatY * 0.7),
      balloonColor: const Color(0xFFF78CC6),
      scale: isMobile ? 0.68 : 1.0,
    );
    _drawBalloon(
      canvas,
      center: Offset(leftX - (isMobile ? 8 : 12), 330 + floatY * 0.6),
      balloonColor: const Color(0xFFF6C547),
      scale: isMobile ? 0.72 : 1.05,
    );

    _drawBalloon(
      canvas,
      center: Offset(rightX, 150 - floatY),
      balloonColor: const Color(0xFF59D5D8),
      scale: isMobile ? 0.72 : 1.05,
    );
    _drawBalloon(
      canvas,
      center: Offset(rightX + (isMobile ? 8 : 16), 250 + floatY * 0.5),
      balloonColor: const Color(0xFFFFA24C),
      scale: isMobile ? 0.68 : 1.0,
    );
    _drawBalloon(
      canvas,
      center: Offset(rightX - (isMobile ? 4 : 8), 345 - floatY * 0.7),
      balloonColor: const Color(0xFFA97CF5),
      scale: isMobile ? 0.70 : 1.02,
    );
  }

  void _drawBalloon(
    Canvas canvas, {
    required Offset center,
    required Color balloonColor,
    double scale = 1,
  }) {
    final width = 70.0 * scale;
    final height = 92.0 * scale;
    final stringHeight = 72.0 * scale;

    final rect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    final shadowPaint = Paint()
      ..color = balloonColor.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(rect.inflate(4), shadowPaint);

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 1.0,
        colors: [
          Colors.white.withOpacity(0.80),
          balloonColor,
          _darken(balloonColor, 0.18),
        ],
        stops: const [0.0, 0.22, 1.0],
      ).createShader(rect);

    canvas.drawOval(rect, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.28);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - width * 0.18, center.dy - height * 0.15),
        width: width * 0.22,
        height: height * 0.28,
      ),
      highlightPaint,
    );

    final knotPath = Path()
      ..moveTo(center.dx - 6 * scale, center.dy + height / 2 - 2 * scale)
      ..lineTo(center.dx + 6 * scale, center.dy + height / 2 - 2 * scale)
      ..lineTo(center.dx, center.dy + height / 2 + 9 * scale)
      ..close();

    canvas.drawPath(
      knotPath,
      Paint()..color = _darken(balloonColor, 0.10),
    );

    final stringPaint = Paint()
      ..color = balloonColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final stringPath = Path()
      ..moveTo(center.dx, center.dy + height / 2 + 7 * scale)
      ..quadraticBezierTo(
        center.dx - 12 * scale,
        center.dy + height / 2 + stringHeight * 0.35,
        center.dx + 4 * scale,
        center.dy + height / 2 + stringHeight * 0.75,
      )
      ..quadraticBezierTo(
        center.dx + 12 * scale,
        center.dy + height / 2 + stringHeight * 0.95,
        center.dx,
        center.dy + height / 2 + stringHeight,
      );

    canvas.drawPath(stringPath, stringPaint);
  }

  void _drawSideCakes(Canvas canvas, Size size) {
    final baseY = size.height - (isMobile ? 64 : 82);
    _drawCake(
      canvas,
      center: Offset(isMobile ? 54 : 92, baseY),
      scale: isMobile ? 0.72 : 1.0,
      darkMode: isDark,
      leftCake: true,
    );
    _drawCake(
      canvas,
      center: Offset(size.width - (isMobile ? 54 : 92), baseY),
      scale: isMobile ? 0.72 : 1.0,
      darkMode: isDark,
      leftCake: false,
    );
  }

  void _drawCake(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required bool darkMode,
    required bool leftCake,
  }) {
    final platePaint = Paint()
      ..shader = LinearGradient(
        colors: darkMode
            ? [const Color(0xFFB8C0E0), const Color(0xFF6C7BA8)]
            : [const Color(0xFFDCE7FF), const Color(0xFFB8C8F5)],
      ).createShader(
        Rect.fromCenter(center: center, width: 180 * scale, height: 34 * scale),
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 18 * scale),
        width: 150 * scale,
        height: 30 * scale,
      ),
      Paint()
        ..color = Colors.black.withOpacity(darkMode ? 0.18 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 10 * scale),
        width: 145 * scale,
        height: 28 * scale,
      ),
      platePaint,
    );

    final lowerRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 28 * scale),
        width: 110 * scale,
        height: 62 * scale,
      ),
      Radius.circular(20 * scale),
    );

    final upperRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy - 74 * scale),
        width: 94 * scale,
        height: 48 * scale,
      ),
      Radius.circular(18 * scale),
    );

    final lowerColors = leftCake
        ? [
            const Color(0xFFF8A7C7),
            const Color(0xFFFFD889),
            const Color(0xFFF48FB1)
          ]
        : [
            const Color(0xFFF7D89C),
            const Color(0xFF8D4B32),
            const Color(0xFFFFD89A)
          ];

    final upperColors = leftCake
        ? [const Color(0xFFFFE4C4), const Color(0xFFFFD6B3)]
        : [const Color(0xFFFFE3B8), const Color(0xFFD8A56D)];

    _drawStripedCake(canvas, lowerRect, lowerColors);
    _drawStripedCake(canvas, upperRect, upperColors);

    final creamColor =
        leftCake ? const Color(0xFFFFF4DA) : const Color(0xFF6F3A2B);

    _drawDripCream(
      canvas,
      centerX: center.dx,
      y: center.dy - 92 * scale,
      width: 98 * scale,
      color: creamColor,
      scale: scale,
    );
    _drawDripCream(
      canvas,
      centerX: center.dx,
      y: center.dy - 44 * scale,
      width: 114 * scale,
      color: creamColor,
      scale: scale,
    );

    _drawSprinkles(canvas, center, scale, leftCake);

    _drawCandle(
      canvas,
      base: Offset(center.dx, center.dy - 122 * scale),
      bodyColor:
          leftCake ? const Color(0xFFFF8AB5) : const Color(0xFF51C7E8),
      stripeColor: Colors.white,
      flameShift: math.sin(progress * math.pi * 2) * 1.5,
      scale: scale,
    );
  }

  void _drawStripedCake(Canvas canvas, RRect rect, List<Color> colors) {
    final stripePaint = Paint();

    final stripeHeight = rect.outerRect.height / colors.length;
    for (int i = 0; i < colors.length; i++) {
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.outerRect.left,
          rect.outerRect.top + stripeHeight * i,
          rect.outerRect.width,
          stripeHeight,
        ),
        rect.blRadius,
      );
      stripePaint.color = colors[i];
      canvas.drawRRect(r, stripePaint);
    }
  }

  void _drawDripCream(
    Canvas canvas, {
    required double centerX,
    required double y,
    required double width,
    required Color color,
    required double scale,
  }) {
    final left = centerX - width / 2;
    final right = centerX + width / 2;

    final path = Path()
      ..moveTo(left, y)
      ..lineTo(right, y);

    double x = left;
    while (x < right) {
      path.quadraticBezierTo(
        x + 7 * scale,
        y + 10 * scale,
        x + 14 * scale,
        y + 1 * scale,
      );
      x += 14 * scale;
    }

    path.lineTo(right, y - 8 * scale);
    path.lineTo(left, y - 8 * scale);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = color,
    );
  }

  void _drawSprinkles(
    Canvas canvas,
    Offset center,
    double scale,
    bool leftCake,
  ) {
    final rnd = math.Random(leftCake ? 8 : 14);

    for (int i = 0; i < 14; i++) {
      final x = center.dx - 36 * scale + rnd.nextDouble() * 72 * scale;
      final y = center.dy - 90 * scale + rnd.nextDouble() * 20 * scale;

      final colors = [
        const Color(0xFFFF6B6B),
        const Color(0xFF4D96FF),
        const Color(0xFFFFC75F),
        const Color(0xFFB967FF),
        const Color(0xFF00C9A7),
      ];

      final paint = Paint()..color = colors[i % colors.length];

      if (i.isEven) {
        canvas.drawCircle(Offset(x, y), 4.5 * scale, paint);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(i.toDouble());
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: 10 * scale,
              height: 4 * scale,
            ),
            Radius.circular(2 * scale),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  void _drawCandle(
    Canvas canvas, {
    required Offset base,
    required Color bodyColor,
    required Color stripeColor,
    required double flameShift,
    required double scale,
  }) {
    final candleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: base,
        width: 14 * scale,
        height: 50 * scale,
      ),
      Radius.circular(6 * scale),
    );

    canvas.drawRRect(candleRect, Paint()..color = bodyColor);

    final stripePaint = Paint()
      ..color = stripeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale;

    for (double y = -18 * scale; y <= 18 * scale; y += 10 * scale) {
      canvas.drawLine(
        Offset(base.dx - 5 * scale, base.dy + y),
        Offset(base.dx + 5 * scale, base.dy + y + 8 * scale),
        stripePaint,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 34 * scale + flameShift),
        width: 18 * scale,
        height: 24 * scale,
      ),
      Paint()
        ..color = const Color(0xFFFFC94A).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(base.dx, base.dy - 34 * scale + flameShift),
        width: 10 * scale,
        height: 16 * scale,
      ),
      Paint()..color = const Color(0xFFFFB703),
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }

  @override
  bool shouldRepaint(covariant FestiveBirthdayPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.isMobile != isMobile;
  }
}