import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String announcementId;
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context) {
    // Gerçek uygulamada announcementId ile Firebase'den veri çekilir
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Duyuru Detayı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(
        child: Text('Duyuru detayı Firebase\'den yüklenecek.'),
      ),
    );
  }
}
