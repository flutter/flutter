// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  BuildContext context;

  // Changes made in https://github.com/flutter/flutter/pull/68736
  MediaQuery.of(context, nullOk: true);
  MediaQuery.of(context, nullOk: false);
  MediaQuery.of(error: '');

  // Change made in https://github.com/flutter/flutter/issues/183701
  MediaQuery.maybeOf(context);
  MediaQuery.maybeSizeOf(context);
  MediaQuery.maybeWidthOf(context);
  MediaQuery.maybeHeightOf(context);
  MediaQuery.maybeOrientationOf(context);
  MediaQuery.maybeDevicePixelRatioOf(context);
  MediaQuery.maybeTextScalerOf(context);
  MediaQuery.maybePlatformBrightnessOf(context);
  MediaQuery.maybePaddingOf(context);
  MediaQuery.maybeViewInsetsOf(context);
  MediaQuery.maybeSystemGestureInsetsOf(context);
  MediaQuery.maybeViewPaddingOf(context);
  MediaQuery.maybeAlwaysUse24HourFormatOf(context);
  MediaQuery.maybeAccessibleNavigationOf(context);
  MediaQuery.maybeInvertColorsOf(context);
  MediaQuery.maybeHighContrastOf(context);
  MediaQuery.maybeOnOffSwitchLabelsOf(context);
  MediaQuery.maybeDisableAnimationsOf(context);
  MediaQuery.maybeReduceMotionOf(context);
  MediaQuery.maybeBoldTextOf(context);
  MediaQuery.maybeSupportsAnnounceOf(context);
  MediaQuery.maybeNavigationModeOf(context);
  MediaQuery.maybeGestureSettingsOf(context);
  MediaQuery.maybeDisplayFeaturesOf(context);
  MediaQuery.maybeSupportsShowingSystemContextMenu(context);
  MediaQuery.displayCornerRadiiOf(context);
  // Change made in https://github.com/flutter/flutter/pull/128522
  MediaQueryData();
  MediaQueryData(textScaleFactor: 2.0)
    ..copyWith(textScaleFactor: 2.0)
    ..copyWith();

  // Changes made in https://github.com/flutter/flutter/pull/119647
  MediaQueryData.fromWindow(View.of(context));

  // Changes made in https://github.com/flutter/flutter/pull/114459
  MediaQuery.boldTextOverride(context);
}
