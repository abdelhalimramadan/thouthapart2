import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/routing/routes.dart';
import '../../core/theming/colors.dart';
import '../../core/helpers/notification_permission_helper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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
            _checkLocationPermission(); 
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
            onPressed: () {
              Navigator.of(context).pop();
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
            _checkLocationPermission(); 
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

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
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
        _checkNotificationPermission();
      }
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      if (mounted) {
        await NotificationPermissionHelper.showNotificationPermissionDialog(
            context);
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        _checkNotificationPermission();
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
    final width = MediaQuery.of(context).size.width;
    final baseFontSize = width * 0.04;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize * 1.125, // 18sp
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          content,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: baseFontSize * 0.875, // 14sp
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
                fontSize: baseFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final baseFontSize = width * 0.04;

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
                  width: 200 * (width / 390),
                  height: 200 * (width / 390),
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 32),
                Text(
                  'رعاية ذكية، لمسة طبية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize * 1.75, // 28sp
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
