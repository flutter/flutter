// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

/// The dart:io implementation of [viewportOrigin].
///
/// Views are not embedded in a browser viewport off the web, so this always
/// returns [Offset.zero].
///
/// See also:
///
///  * `_view_utils_web.dart`, which has the web implementation
Offset viewportOrigin(FlutterView view) => Offset.zero;
