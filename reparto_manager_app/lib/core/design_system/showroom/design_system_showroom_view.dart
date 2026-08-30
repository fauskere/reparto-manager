import 'package:flutter/material.dart';
import '../design_system.dart';

/// Galería Visual y Showroom interactivo definitivo de Reparto-Manager V2.
class DesignSystemShowroomView extends StatefulWidget {
  const DesignSystemShowroomView({super.key});

  @override
  State<DesignSystemShowroomView> createState() => _DesignSystemShowroomViewState();
}

class _DesignSystemShowroomViewState extends State<DesignSystemShowroomView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estados interactivos
  String _selectedVariant = '20 Litros';
  int _cartQty1 = 2;
  int _cartQty2 = 1;
  PaymentMethod _selectedPayment = PaymentMethod.efectivo;
  DateTime _filterDate = DateTime.now();
  FilterPeriod _filterPeriod = FilterPeriod.dia;
  String? _filterZone;
  String? _filterCategory;
  final TextEditingController _filterSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text('Design System Showroom V2', style: AppTypography.h3),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryYellow,
          labelColor: AppColors.primaryYellow,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.view_quilt_outlined), text: 'Estructura'),
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Catálogo & Productos'),
            Tab(icon: Icon(Icons.filter_alt_outlined), text: 'Filtros'),
            Tab(icon: Icon(Icons.point_of_sale_outlined), text: 'Caja & Cobro'),
            Tab(icon: Icon(Icons.insights_outlined), text: 'Métricas & Avisos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStructureTab(),
          _buildCatalogTab(),
          _buildFiltersTab(),
          _buildCheckoutTab(),
          _buildMetricsTab(),
        ],
      ),
    );
  }

  // --- 1. ESTRUCTURA ---
  Widget _buildStructureTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Encabezados de Módulo (ModuleHeader)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ModuleHeader(
                title: 'Clientes',
                subtitle: '142 clientes activos • Zona Centro',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, color: AppColors.primaryYellow),
                    onPressed: () => AppSnackBar.showSuccess(context, 'Filtros abiertos'),
                  ),
                  AppButton(
                    text: '+ Nuevo',
                    size: AppButtonSize.small,
                    onPressed: () => AppSnackBar.showSuccess(context, 'Crear cliente'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Títulos de Sección (SectionTitle)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              SectionTitle(
                title: 'Datos de Facturación ARCA',
                subtitle: 'Condición frente al IVA y CUIT',
                action: TextButton(
                  onPressed: () => AppSnackBar.showWarning(context, 'Editando AFIP'),
                  child: const Text('Editar', style: TextStyle(color: AppColors.primaryYellow)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionTitle(
                title: 'Historial de Saldo y Comprobantes',
                subtitle: 'Eventos contables inmutables de los últimos 60 días',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. CATÁLOGO & PRODUCTOS ---
  Widget _buildCatalogTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Selector de Variantes (VariantSelectorChips)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        VariantSelectorChips(
          variants: const ['12 Litros', '20 Litros', 'Retornable', 'Descartable'],
          selectedVariant: _selectedVariant,
          onVariantSelected: (v) => setState(() => _selectedVariant = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Tarjeta de POS (ProductCard)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.82,
          children: [
            ProductCard(
              name: 'Soda Sifón 1.5L (Cajón x6)',
              price: 4500.0,
              category: 'Sifones',
              stock: 24,
              onAdd: () => AppSnackBar.showSuccess(context, 'Soda Sifón agregada'),
            ),
            ProductCard(
              name: 'Bidón 20 Litros Retornable',
              price: 3200.0,
              category: 'Bidones',
              stock: 3,
              onAdd: () => AppSnackBar.showSuccess(context, 'Bidón 20L agregado'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Modo Lista Rápida (ProductListItem)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        ProductListItem(
          name: 'Agua Mineral 500ml Pack x12',
          price: 6800.0,
          category: 'Botellas',
          stock: 40,
          onAdd: () => AppSnackBar.showSuccess(context, 'Pack Agua sumado'),
        ),
      ],
    );
  }

  // --- 3. FILTROS ---
  Widget _buildFiltersTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Barra Universal de Filtros (AppHeaderFilterBar)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppHeaderFilterBar(
          selectedDate: _filterDate,
          onDateChanged: (d) => setState(() => _filterDate = d),
          selectedPeriod: _filterPeriod,
          onPeriodChanged: (p) => setState(() => _filterPeriod = p),
          selectedZone: _filterZone,
          zones: const ['Centro', 'Norte', 'Sur', 'Ruta 188', 'Lincoln'],
          onZoneChanged: (z) => setState(() => _filterZone = z),
          searchController: _filterSearchController,
          onSearchChanged: (q) => setState(() {}),
          onClearSearch: () => setState(() => _filterSearchController.clear()),
          showCategories: true,
          categories: const ['Sifones', 'Bidones', 'Máquinas', 'Repuestos'],
          selectedCategory: _filterCategory,
          onCategoryChanged: (c) => setState(() => _filterCategory = c),
        ),
      ],
    );
  }

  // --- 4. CAJA & COBRO ---
  Widget _buildCheckoutTab() {
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
            AppSnackBar.showSuccess(context, vuelto >= 0 ? 'Vuelto: \$$vuelto' : 'Falta dinero');
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
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AppSuccessDialog(
                  subtitle: 'Cliente: Almacén Don Carlos',
                  totalFormatted: '\$${saleTotal.toInt()}',
                  onPrintDuplicate: () => AppSnackBar.showSuccess(context, 'Imprimiendo duplicado...'),
                  onSendWhatsApp: () => AppSnackBar.showSuccess(context, 'Enviando WhatsApp...'),
                ),
              ),
            ),
            AppButton(
              text: 'Ver Ticket',
              variant: AppButtonVariant.secondary,
              icon: Icons.receipt_long_rounded,
              onPressed: () => showDialog(
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
              ),
            ),
            AppButton(
              text: 'Confirmar Anulación',
              variant: AppButtonVariant.danger,
              icon: Icons.warning_amber_rounded,
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AppConfirmDialog(
                  title: '¿Anular Venta?',
                  message: 'Esta acción revertirá los saldos y el stock de camioneta.',
                  onConfirm: () => AppSnackBar.showError(context, 'Venta anulada'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 5. MÉTRICAS & AVISOS ---
  Widget _buildMetricsTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Tarjetas de Resumen (MetricSummaryCard)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Expanded(
              child: MetricSummaryCard(
                title: 'Total Ventas',
                amount: 485000.0,
                icon: Icons.trending_up_rounded,
                accentColor: AppColors.primaryYellow,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: MetricSummaryCard(
                title: 'Efectivo',
                amount: 320000.0,
                icon: Icons.payments_rounded,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Top 5 Productos Más Vendidos (RankingItemRow)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        const AppCard(
          child: Column(
            children: [
              RankingItemRow(
                rank: 1,
                name: 'Soda Sifón 1.5L (Cajón x6)',
                value: 120,
                maxValue: 120,
                isCurrency: false,
                secondaryInfo: 'Categoría: Sifones',
              ),
              RankingItemRow(
                rank: 2,
                name: 'Bidón 20 Litros Retornable',
                value: 85,
                maxValue: 120,
                isCurrency: false,
                secondaryInfo: 'Categoría: Bidones',
              ),
              RankingItemRow(
                rank: 3,
                name: 'Agua Mineral 500ml Pack x12',
                value: 45,
                maxValue: 120,
                isCurrency: false,
                secondaryInfo: 'Categoría: Botellas',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Alertas Flotantes (AppSnackBar)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              text: 'Éxito',
              icon: Icons.check,
              onPressed: () => AppSnackBar.showSuccess(context, 'Cobro registrado correctamente'),
            ),
            AppButton(
              text: 'Error',
              variant: AppButtonVariant.danger,
              icon: Icons.error_outline,
              onPressed: () => AppSnackBar.showError(context, 'Error al conectar con la impresora'),
            ),
            AppButton(
              text: 'Aviso',
              variant: AppButtonVariant.secondary,
              icon: Icons.warning_amber,
              onPressed: () => AppSnackBar.showWarning(context, 'Cliente con deuda previa acumulada'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Estado Vacío (EmptyStateWidget)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        EmptyStateWidget(
          title: 'Sin clientes en esta zona',
          description: 'No se encontraron clientes registrados en la Zona Norte.',
          actionText: '+ Agregar Cliente',
          onAction: () => AppSnackBar.showSuccess(context, 'Nuevo cliente'),
        ),
      ],
    );
  }
}
