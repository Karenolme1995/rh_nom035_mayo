import 'package:flutter/material.dart';

class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aviso de Privacidad'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor, // 🔥 CLAVE
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aviso de Privacidad',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'En cumplimiento con la normativa aplicable en materia de protección de datos personales...',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),

                _sectionTitle(context, '1. Datos recopilados'),
                _sectionText(context,
                    'Podrán recopilarse datos como nombre, número de empleado...'),

                _sectionTitle(context, '2. Finalidad del tratamiento'),
                _sectionText(context,
                    'La información será utilizada para control interno...'),

                _sectionTitle(context, '3. Confidencialidad'),
                _sectionText(context,
                    'La empresa adopta medidas de seguridad...'),

                _sectionTitle(context, '4. Derechos del titular'),
                _sectionText(context,
                    'El titular de los datos podrá solicitar revisión...'),

                _sectionTitle(context, '5. Cambios al aviso'),
                _sectionText(context,
                    'La empresa se reserva el derecho de modificar...'),

                const SizedBox(height: 20),
                Text(
                  '© Todos los derechos reservados.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _sectionText(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}