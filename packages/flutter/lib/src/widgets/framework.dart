// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'debug.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

export 'dart:ui' show hashValues, hashList;
export 'package:flutter/rendering.dart' show RenderObject, RenderBox, debugPrint;
export 'package:flutter/foundation.dart' show FlutterError;

// KEYS

/// A Key is an identifier for [Widget]s and [Element]s. A new Widget will only
/// be used to reconfigure an existing Element if its Key is the same as its
/// original Widget's Key.
///
/// Keys must be unique amongst the Elements with the same parent.
///
/// Subclasses of Key should either subclass [LocalKey] or [GlobalKey].
abstract class Key {
  /// Construct a ValueKey<String> with the given String.
  /// This is the simplest way to create keys.
  factory Key(String value) => new ValueKey<String>(value);

  /// Default constructor, used by subclasses.
  const Key.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor
}

/// A key that is not a [GlobalKey].
abstract class LocalKey extends Key {
  /// Default constructor, used by subclasses.
  const LocalKey() : super.constructor();
}

/// A kind of [Key] that uses a value of a particular type to identify itself.
///
/// For example, a ValueKey<String> is equal to another ValueKey<String> if
/// their values match.
class ValueKey<T> extends LocalKey {
  const ValueKey(this.value);

  final T value;

  @override
  bool operator ==(dynamic other) {
    if (other is! ValueKey<T>)
      return false;
    final ValueKey<T> typedOther = other;
    return value == typedOther.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '[\'$value\']';
}

/// A [Key] that is only equal to itself.
class UniqueKey extends LocalKey {
  const UniqueKey();

  @override
  String toString() => '[$hashCode]';
}

/// A kind of [Key] that takes its identity from the object used as its value.
///
/// Used to tie the identity of a Widget to the identity of an object used to
/// generate that Widget.
class ObjectKey extends LocalKey {
  const ObjectKey(this.value);

  final Object value;

  @override
  bool operator ==(dynamic other) {
    if (other is! ObjectKey)
      return false;
    final ObjectKey typedOther = other;
    return identical(value, typedOther.value);
  }

  @override
  int get hashCode => identityHashCode(value);

  @override
  String toString() => '[${value.runtimeType}(${value.hashCode})]';
}

typedef void GlobalKeyRemoveListener(GlobalKey key);

/// A GlobalKey is a [Key] that must be unique across the widget tree.
///
/// Global keys uniquely indentify widget subtrees.  The GlobalKey object provides
/// access to other objects that are associated with the subtree, such as the subtree's
/// [BuildContext] and, for [StatefulWidget]s, the subtree's [State].
///
/// Widgets that have global keys reparent their subtrees when they are moved
/// from one location in the tree to another location in the tree. In order to
/// reparent its subtree, a widget must arrive at its new location in the tree
/// in the same animation frame in which it was removed from its old location in
/// the tree.
///
/// GlobalKeys are relatively expensive. If you don't need any of the features
/// listed above, consider using a [Key], [ValueKey], [ObjectKey], or
/// [UniqueKey] instead.
@optionalTypeArgs
abstract class GlobalKey<T extends State<StatefulWidget>> extends Key {
  /// Constructs a LabeledGlobalKey, which is a GlobalKey with a label used for debugging.
  /// The label is not used for comparing the identity of the key.
  factory GlobalKey({ String debugLabel }) => new LabeledGlobalKey<T>(debugLabel); // the label is purely for debugging purposes and is otherwise ignored

  const GlobalKey.constructor() : super.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor

  static final Map<GlobalKey, Element> _registry = new Map<GlobalKey, Element>();
  static final Map<GlobalKey, int> _debugDuplicates = new Map<GlobalKey, int>();
  static final Map<GlobalKey, Set<GlobalKeyRemoveListener>> _removeListeners = new Map<GlobalKey, Set<GlobalKeyRemoveListener>>();
  static final Set<GlobalKey> _removedKeys = new HashSet<GlobalKey>();

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
    if (element is StatefulElement) {
      StatefulElement statefulElement = element;
      return statefulElement.state;
    }
    return null;
  }

  static void registerRemoveListener(GlobalKey key, GlobalKeyRemoveListener listener) {
    assert(key != null);
    Set<GlobalKeyRemoveListener> listeners =
        _removeListeners.putIfAbsent(key, () => new HashSet<GlobalKeyRemoveListener>());
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
      message += 'The following GlobalKey was found multiple times among mounted elements: $key (${_debugDuplicates[key]} instances)\n';
      message += 'The most recently registered instance is: ${_registry[key]}\n';
    }
    if (_debugDuplicates.isNotEmpty) {
      throw new FlutterError(
        'Incorrect GlobalKey usage.\n'
        '$message'
      );
    }
    return true;
  }

  static void _notifyListeners() {
    if (_removedKeys.isEmpty)
      return;
    try {
      for (GlobalKey key in _removedKeys) {
        if (!_registry.containsKey(key) && _removeListeners.containsKey(key)) {
          Set<GlobalKeyRemoveListener> localListeners = new HashSet<GlobalKeyRemoveListener>.from(_removeListeners[key]);
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
class LabeledGlobalKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  const LabeledGlobalKey(this._debugLabel) : super.constructor();

  final String _debugLabel;

  @override
  String toString() => '[GlobalKey ${_debugLabel != null ? _debugLabel : hashCode}]';
}

/// A kind of [GlobalKey] that takes its identity from the object used as its value.
///
/// Used to tie the identity of a Widget to the identity of an object used to
/// generate that Widget.
class GlobalObjectKey extends GlobalKey {
  const GlobalObjectKey(this.value) : super.constructor();
  final Object value;

  @override
  bool operator ==(dynamic other) {
    if (other is! GlobalObjectKey)
      return false;
    final GlobalObjectKey typedOther = other;
    return identical(value, typedOther.value);
  }

  @override
  int get hashCode => identityHashCode(value);

  @override
  String toString() => '[$runtimeType ${value.runtimeType}(${value.hashCode})]';
}

/// This class is a work-around for the "is" operator not accepting a variable value as its right operand
@optionalTypeArgs
class TypeMatcher<T> {
  const TypeMatcher();
  bool check(dynamic object) => object is T;
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

  @override
  String toString() {
    final String name = toStringShort();
    final List<String> data = <String>[];
    debugFillDescription(data);
    if (data.isEmpty)
      return '$name';
    return '$name(${data.join("; ")})';
  }

  void debugFillDescription(List<String> description) { }

  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType &&
      oldWidget.key == newWidget.key;
  }
}

/// StatelessWidgets describe a way to compose other Widgets to form reusable
/// parts, which doesn't depend on anything other than the configuration
/// information in the object itself. (For compositions that can change
/// dynamically, e.g. due to having an internal clock-driven state, or depending
/// on some system state, use [StatefulWidget].)
abstract class StatelessWidget extends Widget {
  const StatelessWidget({ Key key }) : super(key: key);

  /// StatelessWidget always use [StatelessElement]s to represent
  /// themselves in the Element tree.
  @override
  StatelessElement createElement() => new StatelessElement(this);

  /// Returns another Widget out of which this StatelessWidget is built.
  /// Typically that Widget will have been configured with further children,
  /// such that really this function returns a tree of configuration.
  ///
  /// The given build context object contains information about the location in
  /// the tree at which this widget is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree.
  Widget build(BuildContext context);
}

/// StatefulWidgets provide the configuration for
/// [StatefulElement]s, which wrap [State]s, which hold mutable state
/// and can dynamically and spontaneously ask to be rebuilt.
abstract class StatefulWidget extends Widget {
  const StatefulWidget({ Key key }) : super(key: key);

  /// StatefulWidget always use [StatefulElement]s to represent
  /// themselves in the Element tree.
  @override
  StatefulElement createElement() => new StatefulElement(this);

  /// Returns an instance of the state to which this StatefulWidget is
  /// related, using this object as the configuration. Subclasses should
  /// override this to return a new instance of the State class associated with
  /// this StatefulWidget class, like this:
  ///
  ///   _MyState createState() => new _MyState();
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

/// The logic and internal state for a [StatefulWidget].
@optionalTypeArgs
abstract class State<T extends StatefulWidget> {
  /// The current configuration (an instance of the corresponding
  /// [StatefulWidget] class).
  T get config => _config;
  T _config;

  /// This is used to verify that State objects move through life in an orderly fashion.
  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  /// Verifies that the State that was created is one that expects to be created
  /// for that particular Widget.
  bool _debugTypesAreRight(Widget widget) => widget is T;

  /// Pointer to the owner Element object
  StatefulElement _element;

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
  /// widget will not be scheduled for rebuilding, meaning that its rendering
  /// will not be updated.
  void setState(VoidCallback fn) {
    assert(() {
      if (_debugLifecycleState == _StateLifecycle.defunct) {
        throw new FlutterError(
          'setState() called after dispose(): $this\n'
          'This error happens if you call setState() on State object for a widget that '
          'no longer appears in the widget tree (e.g., whose parent widget no longer '
          'includes the widget in its build). This error can occur when code calls '
          'setState() from a timer or an animation callback. The preferred solution is '
          'to cancel the timer or stop listening to the animation in the dispose() '
          'callback. Another solution is to check the "mounted" property of this '
          'object before calling setState() to ensure the object is still in the '
          'tree.\n'
          '\n'
          'This error might indicate a memory leak if setState() is being called '
          'because another object is retaining a reference to this State object '
          'after it has been removed from the tree. To avoid memory leaks, '
          'consider breaking the reference to this object during dipose().'
        );
      }
      return true;
    });
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

  /// Returns another Widget out of which this [StatefulWidget] is built.
  /// Typically that Widget will have been configured with further children,
  /// such that really this function returns a tree of configuration.
  ///
  /// The given build context object contains information about the location in
  /// the tree at which this widget is being built. For example, the context
  /// provides the set of inherited widgets for this location in the tree.
  Widget build(BuildContext context);

  /// Called when an Inherited widget in the ancestor chain has changed. Usually
  /// there is nothing to do here; whenever this is called, build() is also
  /// called.
  void dependenciesChanged(Type affectedWidgetType) { }

  @override
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

abstract class _ProxyWidget extends Widget {
  const _ProxyWidget({ Key key, this.child }) : super(key: key);

  final Widget child;
}

abstract class ParentDataWidget<T extends RenderObjectWidget> extends _ProxyWidget {
  const ParentDataWidget({ Key key, Widget child })
    : super(key: key, child: child);

  @override
  ParentDataElement<T> createElement() => new ParentDataElement<T>(this);

  /// Subclasses should override this function to return true if the given
  /// ancestor is a RenderObjectWidget that wraps a RenderObject that can handle
  /// the kind of ParentData widget that the ParentDataWidget subclass handles.
  ///
  /// The default implementation uses the type argument.
  bool debugIsValidAncestor(RenderObjectWidget ancestor) {
    assert(T != dynamic);
    assert(T != RenderObjectWidget);
    return ancestor is T;
  }

  /// Subclasses should override this to describe the requirements for using the
  /// ParentDataWidget subclass. It is called when debugIsValidAncestor()
  /// returned false for an ancestor, or when there are extraneous
  /// ParentDataWidgets in the ancestor chain.
  String debugDescribeInvalidAncestorChain({ String description, String ownershipChain, bool foundValidAncestor, Iterable<Widget> badAncestors }) {
    assert(T != dynamic);
    assert(T != RenderObjectWidget);
    String result;
    if (!foundValidAncestor) {
      result = '$runtimeType widgets must be placed inside $T widgets.\n'
               '$description has no $T ancestor at all.\n';
    } else {
      assert(badAncestors.isNotEmpty);
      result = '$runtimeType widgets must be placed directly inside $T widgets.\n'
               '$description has a $T ancestor, but there are other widgets between them:\n';
      for (Widget ancestor in badAncestors) {
        if (ancestor.runtimeType == runtimeType) {
          result += '  $ancestor (this is a different $runtimeType than the one with the problem)\n';
        } else {
          result += '  $ancestor\n';
        }
      }
      result += 'These widgets cannot come between a $runtimeType and its $T.\n';
    }
    result += 'The ownership chain for the parent of the offending $runtimeType was:\n  $ownershipChain';
    return result;
  }

  void applyParentData(RenderObject renderObject);
}

abstract class InheritedWidget extends _ProxyWidget {
  const InheritedWidget({ Key key, Widget child })
    : super(key: key, child: child);

  @override
  InheritedElement createElement() => new InheritedElement(this);

  bool updateShouldNotify(InheritedWidget oldWidget);
}

/// RenderObjectWidgets provide the configuration for [RenderObjectElement]s,
/// which wrap [RenderObject]s, which provide the actual rendering of the
/// application.
abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget({ Key key }) : super(key: key);

  /// RenderObjectWidgets always inflate to a RenderObjectElement subclass.
  @override
  RenderObjectElement createElement();

  /// Constructs an instance of the RenderObject class that this
  /// RenderObjectWidget represents, using the configuration described by this
  /// RenderObjectWidget.
  RenderObject createRenderObject(BuildContext context);

  /// Copies the configuration described by this RenderObjectWidget to the given
  /// RenderObject, which must be of the same type as returned by this class'
  /// createRenderObject(BuildContext context).
  void updateRenderObject(BuildContext context, RenderObject renderObject) { }

  void didUnmountRenderObject(RenderObject renderObject) { }
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have no children.
abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget({ Key key }) : super(key: key);

  @override
  LeafRenderObjectElement createElement() => new LeafRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single child slot. (This superclass only provides the storage
/// for that child, it doesn't actually provide the updating logic.)
abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  const SingleChildRenderObjectWidget({ Key key, this.child }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  SingleChildRenderObjectElement createElement() => new SingleChildRenderObjectElement(this);
}

/// A superclass for RenderObjectWidgets that configure RenderObject subclasses
/// that have a single list of children. (This superclass only provides the
/// storage for that child list, it doesn't actually provide the updating
/// logic.)
abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  MultiChildRenderObjectWidget({ Key key, this.children })
    : super(key: key) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  final List<Widget> children;

  @override
  MultiChildRenderObjectElement createElement() => new MultiChildRenderObjectElement(this);
}


// ELEMENTS

enum _ElementLifecycle {
  initial,
  active,
  inactive,
  defunct,
}

class _InactiveElements {
  bool _locked = false;
  final Set<Element> _elements = new HashSet<Element>();

  void _unmount(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.unmount();
    assert(element._debugLifecycleState == _ElementLifecycle.defunct);
    element.visitChildren((Element child) {
      assert(child._parent == element);
      _unmount(child);
    });
  }

  void _unmountAll() {
    try {
      _locked = true;
      for (Element element in _elements)
        _unmount(element);
    } finally {
      _elements.clear();
      _locked = false;
    }
  }

  void _deactivateRecursively(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.deactivate();
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.visitChildren(_deactivateRecursively);
    assert(() { element.debugDeactivated(); return true; });
  }

  void add(Element element) {
    assert(!_locked);
    assert(!_elements.contains(element));
    assert(element._parent == null);
    if (element._active)
      _deactivateRecursively(element);
    _elements.add(element);
  }

  void remove(Element element) {
    assert(!_locked);
    assert(_elements.contains(element));
    assert(element._parent == null);
    _elements.remove(element);
    assert(!element._active);
  }
}

/// Signature for the callback to [BuildContext.visitChildElements].
///
/// The argument is the child being visited.
///
/// It is safe to call `element.visitChildElements` reentrantly within
/// this callback.
typedef void ElementVisitor(Element element);

abstract class BuildContext {
  Widget get widget;
  RenderObject findRenderObject();
  InheritedWidget inheritFromWidgetOfExactType(Type targetType);
  Widget ancestorWidgetOfExactType(Type targetType);
  State ancestorStateOfType(TypeMatcher matcher);
  RenderObject ancestorRenderObjectOfType(TypeMatcher matcher);
  void visitAncestorElements(bool visitor(Element element));
  void visitChildElements(ElementVisitor visitor);
}

class BuildOwner {
  BuildOwner({ this.onBuildScheduled });

  /// Called on each build pass when the first buildable element is marked dirty
  VoidCallback onBuildScheduled;

  final _InactiveElements _inactiveElements = new _InactiveElements();

  final List<BuildableElement> _dirtyElements = <BuildableElement>[];

  /// Adds an element to the dirty elements list so that it will be rebuilt
  /// when buildDirtyElements is called.
  void scheduleBuildFor(BuildableElement element) {
    assert(!_dirtyElements.contains(element));
    assert(element.dirty);
    if (_dirtyElements.isEmpty && onBuildScheduled != null)
      onBuildScheduled();
    _dirtyElements.add(element);
  }

  int _debugStateLockLevel = 0;
  bool get _debugStateLocked => _debugStateLockLevel > 0;
  bool _debugBuilding = false;
  BuildableElement _debugCurrentBuildTarget;

  /// Establishes a scope in which calls to [State.setState] are forbidden.
  ///
  /// This mechanism prevents build functions from transitively requiring other
  /// build functions to run, potentially causing infinite loops.
  ///
  /// If the building argument is true, then this function enables additional
  /// asserts that check invariants that should apply during building.
  ///
  /// The context argument is used to describe the scope in case an exception is
  /// caught while invoking the callback.
  void lockState(void callback(), { bool building: false }) {
    bool debugPreviouslyBuilding;
    assert(_debugStateLockLevel >= 0);
    assert(() {
      if (building) {
        debugPreviouslyBuilding = _debugBuilding;
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
          _debugBuilding = debugPreviouslyBuilding;
        }
        return true;
      });
    }
    assert(_debugStateLockLevel >= 0);
  }

  static int _elementSort(BuildableElement a, BuildableElement b) {
    if (a.depth < b.depth)
      return -1;
    if (b.depth < a.depth)
      return 1;
    if (b.dirty && !a.dirty)
      return -1;
    if (a.dirty && !b.dirty)
      return 1;
    return 0;
  }

  /// Builds all the elements that were marked as dirty using schedule(), in depth order.
  /// If elements are marked as dirty while this runs, they must be deeper than the algorithm
  /// has yet reached.
  /// This is called by beginFrame().
  void buildDirtyElements() {
    if (_dirtyElements.isEmpty)
      return;
    Timeline.startSync('Build');
    try {
      lockState(() {
        _dirtyElements.sort(_elementSort);
        int dirtyCount = _dirtyElements.length;
        int index = 0;
        while (index < dirtyCount) {
          _dirtyElements[index].rebuild();
          index += 1;
          if (dirtyCount < _dirtyElements.length) {
            _dirtyElements.sort(_elementSort);
            dirtyCount = _dirtyElements.length;
          }
        }
        assert(!_dirtyElements.any((BuildableElement element) => element.dirty));
      }, building: true);
    } finally {
      _dirtyElements.clear();
      Timeline.finishSync();
    }
  }

  /// Complete the element build pass by unmounting any elements that are no
  /// longer active.
  ///
  /// This is called by beginFrame().
  ///
  /// In checked mode, this also verifies that each global key is used at most
  /// once.
  ///
  /// After the current call stack unwinds, a microtask that notifies listeners
  /// about changes to global keys will run.
  void finalizeTree() {
    Timeline.startSync('Finalize tree');
    try {
      lockState(() {
        _inactiveElements._unmountAll();
      });
      assert(GlobalKey._debugCheckForDuplicates);
      scheduleMicrotask(GlobalKey._notifyListeners);
    } catch (e, stack) {
      _debugReportException('while finalizing the widget tree', e, stack);
    } finally {
      Timeline.finishSync();
    }
  }

  /// Cause the entire subtree rooted at the given [Element] to
  /// be entirely rebuilt. This is used by development tools when
  /// the application code has changed, to cause the widget tree to
  /// pick up any changed implementations.
  ///
  /// This is expensive and should not be called except during
  /// development.
  void reassemble(Element root) {
    assert(root._parent == null);
    assert(root.owner == this);
    root._reassemble();
  }
}

/// Elements are the instantiations of Widget configurations.
///
/// Elements can, in principle, have children. Only subclasses of
/// RenderObjectElement are allowed to have more than one child.
abstract class Element implements BuildContext {
  Element(Widget widget) : _widget = widget {
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
  @override
  Widget get widget => _widget;
  Widget _widget;

  /// The owner for this node (null if unattached).
  BuildOwner get owner => _owner;
  BuildOwner _owner;

  bool _active = false;

  void _reassemble() {
    assert(_active);
    visitChildren((Element child) {
      child._reassemble();
    });
  }

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
  @override
  void visitChildElements(void visitor(Element element)) {
    // don't allow visitChildElements() during build, since children aren't necessarily built yet
    assert(owner == null || !owner._debugStateLocked);
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
        deactivateChild(child);
      return null;
    }
    if (child != null) {
      if (child.widget == newWidget) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        return child;
      }
      if (Widget.canUpdate(child.widget, newWidget)) {
        if (child.slot != newSlot)
          updateSlotForChild(child, newSlot);
        child.update(newWidget);
        assert(child.widget == newWidget);
        return child;
      }
      deactivateChild(child);
      assert(child._parent == null);
    }
    return inflateWidget(newWidget, newSlot);
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
    if (parent != null) // Only assign ownership if the parent is non-null
      _owner = parent.owner;
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._register(this);
    }
    _updateInheritance();
    assert(() { _debugLifecycleState = _ElementLifecycle.active; return true; });
  }

  /// Called when an Element receives a new configuration widget.
  void update(Widget newWidget) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(newWidget != null);
    assert(newWidget != widget);
    assert(depth != null);
    assert(_active);
    assert(Widget.canUpdate(widget, newWidget));
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

  void _updateDepth(int parentDepth) {
    int expectedDepth = parentDepth + 1;
    if (_depth < expectedDepth) {
      _depth = expectedDepth;
      visitChildren((Element child) {
        child._updateDepth(expectedDepth);
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

  Element _retakeInactiveElement(GlobalKey key, Widget newWidget) {
    Element element = key._currentElement;
    if (element == null)
      return null;
    if (!Widget.canUpdate(element.widget, newWidget))
      return null;
    if (element._parent != null && !element._parent.detachChild(element))
      return null;
    assert(element._parent == null);
    owner._inactiveElements.remove(element);
    return element;
  }

  Element inflateWidget(Widget newWidget, dynamic newSlot) {
    assert(newWidget != null);
    Key key = newWidget.key;
    if (key is GlobalKey) {
      Element newChild = _retakeInactiveElement(key, newWidget);
      if (newChild != null) {
        assert(newChild._parent == null);
        assert(() { _debugCheckForCycles(newChild); return true; });
        newChild._activateWithParent(this, newSlot);
        Element updatedChild = updateChild(newChild, newWidget, newSlot);
        assert(newChild == updatedChild);
        return updatedChild;
      }
    }
    Element newChild = newWidget.createElement();
    assert(() { _debugCheckForCycles(newChild); return true; });
    newChild.mount(this, newSlot);
    assert(newChild._debugLifecycleState == _ElementLifecycle.active);
    return newChild;
  }

  void _debugCheckForCycles(Element newChild) {
    assert(newChild._parent == null);
    assert(() {
      Element node = this;
      while (node._parent != null)
        node = node._parent;
      assert(node != newChild); // indicates we are about to create a cycle
      return true;
    });
  }

  void deactivateChild(Element child) {
    assert(child != null);
    assert(child._parent == this);
    child._parent = null;
    child.detachRenderObject();
    owner._inactiveElements.add(child); // this eventually calls child.deactivate()
  }

  void _activateWithParent(Element parent, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    _parent = parent;
    _updateDepth(_parent.depth);
    _activateRecursively(this);
    attachRenderObject(newSlot);
    assert(_debugLifecycleState == _ElementLifecycle.active);
  }

  static void _activateRecursively(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.activate();
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.visitChildren(_activateRecursively);
  }

  void activate() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    assert(widget != null);
    assert(depth != null);
    assert(!_active);
    _active = true;
    _updateInheritance();
    assert(() { _debugLifecycleState = _ElementLifecycle.active; return true; });
  }

  void deactivate() {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(depth != null);
    assert(_active);
    if (_dependencies != null) {
      for (InheritedElement dependency in _dependencies)
        dependency._dependents.remove(this);
      _dependencies.clear();
    }
    _inheritedWidgets = null;
    _active = false;
    assert(() { _debugLifecycleState = _ElementLifecycle.inactive; return true; });
  }

  /// Called after children have been deactivated.
  void debugDeactivated() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
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

  @override
  RenderObject findRenderObject() => renderObject;

  Map<Type, InheritedElement> _inheritedWidgets;
  Set<InheritedElement> _dependencies;

  @override
  InheritedWidget inheritFromWidgetOfExactType(Type targetType) {
    InheritedElement ancestor = _inheritedWidgets == null ? null : _inheritedWidgets[targetType];
    if (ancestor != null) {
      assert(ancestor is InheritedElement);
      _dependencies ??= new HashSet<InheritedElement>();
      _dependencies.add(ancestor);
      ancestor._dependents.add(this);
      return ancestor.widget;
    }
    return null;
  }

  void _updateInheritance() {
    assert(_active);
    _inheritedWidgets = _parent?._inheritedWidgets;
  }

  @override
  Widget ancestorWidgetOfExactType(Type targetType) {
    Element ancestor = _parent;
    while (ancestor != null && ancestor.widget.runtimeType != targetType)
      ancestor = ancestor._parent;
    return ancestor?.widget;
  }

  @override
  State ancestorStateOfType(TypeMatcher matcher) {
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is StatefulElement && matcher.check(ancestor.state))
        break;
      ancestor = ancestor._parent;
    }
    StatefulElement statefulAncestor = ancestor;
    return statefulAncestor?.state;
  }

  @override
  RenderObject ancestorRenderObjectOfType(TypeMatcher matcher) {
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is RenderObjectElement && matcher.check(ancestor.renderObject))
        break;
      ancestor = ancestor._parent;
    }
    RenderObjectElement renderObjectAncestor = ancestor;
    return renderObjectAncestor?.renderObject;
  }

  /// Calls visitor for each ancestor element.
  ///
  /// Continues until visitor reaches the root or until visitor returns false.
  @override
  void visitAncestorElements(bool visitor(Element element)) {
    Element ancestor = _parent;
    while (ancestor != null && visitor(ancestor))
      ancestor = ancestor._parent;
  }

  void dependenciesChanged(Type affectedWidgetType) {
    assert(false);
  }

  String debugGetCreatorChain(int limit) {
    List<String> chain = <String>[];
    Element node = this;
    while (chain.length < limit && node != null) {
      chain.add(node.toStringShort());
      node = node._parent;
    }
    if (node != null)
      chain.add('\u22EF');
    return chain.join(' \u2190 ');
  }

  String toStringShort() {
    return widget != null ? '${widget.toStringShort()}' : '[$runtimeType]';
  }

  @override
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

/// A widget that renders an exception's message. This widget is used when a
/// build function fails, to help with determining where the problem lies.
/// Exceptions are also logged to the console, which you can read using `flutter
/// logs`. The console will also include additional information such as the
/// stack trace for the exception.
class ErrorWidget extends LeafRenderObjectWidget {
  ErrorWidget(
    Object exception
  ) : message = _stringify(exception),
      super(key: new UniqueKey());

  final String message;

  static String _stringify(Object exception) {
    try {
      return exception.toString();
    } catch (e) { }
    return 'Error';
  }

  @override
  RenderBox createRenderObject(BuildContext context) => new RenderErrorBox(message);

  @override
  void debugFillDescription(List<String> description) {
    description.add('message: ' + _stringify(message));
  }
}

/// Base class for instantiations of widgets that have builders and can be
/// marked dirty.
abstract class BuildableElement extends Element {
  BuildableElement(Widget widget) : super(widget);

  /// Returns true if the element has been marked as needing rebuilding.
  bool get dirty => _dirty;
  bool _dirty = true;

  // We let widget authors call setState from initState, didUpdateConfig, and
  // build even when state is locked because its convenient and a no-op anyway.
  // This flag ensures that this convenience is only allowed on the element
  // currently undergoing initState, didUpdateConfig, or build.
  bool _debugAllowIgnoredCallsToMarkNeedsBuild = false;
  bool _debugSetAllowIgnoredCallsToMarkNeedsBuild(bool value) {
    assert(_debugAllowIgnoredCallsToMarkNeedsBuild == !value);
    _debugAllowIgnoredCallsToMarkNeedsBuild = value;
    return true;
  }

  /// Marks the element as dirty and adds it to the global list of widgets to
  /// rebuild in the next frame.
  ///
  /// Since it is inefficient to build an element twice in one frame,
  /// applications and widgets should be structured so as to only mark
  /// widgets dirty during event handlers before the frame begins, not during
  /// the build itself.
  void markNeedsBuild() {
    assert(_debugLifecycleState != _ElementLifecycle.defunct);
    if (!_active)
      return;
    assert(owner != null);
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(() {
      if (owner._debugBuilding) {
        if (owner._debugCurrentBuildTarget == null) {
          // If _debugCurrentBuildTarget is null, we're not actually building a
          // widget but instead building the root of the tree via runApp.
          // TODO(abarth): Remove these cases and ensure that we always have
          // a current build target when we're building.
          return true;
        }
        bool foundTarget = false;
        visitAncestorElements((Element element) {
          if (element == owner._debugCurrentBuildTarget) {
            foundTarget = true;
            return false;
          }
          return true;
        });
        if (foundTarget)
          return true;
      }
      if (owner._debugStateLocked && (!_debugAllowIgnoredCallsToMarkNeedsBuild || !dirty)) {
        throw new FlutterError(
          'setState() or markNeedsBuild() called during build.\n'
          'This widget cannot be marked as needing to build because the framework '
          'is already in the process of building widgets. A widget can be marked as '
          'needing to be built during the build phase only if one if its ancestors '
          'is currently building. This exception is allowed because the framework '
          'builds parent widgets before children, which means a dirty descendant '
          'will always be built. Otherwise, the framework might not visit this '
          'widget during this build phase.'
        );
      }
      return true;
    });
    if (dirty)
      return;
    _dirty = true;
    owner.scheduleBuildFor(this);
  }

  /// Called by the binding when scheduleBuild() has been called to mark this
  /// element dirty, and, in components, by update() when the widget has
  /// changed.
  void rebuild() {
    assert(_debugLifecycleState != _ElementLifecycle.initial);
    if (!_active || !_dirty) {
      _dirty = false;
      return;
    }
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(owner._debugStateLocked);
    BuildableElement debugPreviousBuildTarget;
    assert(() {
      debugPreviousBuildTarget = owner._debugCurrentBuildTarget;
      owner._debugCurrentBuildTarget = this;
     return true;
    });
    performRebuild();
    assert(() {
      assert(owner._debugCurrentBuildTarget == this);
      owner._debugCurrentBuildTarget = debugPreviousBuildTarget;
      return true;
    });
    assert(!_dirty);
  }

  /// Called by rebuild() after the appropriate checks have been made.
  void performRebuild();

  @override
  void dependenciesChanged(Type affectedWidgetType) {
    markNeedsBuild();
  }

  @override
  void _reassemble() {
    markNeedsBuild();
    super._reassemble();
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dirty)
      description.add('dirty');
  }
}

typedef Widget WidgetBuilder(BuildContext context);
typedef Widget IndexedBuilder(BuildContext context, int index);

// See ComponentElement._builder.
Widget _buildNothing(BuildContext context) => null;

/// Base class for the instantiation of [StatelessWidget], [StatefulWidget],
/// and [_ProxyWidget] widgets.
abstract class ComponentElement extends BuildableElement {
  ComponentElement(Widget widget) : super(widget);

  // Initializing this field with _buildNothing helps the compiler prove that
  // this field always holds a closure.
  WidgetBuilder _builder = _buildNothing;

  Element _child;

  @override
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

  /// Reinvokes the build() method of the [StatelessWidget] object (for
  /// stateless widgets) or the [State] object (for stateful widgets) and
  /// then updates the widget tree.
  ///
  /// Called automatically during mount() to generate the first build, and by
  /// rebuild() when the element needs updating.
  @override
  void performRebuild() {
    assert(_debugSetAllowIgnoredCallsToMarkNeedsBuild(true));
    Widget built;
    try {
      built = _builder(this);
      assert(() {
        if (built == null) {
          throw new FlutterError(
            'A build function returned null.\n'
            'The offending widget is: $widget\n'
            'Build functions must never return null. '
            'To return an empty space that causes the building widget to fill available room, return "new Container()". '
            'To return an empty space that takes as little room as possible, return "new Container(width: 0.0, height: 0.0)".'
          );
        }
        return true;
      });
    } catch (e, stack) {
      _debugReportException('building $_widget', e, stack);
      built = new ErrorWidget(e);
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
      built = new ErrorWidget(e);
      _child = updateChild(null, built, slot);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  bool detachChild(Element child) {
    assert(child == _child);
    deactivateChild(_child);
    _child = null;
    return true;
  }
}

/// Instantiation of [StatelessWidget]s.
class StatelessElement extends ComponentElement {
  StatelessElement(StatelessWidget widget) : super(widget) {
    _builder = widget.build;
  }

  @override
  StatelessWidget get widget => super.widget;

  @override
  void update(StatelessWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _builder = widget.build;
    _dirty = true;
    rebuild();
  }

  @override
  void _reassemble() {
    _builder = widget.build;
    super._reassemble();
  }
}

/// Instantiation of [StatefulWidget]s.
class StatefulElement extends ComponentElement {
  StatefulElement(StatefulWidget widget)
    : _state = widget.createState(), super(widget) {
    assert(_state._debugTypesAreRight(widget));
    assert(_state._element == null);
    _state._element = this;
    assert(_builder == _buildNothing);
    _builder = _state.build;
    assert(_state._config == null);
    _state._config = widget;
    assert(_state._debugLifecycleState == _StateLifecycle.created);
  }

  State<StatefulWidget> get state => _state;
  State<StatefulWidget> _state;

  @override
  void _reassemble() {
    _builder = state.build;
    super._reassemble();
  }

  @override
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
      throw new FlutterError(
        '${_state.runtimeType}.initState failed to call super.initState.\n'
        'initState() implementations must always call their superclass initState() method, to ensure '
        'that the entire widget is initialized correctly.'
      );
    });
    assert(() { _state._debugLifecycleState = _StateLifecycle.ready; return true; });
    super._firstBuild();
  }

  @override
  void update(StatefulWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    StatefulWidget oldConfig = _state._config;
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

  @override
  void activate() {
    super.activate();
    markNeedsBuild();
  }

  @override
  void deactivate() {
    _state.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    _state.dispose();
    assert(() {
      if (_state._debugLifecycleState == _StateLifecycle.defunct)
        return true;
      throw new FlutterError(
        '${_state.runtimeType}.dispose failed to call super.dispose.\n'
        'dispose() implementations must always call their superclass dispose() method, to ensure '
        'that all the resources used by the widget are fully released.'
      );
    });
    assert(!dirty); // See BuildableElement.unmount for why this is important.
    _state._element = null;
    _state = null;
  }

  @override
  void dependenciesChanged(Type affectedWidgetType) {
    super.dependenciesChanged(affectedWidgetType);
    _state.dependenciesChanged(affectedWidgetType);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (state != null)
      description.add('state: $state');
  }
}

abstract class _ProxyElement extends ComponentElement {
  _ProxyElement(_ProxyWidget widget) : super(widget) {
    _builder = _build;
  }

  @override
  _ProxyWidget get widget => super.widget;

  Widget _build(BuildContext context) => widget.child;

  @override
  void _reassemble() {
    _builder = _build;
    super._reassemble();
  }

  @override
  void update(_ProxyWidget newWidget) {
    _ProxyWidget oldWidget = widget;
    assert(widget != null);
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    notifyDescendants(oldWidget);
    _dirty = true;
    rebuild();
  }

  void notifyDescendants(_ProxyWidget oldWidget);
}

class ParentDataElement<T extends RenderObjectWidget> extends _ProxyElement {
  ParentDataElement(ParentDataWidget<T> widget) : super(widget);

  @override
  ParentDataWidget<T> get widget => super.widget;

  @override
  void mount(Element parent, dynamic slot) {
    assert(() {
      List<Widget> badAncestors = <Widget>[];
      Element ancestor = parent;
      while (ancestor != null) {
        if (ancestor is ParentDataElement<RenderObjectWidget>) {
          badAncestors.add(ancestor.widget);
        } else if (ancestor is RenderObjectElement) {
          if (widget.debugIsValidAncestor(ancestor.widget))
            break;
          badAncestors.add(ancestor.widget);
        }
        ancestor = ancestor._parent;
      }
      if (ancestor != null && badAncestors.isEmpty)
        return true;
      throw new FlutterError(
        'Incorrect use of ParentDataWidget.\n' +
        widget.debugDescribeInvalidAncestorChain(
          description: "$this",
          ownershipChain: parent.debugGetCreatorChain(10),
          foundValidAncestor: ancestor != null,
          badAncestors: badAncestors
        )
      );
    });
    super.mount(parent, slot);
  }

  @override
  void notifyDescendants(ParentDataWidget<T> oldWidget) {
    void notifyChildren(Element child) {
      if (child is RenderObjectElement) {
        child.updateParentData(widget);
      } else {
        assert(child is! ParentDataElement<RenderObjectWidget>);
        child.visitChildren(notifyChildren);
      }
    }
    visitChildren(notifyChildren);
  }
}


class InheritedElement extends _ProxyElement {
  InheritedElement(InheritedWidget widget) : super(widget);

  @override
  InheritedWidget get widget => super.widget;

  final Set<Element> _dependents = new HashSet<Element>();

  @override
  void _updateInheritance() {
    assert(_active);
    final Map<Type, InheritedElement> incomingWidgets = _parent?._inheritedWidgets;
    if (incomingWidgets != null)
      _inheritedWidgets = new Map<Type, InheritedElement>.from(incomingWidgets);
    else
      _inheritedWidgets = new Map<Type, InheritedElement>();
    _inheritedWidgets[widget.runtimeType] = this;
  }

  @override
  void debugDeactivated() {
    assert(() {
      assert(_dependents.isEmpty);
      return true;
    });
    super.debugDeactivated();
  }

  @override
  void notifyDescendants(InheritedWidget oldWidget) {
    if (!widget.updateShouldNotify(oldWidget))
      return;
    dispatchDependenciesChanged();
  }

  /// Notifies all dependent elements that this inherited widget has changed.
  ///
  /// [InheritedElement] calls this function if [InheritedWidget.updateShouldNotify]
  /// returns true. Subclasses of [InheritedElement] might wish to call this
  /// function at other times if their inherited information changes outside of
  /// the build phase.
  void dispatchDependenciesChanged() {
    final Type ourRuntimeType = widget.runtimeType;
    for (Element dependant in _dependents) {
      dependant.dependenciesChanged(ourRuntimeType);
      assert(() {
        // check that it really is our descendant
        Element ancestor = dependant._parent;
        while (ancestor != this && ancestor != null)
          ancestor = ancestor._parent;
        return ancestor == this;
      });
    }
  }
}

/// Base class for instantiations of RenderObjectWidget subclasses
abstract class RenderObjectElement extends BuildableElement {
  RenderObjectElement(RenderObjectWidget widget) : super(widget);

  @override
  RenderObjectWidget get widget => super.widget;

  /// The underlying [RenderObject] for this element
  @override
  RenderObject get renderObject => _renderObject;
  RenderObject _renderObject;

  RenderObjectElement _ancestorRenderObjectElement;

  RenderObjectElement _findAncestorRenderObjectElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement)
      ancestor = ancestor._parent;
    return ancestor;
  }

  ParentDataElement<RenderObjectWidget> _findAncestorParentDataElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      if (ancestor is ParentDataElement<RenderObjectWidget>)
        return ancestor;
      ancestor = ancestor._parent;
    }
    return null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _renderObject = widget.createRenderObject(this);
    assert(() { debugUpdateRenderObjectOwner(); return true; });
    assert(_slot == newSlot);
    attachRenderObject(newSlot);
    _dirty = false;
  }

  @override
  void update(RenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    assert(() { debugUpdateRenderObjectOwner(); return true; });
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  void debugUpdateRenderObjectOwner() {
    _renderObject.debugCreator = debugGetCreatorChain(10);
  }

  @override
  void performRebuild() {
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  /// Utility function for subclasses that have one or more lists of children.
  /// Attempts to update the given old children list using the given new
  /// widgets, removing obsolete elements and introducing new ones as necessary,
  /// and then returns the new child list.
  List<Element> updateChildren(List<Element> oldChildren, List<Widget> newWidgets, { Set<Element> detachedChildren }) {
    assert(oldChildren != null);
    assert(newWidgets != null);

    Element replaceWithNullIfDetached(Element child) {
      return detachedChildren != null && detachedChildren.contains(child) ? null : child;
    }

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
    // 1. Walk the lists from the top, syncing nodes, until you no longer have
    //    matching nodes.
    // 2. Walk the lists from the bottom, without syncing nodes, until you no
    //    longer have matching nodes. We'll sync these nodes at the end. We
    //    don't sync them now because we want to sync all the nodes in order
    //    from beginning ot end.
    // At this point we narrowed the old and new lists to the point
    // where the nodes no longer match.
    // 3. Walk the narrowed part of the old list to get the list of
    //    keys and sync null with non-keyed items.
    // 4. Walk the narrowed part of the new list forwards:
    //     * Sync unkeyed items with null
    //     * Sync keyed items with the source if it exists, else with null.
    // 5. Walk the bottom of the list again, syncing the nodes.
    // 6. Sync null with any items in the list of keys that are still
    //    mounted.

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    List<Element> newChildren = oldChildren.length == newWidgets.length ?
        oldChildren : new List<Element>(newWidgets.length);

    Element previousChild;

    // Update the top of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      Element oldChild = replaceWithNullIfDetached(oldChildren[oldChildrenTop]);
      Widget newWidget = newWidgets[newChildrenTop];
      assert(oldChild == null || oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // Scan the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      Element oldChild = replaceWithNullIfDetached(oldChildren[oldChildrenBottom]);
      Widget newWidget = newWidgets[newChildrenBottom];
      assert(oldChild == null || oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // Scan the old children in the middle of the list.
    bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element> oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = new Map<Key, Element>();
      while (oldChildrenTop <= oldChildrenBottom) {
        Element oldChild = replaceWithNullIfDetached(oldChildren[oldChildrenTop]);
        assert(oldChild == null || oldChild._debugLifecycleState == _ElementLifecycle.active);
        if (oldChild != null) {
          if (oldChild.widget.key != null)
            oldKeyedChildren[oldChild.widget.key] = oldChild;
          else
            deactivateChild(oldChild);
        }
        oldChildrenTop += 1;
      }
    }

    // Update the middle of the list.
    while (newChildrenTop <= newChildrenBottom) {
      Element oldChild;
      Widget newWidget = newWidgets[newChildrenTop];
      if (haveOldChildren) {
        Key key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[newWidget.key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
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
      assert(oldChild == null || Widget.canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
    }

    // We've scaned the whole list.
    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newWidgets.length - newChildrenTop == oldChildren.length - oldChildrenTop);
    newChildrenBottom = newWidgets.length - 1;
    oldChildrenBottom = oldChildren.length - 1;

    // Update the bottom of the list.
    while ((oldChildrenTop <= oldChildrenBottom) && (newChildrenTop <= newChildrenBottom)) {
      Element oldChild = oldChildren[oldChildrenTop];
      assert(replaceWithNullIfDetached(oldChild) != null);
      assert(oldChild._debugLifecycleState == _ElementLifecycle.active);
      Widget newWidget = newWidgets[newChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));
      Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild || oldChild == null || oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    // clean up any of the remaining middle nodes from the old list
    if (haveOldChildren && oldKeyedChildren.isNotEmpty) {
      for (Element oldChild in oldKeyedChildren.values) {
        if (detachedChildren == null || !detachedChildren.contains(oldChild))
          deactivateChild(oldChild);
      }
    }

    return newChildren;
  }

  @override
  void deactivate() {
    super.deactivate();
    assert(!renderObject.attached);
  }

  @override
  void unmount() {
    super.unmount();
    assert(!renderObject.attached);
    widget.didUnmountRenderObject(renderObject);
  }

  void updateParentData(ParentDataWidget<RenderObjectWidget> parentData) {
    parentData.applyParentData(renderObject);
  }

  @override
  void _updateSlot(dynamic newSlot) {
    assert(slot != newSlot);
    super._updateSlot(newSlot);
    assert(slot == newSlot);
    _ancestorRenderObjectElement.moveChildRenderObject(renderObject, slot);
  }

  @override
  void attachRenderObject(dynamic newSlot) {
    assert(_ancestorRenderObjectElement == null);
    _slot = newSlot;
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    _ancestorRenderObjectElement?.insertChildRenderObject(renderObject, newSlot);
    ParentDataElement<RenderObjectWidget> parentDataElement = _findAncestorParentDataElement();
    if (parentDataElement != null)
      updateParentData(parentDataElement.widget);
  }

  @override
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

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (renderObject != null)
      description.add('renderObject: $renderObject');
  }
}

/// Instantiation of RenderObjectWidgets at the root of the tree
///
/// Only root elements may have their owner set explicitly. All other
/// elements inherit their owner from their parent.
abstract class RootRenderObjectElement extends RenderObjectElement {
  RootRenderObjectElement(RenderObjectWidget widget): super(widget);

  void assignOwner(BuildOwner owner) {
    _owner = owner;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    // Root elements should never have parents
    assert(parent == null);
    assert(newSlot == null);
    super.mount(parent, newSlot);
  }
}

/// Instantiation of RenderObjectWidgets that have no children
class LeafRenderObjectElement extends RenderObjectElement {
  LeafRenderObjectElement(LeafRenderObjectWidget widget): super(widget);

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(false);
  }
}

/// Instantiation of RenderObjectWidgets that have up to one child
class SingleChildRenderObjectElement extends RenderObjectElement {
  SingleChildRenderObjectElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  SingleChildRenderObjectWidget get widget => super.widget;

  Element _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null)
      visitor(_child);
  }

  @override
  bool detachChild(Element child) {
    assert(child == _child);
    deactivateChild(_child);
    _child = null;
    return true;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void update(SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(slot == null);
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

/// Instantiation of RenderObjectWidgets that can have a list of children
class MultiChildRenderObjectElement extends RenderObjectElement {
  MultiChildRenderObjectElement(MultiChildRenderObjectWidget widget) : super(widget) {
    assert(!debugChildrenHaveDuplicateKeys(widget, widget.children));
  }

  @override
  MultiChildRenderObjectWidget get widget => super.widget;

  List<Element> _children;
  // We keep a set of detached children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _detachedChildren = new HashSet<Element>();

  @override
  void insertChildRenderObject(RenderObject child, Element slot) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
    renderObject.insert(child, after: slot?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in _children) {
      if (!_detachedChildren.contains(child))
        visitor(child);
    }
  }

  @override
  bool detachChild(Element child) {
    _detachedChildren.add(child);
    deactivateChild(child);
    return true;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = new List<Element>(widget.children.length);
    Element previousChild;
    for (int i = 0; i < _children.length; ++i) {
      Element newChild = inflateWidget(widget.children[i], previousChild);
      _children[i] = newChild;
      previousChild = newChild;
    }
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _children = updateChildren(_children, widget.children, detachedChildren: _detachedChildren);
    _detachedChildren.clear();
  }
}

void _debugReportException(String context, dynamic exception, StackTrace stack) {
  FlutterError.reportError(new FlutterErrorDetails(
    exception: exception,
    stack: stack,
    library: 'widgets library',
    context: context
  ));
}
