// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/rendering.dart';

abstract class Key { }

/// A Widget object describes the configuration for an [Element].
/// Widget subclasses should be immutable with const constructors.
/// Widgets form a tree that is then inflated into an Element tree.
abstract class Widget {
  const Widget({ this.key });
  final Key key;

  /// Inflates this configuration to a concrete instance.
  Element createElement();
}

/// RenderObjectWidgets provide the configuration for [RenderObjectElement]s,
/// which wrap [RenderObject]s, which provide the actual rendering of the
/// application.
abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget({ Key key }) : super(key: key);

  /// RenderObjectWidgets always inflate to a RenderObjectElement subclass.
  RenderObjectElement createElement();

  /// Constructs an instance of the RenderObject class that this
  /// RenderObjectWidget represents, using the configuration described by this
  /// RenderObjectWidget.
  RenderObject createRenderObject();

  /// Copies the configuration described by this RenderObjectWidget to the given
  /// RenderObject, which must be of the same type as returned by this class'
  /// createRenderObject().
  void updateRenderObject(RenderObject renderObject);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have no children.
abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget({ Key key }) : super(key: key);

  RenderObjectElement createElement() => new LeafRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single child slot. (This superclass only provides the storage
/// for that child, it doesn't actually provide the updating logic.)
abstract class OneChildRenderObjectWidget extends RenderObjectWidget {
  const OneChildRenderObjectWidget({ Key key, Widget this.child }) : super(key: key);

  final Widget child;

  RenderObjectElement createElement() => new OneChildRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single list of children. (This superclass only provides the
/// storage for that child list, it doesn't actually provide the updating
/// logic.)
abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  const MultiChildRenderObjectWidget({ Key key, List<Widget> this.children })
    : super(key: key);

  final List<Widget> children;

  RenderObjectElement createElement() => new MultiChildRenderObjectElement(this);
}

/// StatelessComponents describe a way to compose other Widgets to form reusable
/// parts, which doesn't depend on anything other than the configuration
/// information in the object itself. (For compositions that can change
/// dynamically, e.g. due to having an internal clock-driven state, or depending
/// on some system state, use [StatefulComponent].)
abstract class StatelessComponent extends Widget {
  const StatelessComponent({ Key key }) : super(key: key);

  /// StatelessComponents always use StatelessComponentElements to represent
  /// themselves in the Element tree.
  StatelessComponentElement createElement() => new StatelessComponentElement(this);

  /// Returns another Widget out of which this StatelessComponent is built.
  /// Typically that Widget will have been configured with further children,
  /// such that really this function returns a tree of configuration.
  Widget build();
}

/// StatefulComponents provide the configuration for
/// [StatefulComponentElement]s, which wrap [ComponentState]s, which hold
/// mutable state and can dynamically and spontaneously ask to be rebuilt.
abstract class StatefulComponent extends Widget {
  const StatefulComponent({ Key key }) : super(key: key);

  /// StatefulComponents always use StatefulComponentElements to represent
  /// themselves in the Element tree.
  StatefulComponentElement createElement() => new StatefulComponentElement(this);

  /// Returns an instance of the state to which this StatefulComponent is
  /// related, using this object as the configuration. Subclasses should
  /// override this to return a new instance of the ComponentState class
  /// associated with this StatefulComponent class, like this:
  ///
  ///   MyComponentState createState() => new MyComponentState(this);
  ComponentState createState();
}

/// The logic and internal state for a StatefulComponent.
abstract class ComponentState<T extends StatefulComponent> {
  ComponentState(this._config);

  StatefulComponentElement _element;

  /// Whenever you need to change internal state for a ComponentState object,
  /// make the change in a function that you pass to setState(), as in:
  ///
  ///    setState(() { myState = newValue });
  ///
  /// If you just change the state directly without calling setState(), then
  /// the component will not be scheduled for rebuilding, meaning that its
  /// rendering will not be updated.
  void setState(void fn()) {
    fn();
    _element.scheduleBuild();
  }

  /// The current configuration (an instance of the corresponding
  /// StatefulComponent class).
  T get config => _config;
  T _config;

  /// Called whenever the configuration changes. Override this method to update
  /// additional state when the config field's value is changed.
  void didUpdateConfig(T oldConfig) { }

  /// Called when this object is removed from the tree. Override this to clean
  /// up any resources allocated by this object.
  void dispose() { }

  /// Returns another Widget out of which this StatefulComponent is built.
  /// Typically that Widget will have been configured with further children,
  /// such that really this function returns a tree of configuration.
  Widget build();
}

bool _canUpdate(Widget oldWidget, Widget newWidget) {
  return oldWidget.runtimeType == newWidget.runtimeType &&
         oldWidget.key == newWidget.key;
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

  /// information set by parent to define where this child fits in its parent's
  /// child list
  dynamic _slot;

  /// an integer that is guaranteed to be greater than the parent's, if any
  int _depth;

  /// the configuration for this element
  T _widget;

  _ElementLifecycle _lifecycleState = _ElementLifecycle.initial;

  /// Calls the argument for each child. Must be overridden by subclasses that support having children.
  void visitChildren(ElementVisitor visitor) { }

  /// Calls the argument for each descendant, depth-first pre-order.
  void visitDescendants(ElementVisitor visitor) {
    void walk(Element element) {
      visitor(element);
      element.visitChildren(walk);
    }
    visitChildren(walk);
  }

  void mount(dynamic slot) {
    assert(_lifecycleState == _ElementLifecycle.initial);
    assert(_parent == null || _parent._lifecycleState == _ElementLifecycle.mounted);
    assert(slot != null);
    assert(_widget != null);
    assert(_depth == null);
    _lifecycleState = _ElementLifecycle.mounted;
    _slot = slot;
    _depth = _parent == null ? 0 : _parent._depth + 1;
  }

  void updateSlot(dynamic slot) {
    assert(slot != null);
    assert(_lifecycleState == _ElementLifecycle.mounted);
    assert(_parent != null);
    assert(_parent._lifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    assert(_depth == null);
    _slot = slot;
  }

  void update(T newWidget) {
    assert(newWidget != null);
    assert(_lifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    assert(_depth != null);
    assert(_canUpdate(_widget, newWidget));
    _widget = newWidget;
  }

  void unmount() {
    assert(_lifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    assert(_depth != null);
    _slot = null;
    _depth = null;
    _lifecycleState = _ElementLifecycle.defunct;
  }

  void _updateSlotForChild(Element child, dynamic slot) {
    if (child == null)
      return;
    assert(child._parent == this);

    void move(Element element) {
      child.updateSlot(slot);
      if (child is! RenderObjectElement)
        child.visitChildren(move);
    }

    move(child);
  }

  void _detachChild(Element child) {
    if (child == null)
      return;
    assert(child._parent == this);
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
      assert(child._slot == slot);
      if (child._widget == updated)
        return child;
      if (_canUpdate(child._widget, updated)) {
        child.update(updated);
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

  static void flushBuild() {
    _buildScheduler.buildDirtyElements();
  }
}

class _BuildScheduler {
  final Set<BuildableElement> _dirtyElements = new Set<BuildableElement>();
  bool _inBuildDirtyElements = false;

  void schedule(BuildableElement element) {
    if (_dirtyElements.isEmpty)
      scheduler.ensureVisualUpdate();
    _dirtyElements.add(element);
  }

  void _absorbDirtyElement(List<BuildableElement> list) {
    list.addAll(_dirtyElements);
    _dirtyElements.clear();
    list.sort((BuildableElement a, BuildableElement b) => a._depth - b._depth);
  }

  void buildDirtyElements() {
    if (_dirtyElements.isEmpty)
      return;

    _inBuildDirtyElements = true;
    try {
      while (!_dirtyElements.isEmpty) {
        List<BuildableElement> sortedDirtyElements = new List<BuildableElement>();
        _absorbDirtyElement(sortedDirtyElements);
        int index = 0;
        while (index < sortedDirtyElements.length) {
          sortedDirtyElements[index]._rebuildIfNeeded();
          if (!_dirtyElements.isEmpty) {
            assert(_dirtyElements.every((Element element) => !sortedDirtyElements.contains(element)));
            _absorbDirtyElement(sortedDirtyElements);
            index = 0;
          } else {
            index += 1;
          }
        }
      }
    } finally {
      _inBuildDirtyElements = false;
    }
    assert(_dirtyElements.isEmpty);
  }
}

final _BuildScheduler _buildScheduler = new _BuildScheduler();

typedef Widget WidgetBuilder();

abstract class BuildableElement<T extends Widget> extends Element<T> {
  BuildableElement(T widget) : super(widget);

  WidgetBuilder _builder;
  Element _child;
  bool _dirty = true;

  void _rebuild() {
    _dirty = false;
    Widget built;
    try {
      built = _builder();
      assert(built != null);
    } catch (e, stack) {
      _debugReportException('building $this', e, stack);
    }
    _child = _updateChild(_child, built, _slot);
  }

  void _rebuildIfNeeded() {
    if (_dirty && _lifecycleState == _ElementLifecycle.mounted)
      _rebuild();
  }

  void scheduleBuild() {
    if (_dirty || _lifecycleState != _ElementLifecycle.mounted)
      return;
    _dirty = true;
    _buildScheduler.schedule(this);
    // TODO(abarth): Implement rebuilding.
  }

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(dynamic slot) {
    super.mount(slot);
    assert(_child == null);
    _rebuild();
    assert(_child != null);
  }
}

class StatelessComponentElement extends BuildableElement<StatelessComponent> {
  StatelessComponentElement(StatelessComponent component) : super(component) {
    _builder = component.build;
  }

  void update(StatelessComponent newWidget) {
    super.update(newWidget);
    assert(_widget == newWidget);
    _builder = _widget.build;
    _rebuild();
  }
}

class StatefulComponentElement extends BuildableElement<StatefulComponent> {
  StatefulComponentElement(StatefulComponent configuration)
    : _state = configuration.createState(), super(configuration) {
    assert(_state._config == configuration);
    _state._element = this;
    _builder = _state.build;
  }

  ComponentState get state => _state;
  ComponentState _state;

  void update(StatefulComponent newWidget) {
    super.update(newWidget);
    assert(_widget == newWidget);
    StatefulComponent oldConfig = _state._config;
    _state._config = _widget;
    _state.didUpdateConfig(oldConfig);
    _rebuild();
  }

  void unmount() {
    super.unmount();
    _state.dispose();
    _state = null;
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

  void update(T updated) {
    super.update(updated);
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

class LeafRenderObjectElement<T extends RenderObjectWidget> extends RenderObjectElement<T> {
  LeafRenderObjectElement(T widget): super(widget);
}

final Object _uniqueChild = new Object();

class OneChildRenderObjectElement<T extends OneChildRenderObjectWidget> extends RenderObjectElement<T> {
  OneChildRenderObjectElement(T widget) : super(widget);

  Element _child;

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(dynamic slot) {
    super.mount(slot);
    _child = _updateChild(_child, _widget.child, _uniqueChild);
  }

  void update(T updated) {
    super.update(updated);
    assert(_widget == updated);
    _child = _updateChild(_child, _widget.child, _uniqueChild);
  }

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is RenderObjectWithChildMixin);
    assert(slot == _uniqueChild);
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



typedef void WidgetsExceptionHandler(String context, dynamic exception, StackTrace stack);
/// This callback is invoked whenever an exception is caught by the widget
/// system. The 'context' argument is a description of what was happening when
/// the exception occurred, and may include additional details such as
/// descriptions of the objects involved. The 'exception' argument contains the
/// object that was thrown, and the 'stack' argument contains the stack trace.
/// The callback is invoked after the information is printed to the console, and
/// could be used to print additional information, such as from
/// [debugDumpApp()].
WidgetsExceptionHandler debugWidgetsExceptionHandler;
void _debugReportException(String context, dynamic exception, StackTrace stack) {
  print('------------------------------------------------------------------------');
  'Exception caught while $context'.split('\n').forEach(print);
  print('$exception');
  print('Stack trace:');
  '$stack'.split('\n').forEach(print);
  if (debugWidgetsExceptionHandler != null)
    debugWidgetsExceptionHandler(context, exception, stack);
  print('------------------------------------------------------------------------');
}
