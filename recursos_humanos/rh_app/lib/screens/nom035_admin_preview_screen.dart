// lib/screens/nom035_admin_preview_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/notices_service.dart';

class Nom035AdminPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int? cycleId;

  const Nom035AdminPreviewScreen({
    super.key,
    required this.userData,
    this.cycleId,
  });

  @override
  State<Nom035AdminPreviewScreen> createState() => _Nom035AdminPreviewScreenState();
}

class _Nom035AdminPreviewScreenState extends State<Nom035AdminPreviewScreen> {
  bool loading = true;
  String? error;

  Map<String, dynamic>? detail;
  int? cycleIdPicked;

  List<Map<String, dynamic>> bankQuestions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? cycleId}) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final cycles = await NoticesService.adminGetCycles();
      if (cycles.isEmpty) throw Exception('No hay ciclos creados.');

      final fromWidget = widget.cycleId;
      final picked = cycleId ?? fromWidget ?? int.parse('${cycles.first['id']}');
      cycleIdPicked = picked;

      final data = await NoticesService.getFormDetailByType(picked, type: 'nom035');
      final bank = await NoticesService.adminGetQuestions();

      setState(() {
        detail = data;
        bankQuestions = bank;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = detail;

    return Scaffold(
  appBar: AppBar(
    title: const Text('Vista previa NOM-035'),
    actions: [
      IconButton(
        onPressed: () => _load(cycleId: cycleIdPicked),
        icon: const Icon(Icons.refresh),
        tooltip: 'Recargar',
      ),
    ],
  ),
  body: Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/favicon.png'),
        fit: BoxFit.contain,       
        alignment: Alignment.center,
        opacity: 0.06,             // efecto “marca de agua”
      ),
    ),
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
            ? Center(child: Text('Error:\n$error'))
            : detail == null
                ? const Center(child: Text('Sin datos'))
                : _documentPreview(detail!),
  ),
);
  }

  // ---------------------------
  // Helpers
  // ---------------------------
  Map<String, dynamic> _asMap(dynamic v) {
    if (v == null) return <String, dynamic>{};
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic v) {
    if (v == null) return <dynamic>[];
    if (v is List) return v;
    return <dynamic>[];
  }

  String _asString(dynamic v) => (v ?? '').toString();

  int _countQuestionsFromSections(List<dynamic> sectionsAny) {
    int total = 0;
    for (final secAny in sectionsAny) {
      final sec = _asMap(secAny);
      total += _asList(sec['questions']).length;

      final groups = _asList(sec['groups']);
      for (final gAny in groups) {
        final g = _asMap(gAny);
        total += _asList(g['questions']).length;
      }
    }
    return total;
  }

  // opciones (tolerante)
  String _readOptionText(dynamic op) {
    if (op == null) return '';
    if (op is String) return op;
    if (op is Map) {
      final m = Map<String, dynamic>.from(op);
      final a = _asString(m['option_text']);
      if (a.isNotEmpty) return a;
      final b = _asString(m['label']);
      if (b.isNotEmpty) return b;
      final c = _asString(m['text']);
      if (c.isNotEmpty) return c;
      final d = _asString(m['value']);
      if (d.isNotEmpty) return d;
      return m.toString();
    }
    return op.toString();
  }

  List<dynamic> _parseOptions(dynamic rawOpts) {
    if (rawOpts == null) return <dynamic>[];
    if (rawOpts is List) return rawOpts;
    if (rawOpts is Map) {
      return rawOpts.entries.map((e) => {'value': e.key, 'label': e.value}).toList();
    }
    if (rawOpts is String) {
      final s = rawOpts.trim();
      if (s.isEmpty) return <dynamic>[];
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return decoded.entries.map((e) => {'value': e.key, 'label': e.value}).toList();
        }
      } catch (_) {}
    }
    return <dynamic>[];
  }

  // ---------------------------
  // ✅ Detectar GUÍA (ROMANO)
  // ---------------------------
  String _romanFromAny(dynamic v) {
    final s = _asString(v).trim().toUpperCase();
    if (s.isEmpty) return '';
    // normaliza "GUIA II" -> "II" si viene así
    final m = RegExp(r'\b(I|II|III|IV|V|VI|VII|VIII|IX|X)\b').firstMatch(s);
    return m?.group(1) ?? s;
  }

  /// Prioridad:
  /// 1) node['guide'] (sec/group/question)
  /// 2) node['title'] (si contiene "Guía II", etc.)
  /// 3) fallback ''
  String _guideKeyFromNode(Map<String, dynamic> node) {
    final g = _romanFromAny(node['guide']);
    if (g.isNotEmpty) return g;

    final t = _asString(node['title']).toUpperCase();
    final m = RegExp(r'\bGU[IÍ]A\s+(I|II|III|IV|V|VI|VII|VIII|IX|X)\b').firstMatch(t);
    if (m != null) return _romanFromAny(m.group(1));

    return '';
  }

  // ---------------------------
  // ✅ Reglas por guía (TU REGLA)
  // ---------------------------
  // I => yes_no
  // II/III => likert
  // IV => doc/politicas
  // V => multiple/open (JSON + abiertos)
  String _forcedTypeByGuideKey(String guideKey) {
    switch (guideKey) {
      case 'I':
        return 'yes_no';
      case 'II':
      case 'III':
        return 'likert';
      case 'IV':
        return 'doc';
      case 'V':
        return 'mixed_v'; // multiple + open
      default:
        return '';
    }
  }

  // ---------------------------
  // Columnas fijas por tipo (para NO romper Table)
  // ---------------------------
  int _colsFor(String forcedType) {
    if (forcedType == 'likert') return 6;     // pregunta + 5
    if (forcedType == 'yes_no') return 3;     // pregunta + sí + no
    if (forcedType == 'multiple') return 2;   // pregunta + opciones
    if (forcedType == 'open') return 2;       // pregunta + línea
    if (forcedType == 'mixed_v') return 2;    // pregunta + opciones/línea
    if (forcedType == 'doc') return 0;
    return 2;
  }

  Map<int, TableColumnWidth> _colWidths(int cols) {
    if (cols == 6) {
      return const {
        0: FlexColumnWidth(7.0),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.2),
        5: FlexColumnWidth(1.2),
      };
    }
    if (cols == 3) {
      return const {
        0: FlexColumnWidth(7.0),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      };
    }
    return const {
      0: FlexColumnWidth(7.0),
      1: FlexColumnWidth(3.0),
    };
  }

  TableRow _headerRow(int cols, String forcedType) {
    if (cols == 6) {
      return TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: const [
          Padding(padding: EdgeInsets.all(8), child: Text('Pregunta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Nunca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Casi\nnunca', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Algunas\nveces', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Casi\nsiempre', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
          Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Siempre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)))),
        ],
      );
    }

    if (cols == 3) {
      return TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: const [
          Padding(padding: EdgeInsets.all(8), child: Text('Pregunta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Sí', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          Padding(padding: EdgeInsets.all(8), child: Center(child: Text('No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
        ],
      );
    }

    // 2 columnas (Guía V / multiple-open)
    final second = (forcedType == 'open') ? 'Respuesta' : 'Opciones';
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      children: [
        const Padding(padding: EdgeInsets.all(8), child: Text('Pregunta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        Padding(padding: const EdgeInsets.all(8), child: Center(child: Text(second, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
      ],
    );
  }

  // detectar tipo real del reactivo (desde BD)
  String _questionType(Map<String, dynamic> q) {
    final t = _asString(q['response_type']);
    if (t.isNotEmpty) return t; // yes_no | likert | multiple | open
    final fallback = _asString(q['question_type']);
    return fallback.isNotEmpty ? fallback : 'yes_no';
  }

  TableRow _rowFixed(Map<String, dynamic> q, {required int number, required int cols, required String forcedType}) {
    final text = _asString(q['question_text']);
    final rawOpts = q['options'] ?? q['options_json'];
    final options = _parseOptions(rawOpts);

    final qCell = Padding(
      padding: const EdgeInsets.all(8),
      child: Text('$number. $text', style: const TextStyle(fontSize: 12)),
    );

    if (cols == 6) {
      // Likert siempre 6 celdas
      return TableRow(
        children: [
          qCell,
          Padding(padding: const EdgeInsets.all(8), child: Center(child: _emptyBox())),
          Padding(padding: const EdgeInsets.all(8), child: Center(child: _emptyBox())),
          Padding(padding: const EdgeInsets.all(8), child: Center(child: _emptyBox())),
          Padding(padding: const EdgeInsets.all(8), child: Center(child: _emptyBox())),
          Padding(padding: const EdgeInsets.all(8), child: Center(child: _emptyBox())),
        ],
      );
    }

    if (cols == 3) {
      // Sí/No siempre 3 celdas
      return TableRow(
        children: [
          qCell,
          Padding(padding: const EdgeInsets.all(8), child: SizedBox(height: 46, child: Center(child: _emptyBox()))),
          Padding(padding: const EdgeInsets.all(8), child: SizedBox(height: 46, child: Center(child: _emptyBox()))),
        ],
      );
    }

    // 2 columnas: Guía V => mixed multiple/open
    final realType = _questionType(q); // multiple/open
    if (forcedType == 'mixed_v') {
      if (realType == 'open') {
        return TableRow(
          children: [
            qCell,
            Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                height: 22,
                decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
              ),
            ),
          ],
        );
      }

      // multiple
      final optCell = Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: options.isEmpty
              ? [const Text('-', style: TextStyle(fontSize: 12))]
              : options
                  .map((op) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('• ${_readOptionText(op)}', style: const TextStyle(fontSize: 11)),
                      ))
                  .toList(),
        ),
      );

      return TableRow(children: [qCell, optCell]);
    }

    // fallback 2 columnas (por si llega algo raro)
    final optCell = Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.isEmpty
            ? [const Text('-', style: TextStyle(fontSize: 12))]
            : options
                .map((op) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('• ${_readOptionText(op)}', style: const TextStyle(fontSize: 11)),
                    ))
                .toList(),
      ),
    );

    return TableRow(children: [qCell, optCell]);
  }

  // ---------------------------
  // UI
  // ---------------------------
  Widget _documentPreview(Map<String, dynamic> d) {
    final form = _asMap(d['form']);
    final sections = _asList(d['sections']);
    final title = _asString(form['title']).isNotEmpty
        ? _asString(form['title'])
        : (_asString(d['title']).isNotEmpty ? _asString(d['title']) : 'NOM-035');

    final totalFromCycle = _countQuestionsFromSections(sections);

    return Container(
      color: Colors.grey.shade300,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: ListView(
            children: [
              _docHeader(title),
              const SizedBox(height: 10),
              Text(
                'Secciones: ${sections.length}  •  Preguntas en este ciclo: $totalFromCycle  •  Banco total: ${bankQuestions.length}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 14),

              for (final secAny in sections) ...[
                Builder(builder: (_) {
                  final sec = _asMap(secAny);
                  final groups = _asList(sec['groups']);
                  if (groups.isNotEmpty) return _guideBlock(sec);
                  return _sectionBlock(sec);
                }),
              ],

              if (totalFromCycle == 0) ...[
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'PREGUNTAS EN BANCO (NO ASIGNADAS AL CICLO)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _bankQuestionsBlock(bankQuestions),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _docHeader(String cycleTitle) {
    return Column(
      children: const [
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Divider(thickness: 1.2)),
            SizedBox(width: 10),
            Text(
              'GUIA DE REFERENCIA  NOM 035-STPS ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 10),
            Expanded(child: Divider(thickness: 1.2)),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'CUESTIONARIO NOM-035',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _bankQuestionsBlock(List<Map<String, dynamic>> qs) {
    if (qs.isEmpty) return const Text('No hay preguntas en el banco.');

    return Table(
      border: TableBorder.all(width: 1, color: Colors.black87),
      columnWidths: _colWidths(2),
      children: [
        _headerRow(2, 'multiple'),
        for (int i = 0; i < qs.length; i++)
          _rowFixed(qs[i], number: i + 1, cols: 2, forcedType: 'multiple'),
      ],
    );
  }

  Widget _instructionBox(String text) {
    final t = text.trim();
    if (t.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 1),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade50,
      ),
      child: Text(
        t,
        textAlign: TextAlign.justify,
        style: const TextStyle(fontSize: 12, height: 1.35),
      ),
    );
  }

  // ✅ Sección con groups (bloques)
  Widget _guideBlock(Map<String, dynamic> sec) {
    final title = _asString(sec['title']).isEmpty ? 'GUÍA' : _asString(sec['title']);
    final instructions = _asString(sec['instructions']);
    final groups = _asList(sec['groups']);

    final guideKey = _guideKeyFromNode(sec); // I/II/III/IV/V
    final forced = _forcedTypeByGuideKey(guideKey);

    // ✅ Guía IV => documento/políticas
    if (forced == 'doc') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          if (instructions.trim().isNotEmpty) _instructionBox(instructions),
          for (final gAny in groups) ...[
            Builder(builder: (_) {
              final g = _asMap(gAny);
              final gt = _asString(g['title']);
              final gi = _asString(g['instructions']);
              final gd = _asString(g['description']);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  if (gt.trim().isNotEmpty) Text(gt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  if (gd.trim().isNotEmpty) Text(gd, style: const TextStyle(fontSize: 12)),
                  if (gi.trim().isNotEmpty) _instructionBox(gi),
                ],
              );
            }),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        if (instructions.trim().isNotEmpty) _instructionBox(instructions),
        const SizedBox(height: 12),
        for (final g in groups) _categoryBlock(_asMap(g), guideKeyFromParent: guideKey),
      ],
    );
  }

  // ✅ Bloque (category)
  Widget _categoryBlock(Map<String, dynamic> group, {required String guideKeyFromParent}) {
    final catTitle = _asString(group['title']).isEmpty ? 'Apartado' : _asString(group['title']);
    final qs = _asList(group['questions']);
    final instr = _asString(group['instructions']);

    // guía: padre (sec) > group > (si llega) question
    final gk = guideKeyFromParent.isNotEmpty ? guideKeyFromParent : _guideKeyFromNode(group);
    final forced = _forcedTypeByGuideKey(gk);

    if (forced == 'doc') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(catTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          if (instr.trim().isNotEmpty) _instructionBox(instr),
          const SizedBox(height: 12),
        ],
      );
    }

    final cols = _colsFor(forced);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(catTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        if (instr.trim().isNotEmpty) _instructionBox(instr),
        const SizedBox(height: 8),

        Table(
          border: TableBorder.all(width: 1, color: Colors.black87),
          columnWidths: _colWidths(cols),
          children: [
            _headerRow(cols, forced),
            for (int i = 0; i < qs.length; i++)
              _rowFixed(_asMap(qs[i]), number: i + 1, cols: cols, forcedType: forced),
          ],
        ),

        const SizedBox(height: 14),
      ],
    );
  }

  // ✅ Sección sin groups
  Widget _sectionBlock(Map<String, dynamic> sec) {
    final secTitle = _asString(sec['title']).isEmpty ? 'Sección' : _asString(sec['title']);
    final desc = _asString(sec['description']);
    final instr = _asString(sec['instructions']);
    final qs = _asList(sec['questions']);

    final guideKey = _guideKeyFromNode(sec);
    final forced = _forcedTypeByGuideKey(guideKey);

    if (forced == 'doc') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Text(secTitle.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          if (desc.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 12)),
          ],
          if (instr.trim().isNotEmpty) _instructionBox(instr),
          const SizedBox(height: 12),
        ],
      );
    }

    final cols = _colsFor(forced);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(secTitle.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(fontSize: 12)),
        ],
        if (instr.trim().isNotEmpty) _instructionBox(instr),
        const SizedBox(height: 10),

        Table(
          border: TableBorder.all(width: 1, color: Colors.black87),
          columnWidths: _colWidths(cols),
          children: [
            _headerRow(cols, forced),
            for (int i = 0; i < qs.length; i++)
              _rowFixed(_asMap(qs[i]), number: i + 1, cols: cols, forcedType: forced),
          ],
        ),
      ],
    );
  }

  Widget _emptyBox() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black87, width: 1),
      ),
    );
  }
}