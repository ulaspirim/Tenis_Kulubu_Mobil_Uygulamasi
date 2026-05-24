import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';
import 'package:tenis_kulubu/features/auth/presentation/widgets/auth_text_field.dart';

import 'package:easy_localization/easy_localization.dart';
// ─────────────────────────────────────────
// KAYIT OL EKRANI
// ─────────────────────────────────────────
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _membershipNumCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _membershipNumCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('uyelik.kullanim_kosullarini_kabul'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).registerWithEmail(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            phone: _phoneCtrl.text.trim(),
            membershipNumber: _membershipNumCtrl.text.trim(),
          );
      if (mounted) context.go(AppRouter.home);
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('uyelik.kayit_ol').tr(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'uyelik.uyelik_bilgileriniz'.tr(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'uyelik.kulup_uye_numarasi_ile_kayit'.tr(),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: AuthTextField(
                      controller: _firstNameCtrl,
                      label: 'uyelik.ad',
                      hint: 'uyelik.adiniz',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'uyelik.ad_zorunludur'.tr() : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthTextField(
                      controller: _lastNameCtrl,
                      label: 'uyelik.soyad',
                      hint: 'uyelik.soyadiniz',
                      prefixIcon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'uyelik.soyad_zorunludur'.tr() : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AuthTextField(
                controller: _emailCtrl,
                label: 'uyelik.email',
                hint: 'ornek@email.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'uyelik.email_gerekli'.tr();
                  if (!v.contains('@')) return 'uyelik.email_gecerli'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AuthTextField(
                controller: _phoneCtrl,
                label: 'uyelik.telefon',
                hint: '05XX XXX XX XX',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                controller: _membershipNumCtrl,
                label: 'uyelik.kulup_uye_numarasi',
                hint: 'ULAS-XXXX',
                prefixIcon: Icons.card_membership_outlined,
                validator: (v) => v!.isEmpty ? 'uyelik.kulup_uye_numarasi_zorunludur'.tr() : null,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                controller: _passwordCtrl,
                label: 'uyelik.sifre',
                hint: 'uyelik.sifre_en_az_6_karakter',
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'uyelik.sifre_zorunludur'.tr();
                  if (v.length < 6) return 'uyelik.sifre_en_az_6_karakter'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AuthTextField(
                controller: _confirmPasswordCtrl,
                label: 'uyelik.sifre_tekrar',
                hint: 'uyelik.sifre_tekrar_girin',
                obscureText: _obscureConfirm,
                prefixIcon: Icons.lock_outline,
                textInputAction: TextInputAction.done,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v != _passwordCtrl.text) return 'uyelik.sifreler_eslesmiyor'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Kullanım Koşulları
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (v) => setState(() => _acceptedTerms = v!),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                        children: [
                          TextSpan(text: 'uyelik.kulup'.tr()),
                          TextSpan(
                            text: 'uyelik.kullanim_kosullarini'.tr(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' uyelik.okudum_ve_kabul_ediyorum'.tr()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              AuthButton(
                label: 'uyelik.kayit_ol'.tr(),
                isLoading: _isLoading,
                onPressed: _register,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'uyelik.zaten_hesabiniz_var_mi'.tr(),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Text(
                      'uyelik.giris_yap'.tr(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ŞİFREMİ UNUTTUM EKRANI
// ─────────────────────────────────────────
