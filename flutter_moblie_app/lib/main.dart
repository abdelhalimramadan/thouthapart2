import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/di/dependency_injection.dart';
import 'core/services/firebase_background_handler.dart';
import 'core/routing/app_router.dart';
import 'core/services/firebase_messaging_service.dart';
import 'features/notifications/data/repos/notification_repo.dart';
import 'doc_app.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background handler for data-only FCM payloads
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Setup Dependency Injection
  await setupGetIt();

  // Initialize Firebase Messaging Service
  final firebaseMessagingService = getIt<FirebaseMessagingService>();
  final notificationRepo = getIt<INotificationRepo>();
  await firebaseMessagingService.initialize(notificationRepo);

  // Initialize Arabic locale data for date formatting
  await initializeDateFormatting('ar');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(DocApp(
    appRouter: AppRouter(),
  ));
}
