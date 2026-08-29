import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../client.dart';
import '../../../models/sale.dart';
import '../../../models/payment.dart';
import '../../../models/manual_debt.dart';
import 'clients_actions_v2.dart';
import '../../printer/printer_actions.dart';
import '../../pos/pos_actions.dart';
import '../../shell/app_shell.dart';

class ClientDetailsDialogsV2 {
  /// Diálogo para Ajuste Manual de Saldo (A favor o En contra) con isAdjustment: true en DB
  static void showAdjustmentDialog(BuildContext context, Client client, double currentBalance) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool isAFavor = true; // true = disminuye deuda, false = aumenta deuda

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Row(
                children: [
                  Icon(Icons.build, color: AppTheme.primaryYellow),
                  SizedBox(width: 8),
                  Text("Ajuste Manual de Saldo", style: TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Utilice esta opción para corregir un desfase puntual en el saldo del cliente. Se guardará con una marca especial (isAdjustment: true) para auditoría.",
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("A Favor (-Deuda)", style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
                            value: true,
                            groupValue: isAFavor,
                            onChanged: (v) => setDialogState(() => isAFavor = v!),
                            activeColor: Colors.greenAccent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text("En Contra (+Deuda)", style: TextStyle(fontSize: 11, color: AppTheme.danger)),
                            value: false,
                            groupValue: isAFavor,
                            onChanged: (v) => setDialogState(() => isAFavor = v!),
                            activeColor: AppTheme.danger,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Monto del Ajuste (\$)", prefixIcon: Icon(Icons.attach_money)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(labelText: "Motivo / Razón del Ajuste", prefixIcon: Icon(Icons.note)),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text("Fecha del Ajuste"),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryYellow),
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (dt != null) setDialogState(() => selectedDate = dt);
                      },
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context), 
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: isSaving ? null : () async {
                    final double amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (amount > 0) {
                      setDialogState(() => isSaving = true);
                      try {
                        if (isAFavor) {
                          await ClientsActionsV2().addAdjustmentPayment(
                            clientId: client.id,
                            amount: amount,
                            date: selectedDate,
                            note: noteCtrl.text.trim(),
                          );
                        } else {
                          await ClientsActionsV2().addAdjustmentDebt(
                            clientId: client.id,
                            amount: amount,
                            date: selectedDate,
                            note: noteCtrl.text.trim(),
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("GUARDAR AJUSTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
        );
      }
    );
  }

  /// Diálogo Completo para ver Detalle de Venta
  static void showSaleDetailsDialog(BuildContext context, Sale sale, Client client) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    final double prev = sale.previousBalance ?? 0.0;
    final double rem = sale.remainingBalance ?? (prev + (sale.total - sale.paidAmount));
    final bool hasAudit = sale.previousBalance != null;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Detalle de Venta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryYellow)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.primaryYellow),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text("Cliente: ${client.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(sale.date)}", style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              
              const Text("Productos Comprados:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: sale.items.map((item) {
                      final vName = item.selectedVariant?.name != null && item.selectedVariant!.name.isNotEmpty ? ' (${item.selectedVariant!.name})' : '';
                      final double itemTotal = item.unitPrice * item.quantity;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text("${item.quantity}x ${item.product.name}$vName", style: const TextStyle(fontSize: 14)),
                                ),
                                Text("${fmt.format(item.unitPrice)} c/u  •  ${fmt.format(itemTotal)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          if (item.manualDiscount > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, bottom: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_offer, color: Colors.greenAccent, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Desc. manual (${((item.manualDiscount / item.unitPrice) * 100).toStringAsFixed(0)}%)",
                                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    "-${fmt.format(item.manualDiscount * item.quantity)}",
                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL VENTA ACTUAL:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(fmt.format(sale.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.primaryYellow)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Saldo Anterior Acumulado:", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Text(
                    fmt.format(prev),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: prev > 0 ? AppTheme.danger : Colors.greenAccent),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              const Text("Detalle de Pago:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 6),
              if ((sale.cashAmount ?? 0) > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("  • Entregó en Efectivo:", style: TextStyle(fontSize: 13, color: Colors.greenAccent)),
                    Text(fmt.format(sale.cashAmount ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.greenAccent)),
                  ],
                ),
              if ((sale.transferAmount ?? 0) > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("  • Entregó en Transferencia:", style: TextStyle(fontSize: 13, color: Colors.lightBlueAccent)),
                    Text(fmt.format(sale.transferAmount ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.lightBlueAccent)),
                  ],
                ),
              if ((sale.cashAmount ?? 0) == 0 && (sale.transferAmount ?? 0) == 0 && sale.paidAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("  • Método: ${sale.paymentMethod}", style: const TextStyle(fontSize: 13)),
                    Text(fmt.format(sale.paidAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: sale.paymentMethod == 'Transferencia' ? Colors.lightBlueAccent : Colors.greenAccent)),
                  ],
                ),
              if (sale.paidAmount == 0)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("  • Método: Pendiente", style: TextStyle(fontSize: 13, color: AppTheme.danger)),
                    Text("\$0", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.danger)),
                  ],
                ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("TOTAL RESTANTE ACUMULADO:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    fmt.format(rem),
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: rem > 0 ? AppTheme.danger : Colors.greenAccent),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        POSActions().loadOrderIntoPos(client, sale.items);
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                        AppShell.globalKey.currentState?.switchTab(0);
                      },
                      icon: const Icon(Icons.shopping_cart_checkout, color: Colors.black, size: 16),
                      label: const Text("CARGAR EN POS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if ((sale.total - sale.paidAmount) > 0) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCollectSaleTicketDialog(context, sale, client);
                        },
                        icon: const Icon(Icons.attach_money, color: Colors.black, size: 16),
                        label: const Text("COBRAR TICKET", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        PrinterActions.printTicket(
                          sale.items,
                          sale.total - sale.discountAmount,
                          sale.discountAmount,
                          sale.appliedPromos,
                          sale.total,
                          sale.exchanges,
                          sale.paidAmount,
                          sale.paymentMethod,
                          client,
                          prev,
                          false,
                          true,
                        );
                      },
                      icon: const Icon(Icons.print, color: Colors.black, size: 16),
                      label: const Text("REIMPRIMIR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDeleteSale(context, sale),
                      icon: const Icon(Icons.delete, color: Colors.white, size: 16),
                      label: const Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo para cobrar una Venta de Mercadería específica elegida por el usuario
  static void _showCollectSaleTicketDialog(BuildContext context, Sale sale, Client client) {
    final double pending = sale.total - sale.paidAmount;
    final amountCtrl = TextEditingController(text: pending > 0 ? pending.toStringAsFixed(0) : '');
    String selectedMethod = 'Efectivo';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Cobrar Ticket (${sale.clientName})",
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total del Ticket: \$${sale.total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text("Pagado Actualmente: \$${sale.paidAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, color: Colors.greenAccent)),
                    Text("Deuda Pendiente Ticket: \$${pending.toStringAsFixed(0)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.danger)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: "Monto a Cobrar (\$)",
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Método de Pago:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Efectivo", style: TextStyle(fontSize: 12)),
                            value: 'Efectivo',
                            groupValue: selectedMethod,
                            onChanged: (v) => setDialogState(() => selectedMethod = v!),
                            activeColor: AppTheme.primaryYellow,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text("Transferencia", style: TextStyle(fontSize: 12)),
                            value: 'Transferencia',
                            groupValue: selectedMethod,
                            onChanged: (v) => setDialogState(() => selectedMethod = v!),
                            activeColor: Colors.lightBlueAccent,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text("Fecha del Pago", style: TextStyle(fontSize: 13)),
                      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(selectedDate), style: const TextStyle(color: AppTheme.primaryYellow)),
                      trailing: const Icon(Icons.calendar_today, color: AppTheme.primaryYellow, size: 20),
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (dt != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          setDialogState(() {
                            selectedDate = DateTime(
                              dt.year, dt.month, dt.day,
                              time?.hour ?? selectedDate.hour,
                              time?.minute ?? selectedDate.minute,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                  onPressed: isSaving ? null : () async {
                    final double amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (amount > 0) {
                      setDialogState(() => isSaving = true);
                      try {
                        await ClientsActionsV2().collectTicketSale(
                          sale: sale,
                          amount: amount,
                          method: selectedMethod,
                          date: selectedDate,
                        );
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("REGISTRAR COBRO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Diálogo Completo para ver Detalle de Pago (con Azul Celeste para transferencias y botón blanco sobre rojo)
  static void showPaymentDetailsDialog(BuildContext context, Payment payment, Client client) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    final double prev = payment.previousBalance ?? 0.0;
    final double rem = payment.remainingBalance ?? 0.0;
    final bool hasAudit = payment.previousBalance != null;

    Color amountColor = Colors.greenAccent;
    if (payment.isAdjustment == true) {
      amountColor = Colors.orange;
    } else if (payment.method == 'Transferencia') {
      amountColor = Colors.lightBlueAccent;
    } else if (payment.method == 'Efectivo') {
      amountColor = Colors.greenAccent;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    payment.isAdjustment == true ? "Detalle de Ajuste" : "Detalle de Pago", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryYellow),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.primaryYellow),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text("Cliente: ${client.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(payment.date)}", style: const TextStyle(color: AppTheme.textSecondary)),
              if (payment.note != null && payment.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("Nota / Motivo: ${payment.note}", style: const TextStyle(color: Colors.orange, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              
              const Text("Detalle del Pago:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Monto Entregado:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(fmt.format(payment.amount), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: amountColor)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Método: ${payment.method}", style: const TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeletePayment(context, payment);
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("ELIMINAR PAGO / AJUSTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Diálogo Completo para ver Detalle de Deuda Antigua / Ajuste En Contra
  static void showDebtDetailsDialog(BuildContext context, ManualDebt debt, Client client) {
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    debt.isAdjustment == true ? "Detalle de Ajuste En Contra" : "Detalle de Deuda", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryYellow),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.primaryYellow),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Text("Cliente: ${client.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text("Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(debt.date)}", style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text("Descripción: ${debt.description}", style: const TextStyle(color: AppTheme.textPrimary)),
              if (debt.note != null && debt.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text("Nota: ${debt.note}", style: const TextStyle(color: Colors.orange, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Monto Deuda Sumada:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(fmt.format(debt.amount), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: debt.isAdjustment == true ? Colors.orange : AppTheme.danger)),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmDeleteDebt(context, debt);
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("ELIMINAR DEUDA / AJUSTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _confirmDeleteSale(BuildContext context, Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Eliminar Venta", style: TextStyle(color: Colors.redAccent)),
        content: const Text("¿Estás seguro de eliminar este ticket de venta de forma permanente? Se ajustará el saldo del cliente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context); // cerrar detalle
              await ClientsActionsV2().deleteSale(sale.id);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _confirmDeletePayment(BuildContext context, Payment payment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Eliminar Pago", style: TextStyle(color: Colors.redAccent)),
        content: const Text("¿Estás seguro de eliminar este pago de forma permanente? El saldo del cliente aumentará."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ClientsActionsV2().deletePayment(payment.id, payment.clientId, payment.amount);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void _confirmDeleteDebt(BuildContext context, ManualDebt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Eliminar Deuda", style: TextStyle(color: Colors.redAccent)),
        content: const Text("¿Estás seguro de eliminar esta deuda de forma permanente? El saldo del cliente disminuye."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ClientsActionsV2().deleteManualDebt(debt.id, debt.clientId, debt.amount);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
