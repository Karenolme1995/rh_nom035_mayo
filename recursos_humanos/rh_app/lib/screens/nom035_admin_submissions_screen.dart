import 'package:flutter/material.dart';

import '../services/notices_service.dart';
import 'nom035_admin_action_plan_screen.dart';
import 'nom035_admin_evidence_screen.dart';
import 'nom035_admin_submission_detail_screen.dart';
import 'nom035_audit_screen.dart';

class Nom035AdminSubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int cycleId;
  final String? cycleTitle;

  const Nom035AdminSubmissionsScreen({
    super.key,
    required this.userData,
    required this.cycleId,
    required this.cycleTitle,
  });

  @override
  State<Nom035AdminSubmissionsScreen> createState() =>
      _Nom035AdminSubmissionsScreenState();
}

class _Nom035AdminSubmissionsScreenState
    extends State<Nom035AdminSubmissionsScreen>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  String? error;

  List items = [];
  List pendingUsers = [];
  int total = 0;
  Map<String, dynamic> rawPayload = {};

  int page = 1;
  final int pageSize = 25;

  String status = '';
  String risk = '';
  final TextEditingController searchCtl = TextEditingController();
  late TabController _tabController;

  Map<int, String> _areasMap = {};
  Map<int, String> _positionsMap = {};

  String _s(dynamic v) => (v == null) ? '' : v.toString();

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

  Map<String, dynamic> _summary() => _asMap(rawPayload['summary']);
  Map<String, dynamic> _compliance() => _asMap(_summary()['compliance']);

  int get _pendingTotal {
    final fromPayload = _asInt(rawPayload['pending_total']);
    if (fromPayload > 0) return fromPayload;
    return pendingUsers.length;
  }

  int get _answeredTotal {
    final fromPayload = _asInt(rawPayload['total']);
    if (fromPayload > 0) return fromPayload;
    return items.length;
  }

  int get _evidenceTotal {
    final fromPayload = _asInt(
      rawPayload['evidence_total'] ??
          _summary()['evidence_total'] ??
          _summary()['total_evidences'] ??
          _summary()['evidences_count'],
    );
    if (fromPayload > 0) return fromPayload;

    return items.where((e) {
      final item = _asMap(e);

      final directCount = _asInt(
        item['attachments_count'] ??
            item['total_attachments'] ??
            item['adjuntos_count'] ??
            item['evidence_count'],
      );

      final evidences = _asList(
        item['evidences'] ?? item['attachments'] ?? item['evidence_files'],
      );

      return directCount > 0 || evidences.isNotEmpty;
    }).length;
  }

  int get _actionPlanTotal {
    final fromPayload = _asInt(
      rawPayload['action_plan_total'] ??
          _summary()['action_plan_total'] ??
          _summary()['total_action_plans'] ??
          _summary()['plans_count'],
    );
    if (fromPayload > 0) return fromPayload;

    return items.where((e) {
      final item = _asMap(e);

      final actionPlan = _asMap(
        item['action_plan'] ?? item['plan'] ?? item['action_plan_data'],
      );
      final planItems = _asList(
        item['action_plans'] ?? item['plans'] ?? item['plan_items'],
      );

      return actionPlan.isNotEmpty || planItems.isNotEmpty;
    }).length;
  }

  int get _currentTabTotal {
    if (_tabController.index == 1) return _pendingTotal;
    return _answeredTotal;
  }

  bool get _showMainFilters =>
      _tabController.index == 0 || _tabController.index == 1;

  List get _pendingPaged {
    if (pendingUsers.isEmpty) return [];
    final start = (page - 1) * pageSize;
    if (start >= pendingUsers.length) return [];
    final end = (start + pageSize) > pendingUsers.length
        ? pendingUsers.length
        : (start + pageSize);
    return pendingUsers.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          page = 1;
        });
      }
    });
    _load();
  }

  Future<void> _loadCatalogs() async {
    try {
      final areasMap = await NoticesService().getAreasMap();
      final positionsMap = await NoticesService().getPositionsMap();
      _areasMap = areasMap;
      _positionsMap = positionsMap;
    } catch (_) {
      _areasMap = {};
      _positionsMap = {};
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) page = 1;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _loadCatalogs();

      final data = await NoticesService.adminNom035GetCycleSubmissions(
        cycleId: widget.cycleId,
        status: status.isEmpty ? null : status,
        risk: risk.isEmpty ? null : risk,
        q: searchCtl.text.trim().isEmpty ? null : searchCtl.text.trim(),
        page: page,
        pageSize: pageSize,
      );

      final safe = _asMap(data);

      setState(() {
        rawPayload = safe;
        items = _asList(safe['items']);
        pendingUsers = _asList(safe['pending_users']);
        total = _asInt(safe['total']);
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      status = '';
      risk = '';
      page = 1;
      searchCtl.clear();
    });
    _load(reset: true);
  }

  String _resolveArea(dynamic raw) {
    if (raw == null) return '—';

    if (raw is Map) {
      final m = _asMap(raw);

      final preferred = [
        _s(m['letter']).trim(),
        _s(m['code']).trim(),
        _s(m['clave']).trim(),
        _s(m['area_letter']).trim(),
        _s(m['area_code']).trim(),
        _s(m['name']).trim(),
        _s(m['area_name']).trim(),
        _s(m['label']).trim(),
      ];

      for (final value in preferred) {
        if (value.isNotEmpty) return value;
      }

      final id = _asInt(m['id'] ?? m['area_id']);
      if (id > 0 && _areasMap.containsKey(id)) return _areasMap[id]!;
      return id > 0 ? 'Área $id' : '—';
    }

    final rawText = _s(raw).trim();
    if (rawText.isEmpty) return '—';

    final id = int.tryParse(rawText);
    if (id != null) {
      return _areasMap[id] ?? 'Área $id';
    }

    return rawText;
  }

  String _resolvePosition(dynamic raw) {
    if (raw == null) return '—';

    if (raw is Map) {
      final m = _asMap(raw);
      final name = _s(m['name']).trim().isNotEmpty
          ? _s(m['name']).trim()
          : _s(m['position_name']).trim();
      if (name.isNotEmpty) return name;

      final id = _asInt(m['id'] ?? m['position_id']);
      if (id > 0 && _positionsMap.containsKey(id)) return _positionsMap[id]!;
      return id > 0 ? 'ID: $id' : '—';
    }

    final rawText = _s(raw).trim();
    if (rawText.isEmpty) return '—';

    final id = int.tryParse(rawText);
    if (id != null) {
      return _positionsMap[id] ?? 'ID: $id';
    }

    return rawText;
  }

  String _formatDateTime(dynamic raw) {
    final s = _s(raw).trim();
    if (s.isEmpty) return '';

    try {
      final dt = DateTime.parse(s.replaceFirst(' ', 'T'));
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return s;
    }
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase().trim();
    switch (s) {
      case 'submitted':
        return 'Enviado';
      case 'in_progress':
        return 'En curso';
      case 'available':
        return 'Disponible';
      case 'pending':
        return 'Pendiente';
      default:
        return s.isEmpty ? '—' : s;
    }
  }

  Color _statusBg(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'submitted') return Colors.green.shade100;
    if (s == 'in_progress') return Colors.orange.shade100;
    if (s == 'available') return Colors.blue.shade100;
    if (s == 'pending') return Colors.orange.shade100;
    return Colors.grey.shade200;
  }

  Color _statusFg(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'submitted') return Colors.green.shade900;
    if (s == 'in_progress') return Colors.orange.shade900;
    if (s == 'available') return Colors.blue.shade900;
    if (s == 'pending') return Colors.orange.shade900;
    return Colors.grey.shade900;
  }

  Color _riskBg(String risk) {
    final r = risk.toLowerCase().trim();
    if (r == 'muy alto') return Colors.red.shade100;
    if (r == 'alto') return Colors.orange.shade100;
    if (r == 'medio') return Colors.amber.shade100;
    if (r == 'bajo') return Colors.green.shade100;
    if (r == 'nulo' || r == 'sin riesgo') return Colors.blueGrey.shade100;
    return Colors.grey.shade200;
  }

  Color _riskFg(String risk) {
    final r = risk.toLowerCase().trim();
    if (r == 'muy alto') return Colors.red.shade900;
    if (r == 'alto') return Colors.orange.shade900;
    if (r == 'medio') return Colors.amber.shade900;
    if (r == 'bajo') return Colors.green.shade900;
    if (r == 'nulo' || r == 'sin riesgo') return Colors.blueGrey.shade900;
    return Colors.grey.shade900;
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchCtl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_tabController.index),
        child: _buildCurrentTab(),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabController.index) {
      case 0:
        return _answeredList();
      case 1:
        return _pendingList();
      case 2:
        return _evidenceOnlyTab();
      case 3:
        return _actionPlanTab();
      case 4:
        return _auditTab();
      default:
        return _answeredList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPrev = page > 1;
    final canNext = (page * pageSize) < _currentTabTotal;

    return Scaffold(
      appBar: AppBar(
        title: Text('Resultados: ${widget.cycleTitle}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Contestados ($_answeredTotal)'),
            Tab(text: 'Pendientes ($_pendingTotal)'),
            Tab(text: 'Evidencias ($_evidenceTotal)'),
            Tab(text: 'Plan de acción ($_actionPlanTotal)'),
            const Tab(text: 'Auditoría'),
          ],
        ),
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _showMainFilters
                ? Column(
                    key: const ValueKey('filters-visible'),
                    children: [
                      _filtersSingleRow(),
                      const Divider(height: 1),
                    ],
                  )
                : const SizedBox(
                    key: ValueKey('filters-hidden'),
                  ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? _error()
                    : _buildAnimatedTabContent(),
          ),
          if (_showMainFilters)
            _pager(canPrev: canPrev, canNext: canNext),
        ],
      ),
    );
  }

  Widget _filtersSingleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: searchCtl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Nombre, empleado, área o puesto...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchCtl.clear();
                      _load(reset: true);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onSubmitted: (_) => _load(reset: true),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: status.isEmpty ? 'all' : status,
                decoration: const InputDecoration(
                  labelText: 'Estatus',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todos')),
                  DropdownMenuItem(
                    value: 'available',
                    child: Text('Disponible'),
                  ),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('En curso'),
                  ),
                  DropdownMenuItem(value: 'submitted', child: Text('Enviado')),
                ],
                onChanged: (v) {
                  setState(() {
                    status = (v == null || v == 'all') ? '' : v;
                  });
                  _load(reset: true);
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: risk.isEmpty ? 'all' : risk,
                decoration: const InputDecoration(
                  labelText: 'Riesgo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Todos')),
                  DropdownMenuItem(value: 'muy alto', child: Text('Muy alto')),
                  DropdownMenuItem(value: 'alto', child: Text('Alto')),
                  DropdownMenuItem(value: 'medio', child: Text('Medio')),
                  DropdownMenuItem(value: 'bajo', child: Text('Bajo')),
                  DropdownMenuItem(value: 'nulo', child: Text('Nulo')),
                ],
                onChanged: (v) {
                  setState(() {
                    risk = (v == null || v == 'all') ? '' : v;
                  });
                  _load(reset: true);
                },
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _load(reset: true),
                icon: const Icon(Icons.search),
                label: const Text('Aplicar'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Limpiar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error:\n$error', textAlign: TextAlign.center),
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

  Widget _answeredList() {
    if (items.isEmpty) {
      return const Center(
        child: Text('No hay resultados con esos filtros.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = _asMap(items[i]);
          final user = _asMap(it['user']);

          final name = _s(user['name']);
          final emp = _s(user['employee_number']);

          final area = _resolveArea(
            user['area'] ?? user['area_id'] ?? user['area_name'],
          );

          final position = _resolvePosition(
            user['position'] ?? user['position_id'] ?? user['position_name'],
          );

          final st = _s(it['status']);
          final score = it['score_total'];
          final riskLevel = _s(it['risk_level']);
          final submittedAt = _formatDateTime(it['submitted_at']);
          final submissionId = it['submission_id'];
          final userId = _s(user['id']);

          IconData icon;
          Color iconColor;

          if (st == 'submitted') {
            icon = Icons.check_circle;
            iconColor = Colors.green.shade700;
          } else if (st == 'in_progress') {
            icon = Icons.pie_chart;
            iconColor = Colors.orange.shade700;
          } else {
            icon = Icons.radio_button_unchecked;
            iconColor = Colors.grey.shade600;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Nom035AdminSubmissionDetailScreen(
                      userData: widget.userData,
                      submissionId: int.tryParse('$submissionId') ?? 0,
                    ),
                  ),
                );
                await _load();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10, top: 2),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 6,
                            spacing: 8,
                            children: [
                              SizedBox(
                                width: 700,
                                child: Text(
                                  name.isEmpty ? 'Usuario #$userId' : name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              _chip(
                                _statusLabel(st),
                                _statusBg(st),
                                _statusFg(st),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 14,
                            runSpacing: 4,
                            children: [
                              if (emp.isNotEmpty)
                                Text(
                                  'Empleado: $emp',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              Text(
                                'Área: $area',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                'Puesto: $position',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Score: ${score ?? "-"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              _chip(
                                riskLevel.isEmpty ? 'Sin riesgo' : riskLevel,
                                _riskBg(riskLevel),
                                _riskFg(riskLevel),
                              ),
                              if (submittedAt.isNotEmpty)
                                Text(
                                  'Enviado: $submittedAt',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pendingList() {
    if (pendingUsers.isEmpty) {
      return const Center(
        child: Text('Todos los usuarios ya contestaron este ciclo.'),
      );
    }

    final paged = _pendingPaged;

    if (paged.isEmpty) {
      return const Center(
        child: Text('No hay usuarios pendientes en esta página.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: paged.length,
        itemBuilder: (context, i) {
          final u = _asMap(paged[i]);

          final name = _s(u['name']);
          final emp = _s(u['employee_number']);
          final area = _resolveArea(
            u['area'] ?? u['area_id'] ?? u['area_name'],
          );
          final position = _resolvePosition(
            u['position'] ?? u['position_id'] ?? u['position_name'],
          );
          final userId = _s(u['id']);

          final submissionStatus = _s(u['status']).trim().toLowerCase();
          final viewed = submissionStatus == 'available' ||
              submissionStatus == 'in_progress' ||
              submissionStatus == 'submitted';
          final answered = submissionStatus == 'submitted';

          String pendingLabel = 'No visto';
          Color pendingBg = Colors.red.shade100;
          Color pendingFg = Colors.red.shade900;
          IconData pendingIcon = Icons.visibility_off_outlined;
          Color iconBg = Colors.red.shade100;
          Color iconFg = Colors.red.shade800;

          if (viewed && !answered) {
            pendingLabel =
                submissionStatus == 'in_progress' ? 'En curso' : 'Visto';
            pendingBg = Colors.orange.shade100;
            pendingFg = Colors.orange.shade900;
            pendingIcon = submissionStatus == 'in_progress'
                ? Icons.timelapse_outlined
                : Icons.remove_red_eye_outlined;
            iconBg = Colors.orange.shade100;
            iconFg = Colors.orange.shade800;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: iconBg,
                child: Icon(
                  pendingIcon,
                  color: iconFg,
                  size: 20,
                ),
              ),
              title: Text(
                name.isEmpty ? 'Usuario #$userId' : name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (emp.isNotEmpty)
                        Text(
                          'Empleado: $emp',
                          style: const TextStyle(fontSize: 13),
                        ),
                      Text(
                        'Área: $area',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Puesto: $position',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: _chip(pendingLabel, pendingBg, pendingFg),
            ),
          );
        },
      ),
    );
  }

  Widget _evidenceOnlyTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Nom035AdminEvidenceScreen(
        userData: widget.userData,
        cycleId: widget.cycleId,
        cycleTitle: widget.cycleTitle ?? '',
      ),
    );
  }

  Widget _actionPlanTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Nom035AdminActionPlanScreen(
        userData: widget.userData,
        cycleId: widget.cycleId,
        cycleTitle: widget.cycleTitle ?? '',
      ),
    );
  }

  Widget _auditTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Nom035AuditScreen(
        userData: widget.userData,
        cycleId: widget.cycleId,
        cycleTitle: widget.cycleTitle,
        rawPayload: rawPayload,
        items: items,
        pendingUsers: pendingUsers,
        areasMap: _areasMap,
        embedded: true,
        onRefreshParent: _load,
      ),
    );
  }

  Widget _pager({required bool canPrev, required bool canNext}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Text('Total: $_currentTabTotal'),
          const Spacer(),
          OutlinedButton(
            onPressed: canPrev
                ? () {
                    setState(() => page--);
                    _load();
                  }
                : null,
            child: const Text('Anterior'),
          ),
          const SizedBox(width: 8),
          Text('Página $page'),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: canNext
                ? () {
                    setState(() => page++);
                    _load();
                  }
                : null,
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }
}