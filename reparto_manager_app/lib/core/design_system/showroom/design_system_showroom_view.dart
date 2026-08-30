import 'package:flutter/material.dart';
import '../design_system.dart';

/// Galería Visual y Showroom interactivo para validar todos los componentes
/// y tokens del Design System de Reparto-Manager V2.
class DesignSystemShowroomView extends StatefulWidget {
  const DesignSystemShowroomView({super.key});

  @override
  State<DesignSystemShowroomView> createState() => _DesignSystemShowroomViewState();
}

class _DesignSystemShowroomViewState extends State<DesignSystemShowroomView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _buttonsLoading = false;
  bool _buttonsDisabled = false;
  double _testBalance = 12500.0;
  final TextEditingController _testInputController =
      TextEditingController(text: 'Prueba de texto interactivo');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _testInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text('Design System Showroom V2', style: AppTypography.h2),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryYellow,
          labelColor: AppColors.primaryYellow,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.palette_outlined), text: 'Tokens'),
            Tab(icon: Icon(Icons.smart_button_outlined), text: 'Botones & Inputs'),
            Tab(icon: Icon(Icons.label_outline), text: 'Badges & Chips'),
            Tab(icon: Icon(Icons.view_agenda_outlined), text: 'Tarjetas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTokensTab(),
          _buildButtonsTab(),
          _buildBadgesTab(),
          _buildCardsTab(),
        ],
      ),
    );
  }

  // --- TAB 1: TOKENS ---
  Widget _buildTokensTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('Paleta de Colores', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _buildColorSwatch('Primary Yellow', AppColors.primaryYellow, AppColors.textOnPrimary),
            _buildColorSwatch('Background Dark', AppColors.backgroundDark, AppColors.textPrimary),
            _buildColorSwatch('Surface Dark', AppColors.surfaceDark, AppColors.textPrimary),
            _buildColorSwatch('Success', AppColors.success, AppColors.textPrimary),
            _buildColorSwatch('Danger', AppColors.danger, AppColors.textPrimary),
            _buildColorSwatch('Warning', AppColors.warning, AppColors.textPrimary),
            _buildColorSwatch('Info', AppColors.info, AppColors.textPrimary),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Escala Tipográfica', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('H1 - Outfit Bold 28px', style: AppTypography.h1),
              const SizedBox(height: AppSpacing.sm),
              Text('H2 - Outfit Bold 22px', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text('H3 - Outfit Bold 18px', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text('Body Large - 16px', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Body Medium - 14px', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Text('Body Small - 12px', style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSwatch(String name, Color color, Color textColor) {
    return Container(
      width: 140,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTypography.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: AppTypography.caption(textColor),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: BOTONES & INPUTS ---
  Widget _buildButtonsTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                title: Text('Loading', style: AppTypography.bodyMedium),
                value: _buttonsLoading,
                activeThumbColor: AppColors.primaryYellow,
                onChanged: (val) => setState(() => _buttonsLoading = val),
              ),
            ),
            Expanded(
              child: SwitchListTile(
                title: Text('Disabled', style: AppTypography.bodyMedium),
                value: _buttonsDisabled,
                activeThumbColor: AppColors.primaryYellow,
                onChanged: (val) => setState(() => _buttonsDisabled = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Variantes de AppButton', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            AppButton(
              text: 'Primario',
              isLoading: _buttonsLoading,
              isDisabled: _buttonsDisabled,
              icon: Icons.check_circle_outline,
              onPressed: () => _showFeedback('Botón Primario presionado'),
            ),
            AppButton(
              text: 'Secundario',
              variant: AppButtonVariant.secondary,
              isLoading: _buttonsLoading,
              isDisabled: _buttonsDisabled,
              icon: Icons.refresh,
              onPressed: () => _showFeedback('Botón Secundario presionado'),
            ),
            AppButton(
              text: 'Peligro',
              variant: AppButtonVariant.danger,
              isLoading: _buttonsLoading,
              isDisabled: _buttonsDisabled,
              icon: Icons.delete_outline,
              onPressed: () => _showFeedback('Botón Peligro presionado'),
            ),
            AppButton(
              text: 'Ghost / Texto',
              variant: AppButtonVariant.ghost,
              isLoading: _buttonsLoading,
              isDisabled: _buttonsDisabled,
              onPressed: () => _showFeedback('Botón Ghost presionado'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          text: 'Botón Full Width',
          fullWidth: true,
          isLoading: _buttonsLoading,
          isDisabled: _buttonsDisabled,
          onPressed: () => _showFeedback('Botón Full Width presionado'),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Campos de Texto (AppTextField)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Buscador de clientes o productos',
          hintText: 'Ingrese nombre o zona...',
          controller: _testInputController,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => _testInputController.clear(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Monto de Cobro',
          hintText: '\$0.00',
          keyboardType: TextInputType.number,
          prefixIcon: Icon(Icons.attach_money),
        ),
      ],
    );
  }

  // --- TAB 3: BADGES & CHIPS ---
  Widget _buildBadgesTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('BalanceBadge (Saldos Matemáticos)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Simulador de Saldo: \$${_testBalance.toStringAsFixed(0)}',
          style: AppTypography.bodyMedium,
        ),
        Slider(
          value: _testBalance,
          min: -10000,
          max: 30000,
          divisions: 40,
          activeColor: AppColors.primaryYellow,
          onChanged: (val) => setState(() => _testBalance = val),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            BalanceBadge(balance: _testBalance, size: BalanceBadgeSize.small),
            BalanceBadge(balance: _testBalance, size: BalanceBadgeSize.medium),
            BalanceBadge(balance: _testBalance, size: BalanceBadgeSize.large),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Casos Predefinidos de Balance', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.md),
        const Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            BalanceBadge(balance: 0.0),
            BalanceBadge(balance: 45000.0),
            BalanceBadge(balance: -1500.0),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('StatusChips (Estados de Visita)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusChip.visit('visited'),
            StatusChip.visit('not_visited'),
            StatusChip.visit('pending'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('StatusChips (Tipos de Cliente)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            StatusChip.clientType('normal'),
            StatusChip.clientType('especial'),
            StatusChip.clientType('revendedor'),
          ],
        ),
      ],
    );
  }

  // --- TAB 4: TARJETAS & CLIENTES ---
  Widget _buildCardsTab() {
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        Text('AppCard Básica', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () => _showFeedback('AppCard tocada'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarjeta Genérica Táctil', style: AppTypography.h4),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Superficie oscura #2C2C2C con borde sutil al 15% de opacidad y feedback táctil.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('ClientCards (Molécula de Reparto / Mostrador)', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        ClientCard(
          name: 'Almacén Don Carlos',
          zone: 'Zona Centro',
          address: 'Av. San Martín 1420',
          phone: '2355-441234',
          clientType: 'normal',
          visitStatus: 'not_visited',
          balance: 18400.0,
          onTap: () => _showFeedback('Ficha Don Carlos'),
          onPosAction: () => _showFeedback('Cargar POS para Don Carlos'),
          onPhoneTap: () => _showFeedback('Llamando a Don Carlos'),
        ),
        const SizedBox(height: AppSpacing.md),
        ClientCard(
          name: 'Restaurante Lincoln Plaza',
          zone: 'Zona Norte',
          address: 'Belgrano 550',
          clientType: 'especial',
          visitStatus: 'visited',
          balance: 0.0,
          isHighlighted: true,
          onTap: () => _showFeedback('Ficha Lincoln Plaza'),
          onPosAction: () => _showFeedback('Cargar POS para Lincoln Plaza'),
        ),
        const SizedBox(height: AppSpacing.md),
        ClientCard(
          name: 'Distribuidora San Cayetano',
          zone: 'Ruta 188',
          address: 'Km 215',
          clientType: 'revendedor',
          visitStatus: 'pending',
          balance: -3500.0,
          onTap: () => _showFeedback('Ficha San Cayetano'),
        ),
      ],
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceDarkElevated,
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
