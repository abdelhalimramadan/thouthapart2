import 'package:thoutha_mobile_app/core/routing/routes.dart';
import 'package:flutter/material.dart';

import '../../features/login/ui/login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/reset_password/ui/otp_verification_screen.dart';
import '../../features/sign_up/ui/sign_up_screen.dart';
import '../../features/splash_screen/splash_screen.dart';
import '../../features/chat/ui/chat_screen.dart';
import '../../features/forgot_password/ui/forgot_password_screen.dart';
import '../../features/forgot_password/ui/change_password_screen.dart';
import '../../features/reset_password/ui/reset_password_screen.dart';
import '../../features/home_screen/ui/home_screen.dart';
import '../../features/notifications/ui/notifications_screen.dart';
import '../../features/home_screen/doctor_home/ui/account_deletion_screen.dart';
import '../../features/home_screen/doctor_home/ui/doctor_booking_records_screen.dart';

class AppRouter {
  Route generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashScreen:
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      case Routes.onBoardingScreen:
        return MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        );
      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      case Routes.signUpScreen:
        return MaterialPageRoute(
          builder: (context) => const SignUpScreen(),
        );
      case Routes.chatScreen:
        return MaterialPageRoute(
          builder: (context) => const ChatScreen(),
        );
      case Routes.forgotPasswordScreen:
        return MaterialPageRoute(
          builder: (context) => const ForgotPasswordScreen(),
        );
      case Routes.changePasswordScreen:
        return MaterialPageRoute(
          builder: (context) => const ChangePasswordScreen(),
        );
      case Routes.otpVerificationScreen:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phone: args['phone'] ?? '',
            expiresInSeconds: args['expires_in'] ?? 300,
          ),
        );
      case Routes.resetPasswordScreen:
        final resetArgs = settings.arguments as Map? ?? {};
        return MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            phone: (resetArgs['phone'] ?? '').toString(),
          ),
        );
      case Routes.categoriesScreen:
        return MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        );
      case Routes.notificationsScreen:
        return MaterialPageRoute(
          builder: (context) => const NotificationsScreen(),
        );
      case Routes.accountDeletionScreen:
        return MaterialPageRoute(
          builder: (context) => const AccountDeletionScreen(),
        );
      case Routes.doctorBookingRecordsScreen:
        return MaterialPageRoute(
          builder: (context) => const DoctorBookingRecordsScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
