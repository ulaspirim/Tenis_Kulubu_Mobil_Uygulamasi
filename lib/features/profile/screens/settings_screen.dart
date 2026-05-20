import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';



class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          // ✅ Navigator.of(context).pop() → context.pop() (GoRouter ile tutarlı)
          onPressed: () => context.push(AppRouter.profile),
        ),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Hesap & Tercihler',
            [
              _buildTile(
                title: 'Bildirim Ayarları',
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push(AppRouter.notificationSettings),
              ),
            ],
            context,
          ),
          _buildSection(
            'Uygulama',
            [
              _buildTile(
                title: 'Dil',
                value: 'Türkçe',
                icon: Icons.language_outlined,
                // ✅ Boş fonksiyon verdik, böylece şeffaf görünmeyecek
                onTap: () {}, 
              ),
              _buildTile(
                title: 'Uygulama Versiyonu',
                value: '1.0.0',
                icon: Icons.info_outline,
                onTap: () {}, // ✅ Şeffaflığı kaldırmak için
              ),
              _buildTile(
                title: 'Gizlilik Politikası',
                icon: Icons.privacy_tip_outlined,
                onTap: () {}, // TODO: URL aç
              ),
              _buildTile(
                title: 'Kullanım Koşulları',
                icon: Icons.description_outlined,
                onTap: () {}, // TODO: URL aç
              ),
            ],
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title, List<Widget> children, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ColoredBox(
          color: AppColors.surface,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile({
    required String title,
    String? value,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        // ✅ Eğer null olsa bile şeffaf olmasını istemiyorsan burayı direkt 1.0 yapabilirsin
        opacity: isEnabled ? 1.0 : 0.70, // Tamamen görünmez olmasın diye 0.45'ten 0.70'e çektim
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.surfaceVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              if (value != null && value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textHint),
                  ),
                ),
              // ✅ Tıklanabilir olmasa da ok ikonunu görmek isteyebilirsin diye isEnabled kontrolünü kaldırabilirsin
              if (isEnabled)
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}