import 'package:flutter/material.dart';
import '../../design_system.dart';

/// Pestaña interactiva del módulo de Clientes en el Showroom.
/// Permite alternar entre Modo Lista y Modo Tarjeta, y probar estados en vivo.
class ShowroomClientsTab extends StatefulWidget {
  const ShowroomClientsTab({super.key});

  @override
  State<ShowroomClientsTab> createState() => _ShowroomClientsTabState();
}

class _ShowroomClientsTabState extends State<ShowroomClientsTab> {
  bool _isGridView = false;

  // Lista mock de clientes interactivos
  late List<_MockClientData> _clients;

  @override
  void initState() {
    super.initState();
    _resetClients();
  }

  void _resetClients() {
    _clients = [
      _MockClientData(
        id: '1',
        name: 'Carlos Gómez',
        nickname: 'El Pela',
        address: 'San Martín 1420',
        zone: 'Centro',
        balance: 24500,
        isContinuousSchedule: true,
        isVisited: false,
        isPassed: false,
      ),
      _MockClientData(
        id: '2',
        name: 'María Belén',
        nickname: 'Kiosco Central',
        address: 'Av. Rivadavia 850',
        zone: 'Norte',
        balance: 0,
        isContinuousSchedule: true,
        isVisited: false,
        isPassed: false,
      ),
      _MockClientData(
        id: '3',
        name: 'Almacén Don Tito',
        nickname: 'Tito',
        address: 'Belgrano 340',
        zone: 'Sur',
        balance: -5000,
        isContinuousSchedule: false,
        isVisited: true,
        isPassed: false,
      ),
      _MockClientData(
        id: '4',
        name: 'Panadería San Cayetano',
        nickname: 'El Gordo',
        address: 'Mitre 2100',
        zone: 'Oeste',
        balance: 12000,
        isContinuousSchedule: false,
        isVisited: false,
        isPassed: true,
      ),
    ];
  }

  double get _totalDebt => _clients
      .where((c) => c.balance > 0)
      .fold(0.0, (acc, c) => acc + c.balance);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewToggleBar(),
        Expanded(
          child: _isGridView ? _buildGridView() : _buildListView(),
        ),
        ClientsBottomBar(
          totalDebt: _totalDebt,
          onAddClient: () => AppSnackBar.showSuccess(
            context,
            'Abrir modal: "+ AGREGAR CLIENTE"',
          ),
        ),
      ],
    );
  }

  Widget _buildViewToggleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.surfaceDark,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt_outlined, size: 18, color: AppColors.primaryYellow),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Clientes (${_clients.length})',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryYellow,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.view_list_rounded,
                  color: !_isGridView ? AppColors.primaryYellow : AppColors.textMuted,
                ),
                tooltip: 'Modo Lista',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _isGridView = false),
              ),
              IconButton(
                icon: Icon(
                  Icons.grid_view_rounded,
                  color: _isGridView ? AppColors.primaryYellow : AppColors.textMuted,
                ),
                tooltip: 'Modo Tarjetas (2 columnas)',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _isGridView = true),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () => setState(_resetClients),
                child: const Text('Reiniciar Estados', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _clients.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final client = _clients[index];
        return ClientListItem(
          name: client.name,
          nickname: client.nickname,
          address: client.address,
          zone: client.zone,
          balance: client.balance,
          isContinuousSchedule: client.isContinuousSchedule,
          isVisited: client.isVisited,
          isPassed: client.isPassed,
          onTap: () => AppSnackBar.showInfo(context, 'Perfil de: ${client.name}'),
          onEdit: () => AppSnackBar.showInfo(context, 'Editar: ${client.name}'),
          onDelete: () => AppSnackBar.showWarning(context, 'Eliminar: ${client.name}'),
          onTogglePassed: () => setState(() => client.isPassed = true),
          onUndoPassed: () => setState(() => client.isPassed = false),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        mainAxisExtent: 160,
      ),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return ClientCardItem(
          name: client.name,
          nickname: client.nickname,
          address: client.address,
          zone: client.zone,
          balance: client.balance,
          isContinuousSchedule: client.isContinuousSchedule,
          isVisited: client.isVisited,
          isPassed: client.isPassed,
          onTap: () => AppSnackBar.showInfo(context, 'Perfil de: ${client.name}'),
          onEdit: () => AppSnackBar.showInfo(context, 'Editar: ${client.name}'),
          onDelete: () => AppSnackBar.showWarning(context, 'Eliminar: ${client.name}'),
          onTogglePassed: () => setState(() => client.isPassed = true),
          onUndoPassed: () => setState(() => client.isPassed = false),
        );
      },
    );
  }
}

class _MockClientData {
  final String id;
  final String name;
  final String? nickname;
  final String? address;
  final String? zone;
  final double balance;
  final bool isContinuousSchedule;
  bool isVisited;
  bool isPassed;

  _MockClientData({
    required this.id,
    required this.name,
    this.nickname,
    this.address,
    this.zone,
    required this.balance,
    required this.isContinuousSchedule,
    required this.isVisited,
    required this.isPassed,
  });
}
