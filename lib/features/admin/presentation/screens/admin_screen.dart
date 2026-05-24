import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';
import 'package:tenis_kulubu/features/admin/data/admin_repository.dart';
import 'package:tenis_kulubu/shared/models/models.dart';

import 'package:easy_localization/easy_localization.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  // ── Mevcut antrenörleri listele ──────────────────────────────────────────
Widget _buildExistingCoachesList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('coaches').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }

      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 24),
          Text(
            'Mevcut Antrenörler',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          ...docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? '';
            final specialty = data['specialty'] ?? '';
            final price = data['pricePerHour'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.textHint.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.greenAccent.withOpacity(0.15),
                    child: const Icon(Icons.person_pin, size: 18, color: Colors.greenAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('$specialty  •  ₺$price/saat',
                            style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: () => _deleteCoach(doc.id, name),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    },
  );
}

  void _deleteCoach(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('coach.sil'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('coach.sil_uyari.tr({name: "$name"})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('coach.iptal'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('coaches').doc(docId).delete();
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('coach.silindi.tr({name: "$name"})'), backgroundColor: AppColors.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('coach.sil'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddCoachDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddCoachDialog(
        onAdded: (name) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('coach.eklendi.tr({name: "$name"})'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Sistem geri hareketinin (sağdan sola kaydırma) uygulamadan çıkmasını engeller
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Kullanıcı parmağını kaydırdığında pat diye çıkmasın, güvenli bir şekilde profile sayfasına yönlendirsin
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/profile');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('admin.panel'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'admin.uyeler'.tr()),
              Tab(text: 'admin.rezervasyonlar'.tr()),
              Tab(text: 'admin.istatistik'.tr()),
              Tab(text: 'admin.ayarlar'.tr()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMemberDialog(context),
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: Text('admin.uye_ekle'.tr(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMembersTab(),
            _buildCoachBookingsTab(),
            _buildStatsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    final usersStream = ref.watch(adminRepositoryProvider).getAllUsers();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'admin.uye_ara'.tr(),
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}'));
              }

              var users = snapshot.data ?? [];

              if (_searchQuery.isNotEmpty) {
                users = users.where((u) {
                  return u.fullName.toLowerCase().contains(_searchQuery) ||
                      u.membershipNumber.toLowerCase().contains(_searchQuery) ||
                      u.email.toLowerCase().contains(_searchQuery);
                }).toList();
              }

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 56, color: AppColors.textHint),
                      SizedBox(height: 12),
                      Text('admin.uye_bulunamadi'.tr(),
                          style: TextStyle(color: AppColors.textHint)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _buildMemberCard(users[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(UserModel user) {
    final statusColor = user.membershipStatus == 'active' ? AppColors.success : AppColors.error;
    final statusLabel ='ana_ekran.${user.membershipStatus == 'active' ? 'aktif' : 'pasif'}'.tr();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            '${user.firstName[0]}${user.lastName[0]}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(user.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.membershipNumber,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(user.email,
                style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            if (user.isMembershipExpiringSoon)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('${user.daysUntilExpiry} admin.gun_kaldi'.tr(),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textHint),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) => _handleMemberAction(value, user),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 10),
                Text('admin.duzenle'.tr()),
              ]),
            ),
            PopupMenuItem(
              value: user.membershipStatus == 'active' ? 'deactivate' : 'activate',
              child: Row(children: [
                Icon(user.membershipStatus == 'active'
                    ? Icons.block_outlined
                    : Icons.check_circle_outline, size: 18),
                const SizedBox(width: 10),
                Text(user.membershipStatus == 'active' ? 'admin.pasife_al'.tr() : 'admin.aktife_al'.tr()),
              ]),
            ),
            PopupMenuItem(
              value: 'extend',
              child: Row(children: [
                Icon(Icons.calendar_month_outlined, size: 18),
                SizedBox(width: 10),
                Text('admin.sure_uzat'.tr()),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                SizedBox(width: 10),
                Text('admin.sil.'.tr(), style: TextStyle(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('coach_bookings')
          .orderBy('date', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final pending = docs.where((d) => d['status'] == 'pending').toList();
        final others = docs.where((d) => d['status'] != 'pending').toList();
        final all = [...pending, ...others];

        if (all.isEmpty) {
          return Center(
            child: Text('coach.randevu_yok'.tr(), style: TextStyle(color: AppColors.textHint)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = all[i];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String;
            final date = (data['date'] as Timestamp).toDate();

            final statusColor = {
              'pending': AppColors.warning,
              'confirmed': AppColors.success,
              'cancelled': AppColors.error,
              'completed': AppColors.info,
            }[status] ?? AppColors.textHint;

            final statusLabel = {
              'pending': 'coach.bekliyor'.tr(),
              'confirmed': 'coach.onaylandi'.tr(),
              'cancelled': 'coach.reddedildi'.tr(),
              'completed': 'coach.iptal_edildi'.tr(),
            }[status] ?? '';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: status == 'pending'
                    ? Border.all(color: AppColors.warning.withOpacity(0.4))
                    : null,
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(data['userName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('👨‍🏫 ${data['coachName']}  •  🕐 ${data['timeSlot']}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text('📅 ${date.day}/${date.month}/${date.year}  •  ₺${data['price']}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  if (data['note'] != null && data['note'] != '') ...[
                    const SizedBox(height: 4),
                    Text('📝 ${data['note']}',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                  ],
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('coach_bookings')
                                  .doc(doc.id)
                                  .update({'status': 'cancelled'});
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                            ),
                            child: Text('coach.reddet'.tr()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('coach_bookings')
                                  .doc(doc.id)
                                  .update({'status': 'confirmed'});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('coach.onayla'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
  void _handleMemberAction(String action, UserModel user) async {
    final repo = ref.read(adminRepositoryProvider);
    switch (action) {
      case 'edit':
        _showEditMemberDialog(context, user);
        break;
      case 'activate':
      case 'deactivate':
        final newStatus = action == 'activate' ? 'active' : 'suspended';
        await repo.updateMembershipStatus(userId: user.id, status: newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(action == 'activate'
                ? 'coach.aktife_alindi.tr({name: "${user.fullName}"})'
                : 'coach.pasife_alindi.tr({name: "${user.fullName}"})'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
        break;
      case 'extend':
        _showExtendMembershipDialog(context, user);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, user);
        break;
    }
  }

  Widget _buildStatsTab() {
    final usersStream = ref.watch(adminRepositoryProvider).getAllUsers();
    return StreamBuilder<List<UserModel>>(
      stream: usersStream,
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        final activeCount = users.where((u) => u.membershipStatus == 'active').length;
        final expiringCount = users.where((u) => u.isMembershipExpiringSoon).length;
        final expiredCount = users.where((u) => u.membershipStatus == 'expired').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard('admin.toplam_uye'.tr(), '${users.length}', Icons.people_rounded, AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('admin.aktif_uye'.tr(), '$activeCount', Icons.check_circle_rounded, AppColors.success)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('admin.yakinda_bitiyor'.tr(), '$expiringCount', Icons.warning_rounded, AppColors.warning)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('admin.suresi_dolmus'.tr(), '$expiredCount', Icons.cancel_rounded, AppColors.error)),
                ],
              ),
              const SizedBox(height: 24),
              if (expiringCount > 0) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('admin.yakinda_suresi_bitenler'.tr(),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.warning)),
                ),
                const SizedBox(height: 12),
                ...users.where((u) => u.isMembershipExpiringSoon).map((u) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(u.membershipNumber,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Text('${u.daysUntilExpiry} admin.gun_kaldi'.tr(),
                              style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ── AYARLAR SEKMESİ ──────────────────────────────────────────────────────────

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Sohbet Grupları ──
        _buildSectionHeader(Icons.forum_rounded, 'admin.sohbet_gruplari'.tr()),
        const SizedBox(height: 12),
        _buildSettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.tum_uyelerin_gorebilecegi'.tr(),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateGroupDialog(context),
                  icon: const Icon(Icons.add_comment_rounded, size: 18),
                  label: Text('admin.yeni_grup_olustur'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Mevcut grupları listele
              _buildExistingGroupsList(),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildSectionHeader(Icons.person_pin, 'admin.coach'.tr()),
        const SizedBox(height: 12),
        _buildSettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.kulup_antrenorlerini_yonetin'.tr(),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddCoachDialog(context),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: Text('admin.yeni_antrenor_ekle'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildExistingCoachesList(),
            ],
          ),
        ),


        // ── Duyurular ──
        _buildSectionHeader(Icons.campaign_rounded, 'admin.duyurular'.tr()),
        const SizedBox(height: 12),
        _buildSettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.tum_uyelerin_gorebilecegi_duyurular'.tr(),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddAnnouncementDialog(context),
                  icon: const Icon(Icons.add_alert_rounded, size: 18),
                  label: Text('admin.yeni_duyuru_ekle'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildExistingAnnouncementsList(),
            ],
          ),
        ),

        // ── Admin Bilgileri ──
        _buildSectionHeader(Icons.admin_panel_settings_rounded, 'admin.admin_bilgileri'.tr()),
        const SizedBox(height: 12),
        _buildSettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('admin.daha_fazla_ayar_yakinda_eklenecek'.tr(),
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }

  /// Firestore'daki mevcut sohbet odalarını listeler
  Widget _buildExistingGroupsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              'admin.mevcut_gruplar'.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? doc.id;
              final isCustom = data['createdByAdmin'] == true;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    isCustom ? Icons.group_rounded : Icons.chat_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  isCustom ? 'admin.admin_tarafindan_olusturuldu'.tr() : 'admin.varsayilan_grup'.tr(),
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
                trailing: isCustom
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => _showDeleteGroupDialog(context, doc.id, name),
                      )
                    : null,
              );
            }),
          ],
        );
      },
    );
  }

  // ── Grup Oluşturma Dialogu ────────────────────────────────────────────────

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CreateGroupDialog(
        onCreated: (name) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('admin.yeni_grup_olusturuldu'.tr(namedArgs: {'name': name})),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, String roomId, String roomName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('admin.grubu_sil'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'admin.grup_silme_onayi'.tr(namedArgs: {'name': roomName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('admin.iptal'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              // Alt koleksiyonları silmek için batch delete gerekir;
              // basit implementasyon: sadece üst belgeyi sil.
              // Gerçek prodüksiyonda Cloud Function kullanılması önerilir.
              await FirebaseFirestore.instance
                  .collection('messages')
                  .doc(roomId)
                  .delete();
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('admin.grup_silindi'.tr(namedArgs: {'name': roomName})),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('admin.grubu_sil'.tr()),
          ),
        ],
      ),
    );
  }

  // ── Dialoglar ──────────────────────────────

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _AddMemberDialog(
        onAdd: (firstName, lastName, email, phone, membershipNum, membershipType, expiryDate) async {
          await ref.read(adminRepositoryProvider).addMember(
            firstName: firstName,
            lastName: lastName,
            email: email,
            membershipType: membershipType,
            membershipNumber: membershipNum,
            phone: phone,

            membershipExpiry: expiryDate,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('admin.uye_eklendi'.tr()),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditMemberDialog(BuildContext context, UserModel user) {
    final firstNameCtrl = TextEditingController(text: user.firstName);
    final lastNameCtrl = TextEditingController(text: user.lastName);
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final membershipNumCtrl = TextEditingController(text: user.membershipNumber);
    String selectedType = user.membershipType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('admin.uye_duzenle'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(firstNameCtrl, 'admin.ad'.tr(), Icons.person_outline),
                const SizedBox(height: 12),
                _dialogField(lastNameCtrl, 'admin.soyad'.tr(), Icons.person_outline),
                const SizedBox(height: 12),
                _dialogField(phoneCtrl, 'admin.telefon'.tr(), Icons.phone_outlined, type: TextInputType.phone),
                const SizedBox(height: 12),
                _dialogField(membershipNumCtrl, 'admin.uyelik_numarasi'.tr(), Icons.card_membership_outlined),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'admin.uyelik_tipi'.tr(),
                    prefixIcon: Icon(Icons.star_outline),
                  ),
                  items: [
                    DropdownMenuItem(value: 'standard', child: Text('admin.uyelik_tipi_standard'.tr())),
                    DropdownMenuItem(value: 'premium', child: Text('admin.uyelik_tipi_premium'.tr())),
                    DropdownMenuItem(value: 'family', child: Text('admin.uyelik_tipi_family'.tr())),
                    DropdownMenuItem(value: 'club_player', child: Text('admin.uyelik_tipi_club_player'.tr())),
                    DropdownMenuItem(value: 'special', child: Text('admin.uyelik_tipi_special'.tr())),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('grup.iptal'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(adminRepositoryProvider).updateMember(
                  userId: user.id,
                  firstName: firstNameCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  membershipType: selectedType,
                  membershipNumber: membershipNumCtrl.text.trim(),
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('admin.uye_guncellendi'.tr()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('admin.kaydet'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendMembershipDialog(BuildContext context, UserModel user) {
    DateTime newExpiry = user.membershipExpiry.isAfter(DateTime.now())
        ? user.membershipExpiry
        : DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('admin.uye_suresini_uzat'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: Text('admin.yeni_bitis_tarihi'.tr()),
                subtitle: Text(
                  DateFormat('d MMMM y', 'tr_TR').format(newExpiry),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: newExpiry,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setDialogState(() => newExpiry = picked);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [3, 6, 12].map((months) {
                  return ActionChip(
                    label: Text('+$months ay'),
                    onPressed: () {
                      setDialogState(() {
                        newExpiry = DateTime(
                          newExpiry.year,
                          newExpiry.month + months,
                          newExpiry.day,
                        );
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('admin.iptal'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(adminRepositoryProvider).extendMembership(
                  userId: user.id,
                  newExpiry: newExpiry,
                );
                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('admin.uye_suresini_uzatildi'.tr()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('admin.uzat'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('admin.uye_sil'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'admin.uye_silme_onayi'.tr(args: [user.fullName]),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('admin.iptal'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteMember(user.id);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('admin.uye_silindi'.tr(args: [user.fullName])),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('admin.uyeyi_sil'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  // ── Duyuru Metodları ────────────────────────

  Widget _buildExistingAnnouncementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('publishedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              'duyurular.mevcut_duyurular'.tr(),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? '';
              final category = data['category'] as String? ?? 'general';
              final isPinned = data['isPinned'] == true;
              final isPublished = data['isPublished'] == true;

              final categoryColors = <String, Color>{
                'tournament': AppColors.accent,
                'maintenance': AppColors.warning,
                'event': AppColors.info,
                'general': AppColors.primary,
              };
              final categoryLabels = <String, String>{
                'tournament': 'duyurular.turnuva'.tr(),
                'maintenance': 'duyurular.bakim'.tr(),
                'event': 'duyurular.etkinlik'.tr(),
                'general': 'duyurular.genel'.tr(),
              };

              final color = categoryColors[category] ?? AppColors.primary;
              final label = categoryLabels[category] ?? 'duyurular.duyuru'.tr();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.textHint.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    if (isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.primary),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(label,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isPublished ? AppColors.success : AppColors.textHint).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPublished ? 'duyurular.yayinda'.tr() : 'duyurular.taslak'.tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isPublished ? AppColors.success : AppColors.textHint,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textHint),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) => _handleAnnouncementAction(value, doc.id, data),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: isPublished ? 'unpublish' : 'publish',
                          child: Row(children: [
                            Icon(isPublished ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            const SizedBox(width: 10),
                            Text(isPublished ? 'duyurular.gizle'.tr() : 'duyurular.yayinla'.tr()),
                          ]),
                        ),
                        PopupMenuItem(
                          value: isPinned ? 'unpin' : 'pin',
                          child: Row(children: [
                            Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(isPinned ? 'duyurular.sabitlemeyi_kaldir'.tr() : 'duyurular.sabitle'.tr()),
                          ]),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 10),
                            Text('duyurular.sil'.tr(), style: TextStyle(color: AppColors.error)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _handleAnnouncementAction(String action, String docId, Map<String, dynamic> data) async {
    final docRef = FirebaseFirestore.instance.collection('announcements').doc(docId);
    switch (action) {
      case 'publish':
        await docRef.update({'isPublished': true});
        break;
      case 'unpublish':
        await docRef.update({'isPublished': false});
        break;
      case 'pin':
        await docRef.update({'isPinned': true});
        break;
      case 'unpin':
        await docRef.update({'isPinned': false});
        break;
      case 'delete':
        _showDeleteAnnouncementDialog(docId, data['title'] ?? '');
        break;
    }
  }

  void _showDeleteAnnouncementDialog(String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('duyurular.duyuruyu_sil'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('duyurular.duyuru_silme_onayi.tr(args: [title])'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('duyurular.iptal'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('announcements')
                  .doc(docId)
                  .delete();
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('duyurular.duyuru_silindi.tr(args: [title])'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('duyurular.sil'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddAnnouncementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AddAnnouncementDialog(),
    );
  }

}

// ─────────────────────────────────────────
// ÜYE EKLE DIALOG
// ─────────────────────────────────────────
class _AddMemberDialog extends StatefulWidget {
  final Future<void> Function(
    String firstName,
    String lastName,
    String email,
    String phone,
    String membershipNum,
    String membershipType,
    DateTime expiryDate,
  ) onAdd;

  const _AddMemberDialog({required this.onAdd});

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _membershipNumCtrl = TextEditingController();
  String _selectedType = 'standard';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _membershipNumCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('uyelik.yeni_uyelik'.tr(), style: TextStyle(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_firstNameCtrl, 'uyelik.ad'.tr(), Icons.person_outline),
              const SizedBox(height: 12),
              _field(_lastNameCtrl, 'uyelik.soyad'.tr(), Icons.person_outline),
              const SizedBox(height: 12),
              _field(_emailCtrl, 'uyelik.e-posta'.tr(), Icons.email_outlined, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'uyelik.telefon'.tr(), Icons.phone_outlined, type: TextInputType.phone),
              const SizedBox(height: 12),
              _field(_membershipNumCtrl, 'admin.uyelik_numarasi'.tr(), Icons.card_membership_outlined),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'uyelik.uyelik_tipi'.tr(),
                  prefixIcon: Icon(Icons.star_outline),
                ),
                items: [
                  DropdownMenuItem(value: 'standard', child: Text('uyelik.standart'.tr())),
                  DropdownMenuItem(value: 'premium', child: Text('uyelik.premium'.tr())),
                  DropdownMenuItem(value: 'family', child: Text('uyelik.family'.tr())),
                  DropdownMenuItem(value: 'club_player', child: Text('uyelik.club_player'.tr())),
                  DropdownMenuItem(value: 'special', child: Text('uyelik.special'.tr())),
                ],
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, color: AppColors.primary),
                title: Text('uyelik.bitis_tarihi'.tr(), style: TextStyle(fontSize: 13)),
                subtitle: Text(
                  '${_expiryDate.day}.${_expiryDate.month}.${_expiryDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expiryDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) setState(() => _expiryDate = picked);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('uyelik.iptal'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_firstNameCtrl.text.isEmpty ||
                      _lastNameCtrl.text.isEmpty ||
                      _emailCtrl.text.isEmpty ||
                      _membershipNumCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('uyelik.zorunlu_alanlar'.tr())),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    await widget.onAdd(
                      _firstNameCtrl.text.trim(),
                      _lastNameCtrl.text.trim(),
                      _emailCtrl.text.trim(),
                      _phoneCtrl.text.trim(),
                      _membershipNumCtrl.text.trim(),
                      _selectedType,
                      _expiryDate,
                    );
                    if (mounted) Navigator.of(context).pop();
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('uyelik.hata.tr() $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('uyelik.kaydet'.tr()),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// GRUP OLUŞTURMA DIALOG WIDGET'I
// ─────────────────────────────────────────

class _CreateGroupDialog extends StatefulWidget {
  final void Function(String name) onCreated;
  const _CreateGroupDialog({required this.onCreated});

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _selectedIcon = 'forum';
  bool _isPrivate = false;
  bool _isLoading = false;
  bool _isFetchingUsers = false;

  // Tüm kullanıcılar (özel grup için)
  List<UserModel> _allUsers = [];
  // Seçili UID'ler
  final Set<String> _selectedUids = {};
  // Üye arama filtresi
  String _memberSearch = '';

  static const _iconOptions = {
    'forum': Icons.forum_rounded,
    'sports_tennis': Icons.sports_tennis_rounded,
    'pool': Icons.pool_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'fitness_center': Icons.fitness_center_rounded,
    'groups': Icons.groups_rounded,
    'star': Icons.star_rounded,
    'announcement': Icons.campaign_rounded,
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isFetchingUsers = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      final users = snap.docs.map((d) {
        final data = d.data();
        // UserModel.fromMap / fromFirestore olduğunu varsayıyoruz; projenize göre uyarlayın
        return UserModel.fromFirestore(d);
      }).toList();
      setState(() {
        _allUsers = users;
        _isFetchingUsers = false;
      });
    } catch (_) {
      setState(() => _isFetchingUsers = false);
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('uyelik.grup_adi_zorunludur'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_isPrivate && _selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('uyelik.ozel_grup_uye_sec'.tr()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final roomId = name
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');

      await FirebaseFirestore.instance.collection('messages').doc(roomId).set({
        'name': name,
        'description': _descCtrl.text.trim(),
        'icon': _selectedIcon,
        'createdByAdmin': true,
        'isPrivate': _isPrivate,
        if (_isPrivate) 'allowedUids': _selectedUids.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated(name);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('grup.hata.tr() $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _memberSearch.isEmpty
        ? _allUsers
        : _allUsers.where((u) =>
            u.fullName.toLowerCase().contains(_memberSearch.toLowerCase()) ||
            u.email.toLowerCase().contains(_memberSearch.toLowerCase())).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.add_comment_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Text('grup.yeni_grup'.tr(),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Grup Adı ──
              _inputField(_nameCtrl, 'grup.grup_adi'.tr(), 'grup.grup_ornek'.tr(),
                  Icons.group_rounded),
              const SizedBox(height: 12),

              // ── Açıklama ──
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: _inputDecoration(
                  '${'grup.aciklama'.tr()} (isteğe bağlı)',
                  '${'grup.aciklama_aciklamasi'.tr()}...',
                  Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 16),

              // ── İkon Seçimi ──
              Text('grup.grup_ikonu'.tr(),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _iconOptions.entries.map((entry) {
                  final isSelected = _selectedIcon == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(entry.value,
                          size: 22,
                          color: isSelected ? Colors.white : AppColors.textHint),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // ── Herkese Açık / Özel Toggle ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  value: _isPrivate,
                  activeColor: AppColors.primary,
                  title: Row(
                    children: [
                      Icon(
                        _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                        size: 18,
                        color: _isPrivate ? AppColors.primary : AppColors.textHint,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPrivate ? 'grup.ozel_grup'.tr() : 'grup.herkese_acik'.tr(),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _isPrivate
                        ? 'grup.sadece_secili_uyeler_gorebilir'.tr()
                        : 'grup.tum_uyeler_bu_grubu_gorebilir'.tr(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _isPrivate = val;
                      _selectedUids.clear();
                    });
                    if (val && _allUsers.isEmpty) _loadUsers();
                  },
                ),
              ),

              // ── Üye Seçimi (sadece özel grupsa) ──
              if (_isPrivate) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person_search_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('grup.uye_sec'.tr(),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const Spacer(),
                    if (_selectedUids.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_selectedUids.length} ${'grup.secildi'.tr()}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Arama kutusu
                TextField(
                  onChanged: (v) => setState(() => _memberSearch = v),
                  decoration: _inputDecoration(
                    'grup.uye_ara'.tr(),
                    '',
                    Icons.search_rounded,
                  ),
                ),
                const SizedBox(height: 8),

                // Üye listesi
                if (_isFetchingUsers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (filteredUsers.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('grup.uye_bulunamadi'.tr(),
                          style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                    ),
                  )
                else
                  // Sabit yükseklikte kaydırılabilir liste
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredUsers.length,
                      itemBuilder: (ctx, i) {
                        final user = filteredUsers[i];
                        final isSelected = _selectedUids.contains(user.id);
                        return InkWell(
                          onTap: () => setState(() {
                            if (isSelected) {
                              _selectedUids.remove(user.id);
                            } else {
                              _selectedUids.add(user.id);
                            }
                          }),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.4)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.12),
                                  child: Text(
                                    '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
                                    style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.fullName,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      Text(user.membershipNumber,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textHint)),
                                    ],
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: isSelected
                                      ? const Icon(Icons.check_circle_rounded,
                                          key: ValueKey(true),
                                          color: AppColors.primary,
                                          size: 20)
                                      : const Icon(
                                          Icons.radio_button_unchecked_rounded,
                                          key: ValueKey(false),
                                          color: AppColors.textHint,
                                          size: 20),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('grup.iptal'.tr()),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _submit,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check_rounded, size: 18),
          label: Text('grup.olustur'.tr()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
      decoration: _inputDecoration(label, hint, icon),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ─────────────────────────────────────────
// DUYURU EKLE DIALOG WIDGET'I
// ─────────────────────────────────────────

class _AddAnnouncementDialog extends StatefulWidget {
  const _AddAnnouncementDialog();

  @override
  State<_AddAnnouncementDialog> createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<_AddAnnouncementDialog> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _selectedCategory = 'general';
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('duyurular.zorunlu_alanlar'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': title,
        'content': content,
        'category': _selectedCategory,
        'isPinned': _isPinned,
        'isPublished': true, // Varsayılan olarak direkt yayınla
        'publishedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('duyurular.duyuru_eklendi'.tr()),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('duyurular.hata'.tr()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.add_alert_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: 10),
          Text('duyurular.duyuru_ekle'.tr(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: _inputDecoration('duyurular.duyuru_basligi'.tr(), Icons.title_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentCtrl,
                maxLines: 4,
                decoration: _inputDecoration('duyurular.duyuru_icerigi'.tr(), Icons.description_outlined),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'duyurular.kategori'.tr(),
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  DropdownMenuItem(value: 'general', child: Text('duyurular.genel'.tr())),
                  DropdownMenuItem(value: 'tournament', child: Text('duyurular.turnuva'.tr())),
                  DropdownMenuItem(value: 'maintenance', child: Text('duyurular.bakim'.tr())),
                  DropdownMenuItem(value: 'event', child: Text('duyurular.etkinlik'.tr())),
                ],
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _isPinned
                      ? 'duyurular.sabitle'.tr()
                      : 'duyurular.sabitlemeyi_kaldir'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: _isPinned,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _isPinned = v),
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('duyurular.iptal'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('duyurular.yayinla'.tr(), style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

class _AddCoachDialog extends StatefulWidget {
  final void Function(String name) onAdded;
  const _AddCoachDialog({required this.onAdded});

  @override
  State<_AddCoachDialog> createState() => _AddCoachDialogState();
}

class _AddCoachDialogState extends State<_AddCoachDialog> {
  final _nameCtrl = TextEditingController();
  final _specialtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  bool _isLoading = false;

  // Müsaitlik: her gün için saatler
  final Map<String, List<String>> _availability = {
    'monday': [], 'tuesday': [], 'wednesday': [],
    'thursday': [], 'friday': [], 'saturday': [], 'sunday': [],
  };

  final _dayLabels = {
    'monday': 'coach.pazartesi'.tr(),
    'tuesday': 'coach.sali'.tr(),
    'wednesday': 'coach.carsamba'.tr(),
    'thursday': 'coach.persembe'.tr(),
    'friday': 'coach.cuma'.tr(),
    'saturday': 'coach.cumartesi'.tr(),
    'sunday': 'coach.pazar'.tr(),
  };

  final _allSlots = ['08:00','09:00','10:00','11:00','12:00',
                     '13:00','14:00','15:00','16:00','17:00',
                     '18:00','19:00','20:00','21:00'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specialtyCtrl.dispose();
    _priceCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('coach.ad_uye_zorunlu'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('coaches').add({
        'name': _nameCtrl.text.trim(),
        'specialty': _specialtyCtrl.text.trim(),
        'pricePerHour': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'photoUrl': _photoCtrl.text.trim(),
        'rating': 0.0,
        'totalSessions': 0,
        'availability': _availability,
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onAdded(_nameCtrl.text.trim());
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('coach.hata.tr(e)'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.person_add_rounded, color: Colors.greenAccent, size: 22),
          SizedBox(width: 10),
          Text('coach.yeni_antrenör', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_nameCtrl, 'coach.ad_soyad'.tr(), Icons.person_outline),
              const SizedBox(height: 12),
              _field(_specialtyCtrl, 'coach.uzmanlik'.tr(), Icons.star_outline),
              const SizedBox(height: 12),
              _field(_priceCtrl, 'coach.ucret'.tr(), Icons.attach_money, type: TextInputType.number),
              const SizedBox(height: 12),
              _field(_photoCtrl, 'coach.fotograf_url'.tr(), Icons.photo_outlined),
              const SizedBox(height: 20),

              Text('coach.musait_saatler'.tr(),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 10),

              ..._availability.keys.map((day) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dayLabels[day]!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _allSlots.map((slot) {
                      final isSelected = _availability[day]!.contains(slot);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            _availability[day]!.remove(slot);
                          } else {
                            _availability[day]!.add(slot);
                            _availability[day]!.sort();
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.greenAccent.shade700 : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(slot,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textHint,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('coach.iptal'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.shade700),
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('coach.ekle'.tr(), style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}