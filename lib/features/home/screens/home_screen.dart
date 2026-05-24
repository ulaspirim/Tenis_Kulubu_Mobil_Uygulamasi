import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';
import 'package:tenis_kulubu/features/announcements/screens/announcements_screen.dart';
import 'package:tenis_kulubu/features/coach/screens/coach_list_screen.dart';

import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return PopScope(
      canPop: false, // Sistem geri hareketinin uygulamadan doğrudan çıkmasını engeller
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Kullanıcıya çıkmak isteyip istemediğini soran onay kutusu
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('uygulama.cikis_yapilsin_mi').tr(),
            content: Text('uygulama.emin_misiniz').tr(),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('uygulama.vazgec').tr(),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('uygulama.cikis_yap').tr(),
              ),
            ],
          ),
        );

        // Eğer kullanıcı "Çıkış Yap" dediyse uygulamayı kapatmaya izin ver
        if (shouldExit == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context, userAsync),
            ),

            // Hızlı Erişim
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(('uygulama.hizli_rezervasyon').tr(),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 14),
                    _buildFacilityCards(context),
                  ],
                ),
              ),
            ),

            // Üyelik Kartı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: userAsync.when(
                  data: (user) => user != null
                      ? _buildMembershipCard(context, user)
                      : const SizedBox.shrink(),
                  loading: () => _buildSkeleton(height: 100),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Duyurular Başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(('uygulama.son_duyurular').tr(),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => context.go(AppRouter.announcements),
                      child: Text(('uygulama.tum_duyurular').tr()),
                    ),
                  ],
                ),
              ),
            ),

            // Duyurular
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: announcementsAsync.when(
                  loading: () => _buildSkeleton(height: 200),
                  error: (e, _) => Text(('uygulama.hata').tr() + ': $e'),
                  data: (items) {
                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Center(
                          child: Text(
                            'uygulama.henuz_duyuru_yok'.tr(),
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ),
                      );
                    }

                    // En fazla 3 duyuru göster
                    final preview = items.take(3).toList();
                    return Column(
                      children: preview
                          .map((a) => _buildAnnouncementTile(context, a))
                          .toList(),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue userAsync) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      child: Row(
        children: [
          Expanded(
            child: userAsync.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'ana_ekran.hosgeldin'.tr()} ${user?.firstName ?? 'uyelik.uye'.tr()} 👋',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'uygulama.bugun_ne_istersiniz'.tr(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMMM y, EEEE', context.locale.toString()).format(DateTime.now()),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 26),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  // Bildirim butonunu aktif hale getirdik:
                  context.go(AppRouter.notifications);
                },
              ),
              GestureDetector(
                onTap: () => context.push(AppRouter.profile),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCards(BuildContext context) {
    final facilities = [
      _FacilityItem('uygulama.tenis_kortu'.tr(), Icons.sports_tennis, AppColors.courtColor, 'uygulama.toplam_kort'.tr()),
      _FacilityItem('uygulama.yuzme_havuzu'.tr(), Icons.pool, AppColors.poolColor, 'uygulama.olimpik_havuz'.tr()),
      _FacilityItem('uygulama.spor_salonu'.tr(), Icons.fitness_center, AppColors.gymColor, 'uygulama.tam_donanim'.tr()),
      _FacilityItem('uygulama.cok_amacli_alan'.tr(), Icons.sports_volleyball, AppColors.secondary, 'uygulama.pickleball_ve_daha_fazlası'.tr()),
      _FacilityItem('uygulama.antrenor_dersi'.tr(), Icons.person_pin, Colors.greenAccent, 'uygulama.özel_ders_al'.tr()),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: facilities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final f = facilities[i];
          return GestureDetector(
            onTap: () {
              if (f.label == 'uygulama.antrenor_dersi'.tr()) {
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CoachListScreen()));
                return;
              }
              context.go(AppRouter.reservation);
            },
            child: Container(
              width: 110,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: f.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(f.icon, color: f.color, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2)),
                      const SizedBox(height: 2),
                      Text(f.subtitle,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMembershipCard(BuildContext context, dynamic user) {
    final daysLeft = user.daysUntilExpiry as int;
    final isCritical = daysLeft <= 7;
    final isWarning = daysLeft <= 30;

    final membershipLabel = {
      'standard':    'admin.uyelik_tipi_standard'.tr(),
      'premium':     'admin.uyelik_tipi_premium'.tr(),
      'family':      'admin.uyelik_tipi_family'.tr(),
      'special':     'admin.uyelik_tipi_special'.tr(),
      'club_player': 'admin.uyelik_tipi_club_player'.tr(),
    }[user.membershipType] ?? user.membershipType;

    return GestureDetector(
      onTap: () => context.go(AppRouter.membership),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isCritical
              ? const LinearGradient(
                  colors: [Color(0xFFC62828), Color(0xFFE53935)])
              : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.elevatedShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_membership,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        membershipLabel as String,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('uygulama.aktif_uyelik'.tr(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    isCritical
                        ? 'uygulama.uyelik_suresi_kalan'.tr(args: ['$daysLeft'])
                        : isWarning
                            ? 'uygulama.uyelik_suresi_kalan_warning'.tr(args: ['$daysLeft'])
                            : 'uygulama.uyelik_suresi_kalan_ok'.tr(args: ['$daysLeft']),
                    style: TextStyle(
                      color: isCritical ? Colors.yellow : Colors.white70,
                      fontSize: 13,
                      fontWeight: isCritical ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementTile(BuildContext context, AnnouncementData a) {
    return GestureDetector(
      onTap: () => context.go(AppRouter.announcements),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMMM y', context.locale.toString()).format(a.publishedAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: a.categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                a.categoryLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: a.categoryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _FacilityItem {
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _FacilityItem(this.label, this.icon, this.color, this.subtitle);
}