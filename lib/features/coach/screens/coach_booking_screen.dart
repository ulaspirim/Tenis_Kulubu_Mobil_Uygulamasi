import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tenis_kulubu/shared/models/coach_model.dart';
import 'package:tenis_kulubu/features/coach/data/coach_booking_model.dart';
import 'package:tenis_kulubu/features/coach/data/coach_service.dart';
import 'package:tenis_kulubu/shared/widgets/time_slot_picker.dart';

class CoachBookingScreen extends StatefulWidget {
  final CoachModel coach;
  const CoachBookingScreen({super.key, required this.coach});

  @override
  State<CoachBookingScreen> createState() => _CoachBookingScreenState();
}

class _CoachBookingScreenState extends State<CoachBookingScreen> {
  final _service = CoachService();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;
  List<String> _bookedSlots = [];
  final _noteController = TextEditingController();
  bool _loading = false;

  // Seçilen günün adını al → availability map key'i
  String get _dayKey {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[_selectedDate.weekday - 1];
  }

  List<String> get _availableSlots =>
      widget.coach.availability[_dayKey] ?? [];

  @override
  void initState() {
    super.initState();
    _loadBookedSlots();
  }

  Future<void> _loadBookedSlots() async {
    final booked = await _service.getBookedSlots(widget.coach.id, _selectedDate);
    setState(() => _bookedSlots = booked);
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir saat seçin.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final booking = CoachBookingModel(
        id: '',
        coachId: widget.coach.id,
        coachName: widget.coach.name,
        userId: user.uid,
        userName: user.displayName ?? 'Üye',
        date: _selectedDate,
        timeSlot: _selectedSlot!,
        price: widget.coach.pricePerHour,
        status: BookingStatus.pending,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      await _service.createBooking(booking);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Randevunuz alındı! Onay bekleniyor.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          '${widget.coach.name} ile Randevu',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Adım 1: Tarih Seçimi ───────────────────────────────────
            const Text('📅 Tarih Seç',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 14, // Önümüzdeki 2 hafta
                itemBuilder: (context, index) {
                  final date = DateTime.now().add(Duration(days: index + 1));
                  final isSelected = _selectedDate.day == date.day &&
                      _selectedDate.month == date.month;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        _selectedSlot = null;
                      });
                      _loadBookedSlots();
                    },
                    child: Container(
                      width: 55,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF1C2128),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayAbbr(date.weekday),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),

            // ── Adım 2: Saat Seçimi ────────────────────────────────────
            const Text('🕐 Saat Seç',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _availableSlots.isEmpty
                ? const Text(
                    'Bu gün için uygun saat yok.',
                    style: TextStyle(color: Colors.white54),
                  )
                : TimeSlotPicker(
                    slots: _availableSlots,
                    bookedSlots: _bookedSlots,
                    selectedSlot: _selectedSlot,
                    onSelected: (slot) => setState(() => _selectedSlot = slot),
                  ),
            const SizedBox(height: 28),

            // ── Adım 3: Not (opsiyonel) ────────────────────────────────
            const Text('📝 Antrenöre Not (opsiyonel)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ör: Backhand çalışmak istiyorum.',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1C2128),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Özet ve Onayla ─────────────────────────────────────────
            if (_selectedSlot != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2128),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} — $_selectedSlot',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.coach.name,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                    Text(
                      '₺${widget.coach.pricePerHour.toInt()}',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading ? null : _confirmBooking,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Randevuyu Onayla',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayAbbr(int weekday) {
    const abbrs = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return abbrs[weekday - 1];
  }
}