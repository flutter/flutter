// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/animation.dart';
import 'package:sky/rendering.dart';

abstract class Key {
  const Key.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor
  factory Key(String value) => new ValueKey<String>(value);
}

class ValueKey<T> extends Key {
  const ValueKey(this.value) : super.constructor();
  final T value;
  String toString() => '[\'${value}\']';
  bool operator==(other) => other is ValueKey<T> && other.value == value;
  int get hashCode => value.hashCode;
}

class ObjectKey extends Key {
  const ObjectKey(this.value) : super.constructor();
  final Object value;
  String toString() => '[${value.runtimeType}(${value.hashCode})]';
  bool operator==(other) => other is ObjectKey && identical(other.value, value);
  int get hashCode => identityHashCode(value);
}

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
  void updateRenderObject(RenderObject renderObject, RenderObjectWidget oldWidget);

  void didUnmountRenderObject(RenderObject renderObject) { }
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

const Object _uniqueChild = const Object();

/// Elements are the instantiations of Widget configurations.
///
/// Elements can, in principle, have children. Only subclasses of
/// RenderObjectElement are allowed to have more than one child.
abstract class Element<T extends Widget> {
  Element(T widget) : _widget = widget {
    assert(_widget != null);
  }

  Element _parent;

  /// Information set by parent to define where this child fits in its parent's
  /// child list.
  ///
  /// Subclasses of Element that only have one child should use _uniqueChild for
  /// the slot for that child.
  dynamic _slot;

  /// An integer that is guaranteed to be greater than the parent's, if any.
  /// The element at the root of the tree must have a depth greater than 0.
  int _depth;

  /// The configuration for this element.
  T _widget;

  /// This is used to verify that Element objects move through life in an orderly fashion.
  _ElementLifecycle _debugLifecycleState = _ElementLifecycle.initial;

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

  Element _updateChild(Element child, Widget newWidget, dynamic slot) {
    // This method is the core of the system.
    //
    // It is called each time we are to add, update, or remove a child based on
    // an updated configuration.
    //
    // If the child is null, and the newWidget is not null, then we have a new
    // child for which we need to create an Element, configured with newWidget.
    //
    // If the newWidget is null, and the child is not null, then we need to
    // remove it because it no longer has a configuration.
    //
    // If neither are null, then we need to update the child's configuration to
    // be the new configuration given by newWidget. If newWidget can be given to
    // the existing child, then it is so given. Otherwise, the old child needs
    // to be disposed and a new child created for the new configuration.
    //
    // If both are null, then we don't have a child and won't have a child, so
    // we do nothing.
    //
    // The _updateChild() method returns the new child, if it had to create one,
    // or the child that was passed in, if it just had to update the child, or
    // null, if it removed the child and did not replace it.
    assert(slot != null);
    if (newWidget == null) {
      if (child != null)
        _detachChild(child);
      return null;
    }
    if (child != null) {
      assert(child._slot == slot);
      if (child._widget == newWidget)
        return child;
      if (_canUpdate(child._widget, newWidget)) {
        child.update(newWidget);
        assert(child._widget == newWidget);
        return child;
      }
      _detachChild(child);
      assert(child._parent == null);
    }
    child = newWidget.createElement();
    child.mount(this, slot);
    assert(child._debugLifecycleState == _ElementLifecycle.mounted);
    return child;
  }

  /// Called when an Element is given a new parent shortly after having been
  /// created.
  void mount(Element parent, dynamic slot) {
    assert(_debugLifecycleState == _ElementLifecycle.initial);
    assert(_widget != null);
    assert(_parent == null);
    assert(parent == null || parent._debugLifecycleState == _ElementLifecycle.mounted);
    assert(_slot == null);
    assert(slot != null);
    assert(_depth == null);
    _parent = parent;
    _slot = slot;
    _depth = _parent != null ? _parent._depth + 1 : 1;
    assert(() { _debugLifecycleState = _ElementLifecycle.mounted; return true; });
  }

  /// Called when an Element receives a new configuration widget.
  void update(T newWidget) {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    assert(newWidget != null);
    assert(_slot != null);
    assert(_depth != null);
    assert(_canUpdate(_widget, newWidget));
    _widget = newWidget;
  }

  /// Called by MultiChildRenderObjectElement, and other RenderObjectElement
  /// subclasses that have multiple children, to update the slot of a particular
  /// child when the child is moved in its child list.
  void updateSlotForChild(Element child, dynamic slot) {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    assert(child != null);
    assert(child._parent == this);

    void move(Element element) {
      child._updateSlot(slot);
      if (child is! RenderObjectElement)
        child.visitChildren(move);
    }

    move(child);
  }

  void _updateSlot(dynamic slot) {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    assert(_parent != null);
    assert(_parent._debugLifecycleState == _ElementLifecycle.mounted);
    assert(_slot != null);
    assert(slot != null);
    assert(_depth == null);
    _slot = slot;
  }

  void _detachChild(Element child) {
    assert(child != null);
    assert(child._parent == this);
    child._parent = null;

    bool haveDetachedRenderObject = false;
    void detach(Element descendant) {
      if (!haveDetachedRenderObject) {
        descendant._slot = null;
        if (descendant is RenderObjectElement) {
          descendant.detachRenderObject();
          haveDetachedRenderObject = true;
        }
      }
      descendant.unmount();
      assert(descendant._debugLifecycleState == _ElementLifecycle.defunct);
    }

    detach(child);
    child.visitDescendants(detach);
  }

  /// Called when an Element is removed from the tree.
  /// Currently, an Element removed from the tree never returns.
  void unmount() {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    assert(_widget != null);
    assert(_depth != null);
    assert(() { _debugLifecycleState = _ElementLifecycle.defunct; return true; });
  }

  // TODO(ianh): Merge this into the binding, expose for tests
  static void flushBuild() {
    _buildScheduler.buildDirtyElements();
  }
}

typedef Widget WidgetBuilder();

/// Base class for the instantiation of StatelessComponent and StatefulComponent
/// widgets.
abstract class BuildableElement<T extends Widget> extends Element<T> {
  BuildableElement(T widget) : super(widget);

  WidgetBuilder _builder;
  Element _child;
  bool _dirty = true;

  void mount(Element parent, dynamic slot) {
    super.mount(parent, slot);
    assert(_child == null);
    _rebuild();
    assert(_child != null);
  }

  // This is also called for the first build
  void _rebuild() {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
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

  /// Called by the binding when scheduleBuild() has been called to mark this element dirty.
  void _rebuildIfNeeded() {
    if (_dirty)
      _rebuild();
  }

  /// Marks the element as dirty and adds it to the global list of widgets to
  /// rebuild in the next frame.
  ///
  /// Since it is inefficient to build an element twice in one frame,
  /// applications and components should be structured so as to only mark
  /// components dirty during event handlers before the frame begins, not during
  /// the build itself.
  void scheduleBuild() {
    assert(_debugLifecycleState == _ElementLifecycle.mounted);
    if (_dirty)
      return;
    _dirty = true;
    _buildScheduler.schedule(this);
  }

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void unmount() {
    super.unmount();
    _dirty = false; // so that we don't get rebuilt even if we're already marked dirty
  }
}

/// Instantiation of StatelessComponent widgets.
class StatelessComponentElement extends BuildableElement<StatelessComponent> {
  StatelessComponentElement(StatelessComponent widget) : super(widget) {
    _builder = _widget.build;
  }

  void update(StatelessComponent newWidget) {
    super.update(newWidget);
    assert(_widget == newWidget);
    _builder = _widget.build;
    _rebuild();
  }
}

/// Instantiation of StatefulComponent widgets.
class StatefulComponentElement extends BuildableElement<StatefulComponent> {
  StatefulComponentElement(StatefulComponent widget)
    : _state = widget.createState(), super(widget) {
    assert(_state._config == widget);
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

/// Base class for instantiations of RenderObjectWidget subclasses
abstract class RenderObjectElement<T extends RenderObjectWidget> extends Element<T> {
  RenderObjectElement(T widget)
    : renderObject = widget.createRenderObject(), super(widget);

  /// The underlying [RenderObject] for this element
  final RenderObject renderObject;
  RenderObjectElement _ancestorRenderObjectElement;

  RenderObjectElement _findAncestorRenderObjectElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement)
      ancestor = ancestor._parent;
    return ancestor;
  }

  void mount(Element parent, dynamic slot) {
    super.mount(parent, slot);
    assert(_ancestorRenderObjectElement == null);
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    _ancestorRenderObjectElement?.insertChildRenderObject(renderObject, slot);
  }

  void update(T newWidget) {
    Widget oldWidget = _widget;
    super.update(newWidget);
    assert(_widget == newWidget);
    _widget.updateRenderObject(renderObject, oldWidget);
  }

  void unmount() {
    super.unmount();
    _widget.didUnmountRenderObject(renderObject);
  }

  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement.removeChildRenderObject(renderObject);
      _ancestorRenderObjectElement = null;
    }
  }

  void insertChildRenderObject(RenderObject child, dynamic slot);

  void removeChildRenderObject(RenderObject child);
}

/// Instantiation of RenderObjectWidgets that have no children
class LeafRenderObjectElement<T extends RenderObjectWidget> extends RenderObjectElement<T> {
  LeafRenderObjectElement(T widget): super(widget);

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void removeChildRenderObject(RenderObject child) {
    assert(false);
  }
}

/// Instantiation of RenderObjectWidgets that have up to one child
class OneChildRenderObjectElement<T extends OneChildRenderObjectWidget> extends RenderObjectElement<T> {
  OneChildRenderObjectElement(T widget) : super(widget);

  Element _child;

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  void mount(Element parent, dynamic slot) {
    super.mount(parent, slot);
    _child = _updateChild(_child, _widget.child, _uniqueChild);
  }

  void update(T newWidget) {
    super.update(newWidget);
    assert(_widget == newWidget);
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

/// Instantiation of RenderObjectWidgets that can have a list of children
class MultiChildRenderObjectElement<T extends MultiChildRenderObjectWidget> extends RenderObjectElement<T> {
  MultiChildRenderObjectElement(T widget) : super(widget);

  // TODO(ianh): implement
}

class _BuildScheduler {
  final List<BuildableElement> _dirtyElements = new List<BuildableElement>();

  int _debugBuildingAtDepth;

  void schedule(BuildableElement element) {
    assert(_debugBuildingAtDepth == null || element._depth > _debugBuildingAtDepth);
    assert(!_dirtyElements.contains(element));
    if (_dirtyElements.isEmpty)
      scheduler.ensureVisualUpdate();
    _dirtyElements.add(element);
  }

  void _absorbDirtyElements(List<BuildableElement> list) {
    assert(_debugBuildingAtDepth != null);
    assert(!_dirtyElements.any((element) => element._depth <= _debugBuildingAtDepth));
    _dirtyElements.sort((BuildableElement a, BuildableElement b) => a._depth - b._depth);
    list.addAll(_dirtyElements);
    _dirtyElements.clear();
  }

  /// Builds all the elements that were marked as dirty using schedule(), in depth order.
  /// If elements are marked as dirty while this runs, they must be deeper than the algorithm
  /// has yet reached.
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
          if (element._depth > _debugBuildingAtDepth)
            _debugBuildingAtDepth = element._depth;
          return element._depth == _debugBuildingAtDepth;
        });
        element._rebuildIfNeeded();
      }
    } while (_dirtyElements.isNotEmpty);
    assert(() { _debugBuildingAtDepth = null; return true; });
  }
}

final _BuildScheduler _buildScheduler = new _BuildScheduler();


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
