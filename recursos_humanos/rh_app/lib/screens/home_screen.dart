import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? imageUrl;
   bool get canCreateNotices {
    final roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    return roleId == 1 || roleId == 2;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  bool get isBirthdayToday {
    final bday = _parseDate(widget.userData['birthday']);
    imageUrl = latestNotice?['image_url']?.toString();
    if (bday == null) return false;
    final now = DateTime.now();
    return now.month == bday.month && now.day == bday.day;
  }

  String _fmtDM(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}';
  }

  String _fmtDMYHM(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  // Simulación: “último aviso” (luego lo traemos del backend)
  // Si quieres, lo cambiamos a FutureBuilder con API.
  final Map<String, dynamic>? latestNotice = null;
  // ejemplo:
  // final latestNotice = {
  //   'title': 'Mantenimiento',
  //   'body': 'Hoy habrá mantenimiento de red a las 6pm.',
  //   'created_at': '2026-02-11T10:15:00'
  // };

  // 🎉 Animación mejorada (confetti simple)
  late final AnimationController _confettiCtrl;
  late final Animation<double> _confettiAnim;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _confettiAnim = CurvedAnimation(
      parent: _confettiCtrl,
      curve: Curves.easeOutCubic,
    );

    if (isBirthdayToday) {
      _confettiCtrl.repeat(); // se mantiene mientras esté en pantalla
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _openCreateNoticeDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo aviso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Mensaje'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // ✅ Aquí luego llamamos al backend (POST /notices)
              // por ahora solo muestra confirmación
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aviso guardado (pendiente backend)')),
              );
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.userData['avatar'];
    final name = (widget.userData['name'] ?? '').toString();
    final empNo = (widget.userData['employee_number'] ?? '—').toString();
    final position = (widget.userData['position'] ?? '—').toString();
    final bday = _parseDate(widget.userData['birthday']);

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _UserHeader(
                avatarUrl: avatarUrl,
                name: name,
                empNo: empNo,
                position: position,
              ),

              const SizedBox(height: 18),

              // ✅ AVISOS (primero)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Avisos',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (canCreateNotices)
                    ElevatedButton.icon(
                      onPressed: _openCreateNoticeDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo'),
                    ),
                ],
              ),
              const SizedBox(height: 10),
_NoticeCard(
  title: latestNotice?['title'] ?? 'Sin avisos por el momento',
  body: latestNotice?['body'] ??
      'Aquí verás el último aviso publicado (el más reciente).',
  createdAt: _parseDate(latestNotice?['created_at']),
  fmt: _fmtDMYHM,
),

if (imageUrl != null && imageUrl!.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 10),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        'http://10.0.2.2:8000$imageUrl',
        height: 180,
        fit: BoxFit.cover,
      ),
    ),
  ),        const SizedBox(height: 18),

              // ✅ CUMPLEAÑOS (después)
              const Text(
                'Recordatorio de cumpleaños',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              if (isBirthdayToday)
                _BirthdayBanner(
                  name: name,
                  onReplay: () => _confettiCtrl.forward(from: 0),
                )
              else
                _BirthdayInfoCard(
                  birthdayText: bday == null ? '—' : _fmtDM(bday),
                ),
            ],
          ),

          // 🎊 Confetti overlay solo si hoy es su cumple
          if (isBirthdayToday)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiAnim,
                builder: (_, __) => CustomPaint(
                  painter: _ConfettiPainter(progress: _confettiAnim.value),
                  size: Size.infinite,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final dynamic avatarUrl;
  final String name;
  final String empNo;
  final String position;

  const _UserHeader({
    required this.avatarUrl,
    required this.name,
    required this.empNo,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Empleado #$empNo',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.work_rounded, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          position,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
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

class _NoticeCard extends StatelessWidget {
  final String title;
  final String body;
  final DateTime? createdAt;
  final String Function(DateTime) fmt;

  const _NoticeCard({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = createdAt == null ? null : fmt(createdAt!.toLocal());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: TextStyle(color: Colors.grey.shade800)),
            if (dateText != null) ...[
              const SizedBox(height: 10),
              Text(
                dateText,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BirthdayInfoCard extends StatelessWidget {
  final String birthdayText;

  const _BirthdayInfoCard({required this.birthdayText});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.cake_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                birthdayText == '—'
                    ? 'No tengo tu cumpleaños registrado.'
                    : 'Tu cumpleaños registrado es: $birthdayText',
                style: TextStyle(color: Colors.grey.shade800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BirthdayBanner extends StatefulWidget {
  final String name;
  final VoidCallback onReplay;

  const _BirthdayBanner({required this.name, required this.onReplay});

  @override
  State<_BirthdayBanner> createState() => _BirthdayBannerState();
}

class _BirthdayBannerState extends State<_BirthdayBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _rotate = Tween<double>(begin: -0.015, end: 0.015).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.name.isEmpty ? '' : ' ${widget.name}';

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.rotate(
        angle: _rotate.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.withOpacity(0.18),
                    Colors.amber.withOpacity(0.18),
                    Colors.lightBlue.withOpacity(0.18),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.celebration_rounded, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Feliz cumpleaños$displayName! 🎉',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Que tengas un gran día. 🥳'),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: widget.onReplay,
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Repetir confetti'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);

    // cantidad de partículas
    const count = 90;

    // cada frame “caen” de arriba hacia abajo, reiniciando por progress (loop)
    for (int i = 0; i < count; i++) {
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();
      final seedS = rng.nextDouble();

      final x = seedX * size.width;

      // simula caída + loop
      final y = ((seedY + progress) % 1.0) * size.height;

      final r = 2.0 + seedS * 4.5;

      // colores vivos sin depender de intl ni paquetes
      final color = Color.fromARGB(
        220,
        80 + (i * 13) % 175,
        80 + (i * 29) % 175,
        80 + (i * 47) % 175,
      );

      final paint = Paint()..color = color;

      // dibuja “rectangulitos” inclinados
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((seedS * 2 - 1) * 0.8);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 1.8, height: r * 1.2),
          Radius.circular(r * 0.4),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}