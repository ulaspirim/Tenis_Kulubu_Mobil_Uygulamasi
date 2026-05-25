import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:tenis_kulubu/core/theme/app_colors.dart';

// ─────────────────────────────────────────────
//  Kullanım (MembershipScreen içinde):
//
//  ElevatedButton.icon(
//    onPressed: () => PaymentBottomSheet.show(
//      context,
//      type: PaymentSheetType.renew,
//      currentPlan: user.membershipType,
//    ),
//    ...
//  ),
//
//  OutlinedButton.icon(
//    onPressed: () => PaymentBottomSheet.show(
//      context,
//      type: PaymentSheetType.upgrade,
//      currentPlan: user.membershipType,
//    ),
//    ...
//  ),
// ─────────────────────────────────────────────

enum PaymentSheetType { renew, upgrade }

class PaymentBottomSheet extends StatefulWidget {
  final PaymentSheetType type;
  final String currentPlan;

  const PaymentBottomSheet({
    super.key,
    required this.type,
    required this.currentPlan,
  });

  // ── Statik yardımcı – tek satırda açmak için ──
  static Future<void> show(
    BuildContext context, {
    required PaymentSheetType type,
    required String currentPlan,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentBottomSheet(type: type, currentPlan: currentPlan),
    );
  }

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  // ── Mevcut upgrade planı seçimi ──
  String? _selectedUpgradePlan;

  // ── IBAN kopyalandı bildirimi ──
  bool _ibanCopied = false;

  // ─── Kulüp bilgileri – ileride remote config / Firestore'dan çekilebilir ───
  static const String _clubIban    = 'TR00 0000 0000 0000 0000 0000 00';
  static const String _clubName    = 'Tenis Kulübü Derneği';
  static const String _clubPhone   = '+90 (000) 000 00 00';
  static const String _clubAddress = 'Atatürk Cad. No:1, Adana';

  // ── Yükseltme seçenekleri (mevcut paket hariç gösterilir) ──
  List<_PlanOption> get _upgradePlans => [
    _PlanOption(key: 'standart',     labelKey: 'admin.uyelik_tipi_standard',     price: 'odeme.besbin'.tr(),  icon: Icons.person_rounded),
    _PlanOption(key: 'premium',     labelKey: 'admin.uyelik_tipi_premium',     price: 'odeme.onbin'.tr(),  icon: Icons.star_rounded),
    _PlanOption(key: 'family',      labelKey: 'admin.uyelik_tipi_family',      price: 'odeme.onbesbin'.tr(),  icon: Icons.family_restroom_rounded),
    _PlanOption(key: 'club_player', labelKey: 'admin.uyelik_tipi_club_player', price: 'odeme.yirmibin'.tr(),  icon: Icons.sports_tennis_rounded),
    _PlanOption(key: 'special',     labelKey: 'admin.uyelik_tipi_special',     price: 'admin.uyelik_tipi_special'.tr(), icon: Icons.verified_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─── IBAN kopyala ───
  Future<void> _copyIban() async {
    await Clipboard.setData(const ClipboardData(text: _clubIban));
    setState(() => _ibanCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _ibanCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final isUpgrade = widget.type == PaymentSheetType.upgrade;
    final availablePlans = _upgradePlans
        .where((p) => p.key != widget.currentPlan)
        .toList();

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // ── Drag handle ──
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // ── İçerik ──
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      // Başlık
                      _SheetHeader(isUpgrade: isUpgrade),
                      const SizedBox(height: 24),

                      // 1) Paket seçimi (sadece upgrade için)
                      if (isUpgrade) ...[
                        _SectionTitle(title: 'odeme.yeni_paket_sec'.tr()),
                        const SizedBox(height: 12),
                        ...availablePlans.map((plan) => _PlanTile(
                          plan: plan,
                          selected: _selectedUpgradePlan == plan.key,
                          onTap: () => setState(() => _selectedUpgradePlan = plan.key),
                        )),
                        const SizedBox(height: 24),
                      ],

                      // 2) IBAN havale bilgisi
                      _SectionTitle(title: 'odeme.havale_eft'.tr()),
                      const SizedBox(height: 12),
                      _IbanCard(
                        iban: _clubIban,
                        clubName: _clubName,
                        copied: _ibanCopied,
                        onCopy: _copyIban,
                      ),
                      const SizedBox(height: 8),
                      _InfoNote(
                        text: 'odeme.aciklama_uyari'.tr(),
                      ),
                      const SizedBox(height: 24),

                      // 3) Adımlar
                      _SectionTitle(title: 'odeme.nasil_isler'.tr()),
                      const SizedBox(height: 12),
                      _StepList(isUpgrade: isUpgrade),
                      const SizedBox(height: 24),

                      // 4) Kulüp iletişim
                      _SectionTitle(title: 'odeme.kuluple_iletisim'.tr()),
                      const SizedBox(height: 12),
                      _ContactCard(phone: _clubPhone, address: _clubAddress),
                      const SizedBox(height: 32),

                      // 5) Kapat butonu
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'odeme.anladim_kapat'.tr(),
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
//  Alt bileşenler
// ════════════════════════════════════════════

class _SheetHeader extends StatelessWidget {
  final bool isUpgrade;
  const _SheetHeader({required this.isUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUpgrade ? Icons.upgrade_rounded : Icons.autorenew_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUpgrade ? 'odeme.paket_yukseltme'.tr() : 'odeme.paketi_yenileme'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isUpgrade
                      ? 'odeme.yeni_paketi_sec'.tr()
                      : 'odeme.odeme_yap_onay_al'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Plan seçim kartı ──
class _PlanOption {
  final String key;
  final String labelKey;
  final String price;
  final IconData icon;
  const _PlanOption({
    required this.key,
    required this.labelKey,
    required this.price,
    required this.icon,
  });
}

class _PlanTile extends StatelessWidget {
  final _PlanOption plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanTile({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? AppColors.cardShadow : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(plan.icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.labelKey.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(plan.price,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── IBAN kartı ──
class _IbanCard extends StatelessWidget {
  final String iban;
  final String clubName;
  final bool copied;
  final VoidCallback onCopy;
  const _IbanCard({
    required this.iban,
    required this.clubName,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
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
          // Hesap adı
          Row(
            children: [
              const Icon(Icons.account_balance_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('odeme.alici'.tr(),
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(clubName,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // IBAN
          Row(
            children: [
              const Icon(Icons.credit_card_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('IBAN',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  iban,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: GestureDetector(
                  key: ValueKey(copied),
                  onTap: copied ? null : onCopy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: copied
                          ? Colors.green.withOpacity(0.12)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          copied
                              ? Icons.check_rounded
                              : Icons.copy_rounded,
                          size: 14,
                          color: copied ? Colors.green : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          copied ? 'odeme.kopyalandi'.tr() : 'odeme.kopyala'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: copied ? Colors.green : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bilgi notu ──
class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Adımlar ──
class _StepList extends StatelessWidget {
  final bool isUpgrade;
  const _StepList({required this.isUpgrade});

  @override
  Widget build(BuildContext context) {
    final steps = isUpgrade
        ? [
            (Icons.touch_app_rounded,    'odeme.paketi_yukaridan_sec'.tr()),
            (Icons.account_balance_rounded, 'odeme.ibana_transfer'.tr()),
            (Icons.edit_note_rounded,    'odeme.aciklama_bilgi'.tr()),
            (Icons.phone_in_talk_rounded,'odeme.kulubu_ara'.tr()),
            (Icons.verified_rounded,     'odeme.yonetici_onayi_sonra'.tr()),
          ]
        : [
            (Icons.account_balance_rounded, 'odeme.ibana_transfer'.tr()),
            (Icons.edit_note_rounded,    'odeme.aciklama_bilgi'.tr()),
            (Icons.phone_in_talk_rounded,'odeme.kulubu_ara'.tr()),
            (Icons.autorenew_rounded,    'odeme.yonetici_onayi_sonra'.tr()),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numara
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // İkon + metin
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(steps[i].$1, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          steps[i].$2,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 16,
                      margin: const EdgeInsets.only(left: 12),
                      color: AppColors.surfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ],
        ],
      ),
    );
  }
}

// ── İletişim kartı ──
class _ContactCard extends StatelessWidget {
  final String phone;
  final String address;
  const _ContactCard({required this.phone, required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          _ContactRow(icon: Icons.phone_rounded,       label: 'admin.telefon'.tr(), value: phone),
          const SizedBox(height: 12),
          _ContactRow(icon: Icons.location_on_rounded, label: 'admin.adres'.tr(),   value: address),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}