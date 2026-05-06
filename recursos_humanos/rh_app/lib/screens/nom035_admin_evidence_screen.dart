import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:universal_html/html.dart' as html;

import '../services/notices_service.dart';

class Nom035AdminEvidenceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int cycleId;
  final String? cycleTitle;

  const Nom035AdminEvidenceScreen({
    super.key,
    required this.userData,
    required this.cycleId,
    this.cycleTitle,
  });

  @override
  State<Nom035AdminEvidenceScreen> createState() =>
      _Nom035AdminEvidenceScreenState();
}

class _Nom035AdminEvidenceScreenState
    extends State<Nom035AdminEvidenceScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> actionPlans = [];
  List<Map<String, dynamic>> _filteredItemsCache = [];

  int? selectedPlanId;
  String selectedType = '';
  String searchText = '';

  int? openingEvidenceId;
  int? previewingEvidenceId;
  int? downloadingEvidenceId;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final Map<int, Uint8List> _fileCache = {};

  static const List<Map<String, String>> evidenceTypes = [
    {'value': 'policy', 'label': 'Política'},
    {'value': 'diffusion', 'label': 'Difusión'},
    {'value': 'training', 'label': 'Capacitación'},
    {'value': 'diagnostic', 'label': 'Diagnóstico'},
    {'value': 'action_plan', 'label': 'Plan de acción'},
    {'value': 'action_execution', 'label': 'Ejecución de acción'},
    {'value': 'stps_support', 'label': 'Soporte STPS'},
  ];

  static const Map<String, String> _typeLabelMap = {
    'policy': 'Política',
    'diffusion': 'Difusión',
    'training': 'Capacitación',
    'diagnostic': 'Diagnóstico',
    'action_plan': 'Plan de acción',
    'action_execution': 'Ejecución de acción',
    'stps_support': 'Soporte STPS',
  };

  static const Map<String, Color> _typeColorMap = {
    'policy': Colors.indigo,
    'diffusion': Colors.teal,
    'training': Colors.orange,
    'diagnostic': Colors.deepPurple,
    'action_plan': Colors.blue,
    'action_execution': Colors.green,
    'stps_support': Colors.brown,
  };

  String _s(dynamic v) => v == null ? '' : v.toString();

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
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

  String _typeLabel(String? value) {
    final safeValue = value ?? '';
    if (safeValue.isEmpty) return '—';
    return _typeLabelMap[safeValue] ?? safeValue;
  }

  Color _typeColor(String? value) {
    return _typeColorMap[value ?? ''] ?? Colors.blueGrey;
  }

  String _cardNumber(int index) {
    final number = index + 1;
    return number.toString().padLeft(2, '0');
  }

  IconData _fileIcon(String fileName) {
    final f = fileName.toLowerCase();

    if (f.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (f.endsWith('.png') ||
        f.endsWith('.jpg') ||
        f.endsWith('.jpeg') ||
        f.endsWith('.gif') ||
        f.endsWith('.webp') ||
        f.endsWith('.bmp')) {
      return Icons.image;
    }
    if (f.endsWith('.xls') || f.endsWith('.xlsx') || f.endsWith('.csv')) {
      return Icons.table_chart;
    }
    if (f.endsWith('.doc') || f.endsWith('.docx')) {
      return Icons.description;
    }
    if (f.endsWith('.ppt') || f.endsWith('.pptx')) {
      return Icons.slideshow;
    }
    if (f.endsWith('.zip') || f.endsWith('.rar')) {
      return Icons.folder_zip;
    }
    return Icons.insert_drive_file;
  }

  bool _isImageFile(String fileName) {
    final f = fileName.toLowerCase();
    return f.endsWith('.png') ||
        f.endsWith('.jpg') ||
        f.endsWith('.jpeg') ||
        f.endsWith('.gif') ||
        f.endsWith('.webp') ||
        f.endsWith('.bmp');
  }

  bool _isPdfFile(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  String _extension(String fileName) {
    final idx = fileName.lastIndexOf('.');
    if (idx == -1 || idx == fileName.length - 1) return '';
    return fileName.substring(idx + 1).toLowerCase();
  }

  String _mimeFromFileName(String fileName) {
    final ext = _extension(fileName);

    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _normalizeEvidence(dynamic e) {
    final m = _asMap(e);

    final id = _asInt(m['id']);
    final title = _s(m['title']);
    final titleLower = title.toLowerCase();
    final fileName = _s(m['file_name']);
    final fileNameLower = fileName.toLowerCase();
    final actionTitle = _s(m['action_title']);
    final actionTitleLower = actionTitle.toLowerCase();
    final evidenceType = _s(m['evidence_type']);
    final actionPlanId = m['action_plan_id'] == null || _s(m['action_plan_id']).isEmpty
        ? null
        : _asInt(m['action_plan_id']);

    return {
      ...m,
      '_id': id,
      '_title': title,
      '_titleLower': titleLower,
      '_fileName': fileName,
      '_fileNameLower': fileNameLower,
      '_actionTitle': actionTitle,
      '_actionTitleLower': actionTitleLower,
      '_evidenceType': evidenceType,
      '_actionPlanId': actionPlanId,
    };
  }

  Map<String, dynamic> _normalizePlan(dynamic p) {
    final m = _asMap(p);
    return {
      ...m,
      '_id': _asInt(m['id']),
      '_actionTitle': _s(m['action_title']),
    };
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final service = NoticesService();

      final results = await Future.wait([
        service.getNom035Evidences(widget.cycleId),
        service.getNom035ActionPlans(widget.cycleId),
      ]);

      final evidenceData = results[0];
      final plansData = results[1];

      final loadedItems = _asList(evidenceData['items'])
          .map<Map<String, dynamic>>(_normalizeEvidence)
          .toList();

      final loadedPlans = _asList(plansData['items'])
          .map<Map<String, dynamic>>(_normalizePlan)
          .toList();

      if (!mounted) return;

      setState(() {
        items = loadedItems;
        actionPlans = loadedPlans;
        _applyFiltersLocal();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _applyFiltersLocal() {
    final query = searchText.trim().toLowerCase();

    _filteredItemsCache = items.where((item) {
      final itemPlanId = item['_actionPlanId'] as int?;
      final itemType = item['_evidenceType'] as String? ?? '';

      final matchPlan =
          selectedPlanId == null ? true : itemPlanId == selectedPlanId;

      final matchType =
          selectedType.isEmpty ? true : itemType == selectedType;

      final matchSearch = query.isEmpty
          ? true
          : (item['_titleLower'] as String).contains(query) ||
              (item['_fileNameLower'] as String).contains(query) ||
              (item['_actionTitleLower'] as String).contains(query);

      return matchPlan && matchType && matchSearch;
    }).toList();
  }

  Future<File?> _pickFileMobile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null || path.isEmpty) return null;

    return File(path);
  }

  Future<Map<String, dynamic>?> _pickFileWeb() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    if (file.bytes == null) return null;

    return {
      'bytes': file.bytes!,
      'filename': file.name,
    };
  }

  Future<void> _showCreateDialog() async {
    final titleCtl = TextEditingController();
    int? planId;
    String? evidenceType;
    File? selectedFile;
    Uint8List? selectedBytes;
    String selectedFileName = '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Crear evidencia'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    initialValue: planId,
                    decoration: const InputDecoration(
                      labelText: 'Plan de acción',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin plan'),
                      ),
                      ...actionPlans.map((p) {
                        final id = p['_id'] as int;
                        final actionTitle = (p['_actionTitle'] as String).trim();
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(
                            '[$id] ${actionTitle.isEmpty ? 'Sin título' : actionTitle}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) => setLocal(() => planId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: evidenceType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evidencia *',
                    ),
                    items: evidenceTypes
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e['value'] ?? '',
                            child: Text(e['label'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => evidenceType = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(labelText: 'Título *'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final small = constraints.maxWidth < 420;

                        Future<void> selectFile() async {
                          if (kIsWeb) {
                            final file = await _pickFileWeb();
                            if (file == null) return;
                            setLocal(() {
                              selectedBytes = file['bytes'] as Uint8List;
                              selectedFileName = _s(file['filename']);
                              selectedFile = null;
                            });
                          } else {
                            final file = await _pickFileMobile();
                            if (file == null) return;
                            setLocal(() {
                              selectedFile = file;
                              selectedFileName =
                                  file.path.split(Platform.pathSeparator).last;
                              selectedBytes = null;
                            });
                          }
                        }

                        if (small) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                onPressed: selectFile,
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Seleccionar archivo'),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  selectedFileName.isEmpty
                                      ? 'Ningún archivo seleccionado'
                                      : selectedFileName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          );
                        }

                        return Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: selectFile,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Seleccionar archivo'),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 260),
                              child: Text(
                                selectedFileName.isEmpty
                                    ? 'Ningún archivo seleccionado'
                                    : selectedFileName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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

    if (ok != true) {
      titleCtl.dispose();
      return;
    }

    if (titleCtl.text.trim().isEmpty) {
      titleCtl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }

    if ((evidenceType ?? '').isEmpty) {
      titleCtl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de evidencia')),
      );
      return;
    }

    if (!kIsWeb && selectedFile == null) {
      titleCtl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un archivo')),
      );
      return;
    }

    if (kIsWeb && (selectedBytes == null || selectedFileName.isEmpty)) {
      titleCtl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un archivo')),
      );
      return;
    }

    try {
      final service = NoticesService();

      if (kIsWeb) {
        await service.createNom035EvidenceWeb(
          cycleId: widget.cycleId,
          actionPlanId: planId,
          evidenceType: evidenceType!,
          title: titleCtl.text.trim(),
          bytes: selectedBytes!,
          filename: selectedFileName,
          uploadedByUserId: _asInt(widget.userData['id']),
        );
      } else {
        await service.createNom035Evidence(
          cycleId: widget.cycleId,
          actionPlanId: planId,
          evidenceType: evidenceType!,
          title: titleCtl.text.trim(),
          file: selectedFile!,
          uploadedByUserId: _asInt(widget.userData['id']),
        );
      }

      titleCtl.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia creada')),
      );
      await _load();
    } catch (e) {
      titleCtl.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final titleCtl = TextEditingController(text: item['_title'] as String? ?? '');

    int? planId = item['_actionPlanId'] as int?;
    String? evidenceType = (item['_evidenceType'] as String?)?.isEmpty ?? true
        ? null
        : item['_evidenceType'] as String?;
    File? selectedFile;
    Uint8List? selectedBytes;
    String selectedFileName = item['_fileName'] as String? ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Editar evidencia'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int?>(
                    initialValue: planId,
                    decoration: const InputDecoration(
                      labelText: 'Plan de acción',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin plan'),
                      ),
                      ...actionPlans.map((p) {
                        final id = p['_id'] as int;
                        final actionTitle = (p['_actionTitle'] as String).trim();
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(
                            '[$id] ${actionTitle.isEmpty ? 'Sin título' : actionTitle}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) => setLocal(() => planId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: evidenceType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de evidencia *',
                    ),
                    items: evidenceTypes
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e['value'] ?? '',
                            child: Text(e['label'] ?? ''),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setLocal(() => evidenceType = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtl,
                    decoration: const InputDecoration(labelText: 'Título *'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final small = constraints.maxWidth < 420;

                        Future<void> selectFile() async {
                          if (kIsWeb) {
                            final file = await _pickFileWeb();
                            if (file == null) return;
                            setLocal(() {
                              selectedBytes = file['bytes'] as Uint8List;
                              selectedFileName = _s(file['filename']);
                              selectedFile = null;
                            });
                          } else {
                            final file = await _pickFileMobile();
                            if (file == null) return;
                            setLocal(() {
                              selectedFile = file;
                              selectedFileName =
                                  file.path.split(Platform.pathSeparator).last;
                              selectedBytes = null;
                            });
                          }
                        }

                        if (small) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              OutlinedButton.icon(
                                onPressed: selectFile,
                                icon: const Icon(Icons.attach_file),
                                label: const Text('Reemplazar archivo'),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  selectedFileName.isEmpty
                                      ? 'Sin archivo'
                                      : selectedFileName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: selectFile,
                              icon: const Icon(Icons.attach_file),
                              label: const Text('Reemplazar archivo'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedFileName.isEmpty
                                    ? 'Sin archivo'
                                    : selectedFileName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Si no seleccionas archivo, se conserva el actual.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
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

    if (ok != true) {
      titleCtl.dispose();
      return;
    }

    if (titleCtl.text.trim().isEmpty) {
      titleCtl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio')),
      );
      return;
    }

    if ((evidenceType ?? '').isEmpty) {
      titleCtl.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de evidencia')),
      );
      return;
    }

    try {
      final service = NoticesService();

      if (kIsWeb) {
        await service.updateNom035EvidenceWeb(
          evidenceId: _asInt(item['id']),
          cycleId: widget.cycleId,
          actionPlanId: planId,
          evidenceType: evidenceType!,
          title: titleCtl.text.trim(),
          uploadedByUserId: _asInt(widget.userData['id']),
          bytes: selectedBytes,
          filename: selectedBytes != null ? selectedFileName : null,
        );
      } else {
        await service.updateNom035Evidence(
          evidenceId: _asInt(item['id']),
          cycleId: widget.cycleId,
          actionPlanId: planId,
          evidenceType: evidenceType!,
          title: titleCtl.text.trim(),
          uploadedByUserId: _asInt(widget.userData['id']),
          file: selectedFile,
        );
      }

      final evidenceId = _asInt(item['id']);
      _fileCache.remove(evidenceId);
      NoticesService.clearEvidenceFileCache(evidenceId);

      titleCtl.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia actualizada')),
      );
      await _load();
    } catch (e) {
      titleCtl.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteEvidence(int evidenceId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar evidencia'),
        content: const Text('¿Deseas eliminar esta evidencia?'),
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
      await NoticesService().deleteNom035Evidence(evidenceId);
      _fileCache.remove(evidenceId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia eliminada')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Uint8List> _getEvidenceBytes(int evidenceId) async {
    final cached = _fileCache[evidenceId];
    if (cached != null) return cached;

    final bytes = await NoticesService().downloadNom035Evidence(evidenceId);
    _fileCache[evidenceId] = bytes;
    return bytes;
  }

  Future<void> _downloadEvidence(
    int evidenceId,
    String fileName,
  ) async {
    try {
      setState(() => downloadingEvidenceId = evidenceId);

      final bytes = await _getEvidenceBytes(evidenceId);
      final safeFileName = fileName.trim().isEmpty
          ? 'evidencia_$evidenceId'
          : fileName.trim();

      if (kIsWeb) {
        final mime = _mimeFromFileName(safeFileName);
        final blob = html.Blob([bytes], mime);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', safeFileName)
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/$safeFileName';
        final file = File(path);
        await file.writeAsBytes(bytes, flush: true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo guardado en: $path')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => downloadingEvidenceId = null);
      }
    }
  }

  Future<String> _writeTempFile(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final safeName = fileName.trim().isEmpty
        ? 'archivo_${DateTime.now().millisecondsSinceEpoch}'
        : fileName.replaceAll('/', '_').replaceAll('\\', '_');

    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _openFile(Map<String, dynamic> item) async {
    final evidenceId = item['_id'] as int? ?? _asInt(item['id']);
    final fileName = (item['_fileName'] as String?)?.isNotEmpty == true
        ? item['_fileName'] as String
        : 'evidencia_$evidenceId';

    try {
      setState(() => openingEvidenceId = evidenceId);

      final bytes = await _getEvidenceBytes(evidenceId);

      if (kIsWeb) {
        final mime = _mimeFromFileName(fileName);
        final blob = html.Blob([bytes], mime);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.window.open(url, '_blank');
        Future.delayed(const Duration(seconds: 15), () {
          html.Url.revokeObjectUrl(url);
        });
        return;
      }

      final tempPath = await _writeTempFile(bytes, fileName);
      final result = await OpenFilex.open(tempPath);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el archivo: ${result.message}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir archivo: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => openingEvidenceId = null);
      }
    }
  }

  Future<void> _previewEvidence(Map<String, dynamic> item) async {
    final evidenceId = item['_id'] as int? ?? _asInt(item['id']);
    final fileName = (item['_fileName'] as String?)?.isNotEmpty == true
        ? item['_fileName'] as String
        : 'evidencia_$evidenceId';

    try {
      setState(() => previewingEvidenceId = evidenceId);

      final bytes = await _getEvidenceBytes(evidenceId);

      if (!mounted) return;

      final isImage = _isImageFile(fileName);
      final isPdf = _isPdfFile(fileName);

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 1000,
            height: 720,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  child: Builder(
                    builder: (_) {
                      if (isImage) {
                        return InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 5,
                          child: Center(
                            child: Image.memory(
                              bytes,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (_, __, ___) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'No se pudo mostrar la imagen.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }

                      if (isPdf) {
                        return SfPdfViewer.memory(
                          bytes,
                          canShowPaginationDialog: false,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                        );
                      }

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 58,
                                color: Colors.orange,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Vista previa no disponible para este tipo de archivo.',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Puedes abrirlo con una aplicación externa o descargarlo.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _openFile(item);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Abrir archivo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _downloadEvidence(evidenceId, fileName);
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Descargar'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir vista previa: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => previewingEvidenceId = null);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedPlanId = null;
      selectedType = '';
      searchText = '';
      _searchController.clear();
      _applyFiltersLocal();
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        searchText = value;
        _applyFiltersLocal();
      });
    });
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
              onPressed: _load,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _filterDeco(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          int columns;
          if (width > 1200) {
            columns = 4;
          } else if (width > 800) {
            columns = 3;
          } else if (width > 500) {
            columns = 2;
          } else {
            columns = 1;
          }

          final itemWidth =
              columns == 1 ? width : (width - (columns - 1) * 6) / columns;

          final smallWidth = columns == 1 ? width : itemWidth * 0.72;

          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<int?>(
                  value: selectedPlanId,
                  isExpanded: true,
                  decoration: _filterDeco('Plan'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text(
                        'Todos',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...actionPlans.map((p) {
                      final id = p['_id'] as int;
                      final title = (p['_actionTitle'] as String).trim();
                      final shortTitle =
                          title.length > 22 ? '${title.substring(0, 22)}...' : title;

                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(
                          '[$id] ${shortTitle.isEmpty ? 'Sin título' : shortTitle}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedPlanId = v;
                      _applyFiltersLocal();
                    });
                  },
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<String>(
                  value: selectedType,
                  isExpanded: true,
                  decoration: _filterDeco('Tipo'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text(
                        'Todos',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...evidenceTypes.map(
                      (e) => DropdownMenuItem<String>(
                        value: e['value'] ?? '',
                        child: Text(
                          e['label'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      selectedType = v ?? '';
                      _applyFiltersLocal();
                    });
                  },
                ),
              ),
              SizedBox(
                width: smallWidth,
                child: TextField(
                  controller: _searchController,
                  decoration: _filterDeco('Buscar').copyWith(
                    prefixIcon: const Icon(Icons.search, size: 18),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              SizedBox(
                width: smallWidth,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text(
                    'Limpiar',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _activeFiltersChips() {
    final chips = <Widget>[];

    if (selectedPlanId != null) {
      String planLabel = 'Plan #$selectedPlanId';

      for (final p in actionPlans) {
        if ((p['_id'] as int) == selectedPlanId) {
          final title = (p['_actionTitle'] as String).trim();
          final shortTitle =
              title.length > 28 ? '${title.substring(0, 28)}...' : title;
          planLabel =
              title.isEmpty ? 'Plan #$selectedPlanId' : 'Plan: $shortTitle';
          break;
        }
      }

      chips.add(
        InputChip(
          label: Text(
            planLabel,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () {
            setState(() {
              selectedPlanId = null;
              _applyFiltersLocal();
            });
          },
        ),
      );
    }

    if (selectedType.isNotEmpty) {
      chips.add(
        InputChip(
          label: Text('Tipo: ${_typeLabel(selectedType)}'),
          onDeleted: () {
            setState(() {
              selectedType = '';
              _applyFiltersLocal();
            });
          },
        ),
      );
    }

    if (searchText.trim().isNotEmpty) {
      chips.add(
        InputChip(
          label: Text(
            'Buscar: ${searchText.trim()}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      chips.add(
        InputChip(
          label: const Text('Quitar búsqueda'),
          onDeleted: () {
            setState(() {
              searchText = '';
              _searchController.clear();
              _applyFiltersLocal();
            });
          },
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...chips,
            ActionChip(
              avatar: const Icon(Icons.clear_all, size: 18),
              label: const Text('Limpiar todo'),
              onPressed: _clearFilters,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionMenu(Map<String, dynamic> item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings),
      tooltip: 'Opciones',
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            await _showEditDialog(item);
            break;
          case 'file':
            await _showEditDialog(item);
            break;
          case 'download':
            await _downloadEvidence(
              item['_id'] as int? ?? _asInt(item['id']),
              item['_fileName'] as String? ?? _s(item['file_name']),
            );
            break;
          case 'delete':
            await _deleteEvidence(item['_id'] as int? ?? _asInt(item['id']));
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'edit',
          child: Text('Editar'),
        ),
        PopupMenuItem<String>(
          value: 'file',
          child: Text('Adjuntar / reemplazar archivo'),
        ),
        PopupMenuItem<String>(
          value: 'download',
          child: Text('Descargar archivo'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text('Eliminar'),
        ),
      ],
    );
  }

  Widget _evidenceCard(Map<String, dynamic> item, int index) {
    final evidenceId = item['_id'] as int? ?? _asInt(item['id']);
    final evidenceType = item['_evidenceType'] as String? ?? '';
    final fileName = item['_fileName'] as String? ?? '';
    final createdAt = _s(item['created_at']);
    final actionPlanId = item['_actionPlanId'] as int?;
    final actionTitle = item['_actionTitle'] as String? ?? '';
    final title = item['_title'] as String? ?? 'Sin título';

    final typeColor = _typeColor(evidenceType);
    final typeLabel = _typeLabel(evidenceType);
    final isPreviewing = previewingEvidenceId == evidenceId;

    return Card(
      key: ValueKey(evidenceId),
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
                          color: typeColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 55,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: typeColor,
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
                              _actionMenu(item),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
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
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Text('Plan: ${actionPlanId == null ? '—' : '#$actionPlanId'}'),
                    Text('Archivo: ${fileName.isEmpty ? '—' : fileName}'),
                    Text(
                      'Fecha: ${createdAt.isEmpty ? '—' : createdAt.split(' ').first}',
                    ),
                  ],
                ),
                if (actionTitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Título del plan: $actionTitle',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _previewEvidence(item),
                      icon: isPreviewing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.visibility_outlined),
                      label: const Text('Vista previa'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredItemsCache;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.cycleTitle ?? 'Evidencias NOM-035'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Crear evidencia'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _errorView()
              : Column(
                  children: [
                    _filters(),
                    _activeFiltersChips(),
                    Expanded(
                      child: list.isEmpty
                          ? const Center(
                              child: Text('No hay evidencias registradas.'),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                itemCount: list.length,
                                cacheExtent: 500,
                                addAutomaticKeepAlives: false,
                                addRepaintBoundaries: true,
                                itemBuilder: (_, i) {
                                  return _evidenceCard(list[i], i);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}