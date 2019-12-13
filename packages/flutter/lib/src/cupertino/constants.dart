// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
