// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

// TODO(keberjg): reconsider the usage of Size Classes

/// An enumerator denoting iOS' size classes describing the height and width of a view 
/// (source: https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/adaptivity-and-layout/)
enum CupertinoSizeClass {
  /// Compact size class
  compact,
  /// Regular size class
  regular,
}

/// A helper class for [CupertinoSizeClass] detection/calculation.
/// Supports all iOS 8 compatible devices
class CupertinoSizeClassHelper {
  /// Checks whether the current window indicates a tablet layout
  /// (source: https://github.com/ominibyte/flutter_device_type/blob/a7d880f108caa6bc62f933aa81b613f960ae2ec3/lib/flutter_device_type.dart#L29)
  static bool isTablet() {
    if(WidgetsBinding.instance.window.devicePixelRatio < 2 && (WidgetsBinding.instance.window.physicalSize.width >= 1000 || WidgetsBinding.instance.window.physicalSize.height >= 1000)) {
      return true;
    }
    else if(WidgetsBinding.instance.window.devicePixelRatio == 2 && (WidgetsBinding.instance.window.physicalSize.width >= 1920 || WidgetsBinding.instance.window.physicalSize.height >= 1920)) {
      return true;
    }
    else
      return false;
  }

  // Device-specific helpers
  // (source: https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions)
  // TODO(kerberjg): investigate results of using this on Android devices (potential resolution mismatch)

  /// Returns true if phone is Xs Max, 11 Pro Max
  static bool isMaxStyle() {
    return WidgetsBinding.instance.window.devicePixelRatio == 3 && (WidgetsBinding.instance.window.physicalSize.width == 2688 || WidgetsBinding.instance.window.physicalSize.height == 2688);
  }

  /// Returns true if phone is X, Xr, Xs, 11, 11 Pro
  static bool is10Style() {
    return (WidgetsBinding.instance.window.physicalSize.width == 828 || WidgetsBinding.instance.window.physicalSize.height == 828) || (WidgetsBinding.instance.window.physicalSize.width == 1125 || WidgetsBinding.instance.window.physicalSize.height == 1125);
  }

  /// Returns true if phone is 6+, 6s+, 7+, 8+
  static bool isPlusStyle() {
    return WidgetsBinding.instance.window.devicePixelRatio == 3 && (WidgetsBinding.instance.window.physicalSize.width == 2208 || WidgetsBinding.instance.window.physicalSize.height == 2208);
  }

  /// Returns true if phone is 6, 6s, 7, 8 (non-plus)
  static bool is6Style() {
    return WidgetsBinding.instance.window.devicePixelRatio == 2 && (WidgetsBinding.instance.window.physicalSize.width == 750 || WidgetsBinding.instance.window.physicalSize.height == 750);
  }

  /// Returns true if phone is 5, 5c, 5s, SE, iPod 5g
  static bool is5Style() {
    return WidgetsBinding.instance.window.devicePixelRatio == 2 && (WidgetsBinding.instance.window.physicalSize.width == 640 || WidgetsBinding.instance.window.physicalSize.height == 640) && (WidgetsBinding.instance.window.physicalSize.width == 1136 || WidgetsBinding.instance.window.physicalSize.height == 1136);
  }

  /// Returns true if phone is 4, 4s, iPod 4g
  static bool is4Style() {
    return WidgetsBinding.instance.window.devicePixelRatio == 2 && (WidgetsBinding.instance.window.physicalSize.width == 640 || WidgetsBinding.instance.window.physicalSize.height == 640) && (WidgetsBinding.instance.window.physicalSize.width == 960 || WidgetsBinding.instance.window.physicalSize.height == 960);
  }

  /// Returns the window's orientation
  static Orientation getOrientation() {
    return WidgetsBinding.instance.window.physicalSize.width > WidgetsBinding.instance.window.physicalSize.height ? Orientation.landscape : Orientation.portrait;
  }

  // NOTE: devices from series 3 and below are not included because they don't support iOS 8

  /// Returns the width [CupertinoSizeClass] for the view in the current [BuildContext]
  static CupertinoSizeClass getWidthSizeClass(BuildContext context) {
    if(isTablet()) {
      return CupertinoSizeClass.regular;
    } else if(getOrientation() == Orientation.portrait) {
      return isPlusStyle() || isMaxStyle() ? CupertinoSizeClass.regular : CupertinoSizeClass.compact;
    } else {
      return CupertinoSizeClass.compact;
    } 
  }

  /// Returns the height [CupertinoSizeClass] for the view in the current [BuildContext]
  static CupertinoSizeClass getHeightSizeClass(BuildContext context) {
    if(isTablet()) {
      return CupertinoSizeClass.regular;
    } else {
      return getOrientation() == Orientation.portrait ? CupertinoSizeClass.regular : CupertinoSizeClass.compact;
    }
  }
}