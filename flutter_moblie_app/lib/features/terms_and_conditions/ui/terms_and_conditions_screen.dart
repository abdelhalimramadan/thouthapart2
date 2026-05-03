import 'package:flutter/material.dart';
import 'package:thoutha_mobile_app/features/home_screen/ui/drawer/drawer.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: HomeDrawer(),
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        titleSpacing: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'terms_and_conditions.terms_and_conditions'.tr(),
              style: textTheme.titleLarge?.copyWith(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Image.asset(
              'assets/images/splash-logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            _buildSection(
              context,
              'terms_and_conditions.first_definition_of_the'.tr(),
              'terms_and_conditions.the_thoutha_application_is'.tr(),
            ),
            _buildSection(
              context,
              'terms_and_conditions.second_the_role_of'.tr(),
              'terms_and_conditions.the_application_is_only'.tr() + 'terms_and_conditions.we_do_not_guarantee'.tr() + 'terms_and_conditions.we_do_not_control'.tr() + 'terms_and_conditions.any_agreement_concluded_is'.tr(),
            ),
            _buildSection(
              context,
              'terms_and_conditions.patient_terms_and_conditions'.tr(),
              'terms_and_conditions.the_application_does_not'.tr() + 'terms_and_conditions.the_patient_is_responsible'.tr() + 'terms_and_conditions.the_application_is_not'.tr() + 'terms_and_conditions.failure_to_attend_or'.tr(),
            ),
            _buildSection(
              context,
              'terms_and_conditions.terms_and_conditions_for'.tr(),
              'terms_and_conditions.the_student_acknowledges_that'.tr() + 'terms_and_conditions.the_student_bears_full'.tr() + 'terms_and_conditions.adherence_to_appointments_and'.tr() + 'terms_and_conditions.the_application_has_the'.tr(),
            ),
            _buildSection(
              context,
              'terms_and_conditions.disclaimer'.tr(),
              'terms_and_conditions.thoutha_application_is_not'.tr(),
            ),
            _buildSection(
              context,
              'terms_and_conditions.approval'.tr(),
              'terms_and_conditions.your_use_of_the'.tr(),
            ),
            SizedBox(height: 24),
            Center(
              child: Text(
                'terms_and_conditions.last_updated_february_2026'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey,
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            textAlign: TextAlign.start,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          ...content.split('\n').map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 2, right: 0),
                child: Text(
                  line,
                  textAlign: TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
