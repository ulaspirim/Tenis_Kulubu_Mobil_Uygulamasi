import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tenis_kulubu/shared/models/coach_model.dart';
import 'package:tenis_kulubu/features/coach/screens/coach_booking_screen.dart';
import 'package:tenis_kulubu/features/coach/data/coach_booking_model.dart';

class CoachService {
  final _db = FirebaseFirestore.instance;

  // ── Tüm antrenörleri getir ──────────────────────────────────────────────
  Stream<List<CoachModel>> getCoaches() {
    return _db.collection('coaches').snapshots().map((snap) =>
        snap.docs.map((doc) => CoachModel.fromMap(doc.data(), doc.id)).toList());
  }

  // ── Belirli bir antrenörü getir ─────────────────────────────────────────
  Future<CoachModel?> getCoachById(String coachId) async {
    final doc = await _db.collection('coaches').doc(coachId).get();
    if (!doc.exists) return null;
    return CoachModel.fromMap(doc.data()!, doc.id);
  }

  // ── Belirli gün ve antrenör için DOLU slotları getir ───────────────────
  Future<List<String>> getBookedSlots(String coachId, DateTime date) async {
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));

  final snap = await _db
      .collection('coach_bookings')
      .where('coachId', isEqualTo: coachId)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('date', isLessThan: Timestamp.fromDate(end))
      .get();

  // status filtresini kod tarafında yap
  return snap.docs
      .where((d) => d['status'] == 'pending' || d['status'] == 'confirmed')
      .map((d) => d['timeSlot'] as String)
      .toList();
}

  // ── Randevu oluştur ─────────────────────────────────────────────────────
  Future<void> createBooking(CoachBookingModel booking) async {
    // Çakışma kontrolü
    final booked = await getBookedSlots(booking.coachId, booking.date);
    if (booked.contains(booking.timeSlot)) {
      throw Exception('Bu saat dolu, lütfen başka bir saat seçin.');
    }

    await _db.collection('coach_bookings').add(booking.toMap());
  }

  // ── Kullanıcının randevularını getir ────────────────────────────────────
  Stream<List<CoachBookingModel>> getUserBookings(String userId) {
    return _db
        .collection('coach_bookings')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CoachBookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Antrenörün randevularını getir (Admin / Antrenör görünümü) ──────────
  Stream<List<CoachBookingModel>> getCoachBookings(String coachId) {
    return _db
        .collection('coach_bookings')
        .where('coachId', isEqualTo: coachId)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CoachBookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Randevu iptal et ────────────────────────────────────────────────────
  Future<void> cancelBooking(String bookingId) async {
    await _db.collection('coach_bookings').doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
    });
  }

  // ── Admin: Randevuyu onayla ─────────────────────────────────────────────
  Future<void> confirmBooking(String bookingId) async {
    await _db.collection('coach_bookings').doc(bookingId).update({
      'status': BookingStatus.confirmed.name,
    });
  }
}