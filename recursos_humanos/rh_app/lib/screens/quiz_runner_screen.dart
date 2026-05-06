//quiz_runner_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rh_app/services/notices_service.dart';
//import 'package:rh_app/screens/courses_screen.dart';
import 'package:rh_app/screens/app_shell.dart';

class QuizRunnerScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> formDetail;
  final int submissionId;
  final String? formType;

  const QuizRunnerScreen({
    super.key,
    required this.userData,
    required this.formDetail,
    required this.submissionId,
    this.formType,
  });

  @override
  State<QuizRunnerScreen> createState() => _QuizRunnerScreenState();
}

class _QuizRunnerScreenState extends State<QuizRunnerScreen> {
  late final Map<String, dynamic> form;
  late List<Map<String, dynamic>> sections;

  int page = 0;
  bool saving = false;
  String? saveError;
  int? _missingQuestionId;

  final Map<int, Map<String, dynamic>> draft = {};

  int? _targetQuestionIndexInGuide;
  final Map<int, GlobalKey> _questionKeys = {};

  final Map<int, Timer> _questionDebouncers = {};
  final Map<int, String> _lastSavedSnapshot = {};

  final Map<String, dynamic> _guideVProfile = {};
  bool _guideISkipDialogVisible = false;

  bool _guideIISkipQuestions41To43 = false;
  bool _guideIIFlowDialogVisible = false;
  bool? _guideIIClientAttentionAnswer;
  bool? _guideIIBossAnswer;
  bool _guideIIFlowApplied = false;
  bool _guideIIBossValidationShown = false;

  bool _guideIIISkipQuestions65To68 = false;
  bool _guideIIIFlowDialogVisible = false;
  bool? _guideIIIClientAttentionAnswer;
  bool? _guideIIIBossAnswer;
  bool _guideIIIFlowApplied = false;
  bool _guideIIIBossValidationShown = false;
  bool _guideIIIFinishedAndLocked = false;
  bool _showGuideIIIFinishedBanner = false;
  Timer? _guideIIIFinishedBannerTimer;

  bool _isGuideVFixedQuestion(int qid) {
  return qid == 188 || qid == 189 || qid == 194 || qid == 195;
  }
  
  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  String _asString(dynamic v) => (v ?? '').toString();

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }

  List _asList(dynamic v) {
    if (v is List) return v;
    return <dynamic>[];
  }

  int? _asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  String _todayYmd() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${two(now.month)}-${two(now.day)}';
  }

bool get _isGuideV {
  if (page >= 0 && page < sections.length) {
    final current = sections[page];
    final text = _normalizeGuideText(
      '${_asString(current['title'])} ${_asString(current['instructions'])} ${_asString(current['description'])}',
    );
    if (_matchesGuideText(text, 'v', '5')) {
      return true;
    }
  }

  for (final sec in sections) {
    final text = _normalizeGuideText(
      '${_asString(sec['title'])} ${_asString(sec['instructions'])} ${_asString(sec['description'])}',
    );
    if (_matchesGuideText(text, 'v', '5')) {
      return true;
    }
  }

  return false;
}

  int? _realAreaIdFromUserData() {
    final data = _asMap(widget.userData);

    final direct = _asNullableInt(data['area_id']) ??
        _asNullableInt(data['areaId']) ??
        _asNullableInt(data['area_id_fk']);
    if (direct != null && direct > 0) return direct;

    final area = data['area'];
    if (area is Map) {
      final areaMap = Map<String, dynamic>.from(area);
      final nested =
          _asNullableInt(areaMap['id']) ?? _asNullableInt(areaMap['area_id']);
      if (nested != null && nested > 0) return nested;
    }

    return null;
  }

  int? _realPositionIdFromUserData() {
    final data = _asMap(widget.userData);

    final direct = _asNullableInt(data['position_id']) ??
        _asNullableInt(data['positionId']) ??
        _asNullableInt(data['position_id_fk']);
    if (direct != null && direct > 0) return direct;

    final position = data['position'];
    if (position is Map) {
      final positionMap = Map<String, dynamic>.from(position);
      final nested = _asNullableInt(positionMap['id']) ??
          _asNullableInt(positionMap['position_id']);
      if (nested != null && nested > 0) return nested;
    }

    return null;
  }

void _initGuideVAutoProfile() {
  if (!_isGuideV) return;

  final realAreaId = _realAreaIdFromUserData();
  final realPositionId = _realPositionIdFromUserData();

  _guideVProfile['questionnaire_no'] = '1';
  _guideVProfile['applied_date'] = _guideVProfile['applied_date'] ?? _todayYmd();
  _guideVProfile['area_id'] = realAreaId;
  _guideVProfile['position_id'] = realPositionId;

  debugPrint('GUIDE V USERDATA: ${widget.userData}');
  debugPrint('GUIDE V area_id real: $realAreaId');
  debugPrint('GUIDE V position_id real: $realPositionId');
}

void _refreshGuideVAutoProfile() {
  if (!_isGuideV) return;

  final realAreaId = _realAreaIdFromUserData();
  final realPositionId = _realPositionIdFromUserData();

  _guideVProfile.putIfAbsent('questionnaire_no', () => '1');
  _guideVProfile.putIfAbsent('applied_date', _todayYmd);

  if (_guideVProfile['area_id'] == null) {
    _guideVProfile['area_id'] = realAreaId;
  }

  if (_guideVProfile['position_id'] == null) {
    _guideVProfile['position_id'] = realPositionId;
  }

  debugPrint('GUIDE V refresh area_id: ${_guideVProfile['area_id']}');
  debugPrint('GUIDE V refresh position_id: ${_guideVProfile['position_id']}');
}

  String? _guideVFieldByQuestionId(int qid) {
  switch (qid) {
    case 188:
      return 'questionnaire_no';
    case 189:
      return 'applied_date';
    case 190:
      return 'sex';
    case 191:
      return 'age_range';
    case 192:
      return 'marital_status';
    case 193:
      return 'education_level';
    case 194:
      return 'position_id';
    case 195:
      return 'area_id';
    case 196:
      return 'job_type';
    case 197:
      return 'hiring_type';
    case 198:
      return 'staff_type';
    case 199:
      return 'workday_type';
    case 200:
      return 'shift_rotation';
    case 201:
      return 'time_current_position';
    case 202:
      return 'total_work_experience';
    default:
      return null;
  }
}

  void _syncGuideVProfileAnswer(int qid, Map<String, dynamic> answer) {
    if (!_isGuideV) return;

    final field = _guideVFieldByQuestionId(qid);
    if (field == null) return;

      if (field == 'questionnaire_no' ||
      field == 'applied_date' ||
      field == 'area_id' ||
      field == 'position_id') {
    return;
  }

    final value = _answerValueForSave(answer);
    if (value == null) return;

    _guideVProfile[field] = value;
  }

  GlobalKey _keyForQuestion(int qid) {
    return _questionKeys.putIfAbsent(qid, () => GlobalKey());
  }

  String get _effectiveFormType {
    final t = (widget.formType?.trim().isNotEmpty == true)
        ? widget.formType!.trim()
        : (widget.formDetail['type'] ?? form['type'] ?? '').toString();
    return t;
  }

  bool get _isNom035 => _effectiveFormType.toLowerCase() == 'nom035';

  List<dynamic> _parseOptions(dynamic rawOpts) {
    if (rawOpts == null) return <dynamic>[];
    if (rawOpts is List) return rawOpts;

    if (rawOpts is Map) {
      return rawOpts.entries
          .map((e) => {'value': e.key, 'label': e.value}).toList();
    }

    if (rawOpts is String) {
      final s = rawOpts.trim();
      if (s.isEmpty) return <dynamic>[];
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return decoded.entries
              .map((e) => {'value': e.key, 'label': e.value}).toList();
        }
      } catch (_) {}
    }

    return <dynamic>[];
  }

  @override
  void initState() {
    super.initState();

    form = _asMap(widget.formDetail['form']);
    final rawSections =
        _asList(widget.formDetail['sections']).map((e) => _asMap(e)).toList();

    sections = _flattenSections(rawSections);

    if (sections.isEmpty) {
      sections = [
        {
          'title': 'Sin guías',
          'description': 'El backend no envió "sections".',
          'instructions': null,
          'questions': <dynamic>[],
          '_kind': 'doc',
        }
      ];
    }

    _initGuideVAutoProfile();
    _hydrateDraftFromQuestionDefaults();
    _loadSavedAnswers();
  }

  List<Map<String, dynamic>> _flattenSections(List<Map<String, dynamic>> raw) {
    final out = <Map<String, dynamic>>[];

    for (final s in raw) {
      final title = _asString(s['title']);
      final desc = _asString(s['description']);
      final ins = _asString(s['instructions']);

      final hasGroups = s.containsKey('groups') && s['groups'] is List;
      final hasQuestions = s.containsKey('questions') && s['questions'] is List;

      if (hasGroups) {
        if (ins.trim().isNotEmpty) {
          out.add({
            'title': title,
            'description': desc,
            'instructions': ins,
            'questions': <dynamic>[],
            '_kind': 'doc',
          });
        }

        for (final gAny in _asList(s['groups'])) {
          final g = _asMap(gAny);
          out.add({
            'title': _asString(g['title']),
            'description': '',
            'instructions': _asString(g['instructions']),
            'questions': _asList(g['questions']),
            '_kind': 'questions',
          });
        }
        continue;
      }

      if (hasQuestions) {
        final qs = _asList(s['questions']);
        out.add({
          'title': title,
          'description': desc,
          'instructions': ins,
          'questions': qs,
          '_kind': (qs.isEmpty && ins.trim().isNotEmpty) ? 'doc' : 'questions',
        });
        continue;
      }

      out.add({
        'title': title.isEmpty ? 'Guía' : title,
        'description': desc,
        'instructions': ins,
        'questions': <dynamic>[],
        '_kind': (ins.trim().isNotEmpty) ? 'doc' : 'questions',
      });
    }

    return out;
  }

  @override                                                                                                                                 
  void dispose() {
    for (final t in _questionDebouncers.values) {
      t.cancel();
    }
    _guideIIIFinishedBannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedAnswers() async {
    try {
      final answers = await NoticesService.getSubmissionAnswers(
        widget.submissionId,
        type: _effectiveFormType,
      );

      for (final a in answers) {
        final qid = _asInt(a['question_id'], fallback: -1);
        if (qid <= 0) continue;

        if (_isGuideVFixedQuestion(qid)) continue;

        if (a['option_id'] != null) {
          draft[qid] = {'type': 'single', 'optionId': a['option_id']};
        } else if (a['option_ids'] != null) {
          final ids = List<dynamic>.from(a['option_ids'] ?? []);
          if (ids.length <= 1) {
            draft[qid] = {
              'type': 'single',
              'optionId': ids.isEmpty ? null : ids.first,
            };
          } else {
            draft[qid] = {
              'type': 'multi',
              'optionIds': ids,
            };
          }
        } else if (a['answer_text'] != null) {
          draft[qid] = {'type': 'text', 'text': _asString(a['answer_text'])};
        }

        if (draft[qid] != null) {
          _lastSavedSnapshot[qid] = _snapshotAnswer(draft[qid]);
          _syncGuideVProfileAnswer(qid, draft[qid]!);
        }
      }

      _restoreSpecialFlowsFromDraft();
      _goToResumePoint();

      if (mounted) {
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _scrollToTargetQuestion();
          });
        });
      }
    } catch (e) {
      debugPrint('Error cargando respuestas: $e');
    }
  }

  void _restoreSpecialFlowsFromDraft() {
    final guideIIIndex = sections.indexWhere((sec) => _isGuideII(sec));
    if (guideIIIndex != -1) {
      final qs = _asList(sections[guideIIIndex]['questions']);
      if (qs.length >= 40) {
        final q40 = _asMap(qs[39]);
        final q40id = _asInt(q40['id'], fallback: -1);
        if (q40id > 0 && _isAnsweredQuestion(q40, draft[q40id])) {
          _guideIIFlowApplied = true;

          bool any41To43Answered = false;
          for (int i = 40; i <= 42 && i < qs.length; i++) {
            final q = _asMap(qs[i]);
            final qid = _asInt(q['id'], fallback: -1);
            if (qid > 0 && _isAnsweredQuestion(q, draft[qid])) {
              any41To43Answered = true;
              break;
            }
          }

          if (any41To43Answered) {
            _guideIIClientAttentionAnswer ??= true;
            _guideIIBossAnswer ??= true;
            _guideIISkipQuestions41To43 = false;
          }
        }
      }
    }

    final guideIIIIndex = _guideIIISectionIndex();
    if (guideIIIIndex != null) {
      final qs = _asList(sections[guideIIIIndex]['questions']);
      if (qs.length >= 64) {
        final q64 = _asMap(qs[63]);
        final q64id = _asInt(q64['id'], fallback: -1);
        if (q64id > 0 && _isAnsweredQuestion(q64, draft[q64id])) {
          _guideIIIFlowApplied = true;

          bool any65To68Answered = false;
          for (int i = 64; i <= 67 && i < qs.length; i++) {
            final q = _asMap(qs[i]);
            final qid = _asInt(q['id'], fallback: -1);
            if (qid > 0 && _isAnsweredQuestion(q, draft[qid])) {
              any65To68Answered = true;
              break;
            }
          }

          if (any65To68Answered) {
            _guideIIIClientAttentionAnswer ??= true;
            _guideIIIBossAnswer ??= true;
            _guideIIISkipQuestions65To68 = false;
            _guideIIIBossValidationShown = true;
          }
        }
      }
    }
  }

  bool _isGuideVAutoLockedQuestion(int qid) {
    if (!_isGuideV) return false;
    return qid == 188 || qid == 189 || qid == 194 || qid == 195;
  }

  void _hydrateDraftFromQuestionDefaults() {
    for (final sec in sections) {
      final questions = _asList(sec['questions']);

          for (final qAny in questions) {
      final q = _asMap(qAny);
      final qid = _asInt(q['id'], fallback: -1);
      if (qid <= 0) continue;

      if (_isGuideVFixedQuestion(qid)) continue;

        if (draft.containsKey(qid)) continue;

        final normalized = _normalizedQuestionType(q);
        final answerValue = q['answer_value'];

        if (answerValue == null) continue;

        if (normalized == 'single') {
          final val = _asString(answerValue).trim();
          if (val.isNotEmpty) {
            draft[qid] = {
              'type': 'single',
              'optionId': answerValue,
            };
            _lastSavedSnapshot[qid] = _snapshotAnswer(draft[qid]);
            _syncGuideVProfileAnswer(qid, draft[qid]!);
          }
        } else if (normalized == 'multi') {
          if (answerValue is List && answerValue.isNotEmpty) {
            draft[qid] = {
              'type': 'multi',
              'optionIds': List<dynamic>.from(answerValue),
            };
            _lastSavedSnapshot[qid] = _snapshotAnswer(draft[qid]);
            _syncGuideVProfileAnswer(qid, draft[qid]!);
          }
        } else if (normalized == 'text') {
          final val = _asString(answerValue).trim();
          if (val.isNotEmpty) {
            draft[qid] = {
              'type': 'text',
              'text': val,
            };
            _lastSavedSnapshot[qid] = _snapshotAnswer(draft[qid]);
            _syncGuideVProfileAnswer(qid, draft[qid]!);
          }
        }
      }
    }
  }

  bool _questionMustBeAnswered(Map<String, dynamic> q) {
    if (_isNom035) return true;
    return (q['required'] == 1 || q['required'] == true);
  }

  String _normalizedQuestionType(Map<String, dynamic> q) {
    final rt = _asString(q['response_type']).trim().toLowerCase();
    final qt = _asString(q['question_type']).trim().toLowerCase();

    final t = rt.isNotEmpty ? rt : qt;

    if (t == 'open') return 'text';
    if (t == 'yes_no') return 'single';
    if (t == 'likert') return 'single';
    if (t == 'multiple') return 'single';

    if (_isNom035 && t == 'multi') return 'single';

    if (t == 'single' || t == 'multi' || t == 'text') return t;

    return 'single';
  }

  bool _isAnsweredQuestion(Map<String, dynamic> q, Map<String, dynamic>? d) {
    final normalized = _normalizedQuestionType(q);

    if (normalized == 'single') {
      return d != null && d['optionId'] != null;
    }
    if (normalized == 'multi') {
      return ((d?['optionIds'] as List?)?.isNotEmpty ?? false);
    }
    if (normalized == 'text') {
      return _asString(d?['text']).trim().isNotEmpty;
    }
    return false;
  }

  bool _shouldValidateQuestion({
    required Map<String, dynamic> section,
    required int questionIndex,
    required Map<String, dynamic> question,
  }) {
    final mustAnswer = _questionMustBeAnswered(question);
    if (!mustAnswer) return false;

    final numberInGuide = questionIndex + 1;

    if (_isGuideI(section)) {
      final questions = _asList(section['questions']);
      if (questions.isNotEmpty) {
        final firstQ = _asMap(questions[0]);
        final firstQid = _asInt(firstQ['id'], fallback: -1);
        final firstDraft = draft[firstQid];
        final firstSelected = firstDraft?['optionId'];

        final skipGuideIRest = _isNoAnswer(firstSelected);
        if (skipGuideIRest && questionIndex >= 1) {
          return false;
        }
      }
    }

    if (_isGuideII(section) &&
        _shouldSkipGuideIIQuestionByNumber(numberInGuide)) {
      return false;
    }

    if (_isGuideIII(section) &&
        _shouldSkipGuideIIIQuestionByNumber(numberInGuide)) {
      return false;
    }

    return true;
  }

  Map<String, dynamic>? _firstMissingQuestionInSectionNormalized(
      int sectionIndex) {
    final section = sections[sectionIndex];
    if (_isDocPage(section)) return null;

    final questions = _asList(section['questions']);

    for (int idx = 0; idx < questions.length; idx++) {
      final q = _asMap(questions[idx]);
      final qid = _asInt(q['id'], fallback: -1);
      if (qid <= 0) continue;

      final shouldValidate = _shouldValidateQuestion(
        section: section,
        questionIndex: idx,
        question: q,
      );

      if (!shouldValidate) continue;

      final answered = _isAnsweredQuestion(q, draft[qid]);
      if (!answered) {
        return {
          'question': q,
          'question_id': qid,
          'question_index': idx,
        };
      }
    }

    return null;
  }

  int _countMissingInSectionNormalized(int sectionIndex) {
    final section = sections[sectionIndex];
    if (_isDocPage(section)) return 0;

    final questions = _asList(section['questions']);
    int missing = 0;

    for (int idx = 0; idx < questions.length; idx++) {
      final q = _asMap(questions[idx]);
      final qid = _asInt(q['id'], fallback: -1);
      if (qid <= 0) continue;

      final shouldValidate = _shouldValidateQuestion(
        section: section,
        questionIndex: idx,
        question: q,
      );

      if (!shouldValidate) continue;

      final answered = _isAnsweredQuestion(q, draft[qid]);
      if (!answered) missing++;
    }

    return missing;
  }

  Map<String, dynamic>? _firstMissingQuestionGlobal() {
    for (int i = 0; i < sections.length; i++) {
      final missing = _firstMissingQuestionInSectionNormalized(i);
      if (missing != null) {
        return {
          'section_index': i,
          ...missing,
        };
      }
    }
    return null;
  }

  int _countMissingAllNormalized() {
    int total = 0;
    for (int i = 0; i < sections.length; i++) {
      total += _countMissingInSectionNormalized(i);
    }
    return total;
  }

  void _goToResumePoint() {
    final guideIIndex = sections.indexWhere((sec) => _isGuideI(sec));
    if (guideIIndex != -1) {
      final guideI = sections[guideIIndex];
      if (!_isDocPage(guideI)) {
        final guideIQuestions = _asList(guideI['questions']);

        if (guideIQuestions.isNotEmpty) {
          final firstQ = _asMap(guideIQuestions[0]);
          final firstQid = _asInt(firstQ['id'], fallback: -1);

          if (firstQid > 0) {
            final firstDraft = draft[firstQid];
            final firstSelected = firstDraft?['optionId'];

            if (_isNoAnswer(firstSelected)) {
              final guideIIIIndex = _guideIIISectionIndex();
              if (guideIIIIndex != null) {
                page = guideIIIIndex;
                _targetQuestionIndexInGuide = 0;
                return;
              }
            }
          }
        }
      }
    }

    int? lastStartedPage;

    for (int i = 0; i < sections.length; i++) {
      final sec = sections[i];
      if (_isDocPage(sec)) continue;

      final qs = _asList(sec['questions']);
      bool hasAnyAnswered = false;

      for (int j = 0; j < qs.length; j++) {
        final q = _asMap(qs[j]);
        final qid = _asInt(q['id'], fallback: -1);
        if (qid <= 0) continue;

        final d = draft[qid];
        final answered = _isAnsweredQuestion(q, d);

        if (answered) {
          hasAnyAnswered = true;
          lastStartedPage = i;
          continue;
        }

        if (hasAnyAnswered) {
          page = i;
          _targetQuestionIndexInGuide = j;
          return;
        }
      }
    }

    if (lastStartedPage != null) {
      page = lastStartedPage;
      _targetQuestionIndexInGuide = 0;
      return;
    }

    final missingGlobal = _firstMissingQuestionGlobal();
    if (missingGlobal != null) {
      page = _asInt(missingGlobal['section_index'], fallback: 0);
      _targetQuestionIndexInGuide =
          _asInt(missingGlobal['question_index'], fallback: 0);
      return;
    }

    page = 0;
    _targetQuestionIndexInGuide = 0;
  }

  void _scrollToTargetQuestion() {
    if (_targetQuestionIndexInGuide == null) return;
    if (_isDocPage(sections[page])) return;

    final current = sections[page];
    final questions = _asList(current['questions']);

    if (_targetQuestionIndexInGuide! < 0 ||
        _targetQuestionIndexInGuide! >= questions.length) {
      return;
    }

    final q = _asMap(questions[_targetQuestionIndexInGuide!]);
    final qid = _asInt(q['id'], fallback: -1);
    if (qid <= 0) return;

    final key = _questionKeys[qid];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  void _goToQuestion(int qid) {
    final key = _questionKeys[qid];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  void _markGuideIIIAsCompleted() {
    if (_guideIIIFinishedAndLocked) return;

    _guideIIIFinishedBannerTimer?.cancel();

    setState(() {
      _guideIIIFinishedAndLocked = true;
      _showGuideIIIFinishedBanner = true;
    });

    _guideIIIFinishedBannerTimer =
        Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() {
        _showGuideIIIFinishedBanner = false;
      });
    });
  }

  void _goToPageWithAnimation(int targetPage, {int targetQuestionIndex = 0}) {
    if (targetPage < 0 || targetPage >= sections.length) return;

    setState(() {
      page = targetPage;
      _targetQuestionIndexInGuide = targetQuestionIndex;
      _missingQuestionId = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) _scrollToTargetQuestion();
      });
    });
  }

  bool _isFirstQuestionOfCurrentGuideI(int qid) {
    final current = sections[page];
    if (!_isGuideI(current) || _isDocPage(current)) return false;

    final questions = _asList(current['questions']);
    if (questions.isEmpty) return false;

    final firstQuestion = _asMap(questions[0]);
    final firstQid = _asInt(firstQuestion['id'], fallback: -1);

    return firstQid > 0 && firstQid == qid;
  }

  Future<void> _handleImmediateGuideISkipIfNeeded(
    int qid,
    Map<String, dynamic> answer,
  ) async {
    final current = sections[page];
    if (!_isGuideI(current)) return;
    if (!_isFirstQuestionOfCurrentGuideI(qid)) return;
    if (_guideISkipDialogVisible) return;

    final selected = answer['optionId'];
    if (!_isNoAnswer(selected)) return;

    _guideISkipDialogVisible = true;

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) {
      _guideISkipDialogVisible = false;
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cuestionario NOM-035'),
        content: const Text(
          'No es necesario responder las demás preguntas.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) {
      _guideISkipDialogVisible = false;
      return;
    }

    final targetIndex = _guideIIISectionIndex();

    if (targetIndex != null) {
      _goToPageWithAnimation(targetIndex, targetQuestionIndex: 0);
    }

    _guideISkipDialogVisible = false;
  }

  bool _shouldLockBackFromGuideIII() {
    final guideIIIIndex = _guideIIISectionIndex();
    if (guideIIIIndex == null) return false;
    if (page != guideIIIIndex) return false;

    final guideIIndex = sections.indexWhere((sec) => _isGuideI(sec));
    if (guideIIndex == -1) return false;

    final guideI = sections[guideIIndex];
    if (_isDocPage(guideI)) return false;

    final questions = _asList(guideI['questions']);
    if (questions.isEmpty) return false;

    final firstQ = _asMap(questions[0]);
    final firstQid = _asInt(firstQ['id'], fallback: -1);
    if (firstQid <= 0) return false;

    final firstDraft = draft[firstQid];
    final firstSelected = firstDraft?['optionId'];

    return _isNoAnswer(firstSelected);
  }

  bool _shouldLockBackByGuideIIFlow() {
    final current = sections[page];
    return _isGuideII(current) && _guideIIFlowApplied;
  }

  bool _shouldLockBackByGuideIIIFlow() {
    final current = sections[page];
    return _isGuideIII(current) && _guideIIIFlowApplied;
  }

  bool _shouldLockBackAfterGuideIII() {
    final guideIIIIndex = _guideIIISectionIndex();
    if (guideIIIIndex == null) return false;
    return _guideIIIFinishedAndLocked && page > guideIIIIndex;
  }

  String _previousButtonTooltipMessage() {
    if (page == 0) return 'Ya estás en la primera guía.';
    if (_shouldLockBackFromGuideIII()) {
      return 'No puedes regresar a la Guía I porque la primera respuesta fue "No".';
    }
    if (_shouldLockBackByGuideIIFlow()) {
      return 'Bloqueado por la validación especial de la Guía II.';
    }
    if (_shouldLockBackByGuideIIIFlow()) {
      return 'Bloqueado por la validación especial de la Guía III.';
    }
    if (_shouldLockBackAfterGuideIII()) {
      return 'No puedes regresar porque ya terminaste la Guía III.';
    }
    return 'Regresar a la guía anterior';
  }

  bool _shouldDisablePreviousButton() {
    return page == 0 ||
        _shouldLockBackFromGuideIII() ||
        _shouldLockBackByGuideIIFlow() ||
        _shouldLockBackByGuideIIIFlow() ||
        _shouldLockBackAfterGuideIII();
  }

  String _snapshotAnswer(Map<String, dynamic>? d) {
    if (d == null) return '';
    return jsonEncode(d);
  }

  dynamic _answerValueForSave(Map<String, dynamic>? answer) {
    if (answer == null) return null;

    final type = _asString(answer['type']);

    if (type == 'single') return answer['optionId'];
    if (type == 'multi') return List<dynamic>.from(answer['optionIds'] ?? []);
    if (type == 'text') return _asString(answer['text']).trim();

    return null;
  }

Future<void> _saveSingleQuestion(int qid, {bool markSaving = false}) async {
  //  No guardar automáticamente campos fijos de Guía V
  if (_isGuideVFixedQuestion(qid)) {
    return;
  }

  final answer = draft[qid];
  if (answer == null) return;

  final answerValue = _answerValueForSave(answer);
  if (answerValue == null) return;

  if (answerValue is String && answerValue.trim().isEmpty) return;
  if (answerValue is List && answerValue.isEmpty) return;

  final snap = _snapshotAnswer(answer);
  if (_lastSavedSnapshot[qid] == snap) return;

  if (markSaving && mounted) {
    setState(() {
      saving = true;
      saveError = null;
    });
  }

  try {
    await NoticesService.saveSingleAnswerByType(
      widget.submissionId,
      questionId: qid,
      answerValue: answerValue,
      type: _effectiveFormType,
      guideVProfile: null,
    );

    _lastSavedSnapshot[qid] = snap;

    if (markSaving && mounted) {
      setState(() {
        saving = false;
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      saving = false;
      saveError = e.toString();
    });
  }
}

  void _scheduleQuestionAutosave(int qid) {
    _questionDebouncers[qid]?.cancel();
    _questionDebouncers[qid] =
        Timer(const Duration(milliseconds: 500), () async {
      await _saveSingleQuestion(qid);
    });
  }

  void _handleQuestionChanged(int qid, Map<String, dynamic> answer) {
    setState(() {
      draft[qid] = answer;
      _syncGuideVProfileAnswer(qid, answer);

      if (_isQuestion40OfGuideII(qid)) {
        _guideIIClientAttentionAnswer = null;
        _guideIIBossAnswer = null;
        _guideIISkipQuestions41To43 = false;
        _guideIIFlowApplied = false;
        _guideIIBossValidationShown = false;
      }

      if (_isQuestion64OfGuideIII(qid)) {
        _guideIIIClientAttentionAnswer = null;
        _guideIIIBossAnswer = null;
        _guideIIISkipQuestions65To68 = false;
        _guideIIIFlowApplied = false;
        _guideIIIBossValidationShown = false;
      }

      if (_missingQuestionId == qid) {
        _missingQuestionId = null;
      }
    });

    _scheduleQuestionAutosave(qid);
    _handleImmediateGuideISkipIfNeeded(qid, answer);
    _handleGuideIIQuestion40FlowIfNeeded(qid, answer);
    _handleGuideIIQuestions41To43CompletionIfNeeded(qid);
    _handleGuideIIIQuestion64FlowIfNeeded(qid, answer);
    _maybeTriggerGuideIIIBossValidationAfterAnswers();
  }

  Future<void> _flushVisibleSectionQuestions() async {
  final current = sections[page];
  final questions = _asList(current['questions']);

  for (final qAny in questions) {
    final q = _asMap(qAny);
    final qid = _asInt(q['id'], fallback: -1);
    if (qid <= 0) continue;

    // 🔒 BLOQUEAR GUÍA V AQUÍ TAMBIÉN
    if (_isGuideVFixedQuestion(qid)) continue;

    _questionDebouncers[qid]?.cancel();
    await _saveSingleQuestion(qid);
  }
}

  List<Map<String, dynamic>> _buildAnswersPayloadForCurrentSection() {
  final current = sections[page];
  final questions = _asList(current['questions']);

  final List<Map<String, dynamic>> out = [];

  for (final qAny in questions) {
    final q = _asMap(qAny);
    final qid = _asInt(q['id'], fallback: -1);
    if (qid <= 0) continue;

    //  No mandar los campos fijos/autollenados de Guía V
    if (_isGuideVFixedQuestion(qid)) {
  continue;
}

    final d = draft[qid];
    if (d == null) continue;

    final normalized = _normalizedQuestionType(q);

    if (normalized == 'single') {
      final optionId = d['optionId'];
      if (optionId != null) {
        out.add({'question_id': qid, 'option_id': optionId});
      }
    } else if (normalized == 'multi') {
      final optionIds = (d['optionIds'] as List?) ?? <dynamic>[];
      if (optionIds.isNotEmpty) {
        out.add({'question_id': qid, 'option_ids': optionIds});
      }
    } else if (normalized == 'text') {
      final text = _asString(d['text']).trim();
      if (text.isNotEmpty) {
        out.add({'question_id': qid, 'answer_text': text});
      }
    }
  }

  return out;
}

Future<void> _saveDraft({bool showSnack = true}) async {
  setState(() {
    saving = true;
    saveError = null;
  });

  try {
    final payload = _buildAnswersPayloadForCurrentSection();

    await NoticesService.saveAnswersByType(
      widget.submissionId,
      payload,
      type: _effectiveFormType,
      guideVProfile: null,
    );

    for (final item in payload) {
      final qid = _asInt(item['question_id'], fallback: -1);
      if (qid <= 0) continue;
      if (draft[qid] != null) {
        _lastSavedSnapshot[qid] = _snapshotAnswer(draft[qid]);
      }
    }

    if (!mounted) return;
    setState(() => saving = false);

    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Respuestas guardadas')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      saving = false;
      saveError = e.toString();
    });

    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }
}

  bool _isDocPage(Map<String, dynamic> sec) {
    final kind = _asString(sec['_kind']);
    if (kind == 'doc') return true;
    final questions = _asList(sec['questions']);
    final ins = _asString(sec['instructions']);
    return questions.isEmpty && ins.trim().isNotEmpty;
  }

  int _countMissingInSection(int index) {
    return _countMissingInSectionNormalized(index);
  }

  Map<String, dynamic>? _firstMissingQuestionInSection(int index) {
    final result = _firstMissingQuestionInSectionNormalized(index);
    return result?['question'] as Map<String, dynamic>?;
  }

  int _countMissingAll() {
    return _countMissingAllNormalized();
  }

  int _answeredInSection(int index) {
    final current = sections[index];
    if (_isDocPage(current)) return 0;

    final questions = _asList(current['questions']);
    int answered = 0;

    for (int idx = 0; idx < questions.length; idx++) {
      final q = _asMap(questions[idx]);
      final qid = _asInt(q['id'], fallback: -1);
      if (qid <= 0) continue;

      final shouldValidate = _shouldValidateQuestion(
        section: current,
        questionIndex: idx,
        question: q,
      );

      if (!shouldValidate) continue;

      if (_isAnsweredQuestion(q, draft[qid])) {
        answered++;
      }
    }

    return answered;
  }

  String _normalizeGuideText(String s) {
    return s
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _matchesGuideText(String text, String roman, String arabic) {
    final normalized = _normalizeGuideText(text);

    final patterns = <RegExp>[
      RegExp('\\bguia de referencia $roman\\b'),
      RegExp('\\bguia de referencia $arabic\\b'),
      RegExp('\\breferencia $roman\\b'),
      RegExp('\\breferencia $arabic\\b'),
      RegExp('\\bguia $roman\\b'),
      RegExp('\\bguia $arabic\\b'),
    ];

    for (final pattern in patterns) {
      if (pattern.hasMatch(normalized)) return true;
    }

    return false;
  }

  bool _isGuideI(Map<String, dynamic> sec) {
    final allText = _normalizeGuideText(
      '${_asString(sec['title'])} ${_asString(sec['instructions'])} ${_asString(sec['description'])}',
    );

    return _matchesGuideText(allText, 'i', '1');
  }

  bool _isGuideII(Map<String, dynamic> sec) {
    final allText = _normalizeGuideText(
      '${_asString(sec['title'])} ${_asString(sec['instructions'])} ${_asString(sec['description'])}',
    );

    return _matchesGuideText(allText, 'ii', '2');
  }

  bool _isGuideIII(Map<String, dynamic> sec) {
    final allText = _normalizeGuideText(
      '${_asString(sec['title'])} ${_asString(sec['instructions'])} ${_asString(sec['description'])}',
    );

    return _matchesGuideText(allText, 'iii', '3');
  }

  bool _isGuideIV(Map<String, dynamic> sec) {
    final allText = _normalizeGuideText(
      '${_asString(sec['title'])} ${_asString(sec['instructions'])} ${_asString(sec['description'])}',
    );

    return _matchesGuideText(allText, 'iv', '4');
  }

  int _questionIndexInCurrentSectionById(int qid) {
    final current = sections[page];
    final questions = _asList(current['questions']);

    for (int i = 0; i < questions.length; i++) {
      final q = _asMap(questions[i]);
      final currentQid = _asInt(q['id'], fallback: -1);
      if (currentQid == qid) return i;
    }

    return -1;
  }

  bool _isQuestion40OfGuideII(int qid) {
    final current = sections[page];
    if (_isDocPage(current)) return false;
    if (!_isGuideII(current)) return false;

    final idx = _questionIndexInCurrentSectionById(qid);
    return idx == 39;
  }

  bool _isQuestion64OfGuideIII(int qid) {
    final current = sections[page];
    if (_isDocPage(current)) return false;
    if (!_isGuideIII(current)) return false;

    final idx = _questionIndexInCurrentSectionById(qid);
    return idx == 63;
  }

  bool _shouldSkipGuideIIQuestionByNumber(int numberInGuide) {
    if (!_guideIISkipQuestions41To43) return false;
    return numberInGuide >= 41 && numberInGuide <= 43;
  }

  bool _shouldSkipGuideIIIQuestionByNumber(int numberInGuide) {
    if (!_guideIIISkipQuestions65To68) return false;
    return numberInGuide >= 65 && numberInGuide <= 68;
  }

  Future<void> _handleGuideIIQuestion40FlowIfNeeded(
    int qid,
    Map<String, dynamic> answer,
  ) async {
    if (!_isQuestion40OfGuideII(qid)) return;
    if (_guideIIFlowDialogVisible) return;

    final answered = _answerValueForSave(answer);
    if (answered == null) return;
    if (answered is String && answered.trim().isEmpty) return;
    if (answered is List && answered.isEmpty) return;

    _guideIIFlowDialogVisible = true;

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) {
      _guideIIFlowDialogVisible = false;
      return;
    }

    final brindaAtencion = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cuestionario NOM-035'),
        content: const Text(
          'En mi trabajo debo brindar atención a clientes o usuarios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ'),
          ),
        ],
      ),
    );

    if (!mounted) {
      _guideIIFlowDialogVisible = false;
      return;
    }

    setState(() {
      _guideIIClientAttentionAnswer = brindaAtencion == true;
      _guideIIFlowApplied = true;
      _missingQuestionId = null;
      _guideIIBossAnswer = null;
      _guideIIBossValidationShown = false;
      _guideIISkipQuestions41To43 = brindaAtencion != true;
    });

    if (brindaAtencion == true) {
      _guideIIFlowDialogVisible = false;
      return;
    }

    await _showGuideIIBossValidation();

    _guideIIFlowDialogVisible = false;
  }

  bool _isGuideIIQuestions41To43Complete() {
    final guideIIIndex = sections.indexWhere((sec) => _isGuideII(sec));
    if (guideIIIndex == -1) return false;

    final questions = _asList(sections[guideIIIndex]['questions']);
    if (questions.length < 43) return false;

    for (int idx = 40; idx <= 42; idx++) {
      final q = _asMap(questions[idx]);
      final qid = _asInt(q['id'], fallback: -1);
      if (qid <= 0) return false;
      if (!_isAnsweredQuestion(q, draft[qid])) return false;
    }

    return true;
  }

  Future<void> _handleGuideIIQuestions41To43CompletionIfNeeded(int qid) async {
    final current = sections[page];
    if (!_isGuideII(current)) return;
    if (_guideIIClientAttentionAnswer != true) return;
    if (_guideIIBossValidationShown) return;

    final idx = _questionIndexInCurrentSectionById(qid);
    if (idx < 40 || idx > 42) return;

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;
    if (!_isGuideIIQuestions41To43Complete()) return;

    await _showGuideIIBossValidation();
  }

  Future<void> _showGuideIIBossValidation() async {
    if (_guideIIBossValidationShown) return;
    _guideIIBossValidationShown = true;

    final esJefe = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cuestionario NOM-035'),
        content: const Text('¿Soy jefe de otros trabajadores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    setState(() {
      _guideIIBossAnswer = esJefe == true;
      _guideIIFlowApplied = true;
    });

    if (esJefe == true) {
      if (_guideIIClientAttentionAnswer == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Cuestionario NOM-035'),
            content: const Text(
              'Las siguientes preguntas están relacionadas con las actitudes de los trabajadores que supervisa.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cuestionario NOM-035'),
        content: const Text(
          'Ha concluido este apartado del cuestionario y pasará automáticamente a la Guía III.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    final targetIndex = _guideIIISectionIndex();
    if (targetIndex != null) {
      _goToPageWithAnimation(targetIndex, targetQuestionIndex: 0);
    }
  }

  Future<void> _handleGuideIIIQuestion64FlowIfNeeded(
    int qid,
    Map<String, dynamic> answer,
  ) async {
    if (!_isQuestion64OfGuideIII(qid)) return;
    if (_guideIIIFlowDialogVisible) return;

    final answered = _answerValueForSave(answer);
    if (answered == null) return;
    if (answered is String && answered.trim().isEmpty) return;
    if (answered is List && answered.isEmpty) return;

    _guideIIIFlowDialogVisible = true;

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) {
      _guideIIIFlowDialogVisible = false;
      return;
    }

    final brindaAtencion = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cuestionario NOM-035'),
        content: const Text(
          'En mi trabajo debo brindar atención a clientes o usuarios.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ'),
          ),
        ],
      ),
    );

    if (!mounted) {
      _guideIIIFlowDialogVisible = false;
      return;
    }

    setState(() {
      _guideIIIClientAttentionAnswer = brindaAtencion == true;
      _guideIIIFlowApplied = true;
      _missingQuestionId = null;
      _guideIIIBossValidationShown = false;
      _guideIIISkipQuestions65To68 = brindaAtencion != true;

      if (_guideIIISkipQuestions65To68) {
        final guideIIIIndex = _guideIIISectionIndex();
        if (guideIIIIndex != null) {
          final qs = _asList(sections[guideIIIIndex]['questions']);
          for (int i = 64; i <= 67 && i < qs.length; i++) {
            final q = _asMap(qs[i]);
            final skipQid = _asInt(q['id'], fallback: -1);
            if (skipQid > 0) {
              draft.remove(skipQid);
              _lastSavedSnapshot.remove(skipQid);
            }
          }
        }
      }
    });

    if (brindaAtencion != true) {
      await _showGuideIIIBossValidation();
      _guideIIIFlowDialogVisible = false;
      return;
    }

    _guideIIIFlowDialogVisible = false;
  }

  Future<void> _showGuideIIIBossValidation() async {
    if (_guideIIIBossValidationShown) return;
    _guideIIIBossValidationShown = true;

    final esJefe = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Cuestionario NOM-035'),
        content: const Text('¿Soy jefe de otros trabajadores?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SÍ'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    setState(() {
      _guideIIIBossAnswer = esJefe == true;
      _guideIIIFlowApplied = true;
    });

    if (esJefe != true) {
      final guideIVIndex = _guideIVSectionIndex();
      if (guideIVIndex != null) {
        _markGuideIIIAsCompleted();
        _goToPageWithAnimation(guideIVIndex, targetQuestionIndex: 0);
      }
      return;
    }

    if (_guideIIISkipQuestions65To68) {
      _goToGuideIIIRemainingQuestions();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        _goToGuideIIIRemainingQuestions();
      });
    });
  }

  int? _guideIIISectionIndex() {
    for (int i = 0; i < sections.length; i++) {
      if (_isGuideIII(sections[i])) {
        return i;
      }
    }
    return null;
  }

  int? _guideIVSectionIndex() {
    for (int i = 0; i < sections.length; i++) {
      if (_isGuideIV(sections[i])) {
        return i;
      }
    }
    return null;
  }

  bool _isNoAnswer(dynamic selected) {
    final val = '$selected'.trim().toLowerCase();
    return val == '2' || val == 'no';
  }

  bool _isGuideIIIQuestions65To68Complete() {
    if (_guideIIISkipQuestions65To68) return true;

    final guideIIIIndex = _guideIIISectionIndex();
    if (guideIIIIndex == null) return false;

    final questions = _asList(sections[guideIIIIndex]['questions']);
    if (questions.length < 68) return false;

    for (int idx = 64; idx <= 67; idx++) {
      final q = _asMap(questions[idx]);
      final qid = _asInt(q['id'], fallback: -1);
      if (qid <= 0) return false;
      if (!_isAnsweredQuestion(q, draft[qid])) return false;
    }

    return true;
  }

  void _maybeTriggerGuideIIIBossValidationAfterAnswers() {
    final current = sections[page];

    if (!_isGuideIII(current)) return;

    if (_guideIIIClientAttentionAnswer != true) return;

    if (_guideIIIBossValidationShown) return;

    if (!_isGuideIIIQuestions65To68Complete()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;
      if (_guideIIIBossValidationShown) return;

      await _showGuideIIIBossValidation();
    });
  }

  void _goToGuideIIIRemainingQuestions() {
    final guideIIIIndex = _guideIIISectionIndex();
    if (guideIIIIndex == null) return;

    final startIndex = _guideIIISkipQuestions65To68 ? 68 : 64;
    final questions = _asList(sections[guideIIIIndex]['questions']);
    if (questions.length <= startIndex) return;

    _goToPageWithAnimation(guideIIIIndex, targetQuestionIndex: startIndex);
  }

  Future<void> _next() async {
    final current = sections[page];

    if (_isGuideIII(current) &&
        _guideIIIClientAttentionAnswer == true &&
        !_guideIIIBossValidationShown &&
        _isGuideIIIQuestions65To68Complete()) {
      await _showGuideIIIBossValidation();
      return;
    }

    if (!_isDocPage(current)) {
      final firstMissingData = _firstMissingQuestionInSectionNormalized(page);

      if (firstMissingData != null) {
        final qid = _asInt(firstMissingData['question_id'], fallback: -1);
        final indexInGuide =
            _asInt(firstMissingData['question_index'], fallback: -1);

        setState(() {
          _missingQuestionId = qid;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Te falta responder la pregunta número ${indexInGuide + 1}'),
            backgroundColor: Colors.red,
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToQuestion(qid);
        });

        return;
      }

      setState(() {
        _missingQuestionId = null;
      });

      await _flushVisibleSectionQuestions();
    }

    if (_isGuideII(current) &&
        _guideIIClientAttentionAnswer == true &&
        !_guideIIBossValidationShown &&
        _isGuideIIQuestions41To43Complete()) {
      await _showGuideIIBossValidation();
      return;
    }

    if (_isGuideIII(current) &&
        _guideIIIClientAttentionAnswer == true &&
        !_guideIIIBossValidationShown &&
        _isGuideIIIQuestions65To68Complete()) {
      await _showGuideIIIBossValidation();
      return;
    }

    if (page < sections.length - 1) {
      if (_isGuideIII(current)) {
        _markGuideIIIAsCompleted();
      }
      _goToPageWithAnimation(page + 1, targetQuestionIndex: 0);
    }
  }

  void _back() {
    if (_shouldLockBackFromGuideIII()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No es necesario regresar a la Guía I porque la primera respuesta fue "No".',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_shouldLockBackByGuideIIFlow()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes regresar porque ya se aplicó la validación especial de la Guía II.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_shouldLockBackByGuideIIIFlow()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes regresar porque ya se aplicó la validación especial de la Guía III.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_shouldLockBackAfterGuideIII()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes regresar porque ya terminaste la Guía III.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (page > 0) {
      _goToPageWithAnimation(page - 1, targetQuestionIndex: 0);
    }
  }

  Future<void> _submit({bool allowEarlyFinish = false}) async {
    if (!allowEarlyFinish) {
      final firstMissingGlobal = _firstMissingQuestionGlobal();

      if (firstMissingGlobal != null) {
        final sectionIndex =
            _asInt(firstMissingGlobal['section_index'], fallback: 0);
        final qid = _asInt(firstMissingGlobal['question_id'], fallback: -1);
        final indexInGuide =
            _asInt(firstMissingGlobal['question_index'], fallback: -1);
        final missingAll = _countMissingAllNormalized();

        setState(() {
          page = sectionIndex;
          _missingQuestionId = qid;
          _targetQuestionIndexInGuide = indexInGuide;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _goToQuestion(qid);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              missingAll == 1
                  ? 'Falta 1 pregunta por responder.'
                  : 'Aún faltan $missingAll preguntas por contestar.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enviar cuestionario'),
        content: const Text(
          '¿Seguro que deseas enviar? Ya no podrás editar las respuestas.',
        ),
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

    if (mounted) {
      setState(() {
        saving = true;
        saveError = null;
      });
    }

    try {
      await _flushVisibleSectionQuestions();
      //_refreshGuideVAutoProfile();

      await NoticesService.submitFormByType(
      widget.submissionId,
      type: _effectiveFormType,
      guideVProfile: _isGuideV ? _guideVProfile : null,
      );

      if (!mounted) return;

      setState(() {
        saving = false;
      });

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
          builder: (_) => AppShell(
          userData: widget.userData,
          initialIndex: 2,
          ),
          ),
          (route) => false,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saving = false;
        saveError = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    }
  }

  Widget _buildSkipIndicator(Map<String, dynamic> current) {
    String? message;

    if (_isGuideII(current) && _guideIIFlowApplied) {
      if (_guideIISkipQuestions41To43) {
        message =
            'Se saltaron las preguntas 41, 42 y 43 por el flujo lógico de la Guía II.';
      } else {
        message =
            'Se aplicó la validación especial de la Guía II después de la pregunta 40.';
      }
    } else if (_isGuideIII(current) && _guideIIIFlowApplied) {
      if (_guideIIISkipQuestions65To68) {
        message =
            'Se saltaron las preguntas 65, 66, 67 y 68 por el flujo lógico de la Guía III.';
      } else {
        message =
            'Se aplicó la validación especial de la Guía III después de la pregunta 64.';
      }
    }

    if (message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideIIICompletionBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: _showGuideIIIFinishedBanner
          ? Container(
              key: const ValueKey('guide_iii_finished_banner'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Guía III finalizada. El botón Anterior quedó bloqueado.',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(
              key: ValueKey('guide_iii_finished_banner_empty')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _asString(form['title']).isNotEmpty
        ? _asString(form['title'])
        : 'Cuestionario';

    final current = sections[page];
    final guideTitle = _asString(current['title']);
    final guideDesc = _asString(current['description']);
    final guideIns = _asString(current['instructions']);
    final questions = _asList(current['questions']);

    final totalGuides = sections.length;
    final isLast = page == totalGuides - 1;
    final isDoc = _isDocPage(current);
    final answeredHere = isDoc ? 0 : _answeredInSection(page);

    return WillPopScope(
      onWillPop: () async {
        if (_shouldLockBackFromGuideIII()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No puedes regresar a la Guía I porque la primera respuesta fue "No".',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }

        if (_shouldLockBackByGuideIIFlow()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No puedes regresar porque ya se aplicó la validación especial de la Guía II.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }

        if (_shouldLockBackByGuideIIIFlow()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No puedes regresar porque ya se aplicó la validación especial de la Guía III.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }

        if (_shouldLockBackAfterGuideIII()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No puedes regresar porque ya terminaste la Guía III.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }

        final total = questions.length;
        final answered = answeredHere;

        final exit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Salir del cuestionario'),
            content: Text(
              'En esta guía has respondido $answered de $total.\n\n¿Deseas salir?',
            ),
            actions: [
              TextButton(
                child: const Text('Continuar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text('Salir'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        );

        return exit ?? false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          automaticallyImplyLeading: !_shouldDisablePreviousButton(),
          title: Text(title),
          actions: [
            if (saving)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: saving ? null : () => _saveDraft(showSnack: true),
              tooltip: 'Guardar',
            ),
          ],
        ),

body: SafeArea(
  child: Stack(
    children: [
      Positioned.fill(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  key: ValueKey('header_$page'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Guía ${page + 1} de $totalGuides',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: LinearProgressIndicator(
                            value: (page + 1) / totalGuides,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSkipIndicator(current),
                    _buildGuideIIICompletionBanner(),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guideTitle.isEmpty
                                  ? 'Guía'
                                  : 'Guía: $guideTitle',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (guideDesc.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(guideDesc),
                            ],
                            if (guideIns.trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(guideIns),
                            ],
                            if (!isDoc) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Respondidas: $answeredHere / ${questions.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (saveError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                saveError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.12, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: isDoc
                    ? Card(
                        key: ValueKey('doc_$page'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            guideIns.trim().isNotEmpty
                                ? guideIns
                                : 'Documento sin contenido.',
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      )
                    : Column(
                        key: ValueKey('questions_$page'),
                        children: List.generate(questions.length, (idx) {
                          final q = _asMap(questions[idx]);
                          final qid = _asInt(q['id'], fallback: -1);
                          final numberInGuide = idx + 1;

                          if (_isGuideII(current) &&
                              _shouldSkipGuideIIQuestionByNumber(
                                  numberInGuide)) {
                            return _SkippedQuestionCard(
                              numberInGuide: numberInGuide,
                            );
                          }

                          if (_isGuideIII(current) &&
                              _shouldSkipGuideIIIQuestionByNumber(
                                  numberInGuide)) {
                            return _SkippedQuestionCard(
                              numberInGuide: numberInGuide,
                            );
                          }

                          return _QuestionCard(
                            key: qid > 0 ? _keyForQuestion(qid) : UniqueKey(),
                            question: q,
                            draft: draft,
                            onChanged: _handleQuestionChanged,
                            numberInGuide: numberInGuide,
                            optionsParser: _parseOptions,
                            showMissingHighlight: true,
                            highlightThisQuestion: _missingQuestionId == qid,
                            forceSingleChoice: _isNom035,
                            readOnly: _isGuideVAutoLockedQuestion(qid),
                          );
                        }),
                      ),
              ),
            ],
          ),
        ),
      ),

      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: _previousButtonTooltipMessage(),
                    waitDuration: const Duration(milliseconds: 250),
                    child: OutlinedButton.icon(
                      onPressed:
                          _shouldDisablePreviousButton() ? null : _back,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Anterior'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: saving
                        ? null
                        : (isLast
                            ? () => _submit(allowEarlyFinish: true)
                            : _next),
                    icon: Icon(
                      isLast ? Icons.check : Icons.arrow_forward,
                    ),
                    label: Text(isLast ? 'Enviar' : 'Siguiente'),
                  ),
                ),
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

class _SkippedQuestionCard extends StatelessWidget {
  final int numberInGuide;

  const _SkippedQuestionCard({
    required this.numberInGuide,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.fast_forward_rounded, color: Colors.grey.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pregunta $numberInGuide omitida por flujo lógico.',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatefulWidget {
  final Map<String, dynamic> question;
  final Map<int, Map<String, dynamic>> draft;
  final void Function(int questionId, Map<String, dynamic> answer) onChanged;
  final int numberInGuide;
  final List<dynamic> Function(dynamic raw) optionsParser;
  final bool showMissingHighlight;
  final bool highlightThisQuestion;
  final bool forceSingleChoice;
  final bool readOnly;

  const _QuestionCard({
    super.key,
    required this.question,
    required this.draft,
    required this.onChanged,
    required this.numberInGuide,
    required this.optionsParser,
    required this.showMissingHighlight,
    required this.highlightThisQuestion,
    required this.forceSingleChoice,
    required this.readOnly,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  late final int qid;
  late final String normalizedType;
  late final bool required;

  final TextEditingController _txt = TextEditingController();

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  String _asString(dynamic v) => (v ?? '').toString();

  String _normalize(Map<String, dynamic> q) {
    final rt = _asString(q['response_type']).trim().toLowerCase();
    final qt = _asString(q['question_type']).trim().toLowerCase();
    final t = rt.isNotEmpty ? rt : qt;

    if (t == 'yes_no') return 'single';
    if (t == 'likert') return 'single';
    if (t == 'multiple') return 'single';
    if (t == 'open') return 'text';

    if (widget.forceSingleChoice && t == 'multi') {
      return 'single';
    }

    if (t == 'single' || t == 'multi' || t == 'text') return t;
    return 'single';
  }

  bool _isAnswered() {
    final d = widget.draft[qid];

    if (normalizedType == 'single') {
      return d != null && d['optionId'] != null;
    }

    if (normalizedType == 'multi') {
      return ((d?['optionIds'] as List?)?.isNotEmpty ?? false);
    }

    if (normalizedType == 'text') {
      return _asString(d?['text']).trim().isNotEmpty;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();

    qid = _asInt(widget.question['id'], fallback: -1);
    normalizedType = _normalize(widget.question);
    required =
        (widget.question['required'] == 1 || widget.question['required'] == true);

    final d = widget.draft[qid];
    if (normalizedType == 'text') {
      _txt.text = _asString(d?['text']);
    }
  }

  @override
  void didUpdateWidget(covariant _QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final d = widget.draft[qid];
    if (normalizedType == 'text') {
      final newText = _asString(d?['text']);
      if (_txt.text != newText) {
        _txt.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _txt.dispose();
    super.dispose();
  }

  dynamic _optValue(dynamic optionAny, int index) {
    if (optionAny is Map) {
      final m = Map<String, dynamic>.from(optionAny);
      return m['value'] ?? m['id'] ?? (index + 1);
    }

    final label = _asString(optionAny).trim().toLowerCase();
    if (label == 'sí' || label == 'si') return 1;
    if (label == 'no') return 2;

    return index + 1;
  }

  String _optLabel(dynamic optionAny) {
    if (optionAny is Map) {
      final m = Map<String, dynamic>.from(optionAny);
      return _asString(
        m['label'] ?? m['option_text'] ?? m['text'] ?? m['value'],
      );
    }
    return _asString(optionAny);
  }

  List<dynamic> _optionsFromQuestion() {
    final raw = widget.question['options'] ?? widget.question['options_json'];
    final opts = widget.optionsParser(raw);

    final rt = _asString(widget.question['response_type']);
    if (rt == 'yes_no' && opts.isEmpty) {
      return [
        {'label': 'Sí', 'value': 1},
        {'label': 'No', 'value': 2},
      ];
    }

    return opts;
  }

  @override
  Widget build(BuildContext context) {
    final text = _asString(widget.question['question_text']);
    final options = _optionsFromQuestion();
    final answered = _isAnswered();
    final missingRequired = widget.highlightThisQuestion && !answered;

    if (qid <= 0) {
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Pregunta inválida (sin id). Revisa el JSON del backend.'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.showMissingHighlight && missingRequired
            ? const BorderSide(color: Colors.red, width: 1.4)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.numberInGuide}. $text${required ? ' *' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.showMissingHighlight && missingRequired
                    ? Colors.red.shade900
                    : null,
              ),
            ),
            if (widget.readOnly) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Valor autollenado',
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            if (widget.showMissingHighlight && missingRequired) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pregunta pendiente por responder',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (normalizedType == 'single') ..._singleOptions(options),
            if (normalizedType == 'multi') ..._multiOptions(options),
            if (normalizedType == 'text') _textAnswer(),
          ],
        ),
      ),
    );
  }

  List<Widget> _singleOptions(List options) {
    final d = widget.draft[qid] ?? {};
    final selected = d['optionId'];

    if (options.isEmpty) {
      return const [
        Text(
          'Sin opciones para esta pregunta. Revisa options_json.',
          style: TextStyle(fontSize: 12),
        ),
      ];
    }

    return List<Widget>.generate(options.length, (i) {
      final oid = _optValue(options[i], i);
      final label = _optLabel(options[i]);

      return RadioListTile<dynamic>(
        value: oid,
        groupValue: selected,
        title: Text(label),
        onChanged: widget.readOnly
            ? null
            : (v) {
                final answer = {'type': 'single', 'optionId': v};
                widget.draft[qid] = answer;
                setState(() {});
                widget.onChanged(qid, answer);
              },
      );
    });
  }

  List<Widget> _multiOptions(List options) {
    final d = widget.draft[qid] ?? {};
    final selected = List<dynamic>.from(d['optionIds'] ?? []);

    if (options.isEmpty) {
      return const [
        Text(
          'Sin opciones para esta pregunta. Revisa options_json.',
          style: TextStyle(fontSize: 12),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          'Puedes seleccionar una o varias opciones',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      ...List<Widget>.generate(options.length, (i) {
        final oid = _optValue(options[i], i);
        final label = _optLabel(options[i]);
        final isChecked = selected.any((x) => '$x' == '$oid');

        return CheckboxListTile(
          value: isChecked,
          title: Text(label),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          onChanged: widget.readOnly
              ? null
              : (checked) {
                  final updated = List<dynamic>.from(selected);

                  if (checked == true) {
                    if (!updated.any((x) => '$x' == '$oid')) {
                      updated.add(oid);
                    }
                  } else {
                    updated.removeWhere((x) => '$x' == '$oid');
                  }

                  final answer = {
                    'type': 'multi',
                    'optionIds': updated,
                  };

                  widget.draft[qid] = answer;
                  setState(() {});
                  widget.onChanged(qid, answer);
                },
        );
      }),
    ];
  }

  Widget _textAnswer() {
    final answered = _isAnswered();
    final missingRequired = widget.highlightThisQuestion && !answered;

    return TextField(
      controller: _txt,
      minLines: 2,
      maxLines: 6,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        hintText: 'Escribe tu respuesta...',
        border: const OutlineInputBorder(),
        enabledBorder: widget.showMissingHighlight && missingRequired
            ? OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade400),
              )
            : null,
        focusedBorder: widget.showMissingHighlight && missingRequired
            ? OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red.shade700, width: 2),
              )
            : null,
      ),
      onChanged: widget.readOnly
          ? null
          : (v) {
              final answer = {'type': 'text', 'text': v};
              widget.draft[qid] = answer;
              widget.onChanged(qid, answer);
              setState(() {});
            },
    );
  }
}