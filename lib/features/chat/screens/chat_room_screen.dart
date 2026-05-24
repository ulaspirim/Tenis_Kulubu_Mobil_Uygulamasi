import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/core/router/app_router.dart';

import 'package:easy_localization/easy_localization.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String get _roomName {
    var names = {
      'genel': 'sohbet.genel'.tr(),
      'tenis': 'sohbet.tenis'.tr(),
      'havuz': 'sohbet.havuz'.tr(),
      'turnuva': 'sohbet.turnuva'.tr(),
    };
    return names[widget.roomId] ?? widget.roomId;
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;
    _messageCtrl.clear();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final firstName = userDoc.data()?['firstName'] ?? 'sohbet.uye'.tr();
    final lastName = userDoc.data()?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.roomId)
        .collection('chats')
        .add({
      'senderId': user.uid,
      'senderName': fullName,
      'content': text,
      'sentAt': Timestamp.now(),
      'messageType': 'text',
    });

    await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.roomId)
        .update({
      'lastMessage': text,
      'lastMessageTime': Timestamp.now(),
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Grupta mesaj göndermiş benzersiz kullanıcıları çekip bottom sheet olarak gösterir
  void _showMembersSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MembersBottomSheet(roomId: widget.roomId, roomName: _roomName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_roomName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go(AppRouter.chat),
        ),
        actions: [
          // Üyeleri gösteren ikon
          IconButton(
            icon: const Icon(Icons.people_alt_rounded),
            tooltip: 'sohbet.grup_uyeleri'.tr(),
            onPressed: _showMembersSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(widget.roomId)
                  .collection('chats')
                  .orderBy('sentAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text(
                          'sohbet.henuz_mesaj_yok'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                    final sentAt = data['sentAt'] != null
                        ? (data['sentAt'] as Timestamp).toDate()
                        : DateTime.now();
                    final time = TimeOfDay.fromDateTime(sentAt).format(context);

                    return _buildMessageBubble(
                      text: data['content'] ?? '',
                      isMe: isMe,
                      sender: data['senderName'] ?? 'sohbet.uye'.tr(),
                      time: time,
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    required String sender,
    required String time,
  }) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  sender,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                time,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Mesaj yazın...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// GRUP ÜYELERİ BOTTOM SHEET
// ─────────────────────────────────────────

class _MembersBottomSheet extends StatelessWidget {
  final String roomId;
  final String roomName;

  const _MembersBottomSheet({required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Tutamak çubuğu
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'sohbet.grup_uyeleri'.tr(),
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          roomName,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Üye listesi — bu grupta en az bir mesaj göndermiş kişiler
            Expanded(
              child: FutureBuilder<List<_ChatMember>>(
                future: _fetchMembers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'sohbet.hata'.tr(
                          namedArgs: {
                            'e': snapshot.error.toString(),
                          },
                        ),
                      ),
                    );
                  }

                  final members = snapshot.data ?? [];

                  if (members.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text('sohbet.henuz_mesaj_yok'.tr(),
                              style: TextStyle(color: AppColors.textHint)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Üye sayısı badge
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${members.length} ${'sohbet.uye'.tr()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: members.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) => _buildMemberTile(members[i], context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(_ChatMember member, BuildContext context) {
    final isCurrentUser = member.uid == FirebaseAuth.instance.currentUser?.uid;
    final initials = member.name.isNotEmpty
        ? member.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withOpacity(0.13),
          child: Text(
            initials.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'grup.siz'.tr(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${member.messageCount} ${'sohbet.mesaj'.tr()}',
          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
        ),
      ),
    );
  }

  /// Gruptaki mesajlardan benzersiz gönderici listesi oluşturur
  Future<List<_ChatMember>> _fetchMembers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(roomId)
        .collection('chats')
        .get();

    // senderId → {name, count}
    final Map<String, _ChatMember> memberMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final uid = data['senderId'] as String? ?? '';
      final name = data['senderName'] as String? ?? 'sohbet.uye'.tr();

      if (uid.isEmpty) continue;

      if (memberMap.containsKey(uid)) {
        memberMap[uid] = memberMap[uid]!.copyWithIncrement();
      } else {
        memberMap[uid] = _ChatMember(uid: uid, name: name, messageCount: 1);
      }
    }

    // Mesaj sayısına göre sırala (çok mesaj atan başta)
    final list = memberMap.values.toList()
      ..sort((a, b) => b.messageCount.compareTo(a.messageCount));

    return list;
  }
}

class _ChatMember {
  final String uid;
  final String name;
  final int messageCount;

  const _ChatMember({
    required this.uid,
    required this.name,
    required this.messageCount,
  });

  _ChatMember copyWithIncrement() => _ChatMember(
        uid: uid,
        name: name,
        messageCount: messageCount + 1,
      );
}