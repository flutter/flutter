// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'drag_avatar.dart';
import 'drag_target_state.dart';

/// Signature for determining whether the given data will be accepted by a [DragTarget].
///
/// Used by [DragTarget.onWillAccept].
typedef DragTargetWillAccept<T> = bool Function(T? data);

/// Signature for causing a [DragTarget] to accept the given data.
///
/// Used by [DragTarget.onAccept].
typedef DragTargetAccept<T> = void Function(T data);

/// Signature for determining information about the acceptance by a [DragTarget].
///
/// Used by [DragTarget.onAcceptWithDetails].
typedef DragTargetAcceptWithDetails<T> = void Function(DragTargetDetails<T> details);

/// Signature for building children of a [DragTarget].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [DragTarget] and that has passed [DragTarget.onWillAccept]. The
/// `rejectedData` argument contains the list of drag data that is hovering over
/// this [DragTarget] and that will not be accepted by the [DragTarget].
///
/// Used by [DragTarget.builder].
typedef DragTargetBuilder<T> = Widget Function(BuildContext context, List<T?> candidateData, List<dynamic> rejectedData);

/// Signature for when a [Draggable] leaves a [DragTarget].
///
/// Used by [DragTarget.onLeave].
typedef DragTargetLeave<T> = void Function(T? data);

/// Signature for when a [Draggable] moves within a [DragTarget].
///
/// Used by [DragTarget.onMove].
typedef DragTargetMove<T> = void Function(DragTargetDetails<T> details);

/// Represents the details when a pointer event occurred on the [DragTarget].
class DragTargetDetails<T> {
  /// Creates details for a [DragTarget] callback.
  ///
  /// The [offset] must not be null.
  DragTargetDetails({required this.data, required this.offset}) : assert(offset != null);

  /// The data that was dropped onto this [DragTarget].
  final T data;

  /// The global position when the specific pointer event occurred on
  /// the draggable.
  final Offset offset;
}

/// A widget that receives data when a [Draggable] widget is dropped.
///
/// When a draggable is dragged on top of a drag target, the drag target is
/// asked whether it will accept the data the draggable is carrying. If the user
/// does drop the draggable on top of the drag target (and the drag target has
/// indicated that it will accept the draggable's data), then the drag target is
/// asked to accept the draggable's data.
///
/// See also:
///
///  * [Draggable]
///  * [LongPressDraggable]
class DragTarget<T extends Object> extends StatefulWidget {
  /// Creates a widget that receives drags.
  ///
  /// The [builder] argument must not be null.
  const DragTarget({
    Key? key,
    required this.builder,
    this.onWillAccept,
    this.onAccept,
    this.onAcceptWithDetails,
    this.onLeave,
    this.onMove,
    this.hitTestBehavior = HitTestBehavior.translucent,
  }) : super(key: key);

  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final DragTargetBuilder<T> builder;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  ///
  /// Called when a piece of data enters the target. This will be followed by
  /// either [onAccept] and [onAcceptWithDetails], if the data is dropped, or
  /// [onLeave], if the drag leaves the target.
  final DragTargetWillAccept<T>? onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAcceptWithDetails], but only includes the data.
  final DragTargetAccept<T>? onAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  ///
  /// Equivalent to [onAccept], but with information, including the data, in a
  /// [DragTargetDetails].
  final DragTargetAcceptWithDetails<T>? onAcceptWithDetails;

  /// Called when a given piece of data being dragged over this target leaves
  /// the target.
  final DragTargetLeave<T>? onLeave;

  /// Called when a [Draggable] moves within this [DragTarget].
  ///
  /// Note that this includes entering and leaving the target.
  final DragTargetMove<T>? onMove;

  /// How to behave during hit testing.
  ///
  /// Defaults to [HitTestBehavior.translucent].
  final HitTestBehavior hitTestBehavior;

  @override
  DragTargetState<T> createState() => DragTargetState<T>();
}

List<T?> _mapAvatarsToData<T extends Object>(List<DragAvatar<Object>> avatars) {
  return avatars.map<T?>((DragAvatar<Object> avatar) => avatar.data as T?).toList();
}




