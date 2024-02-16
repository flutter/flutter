// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';

/// Function signature for the [SliverCoordinator.callback], which is called each time
/// its [CustomScrollView] has been laid out.
///
/// The second parameter can be used to retrieve layout information when
/// [CoordinatedSliver.hasLayoutInfo] is true. See [CoordinatedSliver.getSliverConstraints]
/// and [CoordinatedSliver.getSliverGeometry].
typedef SliverCoordinatorCallback = void Function(ScrollNotification notification, SliverCoordinatorData data);

class _SliverLayoutInfo {
  const _SliverLayoutInfo({
    required this.constraints,
    required this.geometry
  });

  final SliverConstraints constraints;
  final SliverGeometry geometry;
}

/// Encapsulates a table of layout information for [CoordinatedSliver]s.
///
/// An instance of this class is passed to the [SliverCoordinator.callback].
/// To retreive data from this table use [CoordinatedSliver.hasLayoutInfo]
/// [CoordinatedSliver.getSliverConstraints], and [CoordinatedSliver.getSliverGeometry].
class SliverCoordinatorData {
  final Map<Object, _SliverLayoutInfo> _idToInfo = <Object, _SliverLayoutInfo>{};

  // Add an entry to the layout information table.
  void _put<T extends _SliverLayoutInfo>(Object id, T info) {
    _idToInfo[id] = info;
  }

  // Retreieve an entry from the layout information table.
  T? _get<T extends _SliverLayoutInfo>(Object id) {
    return _idToInfo[id] as T?;
  }

  // Clear the contents of the layout information table.
  @protected
  void _clear() => _idToInfo.clear();
}

class _SliverCoordinatorScope extends InheritedWidget {
  const _SliverCoordinatorScope({ required this.data, required super.child });

  final SliverCoordinatorData data;

  @override
  bool updateShouldNotify(_SliverCoordinatorScope oldWidget) => false;
}

/// Provides [ScrollNotification]s for its [CustomScrollView] descendant as well as
/// layout information for each [CoordinatedSliver] contained by the scroll view.
///
/// This widget is intended for triggering animations or auto-scrolls in reaction to
/// scroll notifications and the concomittant layout changes in the scroll view's
/// [CoordinatedSliver]s. It cannot be used to change sliver layouts. Typical use cases:
///
/// - When a drag gesture ends: auto-scrolling a widget that overlaps the top
/// or bottom of the viewport so that it's completely visible.
/// - When a sliver scrolls under a pinned header, change the header's
/// content or elevation with an animated transition.
/// - Show an indicator while a special sliver is visible or when its
/// visibility changes.
///
/// {@tool dartpad}
/// This example contains one [CoordinatedSliver] which is
/// auto-scrolled so that it's aligned with the top of the viewport
/// whenever a scroll-end gesture leaves it partially visible. The
/// auto-scroll is triggered by the [SliverCoordinator]'s
/// callback. The callback has access to the current scroll offset and
/// the current extent (height) of the [CoordinatedSliver].
///
/// ** See code in examples/api/lib/widgets/sliver/sliver_coordinator.0.dart **
/// {@end-tool}
class SliverCoordinator extends StatefulWidget {
  /// Create specialized scroll notification listener for a [CustomScrollView] descendant.
  ///
  /// The [callback] runs each time the scroll view is scrolled.
  const SliverCoordinator({ super.key, required this.callback, required this.child });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;


  /// Called each time the [CustomScrollView] below this widget scrolls.
  ///
  /// This callback runs after its descendants, including the scroll
  /// view, have been laid out.  The callback's
  /// [SliverCoordinatorData] parameter includes the
  /// [SliverConstraints] and [SliverGeometry] computed for each
  /// [CoordinatedSliver].
  final SliverCoordinatorCallback callback;

  @override
  State<SliverCoordinator> createState() => _SliverCoordinatorState();

  static SliverCoordinatorData _of(BuildContext context) {
    final _SliverCoordinatorScope? scope = context.dependOnInheritedWidgetOfExactType<_SliverCoordinatorScope>();
    return scope!.data;
  }
}

class _SliverCoordinatorState extends State<SliverCoordinator> {
  SliverCoordinatorData data = SliverCoordinatorData();

  bool handleScrollNotification(ScrollNotification notification) {
    // The table of CoordinatedSliver data will be repopulated after the
    // scroll view is laid out (see RenderCoordinatedSliver.performLayout)
    // and before the callback runs.
    if (notification is ScrollUpdateNotification) {
      data._clear();
    }
    // The callback runs after the descendant CustomScrollView's viewport
    // has been laid out and the _SliverLayoutInfo object has been updated.
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      widget.callback(notification, data);
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: handleScrollNotification,
      child: _SliverCoordinatorScope(
        data: data,
        child: widget.child,
      ),
    );
  }
}

/// Enables [SliverCoordinator.callback] methods to use sliver layout
/// information to trigger animations or auto-scrolling.
///
/// Coordinated slivers store their [SliverConstraints] and
/// [SliverGeometry] values after they've been laid out. These values
/// can be retrieved - after the entire [CustomScrollView] has been
/// laid out - in a [SliverCoordinator.callback] using [getSliverConstraints]
/// and [getSliverGeometry]. To do so, you must save a reference to the
/// sliver coordinator widget itself in an enclosing [StatefulWidget].
/// You can see as much in the example below.
///
/// {@tool dartpad}
/// This example contains one [CoordinatedSliver] which is
/// auto-scrolled so that it's aligned with the top of the viewport
/// whenever a scroll-end gesture leaves it partially visible. The
/// auto-scroll is triggered by the [SliverCoordinator]'s
/// callback. The callback has access to the current scroll offset and
/// the current extent (height) of the [CoordinatedSliver].
///
/// ** See code in examples/api/lib/widgets/sliver/sliver_coordinator.0.dart **
/// {@end-tool}
class CoordinatedSliver extends SingleChildRenderObjectWidget {
  /// Encapsulate a Sliver and save its layout information so that it can be
  /// retrieved from a [SliverCoordinator.callback] after its [CustomScrollView]
  /// has completed layout.
  const CoordinatedSliver({
    super.key,
    Widget? sliver,
  }) : super(child: sliver);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCoordinatedSliver(
      id: this,
      data: SliverCoordinator._of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCoordinatedSliver renderObject) {
    renderObject.id = this;
    renderObject.data = SliverCoordinator._of(context);
  }

  /// True if [getSliverConstraints] and [getSliverGeometry] are safe to call
  /// from  [SliverCoordinator.callback].
  ///
  /// False if this sliver wasn't laid out in the most recent [CustomScrollView]
  /// layout.
  bool hasLayoutInfo(SliverCoordinatorData data) {
    return data._get<_SliverLayoutInfo>(this) != null;
  }

  /// The [SliverConstraints] computed for this sliver in the most recent
  /// [CustomScrollView] layout.
  SliverConstraints getSliverConstraints(SliverCoordinatorData data) {
    assert(hasLayoutInfo(data));
    return data._get<_SliverLayoutInfo>(this)!.constraints;
  }

  /// The [SliverGeometry] computed for this sliver in the most recent
  /// [CustomScrollView] layout.
  SliverGeometry getSliverGeometry(SliverCoordinatorData data) {
    assert(hasLayoutInfo(data));
    return data._get<_SliverLayoutInfo>(this)!.geometry;
  }
}


/// A sliver that saves its [SliverConstraints] and [SliverGeometry]
/// layout information in [data], using [id] as a key, each time it's laid out.
class RenderCoordinatedSliver extends RenderProxySliver {
  /// Creates a render object that that saves its [SliverConstraints] and [SliverGeometry]
  /// values in a [SliverCoordinatorData] table each time it's laid out.
  RenderCoordinatedSliver({
    required this.id,
    required this.data,
    RenderSliver? child,
  }) : super(child);

  /// The [SliverCoordinatorData] table lookup key for this sliver's layout
  /// information.
  ///
  /// Currently the [CoordinatedSliver] itself is used as its lookup key.
  Object id;

  /// The [SliverCoordinatorData] table where this sliver's layout information
  /// will be stored.
  SliverCoordinatorData data;

  @override
  void performLayout() {
    super.performLayout();
    data._put<_SliverLayoutInfo>(id, _SliverLayoutInfo(
      constraints: constraints,
      geometry: geometry!,
    ));
  }
}
