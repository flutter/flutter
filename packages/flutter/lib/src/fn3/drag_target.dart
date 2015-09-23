// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:sky/rendering.dart';
import 'package:sky/src/fn3/basic.dart';
import 'package:sky/src/fn3/binding.dart';
import 'package:sky/src/fn3/framework.dart';

typedef bool DragTargetWillAccept<T>(T data);
typedef void DragTargetAccept<T>(T data);
typedef Widget DragTargetBuilder<T>(BuildContext context, List<T> candidateData, List<dynamic> rejectedData);

class DragTarget<T> extends StatefulComponent {
  const DragTarget({
    Key key,
    this.builder,
    this.onWillAccept,
    this.onAccept
  }) : super(key: key);

  final DragTargetBuilder<T> builder;
  final DragTargetWillAccept<T> onWillAccept;
  final DragTargetAccept<T> onAccept;

  DragTargetState<T> createState() => new DragTargetState<T>(this);
}

class DragTargetState<T> extends ComponentState<DragTarget<T>> {
  DragTargetState(DragTarget<T> config) : super(config);

  final List<T> _candidateData = new List<T>();
  final List<dynamic> _rejectedData = new List<dynamic>();

  bool didEnter(dynamic data) {
    assert(!_candidateData.contains(data));
    assert(!_rejectedData.contains(data));
    if (data is T && (config.onWillAccept == null || config.onWillAccept(data))) {
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
    if (config.onAccept != null)
      config.onAccept(data);
  }

  Widget build(BuildContext context) {
    return new MetaData(
      metaData: this,
      child: config.builder(context,
                            new UnmodifiableListView<T>(_candidateData),
                            new UnmodifiableListView<dynamic>(_rejectedData))
    );
  }
}

class DragController {
  DragController(this.data);

  final dynamic data;

  DragTargetState _activeTarget;
  bool _activeTargetWillAcceptDrop = false;

  DragTargetState _getDragTarget(List<HitTestEntry> path) {
    // TODO(abarth): Why to we reverse the path here?
    for (HitTestEntry entry in path.reversed) {
      if (entry.target is RenderMetaData) {
        RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is DragTargetState)
          return renderMetaData.metaData;
      }
    }
    return null;
  }

  void update(Point globalPosition) {
    HitTestResult result = WidgetFlutterBinding.instance.hitTest(globalPosition);
    DragTargetState target = _getDragTarget(result.path);
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
