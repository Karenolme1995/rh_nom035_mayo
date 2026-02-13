import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/scheduler.dart';

import '../utils/export_csv.dart';
import '../services/notices_service.dart';

class UsersScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UsersScreen({super.key, required this.userData});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _svc = NoticesService();
  final _picker = ImagePicker();

  bool _loading = true;
  bool _saving = false;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _positions = [];

  // ✅ DataSource persistente (SIEMPRE inicializado)
  late final _UsersDataSource _ds;

  bool get _canManageUsers {
    final roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    return roleId == 1 || roleId == 2; // Admin + RH
  }

  // ✅ setState seguro (evita mouse_tracker en web)
  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer =
        phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.postFrameCallbacks;

    if (shouldDefer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  // ✅ Sanitiza respuesta API
  Map<String, dynamic> _asStringMap(dynamic x) {
    if (x is Map<String, dynamic>) return x;
    if (x is Map) return x.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfStringMaps(dynamic x) {
    if (x is! List) return <Map<String, dynamic>>[];
    return x.map(_asStringMap).where((m) => m.isNotEmpty).toList();
  }

  String _areaNameFromValue(dynamic v) {
    if (v == null) return '—';
    final byId = _areas.where((a) => a['id'].toString() == v.toString()).toList();
    if (byId.isNotEmpty) return (byId.first['name'] ?? '—').toString();
    final s = v.toString();
    return s.isEmpty ? '—' : s;
  }

  String _positionNameFromValue(dynamic v) {
    if (v == null) return '—';
    final byId = _positions.where((p) => p['id'].toString() == v.toString()).toList();
    if (byId.isNotEmpty) return (byId.first['name'] ?? '—').toString();
    final s = v.toString();
    return s.isEmpty ? '—' : s;
  }

  String _fmtDate(dynamic value) {
    if (value == null) return '—';
    final s = value.toString();
    if (s.isEmpty) return '—';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  @override
  void initState() {
    super.initState();

    // ✅ SIEMPRE inicializar _ds (aunque no tenga permisos)
    _ds = _UsersDataSource(
      // context no lo uses para nada en datasource, solo lo guardamos por firma
      context: context,
      initialUsers: _users,
      areaName: _areaNameFromValue,
      posName: _positionNameFromValue,
      fmtDate: _fmtDate,
      onEdit: _openEdit,
      onDelete: _confirmDelete,
      onToggleActive: _toggleActive,
    );

    if (_canManageUsers) {
      _loadAll();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        safeSetState(() => _loading = false);
      });
    }
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    safeSetState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.getUsers(),
        _svc.getAreas(),
        _svc.getPositions(),
      ]);

      safeSetState(() {
        _users = _asListOfStringMaps(results[0]);
        _areas = _asListOfStringMaps(results[1]);
        _positions = _asListOfStringMaps(results[2]);
      });

      _ds.setUsers(_users);
    } catch (e) {
      _showSnack('Error cargando datos: $e', isError: true);
    } finally {
      if (mounted) safeSetState(() => _loading = false);
    }
  }

  Future<void> _refreshUsers() async {
    try {
      final list = await _svc.getUsers();
      if (!mounted) return;
      safeSetState(() {
        _users = _asListOfStringMaps(list);
      });
      _ds.setUsers(_users);
    } catch (e) {
      _showSnack('Error al recargar usuarios: $e', isError: true);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> u) async {
    final id = u['id'];
    if (id == null) {
      _showSnack('Usuario sin ID (dato inválido)', isError: true);
      return;
    }

    final raw = u['active'];
    final current = raw == true || raw == 1 || raw?.toString() == '1' ? 1 : 0;
    final next = current == 1 ? 0 : 1;

    try {
      await _svc.updateUser(id, {'active': next});
      if (!mounted) return;

      safeSetState(() {
        final idx = _users.indexWhere((x) => x['id'] == id);
        if (idx != -1) _users[idx] = {..._users[idx], 'active': next};
      });

      _ds.setUsers(_users);
    } catch (e) {
      _showSnack('No se pudo actualizar activo: $e', isError: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> u) async {
    final name = (u['name'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a "$name"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) await _deleteUser(u);
  }

  Future<void> _deleteUser(Map<String, dynamic> u) async {
    final id = u['id'];
    if (id == null) {
      _showSnack('Usuario sin ID (dato inválido)', isError: true);
      return;
    }
    if (!mounted) return;

    safeSetState(() => _saving = true);
    try {
      await _svc.deleteUser(id);

      if (!mounted) return;
      safeSetState(() {
        _users.removeWhere((x) => x['id'] == id);
      });

      _ds.setUsers(_users);
      _showSnack('Usuario eliminado');
    } catch (e) {
      _showSnack('No se pudo eliminar: $e', isError: true);
    } finally {
      if (mounted) safeSetState(() => _saving = false);
    }
  }

  Future<void> _openEdit(Map<String, dynamic> user) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.65,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: _UserFormSheet(
                title: 'Editar usuario',
                areas: _areas,
                positions: _positions,
                initial: user,
                onSave: (payload) => _svc.updateUser(user['id'], payload),
                onUploadAvatar: () => _pickAndUploadAvatar(user),
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );

    if (updated == true) {
      await _refreshUsers();
    }
  }

  Future<void> _openCreate() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.65,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: _UserFormSheet(
                title: 'Nuevo empleado',
                areas: _areas,
                positions: _positions,
                onSave: (payload) => _svc.createUser(payload),
                onUploadAvatar: null,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      await _refreshUsers();
    }
  }

  Future<void> _pickAndUploadAvatar(Map<String, dynamic> user) async {
    final id = user['id'];
    if (id == null) {
      _showSnack('Usuario sin ID (dato inválido)', isError: true);
      return;
    }

    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1000,
    );
    if (x == null) return;

    if (!mounted) return;
    safeSetState(() => _saving = true);
    try {
      final file = File(x.path);
      final newUrl = await _svc.uploadUserAvatar(id, file);

      if (!mounted) return;
      safeSetState(() {
        final idx = _users.indexWhere((u) => u['id'] == id);
        if (idx != -1) _users[idx] = {..._users[idx], 'avatar': newUrl};
      });

      _ds.setUsers(_users);
      _showSnack('Avatar actualizado');
    } catch (e) {
      _showSnack('No se pudo actualizar avatar: $e', isError: true);
    } finally {
      if (mounted) safeSetState(() => _saving = false);
    }
  }

  Future<void> _exportCsv() async {
    if (_users.isEmpty) return;

    String esc(dynamic v) {
      final s = (v ?? '').toString().replaceAll('"', '""');
      return '"$s"';
    }

    final headers = [
      'id',
      'employee_number',
      'name',
      'email',
      'role_id',
      'area',
      'position',
      'active',
      'entry_date',
      'birthday',
      'phone',
      'curp',
      'plant',
      'avatar'
    ];

    final rows = <String>[];
    rows.add(headers.map(esc).join(','));

    for (final u in _users) {
      rows.add([
        u['id'],
        u['employee_number'],
        u['name'],
        u['email'],
        u['role_id'],
        u['area'],
        u['position'],
        u['active'],
        u['entry_date'],
        u['birthday'],
        u['phone'],
        u['curp'],
        u['plant'],
        u['avatar'],
      ].map(esc).join(','));
    }

    final csv = rows.join('\n');

    try {
      await exportCsv('usuarios.csv', csv);
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageUsers) {
      return const Center(child: Text('No tienes permisos para ver esta sección.'));
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Usuarios',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _users.isEmpty ? null : _exportCsv,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Exportar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _openCreate,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Nuevo'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAll,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  children: [
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.black12),
                      ),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: c.maxWidth),
                              child: PaginatedDataTable(
                                header: const Text('Listado'),
                                rowsPerPage: 10,
                                showFirstLastButtons: true,
                                columns: const [
                                  DataColumn(label: Text('ID')),
                                  DataColumn(label: Text('Empleado')),
                                  DataColumn(label: Text('Nombre')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Rol')),
                                  DataColumn(label: Text('Área')),
                                  DataColumn(label: Text('Puesto')),
                                  DataColumn(label: Text('Ingreso')),
                                  DataColumn(label: Text('Activo')),
                                  DataColumn(label: Text('Acciones')),
                                ],
                                source: _ds,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_saving)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black.withOpacity(0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}

class _UsersDataSource extends DataTableSource {
  final BuildContext context;
  List<Map<String, dynamic>> _users = [];

  final String Function(dynamic v) areaName;
  final String Function(dynamic v) posName;
  final String Function(dynamic v) fmtDate;

  final void Function(Map<String, dynamic> u) onEdit;
  final void Function(Map<String, dynamic> u) onDelete;
  final void Function(Map<String, dynamic> u) onToggleActive;

  _UsersDataSource({
    required this.context,
    required List<Map<String, dynamic>> initialUsers,
    required this.areaName,
    required this.posName,
    required this.fmtDate,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  }) {
    _users = initialUsers;
  }

  void setUsers(List<Map<String, dynamic>> next) {
    _users = next;
    notifyListeners();
  }

  String s(dynamic v) => (v == null) ? '' : v.toString();

  bool _isActive(dynamic raw) {
    if (raw == null) return false;
    if (raw == true) return true;
    if (raw is num) return raw.toInt() == 1;
    final t = raw.toString().toLowerCase();
    return t == '1' || t == 'true';
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _users.length) return null;
    final u = _users[index];
    final active = _isActive(u['active']);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(s(u['id']))),
        DataCell(Text(s(u['employee_number']))),
        DataCell(Text(s(u['name']))),
        DataCell(Text(s(u['email']))),
        DataCell(Text(s(u['role_id']))),
        DataCell(Text(areaName(u['area']))),
        DataCell(Text(posName(u['position']))),
        DataCell(Text(fmtDate(u['entry_date']))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active ? Colors.green.withOpacity(.12) : Colors.red.withOpacity(.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: active ? Colors.green : Colors.redAccent),
            ),
            child: Text(
              active ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: active ? Colors.green.shade700 : Colors.redAccent,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              IconButton(
                tooltip: null,
                mouseCursor: SystemMouseCursors.basic,
                hoverColor: Colors.transparent,
                splashRadius: 20,
                enableFeedback: false,
                onPressed: () => onEdit(u),
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                tooltip: null,
                mouseCursor: SystemMouseCursors.basic,
                hoverColor: Colors.transparent,
                splashRadius: 20,
                enableFeedback: false,
                onPressed: () => onDelete(u),
                icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              ),
              IconButton(
                tooltip: null,
                mouseCursor: SystemMouseCursors.basic,
                hoverColor: Colors.transparent,
                splashRadius: 20,
                enableFeedback: false,
                onPressed: () => onToggleActive(u),
                icon: Icon(active ? Icons.toggle_off_rounded : Icons.toggle_on_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _users.length;

  @override
  int get selectedRowCount => 0;
}

class _UserFormSheet extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? initial;
  final List<Map<String, dynamic>> areas;
  final List<Map<String, dynamic>> positions;

  final Future<void> Function(Map<String, dynamic> payload) onSave;
  final Future<void> Function()? onUploadAvatar;

  final ScrollController scrollController;

  const _UserFormSheet({
    required this.title,
    required this.areas,
    required this.positions,
    required this.onSave,
    required this.scrollController,
    this.onUploadAvatar,
    this.initial,
    super.key,
  });

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _showPassword = false;

  late final TextEditingController employeeNumber;
  late final TextEditingController name;
  late final TextEditingController email;
  late final TextEditingController curp;
  late final TextEditingController password;
  late final TextEditingController roleId;
  late final TextEditingController birthday;
  late final TextEditingController phone;
  late final TextEditingController entryDate;
  late final TextEditingController plant;

  int active = 1;
  String? areaValue;
  String? positionValue;

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer =
        phase == SchedulerPhase.persistentCallbacks || phase == SchedulerPhase.postFrameCallbacks;

    if (shouldDefer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    final u = widget.initial ?? {};

    employeeNumber = TextEditingController(text: (u['employee_number'] ?? '').toString());
    name = TextEditingController(text: (u['name'] ?? '').toString());
    email = TextEditingController(text: (u['email'] ?? '').toString());
    curp = TextEditingController(text: (u['curp'] ?? '').toString());
    password = TextEditingController(text: '');
    roleId = TextEditingController(text: (u['role_id'] ?? '').toString());
    birthday = TextEditingController(text: _fmtDate(u['birthday']));
    phone = TextEditingController(text: (u['phone'] ?? '').toString());
    entryDate = TextEditingController(text: _fmtDate(u['entry_date']));
    plant = TextEditingController(text: (u['plant'] ?? '').toString());

    active = ((u['active'] as num?)?.toInt() ?? (u['active']?.toString() == '1' ? 1 : 1));
    areaValue = u['area']?.toString();
    positionValue = u['position']?.toString();

    _autoPasswordIfCreate();
  }

  void _autoPasswordIfCreate() {
    final isEdit = widget.initial != null;
    if (isEdit) return;

    void rebuild() {
      final emp = employeeNumber.text.trim();
      final nm = name.text.trim();
      if (emp.isEmpty || nm.isEmpty) return;

      final parts = nm.split(RegExp(r'\s+')).where((x) => x.trim().isNotEmpty).toList();
      final first = parts.isNotEmpty ? parts[0] : '';
      final second = parts.length > 1 ? parts[1] : '';
      final initials =
          '${first.isNotEmpty ? first[0] : ''}${second.isNotEmpty ? second[0] : ''}'.toLowerCase();

      final gen = '$initials$emp';
      if (password.text.trim().isEmpty) {
        password.text = gen;
      }
    }

    employeeNumber.addListener(rebuild);
    name.addListener(rebuild);
  }

  @override
  void dispose() {
    employeeNumber.dispose();
    name.dispose();
    email.dispose();
    curp.dispose();
    password.dispose();
    roleId.dispose();
    birthday.dispose();
    phone.dispose();
    entryDate.dispose();
    plant.dispose();
    super.dispose();
  }

  static String _fmtDate(dynamic value) {
    if (value == null) return '';
    final s = value.toString();
    if (s.isEmpty) return '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  List<Map<String, dynamic>> get _activeAreas =>
      widget.areas.where((a) => ((a['active'] as num?)?.toInt() ?? 1) == 1).toList();

  List<Map<String, dynamic>> get _activePositions {
    final all = widget.positions.where((p) => ((p['active'] as num?)?.toInt() ?? 1) == 1).toList();
    final a = areaValue;
    if (a == null || a.isEmpty) return all;

    return all.where((p) {
      final areaId = p['area_id'];
      if (areaId == null) return true;
      return areaId.toString() == a.toString();
    }).toList();
  }

  Future<void> _save() async {
    final st = _formKey.currentState;
    if (st == null) return;
    if (!st.validate()) return;

    final payload = <String, dynamic>{
      'employee_number': employeeNumber.text.trim(),
      'name': name.text.trim(),
      'email': email.text.trim().isEmpty ? null : email.text.trim(),
      'curp': curp.text.trim().isEmpty ? null : curp.text.trim(),
      'phone': phone.text.trim().isEmpty ? null : phone.text.trim(),
      'role_id': int.tryParse(roleId.text.trim()) ?? 3,
      'area': areaValue,
      'position': positionValue,
      'birthday': birthday.text.trim().isEmpty ? null : birthday.text.trim(),
      'entry_date': entryDate.text.trim().isEmpty ? null : entryDate.text.trim(),
      'active': active,
      'plant': plant.text.trim().isEmpty ? null : plant.text.trim(),
    };

    if (password.text.trim().isNotEmpty) {
      payload['password'] = password.text.trim();
    }

    if (!mounted) return;
    safeSetState(() => _saving = true);
    try {
      await widget.onSave(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) safeSetState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: c,
        builder: (_, __, ___) {
          final filled = c.text.trim().isNotEmpty;
          return TextFormField(
            controller: c,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: icon != null ? Icon(icon) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: filled ? Colors.green : Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: filled ? Colors.green : Colors.blue, width: 2),
              ),
            ),
            validator: (v) {
              if (!required) return null;
              if (v == null || v.trim().isEmpty) return 'Requerido';
              return null;
            },
          );
        },
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, __, ___) {
          final filled = controller.text.trim().isNotEmpty;
          return TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              suffixIcon: IconButton(
                tooltip: null,
                mouseCursor: SystemMouseCursors.basic,
                hoverColor: Colors.transparent,
                splashRadius: 20,
                enableFeedback: false,
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: now,
                    firstDate: DateTime(1950, 1, 1),
                    lastDate: DateTime(now.year + 1, 12, 31),
                  );
                  if (picked != null) {
                    final s =
                        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    controller.text = s;
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: filled ? Colors.green : Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: filled ? Colors.green : Colors.blue, width: 2),
              ),
            ),
            keyboardType: TextInputType.datetime,
            validator: (v) {
              if (!required) return null;
              if (v == null || v.trim().isEmpty) return 'Requerido';
              return null;
            },
          );
        },
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    bool required = true,
  }) {
    final filled = (value != null && value.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: filled ? value : null,
        items: items,
        onChanged: _saving
            ? null
            : (v) {
                onChanged(v);
                safeSetState(() {});
              },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: filled ? Colors.green : Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: filled ? Colors.green : Colors.blue, width: 2),
          ),
        ),
        validator: (v) {
          if (!required) return null;
          if (v == null || v.isEmpty) return 'Selecciona una opción';
          return null;
        },
      ),
    );
  }

  Widget _autocompleteSelect({
    required String label,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String? selectedId,
    required void Function(String? id) onSelected,
    bool required = true,
  }) {
    String nameOf(Map<String, dynamic> x) => (x['name'] ?? '').toString();
    String idOf(Map<String, dynamic> x) => (x['id'] ?? '').toString();

    final initialText = () {
      if (selectedId == null || selectedId!.isEmpty) return '';
      final match = items.where((x) => idOf(x) == selectedId).toList();
      if (match.isEmpty) return '';
      return nameOf(match.first);
    }();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Autocomplete<Map<String, dynamic>>(
        displayStringForOption: (opt) => nameOf(opt),
        optionsBuilder: (TextEditingValue v) {
          final q = v.text.trim().toLowerCase();
          if (q.isEmpty) return items;
          return items.where((e) => nameOf(e).toLowerCase().contains(q));
        },
        initialValue: TextEditingValue(text: initialText),
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return Focus(
            onFocusChange: (hasFocus) {
              if (!hasFocus) {
                if (controller.text.trim().isEmpty) onSelected(null);
              }
            },
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (_) {
                if (!required) return null;
                if (selectedId == null || selectedId.isEmpty) return 'Selecciona una opción';
                return null;
              },
            ),
          );
        },
        onSelected: (opt) => onSelected(idOf(opt)),
        optionsViewBuilder: (context, onSelectedOpt, opts) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260, maxWidth: 520),
                child: ListView.builder(
                  padding: const EdgeInsets.all(6),
                  itemCount: opts.length,
                  itemBuilder: (_, i) {
                    final opt = opts.elementAt(i);
                    return ListTile(
                      dense: true,
                      title: Text(nameOf(opt)),
                      onTap: () => onSelectedOpt(opt),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: null,
                    mouseCursor: SystemMouseCursors.basic,
                    hoverColor: Colors.transparent,
                    splashRadius: 20,
                    enableFeedback: false,
                    onPressed: _saving ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isEdit) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : widget.onUploadAvatar,
                    icon: const Icon(Icons.photo_camera_back_rounded),
                    label: const Text('Actualizar avatar (opcional)'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    primary: false,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.black12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Datos básicos', style: TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 10),
                                _field(employeeNumber, 'Número de empleado', icon: Icons.badge_rounded),
                                _field(name, 'Nombre (incluye apellidos)', icon: Icons.person_rounded),
                                _field(email, 'Email (opcional)',
                                    icon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    required: false),
                                _field(curp, 'CURP (opcional)', icon: Icons.assignment_ind_rounded, required: false),
                                _field(phone, 'Teléfono (opcional)',
                                    icon: Icons.phone_rounded, keyboardType: TextInputType.phone, required: false),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TextFormField(
                                    controller: password,
                                    obscureText: !_showPassword,
                                    decoration: InputDecoration(
                                      labelText: isEdit ? 'Password (opcional)' : 'Password (auto)',
                                      prefixIcon: const Icon(Icons.lock_rounded),
                                      suffixIcon: IconButton(
                                        tooltip: null,
                                        mouseCursor: SystemMouseCursors.basic,
                                        hoverColor: Colors.transparent,
                                        splashRadius: 20,
                                        enableFeedback: false,
                                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                                        onPressed: () => safeSetState(() => _showPassword = !_showPassword),
                                      ),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    validator: (v) {
                                      if (!isEdit && (v == null || v.trim().isEmpty)) return 'Requerido';

                                      final emp = employeeNumber.text.trim();
                                      final nm = name.text.trim();
                                      if (emp.isNotEmpty && nm.isNotEmpty && (v ?? '').trim().isNotEmpty) {
                                        final parts = nm.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
                                        final first = parts.isNotEmpty ? parts[0] : '';
                                        final second = parts.length > 1 ? parts[1] : '';
                                        final initials =
                                            '${first.isNotEmpty ? first[0] : ''}${second.isNotEmpty ? second[0] : ''}'
                                                .toLowerCase();
                                        final expected = '$initials$emp';
                                        if (v!.trim().toLowerCase() != expected) {
                                          return 'Debe ser "$expected" (2 iniciales + num empleado)';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _dropdown(
                                  label: 'Rol',
                                  value: roleId.text.trim().isEmpty ? null : roleId.text.trim(),
                                  icon: Icons.admin_panel_settings_rounded,
                                  items: const [
                                    DropdownMenuItem(value: '1', child: Text('1 - Administrador')),
                                    DropdownMenuItem(value: '2', child: Text('2 - Recursos Humanos')),
                                    DropdownMenuItem(value: '3', child: Text('3 - Empleado')),
                                  ],
                                  onChanged: (v) => roleId.text = v ?? '3',
                                ),
                                _dateField(
                                  controller: birthday,
                                  label: 'Cumpleaños (YYYY-MM-DD) (opcional)',
                                  icon: Icons.cake_rounded,
                                  required: false,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Colors.black12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Laboral', style: TextStyle(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 10),
                                _autocompleteSelect(
                                  label: 'Área (escribe para buscar)',
                                  icon: Icons.apartment_rounded,
                                  items: _activeAreas,
                                  selectedId: areaValue,
                                  onSelected: (String? id) {
                                    safeSetState(() {
                                      areaValue = id;
                                      positionValue = null;
                                    });
                                  },
                                ),
                                _autocompleteSelect(
                                  label: 'Puesto (escribe para buscar)',
                                  icon: Icons.work_rounded,
                                  items: _activePositions,
                                  selectedId: positionValue,
                                  onSelected: (String? id) => safeSetState(() => positionValue = id),
                                ),
                                _dateField(
                                  controller: entryDate,
                                  label: 'Fecha de ingreso (YYYY-MM-DD) (opcional)',
                                  icon: Icons.event_available_rounded,
                                  required: false,
                                ),
                                _field(plant, 'Planta (opcional)', icon: Icons.factory_rounded, required: false),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: active == 1,
                                  onChanged: _saving ? null : (v) => safeSetState(() => active = v ? 1 : 0),
                                  title: const Text('Activo'),
                                  secondary: Icon(active == 1 ? Icons.toggle_on_rounded : Icons.toggle_off_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.save_rounded),
                            label: Text(isEdit ? 'Actualizar información' : 'Crear usuario'),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
