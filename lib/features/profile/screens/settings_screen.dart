import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';

// ─── Desteklenen diller ───────────────────────────────────────────────────────
class _Language {
  final String label;      // Ekranda gösterilecek isim
  final String nativeLabel; // Dilin kendi adı
  final String flagEmoji;
  final Locale locale;

  const _Language({
    required this.label,
    required this.nativeLabel,
    required this.flagEmoji,
    required this.locale,
  });
}

const _languages = [
  _Language(label: 'Türkçe',     nativeLabel: 'Türkçe',     flagEmoji: '🇹🇷', locale: Locale('tr')),
  _Language(label: 'İngilizce',  nativeLabel: 'English',    flagEmoji: '🇬🇧', locale: Locale('en')),
  _Language(label: 'Rusça',      nativeLabel: 'Русский',    flagEmoji: '🇷🇺', locale: Locale('ru')),
  _Language(label: 'Ukraynaca',  nativeLabel: 'Українська', flagEmoji: '🇺🇦', locale: Locale('uk')),
];
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Şu anki locale'e göre seçili dil objesini döner
  _Language _currentLanguage(BuildContext context) {
    final code = context.locale.languageCode;
    return _languages.firstWhere(
      (l) => l.locale.languageCode == code,
      orElse: () => _languages.first,
    );
  }

  // Dil seçici bottom sheet
  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final currentCode = context.locale.languageCode;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Icon(Icons.language_outlined, size: 20,
                        color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      'Dil Seçin',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceVariant),

              // Dil listesi
              ...(_languages.map((lang) {
                final isSelected = lang.locale.languageCode == currentCode;
                return InkWell(
                  onTap: () {
                    context.setLocale(lang.locale);
                    Navigator.pop(sheetContext);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.surfaceVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Bayrak
                        Text(lang.flagEmoji,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 14),
                        // Dil isimleri
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang.nativeLabel, // "English", "Русский" ...
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Theme.of(context).primaryColor
                                      : null,
                                ),
                              ),
                              Text(
                                lang.label, // "İngilizce", "Rusça" ...
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                        // Seçili işareti
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              size: 20,
                              color: Theme.of(context).primaryColor),
                      ],
                    ),
                  ),
                );
              })),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = _currentLanguage(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
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
              // ✅ Dil tile'ı — seçili dili gösteriyor, tıklayınca picker açılıyor
              _buildTile(
                title: 'Dil',
                value: '${currentLang.flagEmoji} ${currentLang.nativeLabel}',
                icon: Icons.language_outlined,
                onTap: () => _showLanguagePicker(context),
              ),
              _buildTile(
                title: 'Uygulama Versiyonu',
                value: '1.0.0',
                icon: Icons.info_outline,
                onTap: null, // Tıklanamaz, ok ikonu gösterilmez
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
        opacity: isEnabled ? 1.0 : 0.70,
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