import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/notices_service.dart';

class Nom035AdminActionPlanScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int cycleId;
  final String cycleTitle;

  const Nom035AdminActionPlanScreen({
    super.key,
    required this.userData,
    required this.cycleId,
    required this.cycleTitle,
  });

  @override
  State<Nom035AdminActionPlanScreen> createState() =>
      _Nom035AdminActionPlanScreenState();
}

class _Nom035AdminActionPlanScreenState
    extends State<Nom035AdminActionPlanScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> cycles = [];
  List<Map<String, dynamic>> users = [];

  bool loadingAreas = false;
  bool loadingCycles = false;
  bool loadingUsers = false;

  int? selectedCycleId;

  final Map<int, List<Map<String, dynamic>>> attachmentsByPlan = {};
  final Map<int, bool> loadingAttachments = {};
  final Map<int, bool> attachmentsExpanded = {};

  static const List<String> _riskLevels = [
    'Bajo',
    'Medio',
    'Alto',
    'Muy Alto',
  ];

  static const List<String> _statuses = [
    'pendiente',
    'en_proceso',
    'completado',
    'cancelado',
  ];

  static const Map<String, String> _statusLabelMap = {
    'pendiente': 'Pendiente',
    'en_proceso': 'En proceso',
    'completado': 'Completado',
    'cancelado': 'Cancelado',
  };

  static const Map<String, Color> _statusColorMap = {
    'pendiente': Colors.blueGrey,
    'en_proceso': Colors.orange,
    'completado': Colors.green,
    'cancelado': Colors.red,
  };

  static const Map<String, Color> _riskColorMap = {
    'bajo': Colors.green,
    'medio': Colors.amber,
    'alto': Colors.deepOrange,
    'muy alto': Colors.red,
  };

  String _s(dynamic v) => v == null ? '' : v.toString();

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List _asList(dynamic v) {
    if (v is List) return v;
    return <dynamic>[];
  }

  @override
  void initState() {
    super.initState();
    selectedCycleId = widget.cycleId;
    _loadInitial();
  }

  String _cardNumber(int index) {
    final number = index + 1;
    return number.toString().padLeft(2, '0');
  }

  String _normalizeDateForInput(dynamic value) {
    final raw = _s(value).trim();
    if (raw.isEmpty) return '';

    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
        return raw;
      }

      if (raw.contains(' ')) {
        final first = raw.split(' ').first.trim();
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(first)) {
          return first;
        }
      }

      if (raw.contains('T')) {
        final first = raw.split('T').first.trim();
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(first)) {
          return first;
        }
      }

      final dt = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return '';
    }
  }

  String? _dateForApi(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    return value;
  }

  Future<void> _loadInitial() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      NoticesService.clearNom035Caches();

      await Future.wait([
        _loadAreas(),
        _loadCycles(),
        _loadUsers(),
      ]);

      await _loadPlans(selectedCycleId ?? widget.cycleId);

      if (!mounted) return;
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _loadAreas() async {
    loadingAreas = true;
    try {
      final data = await NoticesService().getAreas();
      areas = data.map<Map<String, dynamic>>((e) {
        final a = _asMap(e);
        return {
          ...a,
          '_id': _asInt(a['id'] ?? a['area_id']),
          '_name': _s(a['name'] ?? a['area'] ?? a['nombre']),
        };
      }).toList();
    } finally {
      loadingAreas = false;
    }
  }

  Future<void> _loadCycles() async {
    loadingCycles = true;
    try {
      final data = await NoticesService.adminGetCycles();
      cycles = data.map<Map<String, dynamic>>((e) {
        final c = _asMap(e);
        return {
          ...c,
          '_id': _asInt(c['id']),
          '_title': _s(c['title']),
        };
      }).toList();
    } finally {
      loadingCycles = false;
    }
  }

  Future<void> _loadUsers() async {
    loadingUsers = true;
    try {
      final data = await NoticesService().getUsers();
      users = data
          .where((u) {
            if (!u.containsKey('active')) return true;
            return _asInt(u['active']) == 1;
          })
          .map<Map<String, dynamic>>((e) {
            final u = _asMap(e);
            return {
              ...u,
              '_id': _asInt(u['id']),
              '_name': _s(u['name']).isEmpty
                  ? 'Usuario ${_asInt(u['id'])}'
                  : _s(u['name']),
            };
          })
          .toList();
    } finally {
      loadingUsers = false;
    }
  }

Map<String, dynamic> _normalizePlan(dynamic raw) {
  final item = _asMap(raw);

  final planId = _asInt(item['id']);
  final title = _s(item['action_title']);
  final description = _s(item['action_description']);
  final departmentName = _s(item['department_name']);
  final responsibleName = _s(item['responsible_name']);
  final risk = _s(item['risk_level']);
  final status = _s(item['status']).isEmpty ? 'pendiente' : _s(item['status']);
  final progress = _asDouble(item['progress_percent']).clamp(0, 100);
  final dueDate = _s(item['due_date']);
  final attachmentsCount = _asInt(
    item['attachments_count'] ??
        item['total_attachments'] ??
        item['adjuntos_count'],
  );

  return {
    ...item,
    '_id': planId,
    '_title': title,
    '_description': description,
    '_departmentName': departmentName,
    '_responsibleName': responsibleName,
    '_risk': risk,
    '_status': status,
    '_progress': progress,
    '_dueDate': dueDate,
    '_attachmentsCount': attachmentsCount,
  };
}

Future<void> _loadPlans(int cycleId) async {
  final data = await NoticesService().getNom035ActionPlans(cycleId);

  debugPrint('DATA PLANES: $data');

  final rawItems = _asList(data['items']);

  for (final raw in rawItems) {
    final item = _asMap(raw);
    debugPrint(
      'PLAN ${_asInt(item['id'])} | '
      'attachments_count=${item['attachments_count']} | '
      'total_attachments=${item['total_attachments']} | '
      'adjuntos_count=${item['adjuntos_count']}',
    );
  }

  items = rawItems.map<Map<String, dynamic>>(_normalizePlan).toList();

  attachmentsByPlan.clear();
  loadingAttachments.clear();
  attachmentsExpanded.clear();
}


  Future<void> _refresh() async {
    NoticesService.clearNom035Caches();
    await _loadPlans(selectedCycleId ?? widget.cycleId);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadAttachments(int planId, {bool forceRefresh = false}) async {
    setState(() {
      loadingAttachments[planId] = true;
    });

    try {
      final items = await NoticesService().getNom035ActionPlanAttachmentsFast(
        planId,
        forceRefresh: forceRefresh,
      );

      attachmentsByPlan[planId] = items;
    } catch (_) {
      attachmentsByPlan[planId] = [];
    }

    if (!mounted) return;
    setState(() {
      loadingAttachments[planId] = false;
    });
  }

  Future<void> _toggleAttachments(int planId) async {
    final expanded = attachmentsExpanded[planId] == true;

    if (expanded) {
      setState(() {
        attachmentsExpanded[planId] = false;
      });
      return;
    }

    setState(() {
      attachmentsExpanded[planId] = true;
    });

    if (!attachmentsByPlan.containsKey(planId)) {
      await _loadAttachments(planId);
    }
  }

  String _formatDateMx(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return '—';
    try {
      final clean = _normalizeDateForInput(isoDate);
      if (clean.isEmpty) return '—';
      final date = DateTime.parse(clean);
      return DateFormat('dd/MM/yyyy', 'es_MX').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatBytes(dynamic value) {
    final bytes = _asDouble(value);
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<void> _pickDate(
    BuildContext pickerContext,
    TextEditingController controller,
    void Function() refresh,
  ) async {
    final firstDate = DateTime(2020, 1, 1);
    final lastDate = DateTime(2100, 12, 31);

    DateTime initialDate = DateTime.now();

    final raw = controller.text.trim();
    if (raw.isNotEmpty) {
      try {
        initialDate = DateTime.parse(raw);
      } catch (_) {
        initialDate = DateTime.now();
      }
    }

    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final picked = await showDatePicker(
      context: pickerContext,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('es', 'MX'),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
      refresh();
    }
  }

  String _areaNameById(int? id) {
    if (id == null || id <= 0) return '';
    for (final a in areas) {
      if ((a['_id'] as int) == id) {
        return a['_name'] as String;
      }
    }
    return '';
  }

  String _userNameById(int? id) {
    if (id == null || id <= 0) return '';
    for (final u in users) {
      if ((u['_id'] as int) == id) {
        return u['_name'] as String;
      }
    }
    return '';
  }

  String _cycleTitleById(int? id) {
    if (id == null || id <= 0) return '';
    for (final c in cycles) {
      if ((c['_id'] as int) == id) {
        final title = c['_title'] as String;
        return title.isEmpty ? 'Ciclo $id' : title;
      }
    }
    return '';
  }

  Color _statusColor(String status) {
    return _statusColorMap[status] ?? Colors.blueGrey;
  }

  String _statusLabel(String status) {
    return _statusLabelMap[status] ?? 'Pendiente';
  }

  Color _riskColor(String risk) {
    return _riskColorMap[risk.toLowerCase()] ?? Colors.blueGrey;
  }

  Map<String, dynamic>? _findAreaByName(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return null;

    for (final a in areas) {
      final areaName = (a['_name'] as String).trim();
      if (areaName.toLowerCase() == clean) {
        return {
          'id': a['_id'],
          'name': areaName,
        };
      }
    }
    return null;
  }

  List<int> _departmentIdsFromItem(Map<String, dynamic> item) {
    final result = <int>[];

    final singleId = _asInt(item['department_id']);
    if (singleId > 0) {
      result.add(singleId);
    }

    final rawNames = _s(item['department_name']).trim();
    if (rawNames.isNotEmpty) {
      final parts = rawNames
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (final part in parts) {
        final found = _findAreaByName(part);
        if (found != null) {
          final id = _asInt(found['id']);
          if (id > 0 && !result.contains(id)) {
            result.add(id);
          }
        }
      }
    }

    return result;
  }

  String _departmentNamesFromIds(List<int> ids) {
    final names = ids
        .map(_areaNameById)
        .where((name) => name.trim().isNotEmpty)
        .toList();
    return names.join(', ');
  }

  Widget _buildUserAutocomplete({
    required int? selectedId,
    required ValueChanged<int?> onChanged,
  }) {
    final options = users
        .map((u) => {
              'id': u['_id'],
              'name': u['_name'],
            })
        .toList();

    final initial = selectedId == null ? '' : _userNameById(selectedId);

    return Autocomplete<Map<String, dynamic>>(
      initialValue: TextEditingValue(text: initial),
      displayStringForOption: (option) => _s(option['name']),
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return options;
        return options.where((opt) {
          return _s(opt['name']).toLowerCase().contains(q);
        });
      },
      onSelected: (option) {
        onChanged(_asInt(option['id']));
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Responsable',
            hintText: 'Escribe para buscar responsable',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.search),
          ),
        );
      },
    );
  }

  Widget _buildMultiAreaSelector({
    required List<int> selectedIds,
    required ValueChanged<List<int>> onChanged,
  }) {
    final options = areas
        .map((a) => {
              'id': a['_id'],
              'name': a['_name'],
            })
        .where((e) => _asInt(e['id']) > 0 && _s(e['name']).trim().isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedIds.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selectedIds.map((id) {
                return Chip(
                  label: Text(_areaNameById(id)),
                  onDeleted: () {
                    final updated = List<int>.from(selectedIds)..remove(id);
                    onChanged(updated);
                  },
                );
              }).toList(),
            ),
          ),
        if (selectedIds.isNotEmpty) const SizedBox(height: 10),
        Autocomplete<Map<String, dynamic>>(
          displayStringForOption: (option) => _s(option['name']),
          optionsBuilder: (textEditingValue) {
            final q = textEditingValue.text.trim().toLowerCase();
            return options.where((opt) {
              final id = _asInt(opt['id']);
              final name = _s(opt['name']).toLowerCase();
              final matches = q.isEmpty ? true : name.contains(q);
              return matches && !selectedIds.contains(id);
            });
          },
          onSelected: (option) {
            final id = _asInt(option['id']);
            if (id > 0 && !selectedIds.contains(id)) {
              final updated = List<int>.from(selectedIds)..add(id);
              onChanged(updated);
            }
          },
          fieldViewBuilder:
              (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                labelText: 'Departamento(s)',
                hintText: 'Escribe para buscar y seleccionar varios',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isImageFile(String name) {
    final n = name.toLowerCase();
    return n.endsWith('.png') ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.gif') ||
        n.endsWith('.webp');
  }

  bool _isPdfFile(String name) {
    return name.toLowerCase().endsWith('.pdf');
  }

  bool _isOfficeFile(String name) {
    final n = name.toLowerCase();
    return n.endsWith('.doc') ||
        n.endsWith('.docx') ||
        n.endsWith('.xls') ||
        n.endsWith('.xlsx') ||
        n.endsWith('.ppt') ||
        n.endsWith('.pptx');
  }

  IconData _attachmentIcon(String name) {
    if (_isImageFile(name)) return Icons.image_outlined;
    if (_isPdfFile(name)) return Icons.picture_as_pdf;
    if (_isOfficeFile(name)) return Icons.description_outlined;
    return Icons.attach_file;
  }

  Color _attachmentIconColor(String name) {
    if (_isImageFile(name)) return Colors.blue;
    if (_isPdfFile(name)) return Colors.red;
    if (_isOfficeFile(name)) return Colors.green;
    return Colors.blueGrey;
  }

  Future<void> _openAttachmentUrl(String url) async {
    final uri = Uri.parse(url);

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok) {
      throw Exception('No se pudo abrir el archivo');
    }
  }

  Future<void> _previewAttachment(Map<String, dynamic> item) async {
    final attachmentId = _asInt(item['id']);
    final name = _s(item['original_name']).trim();
    final url = NoticesService().getNom035AttachmentDownloadUrl(attachmentId);

    if (_isImageFile(name)) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 700,
            height: 600,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.image_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name.isEmpty ? 'Vista previa' : name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Abrir',
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await _openAttachmentUrl(url);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Center(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No se pudo cargar la vista previa de la imagen.',
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vista previa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _attachmentIcon(name),
              size: 60,
              color: _attachmentIconColor(name),
            ),
            const SizedBox(height: 12),
            Text(
              name.isEmpty ? 'Archivo adjunto' : name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isPdfFile(name)
                  ? 'El PDF se abrirá en una aplicación externa o navegador.'
                  : _isOfficeFile(name)
                      ? 'Este archivo se abrirá en una aplicación compatible.'
                      : 'Se abrirá el archivo en una aplicación externa.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _openAttachmentUrl(url);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            icon: const Icon(Icons.remove_red_eye_outlined),
            label: const Text('Abrir vista previa'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final dueCtl = TextEditingController();

    int? localCycleId = selectedCycleId ?? widget.cycleId;
    List<int> selectedDepartmentIds = [];
    int? selectedResponsibleUserId;
    String? riskLevel;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Crear plan de acción'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: localCycleId,
                    decoration: const InputDecoration(
                      labelText: 'Ciclo',
                      border: OutlineInputBorder(),
                    ),
                    items: cycles.map((c) {
                      final id = c['_id'] as int;
                      final title = (c['_title'] as String).isEmpty
                          ? 'Ciclo $id'
                          : c['_title'] as String;
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(title),
                      );
                    }).toList(),
                    onChanged: (v) => setLocal(() => localCycleId = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMultiAreaSelector(
                    selectedIds: selectedDepartmentIds,
                    onChanged: (v) => setLocal(() => selectedDepartmentIds = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: riskLevel,
                    decoration: const InputDecoration(
                      labelText: 'Nivel de riesgo',
                      border: OutlineInputBorder(),
                    ),
                    items: _riskLevels
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => riskLevel = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  _buildUserAutocomplete(
                    selectedId: selectedResponsibleUserId,
                    onChanged: (v) =>
                        setLocal(() => selectedResponsibleUserId = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dueCtl,
                    readOnly: true,
                    onTap: () async {
                      await _pickDate(
                        dialogContext,
                        dueCtl,
                        () => setLocal(() {}),
                      );
                    },
                    decoration: const InputDecoration(
                      labelText: 'Fecha límite',
                      hintText: 'Selecciona una fecha',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  if (dueCtl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Fecha seleccionada: ${_formatDateMx(dueCtl.text)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    if (titleCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }

    try {
      final departmentId =
          selectedDepartmentIds.isNotEmpty ? selectedDepartmentIds.first : null;
      final departmentName = _departmentNamesFromIds(selectedDepartmentIds);
      final responsibleName = _userNameById(selectedResponsibleUserId);

      await NoticesService().createNom035ActionPlan(
        cycleId: localCycleId ?? widget.cycleId,
        departmentId: departmentId,
        departmentName: departmentName.isEmpty ? null : departmentName,
        riskLevel: riskLevel?.trim(),
        actionTitle: titleCtl.text.trim(),
        actionDescription: descCtl.text.trim(),
        responsibleName: responsibleName.isEmpty ? null : responsibleName,
        responsibleUserId: selectedResponsibleUserId,
        dueDate: _dateForApi(dueCtl.text),
        createdByUserId: _asInt(widget.userData['id']),
      );

      selectedCycleId = localCycleId ?? widget.cycleId;
      NoticesService.clearNom035Caches();
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan de acción creado')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final titleCtl = TextEditingController(text: _s(item['action_title']));
    final descCtl =
        TextEditingController(text: _s(item['action_description']));
    final dueCtl = TextEditingController(
      text: _normalizeDateForInput(item['due_date']),
    );

    int? localCycleId = _asInt(item['cycle_id']);
    if (localCycleId == 0) localCycleId = selectedCycleId ?? widget.cycleId;

    List<int> selectedDepartmentIds = _departmentIdsFromItem(item);

    int? selectedResponsibleUserId = _asInt(item['responsible_user_id']);
    if (selectedResponsibleUserId == 0) selectedResponsibleUserId = null;

    String? riskLevel =
        _s(item['risk_level']).isEmpty ? null : _s(item['risk_level']);
    String status =
        _s(item['status']).isEmpty ? 'pendiente' : _s(item['status']);
    double progress = _asDouble(item['progress_percent']).clamp(0, 100);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Editar plan de acción'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    value: localCycleId,
                    decoration: const InputDecoration(
                      labelText: 'Ciclo',
                      border: OutlineInputBorder(),
                    ),
                    items: cycles.map((c) {
                      final id = c['_id'] as int;
                      final title = (c['_title'] as String).isEmpty
                          ? 'Ciclo $id'
                          : c['_title'] as String;
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text(title),
                      );
                    }).toList(),
                    onChanged: (v) => setLocal(() => localCycleId = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(
                      labelText: 'Título *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMultiAreaSelector(
                    selectedIds: selectedDepartmentIds,
                    onChanged: (v) => setLocal(() => selectedDepartmentIds = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _riskLevels.contains(riskLevel) ? riskLevel : null,
                    decoration: const InputDecoration(
                      labelText: 'Nivel de riesgo',
                      border: OutlineInputBorder(),
                    ),
                    items: _riskLevels
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => riskLevel = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  _buildUserAutocomplete(
                    selectedId: selectedResponsibleUserId,
                    onChanged: (v) =>
                        setLocal(() => selectedResponsibleUserId = v),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dueCtl,
                    readOnly: true,
                    onTap: () async {
                      await _pickDate(
                        dialogContext,
                        dueCtl,
                        () => setLocal(() {}),
                      );
                    },
                    decoration: const InputDecoration(
                      labelText: 'Fecha límite',
                      hintText: 'Selecciona una fecha',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  if (dueCtl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Fecha seleccionada: ${_formatDateMx(dueCtl.text)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _statuses.contains(status) ? status : 'pendiente',
                    decoration: const InputDecoration(
                      labelText: 'Estatus',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem(
                        value: 'en_proceso',
                        child: Text('En proceso'),
                      ),
                      DropdownMenuItem(
                        value: 'completado',
                        child: Text('Completado'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelado',
                        child: Text('Cancelado'),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => status = v ?? 'pendiente'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Avance'),
                      Expanded(
                        child: Slider(
                          value: progress,
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '${progress.toStringAsFixed(0)}%',
                          onChanged: (v) => setLocal(() => progress = v),
                        ),
                      ),
                      Text('${progress.toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    if (titleCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }

    try {
      final departmentId =
          selectedDepartmentIds.isNotEmpty ? selectedDepartmentIds.first : null;
      final departmentName = _departmentNamesFromIds(selectedDepartmentIds);
      final responsibleName = _userNameById(selectedResponsibleUserId);

      await NoticesService().updateNom035ActionPlan(
        planId: _asInt(item['id']),
        cycleId: localCycleId,
        departmentId: departmentId,
        departmentName: departmentName.isEmpty ? null : departmentName,
        riskLevel: riskLevel?.trim(),
        actionTitle: titleCtl.text.trim(),
        actionDescription: descCtl.text.trim(),
        responsibleName: responsibleName.isEmpty ? null : responsibleName,
        responsibleUserId: selectedResponsibleUserId,
        dueDate: _dateForApi(dueCtl.text),
        status: status,
        progressPercent: progress,
      );

      selectedCycleId = localCycleId ?? selectedCycleId;
      NoticesService.clearNom035Caches();
      await _refresh();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan actualizado')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deletePlan(int planId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar plan'),
        content: const Text('¿Deseas eliminar este plan de acción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await NoticesService().deleteNom035ActionPlan(planId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan eliminado')),
      );
      NoticesService.clearNom035Caches();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _pickAndUploadAttachment(int planId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'doc',
          'docx',
          'xls',
          'xlsx'
        ],
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;

      if (picked.name.trim().isEmpty) {
        throw Exception('No se pudo leer el archivo seleccionado');
      }

      if (kIsWeb) {
        if (picked.bytes == null) {
          throw Exception('No se pudieron obtener los bytes del archivo');
        }

        await NoticesService().uploadNom035ActionPlanAttachmentWeb(
          planId: planId,
          bytes: picked.bytes!,
          fileName: picked.name,
          uploadedByUserId: _asInt(widget.userData['id']),
        );
      } else {
        if (picked.path == null || picked.path!.trim().isEmpty) {
          throw Exception('No se pudo leer la ruta del archivo');
        }

        final file = File(picked.path!);

        await NoticesService().uploadNom035ActionPlanAttachment(
          planId: planId,
          file: file,
          fileName: picked.name,
          uploadedByUserId: _asInt(widget.userData['id']),
        );
      }

      attachmentsByPlan.remove(planId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivo adjunto cargado')),
      );

      await _loadAttachments(planId, forceRefresh: true);
      setState(() {
        attachmentsExpanded[planId] = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al adjuntar archivo: $e')),
      );
    }
  }

  Future<void> _deleteAttachment(int attachmentId, int planId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar adjunto'),
        content: const Text('¿Deseas eliminar este archivo adjunto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await NoticesService().deleteNom035ActionPlanAttachment(attachmentId);

      attachmentsByPlan.remove(planId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunto eliminado')),
      );

      await _loadAttachments(planId, forceRefresh: true);
      setState(() {
        attachmentsExpanded[planId] = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _downloadPlanPdf(int planId) async {
    try {
      final url = NoticesService().getNom035ActionPlanPdfUrl(planId);
      final uri = Uri.parse(url);

      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!ok) {
        throw Exception('No se pudo abrir el PDF');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abriendo PDF...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar PDF: $e')),
      );
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final cycleId = selectedCycleId ?? widget.cycleId;
      final url = NoticesService().getNom035ActionPlansCyclePdfUrl(cycleId);
      final uri = Uri.parse(url);

      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!ok) {
        throw Exception('No se pudo abrir el PDF del ciclo');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abriendo PDF del ciclo...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir PDF del ciclo: $e')),
      );
    }
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error ?? 'Error desconocido', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadInitial,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planActionMenu(int planId, Map<String, dynamic> item) {
    return PopupMenuButton<String>(
      tooltip: 'Opciones',
      icon: const Icon(Icons.settings),
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await _showEditDialog(item);
            break;
          case 'pdf':
            await _downloadPlanPdf(planId);
            break;
          case 'attach':
            await _pickAndUploadAttachment(planId);
            break;
          case 'delete':
            await _deletePlan(planId);
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf, color: Colors.red),
              SizedBox(width: 8),
              Text('Descargar PDF'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'attach',
          child: Row(
            children: [
              Icon(Icons.attach_file),
              SizedBox(width: 8),
              Text('Adjuntar archivo'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentList(int planId) {
    final attachments = attachmentsByPlan[planId] ?? [];
    final isLoading = loadingAttachments[planId] == true;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: LinearProgressIndicator(),
      );
    }

    if (attachments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('Sin archivos adjuntos'),
      );
    }

    return Column(
      children: attachments.map((item) {
        final attachmentId = _asInt(item['id']);
        final originalName =
            _s(item['original_name']).isEmpty ? 'Archivo' : _s(item['original_name']);

        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(
                _attachmentIcon(originalName),
                color: _attachmentIconColor(originalName),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _previewAttachment(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          originalName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tamaño: ${_formatBytes(item['file_size'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Toca el nombre para vista previa',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Vista previa',
                    onPressed: () => _previewAttachment(item),
                    icon: const Icon(Icons.remove_red_eye_outlined),
                  ),
                  IconButton(
                    tooltip: 'Descargar',
                    onPressed: () async {
                      try {
                        final url = NoticesService()
                            .getNom035AttachmentDownloadUrl(attachmentId);
                        await _openAttachmentUrl(url);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al descargar adjunto: $e'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.download_outlined),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: () => _deleteAttachment(attachmentId, planId),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

 Widget _planCard(Map<String, dynamic> item, int index) {
  final planId = item['_id'] as int;
  final status = item['_status'] as String;
  final progress = item['_progress'] as double;
  final risk = item['_risk'] as String;
  final title = item['_title'] as String;
  final description = item['_description'] as String;
  final departmentName = item['_departmentName'] as String;
  final responsibleName = item['_responsibleName'] as String;
  final dueDate = item['_dueDate'] as String;

  final statusColor = _statusColor(status);

  final loadedAttachmentsCount = (attachmentsByPlan[planId] ?? []).length;
  final initialAttachmentsCount = item['_attachmentsCount'] as int? ?? 0;

  final attachmentsCount = loadedAttachmentsCount > 0
      ? loadedAttachmentsCount
      : initialAttachmentsCount;

  return Card(
    key: ValueKey(planId),
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 500;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      _cardNumber(index),
                      style: TextStyle(
                        fontSize: isSmall ? 28 : 36,
                        fontWeight: FontWeight.bold,
                        color: statusColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 55,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title.isEmpty ? 'Sin título' : title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _planActionMenu(planId, item),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text('Depto: ${departmentName.isEmpty ? '—' : departmentName}'),
                  Text('Riesgo: ${risk.isEmpty ? '—' : risk}'),
                  Text(
                    'Responsable: ${responsibleName.isEmpty ? '—' : responsibleName}',
                  ),
                  Text('Fecha: ${_formatDateMx(dueDate)}'),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress / 100,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Avance: ${progress.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _toggleAttachments(planId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.folder_open_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Adjuntos ($attachmentsCount)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        attachmentsExpanded[planId] == true
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ],
                  ),
                ),
              ),
              if (attachmentsExpanded[planId] == true)
                _buildAttachmentList(planId),
            ],
          );
        },
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final currentCycleTitle = _cycleTitleById(selectedCycleId).isEmpty
        ? widget.cycleTitle
        : _cycleTitleById(selectedCycleId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(currentCycleTitle),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'pdf') {
                await _downloadPdf();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Descargar PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Crear plan'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _errorView()
              : Column(
                  children: [
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Text('No hay planes de acción registrados.'),
                            )
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: items.length,
                                cacheExtent: 500,
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                itemBuilder: (_, i) {
                                  return _planCard(items[i], i);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}