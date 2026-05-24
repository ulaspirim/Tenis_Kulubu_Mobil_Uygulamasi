import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';
import 'package:tenis_kulubu/features/coach/data/coach_booking_model.dart';
import 'package:tenis_kulubu/features/coach/data/coach_service.dart';

import 'package:easy_localization/easy_localization.dart';

// =========================================================================
// 1. VERİ MODELİ (Genişletilmiş MyReservationData)
// =========================================================================
class MyReservationData {
  final String id;
  final String facilityName;
  final String facilityType;
  final String startTime;
  final String endTime;
  final String status;
  final DateTime date;
  final bool isCoachBooking; // Koç randevusu ayrımı için
  final BookingStatus? coachBookingStatus; // Koç randevusunun detay durumu için

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

  bool get isActive => isCoachBooking 
      ? (coachBookingStatus != BookingStatus.cancelled)
      : (status == 'active');

  IconData get icon {
    switch (facilityType) {
      case 'tennis_court': return Icons.sports_tennis;
      case 'pool': return Icons.pool;
      case 'gym': return Icons.fitness_center;
      case 'coach': return Icons.person; // Özel ders koçu ikonu
      default: return Icons.sports_volleyball;
    }
  }

  Color get color {
    switch (facilityType) {
      case 'tennis_court': return AppColors.courtColor;
      case 'pool': return AppColors.poolColor;
      case 'gym': return AppColors.gymColor;
      case 'coach': return Colors.orange; // Koç kartları için tema rengi
      default: return AppColors.secondary;
    }
  }
}

// =========================================================================
// 2. DATA PROVIDERLAR (Tesis ve Koç Rezervasyonları Akışları)
// =========================================================================

// Standart Tesis Rezervasyonları Stream'i
final facilityReservationsProvider = StreamProvider<List<MyReservationData>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;

  if (user == null) return Stream.value([]);

  // Sadece userId filtresi uyguluyoruz, orderBy eklemiyoruz (İndeks hatasını önlemek için)
  return FirebaseFirestore.instance
      .collection('reservations')
      .where('userId', isEqualTo: user.id)
      .snapshots()
      .map((snap) {
    return snap.docs.map((doc) {
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
  });
});

// Koç Rezervasyonları Stream'i
// Koç Rezervasyonları Stream'i (İndeks hatasını önlemek için sıralamayı cihazda yapacağız)
final coachReservationsProvider = StreamProvider<List<MyReservationData>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;

  if (user == null) return Stream.value([]);

  final coachService = CoachService();
  return coachService.getUserBookings(user.id).map((bookings) {
    final list = bookings.map((b) {
      String statusStr = 'active';
      if (b.status == BookingStatus.cancelled) statusStr = 'cancelled';

      return MyReservationData(
        id: b.id,
        facilityName: '${b.coachName} - ${'coach.ozel_ders'.tr()}',
        facilityType: 'coach',
        startTime: b.timeSlot,
        endTime: '', 
        status: statusStr,
        date: b.date,
        isCoachBooking: true,
        coachBookingStatus: b.status,
      );
    }).toList();
    
    return list;
  }).handleError((error) {
    // Eğer koç servisinde hala indeks hatası varsa uygulamayı çökertmesin, 
    // boş liste dönsün ve sadece tesis rezervasyonları listelenebilsin.
    debugPrint("${'coach.servis_indeksi'.tr()}: $error");
    return <MyReservationData>[];
  });
});

// Kombine Rezervasyon Listesi Provider'ı (İki akışı bellek üzerinde birleştirir ve sıralar)
final myReservationsProvider = Provider<AsyncValue<List<MyReservationData>>>((ref) {
  final facilityResAsync = ref.watch(facilityReservationsProvider);
  final coachResAsync = ref.watch(coachReservationsProvider);

  // İki akıştan herhangi biri yükleniyorsa yükleniyor durumunu dön
  if (facilityResAsync.isLoading || coachResAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Herhangi biri hata veriyorsa hata durumunu dön
  if (facilityResAsync.hasError) return AsyncValue.error(facilityResAsync.error!, facilityResAsync.stackTrace!);
  if (coachResAsync.hasError) return AsyncValue.error(coachResAsync.error!, coachResAsync.stackTrace!);

  final facilities = facilityResAsync.value ?? [];
  final coaches = coachResAsync.value ?? [];

  // Listeleri birleştir
  final combinedList = [...facilities, ...coaches];

  // Sıralama işlemini Firestore yerine cihaz belleğinde yapıyoruz. (Hata vermesini engeller)
  // Tarihe göre en yakından en uzağa sıralama yap (En yeni randevu en üstte)
  combinedList.sort((a, b) => b.date.compareTo(a.date));

  return AsyncValue.data(combinedList);
});

// =========================================================================
// 3. UI KATMANI (MyReservationsScreen Ekranı)
// =========================================================================
class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  // Tipe göre dinamik iptal operasyonu
  Future<void> _cancelReservation(BuildContext context, MyReservationData reservation) async {
    try {
      if (reservation.isCoachBooking) {
        // Koç ders rezervasyonunu iptal et
        final service = CoachService();
        await service.cancelBooking(reservation.id);
      } else {
        // Tesis rezervasyonunu iptal et
        await FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservation.id)
            .update({'status': 'cancelled'});
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('coach.rezervasyon_iptal_edildi'.tr()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('coach.hata_randevu'.tr()),
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
        title: Text('rezervasyon.iptal'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'rezervasyon.iptal_onay'.tr(
            args: [reservation.facilityName],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('uygulama.vazgec'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _cancelReservation(context, reservation);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('coach.iptal_et'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kombine ettiğimiz yeni rezervasyon provider'ını dinliyoruz
    final reservationsAsync = ref.watch(myReservationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('uyelik.rezervasyonlarim'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: reservationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata oluştu: $e')),
        data: (reservations) {
          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 56, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text(
                    'coach.rezervasyon_yok'.tr(),
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
    
    // Temel durum etiket ve renk atamaları
    String statusLabel = !res.isActive ? 'coach.iptal_edildi'.tr() : (isPast ? 'coach.tamamlandi'.tr() : 'coach.aktif'.tr());
    Color statusColor = res.isActive && !isPast ? AppColors.success : AppColors.textHint;

    // Koç Randevularına Özel Durum Etiket Yönetimi (Bekliyor / Onaylandı durumları için)
    if (res.isCoachBooking && res.isActive && !isPast) {
      if (res.coachBookingStatus == BookingStatus.pending) {
        statusLabel = 'coach.bekliyor'.tr();
        statusColor = Colors.orange;
      } else if (res.coachBookingStatus == BookingStatus.confirmed) {
        statusLabel = 'coach.onaylandi'.tr();
        statusColor = const Color(0xFF4CAF50);
      }
    }

    // İptal Butonu Görünme Mantığı
    // Sadece geçmişte kalmayan ve aktif olan randevular iptal edilebilir.
    // Koç randevularında ise sadece 'pending' (Bekliyor) olanlar iptal edilebilir durumda bırakılmıştır.
    bool canBeCancelled = false;
    if (!isPast && res.isActive) {
      if (res.isCoachBooking) {
        canBeCancelled = res.coachBookingStatus == BookingStatus.pending;
      } else {
        canBeCancelled = true;
      }
    }
    
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
            // 1. Sol Bölüm: Dinamik İkon Kutusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: res.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(res.icon, color: res.color, size: 24),
            ),
            const SizedBox(width: 14),
            
            // 2. Orta Bölüm: Detay Bilgileri
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
                        res.isCoachBooking ? res.startTime : '${res.startTime} - ${res.endTime}',
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
            
            // 3. Sağ Bölüm: Durum Etiketi ve İptal Aksiyonu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                    onPressed: () => _showCancelDialog(context, res),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    tooltip: 'coach.iptal_et'.tr(),
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