// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';

typedef SliverCoordinatorCallback = void Function(ScrollNotification notification, SliverCoordinatorData data);

class SliverLayoutInfo {
  const SliverLayoutInfo({
    required this.constraints,
    required this.geometry
  });

  final SliverConstraints constraints;
  final SliverGeometry geometry;
}

class SliverCoordinatorData {
  final Map<Object, SliverLayoutInfo> _idToInfo = <Object, SliverLayoutInfo>{};

  void put<T extends SliverLayoutInfo>(Object id, T info) {
    _idToInfo[id] = info;
  }

  T? get<T extends SliverLayoutInfo>(Object id) {
    return _idToInfo[id] as T?;
  }

  void clear() => _idToInfo.clear();
}

class _SliverCoordinatorScope extends InheritedWidget {
  const _SliverCoordinatorScope({ required this.data, required super.child });

  final SliverCoordinatorData data;

  @override
  bool updateShouldNotify(_SliverCoordinatorScope oldWidget) => false;
}

/// {@tool dartpad}
/// This sample ...
///
/// ** See code in examples/api/lib/widgets/sliver/sliver_coordinator.0.dart **
/// {@end-tool}
class SliverCoordinator extends StatefulWidget {
  const SliverCoordinator({ super.key, required this.callback, required this.child });

  final Widget child;
  final SliverCoordinatorCallback callback;

  @override
  State<SliverCoordinator> createState() => _SliverCoordinatorState();

  static SliverCoordinatorData of(BuildContext context) {
    final _SliverCoordinatorScope? scope = context.dependOnInheritedWidgetOfExactType<_SliverCoordinatorScope>();
    return scope!.data;
  }
}

class _SliverCoordinatorState extends State<SliverCoordinator> {
  SliverCoordinatorData data = SliverCoordinatorData();

  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      data.clear();
    }
    // The callback runs after the descendant CustomScrollView's viewport
    // has been laid out and the SliverLayoutInfo object has been updated.
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

class CoordinatedSliver extends SingleChildRenderObjectWidget {
  const CoordinatedSliver({
    super.key,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderCoordinatedSliver(
      id: this,
      data: SliverCoordinator.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCoordinatedSliver renderObject) {
    renderObject.id = this;
    renderObject.data = SliverCoordinator.of(context);
  }

  SliverLayoutInfo? getLayoutInfo(SliverCoordinatorData data) {
    return data.get<SliverLayoutInfo>(this);
  }
}

class RenderCoordinatedSliver extends RenderProxySliver {
  RenderCoordinatedSliver({
    required this.id,
    required this.data,
    RenderSliver? child,
  }) : super(child);

  Object id;
  SliverCoordinatorData data;

  @override
  void performLayout() {
    super.performLayout();
    data.put<SliverLayoutInfo>(id, SliverLayoutInfo(
      constraints: constraints,
      geometry: geometry!,
    ));
  }
}
