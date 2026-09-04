// lib/core/design_system/widgets/app_dialogs.dart
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'app_button.dart';

export 'app_receipt_preview_dialog.dart';

/// Modal base estandarizado para todos los pop-ups del sistema.
class AppModalDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final double maxWidth;

  const AppModalDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.onClose,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusXl,
        side: BorderSide(color: AppColors.borderCard),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Divider(color: AppColors.borderSubtle, height: 16),
              Flexible(
                child: SingleChildScrollView(child: content),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo de confirmación para acciones críticas (anular, eliminar, blanquear).
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDanger;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.isDanger = true,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AppModalDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDanger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                color: isDanger ? AppColors.danger : AppColors.primaryYellow,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton(
          text: cancelText,
          variant: AppButtonVariant.ghost,
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton(
          text: confirmText,
          variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
        ),
      ],
    );
  }
}

/// Diálogo modal de venta exitosa con checkmark gigante y accesos rápidos.
class AppSuccessDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String totalFormatted;
  final VoidCallback? onPrintDuplicate;
  final VoidCallback? onSendWhatsApp;
  final VoidCallback? onNewSale;

  const AppSuccessDialog({
    super.key,
    this.title = '¡Venta Registrada!',
    required this.subtitle,
    required this.totalFormatted,
    this.onPrintDuplicate,
    this.onSendWhatsApp,
    this.onNewSale,
  });

  @override
  Widget build(BuildContext context) {
    return AppModalDialog(
      title: 'Comprobante Confirmado',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.h3),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTypography.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            totalFormatted,
            style: AppTypography.currencyLarge.copyWith(color: AppColors.primaryYellow),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Duplicado',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.print_rounded,
                  onPressed: onPrintDuplicate,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  text: 'WhatsApp',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.share_rounded,
                  onPressed: onSendWhatsApp,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        AppButton(
          text: 'Nueva Venta',
          fullWidth: true,
          onPressed: onNewSale ?? () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
