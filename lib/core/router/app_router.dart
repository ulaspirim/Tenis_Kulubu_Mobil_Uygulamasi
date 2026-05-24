import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tenis_kulubu/features/auth/presentation/screens/login_screen.dart';
import 'package:tenis_kulubu/features/auth/presentation/screens/register_screen.dart';
import 'package:tenis_kulubu/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tenis_kulubu/features/home/screens/main_shell_screen.dart';
import 'package:tenis_kulubu/features/home/screens/home_screen.dart';
import 'package:tenis_kulubu/features/reservation/presentation/screens/reservation_screen.dart';
import 'package:tenis_kulubu/features/announcements/screens/announcements_screen.dart';
import 'package:tenis_kulubu/features/announcements/screens/announcement_detail_screen.dart';
import 'package:tenis_kulubu/features/chat/screens/chat_list_screen.dart';
import 'package:tenis_kulubu/features/chat/screens/chat_room_screen.dart';
import 'package:tenis_kulubu/features/membership/screens/membership_screen.dart';
import 'package:tenis_kulubu/features/profile/screens/profile_screen.dart';
import 'package:tenis_kulubu/features/profile/screens/settings_screen.dart';
import 'package:tenis_kulubu/features/home/screens/splash_screen.dart';
import 'package:tenis_kulubu/features/home/screens/onboarding_screen.dart';
import 'package:tenis_kulubu/features/auth/presentation/screens/force_change_password_screen.dart';
import 'package:tenis_kulubu/features/profile/screens/change_password_screen.dart';
import 'package:tenis_kulubu/features/admin/presentation/screens/admin_screen.dart';
import 'package:tenis_kulubu/features/profile/screens/personal_info_screen.dart';

// Diğer rezervasyon ekranı importunun hemen altına ekleyebilirsin:
import 'package:tenis_kulubu/features/reservation/presentation/screens/reservation_screen.dart';
import 'package:tenis_kulubu/features/reservation/presentation/screens/my_reservations_screen.dart';
import 'package:tenis_kulubu/features/announcements/screens/notifications_screen.dart';

import 'package:tenis_kulubu/features/announcements/screens/notification_settings_screen.dart';
import 'package:tenis_kulubu/features/profile/screens/support_screen.dart';

class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String reservation = '/reservation';
  static const String reservationDetail = '/reservation/:id';
  static const String myReservations = '/my-reservations';
  static const String announcements = '/announcements';
  static const String announcementDetail = '/announcements/:id';
  static const String chat = '/chat';
  static const String chatRoom = '/chat/:roomId';
  static const String membership = '/membership';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String forceChangePassword = '/force-change-password';
  static const String changePassword = '/change-password';
  static const String admin = '/admin';
  static const String personalInfo = '/personal-info';
  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String notificationSettings = '/notification-settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRouter.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRouter.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRouter.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRouter.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/force-change-password',
        builder: (context, state) => const ForceChangePasswordScreen(),
      ),
      GoRoute(
        path: AppRouter.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRouter.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/personal-info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),

      GoRoute(
            path: AppRouter.notifications,
            builder: (context, state) => const NotificationsScreen(),
          ),
          
      GoRoute(
        path: AppRouter.support,
        builder: (context, state) => const SupportScreen(),
      ),
      

      // Ana Shell (Bottom Navigation Bar)
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: AppRouter.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRouter.reservation,
            builder: (context, state) => const ReservationScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ReservationDetailScreen(
                  reservationId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
   
          
         
          GoRoute(
            path: AppRouter.myReservations,
            builder: (context, state) => const MyReservationsScreen(),
          ),
          GoRoute(
            path: AppRouter.announcements,
            builder: (context, state) => const AnnouncementsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => AnnouncementDetailScreen(
                  announcementId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRouter.chat,
            builder: (context, state) => const ChatListScreen(),
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (context, state) => ChatRoomScreen(
                  roomId: state.pathParameters['roomId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRouter.membership,
            builder: (context, state) => const MembershipScreen(),
          ),
          GoRoute(
            path: AppRouter.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRouter.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRouter.notificationSettings,
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRouter.admin,
        builder: (context, state) => const AdminScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Sayfa bulunamadı: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.home),
              child: Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    ),
  );
});
