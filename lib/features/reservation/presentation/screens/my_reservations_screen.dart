import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';
import 'package:tenis_kulubu/features/coach/data/coach_booking_model.dart';
import 'package:tenis_kulubu/features/coach/data/coach_service.dart';

import 'dart:async';

class MyReservationData {
  final String id;
  final String facilityName;
  final String facilityType;
  final String startTime;
  final String endTime;
  final String status;
  final DateTime date;
  final bool isCoachBooking;
  final BookingStatus? coachBookingStatus;

  const MyReservationData({
    required this.id,
    required this.facilityName,
    required this.facilityType,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.date,
    this.isCoachBooking = false,
    this.coachBookingStatus,
  });

  bool get isActive {
    if (isCoachBooking) {
      return coachBookingStatus != BookingStatus.cancelled;
    }
    return status == 'active';
  }

  IconData get icon {
    switch (facilityType) {
      case 'tennis_court':
        return Icons.sports_tennis;
      case 'pool':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      case 'coach':
        return Icons.person;
      default:
        return Icons.sports_volleyball;
    }
  }

  Color get color {
    switch (facilityType) {
      case 'tennis_court':
        return AppColors.courtColor;
      case 'pool':
        return AppColors.poolColor;
      case 'gym':
        return AppColors.gymColor;
      case 'coach':
        return AppColors.warning; // AppColors'a eklenmeli: static const coachColor = Color(0xFFFF9800);
      default:
        return AppColors.secondary;
    }
  }
}

// =========================================================================
// 2. PROVIDER'LAR
// =========================================================================

/// Standart tesis rezervasyonları stream'i
final facilityReservationsProvider = StreamProvider<List<MyReservationData>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;

  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('reservations')
      .where('userId', isEqualTo: user.id)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final d = doc.data();
            return MyReservationData(
              id: doc.id,
              facilityName: d['facilityName'] ?? '',
              facilityType: d['facilityType'] ?? '',
              startTime: d['startTime'] ?? '',
              endTime: d['endTime'] ?? '',
              status: d['status'] ?? 'active',
              date: d['date'] != null
                  ? (d['date'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }).toList());
});

/// Koç rezervasyonları stream'i
final coachReservationsProvider = StreamProvider<List<MyReservationData>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;

  if (user == null) return Stream.value([]);

  // CoachService'i provider dışında tekrar oluşturmamak için burada bir kez alıyoruz.
  final coachService = CoachService();

  return coachService
      .getUserBookings(user.id)
      .map<List<MyReservationData>>((bookings) => bookings.map((b) {
            return MyReservationData(
              id: b.id,
              facilityName: '${b.coachName} - Özel Ders',
              facilityType: 'coach',
              // timeSlot zaten "HH:mm - HH:mm" formatında geliyorsa startTime'a atıyoruz,
              // endTime boş kalıyor; UI'da sadece startTime gösterilecek.
              startTime: b.timeSlot,
              endTime: '',
              status: b.status == BookingStatus.cancelled ? 'cancelled' : 'active',
              date: b.date,
              isCoachBooking: true,
              coachBookingStatus: b.status,
            );
          }).toList())
      // onErrorReturn: stream hata verse bile uygulama çökmez, boş liste döner.
      .transform(
      StreamTransformer.fromHandlers(
        handleError: (error, stack, sink) {
          debugPrint('Koç rezervasyonları alınamadı: $error');
          sink.add([]); // Hata olursa boş liste gönder
        },
      ),
    );
});

/// İki stream'i bellekte birleştiren kombine provider
final myReservationsProvider = Provider<AsyncValue<List<MyReservationData>>>((ref) {
  final facilityAsync = ref.watch(facilityReservationsProvider);
  final coachAsync = ref.watch(coachReservationsProvider);

  if (facilityAsync.isLoading || coachAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (facilityAsync.hasError) {
    return AsyncValue.error(facilityAsync.error!, facilityAsync.stackTrace!);
  }
  if (coachAsync.hasError) {
    return AsyncValue.error(coachAsync.error!, coachAsync.stackTrace!);
  }

  final combined = <MyReservationData>[
  ...facilityAsync.value ?? [],
  ...coachAsync.value ?? [],
]..sort((a, b) => b.date.compareTo(a.date));

  return AsyncValue.data(combined);
});

// =========================================================================
// 3. EKRAN
// =========================================================================

class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  Future<void> _cancelReservation(
    BuildContext context,
    WidgetRef ref,
    MyReservationData reservation,
  ) async {
    try {
      if (reservation.isCoachBooking) {
        final service = CoachService();
        await service.cancelBooking(reservation.id);
      } else {
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservation.id)
            .update({'status': 'cancelled'});
      }

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
            content: Text('İptal edilirken bir hata oluştu: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    MyReservationData reservation,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Rezervasyonu İptal Et',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${reservation.facilityName} için olan rezervasyonunuzu iptal etmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _cancelReservation(context, ref, reservation);
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
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Henüz bir rezervasyonunuz bulunmuyor.',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildReservationCard(context, ref, reservations[index]),
          );
        },
      ),
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    WidgetRef ref,
    MyReservationData res,
  ) {
    final isPast = res.date.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // --- Durum etiketi ve rengi ---
    final String statusLabel;
    final Color statusColor;

    if (!res.isActive) {
      statusLabel = 'İptal Edildi';
      statusColor = AppColors.textHint;
    } else if (isPast) {
      statusLabel = 'Tamamlandı';
      statusColor = AppColors.textHint;
    } else if (res.isCoachBooking) {
      switch (res.coachBookingStatus) {
        case BookingStatus.pending:
          statusLabel = 'Bekliyor';
          statusColor = AppColors.warning;
          break;
        case BookingStatus.confirmed:
          statusLabel = 'Onaylandı';
          statusColor = AppColors.success;
          break;
        default:
          statusLabel = 'Aktif';
          statusColor = AppColors.success;
      }
    } else {
      statusLabel = 'Aktif';
      statusColor = AppColors.success;
    }

    // --- İptal butonu görünürlüğü ---
    // Geçmişte kalan veya iptal edilmiş randevular iptal edilemez.
    // Koç randevularında sadece "Bekliyor" durumundakiler iptal edilebilir.
    final bool canBeCancelled = !isPast &&
        res.isActive &&
        (res.isCoachBooking
            ? res.coachBookingStatus == BookingStatus.pending
            : true);

    // --- Saat gösterimi ---
    // Koç randevularında timeSlot zaten tam aralığı içeriyor (örn. "10:00 - 11:00")
    final String timeDisplay = res.isCoachBooking
        ? res.startTime
        : '${res.startTime} - ${res.endTime}';

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
            // Sol: İkon kutusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: res.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(res.icon, color: res.color, size: 24),
            ),
            const SizedBox(width: 14),

            // Orta: Bilgi alanı
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
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMMM y, EEEE', 'tr_TR').format(res.date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeDisplay,
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

            // Sağ: Durum etiketi + iptal butonu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                if (canBeCancelled) ...[
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: () => _showCancelDialog(context, ref, res),
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
}