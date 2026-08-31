import 'package:flutter/material.dart';
import '../../design_system.dart';

/// Pestaña de Checkout, Carrito, Vuelto y Diálogos de Venta.
class ShowroomCheckoutTab extends StatefulWidget {
  const ShowroomCheckoutTab({super.key});

  @override
  State<ShowroomCheckoutTab> createState() => _ShowroomCheckoutTabState();
}

class _ShowroomCheckoutTabState extends State<ShowroomCheckoutTab> {
  int _cartQty1 = 2;
  int _cartQty2 = 1;
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;

  @override
  Widget build(BuildContext context) {
    final saleTotal = (4500.0 * _cartQty1) + (3200.0 * _cartQty2);

    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Carrito de Venta (CartItemRow)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        CartItemRow(
          productName: 'Soda Sifón 1.5L (Cajón x6)',
          unitPrice: 4500.0,
          quantity: _cartQty1,
          onQuantityChanged: (q) => setState(() => _cartQty1 = q),
          onRemove: () => AppSnackBar.showError(context, 'Sifón eliminado'),
        ),
        CartItemRow(
          productName: 'Bidón 20 Litros Retornable',
          unitPrice: 3200.0,
          quantity: _cartQty2,
          onQuantityChanged: (q) => setState(() => _cartQty2 = q),
          onRemove: () => AppSnackBar.showError(context, 'Bidón eliminado'),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Forma de Pago', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        PaymentMethodSelector(
          selectedMethod: _selectedPayment,
          onMethodChanged: (m) => setState(() => _selectedPayment = m),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Calculadora de Vuelto', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        QuickCashCalculator(
          totalToPay: saleTotal,
          onAmountSelected: (amt) {
            final vuelto = amt - saleTotal;
            AppSnackBar.showSuccess(context, vuelto >= 0 ? 'Vuelto: \$$vuelto' : 'Monto menor al total');
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Desglose Contable', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        PaymentSummaryBox(
          previousBalance: 5000.0,
          saleTotal: saleTotal,
          paidAmount: _selectedPayment == PaymentMethod.pendiente ? 0.0 : saleTotal,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Diálogos del Sistema', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              text: 'Modal Éxito',
              icon: Icons.check_circle_outline,
              onPressed: () => _openSuccessDialog(saleTotal),
            ),
            AppButton(
              text: 'Ver Ticket',
              variant: AppButtonVariant.secondary,
              icon: Icons.receipt_long_rounded,
              onPressed: _openReceiptDialog,
            ),
            AppButton(
              text: 'Confirmar Anulación',
              variant: AppButtonVariant.danger,
              icon: Icons.warning_amber_rounded,
              onPressed: _openConfirmDialog,
            ),
          ],
        ),
      ],
    );
  }

  void _openSuccessDialog(double total) {
    showDialog(
      context: context,
      builder: (_) => AppSuccessDialog(
        subtitle: 'Cliente: Almacén Don Carlos',
        totalFormatted: '\$${total.toInt()}',
        onPrintDuplicate: () => AppSnackBar.showSuccess(context, 'Imprimiendo duplicado...'),
        onSendWhatsApp: () => AppSnackBar.showSuccess(context, 'Enviando WhatsApp...'),
      ),
    );
  }

  void _openReceiptDialog() {
    showDialog(
      context: context,
      builder: (_) => AppReceiptPreviewDialog(
        businessName: 'María Belén',
        receiptNumber: '0001-00049281',
        clientName: 'Almacén Don Carlos',
        itemsLines: const [
          '2x Soda Sifón 1.5L        \$9.000',
          '1x Bidón 20L Retornable    \$3.200',
        ],
        totalFormatted: '\$12.200',
        onPrint: () => AppSnackBar.showSuccess(context, 'Ticket impreso'),
        onLoadInPos: () => AppSnackBar.showSuccess(context, 'Cargado en POS'),
      ),
    );
  }

  void _openConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: '¿Anular Venta?',
        message: 'Esta acción revertirá los saldos y el stock de camioneta.',
        onConfirm: () => AppSnackBar.showError(context, 'Venta anulada'),
      ),
    );
  }
}
