// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'framework.dart';

class WidgetFlutterBinding extends FlutterBinding {

  WidgetFlutterBinding() {
    BuildableElement.scheduleBuildFor = scheduleBuildFor;
  }

  /// Ensures that there is a FlutterBinding object instantiated.
  static void ensureInitialized() {
    if (FlutterBinding.instance == null)
      new WidgetFlutterBinding();
    assert(FlutterBinding.instance is WidgetFlutterBinding);
  }

  static WidgetFlutterBinding get instance => FlutterBinding.instance;

  void beginFrame() {
    buildDirtyElements();
    super.beginFrame();
    Element.finalizeTree();
  }

  List<BuildableElement> _dirtyElements = <BuildableElement>[];

  /// Adds an element to the dirty elements list so that it will be rebuilt
  /// when buildDirtyElements is called.
  void scheduleBuildFor(BuildableElement element) {
    assert(!_dirtyElements.contains(element));
    assert(element.dirty);
    if (_dirtyElements.isEmpty)
      scheduler.ensureVisualUpdate();
    _dirtyElements.add(element);
  }

  /// Builds all the elements that were marked as dirty using schedule(), in depth order.
  /// If elements are marked as dirty while this runs, they must be deeper than the algorithm
  /// has yet reached.
  /// This is called by beginFrame().
  void buildDirtyElements() {
    if (_dirtyElements.isEmpty)
      return;
    Timeline.startSync('Build');
    BuildableElement.lockState(() {
      _dirtyElements.sort((BuildableElement a, BuildableElement b) => a.depth - b.depth);
      int dirtyCount = _dirtyElements.length;
      int index = 0;
      while (index < dirtyCount) {
        _dirtyElements[index].rebuild();
        index += 1;
        if (dirtyCount < _dirtyElements.length) {
          _dirtyElements.sort((BuildableElement a, BuildableElement b) => a.depth - b.depth);
          dirtyCount = _dirtyElements.length;
        }
      }
      assert(!_dirtyElements.any((BuildableElement element) => element.dirty));
      _dirtyElements.clear();
    }, building: true);
    assert(_dirtyElements.isEmpty);
    Timeline.finishSync();
  }

  /// The [Element] that is at the root of the hierarchy (and which wraps the
  /// [RenderView] object at the root of the rendering hierarchy).
  Element get renderViewElement => _renderViewElement;
  Element _renderViewElement;
  void _runApp(Widget app) {
    _renderViewElement = new RenderObjectToWidgetAdapter<RenderBox>(
      container: renderView,
      child: app
    ).attachToRenderTree(_renderViewElement);
    beginFrame();
  }
}

void runApp(Widget app) {
  WidgetFlutterBinding.ensureInitialized();
  WidgetFlutterBinding.instance._runApp(app);
}

void debugDumpApp() {
  assert(WidgetFlutterBinding.instance != null);
  assert(WidgetFlutterBinding.instance.renderViewElement != null);
  String mode = 'RELEASE MODE';
  assert(() { mode = 'CHECKED MODE'; return true; });
  debugPrint('${WidgetFlutterBinding.instance.runtimeType} - $mode');
  debugPrint(WidgetFlutterBinding.instance.renderViewElement.toStringDeep());
}

/// This class provides a bridge from a RenderObject to an Element tree. The
/// given container is the RenderObject that the Element tree should be inserted
/// into. It must be a RenderObject that implements the
/// RenderObjectWithChildMixin protocol. The type argument T is the kind of
/// RenderObject that the container expects as its child.
class RenderObjectToWidgetAdapter<T extends RenderObject> extends RenderObjectWidget {
  RenderObjectToWidgetAdapter({ this.child, RenderObjectWithChildMixin<T> container })
    : container = container, super(key: new GlobalObjectKey(container));

  final Widget child;
  final RenderObjectWithChildMixin<T> container;

  RenderObjectToWidgetElement<T> createElement() => new RenderObjectToWidgetElement<T>(this);

  RenderObjectWithChildMixin<T> createRenderObject() => container;

  void updateRenderObject(RenderObject renderObject, RenderObjectWidget oldWidget) { }

  RenderObjectToWidgetElement<T> attachToRenderTree([RenderObjectToWidgetElement<T> element]) {
    BuildableElement.lockState(() {
      if (element == null) {
        element = createElement();
        element.mount(null, null);
      } else {
        element.update(this);
      }
    }, building: true);
    return element;
  }
}

/// This element class is the instantiation of a [RenderObjectToWidgetAdapter].
/// It can only be used as the root of an Element tree (it cannot be mounted
/// into another Element, it's parent must be null).
///
/// In typical usage, it will be instantiated for a RenderObjectToWidgetAdapter
/// whose container is the RenderView that connects to the Flutter engine. In
/// this usage, it is normally instantiated by the bootstrapping logic in the
/// WidgetFlutterBinding singleton created by runApp().
class RenderObjectToWidgetElement<T extends RenderObject> extends RenderObjectElement {
  RenderObjectToWidgetElement(RenderObjectToWidgetAdapter<T> widget) : super(widget);

  Element _child;

  static const _rootChild = const Object();

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(Element parent, dynamic newSlot) {
    assert(parent == null);
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, _rootChild);
  }

  void update(RenderObjectToWidgetAdapter<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, _rootChild);
  }

  RenderObjectWithChildMixin<T> get renderObject => super.renderObject;

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(slot == _rootChild);
    renderObject.child = child;
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(renderObject.child == child);
    renderObject.child = null;
  }
}
