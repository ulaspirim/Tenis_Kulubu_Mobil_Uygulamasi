import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';

class MembershipScreen extends ConsumerWidget {
  const MembershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Hata oluştu')),
      ),
      data: (user) {
        if (user == null) return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Üyeliğim')),
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
                  label: const Text('Üyeliği Yenile'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upgrade_rounded),
                  label: const Text('Paket Yükselt'),
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
      'standard': 'Standart Üyelik',
      'premium': 'Premium Üyelik',
      'family': 'Aile Üyeliği',
      'student': 'Öğrenci Üyeliği',
    }[membershipType] ?? 'Paket';

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
              const Text('Ulaş Tenis Kulübü - Mobil Uygulaması', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isActive ? Colors.greenAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5)),
                ),
                child: Text(
                  isActive ? '● AKTİF' : '● PASİF',
                  style: TextStyle(color: isActive ? Colors.greenAccent : Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(membershipLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(membershipNumber, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ÜYE ADI', style: TextStyle(color: Colors.white54, fontSize: 10)),
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
          const Text(
            'Üyelik Bitimine Kalan',
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
          const Text(
            'gün',
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
    const benefits = [
      '🎾 Tüm kortlara sınırsız erişim',
      '🏊 Havuz öncelikli rezervasyon',
      '💪 Spor salonu ücretsiz kullanım',
      '🏆 Turnuvalara öncelikli kayıt',
      '👥 Misafir kontenjanı: 2 kişi/ay',
      '🎓 Aylık 2 ücretsiz antrenör dersi',
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
            '${{'standard': 'Standart Paket', 'premium': 'Premium Paket', 'family': 'Aile Paketi', 'student': 'Öğrenci Paketi'}[membershipType] ?? 'Paket'} Avantajları',
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
