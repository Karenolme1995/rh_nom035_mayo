import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/notices_service.dart';
import '../services/auth_service.dart';
import '../widgets/confetti_painter.dart';
import 'profile_screen.dart';
import 'birthdays_month_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? latestNotice;

  List<Map<String, dynamic>> birthdaysToday = [];
  List<Map<String, dynamic>> anniversariesToday = [];

  Map<int, String> _positionsMap = {};
  Map<int, String> _areasMap = {};

  String _positionName = '—';

  int unreadNoticesCount = 0;
  bool hasImportantNotice = false;

  static String get _baseUrl => AuthService.baseUrl;

  String _absoluteUrl(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) return '$_baseUrl$s';
    return '$_baseUrl/$s';
  }

  bool get canViewAnniversaries {
    final roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    final area = (widget.userData['area'] ?? '').toString().trim();
    return roleId == 1 || roleId == 2 || area.isNotEmpty;
  }

  late final AnimationController _confettiCtrl;
  late final Animation<double> _confettiAnim;

  @override
  void initState() {
    super.initState();

    _resolvePositionName(widget.userData['position']);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _confettiAnim = CurvedAnimation(
      parent: _confettiCtrl,
      curve: Curves.easeOutCubic,
    );

    if (isBirthdayToday) {
      _confettiCtrl.repeat();
    }

    _loadHome();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  List<String> _parseImageUrls(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }

    return [];
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    final mysql = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (mysql != null) return mysql;

    return null;
  }

  bool get isBirthdayToday {
    final bday = _parseDate(widget.userData['birthday']);
    if (bday == null) return false;

    final now = DateTime.now();
    final local = bday.toLocal();
    return now.month == local.month && now.day == local.day;
  }

  String _fmtDM(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

  String _fmtDMYHM(DateTime dt) =>
      '${_fmtDM(dt)}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _resolvePositionName(dynamic positionRaw) async {
    try {
      final raw = (positionRaw ?? '').toString().trim();

      if (raw.isEmpty) {
        if (!mounted) return;
        setState(() => _positionName = '—');
        return;
      }

      final id = int.tryParse(raw);

      if (id == null) {
        if (!mounted) return;
        setState(() => _positionName = raw);
        return;
      }

      final posMap = await NoticesService().getPositionsMap();
      if (!mounted) return;

      setState(() {
        _positionName = posMap[id] ?? raw;
      });
    } catch (e) {
      debugPrint('Error resolviendo puesto: $e');
      if (!mounted) return;
      setState(() => _positionName = (positionRaw ?? '—').toString());
    }
  }

  Future<void> _loadHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notice = await NoticesService.getLatestNotice();
      final users = await NoticesService().getBirthdaysToday();
      final badge = await NoticesService.getBadge();
      final posMap = await NoticesService().getPositionsMap();
      final areasMap = await NoticesService().getAreasMap();
      final anniversaries = await NoticesService().getWorkAnniversariesToday();

      final myId = (widget.userData['id'] as num?)?.toInt();
      final filtered = (myId == null)
          ? users
          : users.where((u) => (u['id'] as num?)?.toInt() != myId).toList();

      if (!mounted) return;

      setState(() {
        latestNotice = notice;
        birthdaysToday = filtered;
        anniversariesToday = anniversaries;
        _positionsMap = posMap;
        _areasMap = areasMap;
        unreadNoticesCount = (badge?['unread_count'] as num?)?.toInt() ?? 0;
        hasImportantNotice = (badge?['has_important'] as bool?) ?? false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openPdfPreview(String pdfUrl) async {
    final fullUrl = _absoluteUrl(pdfUrl);

    if (fullUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró la ruta del PDF')),
      );
      return;
    }

    if (kIsWeb) {
      final uri = Uri.parse(fullUrl);
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el PDF: $fullUrl')),
        );
      }
      return;
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Vista previa PDF')),
          body: SfPdfViewer.network(
            fullUrl,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarRaw = (widget.userData['avatar'] ?? '').toString();
    final avatarUrl = _absoluteUrl(avatarRaw);

    final name = (widget.userData['name'] ?? '').toString();
    final empNo = (widget.userData['employee_number'] ?? '—').toString();
    final position = _positionName;
    final bday = _parseDate(widget.userData['birthday']);

    final imageUrl = latestNotice?['image_url']?.toString() ?? '';
    final imageUrls = _parseImageUrls(latestNotice?['image_urls']);
    final pdfUrl = latestNotice?['pdf_url']?.toString() ?? '';

    final allImages = <String>{
      if (imageUrl.isNotEmpty) imageUrl,
      ...imageUrls.where((e) => e.trim().isNotEmpty),
    }.toList();

    return SafeArea(
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadHome,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _UserHeader(
                  avatarUrl: avatarUrl,
                  name: name,
                  empNo: empNo,
                  position: position,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(userData: widget.userData),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          Text(
                            'Avisos',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          _RedBadge(
                            show: hasImportantNotice || unreadNoticesCount > 0,
                            text: hasImportantNotice
                                ? '!'
                                : unreadNoticesCount.toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const _LoadingCard(label: 'Cargando avisos...')
                else if (_error != null)
                  _ErrorCard(error: _error!, onRetry: _loadHome)
                else ...[
                  _NoticeCard(
                    title: latestNotice?['title'] ?? 'Sin avisos',
                    body:
                        latestNotice?['body'] ?? 'Aquí verás el último aviso.',
                    createdAt: _parseDate(latestNotice?['created_at']),
                    fmt: _fmtDMYHM,
                    important: (latestNotice?['important'] as bool?) ?? false,
                    images: allImages.map(_absoluteUrl).toList(),
                    pdfUrl: pdfUrl,
                    onOpenPdf: _openPdfPreview,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Recordatorio de cumpleaños',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                if (isBirthdayToday)
                  _BirthdayBanner(
                    name: name,
                    birthdayText: bday == null ? '—' : _fmtDM(bday),
                    onReplay: () => _confettiCtrl.forward(from: 0),
                    onOpenMonth: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BirthdaysMonthScreen(),
                        ),
                      );
                    },
                  )
                else
                  _BirthdayInfoCard(
                    birthdayText: bday == null ? '—' : _fmtDM(bday),
                  ),
                const SizedBox(height: 12),
                if (!_loading && _error == null)
                  _BirthdaysTodayList(
                    users: birthdaysToday,
                    positionsMap: _positionsMap,
                    onOpenMonth: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BirthdaysMonthScreen(),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 18),
                if (canViewAnniversaries && anniversariesToday.isNotEmpty)
                  _WorkAnniversariesList(
                    users: anniversariesToday,
                    positionsMap: _positionsMap,
                    areasMap: _areasMap,
                  ),
              ],
            ),
          ),
          if (isBirthdayToday)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiAnim,
                builder: (_, __) => CustomPaint(
                  painter: ConfettiPainter(progress: _confettiAnim.value),
                  size: Size.infinite,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NoticeImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const NoticeImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 220,
  });

  @override
  State<NoticeImageGallery> createState() => _NoticeImageGalleryState();
}

class _NoticeImageGalleryState extends State<NoticeImageGallery> {
  late final PageController _controller;
  int index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _HomeGalleryViewer(
          imageUrls: widget.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final images = widget.imageUrls;

    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) {
              return InkWell(
                onTap: () => _openViewer(i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 42),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (index > 0)
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () {
                    _controller.previousPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
        if (index < images.length - 1)
          Positioned(
            right: 5,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.18)
                      : Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
            ),
          ),
        if (images.length > 1)
          Positioned(
            bottom: 8,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${index + 1} / ${images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _HomeGalleryViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_HomeGalleryViewer> createState() => _HomeGalleryViewerState();
}

class _HomeGalleryViewerState extends State<_HomeGalleryViewer> {
  late final PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goPrevious() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goNext() {
    if (currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imageUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${currentIndex + 1} / ${images.length}'),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) {
              setState(() {
                currentIndex = i;
              });
            },
            itemBuilder: (_, i) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    images[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 60,
                    ),
                  ),
                ),
              );
            },
          ),
          if (currentIndex > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _goPrevious,
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          if (currentIndex < images.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _goNext,
                    icon: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BirthdaysTodayList extends StatelessWidget {
  final Map<int, String> positionsMap;
  final List<Map<String, dynamic>> users;
  final VoidCallback onOpenMonth;

  const _BirthdaysTodayList({
    required this.users,
    required this.positionsMap,
    required this.onOpenMonth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (users.isEmpty) {
      return Card(
        elevation: 2,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.cake_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hoy no hay cumpleaños registrados.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onOpenMonth,
                  icon: const Icon(Icons.cake_rounded),
                  label: const Text('Ver cumpleañeros del mes'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cake_rounded),
                const SizedBox(width: 10),
                Text(
                  'Cumpleañeros de hoy',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...users.map((u) {
              final name = (u['name'] ?? '—').toString();
              final rawPos = (u['position'] ?? '').toString().trim();
              final id = int.tryParse(rawPos);

              final position = id != null ? (positionsMap[id] ?? rawPos) : rawPos;

              final raw = (u['avatar'] ?? '').toString();
              final avatar = raw.isEmpty
                  ? ''
                  : (raw.startsWith('http') ? raw : '${AuthService.baseUrl}$raw');

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage:
                          avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar.isEmpty
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (position.isNotEmpty)
                            Text(
                              position,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Text('🎉'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onOpenMonth,
                icon: const Icon(Icons.cake_rounded),
                label: const Text('Ver cumpleañeros del mes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String empNo;
  final String position;
  final VoidCallback? onTap;

  const _UserHeader({
    required this.avatarUrl,
    required this.name,
    required this.empNo,
    required this.position,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = avatarUrl.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 2,
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: s.isNotEmpty ? NetworkImage(s) : null,
                child: s.isEmpty ? const Icon(Icons.person, size: 30) : null,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Empleado #$empNo',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.work_rounded,
                          size: 18,
                          color:
                              theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            position,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
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
      ),
    );
  }
}

class _RedBadge extends StatelessWidget {
  final bool show;
  final String text;

  const _RedBadge({required this.show, required this.text});

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String label;

  const _LoadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error cargando datos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticeCard extends StatefulWidget {
  final String title;
  final String body;
  final DateTime? createdAt;
  final String Function(DateTime) fmt;
  final bool important;

  final List<String> images;
  final String pdfUrl;
  final Function(String) onOpenPdf;

  const _NoticeCard({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.fmt,
    required this.important,
    required this.images,
    required this.pdfUrl,
    required this.onOpenPdf,
  });

  @override
  State<_NoticeCard> createState() => _NoticeCardState();
}

class _NoticeCardState extends State<_NoticeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  bool get isNew {
    if (widget.createdAt == null) return false;
    final diff = DateTime.now().difference(widget.createdAt!.toLocal());
    return diff.inHours <= 24;
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.018).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (widget.important) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _NoticeCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.important && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.important && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateText =
        widget.createdAt == null ? null : widget.fmt(widget.createdAt!.toLocal());

    final showHighlight = widget.important || isNew;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        return Transform.scale(
          scale: widget.important ? _pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: showHighlight
              ? [
                  BoxShadow(
                    color: widget.important
                        ? Colors.red.withOpacity(0.18)
                        : Colors.orange.withOpacity(0.14),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Card(
          elevation: widget.important ? 4 : 2,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: widget.important
                  ? Colors.red.withOpacity(0.30)
                  : isNew
                      ? Colors.orange.withOpacity(0.28)
                      : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: showHighlight
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.important
                          ? [
                              Colors.red.withOpacity(0.08),
                              isDark ? theme.cardColor : Colors.white,
                            ]
                          : [
                              Colors.orange.withOpacity(0.08),
                              isDark ? theme.cardColor : Colors.white,
                            ],
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: widget.important ? 1 : 0,
                        ),
                        duration: const Duration(milliseconds: 700),
                        builder: (_, value, child) {
                          return Transform.rotate(
                            angle: value * 0.08 * math.sin(value * math.pi * 2),
                            child: child,
                          );
                        },
                        child: Icon(
                          Icons.campaign_rounded,
                          color: widget.important ? Colors.red : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isNew) ...[
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'NUEVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                      if (widget.important)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'IMPORTANTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                    ),
                  ),
                  if (widget.images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    NoticeImageGallery(
                      imageUrls: widget.images,
                      height: 220,
                    ),
                  ],
                  if (widget.pdfUrl.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.red.withOpacity(0.12)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.red.withOpacity(0.28)
                              : Colors.red.shade100,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'PDF adjunto',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => widget.onOpenPdf(widget.pdfUrl),
                            child: const Text('Ver'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (dateText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      dateText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      color: theme.cardColor,
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
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
                ),
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
  final String birthdayText;
  final VoidCallback onReplay;
  final VoidCallback onOpenMonth;

  const _BirthdayBanner({
    required this.name,
    required this.birthdayText,
    required this.onReplay,
    required this.onOpenMonth,
  });

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
    final theme = Theme.of(context);
    final displayName = widget.name.isEmpty ? '' : ' ${widget.name}';

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.rotate(
        angle: _rotate.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Card(
            elevation: 3,
            color: theme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
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
                          '¡Feliz cumpleaños$displayName! 🎉🥧🎈',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Que tengas un gran día. 🥳',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (widget.birthdayText != '—') ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tu cumpleaños es: ${widget.birthdayText}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.85),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              TextButton.icon(
                                onPressed: widget.onReplay,
                                icon: const Icon(Icons.replay_rounded),
                                label: const Text('Repetir confetti'),
                              ),
                            ],
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

class _WorkAnniversariesList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final Map<int, String> positionsMap;
  final Map<int, String> areasMap;

  const _WorkAnniversariesList({
    required this.users,
    required this.positionsMap,
    required this.areasMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = users.length;

    return Card(
      elevation: 3,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(0.10),
              Colors.orange.withOpacity(0.06),
              isDark ? theme.cardColor : Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aniversarios laborales',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      total == 1 ? '1 aniversario' : '$total aniversarios',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                total == 1
                    ? 'Hoy hay 1 aniversario laboral en esta lista.'
                    : 'Hoy hay $total aniversarios laborales en esta lista.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              ...users.map((u) {
                final name = (u['name'] ?? '—').toString();

                final rawArea = (u['area'] ?? '').toString().trim();
                final areaId = int.tryParse(rawArea);
                final dept = areaId != null
                    ? (areasMap[areaId] ?? rawArea)
                    : (rawArea.isEmpty ? 'Sin departamento' : rawArea);

                final rawPos = (u['position'] ?? '').toString().trim();
                final posId = int.tryParse(rawPos);
                final position = posId != null
                    ? (positionsMap[posId] ?? rawPos)
                    : (rawPos.isEmpty ? 'Sin puesto' : rawPos);

                final years = (u['years'] as num?)?.toInt() ?? 0;
                final rank = (u['rank'] as num?)?.toInt() ?? 0;

                final raw = (u['avatar'] ?? '').toString().trim();
                final avatar = raw.isEmpty
                    ? ''
                    : (raw.startsWith('http')
                        ? raw
                        : '${AuthService.baseUrl}$raw');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? const Icon(Icons.person, size: 20)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              position,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dept,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (rank > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '#$rank',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              years == 1 ? '1 año' : '$years años',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}