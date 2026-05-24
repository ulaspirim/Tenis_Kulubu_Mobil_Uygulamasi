import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/announcements/screens/announcements_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  final String announcementId;
  const AnnouncementDetailScreen({super.key, required this.announcementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('duyurular.duyuru_detayi'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('announcements')
            .doc(announcementId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('duyurular.duyuru_yok'.tr(),
                  style: TextStyle(color: AppColors.textHint)),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final item = AnnouncementData(
            id: snapshot.data!.id,
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            category: data['category'] ?? 'general',
            isPinned: data['isPinned'] ?? false,
            publishedAt: (data['publishedAt'] as Timestamp).toDate(),
            eventDate: data['eventDate'] != null
                ? (data['eventDate'] as Timestamp).toDate()
                : null,
            location: data['location'],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kategori etiketi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item.categoryLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.categoryColor)),
                ),
                const SizedBox(height: 14),

                // Başlık
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),

                // Tarih
                Text(
                  DateFormat('d MMMM y', context.locale.toString()).format(item.publishedAt),
                  style: const TextStyle(fontSize: 13, color: AppColors.textHint),
                ),

                // Etkinlik tarihi
                if (item.eventDate != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${'duyurular.etkinlik'.tr()}: ${DateFormat('d MMMM y', context.locale.toString()).format(item.eventDate!)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                // Konum
                if (item.location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(item.location!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textHint)),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // İçerik
                Text(item.content,
                    style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.7)),
              ],
            ),
          );
        },
      ),
    );
  }
}