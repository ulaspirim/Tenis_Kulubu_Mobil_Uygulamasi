import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ayarların veri modelini oluşturalım
class NotificationSettings {
  final bool appNotifications;
  final bool emailNotifications;
  final bool announcementAlerts;
  final bool courtReminders; // Tenis kulübü için yeni eklediğimiz kort hatırlatıcısı

  NotificationSettings({
    this.appNotifications = true,
    this.emailNotifications = false,
    this.announcementAlerts = true,
    this.courtReminders = true,
  });

  NotificationSettings copyWith({
    bool? appNotifications,
    bool? emailNotifications,
    bool? announcementAlerts,
    bool? courtReminders,
  }) {
    return NotificationSettings(
      appNotifications: appNotifications ?? this.appNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      announcementAlerts: announcementAlerts ?? this.announcementAlerts,
      courtReminders: courtReminders ?? this.courtReminders,
    );
  }
}

// StateNotifier ile durumu yönetelim
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(NotificationSettings());

  void toggleAppNotifications(bool val) => state = state.copyWith(appNotifications: val);
  void toggleEmailNotifications(bool val) => state = state.copyWith(emailNotifications: val);
  void toggleAnnouncementAlerts(bool val) => state = state.copyWith(announcementAlerts: val);
  void toggleCourtReminders(bool val) => state = state.copyWith(courtReminders: val);
}

// Ekrandan erişeceğimiz Provider
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});