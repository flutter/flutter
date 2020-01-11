// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

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
  static bool isTablet(BuildContext context) {
    if(MediaQuery.of(context).devicePixelRatio < 2 && (MediaQuery.of(context).size.width >= 1000 || MediaQuery.of(context).size.height >= 1000)) {
      return true;
    }
    else if(MediaQuery.of(context).devicePixelRatio == 2 && (MediaQuery.of(context).size.width >= 1920 || MediaQuery.of(context).size.height >= 1920)) {
      return true;
    }
    else
      return false;
  }

  // Device-specific helpers
  // (source: https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions)
  // TODO(kerberjg): investigate results of using this on Android devices (potential resolution mismatch)

  /// Returns true if phone is Xs Max, 11 Pro Max
  static bool isMaxStyle(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio == 3 && (MediaQuery.of(context).size.width == 2688 || MediaQuery.of(context).size.height == 2688);
  }

  /// Returns true if phone is X, Xr, Xs, 11, 11 Pro
  static bool is10Style(BuildContext context) {
    return (MediaQuery.of(context).size.width == 828 || MediaQuery.of(context).size.height == 828) || (MediaQuery.of(context).size.width == 1125 || MediaQuery.of(context).size.height == 1125);
  }

  /// Returns true if phone is 6+, 6s+, 7+, 8+
  static bool isPlusStyle(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio == 3 && (MediaQuery.of(context).size.width == 2208 || MediaQuery.of(context).size.height == 2208);
  }

  /// Returns true if phone is 6, 6s, 7, 8 (non-plus)
  static bool is6Style(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio == 2 && (MediaQuery.of(context).size.width == 750 || MediaQuery.of(context).size.height == 750);
  }

  /// Returns true if phone is 5, 5c, 5s, SE, iPod 5g
  static bool is5Style(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio == 2 && (MediaQuery.of(context).size.width == 640 || MediaQuery.of(context).size.height == 640) && (MediaQuery.of(context).size.width == 1136 || MediaQuery.of(context).size.height == 1136);
  }

  /// Returns true if phone is 4, 4s, iPod 4g
  static bool is4Style(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio == 2 && (MediaQuery.of(context).size.width == 640 || MediaQuery.of(context).size.height == 640) && (MediaQuery.of(context).size.width == 960 || MediaQuery.of(context).size.height == 960);
  }

  // NOTE: devices from series 3 and below are not included because they don't support iOS 8

  /// Returns the width [CupertinoSizeClass] for the view in the current [BuildContext]
  static CupertinoSizeClass getWidthSizeClass(BuildContext context) {
    if(isTablet(context)) {
      return CupertinoSizeClass.regular;
    } else if(MediaQuery.of(context).orientation == Orientation.portrait) {
      return isPlusStyle(context) || isMaxStyle(context) ? CupertinoSizeClass.regular : CupertinoSizeClass.compact;
    } else {
      return CupertinoSizeClass.compact;
    } 
  }

  /// Returns the height [CupertinoSizeClass] for the view in the current [BuildContext]
  static CupertinoSizeClass getHeightSizeClass(BuildContext context) {
    if(isTablet(context)) {
      return CupertinoSizeClass.regular;
    } else {
      return MediaQuery.of(context).orientation == Orientation.portrait ? CupertinoSizeClass.regular : CupertinoSizeClass.compact;
    }
  }
}