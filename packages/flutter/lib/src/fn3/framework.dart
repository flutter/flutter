// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/rendering.dart';

abstract class Key {
}

abstract class Widget {
  Widget(this.key);
  final Key key;

  Element createElement();
}

typedef Widget WidgetBuilder();

abstract class RenderObjectWidget extends Widget {
  RenderObjectWidget({ Key key }) : super(key);

  Element createElement() => new RenderObjectElement(this);

  RenderObject createRenderObject();
  void updateRenderObject(RenderObject renderObject);
}

abstract class OneChildRenderObjectWidget extends RenderObjectWidget {
  OneChildRenderObjectWidget({ Key key, Widget this.child }) : super(key: key);

  final Widget child;

  Element createElement() => new OneChildRenderObjectElement(this);
}

abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  MultiChildRenderObjectWidget({ Key key, List<Widget> this.children })
    : super(key: key);

  final List<Widget> children;

  Element createElement() => new MultiChildRenderObjectElement(this);
}

abstract class Component extends Widget {
  Component({ Key key }) : super(key);
  Element createElement() => new ComponentElement(this);

  Widget build();
}

abstract class ComponentState<T extends ComponentConfiguration> {
  ComponentStateElement _holder;

  void setState(void fn()) {
    fn();
    _holder.scheduleBuild();
  }

  T get config => _config;
  T _config;

  /// Override this setter to update additional state when the config changes.
  void set config(T config) {
    _config = config;
  }

  /// Called when this object is removed from the tree
  void didUnmount() { }

  Widget build();
}

abstract class ComponentConfiguration extends Widget {
  ComponentConfiguration({ Key key }) : super(key);

  ComponentStateElement createElement() => new ComponentStateElement(this);

  ComponentState createState();
}

bool _canUpdate(Widget oldWidget, Widget newWidget) {
  return oldWidget.runtimeType == newWidget.runtimeType
    && oldWidget.key == newWidget.key;
}

void _debugReportException(String context, dynamic exception, StackTrace stack) {
  print('------------------------------------------------------------------------');
  'Exception caught while $context'.split('\n').forEach(print);
  print('$exception');
  print('Stack trace:');
  '$stack'.split('\n').forEach(print);
  print('------------------------------------------------------------------------');
}

enum _ElementLifecycle {
  initial,
  mounted,
  defunct,
}

typedef void ElementVisitor(Element element);

abstract class Element<T extends Widget> {
  Element(T widget) : _widget = widget {
    assert(_widget != null);
  }

  Element _parent;
  T _widget;

  _ElementLifecycle _lifecycleState = _ElementLifecycle.initial;

  void visitChildren(ElementVisitor visitor) { }

  void visitDescendants(ElementVisitor visitor) {
    void walk(Element element) {
      visitor(element);
      element.visitChildren(walk);
    }
    visitChildren(walk);
  }

  void mount(dynamic slot) {
    assert(_lifecycleState == _ElementLifecycle.initial);
    assert(_widget != null);
    _lifecycleState = _ElementLifecycle.mounted;
    assert(_parent == null || _parent._lifecycleState == _ElementLifecycle.mounted);
  }

  void update(T updated, dynamic slot) {
    assert(_lifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    assert(updated != null);
    assert(_canUpdate(_widget, updated));
    _widget = updated;
  }

  void unmount() {
    assert(_lifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    _lifecycleState = _ElementLifecycle.defunct;
  }

  void _detachChild(Element child) {
    if (child == null)
      return;
    child._parent = null;

    bool haveDetachedRenderObject = false;
    void detach(Element descendant) {
      if (!haveDetachedRenderObject && descendant is RenderObjectElement) {
        descendant.detachRenderObject();
        haveDetachedRenderObject = true;
      }
      descendant.unmount();
    }

    detach(child);
    child.visitDescendants(detach);
  }

  Element _updateChild(Element child, Widget updated, dynamic slot) {
    if (updated == null) {
      _detachChild(child);
      return null;
    }

    if (child != null) {
      if (_canUpdate(child._widget, updated)) {
        child.update(updated, slot);
        return child;
      }
      _detachChild(child);
      assert(child._parent == null);
    }

    Element newChild = updated.createElement();
    newChild._parent = this;
    newChild.mount(slot);
    return newChild;
  }

}

abstract class BuildableElement<T extends Widget> extends Element<T> {
  BuildableElement(T widget) : super(widget);

  WidgetBuilder _builder;
  Element _child;

  void _rebuild(dynamic slot) {
    Widget built;
    try {
      built = _builder();
      assert(built != null);
    } catch (e, stack) {
      _debugReportException('building $this', e, stack);
    }
    _child = _updateChild(_child, built, slot);
  }

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(dynamic slot) {
    super.mount(slot);
    assert(_child == null);
    _rebuild(slot);
    assert(_child != null);
  }
}

class ComponentElement extends BuildableElement<Component> {
  ComponentElement(Component component) : super(component) {
    _builder = component.build;
  }

  void update(Component updated, dynamic slot) {
    super.update(updated, slot);
    assert(_widget == updated);
    _builder = _widget.build;
    _rebuild(slot);
  }
}

class ComponentStateElement extends BuildableElement<ComponentConfiguration> {
  ComponentStateElement(ComponentConfiguration configuration)
    : _state = configuration.createState(), super(configuration) {
    _builder = _state.build;
    _state._holder = this;
    _state.config = configuration;
  }

  ComponentState _state;

  void update(ComponentConfiguration updated, dynamic slot) {
    super.update(updated, slot);
    assert(_widget == updated);
    _state.config = _widget;
    _rebuild(slot);
  }

  void unmount() {
    super.unmount();
    _state.didUnmount();
    _state = null;
  }

  void scheduleBuild() {
    // TODO(abarth): Implement rebuilding.
  }
}

RenderObjectElement _findAncestorRenderObjectElement(Element ancestor) {
  while (ancestor != null && ancestor is! RenderObjectElement)
    ancestor = ancestor._parent;
  return ancestor;
}

class RenderObjectElement<T extends RenderObjectWidget> extends Element<T> {
  RenderObjectElement(T widget)
    : renderObject = widget.createRenderObject(), super(widget);

  final RenderObject renderObject;
  RenderObjectElement _ancestorRenderObjectElement;

  void mount(dynamic slot) {
    super.mount(slot);
    assert(_ancestorRenderObjectElement == null);
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement(_parent);
    if (_ancestorRenderObjectElement != null)
      _ancestorRenderObjectElement.insertChildRenderObject(renderObject, slot);
  }

  void update(T updated, dynamic slot) {
    super.update(updated, slot);
    assert(_widget == updated);
    _widget.updateRenderObject(renderObject);
  }

  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement.removeChildRenderObject(renderObject);
      _ancestorRenderObjectElement = null;
    }
  }

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(false);
  }
}

class OneChildRenderObjectElement<T extends OneChildRenderObjectWidget> extends RenderObjectElement<T> {
  OneChildRenderObjectElement(T widget) : super(widget);

  Element _child;

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(dynamic slot) {
    super.mount(slot);
    _child = _updateChild(_child, _widget.child, null);
  }

  void update(T updated, dynamic slot) {
    super.update(updated, slot);
    assert(_widget == updated);
    _child = _updateChild(_child, _widget.child, null);
  }

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is RenderObjectWithChildMixin);
    assert(slot == null);
    renderObject.child = child;
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void removeChildRenderObject(RenderObject child) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is RenderObjectWithChildMixin);
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }
}

class MultiChildRenderObjectElement<T extends MultiChildRenderObjectWidget> extends RenderObjectElement<T> {
  MultiChildRenderObjectElement(T widget) : super(widget);
}
