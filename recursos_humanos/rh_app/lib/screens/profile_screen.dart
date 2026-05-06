import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/notices_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _user;

  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _saving = false;

  String _areaName = '—';
  String _positionName = '—';

  DateTime? _birthday;

  String _s(dynamic v) => (v == null) ? '' : v.toString();

  static String get _baseUrl => AuthService.baseUrl;

  String _absoluteUrl(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) return '$_baseUrl$s';
    return '$_baseUrl/$s';
  }

  int get _roleId => ((_user['role_id'] as num?)?.toInt()) ?? 3;

  bool get _canEditContact =>
      _roleId == 1 || _roleId == 2 || _roleId == 3;

  bool get _canEditBirthday =>
      _user['birthday'] == null || _s(_user['birthday']).trim().isEmpty;

  bool get _canSaveAnything => _canEditContact || _canEditBirthday;

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;

    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
    if (m != null) {
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    }

    final iso = DateTime.tryParse(s);
    if (iso != null) return iso;

    final mysql = DateTime.tryParse(s.replaceFirst(' ', 'T'));
    if (mysql != null) return mysql;

    return null;
  }

  String _fmtDMY(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = dt.toLocal();
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  String _fmtDMYHM(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = dt.toLocal();
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  String _tenureText(DateTime? entryDate) {
    if (entryDate == null) return '—';
    final start = DateTime(entryDate.year, entryDate.month, entryDate.day);
    final now = DateTime.now();

    int months = (now.year - start.year) * 12 + (now.month - start.month);
    if (now.day < start.day) months -= 1;
    if (months < 0) months = 0;

    final years = months ~/ 12;
    final remMonths = months % 12;

    if (years == 0 && remMonths == 0) return '0 meses';
    if (years > 0 && remMonths > 0) return '$years año(s) $remMonths mes(es)';
    if (years > 0) return '$years año(s)';
    return '$remMonths mes(es)';
  }

  bool get _active {
    final a = (_user['active'] as num?)?.toInt();
    return (a ?? 1) == 1;
  }

  String _activeText() => _active ? 'Activo' : 'Inactivo';

  String _lastConnectionText() {
    final raw =
        _user['last_login'] ?? _user['last_connection'] ?? _user['last_seen'];
    final dt = _parseDate(raw);
    if (dt == null) return '—';
    return _fmtDMYHM(dt);
  }

  Future<void> _loadCatalogNames() async {
    try {
      dynamic areaVal = _user['area'] ??
          _user['area_id'] ??
          _user['areaId'] ??
          _user['area_name'] ??
          _user['areaName'];

      dynamic posVal = _user['position'] ??
          _user['position_id'] ??
          _user['positionId'] ??
          _user['position_name'] ??
          _user['positionName'];

      if (areaVal is Map) {
        areaVal =
            areaVal['id'] ?? areaVal['area_id'] ?? areaVal['name'] ?? areaVal['area_name'];
      }
      if (posVal is Map) {
        posVal = posVal['id'] ??
            posVal['position_id'] ??
            posVal['name'] ??
            posVal['position_name'];
      }

      final areaRaw = _s(areaVal).trim();
      final posRaw = _s(posVal).trim();

      final looksLikeIdArea = int.tryParse(areaRaw) != null;
      final looksLikeIdPos = int.tryParse(posRaw) != null;

      if (!looksLikeIdArea && areaRaw.isNotEmpty) _areaName = areaRaw;
      if (!looksLikeIdPos && posRaw.isNotEmpty) _positionName = posRaw;

      if (looksLikeIdArea || looksLikeIdPos) {
        final areaId = _asInt(areaVal);
        final positionId = _asInt(posVal);

        final areasMap = await NoticesService().getAreasMap();
        final posMap = await NoticesService().getPositionsMap();

        final aName = areasMap[areaId];
        final pName = posMap[positionId];

        if (!mounted) return;
        setState(() {
          _areaName = (aName == null || aName.trim().isEmpty) ? '—' : aName;
          _positionName =
              (pName == null || pName.trim().isEmpty) ? '—' : pName;
        });
      } else {
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint('No se pudieron cargar catálogos (áreas/puestos): $e');

      dynamic areaVal = _user['area'] ??
          _user['area_id'] ??
          _user['areaId'] ??
          _user['area_name'] ??
          _user['areaName'];

      dynamic posVal = _user['position'] ??
          _user['position_id'] ??
          _user['positionId'] ??
          _user['position_name'] ??
          _user['positionName'];

      if (areaVal is Map) {
        areaVal = areaVal['name'] ??
            areaVal['area_name'] ??
            areaVal['id'] ??
            areaVal['area_id'];
      }
      if (posVal is Map) {
        posVal = posVal['name'] ??
            posVal['position_name'] ??
            posVal['id'] ??
            posVal['position_id'];
      }

      final areaRaw = _s(areaVal).trim();
      final posRaw = _s(posVal).trim();

      if (!mounted) return;
      setState(() {
        if (areaRaw.isNotEmpty) {
          _areaName = int.tryParse(areaRaw) != null ? 'ID: $areaRaw' : areaRaw;
        }
        if (posRaw.isNotEmpty) {
          _positionName = int.tryParse(posRaw) != null ? 'ID: $posRaw' : posRaw;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _user = Map<String, dynamic>.from(widget.userData);

    _emailCtrl.text = _s(_user['email']).trim();
    _phoneCtrl.text = _s(_user['phone']).trim();
    _birthday = _parseDate(_user['birthday']);

    _loadCatalogNames();
    _refreshProfile();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);

    if (x == null) return;

    setState(() => _saving = true);

    try {
      String urlOrPath;

      if (kIsWeb) {
        final Uint8List bytes = await x.readAsBytes();
        final filename = x.name.isNotEmpty ? x.name : 'avatar.png';
        urlOrPath = await NoticesService().uploadMyAvatarWeb(bytes, filename);
      } else {
        final file = File(x.path);
        urlOrPath = await NoticesService().uploadMyAvatar(file);
      }

      if (!mounted) return;
      setState(() {
        final ts = DateTime.now().millisecondsSinceEpoch;
        _user['avatar'] =
            urlOrPath.contains('?') ? '$urlOrPath&v=$ts' : '$urlOrPath?v=$ts';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar actualizado ✅')),
      );
    } catch (e, st) {
      debugPrint('ERROR subiendo avatar: $e');
      debugPrintStack(stackTrace: st);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo avatar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthday() async {
    if (!_canEditBirthday || _saving) return;

    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 25, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked == null) return;

    setState(() {
      _birthday = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _refreshProfile() async {
    try {
      final me = await NoticesService().getMyProfile();
      if (!mounted) return;

      setState(() {
        _user = Map<String, dynamic>.from(me);
        _emailCtrl.text = _s(_user['email']).trim();
        _phoneCtrl.text = _s(_user['phone']).trim();
        _birthday = _parseDate(_user['birthday']);
      });

      await _loadCatalogNames();
    } catch (e) {
      debugPrint('ERROR getMyProfile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar perfil: $e')),
      );
    }
  }

  Future<void> _saveEditableFields() async {
    if (!_canSaveAnything) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para editar este perfil.'),
        ),
      );
      return;
    }

    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    final currentEmail = _s(_user['email']).trim();
    final currentPhone = _s(_user['phone']).trim();

    final payload = <String, dynamic>{};

    if (_canEditContact) {
      if (email != currentEmail) payload['email'] = email.isEmpty ? null : email;
      if (phone != currentPhone) payload['phone'] = phone.isEmpty ? null : phone;
    }

    if (_canEditBirthday && _birthday != null) {
      final y = _birthday!.year.toString().padLeft(4, '0');
      final m = _birthday!.month.toString().padLeft(2, '0');
      final d = _birthday!.day.toString().padLeft(2, '0');
      payload['birthday'] = '$y-$m-$d';
    }

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay cambios para guardar.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await NoticesService().updateMyProfile(payload);

      if (!mounted) return;
      setState(() {
        if (_canEditContact) {
          if (payload.containsKey('email')) _user['email'] = payload['email'];
          if (payload.containsKey('phone')) _user['phone'] = payload['phone'];
        }
        if (_canEditBirthday && payload.containsKey('birthday')) {
          _user['birthday'] = payload['birthday'];
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final name = (_user['name'] ?? '—').toString();
    final empNo = (_user['employee_number'] ?? '—').toString();

    final area = _areaName;
    final position = _positionName;

    final avatarRaw = (_user['avatar'] ?? '').toString();
    final avatarUrl = _absoluteUrl(avatarRaw);

    final entryDate = _parseDate(_user['entry_date']);
    final tenure = _tenureText(entryDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilledButton.icon(
              onPressed:
                  (_saving || !_canSaveAnything) ? null : _saveEditableFields,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(_saving ? 'Guardando...' : 'Guardar'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _saving ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.grey.shade200,
                          child: ClipOval(
                            child: avatarUrl.trim().isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    width: 88,
                                    height: 88,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: 40,
                                      color: theme.iconTheme.color,
                                    ),
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      );
                                    },
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 40,
                                    color: theme.iconTheme.color,
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Empleado #$empNo',
                    style: TextStyle(
                      color: isDark
                          ? theme.textTheme.bodyMedium?.color?.withOpacity(0.75)
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _active
                          ? (isDark
                              ? Colors.green.withOpacity(0.16)
                              : Colors.green.shade50)
                          : (isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _activeText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _active
                            ? (isDark
                                ? Colors.green.shade300
                                : Colors.green)
                            : (isDark
                                ? theme.textTheme.bodyMedium?.color
                                : Colors.grey.shade700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Datos editables',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _EditableRow(
                    icon: Icons.email_rounded,
                    label: 'Correo electrónico',
                    controller: _emailCtrl,
                    hint: 'correo@empresa.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_saving && _canEditContact,
                  ),
                  Divider(
                    height: 18,
                    color: isDark
                        ? theme.dividerColor
                        : Colors.grey.shade300,
                  ),
                  _EditableRow(
                    icon: Icons.phone_rounded,
                    label: 'Teléfono',
                    controller: _phoneCtrl,
                    hint: '10 dígitos',
                    keyboardType: TextInputType.phone,
                    enabled: !_saving && _canEditContact,
                  ),
                  Divider(
                    height: 18,
                    color: isDark
                        ? theme.dividerColor
                        : Colors.grey.shade300,
                  ),
                  InkWell(
                    onTap: (_saving || !_canEditBirthday) ? null : _pickBirthday,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _ReadOnlyRow(
                        icon: Icons.cake_rounded,
                        label: 'Cumpleaños',
                        value: _birthday == null ? '—' : _fmtDMY(_birthday!),
                      ),
                    ),
                  ),
                  if (!_canEditBirthday) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'El cumpleaños ya está registrado y no se puede modificar.',
                        style: TextStyle(
                          color: isDark
                              ? theme.textTheme.bodySmall?.color?.withOpacity(0.75)
                              : Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Información del empleado',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            color: theme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _ReadOnlyRow(
                    icon: Icons.apartment_rounded,
                    label: 'Área',
                    value: area,
                  ),
                  Divider(
                    height: 18,
                    color: isDark
                        ? theme.dividerColor
                        : Colors.grey.shade300,
                  ),
                  _ReadOnlyRow(
                    icon: Icons.work_rounded,
                    label: 'Puesto',
                    value: position,
                  ),
                  Divider(
                    height: 18,
                    color: isDark
                        ? theme.dividerColor
                        : Colors.grey.shade300,
                  ),
                  _ReadOnlyRow(
                    icon: Icons.event_available_rounded,
                    label: 'Fecha de ingreso',
                    value: entryDate == null ? '—' : _fmtDMY(entryDate),
                  ),
                  Divider(
                    height: 18,
                    color: isDark
                        ? theme.dividerColor
                        : Colors.grey.shade300,
                  ),
                  _ReadOnlyRow(
                    icon: Icons.verified_rounded,
                    label: 'Antigüedad',
                    value: tenure,
                  ),
                  Divider(
                    height: 18,
                    color: isDark
                        ? theme.dividerColor
                        : Colors.grey.shade300,
                  ),
                  _ReadOnlyRow(
                    icon: Icons.history_rounded,
                    label: 'Última conexión',
                    value: _lastConnectionText(),
                  ),
                  Divider(
                    height: 18,
                    color: isDark
                        ? theme.dividerColor
                        : Colors.grey.shade300,
                  ),
                  _ReadOnlyRow(
                    icon: Icons.toggle_on_rounded,
                    label: 'Estatus',
                    value: _activeText(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed:
                (_saving || !_canSaveAnything) ? null : _saveEditableFields,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Guardando cambios...' : 'Guardar cambios'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== Widgets UI ===================== */

class _ReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? theme.textTheme.bodySmall?.color?.withOpacity(0.75)
                      : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isEmpty ? '—' : value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool enabled;

  const _EditableRow({
    required this.icon,
    required this.label,
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: InputBorder.none,
              labelStyle: TextStyle(
                color: isDark
                    ? theme.textTheme.bodyMedium?.color?.withOpacity(0.85)
                    : null,
              ),
              hintStyle: TextStyle(
                color: isDark
                    ? theme.textTheme.bodyMedium?.color?.withOpacity(0.55)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}