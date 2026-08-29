import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../client.dart';
import 'clients_actions_v2.dart';
import 'client_dialogs_v2.dart';
import 'client_details_view_v2.dart';

class ClientCardItemV2 extends StatelessWidget {
  final Client client;
  final bool isMobile;
  final bool isGrid;
  final bool isPhone;

  const ClientCardItemV2({
    super.key,
    required this.client,
    required this.isMobile,
    required this.isGrid,
    this.isPhone = false,
  });

  void _handleDeleteClient(BuildContext context, double calculatedBalance) {
    if (calculatedBalance != 0) {
      final String formattedBal = calculatedBalance > 0 
          ? "\$${calculatedBalance.toStringAsFixed(0)}" 
          : "-\$${calculatedBalance.abs().toStringAsFixed(0)}";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se puede eliminar a un cliente con saldo pendiente o a favor ($formattedBal).", style: const TextStyle(color: Colors.white)),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text("Eliminar Cliente", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text("¿Estás seguro de eliminar a ${client.name}? Esta acción no se puede deshacer.", style: const TextStyle(color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await ClientsActionsV2().deleteClient(client.id);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calculatedBalance = ClientsActionsV2().getCalculatedBalance(client.id);
    final fmt = NumberFormat.currency(locale: 'es_ES', symbol: '\$', decimalDigits: 0);
    final today = DateTime.now().toString().substring(0, 10);
    bool visitedToday = client.lastVisitDate == today;
    bool isVisited = visitedToday && client.lastVisitStatus == 'visited';
    bool isSkipped = visitedToday && client.lastVisitStatus == 'skipped';

    String balanceText = "\$0";
    if (calculatedBalance > 0) {
      balanceText = fmt.format(calculatedBalance);
    } else if (calculatedBalance < 0) {
      balanceText = "-${fmt.format(calculatedBalance.abs())}";
    }

    final cardColor = visitedToday 
        ? (isVisited ? AppTheme.surfaceDark.withOpacity(0.5) : Colors.black.withOpacity(0.3)) 
        : AppTheme.surfaceDark;

    // VISTA EN GRILLA (GRID MODE)
    if (isGrid && !isPhone) {
      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ClientDetailsViewV2(client: client)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fila Superior: Avatar + Nombre + Horario + Visita
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: visitedToday ? Colors.transparent : AppTheme.backgroundDark,
                          child: isVisited
                              ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 36)
                              : isSkipped
                                  ? const Icon(Icons.cancel, color: Colors.grey, size: 36)
                                  : const Icon(Icons.person, color: AppTheme.primaryYellow, size: 36),
                        ),
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: GestureDetector(
                            onTap: () {
                              ClientsActionsV2().toggleOpenContinuous(client.id, client.isOpenContinuous);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4.5),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primaryYellow, width: 1.2),
                              ),
                              child: Icon(
                                client.isOpenContinuous ? Icons.store : Icons.access_time,
                                size: 13,
                                color: client.isOpenContinuous ? AppTheme.textSecondary : AppTheme.primaryYellow,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              decoration: visitedToday ? TextDecoration.lineThrough : null,
                              color: visitedToday ? Colors.grey : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${client.city} • ${client.address}",
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!client.isOpenContinuous) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time, color: AppTheme.primaryYellow, size: 10),
                                const SizedBox(width: 2),
                                Text(
                                  "Cierra Mediodía",
                                  style: TextStyle(
                                    color: visitedToday ? Colors.grey : AppTheme.primaryYellow,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Fila Inferior: Botones Visita + Saldo + Acciones (Editar/Borrar/Detalle)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Botones de Visita
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!visitedToday) ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                            onPressed: () => ClientsActionsV2().markVisit(client.id, 'visited'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 20),
                            onPressed: () => ClientsActionsV2().markVisit(client.id, 'skipped'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.undo, color: AppTheme.primaryYellow, size: 20),
                            onPressed: () => ClientsActionsV2().markVisit(client.id, ''),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          ),
                        ],
                      ],
                    ),

                    // Saldo
                    Text(
                      balanceText,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: calculatedBalance > 0
                            ? AppTheme.danger
                            : (calculatedBalance < 0 ? Colors.greenAccent : AppTheme.textSecondary),
                      ),
                    ),

                    // Acciones (Editar / Borrar / Flecha)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: visitedToday ? Colors.grey : AppTheme.primaryYellow, size: 18),
                          onPressed: () => ClientDialogsV2.showEditDialog(context, client),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: visitedToday ? Colors.grey : AppTheme.danger, size: 18),
                          onPressed: () => _handleDeleteClient(context, calculatedBalance),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: AppTheme.primaryYellow, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ClientDetailsViewV2(client: client)),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // VISTA EN LISTA (LIST MODE)
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ClientDetailsViewV2(client: client)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar & Abre de corrido toggle
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: visitedToday ? Colors.transparent : AppTheme.backgroundDark,
                    child: isVisited
                        ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 30)
                        : isSkipped
                            ? const Icon(Icons.cancel, color: Colors.grey, size: 30)
                            : const Icon(Icons.person, color: AppTheme.primaryYellow, size: 30),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: () {
                        ClientsActionsV2().toggleOpenContinuous(client.id, client.isOpenContinuous);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryYellow, width: 1.2),
                        ),
                        child: Icon(
                          client.isOpenContinuous ? Icons.store : Icons.access_time,
                          size: 12,
                          color: client.isOpenContinuous ? AppTheme.textSecondary : AppTheme.primaryYellow,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Nombre, Dirección y Ciudad + Horario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      client.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        decoration: visitedToday ? TextDecoration.lineThrough : null,
                        color: visitedToday ? Colors.grey : AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          "${client.city} • ${client.address}",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!client.isOpenContinuous) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time, color: AppTheme.primaryYellow, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            "Cierra Mediodía",
                            style: TextStyle(
                              color: visitedToday ? Colors.grey : AppTheme.primaryYellow,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Acciones a la derecha alineadas y centradas
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!visitedToday) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 22),
                      onPressed: () => ClientsActionsV2().markVisit(client.id, 'visited'),
                      tooltip: "Marcar compró",
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.grey, size: 22),
                      onPressed: () => ClientsActionsV2().markVisit(client.id, 'skipped'),
                      tooltip: "Marcar no compró",
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.undo, color: AppTheme.primaryYellow, size: 22),
                      onPressed: () => ClientsActionsV2().markVisit(client.id, ''),
                      tooltip: "Deshacer visita",
                    ),
                  ],
                  const SizedBox(width: 8),

                  Text(
                    balanceText,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: calculatedBalance > 0
                          ? AppTheme.danger
                          : (calculatedBalance < 0 ? Colors.greenAccent : AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),

                  IconButton(
                    icon: Icon(Icons.edit, color: visitedToday ? Colors.grey : AppTheme.primaryYellow, size: 20),
                    onPressed: () => ClientDialogsV2.showEditDialog(context, client),
                    tooltip: "Editar datos",
                  ),

                  IconButton(
                    icon: Icon(Icons.delete_outline, color: visitedToday ? Colors.grey : AppTheme.danger, size: 20),
                    onPressed: () => _handleDeleteClient(context, calculatedBalance),
                    tooltip: "Eliminar cliente",
                  ),

                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppTheme.primaryYellow, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ClientDetailsViewV2(client: client)),
                      );
                    },
                    tooltip: "Ver Cuenta Corriente",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
