// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'android.dart';
import 'common.dart';
import 'glfw.dart';

export 'common.dart' show
  MouseCursor,
  MouseCursorPlatformDelegate,
  SystemCursorShape,
  ActivateMouseCursorDetails;

/// TODOC
abstract class MouseCursorManager {
  /// TODOC
  MouseCursorPlatformDelegate get delegate;

  /// TODOC
  Future<void> setDeviceCursor(int device, MouseCursor cursor) async {
    return cursor.activate(ActivateMouseCursorDetails(
      device: device,
      delegate: delegate,
    ));
  }
}

/// TODOC
class StandardMouseCursorManager extends MouseCursorManager {
  /// Create a [MouseCursorManager] by providing the channel.
  ///
  /// The `channel` must not be null.
  StandardMouseCursorManager(
    MethodChannel mouseCursorChannel,
  ) : assert(mouseCursorChannel != null) {
    _delegate = _createDelegate(mouseCursorChannel);
    assert(_delegate != null);
  }

  @override
  MouseCursorPlatformDelegate get delegate => _delegate;
  MouseCursorPlatformDelegate _delegate;

  MouseCursorPlatformDelegate _createDelegate(MethodChannel channel) {
    if (Platform.isLinux) {
      return MouseCursorGLFWDelegate(channel);
    } else if (Platform.isAndroid) {
      return MouseCursorAndroidDelegate(channel);
    } else {
      return const MouseCursorUnsupportedDelegate();
    }
  }
}

/// TODOC
@immutable
class SystemMouseCursor extends MouseCursor {
  /// TODOC
  const SystemMouseCursor(this.shape, this.description);

  /// TODOC
  final SystemCursorShape shape;

  /// TODOC
  final String description;

  @override
  Future<void> activate(ActivateMouseCursorDetails details) {
    return details.delegate.activateSystemCursor(details, shape);
  }

  @override
  String describeCursor() {
    return description;
  }
}

/// TODOC
class SystemMouseCursors {
  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A layer with this value will absorb the search for mouse cursor
  /// configuration, but the pointer's cursor will not be changed when it enters
  /// or is hovering this layer. This value is typically used on a platform view
  /// or other layers that manages the cursor by itself.
  static const MouseCursor releaseControl = NoopMouseCursor();

  /// Displays no cursor at the pointer.
  static const MouseCursor none = SystemMouseCursor(SystemCursorShape.none, 'none');

  /// The platform-dependent basic cursor. Typically the shape of an arrow.
  static const MouseCursor basic = SystemMouseCursor(SystemCursorShape.basic, 'basic');

  /// A cursor that indicates links or something that needs to be emphasized
  /// to be clickable. Typically the shape of a pointing hand.
  static const MouseCursor click = SystemMouseCursor(SystemCursorShape.click, 'click');

  /// A cursor that indicates a selectable text. Typically the shape of an
  /// I-beam.
  static const MouseCursor text = SystemMouseCursor(SystemCursorShape.text, 'text');

  /// A cursor that indicates an unpermitted action. Typically the shape of a
  /// circle with a diagnal line.
  static const MouseCursor forbidden = SystemMouseCursor(SystemCursorShape.forbidden, 'forbidden');

  /// A cursor that indicates something that can be dragged. Typically the shape
  /// of an open hand.
  static const MouseCursor grab = SystemMouseCursor(SystemCursorShape.grab, 'grab');

  /// A cursor that indicates something that is being dragged. Typically the
  /// shape of a closed hand.
  static const MouseCursor grabbing = SystemMouseCursor(SystemCursorShape.grabbing, 'grabbing');
}
