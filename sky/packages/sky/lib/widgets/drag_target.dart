// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:sky/base/hit_test.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/sky_binding.dart';
import 'package:sky/widgets/basic.dart';
import 'package:sky/widgets/framework.dart';

typedef bool DragTargetWillAccept<T>(T data);
typedef void DragTargetAccept<T>(T data);
typedef Widget DragTargetBuilder<T>(List<T> candidateData, List<dynamic> rejectedData);

class DragTarget<T> extends StatefulComponent {
  DragTarget({
    Key key,
    this.builder,
    this.onWillAccept,
    this.onAccept
  }) : super(key: key);

  DragTargetBuilder<T> builder;
  DragTargetWillAccept<T> onWillAccept;
  DragTargetAccept<T> onAccept;

  final List<T> _candidateData = new List<T>();
  final List<dynamic> _rejectedData = new List<dynamic>();

  void syncConstructorArguments(DragTarget source) {
    builder = source.builder;
    onWillAccept = source.onWillAccept;
    onAccept = source.onAccept;
  }

  bool didEnter(dynamic data) {
    assert(!_candidateData.contains(data));
    assert(!_rejectedData.contains(data));
    if (data is T && (onWillAccept == null || onWillAccept(data))) {
      setState(() {
        _candidateData.add(data);
      });
      return true;
    }
    _rejectedData.add(data);
    return false;
  }

  void didLeave(dynamic data) {
    assert(_candidateData.contains(data) || _rejectedData.contains(data));
    setState(() {
      _candidateData.remove(data);
      _rejectedData.remove(data);
    });
  }

  void didDrop(dynamic data) {
    assert(_candidateData.contains(data));
    setState(() {
      _candidateData.remove(data);
    });
    if (onAccept != null)
      onAccept(data);
  }

  Widget build() {
    return builder(new UnmodifiableListView<T>(_candidateData),
                   new UnmodifiableListView<dynamic>(_rejectedData));
  }
}

class DragController {
  DragController(this.data);

  final dynamic data;

  DragTarget _activeTarget;
  bool _activeTargetWillAcceptDrop = false;

  DragTarget _getDragTarget(List<HitTestEntry> path) {
    for (HitTestEntry entry in path.reversed) {
      if (entry.target is! RenderObject)
        continue;
      for (Widget widget in RenderObjectWrapper.getWidgetsForRenderObject(entry.target)) {
        if (widget is DragTarget)
          return widget;
      }
    }
    return null;
  }

  void update(Point globalPosition) {
    HitTestResult result = SkyBinding.instance.hitTest(globalPosition);
    DragTarget target = _getDragTarget(result.path);
    if (target == _activeTarget)
      return;
    if (_activeTarget != null)
      _activeTarget.didLeave(data);
    _activeTarget = target;
    _activeTargetWillAcceptDrop = _activeTarget != null && _activeTarget.didEnter(data);
  }

  void cancel() {
    if (_activeTarget != null)
      _activeTarget.didLeave(data);
    _activeTarget = null;
    _activeTargetWillAcceptDrop = false;
  }

  void drop() {
    if (_activeTarget == null)
      return;
    if (_activeTargetWillAcceptDrop)
      _activeTarget.didDrop(data);
    else
      _activeTarget.didLeave(data);
    _activeTarget = null;
    _activeTargetWillAcceptDrop = false;
  }
}
