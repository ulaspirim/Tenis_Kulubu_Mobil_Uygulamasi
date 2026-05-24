import 'package:flutter/material.dart';
import 'package:tenis_kulubu/features/coach/data/coach_service.dart';
import 'package:tenis_kulubu/shared/models/coach_model.dart';
import 'package:tenis_kulubu/shared/widgets/coach_card.dart';
import 'package:tenis_kulubu/features/coach/screens/coach_detail_screen.dart';

import 'package:easy_localization/easy_localization.dart';

class CoachListScreen extends StatelessWidget {
  const CoachListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CoachService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          'coach.coach_liste'.tr(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<CoachModel>>(
        stream: service.getCoaches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('coach.coach_bulunamadi'.tr(), style: TextStyle(color: Colors.white54)),
            );
          }

          final coaches = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coaches.length,
            itemBuilder: (context, index) {
              return CoachCard(
                coach: coaches[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CoachDetailScreen(coach: coaches[index]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}