import 'package:flutter/material.dart';

class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
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
                /// TITULO
                Text(
                  'Términos y Condiciones',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 16),

                /// INTRO
                Text(
                  'El uso de esta aplicación implica la aceptación de los siguientes términos y condiciones establecidos por la empresa.',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 14),

                _sectionTitle(context, '1. Uso de la aplicación'),
                _sectionText(context,
                    'Esta aplicación es para uso interno de la empresa y debe ser utilizada únicamente para fines laborales autorizados.'),

                _sectionTitle(context, '2. Privacidad'),
                _sectionText(context,
                    'Los datos personales serán tratados conforme a la normativa vigente y al aviso de privacidad correspondiente.'),

                _sectionTitle(context, '3. Responsabilidad del usuario'),
                _sectionText(context,
                    'El usuario es responsable del uso de su cuenta, así como de mantener la confidencialidad de sus credenciales.'),

                _sectionTitle(context, '4. Seguridad'),
                _sectionText(context,
                    'Está prohibido compartir información de acceso o realizar acciones que comprometan la seguridad del sistema.'),

                _sectionTitle(context, '5. Modificaciones'),
                _sectionText(context,
                    'La empresa se reserva el derecho de modificar estos términos en cualquier momento sin previo aviso.'),

                const SizedBox(height: 20),

                /// FOOTER
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