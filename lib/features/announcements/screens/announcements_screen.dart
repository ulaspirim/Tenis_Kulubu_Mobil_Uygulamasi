import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';

import 'package:easy_localization/easy_localization.dart';

final announcementsProvider = StreamProvider<List<AnnouncementData>>((ref) {
  return FirebaseFirestore.instance
      .collection('announcements')
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .where((doc) => doc.data()['isPublished'] == true)
            .map((doc) {
              final data = doc.data();
              return AnnouncementData(
                id: doc.id,
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
            }).toList();

        // Sıralama: önce sabitlenmiş, sonra tarihe göre
        list.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.publishedAt.compareTo(a.publishedAt);
        });

        return list;
      });
});

class AnnouncementData {
  final String id;
  final String title;
  final String content;
  final String category;
  final bool isPinned;
  final DateTime publishedAt;
  final DateTime? eventDate;
  final String? location;

  const AnnouncementData({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.isPinned,
    required this.publishedAt,
    this.eventDate,
    this.location,
  });

  Color get categoryColor {
    switch (category) {
      case 'tournament': return AppColors.accent;
      case 'maintenance': return AppColors.warning;
      case 'event': return AppColors.info;
      default: return AppColors.primary;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'tournament': return 'duyurular.duyuru_kategori_turnuva'.tr();
      case 'maintenance': return 'duyurular.duyuru_kategori_bakim'.tr();
      case 'event': return 'duyurular.duyuru_kategori_etkinlik'.tr();
      default: return 'duyurular.duyuru'.tr();
    }
  }
}

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = [
  'duyurular.duyuru_kategori_tumu'.tr(),
  'duyurular.duyuru_kategori_turnuva'.tr(),
  'duyurular.duyuru_kategori_etkinlik'.tr(),
  'duyurular.duyuru_kategori_genel'.tr(),
  'duyurular.duyuru_kategori_bakim'.tr(),
];
  final _filters = ['', 'tournament', 'event', 'general', 'maintenance'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('duyurular.duyurular'.tr()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: ref.watch(announcementsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${'duyurular.hata'.tr()}: $e')),
        data: (items) => TabBarView(
          controller: _tabController,
          children: List.generate(_tabs.length, (i) {
            final filter = _filters[i];
            final filtered = filter.isEmpty
                ? items
                : items.where((a) => a.category == filter).toList();
            return _buildList(filtered);
          }),
        ),
      ),
    );
  }

  Widget _buildList(List<AnnouncementData> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('duyurular.duyuru_yok'.tr(),
                style: TextStyle(color: AppColors.textHint)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(AnnouncementData item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: item.isPinned
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('duyurular.sabitlenmis'.tr(),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(item.title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item.categoryLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: item.categoryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(item.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5)),
                if (item.eventDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${'duyurular.etkinlik'.tr()}: ${DateFormat('d MMMM y', context.locale.toString()).format(item.eventDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    ],
                  ),
                ],
                if (item.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(item.location!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  DateFormat('d MMMM y', context.locale.toString()).format(item.publishedAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}