import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';
import 'package:tenis_kulubu/features/announcements/screens/announcements_screen.dart';

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
            title: const Text('Uygulamadan Çıkılsın mı?'),
            content: const Text('Tenis Kulübü uygulamasından çıkmak istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
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
                    const Text('Hızlı Rezervasyon',
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
                    const Text('Son Duyurular',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => context.go(AppRouter.announcements),
                      child: const Text('Tümü'),
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
                  error: (e, _) => Text('Hata: $e'),
                  data: (items) {
                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: const Center(
                          child: Text('Henüz duyuru yok.',
                              style: TextStyle(color: AppColors.textHint)),
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
                    'Merhaba, ${user?.firstName ?? 'Üye'} 👋',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bugün ne oynamak istersiniz?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMMM y, EEEE', 'tr_TR').format(DateTime.now()),
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
                  context.push(AppRouter.notifications);
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
      _FacilityItem('Tenis Kortu', Icons.sports_tennis, AppColors.courtColor, '6 Kort Mevcut'),
      _FacilityItem('Yüzme\nHavuzu', Icons.pool, AppColors.poolColor, 'Olimpik Havuz'),
      _FacilityItem('Spor\nSalonu', Icons.fitness_center, AppColors.gymColor, 'Tam Donanım'),
      _FacilityItem('Çok Amaçlı\nAlan', Icons.sports_volleyball, AppColors.secondary, 'Basketbol / Voleybol'),
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
            onTap: () => context.go(AppRouter.reservation),
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
                        user.membershipNumber as String,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Aktif Üyelik',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    isCritical
                        ? '⚠️ $daysLeft gün kaldı!'
                        : isWarning
                            ? '$daysLeft gün kaldı, yenilemeyi düşünün'
                            : '$daysLeft gün geçerli',
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
                    DateFormat('d MMMM y', 'tr_TR').format(a.publishedAt),
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