// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'drag_details.dart';

/// Called when the user taps with a semantics device.
typedef SemanticsTapCallback = void Function();
/// Called when the user presses for a long period of time with a semantics
/// device.
typedef SemanticsLongPressCallback = void Function();
/// Called when the user drags with a semantics device.
typedef SemanticsDragUpdateCallback = void Function(DragUpdateDetails details);

/// Describes the callbacks to handle each kind of semantics events respectively.
/// All properties are optional.
///
/// See also:
///
///  * [GestureRecognizer.semanticsHandlers], a method that returns
///    an instance of this class.
class SemanticsHandlerConfiguration {
  /// Initialize the semantics handler configuration by declaring the handlers
  /// for each kind of semantics events.
  SemanticsHandlerConfiguration({
    this.onTap,
    this.onLongPress,
    this.onHorizontalDragUpdate,
    this.onVerticalDragUpdate,
  });

  /// Called when the user taps with a semantics device.
  ///
  /// See also:
  ///
  ///  * [RenderSemanticsGestureHandler.onTap], which calls this handler with
  ///    the help of [RawGestureRecognizer].
  final SemanticsTapCallback onTap;

  /// Called when the user presses for a long period of time with a semantics
  /// device.
  ///
  /// See also:
  ///
  ///  * [RenderSemanticsGestureHandler.onLongPress], which calls this handler
  ///    with the help of [RawGestureRecognizer].
  final SemanticsLongPressCallback onLongPress;

  /// Called when the user scrolls to the left or to the right with a semantics
  /// device.
  ///
  /// See also:
  ///
  ///  * [RenderSemanticsGestureHandler.onHorizontalDragUpdate], which calls
  ///    this handler with the help of [RawGestureRecognizer].
  final SemanticsDragUpdateCallback onHorizontalDragUpdate;

  /// Called when the user scrolls up or down with a semantics device.
  ///
  /// See also:
  ///
  ///  * [RenderSemanticsGestureHandler.onVerticalDragUpdate], which calls
  ///    this handler with the help of [RawGestureRecognizer].
  final SemanticsDragUpdateCallback onVerticalDragUpdate;
}
