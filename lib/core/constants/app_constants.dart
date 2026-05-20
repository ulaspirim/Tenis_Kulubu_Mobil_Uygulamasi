class AppConstants {
  AppConstants._();

  // Uygulama Bilgileri
  static const String appName = 'UTK';
  static const String appFullName = 'Ulaş Tenis Kulübü - Mobil Uygulaması';
  static const String appVersion = '1.0.0';

  // Firestore Koleksiyonları
  static const String usersCollection = 'users';
  static const String reservationsCollection = 'reservations';
  static const String announcementsCollection = 'announcements';
  static const String tournamentsCollection = 'tournaments';
  static const String messagesCollection = 'messages';
  static const String facilitiesCollection = 'facilities';
  static const String membershipsCollection = 'memberships';
  static const String notificationsCollection = 'notifications';

  // Tesis Tipleri
  static const String facilityTennisCourt = 'tennis_court';
  static const String facilityPool = 'pool';
  static const String facilityGym = 'gym';
  static const String facilityMultipurpose = 'multipurpose';

  // Rezervasyon Durumları
  static const String reservationStatusActive = 'active';
  static const String reservationStatusPending = 'pending';
  static const String reservationStatusCancelled = 'cancelled';
  static const String reservationStatusCompleted = 'completed';

  // Üyelik Tipleri
  static const String membershipStandard = 'standard';
  static const String membershipPremium = 'premium';
  static const String membershipFamily = 'family';
  static const String membershipStudent = 'student';

  // Üyelik Durumları
  static const String membershipActive = 'active';
  static const String membershipExpired = 'expired';
  static const String membershipSuspended = 'suspended';

  // Duyuru Kategorileri
  static const String announcementGeneral = 'general';
  static const String announcementTournament = 'tournament';
  static const String announcementMaintenance = 'maintenance';
  static const String announcementEvent = 'event';

  // Rezervasyon Ayarları
  static const int reservationSlotMinutes = 60; // 1 saatlik slotlar
  static const int maxAdvanceReservationDays = 14; // 2 hafta önceden
  static const int maxActiveReservationsPerUser = 3;
  static const String openTime = '07:00';
  static const String closeTime = '23:00';

  // Shared Preferences Anahtarları
  static const String prefUserId = 'user_id';
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefThemeMode = 'theme_mode';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefLanguage = 'language';

  // Sayfalama
  static const int pageSize = 20;

  // Üyelik Hatırlatma (gün)
  static const int membershipWarningDays = 30;
  static const int membershipCriticalDays = 7;

  // Animasyon Süreleri
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Tesis Adları
  static const Map<String, String> facilityNames = {
    facilityTennisCourt: 'Tenis Kortu',
    facilityPool: 'Yüzme Havuzu',
    facilityGym: 'Spor Salonu',
    facilityMultipurpose: 'Çok Amaçlı Alan',
  };

  // Üyelik Paket Adları
  static const Map<String, String> membershipNames = {
    membershipStandard: 'Standart Üyelik',
    membershipPremium: 'Premium Üyelik',
    membershipFamily: 'Aile Üyeliği',
    membershipStudent: 'Öğrenci Üyeliği',
  };
}

class AppAssets {
  AppAssets._();

  // Görseller
  static const String logo = 'assets/images/logo.png';
  static const String logoWhite = 'assets/images/logo_white.png';
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  static const String onboarding3 = 'assets/images/onboarding_3.png';
  static const String tennisCourt = 'assets/images/tennis_court.png';
  static const String pool = 'assets/images/pool.png';
  static const String gym = 'assets/images/gym.png';
  static const String placeholder = 'assets/images/placeholder.png';
  static const String avatarPlaceholder = 'assets/images/avatar_placeholder.png';

  // İkonlar (SVG)
  static const String iconTennis = 'assets/icons/tennis.svg';
  static const String iconPool = 'assets/icons/pool.svg';
  static const String iconGym = 'assets/icons/gym.svg';
  static const String iconTrophy = 'assets/icons/trophy.svg';
  static const String iconMembership = 'assets/icons/membership.svg';

  // Animasyonlar (Lottie)
  static const String animLoading = 'assets/animations/loading.json';
  static const String animSuccess = 'assets/animations/success.json';
  static const String animEmpty = 'assets/animations/empty.json';
  static const String animError = 'assets/animations/error.json';
  static const String animTennis = 'assets/animations/tennis_ball.json';
}
