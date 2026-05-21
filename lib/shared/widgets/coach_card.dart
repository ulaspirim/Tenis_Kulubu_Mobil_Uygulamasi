import 'package:flutter/material.dart';
import '../models/coach_model.dart';

class CoachCard extends StatelessWidget {
  final CoachModel coach;
  final VoidCallback onTap;

  const CoachCard({super.key, required this.coach, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2128),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(coach.photoUrl),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coach.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  Text(coach.specialty,
                      style: const TextStyle(
                          color: Color(0xFF4CAF50), fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('⭐ ${coach.rating}  •  ₺${coach.pricePerHour.toInt()}/saat',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}