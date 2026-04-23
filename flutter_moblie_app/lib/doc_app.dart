import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/routing/navigator_service.dart';
import 'core/routing/routes.dart';
import 'core/theming/app_theme.dart';
import 'core/theming/theme_provider.dart';

class DocApp extends StatelessWidget {
  final AppRouter appRouter;

  const DocApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double height = constraints.maxHeight;

              // True Full-Screen Tablet Strategy:
              // We allow the canvas to spread 100%, but we cap 'designSize'
              // to ensure scaling factors (.w, .h, .sp) never exceed ~1.3x.
              double designWidth = 375;
              double designHeight = 812;

              if (width >= 600) {
                // Tablet spreading mode
                designWidth = width / 1.3;
                designHeight = height / 1.3;
              }

              return ScreenUtilInit(
                designSize: Size(designWidth, designHeight),
                minTextAdapt: true,
                splitScreenMode: true,
                fontSizeResolver: (fontSize, instance) {
                  // Standard scaling capped at a safe 1.5x of original size
                  final double scaledSize = fontSize * instance.scaleText;
                  final double maxAllowed = fontSize * 1.5;
                  return scaledSize > maxAllowed ? maxAllowed : scaledSize;
                },
                builder: (context, child) {
                  return MaterialApp(
                    navigatorKey: NavigatorService.navigatorKey,
                    title: 'ثوثة',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeProvider.isDarkMode
                        ? ThemeMode.dark
                        : ThemeMode.light,
                    initialRoute: Routes.splashScreen,
                    onGenerateRoute: appRouter.generateRoute,
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [
                      Locale('ar', 'EG'),
                      Locale('en', 'US'),
                    ],
                    locale: const Locale('ar', 'EG'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
