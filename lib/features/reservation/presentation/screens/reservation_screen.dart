import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/auth/data/auth_repository.dart';

// ─────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────
final facilitiesProvider = StreamProvider<List<FacilityData>>((ref) {
  return FirebaseFirestore.instance
      .collection('facilities')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final d = doc.data();
            return FacilityData(
              id: doc.id,
              name: d['name'] ?? '',
              type: d['type'] ?? '',
              capacity: d['capacity'] ?? 1,
              openTime: d['openTime'] ?? '07:00',
              closeTime: d['closeTime'] ?? '23:00',
              description: d['description'],
            );
          }).toList());
});

// ─────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────
class FacilityData {
  final String id;
  final String name;
  final String type;
  final int capacity;
  final String openTime;
  final String closeTime;
  final String? description;

  const FacilityData({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.openTime,
    required this.closeTime,
    this.description,
  });

  IconData get icon {
    switch (type) {
      case 'tennis_court': return Icons.sports_tennis;
      case 'pool': return Icons.pool;
      case 'gym': return Icons.fitness_center;
      default: return Icons.sports_volleyball;
    }
  }

  Color get color {
    switch (type) {
      case 'tennis_court': return AppColors.courtColor;
      case 'pool': return AppColors.poolColor;
      case 'gym': return AppColors.gymColor;
      default: return AppColors.secondary;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'tennis_court': return '🎾 Tenis Kortu';
      case 'pool': return '🏊 Havuz';
      case 'gym': return '💪 Spor Salonu';
      default: return '🏐 Çok Amaçlı';
    }
  }
}

// ─────────────────────────────────────────
// REZERVASYON EKRANI
// ─────────────────────────────────────────
class ReservationScreen extends ConsumerStatefulWidget {
  const ReservationScreen({super.key});

  @override
  ConsumerState<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends ConsumerState<ReservationScreen> {
  int _currentStep = 0;
  FacilityData? _selectedFacility;
  DateTime _selectedDay = DateTime.now();
  String? _selectedTimeSlot;
  bool _isLoading = false;
  
  // DEĞİŞİKLİK: Hangi saat diliminde kaç rezervasyon olduğunu saymak için Map yapısına geçildi
  Map<String, int> _slotReservationCounts = {};

  List<String> get _timeSlots {
    final slots = <String>[];
    var hour = 7;
    while (hour < 23) {
      final start = '${hour.toString().padLeft(2, '0')}:00';
      final end = '${(hour + 1).toString().padLeft(2, '0')}:00';
      slots.add('$start – $end');
      hour++;
    }
    return slots;
  }

  Future<bool> _loadBookedSlots() async {
    if (_selectedFacility == null) return false;

    setState(() => _isLoading = true);

    try {
      final startOfDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snap = await FirebaseFirestore.instance
          .collection('reservations')
          .where('facilityId', isEqualTo: _selectedFacility!.id)
          .where('status', isEqualTo: 'active')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // DEĞİŞİKLİK: Rezervasyon sayıları her saat dilimi için hesaplanıyor
      final Map<String, int> counts = {};
      for (var doc in snap.docs) {
        final key = '${doc['startTime']} – ${doc['endTime']}';
        counts[key] = (counts[key] ?? 0) + 1;
      }

      setState(() {
        _slotReservationCounts = counts;
        _isLoading = false;
      });
      return true;
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('🔥 FIRESTORE HATASI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saatler yüklenemedi. İndeks eksik olabilir.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return false;
    }
  }

  Future<void> _confirmReservation() async {
    setState(() => _isLoading = true);

    try {
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;
      if (user == null) throw Exception('Kullanıcı bulunamadı');

      final slot = _selectedTimeSlot!.split(' – ');

      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.id,
        'userFullName': user.fullName,
        'facilityId': _selectedFacility!.id,
        'facilityName': _selectedFacility!.name,
        'facilityType': _selectedFacility!.type,
        'date': Timestamp.fromDate(_selectedDay),
        'startTime': slot[0],
        'endTime': slot[1],
        'status': 'active',
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 56),
            ),
            const SizedBox(height: 20),
            const Text('Rezervasyon Oluşturuldu!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '${_selectedFacility!.name}\n'
              '${DateFormat('d MMMM y', 'tr_TR').format(_selectedDay)}\n'
              '$_selectedTimeSlot',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _currentStep = 0;
                    _selectedFacility = null;
                    _selectedTimeSlot = null;
                    _slotReservationCounts = {};
                  });
                },
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rezervasyon'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() {
                _currentStep = 0;
                _selectedFacility = null;
                _selectedTimeSlot = null;
                _slotReservationCounts = {};
              }),
              child: const Text('Sıfırla'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildFacilityStep(),
                _buildCalendarStep(),
                _buildTimeSlotStep(),
                _buildConfirmStep(),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Tesis', 'Tarih', 'Saat', 'Onay'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: List.generate(steps.length, (i) {
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColors.success
                              : isActive
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                      color: isActive ? Colors.white : AppColors.textHint,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[i],
                          style: TextStyle(
                              fontSize: 10,
                              color: isActive ? AppColors.primary : AppColors.textHint,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: i < _currentStep ? AppColors.success : AppColors.surfaceVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFacilityStep() {
    final facilitiesAsync = ref.watch(facilitiesProvider);

    return facilitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (facilities) {
        if (facilities.isEmpty) {
          return const Center(
            child: Text('Henüz tesis eklenmemiş.',
                style: TextStyle(color: AppColors.textHint)),
          );
        }

        final grouped = <String, List<FacilityData>>{};
        for (final f in facilities) {
          grouped.putIfAbsent(f.type, () => []).add(f);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: grouped.entries.map((entry) {
              final label = entry.value.first.typeLabel;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  ...entry.value.map((f) => _buildFacilityTile(f)),
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFacilityTile(FacilityData f) {
    final isSelected = _selectedFacility?.id == f.id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedFacility = f;
        _selectedTimeSlot = null;
        _slotReservationCounts = {};
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? f.color.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? f.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [] : AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: f.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(f.icon, color: f.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary)),
                  Text('Kapasite: ${f.capacity} kişi',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  if (f.description != null)
                    Text(f.description!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: f.color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 14)),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _selectedTimeSlot = null;
                  _slotReservationCounts = {};
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              locale: 'tr_TR',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'En fazla 14 gün önceden rezervasyon yapabilirsiniz.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotStep() {
    final maxCapacity = _selectedFacility?.capacity ?? 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('d MMMM y, EEEE', 'tr_TR').format(_selectedDay),
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(_selectedFacility?.name ?? '',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // Lejant
          Row(
            children: [
              _buildLegend(AppColors.primary.withOpacity(0.08),
                  AppColors.primary, 'Müsait'),
              const SizedBox(width: 16),
              _buildLegend(const Color.fromARGB(255, 151, 23, 23).withOpacity(0.12), 
                  const Color.fromARGB(255, 151, 23, 23), 'Dolu'),
              const SizedBox(width: 16),
              _buildLegend(AppColors.primary, Colors.white, 'Seçili'),
            ],
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5, // Metin sığması için oran biraz artırıldı
            ),
            itemCount: _timeSlots.length,
            itemBuilder: (context, i) {
              final slot = _timeSlots[i];
              final currentBookedCount = _slotReservationCounts[slot] ?? 0;
              
              // DEĞİŞİKLİK: Sadece rezervasyon sayısı tesis kapasitesine ulaştığında slot tam dolu sayılır
              final isFullyBooked = currentBookedCount >= maxCapacity;
              final isSelected = _selectedTimeSlot == slot;

              // Doluluk durumuna göre dinamik renkler belirleniyor
              final Color slotBgColor = isSelected
                  ? AppColors.primary
                  : isFullyBooked
                      ? const Color.fromARGB(255, 151, 23, 23).withOpacity(0.12)
                      : AppColors.primary.withOpacity(0.08);

              final Color slotTextColor = isSelected
                  ? Colors.white
                  : isFullyBooked
                      ? const Color.fromARGB(255, 151, 23, 23)
                      : AppColors.primary;

              final Border? slotBorder = isSelected
                  ? null
                  : Border.all(
                      color: isFullyBooked
                          ? const Color.fromARGB(255, 151, 23, 23).withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.2),
                      width: 1,
                    );

              return GestureDetector(
                onTap: isFullyBooked
                    ? null
                    : () => setState(() => _selectedTimeSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: slotBgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: slotBorder,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slot.split('–')[0].trim(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: slotTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Kapasite bilgisini anlık olarak kartın içinde gösteriyoruz
                        Text(
                          isFullyBooked ? 'DOLU' : '$currentBookedCount/$maxCapacity Kişi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: slotTextColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color bg, Color text, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Rezervasyon Özeti',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                _buildConfirmRow(Icons.sports_tennis, 'Tesis',
                    _selectedFacility?.name ?? '-'),
                const Divider(height: 24),
                _buildConfirmRow(
                    Icons.calendar_today,
                    'Tarih',
                    DateFormat('d MMMM y, EEEE', 'tr_TR')
                        .format(_selectedDay)),
                const Divider(height: 24),
                _buildConfirmRow(
                    Icons.access_time, 'Saat', _selectedTimeSlot ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📋 Rezervasyon Kuralları',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.info)),
                SizedBox(height: 8),
                Text(
                  '• Rezervasyonu iptal etmek için en az 2 saat öncesinden işlem yapınız.\n'
                  '• Rezervasyon saatinden 10 dakika sonrasında gelmezseniz rezervasyonunuz iptal edilir.\n'
                  '• Spor ekipmanları girişte teslim alınabilir.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textHint)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final canProceed = switch (_currentStep) {
      0 => _selectedFacility != null,
      1 => true,
      2 => _selectedTimeSlot != null,
      _ => true,
    };

    final labels = ['Tarih Seç', 'Saat Seç', 'Onayla', 'Rezervasyonu Oluştur'];

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: canProceed
              ? () async {
                  if (_currentStep == 1) {
                    final success = await _loadBookedSlots();
                    if (!success) return; 
                  }
                  
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    await _confirmReservation();
                  }
                }
              : null,
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Text(labels[_currentStep]),
        ),
      ),
    );
  }
}

class ReservationDetailScreen extends StatelessWidget {
  final String reservationId;
  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rezervasyon Detayı')),
        body: Center(child: Text('Rezervasyon: $reservationId')),
      );
}