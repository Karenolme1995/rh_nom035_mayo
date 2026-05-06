// lib/screens/nom035_admin_question_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rh_app/services/notices_service.dart';

class Nom035AdminQuestionsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const Nom035AdminQuestionsScreen({super.key, required this.userData});

  @override
  State<Nom035AdminQuestionsScreen> createState() => _Nom035AdminQuestionsScreen();
}

class _Nom035AdminQuestionsScreen extends State<Nom035AdminQuestionsScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> sections = [];
  int? _sectionId;

  List<Map<String, dynamic>> questions = [];

  final _formKey = GlobalKey<FormState>();

  int? editId;
  final TextEditingController _text = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _guide = TextEditingController(); // ✅ aquí es donde pones 1,2,3,4,5
  final TextEditingController _orderNo = TextEditingController(text: '1');

  String _responseType = 'likert';
  final TextEditingController _optionsJson = TextEditingController(
    text: jsonEncode([
      {"id": 1, "option_text": "Nunca"},
      {"id": 2, "option_text": "Casi nunca"},
      {"id": 3, "option_text": "Algunas veces"},
      {"id": 4, "option_text": "Casi siempre"},
      {"id": 5, "option_text": "Siempre"},
    ]),
  );

  @override
  void initState() {
    super.initState();
    _guardRole();
    _load();
  }

  void _guardRole() {
    final roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;
    if (roleId != 1 && roleId != 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin permisos para administrar NOM-035')),
        );
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _category.dispose();
    _guide.dispose();
    _orderNo.dispose();
    _optionsJson.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final list = await NoticesService.adminGetQuestions();
      final sec = await NoticesService.adminGetSections();

      // Orden preguntas: guide -> order_no -> id
      list.sort((a, b) {
        final ga = (a['guide'] ?? '').toString().trim();
        final gb = (b['guide'] ?? '').toString().trim();
        final gna = int.tryParse(ga);
        final gnb = int.tryParse(gb);
        if (gna != null && gnb != null && gna != gnb) return gna.compareTo(gnb);
        if (ga != gb) return ga.compareTo(gb);

        final ao = (a['order_no'] is num) ? (a['order_no'] as num).toInt() : int.tryParse('${a['order_no']}') ?? 0;
        final bo = (b['order_no'] is num) ? (b['order_no'] as num).toInt() : int.tryParse('${b['order_no']}') ?? 0;
        if (ao != bo) return ao.compareTo(bo);

        final ai = (a['id'] as num?)?.toInt() ?? 0;
        final bi = (b['id'] as num?)?.toInt() ?? 0;
        return ai.compareTo(bi);
      });

      // Orden secciones por order_no, id
      sec.sort((a, b) {
        final ao = (a['order_no'] is num) ? (a['order_no'] as num).toInt() : int.tryParse('${a['order_no']}') ?? 0;
        final bo = (b['order_no'] is num) ? (b['order_no'] as num).toInt() : int.tryParse('${b['order_no']}') ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        final ai = (a['id'] as num?)?.toInt() ?? 0;
        final bi = (b['id'] as num?)?.toInt() ?? 0;
        return ai.compareTo(bi);
      });

      if (!mounted) return;
      setState(() {
        questions = list;
        sections = sec;
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

  void _resetEditor() {
    editId = null;
    _sectionId = null;
    _text.text = '';
    _category.text = '';
    _guide.text = '';
    _orderNo.text = '1';
    _responseType = 'likert';
    _optionsJson.text = jsonEncode([
      {"id": 1, "option_text": "Nunca"},
      {"id": 2, "option_text": "Casi nunca"},
      {"id": 3, "option_text": "Algunas veces"},
      {"id": 4, "option_text": "Casi siempre"},
      {"id": 5, "option_text": "Siempre"},
    ]);
    setState(() {});
  }

  void _fillEditorFromRow(Map<String, dynamic> q) {
    editId = (q['id'] as num?)?.toInt();
    _text.text = (q['question_text'] ?? '').toString();
    _category.text = (q['category'] ?? '').toString();
    _guide.text = (q['guide'] ?? '').toString();
    _orderNo.text = (q['order_no'] ?? '1').toString();
    _sectionId = (q['section_id'] as num?)?.toInt();

    final rt = (q['response_type'] ?? 'likert').toString();
    _responseType = rt.isEmpty ? 'likert' : rt;

    final rawOptions = q['options_json'];
    if (rawOptions == null || rawOptions.toString().trim().isEmpty) {
      _optionsJson.text = '[]';
    } else if (rawOptions is String) {
      _optionsJson.text = rawOptions;
    } else {
      _optionsJson.text = jsonEncode(rawOptions);
    }

    setState(() {});
  }

  dynamic _parseOptionsJsonOrThrow() {
    final s = _optionsJson.text.trim();
    if (_responseType != 'multiple' && _responseType != 'likert' && _responseType != 'yes_no') return [];
    if (s.isEmpty) return [];

    try {
      final decoded = jsonDecode(s);
      if (decoded is List) return decoded;
      throw const FormatException('options_json debe ser un arreglo JSON (lista).');
    } catch (e) {
      throw Exception('options_json inválido: $e');
    }
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    try {
      final orderNo = int.tryParse(_orderNo.text.trim()) ?? 1;
      final options = _parseOptionsJsonOrThrow();

      final payload = <String, dynamic>{
        if (editId != null) 'id': editId,
        'question_text': _text.text.trim(),
        'category': _category.text.trim().isEmpty ? null : _category.text.trim(),
        'guide': _guide.text.trim().isEmpty ? null : _guide.text.trim(), // ✅ guía 1..5
        'section_id': _sectionId,
        'order_no': orderNo,
        'response_type': _responseType,
        'options_json': options,
        'is_active': 1,
      };

      await NoticesService.adminUpsertQuestion(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(editId == null ? 'Pregunta creada ✅' : 'Pregunta actualizada ✅')),
      );

      _resetEditor();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  // ✅ LISTA: agrupada por GUÍA (guide) y numerada 1..N por guía
  Widget _listCard() {
    if (questions.isEmpty) {
      return const Center(child: Text('No hay preguntas registradas.'));
    }

    final list = List<Map<String, dynamic>>.from(questions);

    // Agrupar por guide
    final Map<String, List<Map<String, dynamic>>> groups = {};
    for (final q in list) {
      final g = (q['guide'] ?? '').toString().trim();
      final key = g.isEmpty ? '— Sin guía —' : 'Guía $g';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(q);
    }

    // Orden de guías numérico si aplica
    int? _numFromKey(String k) {
      if (k == '— Sin guía —') return null;
      final parts = k.split(' ');
      if (parts.length < 2) return null;
      return int.tryParse(parts.last.trim());
    }

    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == '— Sin guía —') return 1;
        if (b == '— Sin guía —') return -1;
        final na = _numFromKey(a);
        final nb = _numFromKey(b);
        if (na != null && nb != null && na != nb) return na.compareTo(nb);
        return a.compareTo(b);
      });

    // Orden dentro de cada guía: order_no -> id
    for (final k in keys) {
      groups[k]!.sort((a, b) {
        final ao = (a['order_no'] is num) ? (a['order_no'] as num).toInt() : int.tryParse('${a['order_no']}') ?? 0;
        final bo = (b['order_no'] is num) ? (b['order_no'] as num).toInt() : int.tryParse('${b['order_no']}') ?? 0;
        if (ao != bo) return ao.compareTo(bo);
        final ai = (a['id'] as num?)?.toInt() ?? 0;
        final bi = (b['id'] as num?)?.toInt() ?? 0;
        return ai.compareTo(bi);
      });
    }

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, gi) {
        final key = keys[gi];
        final qs = groups[key]!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(qs.length, (i) {
                  final q = qs[i];
                  final id = (q['id'] as num?)?.toInt();
                  final text = (q['question_text'] ?? '').toString();
                  final rt = (q['response_type'] ?? '').toString();
                  final ord = (q['order_no'] ?? '').toString();

                  IconData icon;
                  if (rt == 'likert') {
                    icon = Icons.linear_scale;
                  } else if (rt == 'yes_no') {
                    icon = Icons.help_outline;
                  } else if (rt == 'multiple') {
                    icon = Icons.checklist;
                  } else {
                    icon = Icons.short_text;
                  }

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${i + 1}')), // ✅ 1..N por guía
                    title: Row(
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    subtitle: Text('ID: ${id ?? '-'}  •  Tipo: $rt  •  Orden: $ord'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _fillEditorFromRow(q),
                      tooltip: 'Editar',
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _editorCard() {
    final isEditing = editId != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar pregunta #$editId' : 'Nueva pregunta',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (isEditing)
                    TextButton.icon(
                      onPressed: _resetEditor,
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _text,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pregunta',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Escribe la pregunta';
                  if (s.length < 5) return 'Pregunta demasiado corta';
                  return null;
                },
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría (opcional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _guide,
                      decoration: const InputDecoration(
                        labelText: 'Guía (1..5)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      controller: _orderNo,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Orden',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<int?>(
                value: _sectionId,
                decoration: const InputDecoration(
                  labelText: 'Sección / Apartado (opcional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('— Sin sección —'),
                  ),
                  ...sections.map((s) {
                    final id = (s['id'] as num?)?.toInt();
                    final title = (s['title'] ?? '').toString();
                    final g = (s['guide'] ?? '').toString();
                    return DropdownMenuItem<int?>(
                      value: id,
                      child: Text('${g.isNotEmpty ? 'Guía $g • ' : ''}$title'),
                    );
                  }).toList(),
                ],
                onChanged: (v) => setState(() => _sectionId = v),
              ),

              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _responseType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de respuesta',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'likert', child: Text('Likert (Nunca→Siempre)')),
                  DropdownMenuItem(value: 'yes_no', child: Text('Sí / No')),
                  DropdownMenuItem(value: 'multiple', child: Text('Múltiple')),
                  DropdownMenuItem(value: 'open', child: Text('Abierta (texto)')),
                ],
                onChanged: (v) => setState(() => _responseType = v ?? 'likert'),
              ),

              const SizedBox(height: 10),

              if (_responseType == 'multiple' || _responseType == 'likert' || _responseType == 'yes_no') ...[
                TextFormField(
                  controller: _optionsJson,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Opciones (JSON array)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if ((_responseType == 'multiple' || _responseType == 'likert' || _responseType == 'yes_no') && s.isEmpty) {
                      return 'Escribe opciones JSON';
                    }
                    try {
                      final decoded = jsonDecode(s);
                      if (decoded is! List) return 'Debe ser un arreglo JSON';
                    } catch (_) {
                      return 'JSON inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
              ],

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(isEditing ? 'Guardar cambios' : 'Crear pregunta'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleId = (widget.userData['role_id'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin NOM-035 • Preguntas'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: roleId == 1 || roleId == 2
          ? (loading
              ? const Center(child: CircularProgressIndicator())
              : (error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Error:\n$error', textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _editorCard(),
                          const SizedBox(height: 12),
                          Expanded(child: _listCard()),
                        ],
                      ),
                    )))
          : const Center(child: Text('Sin permisos')),
    );
  }
}