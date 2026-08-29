import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../client.dart';
import 'clients_actions_v2.dart';

class ClientDialogsV2 {
  static void showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final nicknameController = TextEditingController();
    final newCityController = TextEditingController();
    bool isOpenContinuous = false;
    bool isEnteringNewCity = false;

    final cities = ClientsActionsV2().cities;
    String selectedFormCity = ClientsActionsV2().selectedFilterCity ?? '';
    if (selectedFormCity.isEmpty && cities.isNotEmpty) {
      selectedFormCity = cities.first;
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final citiesList = ClientsActionsV2().cities;
            if (!isEnteringNewCity && selectedFormCity.isNotEmpty && !citiesList.contains(selectedFormCity)) {
              selectedFormCity = '';
            }
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Nuevo Cliente"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre / Negocio', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 16),
                    if (isEnteringNewCity || citiesList.isEmpty) ...[
                      TextField(
                        controller: newCityController,
                        decoration: InputDecoration(
                          labelText: 'Escribe la Ciudad',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_city),
                          suffixIcon: citiesList.isNotEmpty ? IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () => setStateDialog(() => isEnteringNewCity = false),
                          ) : null,
                        ),
                      ),
                    ] else ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_city)),
                        value: selectedFormCity.isEmpty && citiesList.isNotEmpty ? citiesList.first : (selectedFormCity.isEmpty ? null : selectedFormCity),
                        items: [
                          ...citiesList.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                          const DropdownMenuItem<String>(value: 'NEW_CITY', child: Text('+ Agregar nueva ciudad', style: TextStyle(color: AppTheme.primaryYellow))),
                        ],
                        onChanged: (val) {
                          if (val == 'NEW_CITY') {
                            setStateDialog(() => isEnteringNewCity = true);
                          } else {
                            setStateDialog(() {
                              selectedFormCity = val ?? '';
                              isEnteringNewCity = false;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(labelText: 'Apodo (Oculto, útil para buscar)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Abre de corrido ☀️"),
                      subtitle: const Text("Ideal para saber que no cierran al mediodía"),
                      value: isOpenContinuous,
                      activeColor: AppTheme.primaryYellow,
                      onChanged: (val) => setStateDialog(() => isOpenContinuous = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary))),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    final address = addressController.text.trim();
                    final cityInput = isEnteringNewCity ? newCityController.text.trim() : selectedFormCity;
                    final city = cityInput.isEmpty ? 'General' : cityInput;

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Ingresá el nombre del cliente para guardar")),
                      );
                      return;
                    }

                    setStateDialog(() => isSaving = true);
                    try {
                      await ClientsActionsV2().addClient(
                        name, phone, city, address,
                        nickname: nicknameController.text.trim(),
                        isOpenContinuous: isOpenContinuous,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      setStateDialog(() => isSaving = false);
                    }
                  },
                  child: isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("Guardar"),
                )
              ],
            );
          }
        );
      }
    );
  }

  static void showEditDialog(BuildContext context, Client client) {
    final editNameCtrl = TextEditingController(text: client.name);
    final editPhoneCtrl = TextEditingController(text: client.phone);
    final editAddressCtrl = TextEditingController(text: client.address);
    final editCityCtrl = TextEditingController(text: client.city);
    final editNicknameCtrl = TextEditingController(text: client.nickname);
    bool isOpenContinuous = client.isOpenContinuous;

    showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceDark,
              title: const Text("Editar Cliente"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: editNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editCityCtrl,
                      decoration: const InputDecoration(labelText: 'Ciudad', prefixIcon: Icon(Icons.location_city)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editAddressCtrl,
                      decoration: const InputDecoration(labelText: 'Dirección', prefixIcon: Icon(Icons.location_on)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editNicknameCtrl,
                      decoration: const InputDecoration(labelText: 'Apodo (Oculto, útil para buscar)', prefixIcon: Icon(Icons.badge)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: editPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Abre de corrido ☀️"),
                      value: isOpenContinuous,
                      activeColor: AppTheme.primaryYellow,
                      onChanged: (val) => setStateDialog(() => isOpenContinuous = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: isSaving ? null : () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: AppTheme.textSecondary))),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (editNameCtrl.text.trim().isEmpty || editCityCtrl.text.trim().isEmpty) {
                      return;
                    }
                    setStateDialog(() => isSaving = true);
                    try {
                      await ClientsActionsV2().updateClient(
                        client.id,
                        editNameCtrl.text,
                        editPhoneCtrl.text,
                        editCityCtrl.text,
                        editAddressCtrl.text,
                        nickname: editNicknameCtrl.text,
                        isOpenContinuous: isOpenContinuous,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      setStateDialog(() => isSaving = false);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("Guardar"),
                )
              ],
            );
          }
        );
      }
    );
  }

  static void showCopyPricesDialog(BuildContext context, {Client? initialSourceClient}) {
    String? selectedSourceId = initialSourceClient?.id;
    List<String> selectedTargetIds = [];
    String searchQuery = '';
    String? cityFilter;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final allClients = ClientsActionsV2().allClients;
              if (selectedSourceId == null && allClients.isNotEmpty) {
                selectedSourceId = allClients.first.id;
              }

              final sourceClient = selectedSourceId != null
                  ? allClients.firstWhere((c) => c.id == selectedSourceId, orElse: () => allClients.first)
                  : null;

              var targetCandidates = allClients.where((c) => c.id != selectedSourceId && !c.hidden).toList();

              if (cityFilter != null && cityFilter!.isNotEmpty) {
                targetCandidates = targetCandidates.where((c) => c.city.trim().toLowerCase() == cityFilter!.trim().toLowerCase()).toList();
              }

              if (searchQuery.isNotEmpty) {
                targetCandidates = targetCandidates.where((c) => 
                  c.name.toLowerCase().contains(searchQuery) || 
                  c.city.toLowerCase().contains(searchQuery) ||
                  c.nickname.toLowerCase().contains(searchQuery)
                ).toList();
              }

              final citiesList = ClientsActionsV2().cities;

              return Container(
                width: 500,
                constraints: BoxConstraints(
                  maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) * 0.85,
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.copy_all, color: AppTheme.primaryYellow, size: 28),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "Copiar y Pegar Precios",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryYellow),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.primaryYellow),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      dropdownColor: AppTheme.surfaceDark,
                      decoration: InputDecoration(
                        labelText: "Copiar precios DESDE (Cliente Origen)",
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.storefront, color: AppTheme.primaryYellow),
                      ),
                      value: selectedSourceId,
                      items: allClients.map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text("${c.name} (${c.type.toUpperCase()}) - ${c.customPrices.length} precios", style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedSourceId = val;
                          selectedTargetIds.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    if (sourceClient != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.5)),
                        ),
                        child: Text(
                          "Se copiarán ${sourceClient.customPrices.length} precios de '${sourceClient.name}' hacia los clientes seleccionados.",
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            cursorColor: AppTheme.primaryYellow,
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Buscar cliente destino...',
                              hintStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.search, color: Colors.black, size: 18),
                              filled: true,
                              fillColor: AppTheme.primaryYellow,
                              isDense: true,
                            ),
                            onChanged: (val) => setStateDialog(() => searchQuery = val.toLowerCase()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 140,
                          height: 38,
                          child: DropdownButtonFormField<String>(
                            dropdownColor: AppTheme.primaryYellow,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: AppTheme.primaryYellow,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                            value: cityFilter,
                            hint: const Text("Ciudad", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                            items: [
                              const DropdownMenuItem<String>(value: null, child: Text("Todas", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))),
                              ...citiesList.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)))),
                            ],
                            onChanged: (val) => setStateDialog(() => cityFilter = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${selectedTargetIds.length} seleccionados", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        TextButton(
                          onPressed: () {
                            setStateDialog(() {
                              if (selectedTargetIds.length == targetCandidates.length) {
                                selectedTargetIds.clear();
                              } else {
                                selectedTargetIds = targetCandidates.map((c) => c.id).toList();
                              }
                            });
                          },
                          child: Text(
                            selectedTargetIds.length == targetCandidates.length ? "Desmarcar Todos" : "Marcar Todos",
                            style: const TextStyle(color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Expanded(
                      child: targetCandidates.isEmpty
                          ? const Center(child: Text("No se encontraron clientes destino.", style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: targetCandidates.length,
                              itemBuilder: (context, index) {
                                final client = targetCandidates[index];
                                final isChecked = selectedTargetIds.contains(client.id);
                                return CheckboxListTile(
                                  activeColor: AppTheme.primaryYellow,
                                  checkColor: Colors.black,
                                  title: Text("${client.name} (${client.type.toUpperCase()})", style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  subtitle: Text("${client.city} • ${client.customPrices.length} precios actuales", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  value: isChecked,
                                  onChanged: (bool? checked) {
                                    setStateDialog(() {
                                      if (checked == true) {
                                        selectedTargetIds.add(client.id);
                                      } else {
                                        selectedTargetIds.remove(client.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: const Text("CANCELAR", style: TextStyle(color: Colors.white70)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: (isSaving || selectedSourceId == null || selectedTargetIds.isEmpty)
                              ? null
                              : () async {
                                  setStateDialog(() => isSaving = true);
                                  try {
                                    await ClientsActionsV2().copyPricesToClients(selectedSourceId!, selectedTargetIds);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("¡Precios copiados exitosamente a ${selectedTargetIds.length} clientes!"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setStateDialog(() => isSaving = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Error al copiar precios: $e"), backgroundColor: AppTheme.danger),
                                      );
                                    }
                                  }
                                },
                          icon: isSaving 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Icon(Icons.paste, color: Colors.black, size: 18),
                          label: Text(
                            "PEGAR PRECIOS (${selectedTargetIds.length})",
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
