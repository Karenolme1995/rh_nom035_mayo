// nom035_form_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/notices_service.dart';
import 'package:rh_app/screens/quiz_result_screen.dart';
import 'package:rh_app/screens/courses_screen.dart';

class Nom035FormScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final dynamic cycleId;
  final int submissionId;
  final Map<String, dynamic> formDetail;

  const Nom035FormScreen({
    super.key,
    required this.userData,
    required this.cycleId,
    required this.submissionId,
    required this.formDetail,
  });

  @override
  State<Nom035FormScreen> createState() => _Nom035FormScreenState();
}

class _Nom035FormScreenState extends State<Nom035FormScreen> {
  final Map<int, dynamic> _answers = {};
  final Map<int, bool> _required = {};

  Map<int, String>? _areasMap;
  Map<int, String>? _positionsMap;
  String _areaName = '—';
  String _positionName = '—';

  bool _saving = false;
  bool _savedPulse = false;
  Timer? _savedTimer;
  Timer? _debounce;

  late final List<_QItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _parseDetail(widget.formDetail);
    _seedExistingAnswers(widget.formDetail);
    _loadCatalogsAndResolve();
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  void _seedExistingAnswers(Map<String, dynamic> detail) {
    final ans = detail['answers'];
    if (ans is List) {
      for (final a in ans) {
        if (a is Map) {
          final qid = int.tryParse('${a['question_id']}');
          if (qid != null) _answers[qid] = a['answer_value'];
        }
      }
    }

    for (final it in _items) {
      if (it.answerValue != null) {
        _answers[it.questionId] = it.answerValue;
      }
      _required[it.questionId] = it.required;
    }

    setState(() {});
  }

  int get _totalRequired => _items.where((i) => i.required).length;

  int get _answeredRequired {
    int c = 0;
    for (final it in _items) {
      if (!it.required) continue;
      final v = _answers[it.questionId];
      if (_isAnswered(v)) c++;
    }
    return c;
  }

  int get _unansweredRequired =>
      (_totalRequired - _answeredRequired).clamp(0, 999999);

  double get _progress => _totalRequired == 0
      ? 0
      : (_answeredRequired / _totalRequired).clamp(0.0, 1.0);

  bool get _canSubmit => _unansweredRequired == 0 && !_saving;

  bool _isAnswered(dynamic v) {
    if (v == null) return false;
    if (v is String) return v.trim().isNotEmpty;
    if (v is List) return v.isNotEmpty;
    return true;
  }

  Future<void> _loadCatalogsAndResolve() async {
    try {
      final areasMap = await NoticesService().getAreasMap();
      final posMap = await NoticesService().getPositionsMap();

      if (!mounted) return;

      setState(() {
        _areasMap = areasMap;
        _positionsMap = posMap;
      });

      final areaRaw = widget.userData['area_id'] ?? widget.userData['area'];
      final posRaw =
          widget.userData['position_id'] ?? widget.userData['position'];

      String resolve(dynamic raw, Map<int, String>? map) {
        if (raw == null) return '—';
        final s = raw.toString().trim();
        if (s.isEmpty) return '—';
        final id = int.tryParse(s);
        if (id == null) return s;
        return (map != null && map.containsKey(id)) ? map[id]! : s;
      }

      if (!mounted) return;

      setState(() {
        _areaName = resolve(areaRaw, _areasMap);
        _positionName = resolve(posRaw, _positionsMap);
      });
    } catch (_) {}
  }

  Future<void> _saveAnswer(int questionId, dynamic value) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => _saving = true);

      try {
        await NoticesService.submitNom035Answer(
          submissionId: widget.submissionId,
          questionId: questionId,
          answerValue: value,
        );

        if (!mounted) return;
        setState(() {
          _saving = false;
          _savedPulse = true;
        });

        _savedTimer?.cancel();
        _savedTimer = Timer(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() => _savedPulse = false);
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar cuestionario'),
        content: const Text('Al enviar ya no podrás editar. ¿Deseas continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _saving = true);

    try {
      await NoticesService.submitFormByType(
        widget.submissionId,
        type: 'nom035',
      );

      if (!mounted) return;
      setState(() => _saving = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Cuestionario finalizado'),
          content: const Text('Gracias por responder la NOM-035'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (!mounted) return;

Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(
    builder: (_) => CoursesScreen(
      userData: widget.userData,
      initialTabIndex: 1,
    ),
  ),
  (route) => false,
);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOM-035'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_savedPulse)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: Icon(Icons.check_circle, size: 18)),
            )
        ],
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 6),
                Text('$percent% completado · $_unansweredRequired sin responder'),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Card(
                  elevation: 1,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: _items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _canSubmit ? _submit : null,
                                  icon: const Icon(Icons.send),
                                  label: const Text('Enviar'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final it = _items[index];
                      final current = _answers[it.questionId];

                      if (index < 5) {
                        debugPrint(
                          'ITEM[$index] sectionTitle=${it.sectionTitle} '
                          'isSectionStart=${it.isSectionStart} qid=${it.questionId}',
                        );
                      }

                      final isGuideVStart = (it.isSectionStart == true) &&
                          ((it.sectionTitle ?? '').contains('GUÍA DE REFERENCIA V'));

                      if (isGuideVStart) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _GuideVHeader(
                              questionnaireNo:
                                  ((_answers[188]?.toString().trim().isNotEmpty ??
                                          false))
                                      ? _answers[188].toString()
                                      : '1',
                              appliedDate:
                                  ((_answers[189]?.toString().trim().isNotEmpty ??
                                          false))
                                      ? _answers[189].toString()
                                      : '2026-10-23',
                              areaName: _areaName,
                              positionName: _positionName,
                            ),
                            _QuestionBlock(
                              number: index + 1,
                              item: it,
                              value: current,
                              onChanged: (v) async {
                                if (it.kind == 'policy') return;
                                setState(() => _answers[it.questionId] = v);
                                await _saveAnswer(it.questionId, v);
                              },
                            ),
                          ],
                        );
                      }

                      return _QuestionBlock(
                        number: index + 1,
                        item: it,
                        value: current,
                        onChanged: (v) async {
                          if (it.kind == 'policy') return;
                          setState(() => _answers[it.questionId] = v);
                          await _saveAnswer(it.questionId, v);
                        },
                      );
                    },
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

class _QuestionBlock extends StatelessWidget {
  final int number;
  final _QItem item;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _QuestionBlock({
    required this.number,
    required this.item,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (item.kind == 'policy') {
      final title = (item.sectionTitle ?? '').trim();
      final content = (item.policyContent ?? '').trim();

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 22),
            if (title.isNotEmpty)
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                content,
                textAlign: TextAlign.justify,
                style: const TextStyle(height: 1.25),
              ),
            ],
          ],
        ),
      );
    }

    final requiredMark = item.required ? ' *' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.sectionTitle != null && item.isSectionStart) ...[
            const Divider(height: 22),
            Text(
              item.sectionTitle!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if ((item.sectionInstructions ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.sectionInstructions!,
                style: const TextStyle(height: 1.2),
              ),
            ],
            const SizedBox(height: 10),
          ],
          Text(
            '$number. ${item.questionText}$requiredMark',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          if ((item.helpText ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(item.helpText!, style: TextStyle(color: Colors.grey.shade700)),
          ],
          const SizedBox(height: 8),
          if (item.responseType == 'text' || item.responseType == 'open')
            TextFormField(
              initialValue: (value ?? '').toString(),
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Escribe tu respuesta…',
              ),
              onChanged: (t) => onChanged(t),
            )
          else
            ..._buildOptions(context),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(BuildContext context) {
    final opts = item.options;

    final fallbackYesNo = const [
      {'value': 'si', 'label': 'Sí'},
      {'value': 'no', 'label': 'No'},
    ];

    final list =
        (opts.isNotEmpty) ? opts : (item.responseType == 'yes_no' ? fallbackYesNo : const []);

    return list.map((o) {
      final v = o['value'];
      final label = (o['label'] ?? o['text'] ?? v).toString();

      return RadioListTile<dynamic>(
        value: v,
        groupValue: value,
        onChanged: (x) => onChanged(x),
        title: Text(label),
        dense: true,
        contentPadding: EdgeInsets.zero,
      );
    }).toList();
  }
}

class _QItem {
  final int questionId;
  final String questionText;
  final String responseType;
  final bool required;
  final List<Map<String, dynamic>> options;

  final String kind;
  final String? policyContent;

  final String? sectionTitle;
  final String? sectionInstructions;
  final bool isSectionStart;

  final dynamic answerValue;
  final String? helpText;

  _QItem({
    required this.questionId,
    required this.questionText,
    required this.responseType,
    required this.required,
    required this.options,
    required this.sectionTitle,
    required this.sectionInstructions,
    required this.isSectionStart,
    required this.answerValue,
    required this.helpText,
    this.kind = 'question',
    this.policyContent,
  });
}

List<_QItem> _parseDetail(Map<String, dynamic> detail) {
  final items = <_QItem>[];

  List sections = [];
  if (detail['sections'] is List) {
    sections = detail['sections'] as List;
  } else if (detail['data'] is Map && (detail['data']['sections'] is List)) {
    sections = detail['data']['sections'] as List;
  }

  if (sections.isNotEmpty) {
    for (final sAny in sections) {
      if (sAny is! Map) continue;
      final s = Map<String, dynamic>.from(sAny);

      final secTitle = (s['title'] ?? s['name'] ?? '').toString().trim();
      final secIns = (s['instructions'] ?? s['description'] ?? '').toString();

      final groups = (s['groups'] is List) ? (s['groups'] as List) : <dynamic>[];

      if (groups.isNotEmpty) {
        for (final gAny in groups) {
          if (gAny is! Map) continue;
          final g = Map<String, dynamic>.from(gAny);

          final groupTitle = (g['title'] ?? '').toString().trim();
          final groupIns = (g['instructions'] ?? g['description'] ?? '').toString();

          final qs = (g['questions'] is List) ? (g['questions'] as List) : <dynamic>[];

          if (qs.isEmpty) {
            final rawContent = (g['content'] ??
                    g['policy'] ??
                    g['text'] ??
                    g['body'] ??
                    groupIns ??
                    '')
                .toString()
                .trim();

            if (rawContent.isNotEmpty) {
              items.add(_QItem(
                kind: 'policy',
                questionId: -items.length - 1,
                questionText: '',
                responseType: 'none',
                required: false,
                options: const [],
                sectionTitle: secTitle.isEmpty ? 'POLÍTICA' : secTitle,
                sectionInstructions: null,
                isSectionStart: true,
                answerValue: null,
                helpText: null,
                policyContent: rawContent,
              ));
            }
            continue;
          }

          bool firstInGroup = true;
          for (final qAny in qs) {
            if (qAny is! Map) continue;
            final q = Map<String, dynamic>.from(qAny);

            final qid = int.tryParse('${q['id'] ?? q['question_id']}');
            if (qid == null) continue;

            final text = (q['question_text'] ?? q['text'] ?? '').toString();

            final rtRaw =
                (q['question_type'] ?? q['response_type'] ?? q['type'] ?? 'single')
                    .toString();

            final rt = (rtRaw == 'single' || rtRaw == 'multi' || rtRaw == 'text')
                ? rtRaw
                : (rtRaw == 'open' ? 'text' : 'single');

            final req = (q['required'] == null)
                ? true
                : (q['required'] == true || q['required'] == 1);

            final help = (q['help_text'] ?? q['instruction_text'] ?? '').toString();
            final ans = q['answer_value'];

            final options = _parseOptions(q);

            final combinedTitle = [
              if (secTitle.isNotEmpty) secTitle,
              if (groupTitle.isNotEmpty) groupTitle,
            ].join(' · ');

            final combinedIns = [
              if (secIns.trim().isNotEmpty) secIns.trim(),
              if (groupIns.trim().isNotEmpty) groupIns.trim(),
            ].join('\n');

            items.add(_QItem(
              questionId: qid,
              questionText: text,
              responseType: rt,
              required: req,
              options: options,
              sectionTitle: combinedTitle.isEmpty ? null : combinedTitle,
              sectionInstructions:
                  combinedIns.trim().isEmpty ? null : combinedIns,
              isSectionStart: firstInGroup,
              answerValue: ans,
              helpText: help,
            ));

            firstInGroup = false;
          }
        }

        continue;
      }

      final qs = (s['questions'] is List)
          ? (s['questions'] as List)
          : (s['items'] is List)
              ? (s['items'] as List)
              : <dynamic>[];

      if (qs.isEmpty) {
        final rawContent = (s['content'] ??
                s['policy'] ??
                s['text'] ??
                s['body'] ??
                s['instructions'] ??
                s['description'] ??
                '')
            .toString()
            .trim();

        if (rawContent.isNotEmpty) {
          items.add(_QItem(
            kind: 'policy',
            questionId: -items.length - 1,
            questionText: '',
            responseType: 'none',
            required: false,
            options: const [],
            sectionTitle: secTitle.isEmpty ? 'POLÍTICA' : secTitle,
            sectionInstructions: null,
            isSectionStart: true,
            answerValue: null,
            helpText: null,
            policyContent: rawContent,
          ));
        }
        continue;
      }

      bool firstInSection = true;

      for (final qAny in qs) {
        if (qAny is! Map) continue;
        final q = Map<String, dynamic>.from(qAny);

        final qid = int.tryParse('${q['id'] ?? q['question_id']}');
        if (qid == null) continue;

        final text = (q['question_text'] ?? q['text'] ?? '').toString();
        final rtRaw =
            (q['question_type'] ?? q['response_type'] ?? q['type'] ?? 'single')
                .toString();

        final rt = (rtRaw == 'single' || rtRaw == 'multi' || rtRaw == 'text')
            ? rtRaw
            : (rtRaw == 'open' ? 'text' : 'single');

        final req = (q['required'] == null)
            ? true
            : (q['required'] == true || q['required'] == 1);

        final help = (q['help_text'] ?? q['instruction_text'] ?? '').toString();
        final ans = q['answer_value'];

        items.add(_QItem(
          questionId: qid,
          questionText: text,
          responseType: rt,
          required: req,
          options: _parseOptions(q),
          sectionTitle: secTitle.isEmpty ? null : secTitle,
          sectionInstructions: secIns.trim().isEmpty ? null : secIns,
          isSectionStart: firstInSection,
          answerValue: ans,
          helpText: help,
        ));

        firstInSection = false;
      }
    }

    return items;
  }

  final qs = (detail['questions'] is List) ? (detail['questions'] as List) : <dynamic>[];
  for (final qAny in qs) {
    if (qAny is! Map) continue;
    final q = Map<String, dynamic>.from(qAny);

    final qid = int.tryParse('${q['id'] ?? q['question_id']}');
    if (qid == null) continue;

    final text = (q['question_text'] ?? q['text'] ?? '').toString();
    final rtRaw =
        (q['question_type'] ?? q['response_type'] ?? q['type'] ?? 'single')
            .toString();

    final rt = (rtRaw == 'single' || rtRaw == 'multi' || rtRaw == 'text')
        ? rtRaw
        : (rtRaw == 'open' ? 'text' : 'single');

    final req = (q['required'] == null)
        ? true
        : (q['required'] == true || q['required'] == 1);

    final help = (q['help_text'] ?? q['instruction_text'] ?? '').toString();

    items.add(_QItem(
      questionId: qid,
      questionText: text,
      responseType: rt,
      required: req,
      options: _parseOptions(q),
      sectionTitle: null,
      sectionInstructions: null,
      isSectionStart: false,
      answerValue: q['answer_value'],
      helpText: help,
    ));
  }

  return items;
}

List<Map<String, dynamic>> _parseOptions(Map q) {
  final raw = q['options'] ?? q['options_json'] ?? q['choices'];
  if (raw == null) return <Map<String, dynamic>>[];

  try {
    dynamic decoded = raw;
    if (raw is String) decoded = jsonDecode(raw);

    if (decoded is List) {
      return decoded.map<Map<String, dynamic>>((e) {
        if (e is Map) {
          final v = e['value'] ?? e['id'] ?? e['key'] ?? e['code'] ?? e['text'];
          final lbl = e['label'] ?? e['text'] ?? e['name'] ?? v;
          return {'value': v, 'label': lbl};
        }
        return {'value': e, 'label': e.toString()};
      }).toList();
    }

    if (decoded is Map) {
      return decoded.entries
          .map<Map<String, dynamic>>(
            (e) => {'value': e.key, 'label': e.value},
          )
          .toList();
    }
  } catch (_) {}

  return <Map<String, dynamic>>[];
}