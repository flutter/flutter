// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/foundation.dart';

import 'mouse_cursor/android.dart';

import 'mouse_cursor/basic.dart';
import 'mouse_cursor/glfw.dart';

export 'mouse_cursor/basic.dart';

/// TODOC
@immutable
class SystemCursor extends MouseCursor {
  SystemCursorCollection get _collection {
    if (_cachedCollection == null) {
      if (Platform.isLinux)
        _cachedCollection = const GLFWSystemCursorCollection();
      if (Platform.isAndroid)
        _cachedCollection = const AndroidSystemCursorCollection();
      _cachedCollection ??= const UnsupportedSystemCursorCollection();
    }
    return _cachedCollection;
  }
  SystemCursorCollection _cachedCollection;

  /// TODOC
  const SystemCursor(this.shape);

  /// TODOC
  final SystemCursorShape shape;

  @override
  Future<void> onActivate(MouseCursorActivateDetails details) {
    return _collection.fromShape(shape).onActivate(details);
  }

  @override
  String describeCursor() {
    return _collection.fromShape(shape).describeCursor();
  }
}

class SystemCursors implements SystemCursorCollection {
  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A layer with this value will absorb the search for mouse cursor
  /// configuration, but the pointer's cursor will not be changed when it enters
  /// or is hovering this layer. This value is typically used on a platform view
  /// or other layers that manages the cursor by itself.
  releaseControl,

  /// Displays no cursor at the pointer.
  none,

  /// The platform-dependent basic cursor. Typically the shape of an arrow.
  basic,

  /// A cursor that indicates links or something that needs to be emphasized
  /// to be clickable. Typically the shape of a pointing hand.
  click,

  /// A cursor that indicates a selectable text. Typically the shape of an
  /// I-beam.
  text,

  /// A cursor that indicates an unpermitted action. Typically the shape of a
  /// circle with a diagnal line.
  forbidden,

  /// A cursor that indicates something that can be dragged. Typically the shape
  /// of an open hand.
  grab,

  /// A cursor that indicates something that is being dragged. Typically the
  /// shape of a closed hand.
  grabbing,
}
