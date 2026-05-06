import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/notices_service.dart';

class Nom035AdminStpsFileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int cycleId;
  final String cycleTitle;

  const Nom035AdminStpsFileScreen({
    super.key,
    required this.userData,
    required this.cycleId,
    required this.cycleTitle,
  });

  @override
  State<Nom035AdminStpsFileScreen> createState() =>
      _Nom035AdminStpsFileScreenState();
}

class _Nom035AdminStpsFileScreenState
    extends State<Nom035AdminStpsFileScreen> {
  bool loading = true;
  bool generatingPdf = false;
  String? error;
  Map<String, dynamic> data = {};

  static const String _companyName = 'VITRACOAT PINTURAS EN POLVO SA DE CV';
  static const String _logoAsset = 'assets/images/vitracoat.png';
  static const String _policyAsset = 'assets/docs/POLITICA VITRACOAT.PDF';

  bool get _isWeb => kIsWeb;

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

  String _safeFileName(String text) {
    return text
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await NoticesService().getNom035AuditStpsFile(widget.cycleId);
      setState(() {
        data = res;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> _rebuildAuditFile() async {
    try {
      final res = await NoticesService().rebuildNom035AuditFile(
        cycleId: widget.cycleId,
        generatedByUserId: _asInt(widget.userData['id']),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['is_ready'] == true
                ? 'Expediente STPS listo'
                : 'Expediente recalculado, aún incompleto',
          ),
        ),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _openPolicyFromAssets() async {
    try {
      final data = await rootBundle.load(_policyAsset);
      final bytes = data.buffer.asUint8List();

      if (_isWeb) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: 'POLITICA_VITRACOAT.pdf',
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/POLITICA_VITRACOAT.pdf');

      await file.writeAsBytes(bytes, flush: true);

      final result = await OpenFilex.open(file.path);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir la política: ${result.message}'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir política: $e')),
      );
    }
  }

  Future<void> _generateAuditPdf() async {
    try {
      setState(() => generatingPdf = true);

      final cycle = _asMap(data['cycle']);
      final stats = _asMap(data['submission_stats']);
      final compliance = _asMap(data['compliance']);
      final actionPlans = _asList(data['action_plans']);
      final evidences = _asList(data['evidences']);
      final riskDistribution = _asList(data['risk_distribution']);

      final ready = data['ready'] == true;
      final cycleTitle =
          _s(cycle['title']).isEmpty ? widget.cycleTitle : _s(cycle['title']);
      final cycleYear = _s(cycle['year']).isEmpty
          ? DateTime.now().year.toString()
          : _s(cycle['year']);
      final cycleStatus = _s(cycle['status']).isEmpty ? '—' : _s(cycle['status']);
      final notes = _s(data['notes']);

      final policyUploaded = compliance['policy_uploaded'] == true;
      final evidenceUploaded = compliance['evidence_uploaded'] == true;
      final resultsGenerated = compliance['results_generated'] == true;
      final actionPlanCreated = compliance['action_plan_created'] == true;
      final stpsFileReady = compliance['stps_file_ready'] == true;

      final logoData = await rootBundle.load(_logoAsset);
      final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

      final pdf = pw.Document();

      pw.Widget checklistRow(String label, bool ok) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: ok ? PdfColors.green300 : PdfColors.orange300,
            ),
            color: ok ? PdfColors.green50 : PdfColors.orange50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                ok ? 'OK' : 'PENDIENTE',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: ok ? PdfColors.green800 : PdfColors.orange800,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(child: pw.Text(label)),
            ],
          ),
        );
      }

      pw.Widget sectionTitle(String text) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 8),
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 72,
                  height: 72,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _companyName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'EXPEDIENTE STPS NOM-035',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Ciclo: $cycleTitle'),
                      pw.Text('Año: $cycleYear'),
                      pw.Text('Estatus del ciclo: $cycleStatus'),
                      pw.Text(
                        'Estatus del expediente: '
                        '${ready ? 'LISTO PARA AUDITORÍA' : 'INCOMPLETO'}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: ready ? PdfColors.green800 : PdfColors.orange800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(),

            sectionTitle('1. Checklist de cumplimiento'),
            checklistRow('Política cargada', policyUploaded),
            checklistRow('Evidencia cargada', evidenceUploaded),
            checklistRow('Resultados generados', resultsGenerated),
            checklistRow('Plan de acción creado', actionPlanCreated),
            checklistRow('Expediente STPS listo', stpsFileReady),

            sectionTitle('2. Datos generales'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
              },
              children: [
                pw.TableRow(children: [
                  _pdfCell('Empresa', bold: true),
                  _pdfCell(_companyName),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Ciclo', bold: true),
                  _pdfCell(cycleTitle),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Año', bold: true),
                  _pdfCell(cycleYear),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Estatus del ciclo', bold: true),
                  _pdfCell(cycleStatus),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Fecha generación', bold: true),
                  _pdfCell(DateTime.now().toString().split('.').first),
                ]),
              ],
            ),

            sectionTitle('3. Resumen estadístico'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(children: [
                  _pdfCell('Asignados', bold: true),
                  _pdfCell('${_asInt(stats['total_assigned'])}'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Enviados', bold: true),
                  _pdfCell('${_asInt(stats['submitted_count'])}'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('En curso', bold: true),
                  _pdfCell('${_asInt(stats['in_progress_count'])}'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Disponibles', bold: true),
                  _pdfCell('${_asInt(stats['available_count'])}'),
                ]),
                pw.TableRow(children: [
                  _pdfCell('Promedio score', bold: true),
                  _pdfCell(_asDouble(stats['avg_score']).toStringAsFixed(1)),
                ]),
              ],
            ),

            sectionTitle('4. Distribución de riesgo'),
            if (riskDistribution.isEmpty)
              pw.Text('No hay distribución de riesgo disponible.')
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _pdfCell('Nivel de riesgo', bold: true),
                      _pdfCell('Total', bold: true),
                    ],
                  ),
                  ...riskDistribution.map((e) {
                    final m = _asMap(e);
                    return pw.TableRow(
                      children: [
                        _pdfCell(
                          _s(m['risk_level']).isEmpty ? '—' : _s(m['risk_level']),
                        ),
                        _pdfCell('${_asInt(m['total'])}'),
                      ],
                    );
                  }),
                ],
              ),

            sectionTitle('5. Política'),
            pw.Text(
              policyUploaded
                  ? 'Política registrada y considerada en el expediente.'
                  : 'Política pendiente de registrar.',
            ),
            pw.SizedBox(height: 4),
            pw.Text('Archivo esperado: POLITICA VITRACOAT.PDF'),

            sectionTitle('6. Planes de acción'),
            if (actionPlans.isEmpty)
              pw.Text('No hay planes de acción registrados.')
            else
              ...actionPlans.take(20).map((e) {
                final m = _asMap(e);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _s(m['action_title']).isEmpty
                            ? 'Sin título'
                            : _s(m['action_title']),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Departamento: ${_s(m['department_name']).isEmpty ? '—' : _s(m['department_name'])}',
                      ),
                      pw.Text(
                        'Estatus: ${_s(m['status']).isEmpty ? 'pendiente' : _s(m['status'])}',
                      ),
                    ],
                  ),
                );
              }),

            sectionTitle('7. Evidencias'),
            if (evidences.isEmpty)
              pw.Text('No hay evidencias registradas.')
            else
              ...evidences.take(30).map((e) {
                final m = _asMap(e);
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 6),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _s(m['title']).isEmpty ? 'Sin título' : _s(m['title']),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Tipo: ${_s(m['evidence_type']).isEmpty ? '—' : _s(m['evidence_type'])}',
                      ),
                      pw.Text(
                        'Archivo: ${_s(m['file_name']).isEmpty ? '—' : _s(m['file_name'])}',
                      ),
                    ],
                  ),
                );
              }),

            if (notes.isNotEmpty) ...[
              sectionTitle('8. Observaciones'),
              pw.Text(notes),
            ],
          ],
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'Expediente_STPS_NOM035_${_safeFileName(cycleTitle)}_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';

      if (_isWeb) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: fileName,
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        await OpenFilex.open(file.path);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF STPS generado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => generatingPdf = false);
      }
    }
  }

  pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _flag(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ok ? Colors.green.shade50 : Colors.orange.shade50,
        border: Border.all(
          color: ok ? Colors.green.shade200 : Colors.orange.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.pending,
            size: 18,
            color: ok ? Colors.green.shade700 : Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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

  Color _riskColor(String risk) {
    final r = risk.toLowerCase();
    if (r.contains('muy alto')) return Colors.red;
    if (r.contains('alto')) return Colors.orange;
    if (r.contains('medio')) return Colors.amber.shade700;
    if (r.contains('bajo')) return Colors.green;
    if (r.contains('nulo') || r.contains('sin riesgo')) {
      return Colors.blueGrey;
    }
    return Colors.grey;
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _companyHeader({
    required String companyName,
    required String logoAsset,
    required String cycleTitle,
    required String year,
    required bool ready,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final small = constraints.maxWidth < 640;

            final logo = Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(Icons.business, size: 38);
                  },
                ),
              ),
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Expediente STPS NOM-035',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text(cycleTitle),
                    ),
                    Chip(
                      avatar: const Icon(Icons.badge_outlined, size: 16),
                      label: Text(year.isEmpty ? 'Año —' : 'Año $year'),
                    ),
                    Chip(
                      avatar: Icon(
                        ready ? Icons.verified : Icons.warning_amber_rounded,
                        size: 16,
                        color: ready ? Colors.green : Colors.orange,
                      ),
                      label: Text(
                        ready ? 'Listo para auditoría' : 'Pendiente',
                      ),
                    ),
                  ],
                ),
              ],
            );

            if (small) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  logo,
                  const SizedBox(height: 14),
                  content,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                const SizedBox(width: 16),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cycle = _asMap(data['cycle']);
    final stats = _asMap(data['submission_stats']);
    final compliance = _asMap(data['compliance']);
    final actionPlans = _asList(data['action_plans']);
    final evidences = _asList(data['evidences']);
    final riskDistribution = _asList(data['risk_distribution']);

    final ready = data['ready'] == true;

    final cycleTitle =
        _s(cycle['title']).isEmpty ? widget.cycleTitle : _s(cycle['title']);
    final cycleYear = _s(cycle['year']);
    final cycleStatus = _s(cycle['status']);

    final policyUploaded = compliance['policy_uploaded'] == true;
    final evidenceUploaded = compliance['evidence_uploaded'] == true;
    final resultsGenerated = compliance['results_generated'] == true;
    final actionPlanCreated = compliance['action_plan_created'] == true;
    final stpsFileReady = compliance['stps_file_ready'] == true;

    Map<String, dynamic>? policyFile;
    for (final e in evidences) {
      final item = _asMap(e);
      final fileName = _s(item['file_name']).toLowerCase();
      final title = _s(item['title']).toLowerCase();
      final type = _s(item['evidence_type']).toLowerCase();

      final isPolicy = type == 'policy' ||
          fileName.contains('politica vitracoat.pdf') ||
          title.contains('politica vitracoat');

      if (isPolicy) {
        policyFile = item;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Expediente STPS - ${widget.cycleTitle}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _rebuildAuditFile,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalcular expediente',
          ),
          IconButton(
            onPressed: generatingPdf ? null : _generateAuditPdf,
            icon: generatingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Generar PDF STPS',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _companyHeader(
                        companyName: _companyName,
                        logoAsset: _logoAsset,
                        cycleTitle: cycleTitle,
                        year: cycleYear,
                        ready: ready,
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: Icon(
                            ready ? Icons.verified : Icons.warning_amber_rounded,
                            color: ready ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          title: Text(
                            ready
                                ? 'Expediente listo para auditoría'
                                : 'Expediente incompleto',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Ciclo: $cycleTitle\n'
                            'Año: ${cycleYear.isEmpty ? '—' : cycleYear}\n'
                            'Estatus ciclo: ${cycleStatus.isEmpty ? '—' : cycleStatus}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Checklist de cumplimiento',
                        icon: Icons.checklist_rounded,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _flag('Política cargada', policyUploaded),
                            _flag('Evidencia cargada', evidenceUploaded),
                            _flag('Resultados generados', resultsGenerated),
                            _flag('Plan de acción creado', actionPlanCreated),
                            _flag('Expediente STPS', stpsFileReady),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        title: 'Datos de presentación para auditoría',
                        icon: Icons.apartment,
                        child: Column(
                          children: [
                            _infoTile(
                              icon: Icons.business,
                              label: 'Empresa',
                              value: _companyName,
                            ),
                            const SizedBox(height: 10),
                            _infoTile(
                              icon: Icons.image_outlined,
                              label: 'Logo',
                              value: _logoAsset,
                            ),
                            const SizedBox(height: 10),
                            _infoTile(
                              icon: Icons.policy_outlined,
                              label: 'Política',
                              value: policyFile != null
                                  ? (_s(policyFile['file_name']).isEmpty
                                      ? 'POLITICA VITRACOAT.PDF'
                                      : _s(policyFile['file_name']))
                                  : 'Pendiente de cargar',
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _openPolicyFromAssets,
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Ver política'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        title: 'Resumen del ciclo',
                        icon: Icons.analytics_outlined,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 220,
                              child: _infoTile(
                                icon: Icons.group_outlined,
                                label: 'Asignados',
                                value: '${_asInt(stats['total_assigned'])}',
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: _infoTile(
                                icon: Icons.task_alt_outlined,
                                label: 'Enviados',
                                value: '${_asInt(stats['submitted_count'])}',
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: _infoTile(
                                icon: Icons.timelapse_outlined,
                                label: 'En curso',
                                value: '${_asInt(stats['in_progress_count'])}',
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: _infoTile(
                                icon: Icons.inventory_2_outlined,
                                label: 'Disponibles',
                                value: '${_asInt(stats['available_count'])}',
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: _infoTile(
                                icon: Icons.score_outlined,
                                label: 'Promedio score',
                                value:
                                    _asDouble(stats['avg_score']).toStringAsFixed(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        title: 'Distribución de riesgo',
                        icon: Icons.stacked_bar_chart_outlined,
                        child: riskDistribution.isEmpty
                            ? const Text('No hay distribución de riesgo disponible.')
                            : Column(
                                children: riskDistribution.map((e) {
                                  final m = _asMap(e);
                                  final riskLevel = _s(m['risk_level']).isEmpty
                                      ? '—'
                                      : _s(m['risk_level']);
                                  final total = _asInt(m['total']);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          _riskColor(riskLevel).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _riskColor(riskLevel)
                                            .withOpacity(0.25),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 12,
                                          color: _riskColor(riskLevel),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            riskLevel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '$total',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        title: 'Planes de acción (${actionPlans.length})',
                        icon: Icons.assignment_outlined,
                        child: actionPlans.isEmpty
                            ? const Text('No hay planes de acción.')
                            : Column(
                                children: actionPlans.take(10).map((e) {
                                  final m = _asMap(e);
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '• ${_s(m['action_title']).isEmpty ? 'Sin título' : _s(m['action_title'])}\n'
                                      'Departamento: ${_s(m['department_name']).isEmpty ? '—' : _s(m['department_name'])}\n'
                                      'Estatus: ${_s(m['status']).isEmpty ? 'pendiente' : _s(m['status'])}',
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        title: 'Evidencias (${evidences.length})',
                        icon: Icons.folder_copy_outlined,
                        child: evidences.isEmpty
                            ? const Text('No hay evidencias.')
                            : Column(
                                children: evidences.take(10).map((e) {
                                  final m = _asMap(e);
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '• ${_s(m['title']).isEmpty ? 'Sin título' : _s(m['title'])}\n'
                                      'Tipo: ${_s(m['evidence_type']).isEmpty ? '—' : _s(m['evidence_type'])}\n'
                                      'Archivo: ${_s(m['file_name']).isEmpty ? '—' : _s(m['file_name'])}',
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: generatingPdf ? null : _generateAuditPdf,
        icon: generatingPdf
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Generar PDF STPS'),
      ),
    );
  }
}