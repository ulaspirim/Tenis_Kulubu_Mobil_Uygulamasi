import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tenis_kulubu/core/theme/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Yardım & Destek'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          // ✅ Navigator.of(context).pop() → context.pop() (GoRouter ile tutarlı)
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSupportTile(
            context: context,
            icon: Icons.mail_outline_rounded,
            title: 'Bize E-posta Gönderin',
            subtitle: 'support@teniskulubu.com',
            onTap: () {
              // TODO: url_launcher ile mailto: aç
            },
          ),
          const SizedBox(height: 12),
          _buildSupportTile(
            context: context,
            icon: Icons.phone_in_talk_outlined,
            title: 'Telefon ile Ulaşın',
            subtitle: '+90 (212) XXX XX XX',
            onTap: () {
              // TODO: url_launcher ile tel: aç
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Sıkça Sorulan Sorular',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // ✅ FAQ tile'ları Card içine alındı — SupportTile ile stil tutarlılığı sağlandı
          Card(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                _buildFaqTile(
                  'Rezervasyonumu nasıl iptal edebilirim?',
                  'Rezervasyonlarım sekmesinden aktif rezervasyonunuzu bulup son 24 saate kadar ücretsiz iptal edebilirsiniz.',
                ),
                const Divider(height: 1, color: AppColors.surfaceVariant),
                _buildFaqTile(
                  'Üyelik paketimi nasıl yükseltebilirim?',
                  'Kulüp resepsiyonundan veya Üyeliğim ekranındaki adımları takip ederek Premium pakete geçiş yapabilirsiniz.',
                ),
                _buildFaqTile(
                  'Üyelik paketimi nasıl yenilerim?',
                  'Kulüp resepsiyonundan veya Üyeliğim ekranındaki adımları takip ederek mevcut paketinizin süresini uzatabilirsiniz.',
                ),
                _buildFaqTile(
                  'Özel sohbet grubunu nasıl oluştururum?',
                  'Kulüp resepsiyonundan talep ederek özel sohbet grubu oluşturabilirsiniz.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  // ✅ ExpansionTile artık doğrudan Card içinde — tutarlı yüzey rengi
  Widget _buildFaqTile(String title, String content) {
    return ExpansionTile(
      // ✅ Expanded/collapsed arka plan renkleri Card rengiyle eşleştirildi
      backgroundColor: AppColors.surface,
      collapsedBackgroundColor: AppColors.surface,
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}