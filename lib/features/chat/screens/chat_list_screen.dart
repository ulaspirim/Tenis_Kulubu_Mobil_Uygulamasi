import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';

import 'package:easy_localization/easy_localization.dart';

final chatRoomsProvider = StreamProvider<List<ChatRoomData>>((ref) {
  return FirebaseFirestore.instance
      .collection('messages')
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final d = doc.data();
            return ChatRoomData(
              id: doc.id,
              name: d['name'] ?? '',
              lastMessage: d['lastMessage'] ?? '',
              iconName: d['icon'] ?? 'chat',
            );
          }).toList());
});

class ChatRoomData {
  final String id;
  final String name;
  final String lastMessage;
  final String iconName;

  const ChatRoomData({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.iconName,
  });

  IconData get icon {
    switch (iconName) {
      case 'groups': return Icons.groups;
      case 'sports_tennis': return Icons.sports_tennis;
      case 'pool': return Icons.pool;
      case 'emoji_events': return Icons.emoji_events;
      default: return Icons.chat_bubble_outline;
    }
  }
}

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('sohbet.sohbet').tr()),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (rooms) {
          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 56, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('sohbet.henuz_sohbet_yok'.tr(),
                      style: TextStyle(color: AppColors.textHint)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            separatorBuilder: (_, __) =>
                const Divider(indent: 80, endIndent: 20),
            itemBuilder: (context, i) {
              final room = rooms[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(room.icon, color: Colors.white, size: 24),
                ),
                title: Text(
                  room.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                subtitle: Text(
                  room.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.textHint),
                onTap: () => context.go('${AppRouter.chat}/${room.id}'),
              );
            },
          );
        },
      ),
    );
  }
}