import 'package:flutter/services.dart';

void setWebTitle(String titleName, int color) {
  SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
    label: titleName,
    primaryColor: color
  ));
}
