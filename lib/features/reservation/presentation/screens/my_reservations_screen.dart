import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';

// Kullanıcının kendi rezervasyonlarını çeken StreamProvider
final myReservationsProvider = StreamProvider<List<MyReservationData>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;

  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('reservations')
      .where('userId', isEqualTo: user.id)
      .snapshots()
      .map((snap) {
    final list = snap.docs.map((doc) {
      final d = doc.data();
      return MyReservationData(
        id: doc.id,
        facilityName: d['facilityName'] ?? '',
        facilityType: d['facilityType'] ?? '',
        startTime: d['startTime'] ?? '',
        endTime: d['endTime'] ?? '',
        status: d['status'] ?? 'active',
        date: d['date'] != null ? (d['date'] as Timestamp).toDate() : DateTime.now(),
      );
    }).toList();

    // Tarihe göre en yakından en uzağa sıralayalım
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  });
});

class MyReservationData {
  final String id;
  final String facilityName;
  final String facilityType;
  final String startTime;
  final String endTime;
  final String status;
  final DateTime date;

  const MyReservationData({
    required this.id,
    required this.facilityName,
    required this.facilityType,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.date,
  });

  bool get isActive => status == 'active';

  IconData get icon {
    switch (facilityType) {
      case 'tennis_court': return Icons.sports_tennis;
      case 'pool': return Icons.pool;
      case 'gym': return Icons.fitness_center;
      default: return Icons.sports_volleyball;
    }
  }

  Color get color {
    switch (facilityType) {
      case 'tennis_court': return AppColors.courtColor;
      case 'pool': return AppColors.poolColor;
      case 'gym': return AppColors.gymColor;
      default: return AppColors.secondary;
    }
  }
}

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  // Rezervasyon İptal Etme Fonksiyonu
  Future<void> _cancelReservation(BuildContext context, String id) async {
    try {
      // Doğrudan silmek yerine status'ü 'cancelled' yapıyoruz ki geçmişte görünsün
      // Veya istersen direkt .delete() de yapabilirsin.
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(id)
          .update({'status': 'cancelled'});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervasyon başarıyla iptal edildi.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İptal edilirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCancelDialog(BuildContext context, MyReservationData reservation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rezervasyonu İptal Et', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('${reservation.facilityName} için olan rezervasyonunuzu iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _cancelReservation(context, reservation.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(myReservationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rezervasyonlarım'),
      ),
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata oluştu: $e')),
        data: (reservations) {
          if (reservations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 56, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('Henüz bir rezervasyonunuz bulunmuyor.',
                      style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final res = reservations[index];
              return _buildReservationCard(context, res);
            },
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, MyReservationData res) {
    final isPast = res.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Sol Taraf: İkon Alanı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: res.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(res.icon, color: res.color, size: 24),
            ),
            const SizedBox(width: 14),
            
            // Orta Taraf: Rezervasyon Bilgileri
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    res.facilityName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMMM y, EEEE', 'tr_TR').format(res.date),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${res.startTime} - ${res.endTime}',
                        style: const TextStyle(
                          fontSize: 12, 
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Sağ Taraf: Durum Etiketi veya İptal Butonu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: res.isActive && !isPast
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    !res.isActive 
                        ? 'İptal Edildi' 
                        : isPast 
                            ? 'Tamamlandı' 
                            : 'Aktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: res.isActive && !isPast ? AppColors.success : AppColors.textHint,
                    ),
                  ),
                ),
                if (res.isActive && !isPast) ...[
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                    onPressed: () => _showShowCancelDialog(context, res),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'İptal Et',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Küçük bir yazım düzeltmesi için wrapper
  void _showShowCancelDialog(BuildContext context, MyReservationData res) {
    _showCancelDialog(context, res);
  }
}