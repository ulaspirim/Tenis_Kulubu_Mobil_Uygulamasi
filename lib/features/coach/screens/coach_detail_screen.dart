import 'package:flutter/material.dart';
import 'package:tenis_kulubu/shared/models/coach_model.dart';
import 'package:tenis_kulubu/features/coach/screens/coach_booking_screen.dart';

import 'package:easy_localization/easy_localization.dart';

class CoachDetailScreen extends StatelessWidget {
  final CoachModel coach;
  const CoachDetailScreen({super.key, required this.coach});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: CustomScrollView(
        slivers: [
          // ── Antrenör fotoğrafı ve temel bilgiler ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0D1117),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(coach.photoUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0D1117).withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ad ve uzmanlık
                  Text(
                    coach.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coach.specialty,
                    style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // İstatistik kartları
                  Row(
                    children: [
                      _statCard('coach.puan'.tr(), coach.rating.toStringAsFixed(1)),
                      const SizedBox(width: 12),
                      _statCard('coach.ders'.tr(), '${coach.totalSessions}'),
                      const SizedBox(width: 12),
                      _statCard('coach.saat'.tr(), '₺${coach.pricePerHour.toInt()}'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Randevu al butonu
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
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CoachBookingScreen(coach: coach),
                        ),
                      ),
                      child: Text(
                        'coach.randevu_al'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}