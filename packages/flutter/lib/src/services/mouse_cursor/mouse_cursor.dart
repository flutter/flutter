// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'android.dart';
import 'common.dart';
import 'glfw.dart';
import 'macos.dart';

export 'common.dart' show
  MouseCursor,
  MouseCursorPlatformDelegate,
  SystemMouseCursorShape,
  MouseCursorActivateDetails;

// A mouse cursor based on resources provided by the platform.
//
// See also:
//
//  * [SystemMouseCursors], which lists all system mouse cursors.
@immutable
class _SystemMouseCursor extends MouseCursor {
  const _SystemMouseCursor(this.shape, this.description)
    : assert(shape != null), assert(description != null);

  final SystemMouseCursorShape shape;

  final String description;

  @override
  Future<bool> activate(MouseCursorActivateDetails details) {
    return details.platformDelegate.activateSystemCursor(
      MouseCursorPlatformActivateSystemCursorDetails(
        device: details.device,
        shape: shape,
      ),
    );
  }

  @override
  String describeCursor() {
    return description;
  }
}

// A [_SystemMouseCursor] that guarantees to be implemented.
@immutable
class _EnsuredImplementedSystemMouseCursor extends _SystemMouseCursor {
  const _EnsuredImplementedSystemMouseCursor(
    SystemMouseCursorShape shape,
    String description,
  ) : super(shape, description);

  @override
  Future<bool> activate(MouseCursorActivateDetails details) async {
    final bool implemented = await super.activate(details);
    assert(implemented);
    return implemented;
  }
}

/// A collection of system [MouseCursor]s.
///
/// This is a superset of system cursors from all platforms that Flutter
/// supports. If a cursor is unimplemented by a platform, it will fallback to
/// another cursor or the basic cursor.
class SystemMouseCursors {
  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A layer with this value will absorb the search for mouse cursor
  /// configuration, but the pointer's cursor will not be changed when it enters
  /// or is hovering this layer. This value is typically used on a platform view
  /// or other layers that manages the cursor by itself.
  static const MouseCursor releaseControl = NoopMouseCursor();

  /// Displays no cursor at the pointer.
  static const MouseCursor none = _SystemMouseCursor(SystemMouseCursorShape.none, 'none');

  /// The platform-dependent basic cursor. Typically the shape of an arrow.
  ///
  /// This cursor is the fallback of unimplemented cursors, and guarantees to
  /// be implemented by all platforms.
  static const MouseCursor basic = _EnsuredImplementedSystemMouseCursor(
    SystemMouseCursorShape.basic, 'basic');

  /// A cursor that indicates links or something that needs to be emphasized
  /// to be clickable. Typically the shape of a pointing hand.
  static const MouseCursor click = _SystemMouseCursor(SystemMouseCursorShape.click, 'click');

  /// A cursor that indicates a selectable text. Typically the shape of an
  /// I-beam.
  static const MouseCursor text = _SystemMouseCursor(SystemMouseCursorShape.text, 'text');

  /// A cursor that indicates an unpermitted action. Typically the shape of a
  /// circle with a diagnal line.
  static const MouseCursor forbidden = _SystemMouseCursor(SystemMouseCursorShape.forbidden, 'forbidden');

  /// A cursor that indicates something that can be dragged. Typically the shape
  /// of an open hand.
  static const MouseCursor grab = _SystemMouseCursor(SystemMouseCursorShape.grab, 'grab');

  /// A cursor that indicates something that is being dragged. Typically the
  /// shape of a closed hand.
  static const MouseCursor grabbing = _SystemMouseCursor(SystemMouseCursorShape.grabbing, 'grabbing');
}

/// The base class of a manager that maintains states related to mouse cursor
/// and provides a simple interface to operate [MouseCursor]s.
///
/// See also:
///
///  * [StandardMouseCursorManager], which implements the platform-specific
///    code based on the platform that this program is running on.
///  * [MouseTracker], which uses this class.
abstract class MouseCursorManager {
  /// The delegate of the platform that this manager operates.
  ///
  /// It is provided to [MouseCursor] to perform platform operations.
  MouseCursorPlatformDelegate get platformDelegate;

  /// Set the cursor of pointer `device` to `cursor`.
  ///
  /// This method handles states or fallbacks.
  ///
  /// This method resolves if the operation is successful, or throws errors if
  /// any occur.
  Future<void> setDeviceCursor(int device, MouseCursor cursor) async {
    final MouseCursorActivateDetails details = MouseCursorActivateDetails(
      device: device,
      platformDelegate: platformDelegate,
    );
    final bool implemented = await cursor.activate(details);
    if (!implemented) {
      final bool basicImplemented = await SystemMouseCursors.basic.activate(details);
      assert(basicImplemented);
    }
  }
}

/// The [MouseCursorManager] that implements the platform-specific code based on
/// the platform that this program is running on.
///
/// See also:
///
///  * [MouseTracker], which owns an instance of this class.
class StandardMouseCursorManager extends MouseCursorManager {
  /// Create a [MouseCursorManager] by providing the channel.
  ///
  /// The `mouseCursorChannel` is used to create platform delegates, and must
  /// not be null.
  StandardMouseCursorManager(
    MethodChannel mouseCursorChannel,
  ) : assert(mouseCursorChannel != null) {
    _platformDelegate = _createDelegate(mouseCursorChannel);
    assert(_platformDelegate != null);
  }

  @override
  MouseCursorPlatformDelegate get platformDelegate => _platformDelegate;
  MouseCursorPlatformDelegate _platformDelegate;

  MouseCursorPlatformDelegate _createDelegate(MethodChannel channel) {
    if (Platform.isLinux) {
      return MouseCursorGLFWDelegate(mouseCursorChannel: channel);
    } else if (Platform.isAndroid) {
      return MouseCursorAndroidDelegate(mouseCursorChannel: channel);
    } else if (Platform.isMacOS) {
      return MouseCursorMacOSDelegate(mouseCursorChannel: channel);
    } else {
      return const MouseCursorUnsupportedPlatformDelegate();
    }
  }
}
