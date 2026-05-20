import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Ana Renkler — Tenis Yeşili + Lacivert
  static const Color primary = Color(0xFF1B5E20);       // Koyu tenis yeşili
  static const Color primaryLight = Color(0xFF4CAF50);  // Açık yeşil
  static const Color primaryDark = Color(0xFF003300);   // Çok koyu yeşil

  static const Color secondary = Color(0xFF0D1B4B);     // Lacivert (kulüp rengi)
  static const Color secondaryLight = Color(0xFF1A3A8F);
  static const Color accent = Color(0xFFF9A825);        // Altın sarısı (ödül/rozet)

  // Nötr
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF1F5);

  // Metin
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF5A6472);
  static const Color textHint = Color(0xFFADB5C0);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Durum Renkleri
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);

  // Rezervasyon Durumları
  static const Color reservationActive = Color(0xFF1B5E20);
  static const Color reservationPending = Color(0xFFF57C00);
  static const Color reservationCancelled = Color(0xFFC62828);
  static const Color reservationCompleted = Color(0xFF5A6472);

  // Tesis Renkleri
  static const Color courtColor = Color(0xFF2196F3);    // Tenis kortu — mavi
  static const Color poolColor = Color(0xFF00BCD4);     // Havuz — cyan
  static const Color gymColor = Color(0xFFFF5722);      // Spor salonu — turuncu

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B4B), Color(0xFF1B5E20)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A8F), Color(0xFF0D1B4B)],
  );

  // Gölge
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
