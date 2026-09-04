import 'package:flutter/material.dart';
import '../../../core/design_system/theme_manager.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/app_button.dart';
import '../../../core/design_system/widgets/app_dialogs.dart';
import '../../../core/design_system/widgets/app_text_field.dart';
import '../../../core/design_system/widgets/feedback_and_metrics_widgets.dart';
import '../session_manager.dart';

/// Diálogo modal para solicitar envío de enlace de activación o restablecimiento de contraseña.
class ForgotPasswordDialog extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordDialog({super.key, this.initialEmail});

  static Future<void> show(BuildContext context, {String? initialEmail}) {
    return showDialog<void>(
      context: context,
      builder: (context) => ForgotPasswordDialog(initialEmail: initialEmail),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Ingrese su correo electrónico.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await SessionManager.instance.sendInvitationOrResetEmail(
      email,
      isSelfPasswordReset: true,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        setState(() => _errorMessage = failure.message);
      },
      (_) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(
          context,
          'Se ha enviado el enlace de activación a $email',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModalDialog(
      title: 'Activar / Recuperar Cuenta',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ingrese el correo de su cuenta para recibir un enlace seguro de activación o cambio de contraseña.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Correo Electrónico',
            hintText: 'ejemplo@correo.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSendEmail(),
            prefixIcon: Icon(
              Icons.email,
              color: ThemeManager.instance.currentPalette.primary,
              size: 22,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.danger),
            ),
          ],
        ],
      ),
      actions: [
        AppButton(
          text: 'Cancelar',
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          text: 'Enviar Enlace',
          variant: AppButtonVariant.primary,
          isLoading: _isLoading,
          onPressed: _handleSendEmail,
        ),
      ],
    );
  }
}
