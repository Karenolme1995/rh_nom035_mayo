import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/notices_service.dart';

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const NotificationsScreen({super.key, required this.userData});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Pantalla de avisos'));
  }
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool get isAdminOrRH {
    final role = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    return role == 1 || role == 2;
  }

  String? get plant => widget.userData['plant']?.toString();

  bool loading = true;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      items = await NoticesService.list(plant: plant);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => NoticeFormDialog(
        title: 'Nuevo aviso',
        plant: plant,
      ),
    );
    if (created == true) await _load();
  }

  Future<void> _edit(Map<String, dynamic> notice) async {
    final edited = await showDialog<bool>(
      context: context,
      builder: (_) => NoticeFormDialog(
        title: 'Editar aviso',
        plant: plant,
        notice: notice,
      ),
    );
    if (edited == true) await _load();
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (ok == true) {
      await NoticesService.remove(id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ role 3: vista tipo noticia (cards grandes, sin botones)
    if (!isAdminOrRH) {
      if (items.isEmpty) {
        return const Center(child: Text('No hay avisos por el momento.'));
      }
      final latest = items.first;
      return _EmployeeNoticeView(notice: latest);
    }

    // ✅ role 1/2: lista + CRUD
    return Scaffold(
      body: RefreshIndicator(
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
            final active = (n['active'] == 1 || n['active'] == true);
            final imageUrl = (n['image_url'] ?? '').toString();

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title.isEmpty ? '—' : title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: active ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            active ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              color: active ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),

                    if (imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          '${NoticesService.baseUrl}$imageUrl',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _edit(n),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _delete(n),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ),
                        const Spacer(),
                        Text('#$id', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo aviso'),
      ),
    );
  }
}

class _EmployeeNoticeView extends StatelessWidget {
  final Map<String, dynamic> notice;
  const _EmployeeNoticeView({required this.notice});

  @override
  Widget build(BuildContext context) {
    final title = (notice['title'] ?? '').toString();
    final body = (notice['body'] ?? '').toString();
    final imageUrl = (notice['image_url'] ?? '').toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        if (imageUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              '${NoticesService.baseUrl}$imageUrl',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(body, style: const TextStyle(fontSize: 15, height: 1.35)),
      ],
    );
  }
}

class NoticeFormDialog extends StatefulWidget {
  final String title;
  final String? plant;
  final Map<String, dynamic>? notice; // si viene, es editar

  const NoticeFormDialog({
    super.key,
    required this.title,
    this.plant,
    this.notice,
  });

  @override
  State<NoticeFormDialog> createState() => _NoticeFormDialogState();
}

class _NoticeFormDialogState extends State<NoticeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController titleCtrl;
  late final TextEditingController bodyCtrl;

  bool active = true;
  bool saving = false;

  File? selectedImage;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: (widget.notice?['title'] ?? '').toString());
    bodyCtrl = TextEditingController(text: (widget.notice?['body'] ?? '').toString());
    final a = widget.notice?['active'];
    active = (a == null) ? true : (a == 1 || a == true);
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (x == null) return;
    setState(() => selectedImage = File(x.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    try {
      final isEdit = widget.notice != null;
      if (!isEdit) {
        await NoticesService.create(
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
          active: active,
          plant: widget.plant,
          image: selectedImage,
        );
      } else {
        final id = (widget.notice!['id'] as num).toInt();
        await NoticesService.update(
          id: id,
          title: titleCtrl.text.trim(),
          body: bodyCtrl.text.trim(),
          active: active,
          plant: widget.plant,
        );
        // si eligió imagen nueva, se sube aparte
        if (selectedImage != null) {
          await NoticesService.updateImage(id: id, image: selectedImage!);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.notice != null;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SwitchListTile(
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                  title: const Text('Activo'),
                ),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: bodyCtrl,
                  decoration: const InputDecoration(labelText: 'Body'),
                  minLines: 4,
                  maxLines: 8,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(selectedImage == null ? 'Agregar imagen' : 'Cambiar imagen'),
                  ),
                ),

                if (selectedImage != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(selectedImage!, height: 160, fit: BoxFit.cover),
                  ),
                ],

                if (isEdit) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Al editar: los textos se actualizan con Guardar.\nSi seleccionas imagen, se sube al finalizar.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: saving ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Guardar' : 'Publicar'),
        ),
      ],
    );
  }
}