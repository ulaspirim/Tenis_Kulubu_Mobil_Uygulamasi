import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/announcements/screens/notification_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Riverpod state'ini dinliyoruz
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('bildirim_ayarlari'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          // ✅ Bir önceki sayfada yazdığımız güvenli pop mantığı
          onPressed: () => context.canPop() ? context.pop() : Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('bildirimler.bildirimler'.tr().toUpperCase()),
          _buildSwitchTile(
            title: 'bildirimler.uygulama'.tr(),
            subtitle: 'bildirimler.uygulama_aciklama'.tr(),
            value: settings.appNotifications,
            onChanged: notifier.toggleAppNotifications,
          ),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          _buildSwitchTile(
            title: 'bildirimler.email'.tr(),
            subtitle: 'bildirimler.email_aciklama'.tr(),
            value: settings.emailNotifications,
            onChanged: notifier.toggleEmailNotifications,
          ),
          
          _buildSectionHeader('bildirimler.kulup_ve_kort'.tr()),
          _buildSwitchTile(
            title: 'bildirimler.rezervasyon'.tr(),
            subtitle: 'bildirimler.rezervasyon_aciklama'.tr(),
            value: settings.courtReminders,
            onChanged: notifier.toggleCourtReminders,
          ),
          const Divider(height: 1, color: AppColors.surfaceVariant),
          _buildSwitchTile(
            title: 'bildirimler.duyurularr'.tr(),
            subtitle: 'bildirimler.duyurularr_aciklama'.tr(),
            value: settings.announcementAlerts,
            onChanged: notifier.toggleAnnouncementAlerts,
          ),
          
          Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'bildirimler.cihaz_ayarlari'.tr(),
              style: TextStyle(fontSize: 12, color: AppColors.textHint, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Bölüm başlıkları için küçük estetik helper
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: SwitchListTile.adaptive( // ✅ iOS ve Android'de yerel görünüm için .adaptive yaptık
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
          value: value,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ),
    );
  }
}