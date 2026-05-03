import 'package:flutter/material.dart';

import '../../../../core/theming/styles.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class TermsAndConditionsText extends StatelessWidget {
  const TermsAndConditionsText({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text:
                'login.by_logging_in_you'.tr(),
            style: TextStyles.font13GrayRegular,
          ),
          TextSpan(
            text: 'login.terms_and_conditions'.tr(),
            style: TextStyles.font13DarkBlueMedium,
          ),
          TextSpan(
            text: 'login.and'.tr(),
            style: TextStyles.font13GrayRegular.copyWith(height: 1.5),
          ),
          TextSpan(
            text: 'login.privacy_policy'.tr(),
            style: TextStyles.font13DarkBlueMedium,
          ),
        ],
      ),
    );
  }
}
