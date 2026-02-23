import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'حول التطبيق',
          style: textTheme.titleLarge?.copyWith(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
                    width: 1.1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ثوثة',
                      style: textTheme.titleLarge?.copyWith(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تطبيق ثوثة يهدف إلى تسهيل التواصل بين طلاب طب الأسنان والمرضى،\n'
                      'ويقدم تجربة استخدام بسيطة وآمنة لتنظيم الحجوزات ومتابعة الحالات.\n'
                      'يساعد التطبيق على توفير معلومات أوضح عن الخدمات المتاحة، ويُسهّل\n'
                      'إدارة المواعيد والتواصل السريع، بما يدعم رحلة علاجية أكثر سلاسة.\n'
                      'نسعى دائمًا لتحسين الجودة وإضافة مزايا تخدم المستخدمين بشكل أفضل.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 2,
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الإصدار 1.0.3',
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
