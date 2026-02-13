import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'courses_screen.dart';
import 'evaluations_screen.dart';
import 'user_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class AppShell extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AppShell({super.key, required this.userData});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final int roleId;
  late final List<MenuItemData> allItems;
  late List<MenuItemData> items;

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;

    allItems = [
      MenuItemData(
        id: 'home',
        title: 'Inicio',
        icon: Icons.home_rounded,
        page: HomeScreen(userData: widget.userData),
        rolesAllowed: const [1, 2, 3],
      ),

      // ❌ Quitamos "Avisos / notices" por el momento
      // MenuItemData(
      //   id: 'notices',
      //   title: 'Avisos',
      //   icon: Icons.campaign_rounded,
      //   page: NotificationsScreen(userData: widget.userData),
      //   rolesAllowed: const [1, 2, 3],
      // ),

      MenuItemData(
        id: 'courses',
        title: 'Cursos',
        icon: Icons.school_rounded,
        page: CoursesScreen(userData: widget.userData),
        rolesAllowed: const [1, 2, 3],
      ),

      MenuItemData(
        id: 'evaluations',
        title: 'Evaluaciones',
        icon: Icons.fact_check_rounded,
        page: EvaluationsScreen(userData: widget.userData),
        rolesAllowed: const [1, 2, 3], // ejemplo: empleado no ve evaluaciones
      ),
      
      // SOLO Admin y RH
  MenuItemData(
    id: 'users',
    title: 'Usuarios',
    icon: Icons.people_alt_rounded,
    page: UsersScreen(userData: widget.userData),
    rolesAllowed: const [1, 2],
  ),
      // todos los roles 
      MenuItemData(
        id: 'profile',
        title: 'Mi perfil',
        icon: Icons.person_rounded,
        page: ProfileScreen(userData: widget.userData),
        rolesAllowed: const [1, 2, 3],
      ),
    ];

    items = allItems.where((i) => i.rolesAllowed.contains(roleId)).toList();
    if (items.isEmpty) items = [allItems.first];

    if (selectedIndex >= items.length) selectedIndex = 0;
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: Container(
          key: ValueKey(current.id),
          child: current.page,
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    final name = (widget.userData['name'] ?? '').toString();
    final email = (widget.userData['email'] ?? '').toString();
    final avatarUrl = widget.userData['avatar'];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 26)
                        : null,
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
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email.isEmpty ? '—' : email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  final selected = i == selectedIndex;

                  return _DrawerTile(
                    icon: item.icon,
                    title: item.title,
                    selected: selected,
                    onTap: () {
                      setState(() => selectedIndex = i);
                      Navigator.pop(context);
                    },
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
    final bg = selected ? Colors.blue.withOpacity(0.12) : Colors.transparent;
    final color =
        isDanger ? Colors.redAccent : (selected ? Colors.blue : Colors.black87);

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