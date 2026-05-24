import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';

import 'package:easy_localization/easy_localization.dart';

class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('ana_ekran.hata_olustu'.tr())),
      ),
      data: (user) {
        if (user == null) return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: Text('uyelik.uyelik'.tr())),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMembershipCard(user.fullName, user.membershipNumber, user.membershipType, user.membershipStatus),
                const SizedBox(height: 20),
                _buildDaysLeftCard(user.daysUntilExpiry),
                const SizedBox(height: 16),
                _buildBenefitsCard(user.membershipType),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.autorenew_rounded),
                  label: Text('ana_ekran.uyeligi_yenile'.tr()),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upgrade_rounded),
                  label: Text('ana_ekran.paket_yukselt'.tr()),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembershipCard(String fullName, String membershipNumber, String membershipType, String membershipStatus) {
    final isActive = membershipStatus == 'active';

  final membershipLabel = {
    'standard':    'admin.uyelik_tipi_standard'.tr(),
    'premium':     'admin.uyelik_tipi_premium'.tr(),
    'family':      'admin.uyelik_tipi_family'.tr(),
    'special':     'admin.uyelik_tipi_special'.tr(),
    'club_player': 'admin.uyelik_tipi_club_player'.tr(),
  }[membershipType] ?? membershipType; 
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Expanded(
                  child: Text(
                    'club_name'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
                ),
                child: Text(
                  isActive ? 'ana_ekran.aktif'.tr() : 'ana_ekran.pasif'.tr(),
                  style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text('admin.uyelik_tipi'.tr(), style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(membershipLabel, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ana_ekran.uye_adi'.tr(), style: TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysLeftCard(int daysLeft) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            'ana_ekran.uyelik_bitimine_kalan'.tr(),
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            '$daysLeft',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          Text(
            'ana_ekran.gun'.tr(),
            style: TextStyle(color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: daysLeft / 365,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(String membershipType) {
    final benefits = [
      'ana_ekran.sinirsiz'.tr(),
      'ana_ekran.havuz'.tr(),
      'ana_ekran.spor_salonu'.tr(),
      'ana_ekran.turnuvalara'.tr(),
      'ana_ekran.misafir'.tr() ,
      'ana_ekran.antrenor'.tr(),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${{
              'standard': 'uyelik.standart'.tr(),
              'premium': 'uyelik.premium'.tr(),
              'family': 'uyelik.aile'.tr(),
              'student': 'uyelik.ogrenci'.tr(),
            }[membershipType] ?? 'uyelik.paket'.tr()} '
            '${'uyelik.avantajlari'.tr()}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...benefits.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
