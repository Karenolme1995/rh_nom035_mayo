// lib/screens/user_screen.dart
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../services/notices_service.dart';
import '../services/auth_service.dart';
import '../utils/export_csv.dart';

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

  late final _UsersDataSource _ds;

  final TextEditingController _searchC = TextEditingController();
  String _q = '';
  String? _areaFilter;
  String? _posFilter;

  String _sortBy = 'employee_number';
  bool _sortAscending = true;

  String get _sortDropdownValue =>
      '${_sortBy}_${_sortAscending ? 'asc' : 'desc'}';

  int _page = 0;
  final int _rowsPerPage = 20;

  String? _highlightNewEmployeeNumber;

  bool get _canManageUsers {
    final roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    return roleId == 1 || roleId == 2;
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.postFrameCallbacks;

    if (shouldDefer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(fn);
      });
    } else {
      setState(fn);
    }
  }

  Map<String, dynamic> _asStringMap(dynamic x) {
    if (x is Map<String, dynamic>) return x;
    if (x is Map) return x.map((k, v) => MapEntry(k.toString(), v));
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfStringMaps(dynamic x) {
    if (x is! List) return <Map<String, dynamic>>[];
    return x.map(_asStringMap).where((m) => m.isNotEmpty).toList();
  }

  int _compareNullableStrings(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 0;
    if (a.isEmpty) return 1;
    if (b.isEmpty) return -1;
    return a.compareTo(b);
  }

  int _employeeSortValue(Map<String, dynamic> u) {
    final raw = (u['employee_number'] ?? '').toString().trim();
    final n = int.tryParse(raw);
    if (n != null) return n;
    return 999999999;
  }

  void _sortUsersInPlace(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      int result = 0;

      if (_sortBy == 'entry_date') {
        final da = (a['entry_date'] ?? '').toString().trim();
        final db = (b['entry_date'] ?? '').toString().trim();
        result = _compareNullableStrings(da, db);
      } else {
        final empA = _employeeSortValue(a);
        final empB = _employeeSortValue(b);
        result = empA.compareTo(empB);

        if (result == 0) {
          result = (a['employee_number'] ?? '')
              .toString()
              .compareTo((b['employee_number'] ?? '').toString());
        }
      }

      return _sortAscending ? result : -result;
    });
  }

  int _safePageForLength(int length) {
    if (length <= 0) return 0;
    if (_rowsPerPage <= 0) return 0;

    final maxPage = (length - 1) ~/ _rowsPerPage;
    if (_page < 0) return 0;
    if (_page > maxPage) return maxPage;
    return _page;
  }

  List<Map<String, dynamic>> _pagedUsersFrom(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return <Map<String, dynamic>>[];

    final safePage = _safePageForLength(list.length);
    final start = safePage * _rowsPerPage;
    final end = (start + _rowsPerPage) > list.length
        ? list.length
        : (start + _rowsPerPage);

    if (start < 0 || start >= list.length || end < start) {
      return <Map<String, dynamic>>[];
    }

    return list.sublist(start, end);
  }

  int _totalPagesFrom(int length) {
    if (length <= 0) return 1;
    if (_rowsPerPage <= 0) return 1;
    return (length / _rowsPerPage).ceil();
  }

  void _clampPage() {
    final total = _filteredUsers.length;
    final safePage = _safePageForLength(total);
    if (_page != safePage) {
      _page = safePage;
    }
  }

  String _areaNameFromValue(dynamic v) {
    if (v == null) return '—';
    final byId =
        _areas.where((a) => a['id'].toString() == v.toString()).toList();
    if (byId.isNotEmpty) return (byId.first['name'] ?? '—').toString();
    final s = v.toString();
    return s.isEmpty ? '—' : s;
  }

  String _positionNameFromValue(dynamic v) {
    if (v == null) return '—';
    final byId =
        _positions.where((p) => p['id'].toString() == v.toString()).toList();
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

  static String absUrl(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) return '${AuthService.baseUrl}$s';
    return '${AuthService.baseUrl}/$s';
  }

  List<Map<String, dynamic>> get _activeAreas {
    return _areas
        .where((a) => ((a['active'] as num?)?.toInt() ?? 1) == 1)
        .toList();
  }

  List<Map<String, dynamic>> get _activePositions {
    final all = _positions
        .where((p) => ((p['active'] as num?)?.toInt() ?? 1) == 1)
        .toList();

    if (_areaFilter == null || _areaFilter!.isEmpty) return all;

    return all.where((p) {
      final areaId = p['area_id'] ?? p['areaId'];
      if (areaId == null) return false;
      return areaId.toString() == _areaFilter.toString();
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final q = _q.trim().toLowerCase();

    final filtered = _users.where((u) {
      if (_areaFilter != null && _areaFilter!.isNotEmpty) {
        if ((u['area'] ?? '').toString() != _areaFilter.toString()) {
          return false;
        }
      }

      if (_posFilter != null && _posFilter!.isNotEmpty) {
        if ((u['position'] ?? '').toString() != _posFilter.toString()) {
          return false;
        }
      }

      if (q.isEmpty) return true;

      String s(dynamic v) => (v ?? '').toString().toLowerCase();
      final areaName = _areaNameFromValue(u['area']).toLowerCase();
      final posName = _positionNameFromValue(u['position']).toLowerCase();
      final entryDate = _fmtDate(u['entry_date']).toLowerCase();

      return s(u['id']).contains(q) ||
          s(u['employee_number']).contains(q) ||
          s(u['name']).contains(q) ||
          s(u['email']).contains(q) ||
          s(u['phone']).contains(q) ||
          s(u['curp']).contains(q) ||
          s(u['plant']).contains(q) ||
          entryDate.contains(q) ||
          areaName.contains(q) ||
          posName.contains(q);
    }).toList();

    _sortUsersInPlace(filtered);
    return filtered;
  }

  @override
  void initState() {
    super.initState();

    _ds = _UsersDataSource(
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

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
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

      final users = _asListOfStringMaps(results[0]);
      final areas = _asListOfStringMaps(results[1]);
      final positions = _asListOfStringMaps(results[2]);

      _sortUsersInPlace(users);

      safeSetState(() {
        _users = users;
        _areas = areas;
        _positions = positions;
        _clampPage();
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

      final users = _asListOfStringMaps(list);
      _sortUsersInPlace(users);

      safeSetState(() {
        _users = users;
        _clampPage();
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
        if (idx != -1) {
          _users[idx] = {..._users[idx], 'active': next};
        }
        _sortUsersInPlace(_users);
      });

      _ds.setUsers(_users);
      _showSnack(next == 1 ? 'Usuario activado' : 'Usuario desactivado');
    } catch (e) {
      _showSnack('No se pudo actualizar activo: $e', isError: true);
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> u) async {
    final theme = Theme.of(context);
    final name = (u['name'] ?? '').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Eliminar usuario'),
        content: Text('¿Seguro que deseas eliminar a "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
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
        _clampPage();
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
    final theme = Theme.of(context);

    final updated = await showModalBottomSheet<String>(
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
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: _UserFormSheet(
                title: 'Editar usuario',
                areas: _areas,
                positions: _positions,
                existingUsers: _users,
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

    if (updated != null) {
      await _refreshUsers();
      _showSnack('Usuario actualizado');
    }
  }

  Future<void> _openCreate() async {
    final theme = Theme.of(context);

    final createdEmployee = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.96,
          minChildSize: 0.65,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Material(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: _UserFormSheet(
                title: 'Nuevo empleado',
                areas: _areas,
                positions: _positions,
                existingUsers: _users,
                onSave: (payload) => _svc.createUser(payload),
                onUploadAvatar: null,
                scrollController: scrollController,
              ),
            );
          },
        );
      },
    );

    if (createdEmployee != null && createdEmployee.trim().isNotEmpty) {
      await _refreshUsers();

      safeSetState(() {
        _highlightNewEmployeeNumber = createdEmployee.trim();
        final index = _filteredUsers.indexWhere(
          (u) =>
              (u['employee_number'] ?? '').toString().trim() ==
              createdEmployee.trim(),
        );
        if (index >= 0 && _rowsPerPage > 0) {
          _page = index ~/ _rowsPerPage;
        }
        _clampPage();
      });

      _showSnack('Usuario agregado correctamente');

      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        safeSetState(() {
          if (_highlightNewEmployeeNumber == createdEmployee.trim()) {
            _highlightNewEmployeeNumber = null;
          }
        });
      });
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
      String newUrl;

      if (kIsWeb) {
        final Uint8List bytes = await x.readAsBytes();
        final filename = x.name.isNotEmpty ? x.name : 'avatar.png';
        newUrl = await _svc.uploadUserAvatarWeb(id, bytes, filename);
      } else {
        final file = File(x.path);
        newUrl = await _svc.uploadUserAvatar(id, file);
      }

      if (!mounted) return;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final freshUrl =
          newUrl.contains('?') ? '$newUrl&v=$ts' : '$newUrl?v=$ts';

      safeSetState(() {
        final idx = _users.indexWhere((u) => u['id'] == id);
        if (idx != -1) {
          _users[idx] = {..._users[idx], 'avatar': freshUrl};
        }
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
    if (_filteredUsers.isEmpty) return;

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
      'avatar',
    ];

    final rows = <String>[];
    rows.add(headers.map(esc).join(','));

    for (final u in _filteredUsers) {
      rows.add([
        u['id'],
        u['employee_number'],
        u['name'],
        u['email'],
        u['role_id'],
        _areaNameFromValue(u['area']),
        _positionNameFromValue(u['position']),
        (u['active'] == 1 ||
                u['active'] == true ||
                u['active']?.toString() == '1')
            ? 'Activo'
            : 'Inactivo',
        _fmtDate(u['entry_date']) == '—' ? '' : _fmtDate(u['entry_date']),
        _fmtDate(u['birthday']) == '—' ? '' : _fmtDate(u['birthday']),
        u['phone'],
        u['curp'],
        u['plant'],
        absUrl(u['avatar']),
      ].map(esc).join(','));
    }

    final csv = rows.join('\n');

    try {
      final bytes = Uint8List.fromList(utf8.encode(csv));
      await exportCsv(
        filename: 'usuarios.csv',
        bytes: bytes,
        mimeType: 'text/csv;charset=utf-8',
      );
      _showSnack('Archivo exportado correctamente');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.colorScheme.inverseSurface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredUsers;
    final safePage = _safePageForLength(filtered.length);
    final pagedUsers = _pagedUsersFrom(filtered);
    final totalPages = _totalPagesFrom(filtered.length);

    final start = filtered.isEmpty ? 0 : (safePage * _rowsPerPage) + 1;
    final end = filtered.isEmpty ? 0 : start + pagedUsers.length - 1;

    if (!_canManageUsers) {
      return Center(
        child: Text(
          'No tienes permisos para ver esta sección.',
          style: theme.textTheme.bodyLarge,
        ),
      );
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
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final small = w < 520;

                  final btnStyle = OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: small ? 10 : 14,
                      vertical: small ? 10 : 12,
                    ),
                    visualDensity: small
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );

                  final filledStyle = FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: small ? 10 : 14,
                      vertical: small ? 10 : 12,
                    ),
                    visualDensity: small
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );

                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          '',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        style: btnStyle,
                        onPressed: filtered.isEmpty ? null : _exportCsv,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(small ? '' : 'Exportar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: filledStyle,
                        onPressed: _openCreate,
                        icon:
                            const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: Text(small ? '' : 'Nuevo'),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final small = w < 960;
                  final tiny = w < 650;
                  final dense = small;

                  InputDecoration deco({
                    required String label,
                    String? hint,
                    Widget? prefixIcon,
                    Widget? suffixIcon,
                  }) {
                    return InputDecoration(
                      isDense: dense,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: tiny ? 10 : (small ? 12 : 14),
                      ),
                      labelText: label,
                      hintText: hint,
                      prefixIcon: prefixIcon,
                      suffixIcon: suffixIcon,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    );
                  }

                  final minSearch = tiny ? 240.0 : 320.0;
                  final minFilter = tiny ? 180.0 : 220.0;
                  final minSort = tiny ? 180.0 : 210.0;

                  Widget searchWidgetBig() => Expanded(
                        flex: 4,
                        child: TextField(
                          controller: _searchC,
                          onChanged: (v) {
                            safeSetState(() {
                              _q = v;
                              _page = 0;
                            });
                          },
                          decoration: deco(
                            label: 'Buscar',
                            hint: 'Buscar por nombre, #empleado, email...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _q.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchC.clear();
                                      safeSetState(() {
                                        _q = '';
                                        _page = 0;
                                      });
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                      );

                  Widget searchWidgetSmall() => SizedBox(
                        width: minSearch,
                        child: TextField(
                          controller: _searchC,
                          onChanged: (v) {
                            safeSetState(() {
                              _q = v;
                              _page = 0;
                            });
                          },
                          decoration: deco(
                            label: 'Buscar',
                            hint: tiny ? '' : 'Nombre, #empleado, email...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _q.trim().isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchC.clear();
                                      safeSetState(() {
                                        _q = '';
                                        _page = 0;
                                      });
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                      );

                  Widget areaWidget() => SizedBox(
                        width: minFilter,
                        child: _FilterAutocomplete(
                          label: 'Área',
                          icon: Icons.apartment_rounded,
                          hint: 'Todas',
                          items: _activeAreas,
                          selectedId: _areaFilter,
                          onSelected: (v) {
                            safeSetState(() {
                              _areaFilter = v;
                              _posFilter = null;
                              _page = 0;
                            });
                          },
                        ),
                      );

                  Widget posWidget() => SizedBox(
                        width: minFilter,
                        child: _FilterAutocomplete(
                          label: 'Puesto',
                          icon: Icons.work_rounded,
                          hint: 'Todos',
                          items: _activePositions,
                          selectedId: _posFilter,
                          onSelected: (v) {
                            safeSetState(() {
                              _posFilter = v;
                              _page = 0;
                            });
                          },
                        ),
                      );

                  Widget sortWidget() => SizedBox(
                        width: minSort,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _sortDropdownValue,
                          decoration: deco(
                            label: 'Ordenar',
                            prefixIcon: const Icon(Icons.sort_rounded),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'employee_number_asc',
                              child: Text('No. empleado ↑'),
                            ),
                            DropdownMenuItem(
                              value: 'employee_number_desc',
                              child: Text('No. empleado ↓'),
                            ),
                            DropdownMenuItem(
                              value: 'entry_date_asc',
                              child: Text('Fecha ingreso antigua'),
                            ),
                            DropdownMenuItem(
                              value: 'entry_date_desc',
                              child: Text('Fecha ingreso reciente'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null || v.isEmpty) return;
                            safeSetState(() {
                              _sortBy = v.startsWith('employee_number')
                                  ? 'employee_number'
                                  : 'entry_date';
                              _sortAscending = v.endsWith('_asc');
                              _sortUsersInPlace(_users);
                              _page = 0;
                            });
                          },
                        ),
                      );

                  final clearStyle = OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: tiny ? 10 : 12,
                      vertical: 10,
                    ),
                    visualDensity:
                        dense ? VisualDensity.compact : VisualDensity.standard,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );

                  final row = Row(
                    children: [
                      small ? searchWidgetSmall() : searchWidgetBig(),
                      const SizedBox(width: 10),
                      areaWidget(),
                      const SizedBox(width: 10),
                      posWidget(),
                      const SizedBox(width: 10),
                      sortWidget(),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: clearStyle,
                        onPressed: (_q.trim().isEmpty &&
                                (_areaFilter == null || _areaFilter!.isEmpty) &&
                                (_posFilter == null || _posFilter!.isEmpty) &&
                                _sortBy == 'employee_number' &&
                                _sortAscending)
                            ? null
                            : () {
                                _searchC.clear();
                                safeSetState(() {
                                  _q = '';
                                  _areaFilter = null;
                                  _posFilter = null;
                                  _sortBy = 'employee_number';
                                  _sortAscending = true;
                                  _sortUsersInPlace(_users);
                                  _page = 0;
                                });
                              },
                        icon:
                            const Icon(Icons.filter_alt_off_rounded, size: 18),
                        label: Text(tiny ? '' : 'Limpiar'),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tiny ? 8 : 10,
                          vertical: tiny ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.35),
                          ),
                          borderRadius: BorderRadius.circular(999),
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.35),
                        ),
                        child: Text(
                          '${filtered.length}/${_users.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: tiny ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  );

                  if (!small) return row;

                  final minTotalWidth = minSearch +
                      10 +
                      minFilter +
                      10 +
                      minFilter +
                      10 +
                      minSort +
                      10 +
                      110 +
                      10 +
                      70;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: minTotalWidth),
                      child: row,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAll,
                child: filtered.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Text(
                              'Sin resultados con ese filtro.',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 4, 12, 12),
                              itemCount: pagedUsers.length,
                              itemBuilder: (_, i) {
                                final user = pagedUsers[i];
                                final emp = (user['employee_number'] ?? '')
                                    .toString()
                                    .trim();

                                return _UserCard(
                                  key: ValueKey(
                                    '${user['id']}_${user['avatar'] ?? ''}_${emp == _highlightNewEmployeeNumber}',
                                  ),
                                  u: user,
                                  areaName: _areaNameFromValue,
                                  posName: _positionNameFromValue,
                                  fmtDate: _fmtDate,
                                  onEdit: _openEdit,
                                  onDelete: _confirmDelete,
                                  onToggleActive: _toggleActive,
                                  highlightAsNew: emp.isNotEmpty &&
                                      emp == _highlightNewEmployeeNumber,
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Text(
                                  'Mostrando $start-$end de ${filtered.length}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color:
                                          theme.dividerColor.withOpacity(0.35),
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    color: theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.35),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Anterior',
                                        onPressed: safePage > 0
                                            ? () {
                                                safeSetState(
                                                  () => _page = safePage - 1,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_left_rounded,
                                        ),
                                      ),
                                      Text(
                                        'Página ${safePage + 1} de $totalPages',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Siguiente',
                                        onPressed: (safePage + 1) < totalPages
                                            ? () {
                                                safeSetState(
                                                  () => _page = safePage + 1,
                                                );
                                              }
                                            : null,
                                        icon: const Icon(
                                          Icons.chevron_right_rounded,
                                        ),
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
          ],
        ),
        if (_saving)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: theme.colorScheme.scrim.withOpacity(0.12),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserCard extends StatefulWidget {
  final Map<String, dynamic> u;
  final bool highlightAsNew;

  final String Function(dynamic v) areaName;
  final String Function(dynamic v) posName;
  final String Function(dynamic v) fmtDate;

  final void Function(Map<String, dynamic> u) onEdit;
  final void Function(Map<String, dynamic> u) onDelete;
  final void Function(Map<String, dynamic> u) onToggleActive;

  const _UserCard({
    super.key,
    required this.u,
    required this.areaName,
    required this.posName,
    required this.fmtDate,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    this.highlightAsNew = false,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnim;
  late bool _active;

  late final AnimationController _enterController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  bool _playedEnter = false;

  String s(dynamic v) => (v == null) ? '' : v.toString();

  bool _isActive(dynamic raw) {
    if (raw == null) return false;
    if (raw == true) return true;
    if (raw is num) return raw.toInt() == 1;
    final t = raw.toString().toLowerCase();
    return t == '1' || t == 'true';
  }

  String _absAvatar(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) return '${AuthService.baseUrl}$s';
    return '${AuthService.baseUrl}/$s';
  }

  void _runEnterIfNeeded() {
    if (widget.highlightAsNew && !_playedEnter) {
      _playedEnter = true;
      _enterController.forward(from: 0);
    }
  }

  @override
  void initState() {
    super.initState();
    _active = _isActive(widget.u['active']);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.03)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.03, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_pulseController);

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.14),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    ));

    if (!widget.highlightAsNew) {
      _enterController.value = 1;
      _playedEnter = true;
    } else {
      _runEnterIfNeeded();
    }
  }

  @override
  void didUpdateWidget(covariant _UserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldActive = _isActive(oldWidget.u['active']);
    final newActive = _isActive(widget.u['active']);

    if (oldActive != newActive) {
      _active = newActive;
      _pulseController.forward(from: 0);
    } else {
      _active = newActive;
    }

    if (!oldWidget.highlightAsNew && widget.highlightAsNew) {
      _playedEnter = false;
      _runEnterIfNeeded();
    }

    if (!widget.highlightAsNew && _enterController.value == 0) {
      _enterController.value = 1;
      _playedEnter = true;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = _active;

    final name = s(widget.u['name']).trim().isEmpty
        ? '—'
        : s(widget.u['name']).trim();
    final emp = s(widget.u['employee_number']).trim();
    final email = s(widget.u['email']).trim();
    final plant = s(widget.u['plant']).trim();
    final avatarUrl = _absAvatar(s(widget.u['avatar']).trim());

    final area = widget.areaName(widget.u['area']);
    final pos = widget.posName(widget.u['position']);
    final entry = widget.fmtDate(widget.u['entry_date']);

    final statusBorder = active ? Colors.green : theme.colorScheme.error;
    final statusBg = (active ? Colors.green : theme.colorScheme.error)
        .withOpacity(.10);
    final statusText =
        active ? Colors.green.shade700 : theme.colorScheme.error;
    final accentBar = active ? Colors.green : theme.colorScheme.error;

    final newGlow = widget.highlightAsNew
        ? theme.colorScheme.primary.withOpacity(.14)
        : (active
            ? Colors.green.withOpacity(.08)
            : theme.colorScheme.error.withOpacity(.08));

    final fadeValue = _fadeAnim.value.isFinite ? _fadeAnim.value : 1.0;

    return FadeTransition(
      opacity: AlwaysStoppedAnimation<double>(fadeValue),
      child: SlideTransition(
        position: _slideAnim,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) {
            final scale = _scaleAnim.value.isFinite ? _scaleAnim.value : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: newGlow,
                  blurRadius: widget.highlightAsNew ? 24 : 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: widget.highlightAsNew
                      ? theme.colorScheme.primary.withOpacity(.28)
                      : active
                          ? Colors.green.withOpacity(.22)
                          : theme.colorScheme.error.withOpacity(.22),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      width: 5,
                      decoration: BoxDecoration(
                        color: widget.highlightAsNew
                            ? theme.colorScheme.primary
                            : accentBar,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(.55),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Image.asset(
                                      'assets/images/favicon.png',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/favicon.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (widget.highlightAsNew)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(.10),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      child: Text(
                                        'Nuevo',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 420),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border:
                                          Border.all(color: statusBorder),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      transitionBuilder:
                                          (child, animation) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Text(
                                        active ? 'Activo' : 'Inactivo',
                                        key: ValueKey(active),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: statusText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  if (emp.isNotEmpty)
                                    Text(
                                      'Empleado: $emp',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  Text(
                                    'Área: $area',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Puesto: $pos',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (email.isNotEmpty)
                                    _softChip(context, Icons.email_rounded, email),
                                  if (entry != '—')
                                    _softChip(
                                      context,
                                      Icons.event_available_rounded,
                                      'Ingreso: $entry',
                                    ),
                                  if (plant.isNotEmpty)
                                    _softChip(
                                      context,
                                      Icons.factory_rounded,
                                      plant,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          tooltip: 'Opciones',
                          icon: const Icon(Icons.settings_rounded),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') widget.onEdit(widget.u);
                            if (value == 'toggle') {
                              widget.onToggleActive(widget.u);
                            }
                            if (value == 'delete') widget.onDelete(widget.u);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    active
                                        ? Icons.toggle_off_rounded
                                        : Icons.toggle_on_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(active ? 'Desactivar' : 'Activar'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Eliminar'),
                                ],
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
        ),
      ),
    );
  }

  Widget _softChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.dividerColor.withOpacity(.30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.iconTheme.color?.withOpacity(.75),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
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
              color: active
                  ? Colors.green.withOpacity(.12)
                  : theme.colorScheme.error.withOpacity(.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? Colors.green : theme.colorScheme.error,
              ),
            ),
            child: Text(
              active ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: active ? Colors.green.shade700 : theme.colorScheme.error,
              ),
            ),
          ),
        ),
        DataCell(
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_rounded),
            onSelected: (value) {
              if (value == 'edit') onEdit(u);
              if (value == 'delete') onDelete(u);
              if (value == 'toggle') onToggleActive(u);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      active
                          ? Icons.toggle_off_rounded
                          : Icons.toggle_on_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(active ? 'Desactivar' : 'Activar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text('Eliminar'),
                  ],
                ),
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
  final List<Map<String, dynamic>> existingUsers;

  final Future<void> Function(Map<String, dynamic> payload) onSave;
  final Future<void> Function()? onUploadAvatar;

  final ScrollController scrollController;

  const _UserFormSheet({
    required this.title,
    required this.areas,
    required this.positions,
    required this.existingUsers,
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
  late final TextEditingController birthday;
  late final TextEditingController phone;
  late final TextEditingController entryDate;
  late final TextEditingController plant;

  int active = 1;
  String? areaValue;
  String? positionValue;
  String roleValue = '3';

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer = phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.postFrameCallbacks;

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

    employeeNumber =
        TextEditingController(text: (u['employee_number'] ?? '').toString());
    name = TextEditingController(text: (u['name'] ?? '').toString());
    email = TextEditingController(text: (u['email'] ?? '').toString());
    curp = TextEditingController(text: (u['curp'] ?? '').toString());
    password = TextEditingController(text: '');
    birthday = TextEditingController(text: _fmtDate(u['birthday']));
    phone = TextEditingController(text: (u['phone'] ?? '').toString());
    entryDate = TextEditingController(text: _fmtDate(u['entry_date']));
    plant = TextEditingController(text: (u['plant'] ?? '').toString());

    active = ((u['active'] as num?)?.toInt() ??
        (u['active']?.toString() == '1' ? 1 : 1));
    areaValue = u['area']?.toString();
    positionValue = u['position']?.toString();
    roleValue = (u['role_id'] ?? '3').toString();

    _autoPasswordIfCreate();
  }

  void _autoPasswordIfCreate() {
    final isEdit = widget.initial != null;
    if (isEdit) return;

    void rebuild() {
      final emp = employeeNumber.text.trim();
      final nm = name.text.trim();
      if (emp.isEmpty || nm.isEmpty) return;

      final parts =
          nm.split(RegExp(r'\s+')).where((x) => x.trim().isNotEmpty).toList();
      final first = parts.isNotEmpty ? parts[0] : '';
      final second = parts.length > 1 ? parts[1] : '';
      final initials =
          '${first.isNotEmpty ? first[0] : ''}${second.isNotEmpty ? second[0] : ''}'
              .toLowerCase();

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

  String _norm(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    if (s.toLowerCase() == 'null') return '';
    return s;
  }

  List<Map<String, dynamic>> get _activeAreas {
    return widget.areas
        .where((a) => ((a['active'] as num?)?.toInt() ?? 1) == 1)
        .toList();
  }

  List<Map<String, dynamic>> get _activePositions {
    final all = widget.positions
        .where((p) => ((p['active'] as num?)?.toInt() ?? 1) == 1)
        .toList();

    final a = areaValue;
    if (a == null || a.isEmpty) return all;

    return all.where((p) {
      final areaId = p['area_id'] ?? p['areaId'];
      if (areaId == null) return false;
      return areaId.toString() == a.toString();
    }).toList();
  }

  Map<String, dynamic> _normalizedPayload(Map<String, dynamic> payload) {
    return {
      'employee_number': _norm(payload['employee_number']),
      'name': _norm(payload['name']),
      'email': _norm(payload['email']),
      'curp': _norm(payload['curp']),
      'phone': _norm(payload['phone']),
      'role_id': _norm(payload['role_id']),
      'area': _norm(payload['area']),
      'position': _norm(payload['position']),
      'birthday': _norm(payload['birthday']),
      'entry_date': _norm(payload['entry_date']),
      'active': _norm(payload['active']),
      'plant': _norm(payload['plant']),
    };
  }

  bool _hasChanges(Map<String, dynamic> payload) {
    final original = widget.initial;
    if (original == null) return true;

    final current = _normalizedPayload(payload);
    final previous = _normalizedPayload({
      'employee_number': original['employee_number'],
      'name': original['name'],
      'email': original['email'],
      'curp': original['curp'],
      'phone': original['phone'],
      'role_id': original['role_id'],
      'area': original['area'],
      'position': original['position'],
      'birthday': _fmtDate(original['birthday']),
      'entry_date': _fmtDate(original['entry_date']),
      'active':
          (original['active'] == true || original['active']?.toString() == '1')
              ? 1
              : 0,
      'plant': original['plant'],
    });

    return current.entries.any((e) => previous[e.key] != e.value);
  }

  bool _employeeNumberExists(String employee, {dynamic editingId}) {
    final emp = employee.trim();
    if (emp.isEmpty) return false;

    return widget.existingUsers.any((u) {
      final sameEmployee =
          (u['employee_number'] ?? '').toString().trim() == emp;
      final sameId =
          editingId != null && (u['id']?.toString() == editingId.toString());
      return sameEmployee && !sameId;
    });
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
      'role_id': int.tryParse(roleValue) ?? 3,
      'area': areaValue,
      'position': positionValue,
      'birthday': birthday.text.trim().isEmpty ? null : birthday.text.trim(),
      'entry_date': entryDate.text.trim().isEmpty ? null : entryDate.text.trim(),
      'active': active,
      'plant': plant.text.trim().isEmpty ? null : plant.text.trim(),
    };

    final isEdit = widget.initial != null;

    if (_employeeNumberExists(
      employeeNumber.text.trim(),
      editingId: widget.initial?['id'],
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('El número de empleado ya existe'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (password.text.trim().isNotEmpty) {
      payload['password'] = password.text.trim();
    }

    if (isEdit && !_hasChanges(payload) && password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se detectaron cambios'),
        ),
      );
      return;
    }

    if (!mounted) return;
    safeSetState(() => _saving = true);
    try {
      await widget.onSave(payload);
      if (!mounted) return;
      Navigator.pop(context, employeeNumber.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) safeSetState(() => _saving = false);
    }
  }

  InputDecoration _themedDecoration(
    BuildContext context, {
    required String label,
    IconData? icon,
    Widget? suffixIcon,
    bool filled = false,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.dividerColor.withOpacity(0.45);

    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2,
        ),
      ),
    );
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
            decoration: _themedDecoration(
              context,
              label: label,
              icon: icon,
              selected: filled,
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
            decoration: _themedDecoration(
              context,
              label: label,
              icon: icon,
              selected: filled,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                onPressed: () async {
                  final now = DateTime.now();
                  final currentText = controller.text.trim();
                  final parsed = DateTime.tryParse(currentText);
                  final initial = parsed ?? now;

                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initial,
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
        decoration: _themedDecoration(
          context,
          label: label,
          icon: icon,
          selected: filled,
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
      if (selectedId == null || selectedId.isEmpty) return '';
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
              if (!hasFocus && controller.text.trim().isEmpty) {
                onSelected(null);
              }
            },
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: _themedDecoration(
                context,
                label: label,
                icon: icon,
                selected: selectedId != null && selectedId!.isNotEmpty,
              ),
              validator: (_) {
                if (!required) return null;
                if (selectedId == null || selectedId.isEmpty) {
                  return 'Selecciona una opción';
                }
                return null;
              },
            ),
          );
        },
        onSelected: (opt) => onSelected(idOf(opt)),
        optionsViewBuilder: (context, onSelectedOpt, opts) {
          final theme = Theme.of(context);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 260, maxWidth: 520),
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
    final theme = Theme.of(context);
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
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!isEdit) ...[
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage('assets/images/favicon.png'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Avatar por defecto: assets/images/favicon.png\n(Después puedes cambiarlo en Editar usuario)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        Card(
                          elevation: 0,
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(.30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Datos básicos',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _field(
                                  employeeNumber,
                                  'Número de empleado',
                                  icon: Icons.badge_rounded,
                                ),
                                _field(
                                  name,
                                  'Nombre (incluye apellidos)',
                                  icon: Icons.person_rounded,
                                ),
                                _field(
                                  email,
                                  'Email (opcional)',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  required: false,
                                ),
                                _field(
                                  curp,
                                  'CURP (opcional)',
                                  icon: Icons.assignment_ind_rounded,
                                  required: false,
                                ),
                                _field(
                                  phone,
                                  'Teléfono (opcional)',
                                  icon: Icons.phone_rounded,
                                  keyboardType: TextInputType.phone,
                                  required: false,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: TextFormField(
                                    controller: password,
                                    obscureText: !_showPassword,
                                    decoration: _themedDecoration(
                                      context,
                                      label: isEdit
                                          ? 'Password (opcional)'
                                          : 'Password (sugerida, editable)',
                                      icon: Icons.lock_rounded,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                        ),
                                        onPressed: () => safeSetState(
                                          () => _showPassword = !_showPassword,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (!isEdit &&
                                          (v == null || v.trim().isEmpty)) {
                                        return 'Requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _dropdown(
                                  label: 'Rol',
                                  value: roleValue,
                                  icon: Icons.admin_panel_settings_rounded,
                                  items: const [
                                    DropdownMenuItem(
                                      value: '1',
                                      child: Text('Administrador'),
                                    ),
                                    DropdownMenuItem(
                                      value: '2',
                                      child: Text('RH'),
                                    ),
                                    DropdownMenuItem(
                                      value: '3',
                                      child: Text('Empleado'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    roleValue = v ?? '3';
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(.30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Organización',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _autocompleteSelect(
                                  label: 'Área',
                                  icon: Icons.apartment_rounded,
                                  items: _activeAreas,
                                  selectedId: areaValue,
                                  onSelected: (id) {
                                    safeSetState(() {
                                      areaValue = id;
                                      positionValue = null;
                                    });
                                  },
                                ),
                                _autocompleteSelect(
                                  label: 'Puesto',
                                  icon: Icons.work_rounded,
                                  items: _activePositions,
                                  selectedId: positionValue,
                                  onSelected: (id) {
                                    safeSetState(() {
                                      positionValue = id;
                                    });
                                  },
                                ),
                                _field(
                                  plant,
                                  'Planta (opcional)',
                                  icon: Icons.factory_rounded,
                                  required: false,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Card(
                          elevation: 0,
                          color: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(.30),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fechas y estado',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _dateField(
                                  controller: birthday,
                                  label: 'Cumpleaños',
                                  icon: Icons.cake_rounded,
                                  required: false,
                                ),
                                _dateField(
                                  controller: entryDate,
                                  label: 'Fecha de ingreso',
                                  icon: Icons.event_available_rounded,
                                  required: false,
                                ),
                                _dropdown(
                                  label: 'Estatus',
                                  value: active.toString(),
                                  icon: Icons.toggle_on_rounded,
                                  items: const [
                                    DropdownMenuItem(
                                      value: '1',
                                      child: Text('Activo'),
                                    ),
                                    DropdownMenuItem(
                                      value: '0',
                                      child: Text('Inactivo'),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    active = int.tryParse(v ?? '1') ?? 1;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _saving
                                  ? 'Guardando...'
                                  : (isEdit ? 'Guardar cambios' : 'Crear usuario'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

class _FilterAutocomplete extends StatelessWidget {
  final String label;
  final IconData icon;
  final String hint;
  final List<Map<String, dynamic>> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _FilterAutocomplete({
    required this.label,
    required this.icon,
    required this.hint,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    String nameOf(Map<String, dynamic> x) => (x['name'] ?? '').toString();
    String idOf(Map<String, dynamic> x) => (x['id'] ?? '').toString();

    final initialText = () {
      if (selectedId == null || selectedId!.isEmpty) return '';
      final match = items.where((x) => idOf(x) == selectedId).toList();
      if (match.isEmpty) return '';
      return nameOf(match.first);
    }();

    InputDecoration deco() => InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          suffixIcon: (selectedId != null && selectedId!.isNotEmpty)
              ? IconButton(
                  tooltip: 'Limpiar',
                  onPressed: () => onSelected(null),
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
        );

    return Autocomplete<Map<String, dynamic>>(
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
            if (!hasFocus && controller.text.trim().isEmpty) {
              onSelected(null);
            }
          },
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: deco(),
          ),
        );
      },
      onSelected: (opt) => onSelected(idOf(opt)),
      optionsViewBuilder: (context, onSelectedOpt, opts) {
        final theme = Theme.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxHeight: 260, maxWidth: 520),
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
    );
  }
}