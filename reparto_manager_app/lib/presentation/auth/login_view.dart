// lib/presentation/auth/login_view.dart
import 'package:flutter/material.dart';
import '../../core/design_system/theme_manager.dart';
import '../../core/design_system/tokens/app_colors.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../core/design_system/widgets/app_button.dart';
import '../../core/design_system/widgets/app_card.dart';
import '../../core/design_system/widgets/app_text_field.dart';
import '../../core/design_system/widgets/feedback_and_metrics_widgets.dart';
import 'session_manager.dart';
import 'widgets/forgot_password_dialog.dart';

/// Pantalla oficial de Inicio de Sesión para Reparto-Manager V2.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor complete todos los campos.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await SessionManager.instance.signIn(
      email,
      password,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        setState(() => _errorMessage = failure.message);
        AppSnackBar.showError(context, failure.message);
      },
      (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = ThemeManager.instance.currentPalette.primary;

    return Scaffold(
      backgroundColor: AppColors.surfaceDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AppCard(
                padding: AppSpacing.paddingXl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(primary),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: 'Correo Electrónico / Usuario',
                      hintText: 'ejemplo@correo.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icon(Icons.person, color: primary, size: 22),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: 'Contraseña',
                      hintText: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      prefixIcon: Icon(Icons.lock, color: primary, size: 22),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: primary,
                          size: 22,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildOptionsRow(primary),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildErrorBanner(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      text: 'Ingresar',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.large,
                      isLoading: _isLoading,
                      fullWidth: true,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Text(
                        'v2.0.0-rc1 • Reparto Manager V2',
                        style: AppTypography.caption(AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Column(
      children: [
        Image.asset(
          'assets/Logo.png',
          height: 72,
          errorBuilder: (context, error, stackTrace) =>
              Icon(Icons.local_shipping, size: 64, color: primary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'REPARTO MANAGER',
          style: AppTypography.h2.copyWith(color: primary, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        const SizedBox(height: 2),
        Text(
          'Sistema Profesional de Gestión & Reparto V2',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOptionsRow(Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _isLoading ? null : () => setState(() => _rememberMe = !_rememberMe),
          borderRadius: AppSpacing.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: primary,
                  checkColor: AppColors.textOnPrimary,
                  side: BorderSide(color: AppColors.textSecondary),
                  onChanged: _isLoading ? null : (val) => setState(() => _rememberMe = val ?? false),
                ),
                Expanded(
                  child: Text(
                    'Recordar sesión en este dispositivo',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () => ForgotPasswordDialog.show(context, initialEmail: _emailController.text.trim()),
            child: Text(
              '¿Olvidaste tu contraseña o necesitas activar tu cuenta?',
              style: AppTypography.bodySmall.copyWith(color: primary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
