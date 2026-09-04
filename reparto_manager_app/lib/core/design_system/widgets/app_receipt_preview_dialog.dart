// lib/core/design_system/widgets/app_receipt_preview_dialog.dart
import 'package:flutter/material.dart';
import '../tokens/app_spacing.dart';
import 'app_button.dart';
import 'app_dialogs.dart';

/// Vista previa de ticket térmico BLE/RawBT con botón "CARGAR EN POS".
class AppReceiptPreviewDialog extends StatelessWidget {
  final String businessName;
  final String receiptNumber;
  final String clientName;
  final List<String> itemsLines;
  final String totalFormatted;
  final VoidCallback? onPrint;
  final VoidCallback? onLoadInPos;

  const AppReceiptPreviewDialog({
    super.key,
    required this.businessName,
    required this.receiptNumber,
    required this.clientName,
    required this.itemsLines,
    required this.totalFormatted,
    this.onPrint,
    this.onLoadInPos,
  });

  @override
  Widget build(BuildContext context) {
    return AppModalDialog(
      title: 'Ticket #$receiptNumber',
      content: Column(
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppSpacing.borderRadiusMd,
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  businessName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  '--------------------------------',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black),
                ),
                Text('Cliente: $clientName', style: const TextStyle(color: Colors.black, fontSize: 13)),
                Text('Ticket Nro: $receiptNumber', style: const TextStyle(color: Colors.black, fontSize: 13)),
                const Text(
                  '--------------------------------',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black),
                ),
                ...itemsLines.map((line) => Text(
                      line,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    )),
                const Text(
                  '--------------------------------',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black),
                ),
                Text(
                  'TOTAL: $totalFormatted',
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (onLoadInPos != null)
            AppButton(
              text: 'CARGAR EN POS',
              variant: AppButtonVariant.primary,
              icon: Icons.point_of_sale_rounded,
              fullWidth: true,
              onPressed: onLoadInPos,
            ),
        ],
      ),
      actions: [
        AppButton(
          text: 'Imprimir Ticket',
          icon: Icons.print_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: onPrint,
        ),
      ],
    );
  }
}
