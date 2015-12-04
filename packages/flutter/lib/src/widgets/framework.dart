// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:flutter/rendering.dart';

export 'package:flutter/rendering.dart' show debugPrint;

// KEYS

/// A Key is an identifier for [Widget]s and [Element]s. A new Widget will only
/// be used to reconfigure an existing Element if its Key is the same as its
/// original Widget's Key.
///
/// Keys must be unique amongst the Elements with the same parent.
abstract class Key {
  /// Default constructor, used by subclasses.
  const Key.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor

  /// Construct a ValueKey<String> with the given String.
  /// This is the simplest way to create keys.
  factory Key(String value) => new ValueKey<String>(value);
}

/// A kind of [Key] that uses a value of a particular type to identify itself.
///
/// For example, a ValueKey<String> is equal to another ValueKey<String> if
/// their values match.
class ValueKey<T> extends Key {
  const ValueKey(this.value) : super.constructor();
  final T value;
  bool operator ==(dynamic other) {
    if (other is! ValueKey<T>)
      return false;
    final ValueKey<T> typedOther = other;
    return value == typedOther.value;
  }
  int get hashCode => value.hashCode;
  String toString() => '[\'$value\']';
}

/// A [Key] that is only equal to itself.
class UniqueKey extends Key {
  const UniqueKey() : super.constructor();
  String toString() => '[$hashCode]';
}

/// A kind of [Key] that takes its identity from the object used as its value.
///
/// Used to tie the identity of a Widget to the identity of an object used to
/// generate that Widget.
class ObjectKey extends Key {
  const ObjectKey(this.value) : super.constructor();
  final Object value;
  bool operator ==(dynamic other) {
    if (other is! ObjectKey)
      return false;
    final ObjectKey typedOther = other;
    return identical(value, typedOther.value);
  }
  int get hashCode => identityHashCode(value);
  String toString() => '[${value.runtimeType}(${value.hashCode})]';
}

typedef void GlobalKeyRemoveListener(GlobalKey key);

/// A GlobalKey is one that must be unique across the entire application. It is
/// used by components that need to communicate with other components across the
/// application's element tree.
abstract class GlobalKey<T extends State<StatefulComponent>> extends Key {
  const GlobalKey.constructor() : super.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor

  /// Constructs a LabeledGlobalKey, which is a GlobalKey with a label used for debugging.
  /// The label is not used for comparing the identity of the key.
  factory GlobalKey({ String debugLabel }) => new LabeledGlobalKey<T>(debugLabel); // the label is purely for debugging purposes and is otherwise ignored

  static final Map<GlobalKey, Element> _registry = new Map<GlobalKey, Element>();
  static final Map<GlobalKey, int> _debugDuplicates = new Map<GlobalKey, int>();
  static final Map<GlobalKey, Set<GlobalKeyRemoveListener>> _removeListeners = new Map<GlobalKey, Set<GlobalKeyRemoveListener>>();
  static final Set<GlobalKey> _removedKeys = new Set<GlobalKey>();

  void _register(Element element) {
    assert(() {
      if (_registry.containsKey(this)) {
        int oldCount = _debugDuplicates.putIfAbsent(this, () => 1);
        assert(oldCount >= 1);
        _debugDuplicates[this] = oldCount + 1;
      }
      return true;
    });
    _registry[this] = element;
  }

  void _unregister(Element element) {
    assert(() {
      if (_registry.containsKey(this) && _debugDuplicates.containsKey(this)) {
        int oldCount = _debugDuplicates[this];
        assert(oldCount >= 2);
        if (oldCount == 2) {
          _debugDuplicates.remove(this);
        } else {
          _debugDuplicates[this] = oldCount - 1;
        }
      }
      return true;
    });
    if (_registry[this] == element) {
      _registry.remove(this);
      _removedKeys.add(this);
    }
  }

  Element get _currentElement => _registry[this];
  BuildContext get currentContext => _currentElement;
  Widget get currentWidget => _currentElement?.widget;
  T get currentState {
    Element element = _currentElement;
    if (element is StatefulComponentElement<StatefulComponent, T>) {
      StatefulComponentElement<StatefulComponent, T> statefulElement = element;
      return statefulElement.state;
    }
    return null;
  }

  static void registerRemoveListener(GlobalKey key, GlobalKeyRemoveListener listener) {
    assert(key != null);
    Set<GlobalKeyRemoveListener> listeners =
        _removeListeners.putIfAbsent(key, () => new Set<GlobalKeyRemoveListener>());
    bool added = listeners.add(listener);
    assert(added);
  }

  static void unregisterRemoveListener(GlobalKey key, GlobalKeyRemoveListener listener) {
    assert(key != null);
    assert(_removeListeners.containsKey(key));
    bool removed = _removeListeners[key].remove(listener);
    if (_removeListeners[key].isEmpty)
      _removeListeners.remove(key);
    assert(removed);
  }

  static bool _debugCheckForDuplicates() {
    String message = '';
    for (GlobalKey key in _debugDuplicates.keys) {
      message += 'Duplicate GlobalKey found amongst mounted elements: $key (${_debugDuplicates[key]} instances)\n';
      message += 'Most recently registered instance is:\n${_registry[key]}\n';
    }
    if (!_debugDuplicates.isEmpty)
      throw message;
    return true;
  }

  static void _notifyListeners() {
    if (_removedKeys.isEmpty)
      return;
    try {
      for (GlobalKey key in _removedKeys) {
        if (!_registry.containsKey(key) && _removeListeners.containsKey(key)) {
          Set<GlobalKeyRemoveListener> localListeners = new Set<GlobalKeyRemoveListener>.from(_removeListeners[key]);
          for (GlobalKeyRemoveListener listener in localListeners)
            listener(key);
        }
      }
    } finally {
      _removedKeys.clear();
    }
  }

}

/// Each LabeledGlobalKey instance is a unique key.
/// The optional label can be used for documentary purposes. It does not affect
/// the key's identity.
class LabeledGlobalKey<T extends State<StatefulComponent>> extends GlobalKey<T> {
  const LabeledGlobalKey(this._debugLabel) : super.constructor();
  final String _debugLabel;
  String toString() => '[GlobalKey ${_debugLabel != null ? _debugLabel : hashCode}]';
}

/// A kind of [GlobalKey] that takes its identity from the object used as its value.
///
/// Used to tie the identity of a Widget to the identity of an object used to
/// generate that Widget.
class GlobalObjectKey extends GlobalKey {
  const GlobalObjectKey(this.value) : super.constructor();
  final Object value;
  bool operator ==(dynamic other) {
    if (other is! GlobalObjectKey)
      return false;
    final GlobalObjectKey typedOther = other;
    return identical(value, typedOther.value);
  }
  int get hashCode => identityHashCode(value);
  String toString() => '[$runtimeType ${value.runtimeType}(${value.hashCode})]';
}


// WIDGETS

/// A Widget object describes the configuration for an [Element].
/// Widget subclasses should be immutable with const constructors.
/// Widgets form a tree that is then inflated into an Element tree.
abstract class Widget {
  const Widget({ this.key });
  final Key key;

  /// Inflates this configuration to a concrete instance.
  Element createElement();

  String toStringShort() {
    return key == null ? '$runtimeType' : '$runtimeType-$key';
  }

  String toString() {
    final String name = toStringShort();
    final List<String> data = <String>[];
    debugFillDescription(data);
    if (data.isEmpty)
      return '$name';
    return '$name(${data.join("; ")})';
  }

  void debugFillDescription(List<String> description) { }
}

// TODO(ianh): move the next four classes to below InheritedWidget

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
  void updateRenderObject(RenderObject renderObject, RenderObjectWidget oldWidget) { }

  void didUnmountRenderObject(RenderObject renderObject) { }
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have no children.
abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget({ Key key }) : super(key: key);

  LeafRenderObjectElement createElement() => new LeafRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single child slot. (This superclass only provides the storage
/// for that child, it doesn't actually provide the updating logic.)
abstract class OneChildRenderObjectWidget extends RenderObjectWidget {
  const OneChildRenderObjectWidget({ Key key, this.child }) : super(key: key);

  final Widget child;

  OneChildRenderObjectElement createElement() => new OneChildRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single list of children. (This superclass only provides the
/// storage for that child list, it doesn't actually provide the updating
/// logic.)
abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  MultiChildRenderObjectWidget({ Key key, this.children })
    : super(key: key) {
    assert(!children.any((Widget child) => child == null));
  }

  final List<Widget> children;

  MultiChildRenderObjectElement createElement() => new MultiChildRenderObjectElement(this);
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
  ///
  /// The given build context object contains information about the location in
  /// the tree at which this component is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree.
  Widget build(BuildContext context);
}

/// StatefulComponents provide the configuration for
/// [StatefulComponentElement]s, which wrap [State]s, which hold mutable state
/// and can dynamically and spontaneously ask to be rebuilt.
abstract class StatefulComponent extends Widget {
  const StatefulComponent({ Key key }) : super(key: key);

  /// StatefulComponents always use StatefulComponentElements to represent
  /// themselves in the Element tree.
  StatefulComponentElement createElement() => new StatefulComponentElement(this);

  /// Returns an instance of the state to which this StatefulComponent is
  /// related, using this object as the configuration. Subclasses should
  /// override this to return a new instance of the State class associated with
  /// this StatefulComponent class, like this:
  ///
  ///   MyState createState() => new MyState(this);
  State createState();
}

enum _StateLifecycle {
  created,
  initialized,
  ready,
  defunct,
}

/// The signature of setState() methods.
typedef void StateSetter(VoidCallback fn);

/// The logic and internal state for a StatefulComponent.
abstract class State<T extends StatefulComponent> {
  /// The current configuration (an instance of the corresponding
  /// StatefulComponent class).
  T get config => _config;
  T _config;

  /// This is used to verify that State objects move through life in an orderly fashion.
  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  /// Verifies that the State that was created is one that expects to be created
  /// for that particular Widget.
  bool _debugTypesAreRight(widget) => widget is T;

  /// Pointer to the owner Element object
  StatefulComponentElement _element;

  /// The context in which this object will be built
  BuildContext get context => _element;

  bool get mounted => _element != null;

  /// Called when this object is inserted into the tree. Override this function
  /// to perform initialization that depends on the location at which this
  /// object was inserted into the tree or on the widget configuration object.
  ///
  /// If you override this, make sure your method starts with a call to
  /// super.initState().
  void initState() {
    assert(_debugLifecycleState == _StateLifecycle.created);
    assert(() { _debugLifecycleState = _StateLifecycle.initialized; return true; });
  }

  /// Called whenever the configuration changes. Override this method to update
  /// additional state when the config field's value is changed.
  void didUpdateConfig(T oldConfig) { }

  /// Whenever you need to change internal state for a State object, make the
  /// change in a function that you pass to setState(), as in:
  ///
  ///    setState(() { myState = newValue });
  ///
  /// If you just change the state directly without calling setState(), then the
  /// component will not be scheduled for rebuilding, meaning that its rendering
  /// will not be updated.
  void setState(VoidCallback fn) {
    assert(_debugLifecycleState != _StateLifecycle.defunct);
    fn();
    _element.markNeedsBuild();
  }

  /// Called when this object is removed from the tree.
  /// The object might momentarily be reattached to the tree elsewhere.
  ///
  /// Use this to clean up any links between this state and other
  /// elements in the tree (e.g. if you have provided an ancestor with
  /// a pointer to a descendant's renderObject).
  void deactivate() { }

  /// Called when this object is removed from the tree permanently.
  /// Override this to clean up any resources allocated by this
  /// object.
  ///
  /// If you override this, make sure to end your method with a call to
  /// super.dispose().
  void dispose() {
    assert(_debugLifecycleState == _StateLifecycle.ready);
    assert(() { _debugLifecycleState = _StateLifecycle.defunct; return true; });
  }

  /// Returns another Widget out of which this StatefulComponent is built.
  /// Typically that Widget will have been configured with further children,
  /// such that really this function returns a tree of configuration.
  ///
  /// The given build context object contains information about the location in
  /// the tree at which this component is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree.
  Widget build(BuildContext context);

  /// Called when an Inherited widget in the ancestor chain has changed. Usually
  /// there is nothing to do here; whenever this is called, build() is also
  /// called.
  void dependenciesChanged(Type affectedWidgetType) { }

  String toString() {
    final List<String> data = <String>[];
    debugFillDescription(data);
    return '$runtimeType(${data.join("; ")})';
  }

  void debugFillDescription(List<String> description) {
    description.add('$hashCode');
    assert(() {
      if (_debugLifecycleState != _StateLifecycle.ready)
        description.add('$_debugLifecycleState');
      return true;
    });
    if (_config == null)
      description.add('no config');
    if (_element == null)
      description.add('not mounted');
  }
}

abstract class ProxyComponent extends Widget {
  const ProxyComponent({ Key key, this.child }) : super(key: key);

  final Widget child;
}

abstract class ParentDataWidget extends ProxyComponent {
  const ParentDataWidget({ Key key, Widget child })
    : super(key: key, child: child);

  ParentDataElement createElement() => new ParentDataElement(this);

  /// Subclasses should override this function to ensure that they are placed
  /// inside widgets that expect them.
  ///
  /// The given ancestor is the first RenderObjectWidget ancestor of this widget.
  void debugValidateAncestor(RenderObjectWidget ancestor);

  void applyParentData(RenderObject renderObject);
}

abstract class InheritedWidget extends ProxyComponent {
  const InheritedWidget({ Key key, Widget child })
    : super(key: key, child: child);

  InheritedElement createElement() => new InheritedElement(this);

  bool updateShouldNotify(InheritedWidget oldWidget);
}


// ELEMENTS

bool _canUpdate(Widget oldWidget, Widget newWidget) {
  return oldWidget.runtimeType == newWidget.runtimeType &&
         oldWidget.key == newWidget.key;
}

enum _ElementLifecycle {
  initial,
  active,
  inactive,
  defunct,
}

class _InactiveElements {
  bool _locked = false;
  final Set<Element> _elements = new Set<Element>();

  void _unmount(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.unmount();
    assert(element._debugLifecycleState == _ElementLifecycle.defunct);
    element.visitChildren((Element child) {
      assert(child._parent == element);
      _unmount(child);
    });
  }

  void unmountAll() {
    BuildableElement.lockState(() {
      try {
        _locked = true;
        for (Element element in _elements)
          _unmount(element);
      } finally {
        _elements.clear();
        _locked = false;
      }
    });
  }

  void _deactivate(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.deactivate();
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.visitChildren(_deactivate);
  }

  void add(Element element) {
    assert(!_locked);
    assert(!_elements.contains(element));
    assert(element._parent == null);
    if (element._active)
      _deactivate(element);
    _elements.add(element);
  }

  void _reactivate(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.reactivate();
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.visitChildren(_reactivate);
  }

  void remove(Element element) {
    assert(!_locked);
    assert(_elements.contains(element));
    assert(element._parent == null);
    _elements.remove(element);
    assert(!element._active);
    _reactivate(element);
  }
}

final _InactiveElements _inactiveElements = new _InactiveElements();

typedef void ElementVisitor(Element element);

abstract class BuildContext {
  Widget get widget;
  RenderObject findRenderObject();
  InheritedWidget inheritFromWidgetOfType(Type targetType);
  Widget ancestorWidgetOfType(Type targetType);
  State ancestorStateOfType(Type targetType);
  RenderObject ancestorRenderObjectOfType(Type targetType);
  void visitAncestorElements(bool visitor(Element element));
  void visitChildElements(void visitor(Element element));
}

/// Elements are the instantiations of Widget configurations.
///
/// Elements can, in principle, have children. Only subclasses of
/// RenderObjectElement are allowed to have more than one child.
abstract class Element<T extends Widget> implements BuildContext {
  Element(T widget) : _widget = widget {
    assert(widget != null);
  }

  Element _parent;

  /// Information set by parent to define where this child fits in its parent's
  /// child list.
  ///
  /// Subclasses of Element that only have one child should use null for
  /// the slot for that child.
  dynamic get slot => _slot;
  dynamic _slot;

  /// An integer that is guaranteed to be greater than the parent's, if any.
  /// The element at the root of the tree must have a depth greater than 0.
  int get depth => _depth;
  int _depth;

  /// The configuration for this element.
  T get widget => _widget;
  T _widget;

  bool _active = false;

  RenderObject get renderObject {
    RenderObject result;
    void visit(Element element) {
      assert(result == null); // this verifies that there's only one child
      if (element is RenderObjectElement)
        result = element.renderObject;
      else
        element.visitChildren(visit);
    }
    visit(this);
    return result;
  }

  /// This is used to verify that Element objects move through life in an orderly fashion.
  _ElementLifecycle _debugLifecycleState = _ElementLifecycle.initial;

  /// Calls the argument for each child. Must be overridden by subclasses that support having children.
  void visitChildren(ElementVisitor visitor) { }

  /// Wrapper around visitChildren for BuildContext.
  void visitChildElements(void visitor(Element element)) {
    // don't allow visitChildElements() during build, since children aren't necessarily built yet
    assert(!BuildableElement._debugStateLocked);
    visitChildren(visitor);
  }

  bool detachChild(Element child) => false;

  /// This method is the core of the system.
  ///
  /// It is called each time we are to add, update, or remove a child based on
  /// an updated configuration.
  ///
  /// If the child is null, and the newWidget is not null, then we have a new
  /// child for which we need to create an Element, configured with newWidget.
  ///
  /// If the newWidget is null, and the child is not null, then we need to
  /// remove it because it no longer has a configuration.
  ///
  /// If neither are null, then we need to update the child's configuration to
  /// be the new configuration given by newWidget. If newWidget can be given to
  /// the existing child, then it is so given. Otherwise, the old child needs
  /// to be disposed and a new child created for the new configuration.
  ///
  /// If both are null, then we don't have a child and won't have a child, so
  /// we do nothing.
  ///
  /// The updateChild() method returns the new child, if it had to create one,
  /// or the child that was passed in, if it just had to update the child, or
  /// null, if it removed the child and did not replace it.
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    if (newWidget == null) {
      if (child != null)
        _deactivateChild(child);
      return null;
    }
    if (child != null) {
      if (child.widget == newWidget) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        return child;
      }
      if (_canUpdate(child.widget, newWidget)) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        child.update(newWidget);
        assert(child.widget == newWidget);
        return child;
      }
      _deactivateChild(child);
      assert(child._parent == null);
    }
    return _inflateWidget(newWidget, newSlot);
  }

  static void finalizeTree() {
    _inactiveElements.unmountAll();
    assert(GlobalKey._debugCheckForDuplicates);
    scheduleMicrotask(GlobalKey._notifyListeners);
  }

  /// Called when an Element is given a new parent shortly after having been
  /// created. Use this to initialize state that depends on having a parent. For
  /// state that is independent of the position in the tree, it's better to just
  /// initialize the Element in the constructor.
  void mount(Element parent, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.initial);
    assert(widget != null);
    assert(_parent == null);
    assert(parent == null || parent._debugLifecycleState == _ElementLifecycle.active);
    assert(slot == null);
    assert(depth == null);
    assert(!_active);
    _parent = parent;
    _slot = newSlot;
    _depth = _parent != null ? _parent.depth + 1 : 1;
    _active = true;
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._register(this);
    }
    assert(() { _debugLifecycleState = _ElementLifecycle.active; return true; });
  }

  /// Called when an Element receives a new configuration widget.
  void update(T newWidget) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(newWidget != null);
    assert(newWidget != widget);
    assert(depth != null);
    assert(_active);
    assert(_canUpdate(widget, newWidget));
    _widget = newWidget;
  }

  /// Called by MultiChildRenderObjectElement, and other RenderObjectElement
  /// subclasses that have multiple children, to update the slot of a particular
  /// child when the child is moved in its child list.
  void updateSlotForChild(Element child, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(child != null);
    assert(child._parent == this);
    void visit(Element element) {
      element._updateSlot(newSlot);
      if (element is! RenderObjectElement)
        element.visitChildren(visit);
    }
    visit(child);
  }

  void _updateSlot(dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(_parent != null);
    assert(_parent._debugLifecycleState == _ElementLifecycle.active);
    assert(depth != null);
    _slot = newSlot;
  }

  void _updateDepth() {
    int expectedDepth = _parent.depth + 1;
    if (_depth < expectedDepth) {
      _depth = expectedDepth;
      visitChildren((Element child) {
        child._updateDepth();
      });
    }
  }

  void detachRenderObject() {
    visitChildren((Element child) {
      child.detachRenderObject();
    });
    _slot = null;
  }

  void attachRenderObject(dynamic newSlot) {
    assert(_slot == null);
    visitChildren((Element child) {
      child.attachRenderObject(newSlot);
    });
    _slot = newSlot;
  }

  Element _findAndActivateElement(GlobalKey key, Widget newWidget) {
    Element element = key._currentElement;
    if (element == null)
      return null;
    if (!_canUpdate(element.widget, newWidget))
      return null;
    if (element._parent != null && !element._parent.detachChild(element))
      return null;
    assert(element._parent == null);
    _inactiveElements.remove(element);
    return element;
  }

  Element _inflateWidget(Widget newWidget, dynamic newSlot) {
    Key key = newWidget.key;
    if (key is GlobalKey) {
      Element newChild = _findAndActivateElement(key, newWidget);
      if (newChild != null) {
        assert(newChild._parent == null);
        newChild._parent = this;
        newChild._updateDepth();
        newChild.attachRenderObject(newSlot);
        Element updatedChild = updateChild(newChild, newWidget, newSlot);
        assert(newChild == updatedChild);
        return updatedChild;
      }
    }
    Element newChild = newWidget.createElement();
    newChild.mount(this, newSlot);
    assert(newChild._debugLifecycleState == _ElementLifecycle.active);
    return newChild;
  }

  void _deactivateChild(Element child) {
    assert(child != null);
    assert(child._parent == this);
    child._parent = null;
    child.detachRenderObject();
    _inactiveElements.add(child); // this eventually calls child.deactivate()
  }

  void deactivate() {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(depth != null);
    assert(_active);
    _active = false;
    assert(() { _debugLifecycleState = _ElementLifecycle.inactive; return true; });
  }

  void reactivate() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    assert(widget != null);
    assert(depth != null);
    assert(!_active);
    _active = true;
    assert(() { _debugLifecycleState = _ElementLifecycle.active; return true; });
  }

  /// Called when an Element is removed from the tree permanently.
  void unmount() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    assert(widget != null);
    assert(depth != null);
    assert(!_active);
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._unregister(this);
    }
    assert(() { _debugLifecycleState = _ElementLifecycle.defunct; return true; });
  }

  RenderObject findRenderObject() => renderObject;

  Set<Type> _dependencies;
  InheritedWidget inheritFromWidgetOfType(Type targetType) {
    if (_dependencies == null)
      _dependencies = new Set<Type>();
    _dependencies.add(targetType);
    return ancestorWidgetOfType(targetType);
  }

  Widget ancestorWidgetOfType(Type targetType) {
    Element ancestor = _parent;
    while (ancestor != null && ancestor.widget.runtimeType != targetType)
      ancestor = ancestor._parent;
    return ancestor?.widget;
  }

  State ancestorStateOfType(Type targetType) {
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is StatefulComponentElement && ancestor.state.runtimeType == targetType)
        break;
      ancestor = ancestor._parent;
    }
    StatefulComponentElement statefulAncestor = ancestor;
    return statefulAncestor?.state;
  }

  RenderObject ancestorRenderObjectOfType(Type targetType) {
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is RenderObjectElement && ancestor.renderObject.runtimeType == targetType)
        break;
      ancestor = ancestor._parent;
    }
    RenderObjectElement renderObjectAncestor = ancestor;
    return renderObjectAncestor?.renderObject;
  }

  void visitAncestorElements(bool visitor(Element element)) {
    Element ancestor = _parent;
    while (ancestor != null && visitor(ancestor))
      ancestor = ancestor._parent;
  }

  void dependenciesChanged(Type affectedWidgetType) {
    assert(false);
  }

  String toStringShort() {
    return widget != null ? '${widget.toStringShort()}' : '[$runtimeType]';
  }

  String toString() {
    final List<String> data = <String>[];
    debugFillDescription(data);
    final String name = widget != null ? '${widget.runtimeType}' : '[$runtimeType]';
    return '$name(${data.join("; ")})';
  }

  void debugFillDescription(List<String> description) {
    if (depth == null)
      description.add('no depth');
    if (widget == null) {
      description.add('no widget');
    } else {
      if (widget.key != null)
        description.add('${widget.key}');
      widget.debugFillDescription(description);
    }
  }

  String toStringDeep([String prefixLineOne = '', String prefixOtherLines = '']) {
    String result = '$prefixLineOne$this\n';
    List<Element> children = <Element>[];
    visitChildren(children.add);
    if (children.length > 0) {
      Element last = children.removeLast();
      for (Element child in children)
        result += '${child.toStringDeep("$prefixOtherLines \u251C", "$prefixOtherLines \u2502")}';
      result += '${last.toStringDeep("$prefixOtherLines \u2514", "$prefixOtherLines  ")}';
    }
    return result;
  }
}

class ErrorWidget extends LeafRenderObjectWidget {
  RenderBox createRenderObject() => new RenderErrorBox();
}

typedef void BuildScheduler(BuildableElement element);

/// Base class for instantiations of widgets that have builders and can be
/// marked dirty.
abstract class BuildableElement<T extends Widget> extends Element<T> {
  BuildableElement(T widget) : super(widget);

  /// Returns true if the element has been marked as needing rebuilding.
  bool get dirty => _dirty;
  bool _dirty = true;

  // We let component authors call setState from initState, didUpdateConfig, and
  // build even when state is locked because its convenient and a no-op anyway.
  // This flag ensures that this convenience is only allowed on the element
  // currently undergoing initState, didUpdateConfig, or build.
  bool _debugAllowIgnoredCallsToMarkNeedsBuild = false;
  bool _debugSetAllowIgnoredCallsToMarkNeedsBuild(bool value) {
    assert(_debugAllowIgnoredCallsToMarkNeedsBuild == !value);
    _debugAllowIgnoredCallsToMarkNeedsBuild = value;
    return true;
  }

  static BuildScheduler scheduleBuildFor;

  static int _debugStateLockLevel = 0;
  static bool get _debugStateLocked => _debugStateLockLevel > 0;
  static bool _debugBuilding = false;
  static BuildableElement _debugCurrentBuildTarget;

  /// Establishes a scope in which component build functions can run.
  ///
  /// Inside a build scope, component build functions are allowed to run, but
  /// State.setState() is forbidden. This mechanism prevents build functions
  /// from transitively requiring other build functions to run, potentially
  /// causing infinite loops.
  ///
  /// After unwinding the last build scope on the stack, the framework verifies
  /// that each global key is used at most once and notifies listeners about
  /// changes to global keys.
  static void lockState(void callback(), { bool building: false }) {
    assert(_debugStateLockLevel >= 0);
    assert(() {
      if (building) {
        assert(!_debugBuilding);
        assert(_debugCurrentBuildTarget == null);
        _debugBuilding = true;
      }
      _debugStateLockLevel += 1;
      return true;
    });
    try {
      callback();
    } finally {
      assert(() {
        _debugStateLockLevel -= 1;
        if (building) {
          assert(_debugBuilding);
          assert(_debugCurrentBuildTarget == null);
          _debugBuilding = false;
        }
        return true;
      });
    }
    assert(_debugStateLockLevel >= 0);
  }

  /// Marks the element as dirty and adds it to the global list of widgets to
  /// rebuild in the next frame.
  ///
  /// Since it is inefficient to build an element twice in one frame,
  /// applications and components should be structured so as to only mark
  /// components dirty during event handlers before the frame begins, not during
  /// the build itself.
  void markNeedsBuild() {
    assert(_debugLifecycleState != _ElementLifecycle.defunct);
    if (!_active)
      return;
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(() {
      if (_debugBuilding) {
        bool foundTarget = false;
        visitAncestorElements((Element element) {
          if (element == _debugCurrentBuildTarget) {
            foundTarget = true;
            return false;
          }
          return true;
        });
        if (foundTarget)
          return true;
      }
      return !_debugStateLocked || (_debugAllowIgnoredCallsToMarkNeedsBuild && dirty);
    });
    if (dirty)
      return;
    _dirty = true;
    assert(scheduleBuildFor != null);
    scheduleBuildFor(this);
  }

  /// Called by the binding when scheduleBuild() has been called to mark this
  /// element dirty, and, in Components, by update() when the Widget has
  /// changed.
  void rebuild() {
    assert(_debugLifecycleState != _ElementLifecycle.initial);
    if (!_active || !_dirty) {
      _dirty = false;
      return;
    }
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(_debugStateLocked);
    BuildableElement debugPreviousBuildTarget;
    assert(() {
      debugPreviousBuildTarget = _debugCurrentBuildTarget;
      _debugCurrentBuildTarget = this;
     return true;
    });
    try {
      performRebuild();
    } catch (e, stack) {
      _debugReportException('rebuilding $this', e, stack);
    } finally {
      assert(() {
        assert(_debugCurrentBuildTarget == this);
        _debugCurrentBuildTarget = debugPreviousBuildTarget;
        return true;
      });
    }
    assert(!_dirty);
  }

  /// Called by rebuild() after the appropriate checks have been made.
  void performRebuild();

  void dependenciesChanged(Type affectedWidgetType) {
    markNeedsBuild();
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dirty)
      description.add('dirty');
  }
}

typedef Widget WidgetBuilder(BuildContext context);

/// Base class for the instantiation of StatelessComponent, StatefulComponent,
/// and ProxyComponent widgets.
abstract class ComponentElement<T extends Widget> extends BuildableElement<T> {
  ComponentElement(T widget) : super(widget);

  WidgetBuilder _builder;
  Element _child;

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    assert(_active);
    _firstBuild();
    assert(_child != null);
  }

  void _firstBuild() {
    rebuild();
  }

  /// Reinvokes the build() method of the StatelessComponent object (for
  /// stateless components) or the State object (for stateful components) and
  /// then updates the widget tree.
  ///
  /// Called automatically during mount() to generate the first build, and by
  /// rebuild() when the element needs updating.
  void performRebuild() {
    assert(_debugSetAllowIgnoredCallsToMarkNeedsBuild(true));
    Widget built;
    try {
      built = _builder(this);
      assert(() {
        if (built == null) {
          debugPrint('Widget: $widget');
          assert(() {
            'A build function returned null. Build functions must never return null.'
            'The offending widget is displayed above.';
            return false;
          });
        }
        return true;
      });
    } catch (e, stack) {
      _debugReportException('building $_widget', e, stack);
      built = new ErrorWidget();
    } finally {
      // We delay marking the element as clean until after calling _builder so
      // that attempts to markNeedsBuild() during build() will be ignored.
      _dirty = false;
      assert(_debugSetAllowIgnoredCallsToMarkNeedsBuild(false));
    }
    try {
      _child = updateChild(_child, built, slot);
      assert(_child != null);
    } catch (e, stack) {
      _debugReportException('building $_widget', e, stack);
      built = new ErrorWidget();
      _child = updateChild(null, built, slot);
    }
  }

  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  bool detachChild(Element child) {
    assert(child == _child);
    _deactivateChild(_child);
    _child = null;
    return true;
  }
}

/// Instantiation of StatelessComponent widgets.
class StatelessComponentElement<T extends StatelessComponent> extends ComponentElement<T> {
  StatelessComponentElement(T widget) : super(widget) {
    _builder = widget.build;
  }

  void update(T newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _builder = widget.build;
    _dirty = true;
    rebuild();
  }
}

/// Instantiation of StatefulComponent widgets.
class StatefulComponentElement<T extends StatefulComponent, U extends State<T>> extends ComponentElement<T> {
  StatefulComponentElement(T widget)
    : _state = widget.createState(), super(widget) {
    assert(_state._debugTypesAreRight(widget)); // can't use T and U, since normally we don't actually set those
    assert(_state._element == null);
    _state._element = this;
    assert(_builder == null);
    _builder = _state.build;
    assert(_state._config == null);
    _state._config = widget;
    assert(_state._debugLifecycleState == _StateLifecycle.created);
  }

  U get state => _state;
  U _state;

  void _firstBuild() {
    assert(_state._debugLifecycleState == _StateLifecycle.created);
    try {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(true);
      _state.initState();
    } finally {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(false);
    }
    assert(() {
      if (_state._debugLifecycleState == _StateLifecycle.initialized)
        return true;
      debugPrint('${_state.runtimeType}.initState failed to call super.initState');
      return false;
    });
    assert(() { _state._debugLifecycleState = _StateLifecycle.ready; return true; });
    super._firstBuild();
  }

  void update(T newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    StatefulComponent oldConfig = _state._config;
    // Notice that we mark ourselves as dirty before calling didUpdateConfig to
    // let authors call setState from within didUpdateConfig without triggering
    // asserts.
    _dirty = true;
    _state._config = widget;
    try {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(true);
      _state.didUpdateConfig(oldConfig);
    } finally {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(false);
    }
    rebuild();
  }

  void deactivate() {
    _state.deactivate();
    super.deactivate();
  }

  void unmount() {
    super.unmount();
    _state.dispose();
    assert(() {
      if (_state._debugLifecycleState == _StateLifecycle.defunct)
        return true;
      debugPrint('${_state.runtimeType}.dispose failed to call super.dispose');
      return false;
    });
    assert(!dirty); // See BuildableElement.unmount for why this is important.
    _state._element = null;
    _state = null;
  }

  void dependenciesChanged(Type affectedWidgetType) {
    super.dependenciesChanged(affectedWidgetType);
    _state.dependenciesChanged(affectedWidgetType);
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (state != null)
      description.add('state: $state');
  }
}

abstract class ProxyElement<T extends ProxyComponent> extends ComponentElement<T> {
  ProxyElement(T widget) : super(widget) {
    _builder = (BuildContext context) => this.widget.child;
  }

  void update(T newWidget) {
    T oldWidget = widget;
    assert(widget != null);
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    notifyDescendants(oldWidget);
    _dirty = true;
    rebuild();
  }

  void notifyDescendants(T oldWidget);
}

class ParentDataElement extends ProxyElement<ParentDataWidget> {
  ParentDataElement(ParentDataWidget widget) : super(widget);

  void mount(Element parent, dynamic slot) {
    assert(() {
      Element ancestor = parent;
      while (ancestor is! RenderObjectElement) {
        assert(ancestor != null);
        assert(() {
          'You cannot nest parent data widgets inside one another.';
          return ancestor is! ParentDataElement;
        });
        ancestor = ancestor._parent;
      }
      _widget.debugValidateAncestor(ancestor._widget);
      return true;
    });
    super.mount(parent, slot);
  }

  void notifyDescendants(ParentDataWidget oldWidget) {
    void notifyChildren(Element child) {
      if (child is RenderObjectElement)
        child.updateParentData(widget);
      else if (child is! ParentDataElement)
        child.visitChildren(notifyChildren);
    }
    visitChildren(notifyChildren);
  }
}



class InheritedElement extends ProxyElement<InheritedWidget> {
  InheritedElement(InheritedWidget widget) : super(widget);

  void notifyDescendants(InheritedWidget oldWidget) {
    if (!widget.updateShouldNotify(oldWidget))
      return;
    final Type ourRuntimeType = widget.runtimeType;
    void notifyChildren(Element child) {
      if (child._dependencies != null &&
          child._dependencies.contains(ourRuntimeType)) {
        child.dependenciesChanged(ourRuntimeType);
      }
      if (child.runtimeType != ourRuntimeType)
        child.visitChildren(notifyChildren);
    }
    visitChildren(notifyChildren);
  }
}

/// Base class for instantiations of RenderObjectWidget subclasses
abstract class RenderObjectElement<T extends RenderObjectWidget> extends BuildableElement<T> {
  RenderObjectElement(T widget)
    : _renderObject = widget.createRenderObject(), super(widget) {
    assert(() { debugUpdateRenderObjectOwner(); return true; });
  }

  /// The underlying [RenderObject] for this element
  RenderObject get renderObject => _renderObject;
  final RenderObject _renderObject;

  RenderObjectElement _ancestorRenderObjectElement;

  RenderObjectElement _findAncestorRenderObjectElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement)
      ancestor = ancestor._parent;
    return ancestor;
  }

  ParentDataElement _findAncestorParentDataElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      if (ancestor is ParentDataElement)
        return ancestor;
      ancestor = ancestor._parent;
    }
    return null;
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_slot == newSlot);
    attachRenderObject(newSlot);
    _dirty = false;
  }

  void update(T newWidget) {
    T oldWidget = widget;
    super.update(newWidget);
    assert(widget == newWidget);
    assert(() { debugUpdateRenderObjectOwner(); return true; });
    widget.updateRenderObject(renderObject, oldWidget);
    _dirty = false;
  }

  void debugUpdateRenderObjectOwner() {
    List<String> chain = <String>[];
    Element node = this;
    while (chain.length < 4 && node != null) {
      chain.add(node.toStringShort());
      node = node._parent;
    }
    if (node != null)
      chain.add('\u22EF');
    _renderObject.debugOwner = chain.join(' \u2190 ');
  }

  void performRebuild() {
    reinvokeBuilders();
    _dirty = false;
  }

  void reinvokeBuilders() {
    // There's no way to mark a normal RenderObjectElement dirty.
    // We inherit from BuildableElement so that subclasses can themselves
    // implement reinvokeBuilders() if they do provide a way to mark themeselves
    // dirty, e.g. if they have a builder callback. (Builder callbacks have a
    // 'BuildContext' argument which you can pass to Theme.of() and other
    // InheritedWidget APIs which eventually trigger a rebuild.)
    debugPrint('$runtimeType failed to implement reinvokeBuilders(), but got marked dirty');
    assert(() {
      'reinvokeBuilders() not implemented';
      return false;
    });
  }

  /// Utility function for subclasses that have one or more lists of children.
  /// Attempts to update the given old children list using the given new
  /// widgets, removing obsolete elements and introducing new ones as necessary,
  /// and then returns the new child list.
  List<Element> updateChildren(List<Element> oldChildren, List<Widget> newWidgets) {
    assert(oldChildren != null);
    assert(newWidgets != null);

    // This attempts to diff the new child list (this.children) with
    // the old child list (old.children), and update our renderObject
    // accordingly.

    // The cases it tries to optimise for are:
    //  - the old list is empty
    //  - the lists are identical
    //  - there is an insertion or removal of one or more widgets in
    //    only one place in the list
    // If a widget with a key is in both lists, it will be synced.
    // Widgets without keys might be synced but there is no guarantee.

    // The general approach is to sync the entire new list backwards, as follows:
    // 1. Walk the lists from the top until you no longer have
    //    matching nodes. We don't sync these yet, but we now know to
    //    skip them below. We do this because at each sync we need to
    //    pass the pointer to the new next widget as the slot, which
    //    we can't do until we've synced the next child.
    // 2. Walk the lists from the bottom, syncing nodes, until you no
    //    longer have matching nodes.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys and sync null with non-keyed items.
    // 4. Walk the narrowed part of the new list backwards:
    //     * Sync unkeyed items with null
    //     * Sync keyed items with the source if it exists, else with null.
    // 5. Walk the top list again but backwards, syncing the nodes.
    // 6. Sync null with any items in the list of keys that are still
    //    mounted.

    int childrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    // top of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Element oldChild = oldChildren[childrenTop];
      Widget newWidget = newWidgets[childrenTop];
      assert(oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (!_canUpdate(oldChild.widget, newWidget))
        break;
      childrenTop += 1;
    }

    List<Element> newChildren = oldChildren.length == newWidgets.length ?
        oldChildren : new List<Element>(newWidgets.length);

    Element nextSibling;

    // bottom of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Element oldChild = oldChildren[oldChildrenBottom];
      Widget newWidget = newWidgets[newChildrenBottom];
      assert(oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (!_canUpdate(oldChild.widget, newWidget))
        break;
      Element newChild = updateChild(oldChild, newWidget, nextSibling);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenBottom] = newChild;
      nextSibling = newChild;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // middle of the lists - old list
    bool haveOldNodes = childrenTop <= oldChildrenBottom;
    Map<Key, Element> oldKeyedChildren;
    if (haveOldNodes) {
      oldKeyedChildren = new Map<Key, Element>();
      while (childrenTop <= oldChildrenBottom) {
        Element oldChild = oldChildren[oldChildrenBottom];
        assert(oldChild._debugLifecycleState == _ElementLifecycle.active);
        if (oldChild.widget.key != null)
          oldKeyedChildren[oldChild.widget.key] = oldChild;
        else
          _deactivateChild(oldChild);
        oldChildrenBottom -= 1;
      }
    }

    // middle of the lists - new list
    while (childrenTop <= newChildrenBottom) {
      Element oldChild;
      Widget newWidget = newWidgets[newChildrenBottom];
      if (haveOldNodes) {
        Key key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[newWidget.key];
          if (oldChild != null) {
            if (_canUpdate(oldChild.widget, newWidget)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Not a match, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || _canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, nextSibling);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenBottom] = newChild;
      nextSibling = newChild;
      newChildrenBottom -= 1;
    }
    assert(oldChildrenBottom == newChildrenBottom);
    assert(childrenTop == newChildrenBottom + 1);

    // now sync the top of the list
    while (childrenTop > 0) {
      childrenTop -= 1;
      Element oldChild = oldChildren[childrenTop];
      assert(oldChild._debugLifecycleState == _ElementLifecycle.active);
      Widget newWidget = newWidgets[childrenTop];
      assert(_canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, nextSibling);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[childrenTop] = newChild;
      nextSibling = newChild;
    }

    // clean up any of the remaining middle nodes from the old list
    if (haveOldNodes && !oldKeyedChildren.isEmpty) {
      for (Element oldChild in oldKeyedChildren.values)
        _deactivateChild(oldChild);
    }

    return newChildren;
  }

  void deactivate() {
    super.deactivate();
    assert(!renderObject.attached);
  }

  void unmount() {
    super.unmount();
    assert(!renderObject.attached);
    widget.didUnmountRenderObject(renderObject);
  }

  void updateParentData(ParentDataWidget parentData) {
    parentData.applyParentData(renderObject);
  }

  void _updateSlot(dynamic newSlot) {
    assert(slot != newSlot);
    super._updateSlot(newSlot);
    assert(slot == newSlot);
    _ancestorRenderObjectElement.moveChildRenderObject(renderObject, slot);
  }

  void attachRenderObject(dynamic newSlot) {
    assert(_ancestorRenderObjectElement == null);
    _slot = newSlot;
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    _ancestorRenderObjectElement?.insertChildRenderObject(renderObject, newSlot);
    ParentDataElement parentDataElement = _findAncestorParentDataElement();
    if (parentDataElement != null)
      updateParentData(parentDataElement.widget);
  }

  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement.removeChildRenderObject(renderObject);
      _ancestorRenderObjectElement = null;
    }
    _slot = null;
  }

  void insertChildRenderObject(RenderObject child, dynamic slot);
  void moveChildRenderObject(RenderObject child, dynamic slot);
  void removeChildRenderObject(RenderObject child);

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (renderObject != null)
      description.add('renderObject: $renderObject');
  }
}

/// Instantiation of RenderObjectWidgets that have no children
class LeafRenderObjectElement<T extends RenderObjectWidget> extends RenderObjectElement<T> {
  LeafRenderObjectElement(T widget): super(widget);

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
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

  bool detachChild(Element child) {
    assert(child == _child);
    _deactivateChild(_child);
    _child = null;
    return true;
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, null);
  }

  void update(T newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, null);
  }

  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin renderObject = this.renderObject;
    assert(slot == null);
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  void removeChildRenderObject(RenderObject child) {
    final RenderObjectWithChildMixin renderObject = this.renderObject;
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

/// Instantiation of RenderObjectWidgets that can have a list of children
class MultiChildRenderObjectElement<T extends MultiChildRenderObjectWidget> extends RenderObjectElement<T> {
  MultiChildRenderObjectElement(T widget) : super(widget) {
    assert(!_debugHasDuplicateIds());
  }

  List<Element> _children;

  void insertChildRenderObject(RenderObject child, Element slot) {
    final ContainerRenderObjectMixin renderObject = this.renderObject;
    final RenderObject nextSibling = slot?.renderObject;
    renderObject.add(child, before: nextSibling);
    assert(renderObject == this.renderObject);
  }

  void moveChildRenderObject(RenderObject child, dynamic slot) {
    final ContainerRenderObjectMixin renderObject = this.renderObject;
    final RenderObject nextSibling = slot?.renderObject;
    renderObject.move(child, before: nextSibling);
    assert(renderObject == this.renderObject);
  }

  void removeChildRenderObject(RenderObject child) {
    final ContainerRenderObjectMixin renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  bool _debugHasDuplicateIds() {
    var idSet = new HashSet<Key>();
    for (Widget child in widget.children) {
      assert(child != null);
      if (child.key == null)
        continue; // when these nodes are reordered, we just reassign the data

      if (!idSet.add(child.key)) {
        throw 'If multiple keyed nodes exist as children of another node, they must have unique keys. $widget has multiple children with key "${child.key}".';
      }
    }
    return false;
  }

  void visitChildren(ElementVisitor visitor) {
    for (Element child in _children)
      visitor(child);
  }

  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = new List<Element>(widget.children.length);
    Element previousChild;
    for (int i = _children.length - 1; i >= 0; --i) {
      Element newChild = _inflateWidget(widget.children[i], previousChild);
      _children[i] = newChild;
      previousChild = newChild;
    }
  }

  void update(T newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _children = updateChildren(_children, widget.children);
  }
}

typedef void WidgetsExceptionHandler(String context, dynamic exception, StackTrace stack);
/// This callback is invoked whenever an exception is caught by the widget
/// system. The 'context' argument is a description of what was happening when
/// the exception occurred, and may include additional details such as
/// descriptions of the objects involved. The 'exception' argument contains the
/// object that was thrown, and the 'stack' argument contains the stack trace.
/// If no callback is set, then a default behaviour consisting of dumping the
/// context, exception, and stack trace to the console is used instead.
WidgetsExceptionHandler debugWidgetsExceptionHandler;
void _debugReportException(String context, dynamic exception, StackTrace stack) {
  if (debugWidgetsExceptionHandler != null) {
    debugWidgetsExceptionHandler(context, exception, stack);
  } else {
    debugPrint('------------------------------------------------------------------------');
    debugPrint('Exception caught while $context');
    debugPrint('$exception');
    debugPrint('Stack trace:');
    debugPrint('$stack');
    debugPrint('------------------------------------------------------------------------');
  }
}
