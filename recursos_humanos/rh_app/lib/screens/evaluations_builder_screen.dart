import 'package:flutter/material.dart';

import '../services/notices_service.dart';

class EvaluationsBuilderScreen extends StatefulWidget {
  final int? evaluationId;
  final Map<String, dynamic>? initialData;

  const EvaluationsBuilderScreen({
    super.key,
    this.evaluationId,
    this.initialData,
  });

  bool get isEditing => evaluationId != null;

  @override
  State<EvaluationsBuilderScreen> createState() =>
      _EvaluationsBuilderScreenState();
}

class _EvaluationsBuilderScreenState extends State<EvaluationsBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _type = 'evaluacion';

  bool _loading = false;
  bool _loadingPositions = false;

  bool _allAreas = false;
  bool _allPositions = false;

  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _positions = [];

  int? _selectedAreaFilter;

  final Set<int> _selectedAreas = {};
  final Set<int> _selectedPositions = {};

  final List<_SectionDraft> _sections = [
    _SectionDraft(title: 'Sección 1'),
  ];

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      _fillInitialData(widget.initialData!);
    }

    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    try {
      final areas = await NoticesService.fetchAreas(force: true);

      if (!mounted) return;

      setState(() {
        _areas = areas;
      });

      if (_selectedAreaFilter != null && !_allAreas) {
        await _loadPositionsByArea(
          _selectedAreaFilter!,
          clearSelectedPositions: false,
        );
      }
    } catch (e) {
      _showSnack('Error cargando áreas: $e');
    }
  }

  Future<void> _loadPositionsByArea(
    int areaId, {
    bool clearSelectedPositions = true,
  }) async {
    setState(() {
      _loadingPositions = true;
      _positions = [];
      if (clearSelectedPositions) {
        _selectedPositions.clear();
      }
    });

    try {
      final positions = await NoticesService.fetchPositions(
        areaId: areaId,
        force: true,
      );

      if (!mounted) return;

      setState(() {
        _positions = positions;
        _loadingPositions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingPositions = false);
      _showSnack('Error cargando puestos: $e');
    }
  }

  void _fillInitialData(Map<String, dynamic> data) {
    _nameCtrl.text = '${data['name'] ?? data['title'] ?? ''}';
    _descriptionCtrl.text = '${data['description'] ?? ''}';
    _type = '${data['type'] ?? 'evaluacion'}';

    _allAreas = _isTrue(data['all_areas']);
    _allPositions = _isTrue(data['all_positions']);

    final rawAreaIds = data['area_ids'] ?? data['areas'] ?? [];
    final rawPositionIds = data['position_ids'] ?? data['positions'] ?? [];

    final areaIds = _extractIds(rawAreaIds);
    final positionIds = _extractIds(rawPositionIds);

    _selectedAreas
      ..clear()
      ..addAll(areaIds);

    _selectedPositions
      ..clear()
      ..addAll(positionIds);

    if (_selectedAreas.isNotEmpty && !_allAreas) {
      _selectedAreaFilter = _selectedAreas.first;
    }

    for (final section in _sections) {
      section.dispose();
    }
    _sections.clear();

    final sections = _asMapList(data['sections']);

    for (final s in sections) {
      final section = _SectionDraft(
        title: '${s['title'] ?? ''}',
      );

      section.descriptionCtrl.text = '${s['description'] ?? ''}';

      for (final q in section.questions) {
        q.dispose();
      }
      section.questions.clear();

      final questions = _asMapList(s['questions']);

      for (final q in questions) {
        final question = _QuestionDraft();

        question.questionCtrl.text = '${q['question_text'] ?? q['text'] ?? ''}';
        question.imageUrlCtrl.text =
            '${q['image_url'] == null ? '' : q['image_url']}';
        question.pointsCtrl.text = '${q['points'] ?? 0}';
        question.type = '${q['question_type'] ?? 'single'}';
        question.required = _isTrue(q['is_required']);

        for (final option in question.options) {
          option.dispose();
        }
        question.options.clear();

        final options = _asMapList(q['options']);

        for (final opt in options) {
          question.options.add(
            _OptionDraft(
              text: '${opt['option_text'] ?? opt['text'] ?? ''}',
              value: '${opt['value'] ?? 0}',
            ),
          );
        }

        if (question.type == 'yes_no' && question.options.isEmpty) {
          question.options
            ..add(_OptionDraft(text: 'Sí', value: '1'))
            ..add(_OptionDraft(text: 'No', value: '0'));
        }

        if (question.type != 'text' && question.options.isEmpty) {
          question.options
            ..add(_OptionDraft())
            ..add(_OptionDraft());
        }

        section.questions.add(question);
      }

      if (section.questions.isEmpty) {
        section.questions.add(_QuestionDraft());
      }

      _sections.add(section);
    }

    if (_sections.isEmpty) {
      _sections.add(_SectionDraft(title: 'Sección 1'));
    }
  }

  bool _isTrue(dynamic value) {
    return value == true || value == 1 || value == '1';
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  List<int> _extractIds(dynamic value) {
    if (value is List) {
      return value.map((e) {
        if (e is Map) {
          return _asInt(e['id'] ?? e['area_id'] ?? e['position_id']);
        }
        return _asInt(e);
      }).where((e) => e > 0).toList();
    }

    return <int>[];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();

    for (final section in _sections) {
      section.dispose();
    }

    super.dispose();
  }

  Future<void> _saveEvaluation() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_allAreas && _selectedAreas.isEmpty) {
      _showSnack('Selecciona un área o marca todas las áreas.');
      return;
    }

    if (!_allPositions && _selectedPositions.isEmpty) {
      _showSnack('Selecciona al menos un puesto o marca todos los puestos.');
      return;
    }

    for (final section in _sections) {
      if (section.questions.isEmpty) {
        _showSnack('Cada sección debe tener al menos una pregunta.');
        return;
      }
    }

    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'type': _type,
      'all_areas': _allAreas ? 1 : 0,
      'all_positions': _allPositions ? 1 : 0,
      'area_ids': _allAreas ? [] : _selectedAreas.toList(),
      'position_ids': _allPositions ? [] : _selectedPositions.toList(),
      'sections': _sections.asMap().entries.map((entry) {
        final sectionIndex = entry.key;
        final section = entry.value;

        return {
          'title': section.titleCtrl.text.trim(),
          'description': section.descriptionCtrl.text.trim(),
          'order_index': sectionIndex + 1,
          'questions': section.questions.asMap().entries.map((qEntry) {
            final questionIndex = qEntry.key;
            final q = qEntry.value;

            return {
              'question_text': q.questionCtrl.text.trim(),
              'question_type': q.type,
              'is_required': q.required,
              'order_index': questionIndex + 1,
              'image_url': q.imageUrlCtrl.text.trim().isEmpty
                  ? null
                  : q.imageUrlCtrl.text.trim(),
              'points': int.tryParse(q.pointsCtrl.text.trim()) ?? 0,
              'options': q.type == 'text'
                  ? []
                  : q.options.map((option) {
                      return {
                        'option_text': option.textCtrl.text.trim(),
                        'value': int.tryParse(option.valueCtrl.text.trim()) ?? 0,
                      };
                    }).toList(),
            };
          }).toList(),
        };
      }).toList(),
    };

    print('PAYLOAD EVALUACION => $payload');
    print('AREAS SELECCIONADAS => $_selectedAreas');
    print('PUESTOS SELECCIONADOS => $_selectedPositions');

    setState(() => _loading = true);

    try {
      if (widget.isEditing) {
        await NoticesService.updateEvaluation(widget.evaluationId!, payload);
      } else {
        await NoticesService.createEvaluation(payload);
      }

      if (!mounted) return;

      _showSnack(
        widget.isEditing
            ? 'Evaluación actualizada correctamente.'
            : 'Evaluación creada correctamente.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack('Error al guardar evaluación: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _addSection() {
    setState(() {
      _sections.add(
        _SectionDraft(title: 'Sección ${_sections.length + 1}'),
      );
    });
  }

  void _removeSection(int index) {
    if (_sections.length == 1) {
      _showSnack('Debe existir al menos una sección.');
      return;
    }

    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
    });
  }

  void _addQuestion(_SectionDraft section) {
    setState(() {
      section.questions.add(_QuestionDraft());
    });
  }

  void _removeQuestion(_SectionDraft section, int index) {
    if (section.questions.length == 1) {
      _showSnack('Debe existir al menos una pregunta.');
      return;
    }

    setState(() {
      section.questions[index].dispose();
      section.questions.removeAt(index);
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _bgColor =>
      _isDark ? const Color(0xFF121212) : const Color(0xFFF5F6FA);

  Color get _cardColor => _isDark ? const Color(0xFF1E1E1E) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar evaluación' : 'Crear evaluación'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _saveEvaluation,
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _mainInfoCard(),
                  const SizedBox(height: 16),
                  _targetsCard(),
                  const SizedBox(height: 16),
                  ..._sections.asMap().entries.map(
                        (entry) => _sectionCard(entry.key, entry.value),
                      ),
                  OutlinedButton.icon(
                    onPressed: _addSection,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar sección'),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _saveEvaluation,
        icon: const Icon(Icons.save),
        label: Text(widget.isEditing ? 'Actualizar' : 'Guardar'),
      ),
    );
  }

  Widget _mainInfoCard() {
    return Card(
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del cuestionario',
                prefixIcon: Icon(Icons.assignment),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Instrucciones',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'evaluacion',
                  child: Text('Evaluación'),
                ),
                DropdownMenuItem(
                  value: 'encuesta',
                  child: Text('Encuesta'),
                ),
                DropdownMenuItem(
                  value: 'capacitacion',
                  child: Text('Capacitación'),
                ),
                DropdownMenuItem(
                  value: 'general',
                  child: Text('General'),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  _type = v ?? 'evaluacion';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetsCard() {
    return Card(
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quiénes podrán ver esta evaluación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _allAreas,
              title: const Text('Todas las áreas'),
              subtitle:
                  const Text('La evaluación será visible para cualquier área.'),
              onChanged: (v) {
                setState(() {
                  _allAreas = v;

                  if (v) {
                    _selectedAreas.clear();
                    _selectedAreaFilter = null;
                    _positions.clear();

                    if (!_allPositions) {
                      _selectedPositions.clear();
                    }
                  }
                });
              },
            ),
            SwitchListTile(
              value: _allPositions,
              title: const Text('Todos los puestos'),
              subtitle:
                  const Text('La evaluación será visible para cualquier puesto.'),
              onChanged: (v) {
                setState(() {
                  _allPositions = v;

                  if (v) {
                    _selectedPositions.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            if (!_allAreas)
              DropdownButtonFormField<int>(
                value: _selectedAreaFilter,
                decoration: const InputDecoration(
                  labelText: 'Área',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                items: _areas.map((area) {
                  final id = _asInt(area['id'] ?? area['area_id']);
                  final name =
                      '${area['name'] ?? area['area'] ?? area['nombre'] ?? 'Área'}';

                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text('$name  (ID: $id)'),
                  );
                }).toList(),
                validator: (v) {
                  if (_allAreas) return null;
                  return v == null ? 'Selecciona un área' : null;
                },
                onChanged: (value) async {
                  if (value == null) return;

                  setState(() {
                    _selectedAreaFilter = value;
                    _selectedAreas
                      ..clear()
                      ..add(value);
                  });

                  if (!_allPositions) {
                    await _loadPositionsByArea(value);
                  }
                },
              ),
            if (!_allPositions) ...[
              const SizedBox(height: 16),
              const Text(
                'Puestos disponibles',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (!_allAreas && _selectedAreaFilter == null)
                const Text('Primero selecciona un área.')
              else if (_loadingPositions)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(),
                )
              else if (_positions.isEmpty && !_allAreas)
                const Text('No hay puestos registrados para esta área.')
              else if (_allAreas)
                const Text(
                  'Seleccionaste todas las áreas. Para aplicar a todos los puestos, marca "Todos los puestos".',
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _positions.map((position) {
                    final id =
                        _asInt(position['id'] ?? position['position_id']);
                    final name =
                        '${position['name'] ?? position['position'] ?? position['nombre'] ?? 'Puesto'}';

                    final areaId = _asInt(position['area_id']);
                    final label = areaId > 0 ? '$name  (ID: $id / Área: $areaId)' : '$name  (ID: $id)';

                    return FilterChip(
                      label: Text(label),
                      selected: _selectedPositions.contains(id),
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? _selectedPositions.add(id)
                              : _selectedPositions.remove(id);
                        });
                      },
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(int index, _SectionDraft section) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          section.titleCtrl.text.trim().isEmpty
              ? 'Sección ${index + 1}'
              : section.titleCtrl.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _removeSection(index),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: section.titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Título de sección',
              prefixIcon: Icon(Icons.title),
            ),
            onChanged: (_) => setState(() {}),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: section.descriptionCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Instrucciones de sección',
              prefixIcon: Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 16),
          ...section.questions.asMap().entries.map(
                (entry) => _questionCard(section, entry.key, entry.value),
              ),
          OutlinedButton.icon(
            onPressed: () => _addQuestion(section),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Agregar pregunta'),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(
    _SectionDraft section,
    int qIndex,
    _QuestionDraft q,
  ) {
    final needsOptions =
        q.type == 'single' || q.type == 'multi' || q.type == 'yes_no';

    return Card(
      color: _isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFDFDFD),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pregunta ${qIndex + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeQuestion(section, qIndex),
                ),
              ],
            ),
            TextFormField(
              controller: q.questionCtrl,
              decoration: const InputDecoration(
                labelText: 'Texto de la pregunta',
                prefixIcon: Icon(Icons.help_outline),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: q.type,
              decoration: const InputDecoration(
                labelText: 'Tipo de respuesta',
                prefixIcon: Icon(Icons.checklist),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'single',
                  child: Text('Opción única'),
                ),
                DropdownMenuItem(
                  value: 'multi',
                  child: Text('Varias opciones'),
                ),
                DropdownMenuItem(
                  value: 'text',
                  child: Text('Texto abierto'),
                ),
                DropdownMenuItem(
                  value: 'yes_no',
                  child: Text('Sí / No'),
                ),
              ],
              onChanged: (v) {
                setState(() {
                  q.type = v ?? 'single';

                  if (q.type == 'yes_no') {
                    for (final option in q.options) {
                      option.dispose();
                    }

                    q.options
                      ..clear()
                      ..add(_OptionDraft(text: 'Sí', value: '1'))
                      ..add(_OptionDraft(text: 'No', value: '0'));
                  }

                  if (q.type == 'text') {
                    for (final option in q.options) {
                      option.dispose();
                    }

                    q.options.clear();
                  }

                  if ((q.type == 'single' || q.type == 'multi') &&
                      q.options.isEmpty) {
                    q.options
                      ..add(_OptionDraft())
                      ..add(_OptionDraft());
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: q.pointsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puntos',
                      prefixIcon: Icon(Icons.score),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile(
                    value: q.required,
                    title: const Text('Requerida'),
                    onChanged: (v) {
                      setState(() {
                        q.required = v;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: q.imageUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL de imagen opcional',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            if (needsOptions) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Opciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ...q.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;

                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: option.textCtrl,
                        decoration: InputDecoration(
                          labelText: 'Opción ${index + 1}',
                        ),
                        validator: needsOptions
                            ? (v) => v == null || v.trim().isEmpty
                                ? 'Requerido'
                                : null
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: option.valueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: q.type == 'yes_no' || q.options.length <= 1
                          ? null
                          : () {
                              setState(() {
                                option.dispose();
                                q.options.removeAt(index);
                              });
                            },
                    ),
                  ],
                );
              }),
              if (q.type != 'yes_no')
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        q.options.add(_OptionDraft());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar opción'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionDraft {
  final TextEditingController titleCtrl;
  final TextEditingController descriptionCtrl = TextEditingController();

  final List<_QuestionDraft> questions = [
    _QuestionDraft(),
  ];

  _SectionDraft({required String title})
      : titleCtrl = TextEditingController(text: title);

  void dispose() {
    titleCtrl.dispose();
    descriptionCtrl.dispose();

    for (final q in questions) {
      q.dispose();
    }
  }
}

class _QuestionDraft {
  final TextEditingController questionCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController pointsCtrl = TextEditingController(text: '0');

  String type = 'single';
  bool required = true;

  final List<_OptionDraft> options = [
    _OptionDraft(),
    _OptionDraft(),
  ];

  void dispose() {
    questionCtrl.dispose();
    imageUrlCtrl.dispose();
    pointsCtrl.dispose();

    for (final option in options) {
      option.dispose();
    }
  }
}

class _OptionDraft {
  final TextEditingController textCtrl;
  final TextEditingController valueCtrl;

  _OptionDraft({
    String text = '',
    String value = '0',
  })  : textCtrl = TextEditingController(text: text),
        valueCtrl = TextEditingController(text: value);

  void dispose() {
    textCtrl.dispose();
    valueCtrl.dispose();
  }
}
