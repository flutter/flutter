// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CupertinoTextTheme matches Apple Design resources', () {
    // Check the default cupertino text theme against the style values
    // Values derived from https://developer.apple.com/design/resources/.

    const CupertinoTextThemeData theme = CupertinoTextThemeData();
    const FontWeight normal = FontWeight.normal;
    const FontWeight regular = FontWeight.w400;
    const FontWeight medium = FontWeight.w500;
    const FontWeight semiBold = FontWeight.w600;
    const FontWeight bold = FontWeight.w700;

    // TextStyle 17 -0.41
    expect(theme.textStyle.fontSize, 17);
    expect(theme.textStyle.fontFamily, '.SF Pro Text');
    expect(theme.textStyle.letterSpacing, -0.41);
    expect(theme.textStyle.fontWeight, null);

    // ActionTextStyle 17 -0.41
    expect(theme.actionTextStyle.fontSize, 17);
    expect(theme.actionTextStyle.fontFamily, '.SF Pro Text');
    expect(theme.actionTextStyle.letterSpacing, -0.41);
    expect(theme.actionTextStyle.fontWeight, null);

    // TextStyle 17 -0.41
    expect(theme.tabLabelTextStyle.fontSize, 10);
    expect(theme.tabLabelTextStyle.fontFamily, '.SF Pro Text');
    expect(theme.tabLabelTextStyle.letterSpacing, -0.24);
    expect(theme.tabLabelTextStyle.fontWeight, medium);

    // NavTitle SemiBold 17 -0.41
    expect(theme.navTitleTextStyle.fontSize, 17);
    expect(theme.navTitleTextStyle.fontFamily, '.SF Pro Text');
    expect(theme.navTitleTextStyle.letterSpacing, -0.41);
    expect(theme.navTitleTextStyle.fontWeight, semiBold);

    // NavLargeTitle Bold 34 0.41
    expect(theme.navLargeTitleTextStyle.fontSize, 34);
    expect(theme.navLargeTitleTextStyle.fontFamily, '.SF Pro Display');
    expect(theme.navLargeTitleTextStyle.letterSpacing, 0.41);
    expect(theme.navLargeTitleTextStyle.fontWeight, bold);

    // Picker Regular 21 -0.6
    expect(theme.pickerTextStyle.fontSize, 21);
    expect(theme.pickerTextStyle.fontFamily, '.SF Pro Display');
    expect(theme.pickerTextStyle.letterSpacing, -0.6);
    expect(theme.pickerTextStyle.fontWeight, regular);

    // DateTimePicker Normal 21
    expect(theme.dateTimePickerTextStyle.fontSize, 21);
    expect(theme.dateTimePickerTextStyle.fontFamily, '.SF Pro Display');
    expect(theme.dateTimePickerTextStyle.letterSpacing, null);
    expect(theme.dateTimePickerTextStyle.fontWeight, normal);
  });
}
