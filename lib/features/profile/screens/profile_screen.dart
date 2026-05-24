import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:easy_localization/easy_localization.dart';

// ─────────────────────────────────────────
// PROFİL EKRANI
// ─────────────────────────────────────────
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text(('uyelik.hata').tr())),
      ),
      data: (user) {
        if (user == null) return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

        final initials = '${user.firstName[0]}${user.lastName[0]}'.toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(('uyelik.profilim').tr()),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go(AppRouter.settings),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildAvatarSection(context, user.fullName, user.membershipNumber, user.membershipType, initials),
                const SizedBox(height: 12),
                _buildStatsSection(),
                const SizedBox(height: 12),
                if (user.isAdmin)
                  _buildMenuItem(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'ana_ekran.admin_paneli'.tr(),
                    onTap: () => context.go(AppRouter.admin),
                    color: AppColors.secondary,
                  ),
                _buildMenuSection(context, ref),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(BuildContext context, String fullName, String membershipNumber, String membershipType, String initials) {
    final membershipLabel = {
      'standard': 'uyelik.standart'.tr(),
      'premium': 'uyelik.premium'.tr(),
      'family': 'uyelik.family'.tr(),
      'student': 'uyelik.student'.tr(),
    }[membershipType] ?? 'uyelik.uye'.tr();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      color: AppColors.surface,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            membershipNumber,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              membershipLabel,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          // Rezervasyon sayısı
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservations')
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return _buildStat('$count', 'ana_ekran.rezervasyon'.tr());
              },
            ),
          ),
          _buildDividerWidget(),

          // Turnuva sayısı — şimdilik sabit, ilerleyen adımda dinamik yapılır
          Expanded(child: _buildStat('0', 'ana_ekran.turnuva'.tr())),
          _buildDividerWidget(),

          // Üyelik günü
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snap) {
                final label = 'uyelik.gunluk_uye'.tr();

                if (!snap.hasData) {
                  return _buildStat('-', label);
                }

                final data = snap.data!.data() as Map<String, dynamic>?;
                if (data == null) {
                  return _buildStat('-', label);
                }

                final timestamp = data['createdAt'];
                if (timestamp is! Timestamp) {
                  return _buildStat('-', label);
                }

                final createdAt = timestamp.toDate();
                final days = DateTime.now().difference(createdAt).inDays;

                return _buildStat(
                  '$days',
                  label,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerWidget() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.surfaceVariant,
    );
  }

  Widget _buildMenuSection(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            label: 'uyelik.kisisel_bilgiler'.tr(),
            onTap: () => context.push(AppRouter.personalInfo),
          ),
          _buildMenuItem(
            icon: Icons.calendar_month_outlined,
            label: 'uyelik.rezervasyonlarim'.tr(),
            onTap: () => context.push(AppRouter.myReservations),
          ),
          _buildMenuItem(
            icon: Icons.card_membership_outlined,
            label: 'uyelik.uyelik'.tr(),
            onTap: () => context.push(AppRouter.membership),
          ),
          _buildMenuItem(
            icon: Icons.notifications_outlined,
            label: 'bildirimler.bildirimler'.tr(),
            onTap: () => context.push(AppRouter.notificationSettings),
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            label: 'uyelik.sifre_degistir'.tr(),
            onTap: () => context.push(AppRouter.changePassword),
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            label: 'uyelik.yardim_ve_destek'.tr(),
            onTap: () => context.push(AppRouter.support),
          ),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            label: 'uyelik.cikis_yap'.tr(),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();

              if (context.mounted) {
                context.go(AppRouter.login);
              }
            },
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.surfaceVariant)),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: color ?? AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: color ?? AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
