// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;
import 'dart:ui' show AppLifecycleState, Locale;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'framework.dart';

export 'dart:ui' show AppLifecycleState, Locale;

class BindingObserver {
  bool didPopRoute() => false;
  void didChangeMetrics() { }
  void didChangeLocale(Locale locale) { }
  void didChangeAppLifecycleState(AppLifecycleState state) { }
}

/// A concrete binding for applications based on the Widgets framework.
/// This is the glue that binds the framework to the Flutter engine.
class WidgetFlutterBinding extends BindingBase with Scheduler, Gesturer, Services, Renderer {

  WidgetFlutterBinding() {
    buildOwner.onBuildScheduled = ensureVisualUpdate;
  }

  /// Creates and initializes the WidgetFlutterBinding. This constructor is
  /// idempotent; calling it a second time will just return the
  /// previously-created instance.
  static WidgetFlutterBinding ensureInitialized() {
    if (_instance == null)
      new WidgetFlutterBinding();
    return _instance;
  }

  final BuildOwner _buildOwner = new BuildOwner();
  /// The [BuildOwner] in charge of executing the build pipeline for the
  /// widget tree rooted at this binding.
  BuildOwner get buildOwner => _buildOwner;

  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    ui.window.onLocaleChanged = handleLocaleChanged;
    ui.window.onPopRoute = handlePopRoute;
    ui.window.onAppLifecycleStateChanged = handleAppLifecycleStateChanged;
  }

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    registerBoolServiceExtension(
      name: 'showPerformanceOverlay',
      getter: () => WidgetsApp.showPerformanceOverlayOverride,
      setter: (bool value) {
        if (WidgetsApp.showPerformanceOverlayOverride == value)
          return;
        WidgetsApp.showPerformanceOverlayOverride = value;
        buildOwner.reassemble(renderViewElement);
      }
    );
  }

  /// The one static instance of this class.
  ///
  /// Only valid after the WidgetFlutterBinding constructor) has been called.
  /// Only one binding class can be instantiated per process. If another
  /// BindingBase implementation has been instantiated before this one (e.g.
  /// bindings from other frameworks based on the Flutter "rendering" library),
  /// then WidgetFlutterBinding.instance will not be valid (and will throw in
  /// checked mode).
  static WidgetFlutterBinding get instance => _instance;
  static WidgetFlutterBinding _instance;

  final List<BindingObserver> _observers = new List<BindingObserver>();

  void addObserver(BindingObserver observer) => _observers.add(observer);
  bool removeObserver(BindingObserver observer) => _observers.remove(observer);

  @override
  void handleMetricsChanged() {
    super.handleMetricsChanged();
    for (BindingObserver observer in _observers)
      observer.didChangeMetrics();
  }

  void handleLocaleChanged() {
    dispatchLocaleChanged(ui.window.locale);
  }

  void dispatchLocaleChanged(Locale locale) {
    for (BindingObserver observer in _observers)
      observer.didChangeLocale(locale);
  }

  void handlePopRoute() {
    for (BindingObserver observer in _observers) {
      if (observer.didPopRoute())
        return;
    }
    activity.finishCurrentActivity();
  }

  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    for (BindingObserver observer in _observers)
      observer.didChangeAppLifecycleState(state);
  }

  @override
  void beginFrame() {
    buildOwner.buildDirtyElements();
    super.beginFrame();
    buildOwner.finalizeTree();
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
    ).attachToRenderTree(buildOwner, renderViewElement);
    beginFrame();
  }

  @override
  void reassembleApplication() {
    buildOwner.reassemble(renderViewElement);
    super.reassembleApplication();
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

  /// The widget below this widget in the tree.
  final Widget child;

  final RenderObjectWithChildMixin<T> container;

  final String debugShortDescription;

  @override
  RenderObjectToWidgetElement<T> createElement() => new RenderObjectToWidgetElement<T>(this);

  @override
  RenderObjectWithChildMixin<T> createRenderObject(BuildContext context) => container;

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) { }

  RenderObjectToWidgetElement<T> attachToRenderTree(BuildOwner owner, [RenderObjectToWidgetElement<T> element]) {
    owner.lockState(() {
      if (element == null) {
        element = createElement();
        element.assignOwner(owner);
        element.mount(null, null);
      } else {
        element.update(this);
      }
    }, building: true, context: 'while attaching root widget to rendering tree');
    return element;
  }

  @override
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
class RenderObjectToWidgetElement<T extends RenderObject> extends RootRenderObjectElement {
  RenderObjectToWidgetElement(RenderObjectToWidgetAdapter<T> widget) : super(widget);

  @override
  RenderObjectToWidgetAdapter<T> get widget => super.widget;

  Element _child;

  static const Object _rootChildSlot = const Object();

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    assert(parent == null);
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, _rootChildSlot);
  }

  @override
  void update(RenderObjectToWidgetAdapter<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, _rootChildSlot);
  }

  @override
  RenderObjectWithChildMixin<T> get renderObject => super.renderObject;

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(slot == _rootChildSlot);
    renderObject.child = child;
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(renderObject.child == child);
    renderObject.child = null;
  }
}
