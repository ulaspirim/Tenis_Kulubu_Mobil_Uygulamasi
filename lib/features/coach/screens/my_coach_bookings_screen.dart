import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tenis_kulubu/features/coach/data/coach_booking_model.dart';
import 'package:tenis_kulubu/features/coach/data/coach_service.dart';

import 'package:easy_localization/easy_localization.dart';

class MyCoachBookingsScreen extends StatelessWidget {
  const MyCoachBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final service = CoachService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text('coach.randevularim'.tr(),
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<CoachBookingModel>>(
        stream: service.getUserBookings(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('coach.randevu_yok'.tr(),
                  style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final booking = snapshot.data![index];
              return _bookingCard(context, booking, service);
            },
          );
        },
      ),
    );
  }

  Widget _bookingCard(
      BuildContext context, CoachBookingModel booking, CoachService service) {
    final statusColor = {
      BookingStatus.pending: Colors.orange,
      BookingStatus.confirmed: const Color(0xFF4CAF50),
      BookingStatus.cancelled: Colors.red,
      BookingStatus.completed: Colors.blue,
    }[booking.status]!;

    final statusLabel = {
      BookingStatus.pending: 'coach.bekliyor'.tr(),
      BookingStatus.confirmed: 'coach.onaylandi'.tr(),
      BookingStatus.cancelled: 'coach.reddedildi'.tr(),
      BookingStatus.completed: 'coach.tamamlandi'.tr(),
    }[booking.status]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.coachName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📅 ${booking.date.day}/${booking.date.month}/${booking.date.year}  🕐 ${booking.timeSlot}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (booking.note != null) ...[
            const SizedBox(height: 6),
            Text('📝 ${booking.note}',
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
          if (booking.status == BookingStatus.pending) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await service.cancelBooking(booking.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('coach.iptal_edildi'.tr())),
                  );
                },
                child: Text('coach.iptal_et'.tr(),
                    style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}