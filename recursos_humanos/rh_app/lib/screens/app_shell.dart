import 'package:flutter/material.dart';
import '../main.dart';
import '../models/menu_item.dart';
import '../services/auth_service.dart';
import '../services/notices_service.dart';

import 'home_screen.dart';
import 'courses_screen.dart';
import 'evaluations_screen.dart';
import 'user_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'acerca_screen.dart';

class AppShell extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.userData,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late Map<String, dynamic> _userData;

  late final int roleId;
  late final List<MenuItemData> allItems;
  late List<MenuItemData> items;

  late int selectedIndex;
  int unreadNotices = 0;
  bool _refreshingProfile = false;

  static String get _baseUrl => AuthService.baseUrl;

  String _absoluteUrl(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) return '$_baseUrl$s';
    return '$_baseUrl/$s';
  }

  String _getLastNameInitial(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '?';

    if (parts.length >= 2) {
      return parts.last.substring(0, 1).toUpperCase();
    }

    return parts.first.substring(0, 1).toUpperCase();
  }

  Future<void> _loadUnread() async {
    try {
      final count = await NoticesService.getUnreadNoticeCount();
      if (!mounted) return;
      setState(() => unreadNotices = count);
    } catch (_) {}
  }

  Future<void> _refreshProfile({bool silent = true}) async {
    if (_refreshingProfile) return;
    _refreshingProfile = true;

    try {
      final profile = await NoticesService().getMyProfile();
      if (!mounted) return;

      setState(() {
        _userData = {
          ..._userData,
          ...Map<String, dynamic>.from(profile),
        };
      });
    } catch (e) {
      debugPrint('Error recargando perfil: $e');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo recargar el perfil: $e')),
        );
      }
    } finally {
      _refreshingProfile = false;
    }
  }

  Widget _buildCurrentPage() {
    final current = items[selectedIndex];

    switch (current.id) {
      case 'home':
        return HomeScreen(userData: _userData);

      case 'notices':
        return NotificationsScreen(userData: _userData);

      case 'courses':
        return CoursesScreen(userData: _userData);

      case 'evaluations':
        return EvaluationsScreen(userData: _userData);

      case 'users':
        return UsersScreen(userData: _userData);

      case 'profile':
        return ProfileScreen(userData: _userData);

      case 'info':
        return AcercaScreen(userData: _userData);

      default:
        return HomeScreen(userData: _userData);
    }
  }

  Future<void> _handleMenuTap(int i) async {
    final item = items[i];

    if (item.id == 'profile') {
      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userData: _userData),
        ),
      );

      await _refreshProfile(silent: false);
      return;
    }

    setState(() => selectedIndex = i);
    Navigator.pop(context);

    if (item.id == 'notices') {
      await Future.delayed(const Duration(milliseconds: 300));
      _loadUnread();
    }
  }

  @override
  void initState() {
    super.initState();

    _userData = Map<String, dynamic>.from(widget.userData);
    selectedIndex = widget.initialIndex;

    roleId = (_userData['role_id'] as num?)?.toInt() ?? 0;

    allItems = [
      MenuItemData(
        id: 'home',
        title: 'Inicio',
        icon: Icons.home_rounded,
        page: const SizedBox.shrink(),
        rolesAllowed: const [1, 2, 3],
      ),
      MenuItemData(
        id: 'notices',
        title: 'Avisos',
        icon: Icons.campaign_rounded,
        page: const SizedBox.shrink(),
        rolesAllowed: const [1, 2, 3],
      ),
      MenuItemData(
        id: 'courses',
        title: 'NOM-035-STPS',
        icon: Icons.school_rounded,
        page: const SizedBox.shrink(),
        rolesAllowed: const [1, 2, 3],
      ),
      MenuItemData(
        id: 'evaluations',
        title: 'Evaluaciones',
        icon: Icons.fact_check_rounded,
        page: const SizedBox.shrink(),
        rolesAllowed: const [1, 2, 3],
      ),
      MenuItemData(
        id: 'users',
        title: 'Usuarios',
        icon: Icons.people_alt_rounded,
        page: const SizedBox.shrink(),
        rolesAllowed: const [1, 2],
      ),
      MenuItemData(
        id: 'profile',
        title: 'Mi perfil',
        icon: Icons.person_rounded,
        page: const SizedBox.shrink(),
        rolesAllowed: const [1, 2, 3],
      ),
      MenuItemData(
        id: 'info',
        title: 'Acerca de',
        icon: Icons.info_rounded,
        page: const SizedBox.shrink(),
        rolesAllowed: const [1, 2, 3],
      ),
    ];

    items = allItems.where((i) => i.rolesAllowed.contains(roleId)).toList();
    if (items.isEmpty) items = [allItems.first];

    if (selectedIndex >= items.length) selectedIndex = 0;

    _loadUnread();
    _refreshProfile();
  }

  @override
  Widget build(BuildContext context) {
    final current = items[selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            current.title,
            key: ValueKey(current.id),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _refreshProfile();
          _loadUnread();
        }
      },
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: Material(
          key: ValueKey('${current.id}-${_userData['avatar'] ?? ''}'),
          color: Colors.transparent,
          child: _buildCurrentPage(),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final name = (_userData['name'] ?? '').toString();
    final email = (_userData['email'] ?? '').toString();
    final avatarUrl = _absoluteUrl(_userData['avatar']);
    final employeeNumber = (_userData['employee_number'] ?? '').toString();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E3A8A),
                            const Color(0xFF2563EB),
                          ]
                        : [
                            Colors.blue.shade700,
                            Colors.blue.shade500,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.blue)
                          .withOpacity(0.20),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                      child: TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.95, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: CircleAvatar(
                          key: ValueKey(avatarUrl),
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: avatarUrl.isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Center(
                                        child: Text(
                                          _getLastNameInitial(name),
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? const Color(0xFF1E3A8A)
                                                : Colors.blue.shade700,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Center(
                                    child: Text(
                                      _getLastNameInitial(name),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFF1E3A8A)
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? '—' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (employeeNumber.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Empleado: $employeeNumber',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (employeeNumber.isNotEmpty)
                            const SizedBox(height: 6),
                          Text(
                            email.isEmpty ? '—' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.blue.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        key: ValueKey(isDark),
                        color: isDark ? Colors.amber : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isDark ? 'Modo oscuro activado' : 'Modo oscuro',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: isDark,
                      onChanged: (_) async {
                        await MyApp.of(context)?.toggleTheme();
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            const Divider(height: 1),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final selected = i == selectedIndex;

                  Widget tile;

                  if (item.id == 'notices') {
                    tile = Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _DrawerTile(
                          icon: item.icon,
                          title: item.title,
                          selected: selected,
                          onTap: () => _handleMenuTap(i),
                        ),
                        if (unreadNotices > 0)
                          Positioned(
                            right: 18,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$unreadNotices',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  } else {
                    tile = _DrawerTile(
                      icon: item.icon,
                      title: item.title,
                      selected: selected,
                      onTap: () => _handleMenuTap(i),
                    );
                  }

                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 220 + (i * 70)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(18 * (1 - value), 0),
                          child: child,
                        ),
                      );
                    },
                    child: tile,
                  );
                },
              ),
            ),

            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: _DrawerTile(
                icon: Icons.logout_rounded,
                title: 'Cerrar sesión',
                selected: false,
                isDanger: true,
                onTap: () async {
                  await AuthService.logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final bool isDanger;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = selected
        ? (isDark
            ? Colors.white.withOpacity(0.10)
            : Colors.blue.withOpacity(0.12))
        : Colors.transparent;

    final color = isDanger
        ? Colors.redAccent
        : (selected
            ? (isDark ? Colors.white : Colors.blue)
            : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: selected ? 1.08 : 1.0,
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: selected ? 1 : 0,
                child: Icon(Icons.chevron_right_rounded, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}