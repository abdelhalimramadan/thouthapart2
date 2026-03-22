import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/routing/routes.dart';
import '../../core/theming/colors.dart';
import '../../core/helpers/notification_permission_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheOnboardingImages();
  }

  Future<void> _precacheOnboardingImages() async {
    final images = [
      'assets/images/1-onboarding.jpg',
      'assets/images/2-inboarding.jpg',
      'assets/images/3-onboarding.jpg',
    ];

    try {
      await Future.wait(
        images.map((image) => precacheImage(
              ResizeImage(AssetImage(image), width: 1500),
              context,
            )),
      );
    } catch (e) {
      // ignore
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationDialog(
          title: 'خدمات الموقع مطلوبة',
          content: 'يرجى تفعيل خدمات الموقع للمتابعة.',
          onPressed: () async {
            Navigator.of(context).pop();
            await Geolocator.openLocationSettings();
          },
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showLocationDialog(
            title: 'إذن الموقع مطلوب',
            content:
                'يحتاج التطبيق إلى إذن الموقع ليعمل بشكل صحيح. يرجى منح الإذن.',
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.requestPermission();
              _checkLocationPermission();
            },
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        _showLocationDialog(
          title: 'إذن الموقع مطلوب',
          content:
              'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق للمتابعة.',
          onPressed: () async {
            Navigator.of(context).pop();
            await Geolocator.openAppSettings();
          },
        );
      }
      return;
    }

    if (mounted) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.onBoardingScreen);
      }
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (mounted) {
        await NotificationPermissionHelper.showPermanentlyDeniedDialog(
          context,
          () async {
            Navigator.pop(context);
            await Geolocator.openAppSettings();
          },
        );
        // Remove immediate recursive check to avoid double-dialog.
        // The check will be triggered by didChangeAppLifecycleState when resuming.
      }
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      if (mounted) {
        final result =
            await NotificationPermissionHelper.showNotificationPermissionDialog(
                context);
        if (!mounted) return;
        if (result == true) {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          if (!mounted) return;
          // After first-time system prompt, always proceed to avoid immediate "Go to Settings" dialog.
          Navigator.pushReplacementNamed(context, Routes.onBoardingScreen);
        } else {
          // If user chose "Not Now" (false) or dismissed the dialog (null),
          // proceed to onboarding.
          Navigator.pushReplacementNamed(context, Routes.onBoardingScreen);
        }
      }
      return;
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.onBoardingScreen);
    }
  }

  void _showLocationDialog({
    required String title,
    required String content,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          content,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: onPressed,
            child: Text(
              'موافق',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                color: ColorsManager.mainBlue,
                fontSize: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.7, -0.7),
                radius: 1.5,
                colors: [
                  ColorsManager.layerBlur1.withValues(alpha: 0.4),
                  ColorsManager.layerBlur1.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.1, 0.5, 0.8],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.7, 0.7),
                radius: 1.5,
                colors: [
                  ColorsManager.layerBlur2.withValues(alpha: 0.4),
                  ColorsManager.layerBlur2.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                stops: const [0.1, 0.5, 0.8],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/splash-logo.png',
                  width: 200.w,
                  height: 200.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 32.h),
                Text(
                  'رعاية ذكية، لمسة طبية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: ColorsManager.fontColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
