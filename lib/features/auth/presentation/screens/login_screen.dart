import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';
import 'package:tenis_kulubu/features/auth/presentation/widgets/auth_text_field.dart';

import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
        final userModel = await ref.read(authRepositoryProvider).signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        if (userModel.isFirstLogin) {
          context.go(AppRouter.forceChangePassword);
        } else {
          context.go(AppRouter.home);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_parseAuthError(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseAuthError(String error) {
    if (error.contains('user-not-found')) return 'uyelik.kullanici_bulunamadi'.tr();
    if (error.contains('wrong-password')) return 'uyelik.sifre_hatali'.tr();
    if (error.contains('invalid-email')) return 'uyelik.eposta_gecerli'.tr();
    if (error.contains('too-many-requests')) return 'uyelik.cok_fazla_deneme'.tr();
    return 'uyelik.giris_basarisiz'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),

                    // Logo & Başlık
                    _buildHeader(),

                    const SizedBox(height: 48),

                    // Giriş Formu
                    AuthTextField(
                      controller: _emailController,
                      label: 'uyelik.e-posta'.tr(),
                      hint: 'ornek@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'uyelik.eposta_gerekli'.tr();
                        if (!v.contains('@')) return 'uyelik.eposta_gecerli'.tr();
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    AuthTextField(
                      controller: _passwordController,
                      label: 'uyelik.sifre'.tr(),
                      hint: '••••••••',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textHint,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'uyelik.sifre_zorunludur'.tr();
                        if (v.length < 6) return 'uyelik.sifre_en_az_6_karakter'.tr();
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // Şifremi Unuttum
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRouter.forgotPassword),
                        child: Text(
                          'uyelik.sifremi_unuttum'.tr(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Giriş Butonu
                    AuthButton(
                      label: 'uyelik.giris_yap'.tr(),
                      isLoading: _isLoading,
                      onPressed: _login,
                    ),

                    const SizedBox(height: 32),

                    // Ayırıcı
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'uyelik.veya'.tr(),
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Kayıt Ol
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'uyelik.hesap_yok_mu'.tr(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRouter.register),
                          child: Text(
                            'uyelik.kayit_ol'.tr(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo Container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.elevatedShadow,
          ),
          child: const Center(
            child: Text(
              'ULAS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'uyelik.hosgeldiniz'.tr(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'uyelik.kulup_adi'.tr(),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
