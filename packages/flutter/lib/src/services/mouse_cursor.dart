// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'mouse_cursor/android.dart';

import 'mouse_cursor/basic.dart';
import 'mouse_cursor/glfw.dart';

export 'mouse_cursor/basic.dart';

/// TODOC
@immutable
class SystemCursor extends PlatformDependentCursor {
  /// TODOC
  const SystemCursor(this.shape, this.description);

  /// TODOC
  final SystemCursorShape shape;

  /// TODOC
  final String description;

  @override
  Future<void> onActivateOnPlatform(MouseCursorTargetPlatform platform, ActivateMouseCursorDetails details) {
    switch (platform) {
      case MouseCursorTargetPlatform.android:
        return const AndroidSystemCursorCollection()
          .activateShape(details, shape);
      case MouseCursorTargetPlatform.linux:
        return const GLFWSystemCursorCollection()
          .activateShape(details, shape);
    }
    return null;
  }

  @override
  String describeCursor() {
    return description;
  }
}

/// TODOC
class SystemCursors {
  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A layer with this value will absorb the search for mouse cursor
  /// configuration, but the pointer's cursor will not be changed when it enters
  /// or is hovering this layer. This value is typically used on a platform view
  /// or other layers that manages the cursor by itself.
  static const MouseCursor releaseControl = NoopMouseCursor();

  /// Displays no cursor at the pointer.
  static const MouseCursor none = SystemCursor(SystemCursorShape.none, 'none');

  /// The platform-dependent basic cursor. Typically the shape of an arrow.
  static const MouseCursor basic = SystemCursor(SystemCursorShape.basic, 'basic');

  /// A cursor that indicates links or something that needs to be emphasized
  /// to be clickable. Typically the shape of a pointing hand.
  static const MouseCursor click = SystemCursor(SystemCursorShape.click, 'click');

  /// A cursor that indicates a selectable text. Typically the shape of an
  /// I-beam.
  static const MouseCursor text = SystemCursor(SystemCursorShape.text, 'text');

  /// A cursor that indicates an unpermitted action. Typically the shape of a
  /// circle with a diagnal line.
  static const MouseCursor forbidden = SystemCursor(SystemCursorShape.forbidden, 'forbidden');

  /// A cursor that indicates something that can be dragged. Typically the shape
  /// of an open hand.
  static const MouseCursor grab = SystemCursor(SystemCursorShape.grab, 'grab');

  /// A cursor that indicates something that is being dragged. Typically the
  /// shape of a closed hand.
  static const MouseCursor grabbing = SystemCursor(SystemCursorShape.grabbing, 'grabbing');
}
