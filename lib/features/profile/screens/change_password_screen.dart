import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/auth/presentation/widgets/auth_text_field.dart';

import 'package:easy_localization/easy_localization.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('uyelik.kullanici_bulunamadi'.tr());

      // Önce mevcut şifreyle yeniden doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordCtrl.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Yeni şifreyi ayarla
      await user.updatePassword(_newPasswordCtrl.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('uyelik.sifre_guncellendi'.tr()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        switch (e.code) {
          case 'wrong-password':
            message = 'uyelik.sifre_hatalı'.tr();
            break;
          case 'weak-password':
            message = 'uyelik.sifre_en_az_6_karakter'.tr();
            break;
          case 'requires-recent-login':
            message = 'uyelik.requires_recent_login'.tr();
            break;
          default:
            message = 'uyelik.uye_hata'.tr(args: [e.message ?? '']);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
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
        title: Text('uyelik.sifre_degistir'.tr()),
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
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'uyelik.sifre_guvenlik_uyarisi'.tr(),
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              AuthTextField(
                controller: _currentPasswordCtrl,
                label: 'uyelik.mevcut_sifre'.tr(),
                hint: '••••••••',
                obscureText: _obscureCurrent,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'uyelik.mevcut_sifre_zorunludur'.tr() : null,
              ),

              const SizedBox(height: 16),

              AuthTextField(
                controller: _newPasswordCtrl,
                label: 'uyelik.sifrenizi_belirleyin'.tr(),
                hint: 'uyelik.sifre_en_az_6_karakter'.tr(),
                obscureText: _obscureNew,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'uyelik.sifre_zorunludur'.tr();
                  if (v.length < 6) return 'uyelik.sifre_en_az_6_karakter'.tr();
                  if (v == _currentPasswordCtrl.text)
                    return 'uyelik.yeni_ve_eski_sifre'.tr();
                  return null;
                },
              ),

              const SizedBox(height: 16),

              AuthTextField(
                controller: _confirmPasswordCtrl,
                label: 'uyelik.yeni_sifrenizi_tekrar_girin'.tr(),
                hint: 'uyelik.sifre_tekrar_girin'.tr(),
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
                  if (v != _newPasswordCtrl.text) return 'uyelik.sifreler_eslesmiyor'.tr();
                  return null;
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text(
                          'uyelik.sifremi_guncelle'.tr(),
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}