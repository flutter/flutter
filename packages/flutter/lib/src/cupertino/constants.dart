// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

/// The minimum dimension of any interactive region according to the iOS Human
/// Interface Guidelines.
///
/// This is used to avoid small regions that are hard for the user to interact
/// with. It applies to both dimensions of a region, so a square of size
/// kMinInteractiveDimension x kMinInteractiveDimension is the smallest
/// acceptable region that should respond to gestures.
///
/// See also:
///
///  * [kMinInteractiveDimension]
///  * <https://developer.apple.com/ios/human-interface-guidelines/visual-design/adaptivity-and-layout/>
const double kMinInteractiveDimensionCupertino = 44.0;

/// The relative values needed to transform a color to it's equivalent focus
/// outline color.
///
/// These are used to draw a focus ring around [CupertinoSwitch],
/// [CupertinoCheckbox], [CupertinoRadio] and [CupertinoButton].
///
/// See also:
///
/// * <https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/>
const double kCupertinoFocusColorOpacity = 0.80,
             kCupertinoFocusColorBrightness = 0.69,
             kCupertinoFocusColorSaturation = 0.835;
