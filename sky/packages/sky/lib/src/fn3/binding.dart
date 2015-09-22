// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:sky' as sky;
import 'package:sky/animation.dart';
import 'package:sky/rendering.dart';
import 'package:sky/src/fn3/framework.dart';

class WidgetSkyBinding extends SkyBinding {

  WidgetSkyBinding({ RenderView renderViewOverride: null })
    : super(renderViewOverride: renderViewOverride) {
    BuildableElement.scheduleBuildFor = scheduleBuildFor;
  }

  /// Ensures that there is a SkyBinding object instantiated.
  static void initWidgetSkyBinding({ RenderView renderViewOverride: null }) {
    if (SkyBinding.instance == null)
      new WidgetSkyBinding(renderViewOverride: renderViewOverride);
    assert(SkyBinding.instance is WidgetSkyBinding);
  }

  static WidgetSkyBinding get instance => SkyBinding.instance;

  void handleEvent(sky.Event event, BindingHitTestEntry entry) {
    for (HitTestEntry entry in entry.result.path) {
      if (entry.target is! RenderObject)
        continue;
      for (Widget target in RenderObjectElement.getElementsForRenderObject(entry.target)) {
        // TODO(ianh): implement event handling
        // if (target is ListenerElement)
        //  target.handleEvent(event);
      }
    }
    super.handleEvent(event, entry);
  }

  void beginFrame(double timeStamp) {
    buildDirtyElements();
    super.beginFrame(timeStamp);
  }

  final List<BuildableElement> _dirtyElements = new List<BuildableElement>();

  int _debugBuildingAtDepth;

  /// Adds an element to the dirty elements list so that it will be rebuilt
  /// when buildDirtyElements is called.
  void scheduleBuildFor(BuildableElement element) {
    assert(_debugBuildingAtDepth == null || element.depth > _debugBuildingAtDepth);
    assert(!_dirtyElements.contains(element));
    assert(element.dirty);
    if (_dirtyElements.isEmpty)
      scheduler.ensureVisualUpdate();
    _dirtyElements.add(element);
  }

  void _absorbDirtyElements(List<BuildableElement> list) {
    assert(_debugBuildingAtDepth != null);
    assert(!_dirtyElements.any((element) => element.depth <= _debugBuildingAtDepth));
    _dirtyElements.sort((BuildableElement a, BuildableElement b) => a.depth - b.depth);
    list.addAll(_dirtyElements);
    _dirtyElements.clear();
  }

  /// Builds all the elements that were marked as dirty using schedule(), in depth order.
  /// If elements are marked as dirty while this runs, they must be deeper than the algorithm
  /// has yet reached.
  /// This is called by beginFrame().
  void buildDirtyElements() {
    assert(_debugBuildingAtDepth == null);
    if (_dirtyElements.isEmpty)
      return;
    assert(() { _debugBuildingAtDepth = 0; return true; });
    List<BuildableElement> sortedDirtyElements = new List<BuildableElement>();
    int index = 0;
    do {
      _absorbDirtyElements(sortedDirtyElements);
      for (; index < sortedDirtyElements.length; index += 1) {
        BuildableElement element = sortedDirtyElements[index];
        assert(() {
          if (element.depth > _debugBuildingAtDepth)
            _debugBuildingAtDepth = element.depth;
          return element.depth == _debugBuildingAtDepth;
        });
        element.rebuild();
      }
    } while (_dirtyElements.isNotEmpty);
    assert(() { _debugBuildingAtDepth = null; return true; });
  }
}
