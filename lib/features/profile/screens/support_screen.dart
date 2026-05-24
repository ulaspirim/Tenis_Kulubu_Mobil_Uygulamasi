import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tenis_kulubu/core/theme/app_colors.dart';

import 'package:easy_localization/easy_localization.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(('uyelik.yardim_ve_destek'.tr())),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          // ✅ Navigator.of(context).pop() → context.pop() (GoRouter ile tutarlı)
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSupportTile(
            context: context,
            icon: Icons.mail_outline_rounded,
            title: 'uyelik.bize_eposta_gonderin'.tr(),
            subtitle: 'support@teniskulubu.com',
            onTap: () {
              // TODO: url_launcher ile mailto: aç
            },
          ),
          const SizedBox(height: 12),
          _buildSupportTile(
            context: context,
            icon: Icons.phone_in_talk_outlined,
            title: 'uyelik.bize_ulasin'.tr(),
            subtitle: '+90 (212) XXX XX XX',
            onTap: () {
              // TODO: url_launcher ile tel: aç
            },
          ),
          const SizedBox(height: 24),
          Text(
            'uyelik.sikca_sorulan_sorular'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // ✅ FAQ tile'ları Card içine alındı — SupportTile ile stil tutarlılığı sağlandı
          Card(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                _buildFaqTile(
                  'uyelik.rezervasyonumu_nasil_iptal_ederim'.tr(),
                  'uyelik.rezervasyonlarim_sekmesinden_iptal_edebilirsiniz'.tr(),
                ),
                const Divider(height: 1, color: AppColors.surfaceVariant),
                _buildFaqTile(
                  'uyelik.uyelik_paketimi_nasil_yukseltebilirim'.tr(),
                  'uyelik.paket_yukseltme'.tr(),
                ),
                _buildFaqTile(
                  'uyelik.uyelik_paketimi_nasil_yenilerim'.tr(),
                  'uyelik.paket_yenile'.tr(),
                ),
                _buildFaqTile(
                  'uyelik.ozel_sohbet_grubunu_nasil_olustururum'.tr(),
                  'uyelik.ozel_sohbet_odasi'.tr(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  // ✅ ExpansionTile artık doğrudan Card içinde — tutarlı yüzey rengi
  Widget _buildFaqTile(String title, String content) {
    return ExpansionTile(
      // ✅ Expanded/collapsed arka plan renkleri Card rengiyle eşleştirildi
      backgroundColor: AppColors.surface,
      collapsedBackgroundColor: AppColors.surface,
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}