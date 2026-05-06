import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/notices_service.dart';

String absoluteUrl(String raw) {
  final baseUrl = AuthService.baseUrl;

  final s = raw.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (s.startsWith('/')) return '$baseUrl$s';
  return '$baseUrl/$s';
}

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NotificationsScreen({
    super.key,
    required this.userData,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool get isAdminOrRH {
    final role = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    return role == 1 || role == 2;
  }

  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();
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

  String _formatAreas(dynamic areas) {
    if (areas == null || areas is! List || areas.isEmpty) {
      return 'Todas las áreas';
    }

    final names = areas
        .map((e) => (e['name'] ?? '').toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    if (names.isEmpty) return 'Todas las áreas';
    return names.join(', ');
  }

  Future<void> _openPdfPreview(String pdfUrl) async {
    final fullUrl = absoluteUrl(pdfUrl);

    if (fullUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el PDF')),
      );
      return;
    }

    if (kIsWeb) {
      final uri = Uri.parse(fullUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el PDF')),
        );
      }
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Vista previa PDF')),
          body: SfPdfViewer.network(fullUrl),
        ),
      ),
    );
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final data = await NoticesService.getNotices();

      if (!mounted) return;
      setState(() {
        items = data;
      });

      if (!isAdminOrRH) {
        for (final n in data) {
          final id = (n['id'] as num?)?.toInt();
          if (id != null) {
            try {
              await NoticesService.markNoticeViewed(id);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar avisos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NoticeFormDialog(
        title: 'Nuevo aviso',
      ),
    );

    if (created == true) {
      await _load();
    }
  }

  Future<void> _edit(Map<String, dynamic> notice) async {
    final edited = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NoticeFormDialog(
        title: 'Editar aviso',
        notice: notice,
      ),
    );

    if (edited == true) {
      await _load();
    }
  }

  Future<void> _delete(Map<String, dynamic> notice) async {
    final id = (notice['id'] as num?)?.toInt();
    if (id == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar aviso'),
        content: const Text('¿Seguro que deseas eliminar este aviso?'),
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

    if (ok == true) {
      try {
        await NoticesService.deleteNotice(id);
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: items.isEmpty
          ? const Center(
              child: Text('No hay avisos por el momento.'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final n = items[i];
                  final id = (n['id'] as num?)?.toInt() ?? 0;
                  final title = (n['title'] ?? '').toString();
                  final body = (n['body'] ?? '').toString();
                  final createdAt = (n['created_at'] ?? '').toString();
                  final imageUrl = (n['image_url'] ?? '').toString();
                  final imageUrls = _parseImageUrls(n['image_urls']);
                  final pdfUrl = (n['pdf_url'] ?? '').toString();
                  final active = (n['active'] == 1 || n['active'] == true);
                  final areas = n['areas'];
                  final areasText = _formatAreas(areas);

                  final allImages = <String>{
                    if (imageUrl.isNotEmpty) imageUrl,
                    ...imageUrls.where((e) => e.trim().isNotEmpty),
                  }.toList();

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    color: theme.cardColor,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isEmpty ? 'Sin título' : title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.primary.withOpacity(0.18)
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  areasText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? theme.colorScheme.primary
                                        : Colors.blueGrey,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? (isDark
                                          ? Colors.green.withOpacity(0.16)
                                          : Colors.green.shade50)
                                      : (isDark
                                          ? theme.colorScheme.surfaceContainerHighest
                                          : Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  active ? 'Visible' : 'Oculto',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? (isDark
                                            ? Colors.green.shade300
                                            : Colors.green)
                                        : (isDark
                                            ? theme.textTheme.bodyMedium?.color
                                            : Colors.grey[700]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                          if (allImages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            NoticeImageGallery(
                              imageUrls: allImages,
                              height: 250,
                            ),
                          ],
                          if (pdfUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.red.withOpacity(0.10)
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.red.withOpacity(0.25)
                                      : Colors.red.shade100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    color: isDark
                                        ? Colors.red.shade300
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'PDF adjunto',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _openPdfPreview(pdfUrl),
                                    child: const Text('Ver'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (createdAt.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Fecha: $createdAt',
                              style: TextStyle(
                                color: isDark
                                    ? theme.textTheme.bodySmall?.color?.withOpacity(0.75)
                                    : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                '#$id',
                                style: TextStyle(
                                  color: isDark
                                      ? theme.textTheme.bodySmall?.color?.withOpacity(0.75)
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (isAdminOrRH) ...[
                                TextButton.icon(
                                  onPressed: () => _edit(n),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _delete(n),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Eliminar',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: isAdminOrRH
          ? FloatingActionButton.extended(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          : null,
    );
  }
}

class NoticeImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double height;

  const NoticeImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 240,
  });

  void _openGallery(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NoticeGalleryViewer(
          imageUrls: images,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final images = imageUrls.where((e) => e.trim().isNotEmpty).toList();
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return _GalleryImageTile(
        imageUrl: images[0],
        height: height,
        width: double.infinity,
        radius: 14,
        onTap: () => _openGallery(context, images, 0),
      );
    }

    if (images.length == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: _GalleryImageTile(
                imageUrl: images[0],
                height: height,
                onTap: () => _openGallery(context, images, 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GalleryImageTile(
                imageUrl: images[1],
                height: height,
                onTap: () => _openGallery(context, images, 1),
              ),
            ),
          ],
        ),
      );
    }

    if (images.length == 3) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _GalleryImageTile(
                imageUrl: images[0],
                height: height,
                onTap: () => _openGallery(context, images, 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _GalleryImageTile(
                      imageUrl: images[1],
                      height: (height - 8) / 2,
                      onTap: () => _openGallery(context, images, 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _GalleryImageTile(
                      imageUrl: images[2],
                      height: (height - 8) / 2,
                      onTap: () => _openGallery(context, images, 2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _GalleryImageTile(
              imageUrl: images[0],
              height: height,
              onTap: () => _openGallery(context, images, 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _GalleryImageTile(
                    imageUrl: images[1],
                    height: (height - 8) / 2,
                    onTap: () => _openGallery(context, images, 1),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _GalleryImageTile(
                          imageUrl: images[2],
                          height: (height - 8) / 2,
                          onTap: () => _openGallery(context, images, 2),
                        ),
                      ),
                      if (images.length > 3)
                        Positioned.fill(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openGallery(context, images, 2),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '+${images.length - 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
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
    );
  }
}

class _GalleryImageTile extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double? width;
  final double radius;
  final VoidCallback onTap;

  const _GalleryImageTile({
    required this.imageUrl,
    required this.height,
    required this.onTap,
    this.width,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullUrl = absoluteUrl(imageUrl);

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: width,
          height: height,
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.grey.shade200,
          child: Image.network(
            fullUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surfaceContainerHighest
                  : Colors.grey.shade200,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 42,
                  color: theme.brightness == Brightness.dark
                      ? theme.iconTheme.color?.withOpacity(0.75)
                      : Colors.grey,
                ),
              ),
            ),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NoticeGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _NoticeGalleryViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_NoticeGalleryViewer> createState() => _NoticeGalleryViewerState();
}

class _NoticeGalleryViewerState extends State<_NoticeGalleryViewer> {
  late final PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _goToPrevious() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (currentIndex < widget.imageUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              final fullUrl = absoluteUrl(images[i]);

              return Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 60,
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    },
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
                    onPressed: _goToPrevious,
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
                    onPressed: _goToNext,
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

class NoticeFormDialog extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? notice;

  const NoticeFormDialog({
    super.key,
    required this.title,
    this.notice,
  });

  @override
  State<NoticeFormDialog> createState() => _NoticeFormDialogState();
}

class _NoticeFormDialogState extends State<NoticeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleCtrl;
  late final TextEditingController bodyCtrl;
  final TextEditingController areaSearchCtrl = TextEditingController();

  bool saving = false;
  bool active = true;

  List<Map<String, dynamic>> availableAreas = [];
  List<int> selectedAreaIds = [];
  String areaSearch = '';

  File? mainImage;
  List<File> extraImages = [];
  File? pdfFile;

  Uint8List? mainImageBytes;
  String? mainImageName;

  List<Map<String, dynamic>> extraImageWebFiles = [];

  Uint8List? pdfBytes;
  String? pdfName;

  bool removeMainImage = false;
  bool removePdf = false;
  List<String> removeExtraImages = [];

  @override
  void initState() {
    super.initState();

    titleCtrl = TextEditingController(
      text: (widget.notice?['title'] ?? '').toString(),
    );
    bodyCtrl = TextEditingController(
      text: (widget.notice?['body'] ?? '').toString(),
    );

    final a = widget.notice?['active'];
    active = a == null ? true : (a == 1 || a == true);

    _loadAreas();
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

  List<Map<String, dynamic>> get filteredAreas {
    if (areaSearch.trim().isEmpty) return availableAreas;

    final q = areaSearch.toLowerCase().trim();
    return availableAreas.where((area) {
      final name = (area['name'] ?? '').toString().toLowerCase().trim();
      return name.contains(q);
    }).toList();
  }

  String get _currentMainImage {
    return (widget.notice?['image_url'] ?? '').toString();
  }

  String get _currentPdf {
    return (widget.notice?['pdf_url'] ?? '').toString();
  }

  List<String> get _currentExtraImages {
    return _parseImageUrls(widget.notice?['image_urls']);
  }

  Future<void> _loadAreas() async {
    try {
      final rows = await NoticesService.fetchAreas();
      if (!mounted) return;

      setState(() {
        availableAreas = rows;

        final areas = (widget.notice?['areas'] as List?) ?? [];
        selectedAreaIds = areas
            .map((e) => (e['id'] as num?)?.toInt())
            .whereType<int>()
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar áreas: $e')),
      );
    }
  }

  void _selectAllAreas() {
    setState(() {
      selectedAreaIds = availableAreas
          .map((e) => (e['id'] as num?)?.toInt())
          .whereType<int>()
          .toList();
    });
  }

  void _clearAreaSelection() {
    setState(() {
      selectedAreaIds.clear();
    });
  }

  void _selectFilteredAreas() {
    setState(() {
      final ids = filteredAreas
          .map((e) => (e['id'] as num?)?.toInt())
          .whereType<int>()
          .toList();

      final merged = <int>{...selectedAreaIds, ...ids};
      selectedAreaIds = merged.toList();
    });
  }

  Future<void> _pickMainImage() async {
    if (kIsWeb) {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;

      final file = res.files.first;
      if (file.bytes == null) return;

      setState(() {
        mainImageBytes = file.bytes!;
        mainImageName = file.name;
        removeMainImage = false;
      });
      return;
    }

    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    setState(() {
      mainImage = File(x.path);
      removeMainImage = false;
    });
  }

  Future<void> _pickExtraImages() async {
    if (kIsWeb) {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;

      setState(() {
        extraImageWebFiles.addAll(
          res.files.where((f) => f.bytes != null).map((f) {
            return {
              'bytes': f.bytes!,
              'name': f.name,
            };
          }),
        );
      });
      return;
    }

    final picker = ImagePicker();
    final xs = await picker.pickMultiImage(imageQuality: 85);
    if (xs.isEmpty) return;

    setState(() {
      extraImages.addAll(xs.map((x) => File(x.path)));
    });
  }

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: kIsWeb,
    );
    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;

    if (kIsWeb) {
      if (file.bytes == null) return;
      setState(() {
        pdfBytes = file.bytes!;
        pdfName = file.name;
        removePdf = false;
      });
      return;
    }

    if (file.path == null) return;
    setState(() {
      pdfFile = File(file.path!);
      removePdf = false;
    });
  }

  void _toggleRemoveExtraImage(String url) {
    setState(() {
      if (removeExtraImages.contains(url)) {
        removeExtraImages.remove(url);
      } else {
        removeExtraImages.add(url);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      if (widget.notice == null) {
        if (kIsWeb) {
          await NoticesService.createNoticeAdvancedWeb(
            title: titleCtrl.text.trim(),
            body: bodyCtrl.text.trim(),
            areaIds: selectedAreaIds,
            mainImageBytes: mainImageBytes,
            mainImageName: mainImageName,
            images: extraImageWebFiles,
            pdfBytes: pdfBytes,
            pdfName: pdfName,
          );
        } else {
          await NoticesService.createNoticeAdvanced(
            title: titleCtrl.text.trim(),
            body: bodyCtrl.text.trim(),
            areaIds: selectedAreaIds,
            mainImage: mainImage,
            images: extraImages,
            pdf: pdfFile,
          );
        }
      } else {
        final id = (widget.notice?['id'] as num?)?.toInt();
        if (id == null) {
          throw Exception('No se pudo identificar el aviso');
        }

        await NoticesService.updateNoticeAdvanced(
          id: id,
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
          active: active,
          areaIds: selectedAreaIds,
          replaceMainImage: mainImage != null || mainImageBytes != null,
          removeMainImage: removeMainImage,
          replacePdf: pdfFile != null || pdfBytes != null,
          removePdf: removePdf,
          removeExtraImages: removeExtraImages,
          mainImage: mainImage,
          images: extraImages,
          pdf: pdfFile,
          mainImageBytes: mainImageBytes,
          mainImageName: mainImageName,
          imageWebFiles: extraImageWebFiles,
          pdfBytes: pdfBytes,
          pdfName: pdfName,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar aviso: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Widget _buildAreaSelector() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final areas = filteredAreas;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.5)
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? theme.colorScheme.surface : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: areaSearchCtrl,
            onChanged: (v) {
              setState(() {
                areaSearch = v;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar área...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: areaSearch.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        areaSearchCtrl.clear();
                        setState(() {
                          areaSearch = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _selectAllAreas,
                icon: const Icon(Icons.done_all),
                label: const Text('Seleccionar todas'),
              ),
              OutlinedButton.icon(
                onPressed: _selectFilteredAreas,
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Seleccionar búsqueda'),
              ),
              OutlinedButton.icon(
                onPressed: _clearAreaSelection,
                icon: const Icon(Icons.remove_done),
                label: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Seleccionadas: ${selectedAreaIds.length}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? theme.textTheme.bodyMedium?.color?.withOpacity(0.8)
                  : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),
          if (availableAreas.isEmpty)
            const Text('No hay áreas disponibles')
          else if (areas.isEmpty)
            const Text('No se encontraron áreas')
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: areas.map((area) {
                    final id = (area['id'] as num?)?.toInt();
                    final name = (area['name'] ?? '').toString();

                    if (id == null || name.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final selected = selectedAreaIds.contains(id);

                    return FilterChip(
                      label: Text(name),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            if (!selectedAreaIds.contains(id)) {
                              selectedAreaIds.add(id);
                            }
                          } else {
                            selectedAreaIds.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExistingExtraImages() {
    final currentImages = _currentExtraImages;
    if (currentImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imágenes extra actuales',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: currentImages.map((url) {
            final marked = removeExtraImages.contains(url);

            return Stack(
              children: [
                Opacity(
                  opacity: marked ? 0.35 : 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      absoluteUrl(url),
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 92,
                        height: 92,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => _toggleRemoveExtraImage(url),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: marked ? Colors.green : Colors.red,
                      child: Icon(
                        marked ? Icons.undo : Icons.delete,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditingFilesSection() {
    final currentMainImage = _currentMainImage;
    final currentPdf = _currentPdf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: active,
          contentPadding: EdgeInsets.zero,
          title: const Text('Aviso visible'),
          onChanged: (v) {
            setState(() {
              active = v;
            });
          },
        ),
        const SizedBox(height: 4),
        if (currentMainImage.isNotEmpty) ...[
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Imagen principal actual',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              absoluteUrl(currentMainImage),
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: removeMainImage,
            title: const Text('Eliminar imagen principal actual'),
            onChanged: (v) {
              setState(() {
                removeMainImage = v ?? false;
              });
            },
          ),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickMainImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  currentMainImage.isEmpty ? 'Agregar imagen principal' : 'Reemplazar imagen principal',
                ),
              ),
            ),
          ],
        ),
        if (mainImage != null || mainImageBytes != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              mainImageName ??
                  mainImage?.path.split('/').last ??
                  'Nueva imagen principal seleccionada',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _buildExistingExtraImages(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickExtraImages,
                icon: const Icon(Icons.collections_outlined),
                label: const Text('Agregar más imágenes'),
              ),
            ),
          ],
        ),
        if (extraImages.isNotEmpty || extraImageWebFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${extraImages.length + extraImageWebFiles.length} imágenes nuevas seleccionadas',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (currentPdf.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'PDF actual',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final fullUrl = absoluteUrl(currentPdf);
                    if (fullUrl.isEmpty) return;

                    if (kIsWeb) {
                      await launchUrl(
                        Uri.parse(fullUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    } else if (mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: const Text('Vista previa PDF')),
                            body: SfPdfViewer.network(fullUrl),
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Ver'),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: removePdf,
            title: const Text('Eliminar PDF actual'),
            onChanged: (v) {
              setState(() {
                removePdf = v ?? false;
              });
            },
          ),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(currentPdf.isEmpty ? 'Agregar PDF' : 'Reemplazar PDF'),
              ),
            ),
          ],
        ),
        if (pdfFile != null || pdfBytes != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              pdfName ?? pdfFile?.path.split('/').last ?? 'Nuevo PDF seleccionado',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateFilesSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickMainImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Imagen principal'),
              ),
            ),
          ],
        ),
        if (mainImage != null || mainImageBytes != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              mainImageName ?? mainImage?.path.split('/').last ?? 'Imagen principal seleccionada',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickExtraImages,
                icon: const Icon(Icons.collections_outlined),
                label: const Text('Más imágenes'),
              ),
            ),
          ],
        ),
        if (extraImages.isNotEmpty || extraImageWebFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${extraImages.length + extraImageWebFiles.length} imágenes extra seleccionadas',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Adjuntar PDF'),
              ),
            ),
          ],
        ),
        if (pdfFile != null || pdfBytes != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              pdfName ?? pdfFile?.path.split('/').last ?? 'PDF seleccionado',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    areaSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.notice != null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Escribe un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Contenido',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Escribe el contenido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Áreas',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? theme.textTheme.bodyMedium?.color?.withOpacity(0.8)
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAreaSelector(),
                if (editing) ...[
                  const SizedBox(height: 12),
                  _buildEditingFilesSection(),
                ] else ...[
                  _buildCreateFilesSection(),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(editing ? 'Guardar cambios' : 'Crear aviso'),
        ),
      ],
    );
  }
}