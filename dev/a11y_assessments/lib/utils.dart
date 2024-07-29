import 'package:flutter/services.dart';

void setWebTitle(String titleName, int color) {
  SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
    label: titleName,
    primaryColor: color
  ));
}

Color appSeedColor = const Color(0xff6750a4);
