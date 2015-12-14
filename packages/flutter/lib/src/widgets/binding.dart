// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'framework.dart';

class BindingObserver {
  bool didPopRoute() => false;
  void didChangeSize(Size size) { }
  void didChangeLocale(ui.Locale locale) { }
}

/// A concrete binding for applications based on the Widgets framework.
/// This is the glue that binds the framework to the Flutter engine.
class WidgetFlutterBinding extends BindingBase with Scheduler, Gesturer, Renderer {

  WidgetFlutterBinding._();

  /// Creates and initializes the WidgetFlutterBinding. This constructor is
  /// idempotent; calling it a second time will just return the
  /// previously-created instance.
  static WidgetFlutterBinding ensureInitialized() {
    if (_instance == null)
      new WidgetFlutterBinding._();
    return _instance;
  }

  initInstances() {
    super.initInstances();
    _instance = this;
    BuildableElement.scheduleBuildFor = scheduleBuildFor;
    ui.window.onLocaleChanged = handleLocaleChanged;
    ui.window.onPopRoute = handlePopRoute;
  }

  /// The one static instance of this class.
  ///
  /// Only valid after the WidgetFlutterBinding constructor) has been called.
  /// Only one binding class can be instantiated per process. If another
  /// BindingBase implementation has been instantiated before this one (e.g.
  /// bindings from other frameworks based on the Flutter "rendering" library),
  /// then WidgetFlutterBinding.instance will not be valid (and will throw in
  /// checked mode).
  static WidgetFlutterBinding _instance;
  static WidgetFlutterBinding get instance => _instance;

  final List<BindingObserver> _observers = new List<BindingObserver>();

  void addObserver(BindingObserver observer) => _observers.add(observer);
  bool removeObserver(BindingObserver observer) => _observers.remove(observer);

  void handleMetricsChanged() {
    super.handleMetricsChanged();
    for (BindingObserver observer in _observers)
      observer.didChangeSize(ui.window.size);
  }

  void handleLocaleChanged() {
    dispatchLocaleChanged(ui.window.locale);
  }

  void dispatchLocaleChanged(ui.Locale locale) {
    for (BindingObserver observer in _observers)
      observer.didChangeLocale(locale);
  }

  void handlePopRoute() {
    for (BindingObserver observer in _observers) {
      if (observer.didPopRoute())
        break;
    }
  }

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
      ensureVisualUpdate();
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
      debugShortDescription: '[root]',
      child: app
    ).attachToRenderTree(_renderViewElement);
    beginFrame();
  }
}

/// Inflate the given widget and attach it to the screen.
void runApp(Widget app) {
  WidgetFlutterBinding.ensureInitialized()._runApp(app);
}

/// Print a string representation of the currently running app.
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
  RenderObjectToWidgetAdapter({
    this.child,
    RenderObjectWithChildMixin<T> container,
    this.debugShortDescription
  }) : container = container, super(key: new GlobalObjectKey(container));

  final Widget child;
  final RenderObjectWithChildMixin<T> container;
  final String debugShortDescription;

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

  String toStringShort() => debugShortDescription ?? super.toStringShort();
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

  static const _rootChildSlot = const Object();

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(Element parent, dynamic newSlot) {
    assert(parent == null);
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, _rootChildSlot);
  }

  void update(RenderObjectToWidgetAdapter<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, _rootChildSlot);
  }

  RenderObjectWithChildMixin<T> get renderObject => super.renderObject;

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(slot == _rootChildSlot);
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
