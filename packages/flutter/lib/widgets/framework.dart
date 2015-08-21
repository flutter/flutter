// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:sky' as sky;

import 'package:sky/base/hit_test.dart';
import 'package:sky/base/scheduler.dart' as scheduler;
import 'package:sky/mojo/activity.dart';
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/object.dart';
import 'package:sky/rendering/sky_binding.dart';
import 'package:sky/rendering/view.dart';

export 'package:sky/base/hit_test.dart' show EventDisposition, combineEventDispositions;
export 'package:sky/rendering/box.dart' show BoxConstraints, BoxDecoration, Border, BorderSide, EdgeDims;
export 'package:sky/rendering/flex.dart' show FlexDirection;
export 'package:sky/rendering/object.dart' show Point, Offset, Size, Rect, Color, Paint, Path;

final bool _shouldLogRenderDuration = false; // see also 'enableProfilingLoop' argument to runApp()

typedef Widget Builder();
typedef void WidgetTreeWalker(Widget);

abstract class Key {
  const Key.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor
  factory Key(String value) => new StringKey(value);
  factory Key.stringify(Object value) => new StringKey(value.toString());
  factory Key.fromObjectIdentity(Object value) => new ObjectKey(value);
}

class StringKey extends Key {
  const StringKey(this.value) : super.constructor();
  final String value;
  String toString() => '[\'${value}\']';
  bool operator==(other) => other is StringKey && other.value == value;
  int get hashCode => value.hashCode;
}

class ObjectKey extends Key {
  const ObjectKey(this.value) : super.constructor();
  final Object value;
  String toString() => '[${value.runtimeType}(${value.hashCode})]';
  bool operator==(other) => other is ObjectKey && identical(other.value, value);
  int get hashCode => identityHashCode(value);
}

typedef void GlobalKeyRemovalListener(GlobalKey key);

abstract class GlobalKey extends Key {
  const GlobalKey.constructor() : super.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor
  factory GlobalKey({ String label }) => new LabeledGlobalKey(label);
  factory GlobalKey.fromObjectIdentity(Object value) => new GlobalObjectKey(value);

  static final Map<GlobalKey, Widget> _registry = new Map<GlobalKey, Widget>();
  static final Map<GlobalKey, int> _debugDuplicates = new Map<GlobalKey, int>();
  static final Map<GlobalKey, Set<GlobalKeyRemovalListener>> _removalListeners = new Map<GlobalKey, Set<GlobalKeyRemovalListener>>();
  static final Set<GlobalKey> _removedKeys = new Set<GlobalKey>();

  void _register(Widget widget) {
    assert(() {
      if (_registry.containsKey(this)) {
        int oldCount = _debugDuplicates.putIfAbsent(this, () => 1);
        assert(oldCount >= 1);
        _debugDuplicates[this] = oldCount + 1;
      }
      return true;
    });
    _registry[this] = widget;
  }

  void _unregister(Widget widget) {
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
    if (_registry[this] == widget) {
      _registry.remove(this);
      _removedKeys.add(this);
    }
  }

  static bool _notifyingListeners = false;

  static void registerRemovalListener(GlobalKey key, GlobalKeyRemovalListener listener) {
    assert(!_notifyingListeners);
    assert(key != null);
    if (!_removalListeners.containsKey(key))
      _removalListeners[key] = new Set<GlobalKeyRemovalListener>();
    bool added = _removalListeners[key].add(listener);
    assert(added);
  }

  static void unregisterRemovalListener(GlobalKey key, GlobalKeyRemovalListener listener) {
    assert(!_notifyingListeners);
    assert(key != null);
    assert(_removalListeners.containsKey(key));
    bool removed = _removalListeners[key].remove(listener);
    if (_removalListeners[key].isEmpty)
      _removalListeners.remove(key);
    assert(removed);
  }

  static Widget getWidget(GlobalKey key) {
    assert(key != null);
    return _registry[key];
  }

  static void _notifyListeners() {
    assert(!_inBuildDirtyComponents);
    assert(!Widget._notifyingMountStatus);
    assert(_debugDuplicates.isEmpty);
    _notifyingListeners = true;
    for (GlobalKey key in _removedKeys) {
      if (!_registry.containsKey(key) && _removalListeners.containsKey(key)) {
        for (GlobalKeyRemovalListener listener in _removalListeners[key])
          listener(key);
        _removalListeners.remove(key);
      }
    }
    _removedKeys.clear();
    _notifyingListeners = false;
  }

}

class LabeledGlobalKey extends GlobalKey {
  // the label is purely for documentary purposes and does not affect the key
  const LabeledGlobalKey(this._label) : super.constructor();
  final String _label;
  String toString() => '[GlobalKey ${_label != null ? _label : hashCode}]';
}

class GlobalObjectKey extends GlobalKey {
  const GlobalObjectKey(this.value) : super.constructor();
  final Object value;
  String toString() => '[GlobalKey ${value.runtimeType}(${value.hashCode})]';
  bool operator==(other) => other is GlobalObjectKey && identical(other.value, value);
  int get hashCode => identityHashCode(value);
}

/// A base class for elements of the widget tree
abstract class Widget {

  Widget({ Key key }) : _key = key {
    assert(_isConstructedDuringBuild());
  }

  // TODO(jackson): Remove this workaround for limitation of Dart mixins
  Widget._withKey(Key key) : _key = key {
    assert(_isConstructedDuringBuild());
  }

  // you should not build the UI tree ahead of time, build it only during build()
  bool _isConstructedDuringBuild() => this is AbstractWidgetRoot || this is App || _inBuildDirtyComponents || _inLayoutCallbackBuilder > 0;

  Key _key;

  /// A semantic identifer for this widget
  ///
  /// Keys are used to find matches when synchronizing two widget trees, for
  /// example after a [Component] rebuilds. Without keys, two widgets can match
  /// if their runtimeType matches. With keys, the keys must match as well.
  /// Assigning a key to a widget can improve performance by causing the
  /// framework to sync widgets that share a lot of common structure and can
  /// help match stateful components semantically rather than positionally.
  Key get key => _key;

  Widget _parent;

  /// The parent of this widget in the widget tree.
  Widget get parent => _parent;

  bool _mounted = false;
  bool _wasMounted = false;
  bool get mounted => _mounted;
  static bool _notifyingMountStatus = false;
  static List<Widget> _mountedChanged = new List<Widget>();

  /// Called during the synchronizing process to update the widget's parent.
  void setParent(Widget newParent) {
    assert(!_notifyingMountStatus);
    if (_parent == newParent)
      return;
    _parent = newParent;
    if (newParent == null) {
      if (_mounted) {
        _mounted = false;
        _mountedChanged.add(this);
      }
    } else {
      assert(newParent._mounted);
      if (_parent._mounted != _mounted) {
        _mounted = _parent._mounted;
        _mountedChanged.add(this);
      }
    }
  }

  /// Walks the immediate children of this widget
  ///
  /// Override this if you have children and call walker on each child.
  /// Note that you may be called before the child has had its parent
  /// pointer set to point to you. Your walker, and any methods it
  /// invokes on your descendants, should not rely on the ancestor
  /// chain being correctly configured at this point.
  void walkChildren(WidgetTreeWalker walker) { }

  static void _notifyMountStatusChanged() {
    try {
      sky.tracing.begin("Widget._notifyMountStatusChanged");
      _notifyingMountStatus = true;
      for (Widget node in _mountedChanged) {
        if (node._wasMounted != node._mounted) {
          if (node._mounted)
            node.didMount();
          else
            node.didUnmount();
          node._wasMounted = node._mounted;
        }
      }
      _mountedChanged.clear();
    } finally {
      _notifyingMountStatus = false;
      sky.tracing.end("Widget._notifyMountStatusChanged");
    }
    GlobalKey._notifyListeners();
  }

  /// Override this function to learn when this [Widget] enters the widget tree.
  void didMount() {
    if (key is GlobalKey)
      (key as GlobalKey)._register(this); // TODO(ianh): remove cast when analyzer is cleverer
  }

  /// Override this function to learn when this [Widget] leaves the widget tree.
  void didUnmount() {
    if (key is GlobalKey)
      (key as GlobalKey)._unregister(this); // TODO(ianh): remove cast when analyzer is cleverer
  }

  RenderObject _renderObject;

  /// The underlying [RenderObject] associated with this [Widget].
  RenderObject get renderObject => _renderObject;

  // Subclasses which implements Nodes that become stateful may return true
  // if the node has become stateful and should be retained.
  // This is called immediately before _sync().
  // Component.retainStatefulNodeIfPossible() calls syncFields().
  bool retainStatefulNodeIfPossible(Widget newNode) => false;

  void _sync(Widget old, dynamic slot);
  void updateSlot(dynamic newSlot);
  // 'slot' is the identifier that the ancestor RenderObjectWrapper uses to know
  // where to put this descendant. If you just defer to a child, then make sure
  // to pass them the slot.

  Widget findAncestorRenderObjectWrapper() {
    var ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectWrapper)
      ancestor = ancestor._parent;
    return ancestor;
  }

  Set<Type> _dependencies;
  Inherited inheritedOfType(Type targetType) {
    if (_dependencies == null)
      _dependencies = new Set<Type>();
    _dependencies.add(targetType);
    Widget ancestor = parent;
    while (ancestor != null && ancestor.runtimeType != targetType)
      ancestor = ancestor.parent;
    return ancestor;
  }

  void dependenciesChanged() {
    // This is called if you've use inheritedOfType and the Inherited
    // ancestor you were provided was changed. For a widget to use Inherited
    // it needs an implementation of dependenciesChanged. If your widget extends
    // Component or RenderObjectWrapper this is provided for you automatically.
    // If you aren't able to extend one of those classes, you need to
    // provide your own implementation of dependenciesChanged.
    assert(false);
  }

  void remove() {
    walkChildren((Widget child) => child.remove());
    _renderObject = null;
    setParent(null);
  }

  void detachRenderObject();

  // Returns the child which should be retained as the child of this node.
  Widget syncChild(Widget newNode, Widget oldNode, dynamic slot) {

    if (newNode == oldNode) {
      assert(newNode == null || newNode.mounted);
      assert(newNode is! RenderObjectWrapper ||
             (newNode is RenderObjectWrapper && newNode._ancestor != null)); // TODO(ianh): Simplify this once the analyzer is cleverer
      if (newNode != null)
        newNode.setParent(this);
      return newNode; // Nothing to do. Subtrees must be identical.
    }

    if (newNode == null) {
      // the child in this slot has gone away
      assert(oldNode.mounted);
      oldNode.detachRenderObject();
      oldNode.remove();
      assert(!oldNode.mounted);
      return null;
    }

    if (oldNode != null) {
      if (_canSync(newNode, oldNode)) {
        if (oldNode.retainStatefulNodeIfPossible(newNode)) {
          assert(oldNode.mounted);
          assert(!newNode.mounted);
          oldNode.setParent(this);
          oldNode._sync(newNode, slot);
          assert(oldNode.renderObject is RenderObject);
          return oldNode;
        } else {
          oldNode.setParent(null);
        }
      } else {
        assert(oldNode.mounted);
        oldNode.detachRenderObject();
        oldNode.remove();
        oldNode = null;
      }
    }

    assert(oldNode == null || (oldNode.mounted == false && oldNode.parent == null));
    assert(!newNode.mounted);
    newNode.setParent(this);
    newNode._sync(oldNode, slot);
    assert(newNode.renderObject is RenderObject);
    return newNode;
  }

  String _adjustPrefixWithParentCheck(Widget child, String prefix) {
    if (child.parent == this)
      return prefix;
    if (child.parent == null)
      return '$prefix [[DISCONNECTED]] ';
    return '$prefix [[PARENT IS ${child.parent.toStringName()}]] ';
  }

  String toString([String prefix = '', String startPrefix = '']) {
    String childrenString = '';
    List<Widget> children = new List<Widget>();
    walkChildren(children.add);
    if (children.length > 0) {
      Widget lastChild = children.removeLast();
      String nextStartPrefix = prefix + ' +-';
      String nextPrefix = prefix + ' | ';
      for (Widget child in children)
        childrenString += child.toString(nextPrefix, _adjustPrefixWithParentCheck(child, nextStartPrefix));
      nextStartPrefix = prefix + ' \'-';
      nextPrefix = prefix + '   ';
      childrenString += lastChild.toString(nextPrefix, _adjustPrefixWithParentCheck(lastChild, nextStartPrefix));
    }
    return '$startPrefix${toStringName()}\n$childrenString';
  }
  String toStringName() {
    if (key == null)
      return '$runtimeType(unkeyed; hashCode=$hashCode)';
    return '$runtimeType($key; hashCode=$hashCode)';
  }

  // This function can be safely called when the layout is valid.
  // For example Listener or SizeObserver callbacks can safely call
  // globalToLocal().
  Point globalToLocal(Point point) {
    assert(mounted);
    assert(renderObject is RenderBox);
    return (renderObject as RenderBox).globalToLocal(point);
  }

  // See globalToLocal().
  Point localToGlobal(Point point) {
    assert(mounted);
    assert(renderObject is RenderBox);
    return (renderObject as RenderBox).localToGlobal(point);
  }
}

bool _canSync(Widget a, Widget b) {
  return a.runtimeType == b.runtimeType && a.key == b.key;
}


// Descendants of TagNode provide a way to tag RenderObjectWrapper and
// Component nodes with annotations, such as event listeners,
// stylistic information, etc.
abstract class TagNode extends Widget {

  TagNode(Widget child, { Key key })
    : this.child = child, super(key: key);

  // TODO(jackson): Remove this workaround for limitation of Dart mixins
  TagNode._withKey(Widget child, Key key)
    : this.child = child, super._withKey(key);

  Widget child;

  void walkChildren(WidgetTreeWalker walker) {
    if (child != null)
      walker(child);
  }

  void _sync(Widget old, dynamic slot) {
    Widget oldChild = old == null ? null : (old as TagNode).child;
    child = syncChild(child, oldChild, slot);
    assert(child.parent == this);
    assert(child.renderObject != null);
    _renderObject = child.renderObject;
    assert(_renderObject == renderObject); // in case a subclass reintroduces it
  }

  void updateSlot(dynamic newSlot) {
    child.updateSlot(newSlot);
  }

  void detachRenderObject() {
    if (child != null)
      child.detachRenderObject();
  }

}

class ParentDataNode extends TagNode {
  ParentDataNode(Widget child, this.parentData, { Key key })
    : super(child, key: key);
  final ParentData parentData;
}

abstract class Inherited extends TagNode {

  Inherited({ Key key, Widget child }) : super._withKey(child, key);

  void _sync(Widget old, dynamic slot) {
    if (old != null) {
      if (syncShouldNotify(old))
        notifyDescendants();
    }
    super._sync(old, slot);
  }

  void notifyDescendants() {
    final Type ourRuntimeType = runtimeType;
    void notifyChildren(Widget child) {
      if (child._dependencies != null &&
          child._dependencies.contains(ourRuntimeType))
          child.dependenciesChanged();
      if (child.runtimeType != ourRuntimeType)
        child.walkChildren(notifyChildren);
    }
    walkChildren(notifyChildren);
  }

  bool syncShouldNotify(Inherited old);

}

typedef EventDisposition GestureEventListener(sky.GestureEvent e);
typedef EventDisposition PointerEventListener(sky.PointerEvent e);
typedef EventDisposition EventListener(sky.Event e);

class Listener extends TagNode  {

  Listener({
    Key key,
    Widget child,
    EventListener onWheel,
    GestureEventListener onGestureFlingCancel,
    GestureEventListener onGestureFlingStart,
    GestureEventListener onGestureScrollStart,
    GestureEventListener onGestureScrollUpdate,
    GestureEventListener onGestureLongPress,
    GestureEventListener onGestureTap,
    GestureEventListener onGestureTapDown,
    GestureEventListener onGestureShowPress,
    PointerEventListener onPointerCancel,
    PointerEventListener onPointerDown,
    PointerEventListener onPointerMove,
    PointerEventListener onPointerUp,
    Map<String, EventListener> custom
  }) : listeners = _createListeners(
         onWheel: onWheel,
         onGestureFlingCancel: onGestureFlingCancel,
         onGestureFlingStart: onGestureFlingStart,
         onGestureScrollUpdate: onGestureScrollUpdate,
         onGestureScrollStart: onGestureScrollStart,
         onGestureTap: onGestureTap,
         onGestureTapDown: onGestureTapDown,
         onGestureLongPress: onGestureLongPress,
         onGestureShowPress: onGestureShowPress,
         onPointerCancel: onPointerCancel,
         onPointerDown: onPointerDown,
         onPointerMove: onPointerMove,
         onPointerUp: onPointerUp,
         custom: custom
       ),
       super(child, key: key);

  final Map<String, EventListener> listeners;

  static Map<String, EventListener> _createListeners({
    EventListener onWheel,
    GestureEventListener onGestureFlingCancel,
    GestureEventListener onGestureFlingStart,
    GestureEventListener onGestureScrollStart,
    GestureEventListener onGestureScrollUpdate,
    GestureEventListener onGestureTap,
    GestureEventListener onGestureTapDown,
    GestureEventListener onGestureLongPress,
    GestureEventListener onGestureShowPress,
    PointerEventListener onPointerCancel,
    PointerEventListener onPointerDown,
    PointerEventListener onPointerMove,
    PointerEventListener onPointerUp,
    Map<String, EventListener> custom
  }) {
    var listeners = custom != null ?
        new HashMap<String, EventListener>.from(custom) :
        new HashMap<String, EventListener>();

    if (onWheel != null)
      listeners['wheel'] = onWheel;
    if (onGestureFlingCancel != null)
      listeners['gestureflingcancel'] = onGestureFlingCancel;
    if (onGestureFlingStart != null)
      listeners['gestureflingstart'] = onGestureFlingStart;
    if (onGestureScrollStart != null)
      listeners['gesturescrollstart'] = onGestureScrollStart;
    if (onGestureScrollUpdate != null)
      listeners['gesturescrollupdate'] = onGestureScrollUpdate;
    if (onGestureTap != null)
      listeners['gesturetap'] = onGestureTap;
    if (onGestureTapDown != null)
      listeners['gesturetapdown'] = onGestureTapDown;
    if (onGestureLongPress != null)
      listeners['gesturelongpress'] = onGestureLongPress;
    if (onGestureShowPress != null)
      listeners['gestureshowpress'] = onGestureShowPress;
    if (onPointerCancel != null)
      listeners['pointercancel'] = onPointerCancel;
    if (onPointerDown != null)
      listeners['pointerdown'] = onPointerDown;
    if (onPointerMove != null)
      listeners['pointermove'] = onPointerMove;
    if (onPointerUp != null)
      listeners['pointerup'] = onPointerUp;

    return listeners;
  }

  EventDisposition _handleEvent(sky.Event e) {
    EventListener listener = listeners[e.type];
    if (listener != null) {
      return listener(e);
    }
    return EventDisposition.ignored;
  }

}

abstract class Component extends Widget {

  Component({ Key key })
      : _order = _currentOrder + 1,
        super._withKey(key);

  bool _isBuilding = false;

  bool _dirty = true;

  Widget _child;
  dynamic _slot; // cached slot from the last time we were synced

  void updateSlot(dynamic newSlot) {
    _slot = newSlot;
    if (_child != null)
      _child.updateSlot(newSlot);
  }

  void walkChildren(WidgetTreeWalker walker) {
    if (_child != null)
      walker(_child);
  }

  void remove() {
    assert(_child != null);
    assert(renderObject != null);
    super.remove();
    _child = null;
  }

  void detachRenderObject() {
    assert(_child != null);
    assert(renderObject != null);
    _child.detachRenderObject();
  }

  void dependenciesChanged() {
    // called by Inherited.sync()
    _scheduleBuild();
  }

  // order corresponds to _build_ order, not depth in the tree.
  // All the Components built by a particular other Component will have the
  // same order, regardless of whether one is subsequently inserted
  // into another. The order is used to not tell a Component to
  // rebuild if the Component that it built has itself been rebuilt.
  final int _order;
  static int _currentOrder = 0;

  // There are three cases here:
  // 1) Building for the first time:
  //      assert(_child == null && old == null)
  // 2) Re-building (because a dirty flag got set):
  //      assert(_child != null && old == null)
  // 3) Syncing against an old version
  //      assert(_child == null && old != null)
  void _sync(Component old, dynamic slot) {
    assert(_child == null || old == null);

    updateSlot(slot);

    Widget oldChild;
    if (old == null) {
      oldChild = _child;
    } else {
      assert(_child == null);
      oldChild = old._child;
    }

    _isBuilding = true;

    int lastOrder = _currentOrder;
    _currentOrder = _order;
    _child = build();
    _currentOrder = lastOrder;
    assert(_child != null);
    _child = syncChild(_child, oldChild, slot);
    assert(_child != null);
    assert(_child.parent == this);
    _isBuilding = false;

    _dirty = false;
    _renderObject = _child.renderObject;
    assert(_renderObject == renderObject); // in case a subclass reintroduces it
    assert(renderObject != null);
  }

  void _buildIfDirty() {
    if (!_dirty || !_mounted)
      return;
    assert(renderObject != null);
    _sync(null, _slot);
  }

  void _scheduleBuild() {
    assert(!_isBuilding);
    if (_dirty || !_mounted)
      return;
    _dirty = true;
    _scheduleComponentForRender(this);
  }

  static void flushBuild() {
    if (!_dirtyComponents.isEmpty)
      _buildDirtyComponents();
  }

  Widget build();

}

abstract class StatefulComponent extends Component {

  StatefulComponent({ Key key }) : super(key: key);

  bool _disqualifiedFromEverAppearingAgain = false;
  bool _isStateInitialized = false;

  void didMount() {
    assert(!_disqualifiedFromEverAppearingAgain);
    super.didMount();
  }

  void _buildIfDirty() {
    assert(!_disqualifiedFromEverAppearingAgain);
    super._buildIfDirty();
  }

  bool retainStatefulNodeIfPossible(StatefulComponent newNode) {
    assert(!_disqualifiedFromEverAppearingAgain);
    assert(newNode != null);
    assert(_canSync(this, newNode));
    assert(_child != null);
    newNode._disqualifiedFromEverAppearingAgain = true;

    newNode._child = _child;
    _child = null;
    _dirty = true;

    return true;
  }

  // because our retainStatefulNodeIfPossible() method returns true,
  // when _sync is called, our 'old' is actually the new instance that
  // we are to copy state from.
  void _sync(Widget old, dynamic slot) {
    assert(!_disqualifiedFromEverAppearingAgain);
    // TODO(ianh): _sync should only be called once when old == null
    if (old == null && !_isStateInitialized) {
      initState();
      _isStateInitialized = true;
    }
    if (old != null)
      syncFields(old);
    super._sync(old, slot);
  }

  // Stateful components can override initState if they want
  // to do non-trivial work to initialize state. This is
  // always called before build().
  void initState() { }

  // This is called by _sync(). Derived classes should override this
  // method to update `this` to account for the new values the parent
  // passed to `source`. Make sure to call super.syncFields(source)
  // unless you are extending StatefulComponent directly.
  void syncFields(Component source);

  Widget syncChild(Widget node, Widget oldNode, dynamic slot) {
    assert(!_disqualifiedFromEverAppearingAgain);
    return super.syncChild(node, oldNode, slot);
  }

  // Calls function fn immediately and then schedules another build
  // for this Component.
  void setState(void fn()) {
    assert(!_disqualifiedFromEverAppearingAgain);
    fn();
    _scheduleBuild();
  }
}

Set<Component> _dirtyComponents = new Set<Component>();
bool _buildScheduled = false;
bool _inBuildDirtyComponents = false;
int _inLayoutCallbackBuilder = 0;

class LayoutCallbackBuilderHandle { bool _active = true; }
LayoutCallbackBuilderHandle enterLayoutCallbackBuilder() {
  LayoutCallbackBuilderHandle result;
  assert(() {
    _inLayoutCallbackBuilder += 1;
    result = new LayoutCallbackBuilderHandle();
    return true;
  });
  return result;
}
void exitLayoutCallbackBuilder(LayoutCallbackBuilderHandle handle) {
  assert(() {
    assert(handle._active);
    handle._active = false;
    _inLayoutCallbackBuilder -= 1;
    return true;
  });
  Widget._notifyMountStatusChanged();
}

List<int> _debugFrameTimes = <int>[];

void _absorbDirtyComponents(List<Component> list) {
  list.addAll(_dirtyComponents);
  _dirtyComponents.clear();
  list.sort((Component a, Component b) => a._order - b._order);
}

void _buildDirtyComponents() {
  assert(!_dirtyComponents.isEmpty);

  Stopwatch sw;
  if (_shouldLogRenderDuration)
    sw = new Stopwatch()..start();

  while (!_dirtyComponents.isEmpty) {
    _inBuildDirtyComponents = true;
    try {
      sky.tracing.begin('Component.flushBuild');
      List<Component> sortedDirtyComponents = new List<Component>();
      _absorbDirtyComponents(sortedDirtyComponents);
      int index = 0;
      while (index < sortedDirtyComponents.length) {
        Component component = sortedDirtyComponents[index];
        component._buildIfDirty();
        if (_dirtyComponents.length > 0) {
          // the following assert verifies that we're not rebuilding anyone twice in one frame
          assert(_dirtyComponents.every((Component component) => !sortedDirtyComponents.contains(component)));
          _absorbDirtyComponents(sortedDirtyComponents);
          index = 0;
        } else {
          index += 1;
        }
      }
    } finally {
      _buildScheduled = false;
      _inBuildDirtyComponents = false;
      sky.tracing.end('Component.flushBuild');
    }

    Widget._notifyMountStatusChanged();
  }

  if (_shouldLogRenderDuration) {
    sw.stop();
    _debugFrameTimes.add(sw.elapsedMicroseconds);
    if (_debugFrameTimes.length >= 1000) {
      _debugFrameTimes.sort();
      const int i = 99;
      print('Component.flushBuild: ${i+1}th fastest frame out of the last ${_debugFrameTimes.length}: ${_debugFrameTimes[i]} microseconds');
      _debugFrameTimes.clear();
    }
  }
}

void _scheduleComponentForRender(Component component) {
  _dirtyComponents.add(component);
  if (!_buildScheduled) {
    _buildScheduled = true;
    scheduler.ensureVisualUpdate();
  }
}

// RenderObjectWrappers correspond to a desired state of a
// RenderObject. They are fully immutable, except that a Widget which
// is a Component which lives within a RenderObjectWrapper's children
// list may be in-place replaced with the "old" instance if it has
// become stateful.
abstract class RenderObjectWrapper extends Widget {

  RenderObjectWrapper({ Key key }) : super(key: key);

  RenderObject createNode();

  static final Map<RenderObject, RenderObjectWrapper> _nodeMap =
      new HashMap<RenderObject, RenderObjectWrapper>();
  static RenderObjectWrapper _getMounted(RenderObject node) => _nodeMap[node];

  static Iterable<Widget> getWidgetsForRenderObject(RenderObject renderObject) sync* {
    Widget target = RenderObjectWrapper._getMounted(renderObject);
    if (target == null)
      return;
    RenderObject targetRenderObject = target.renderObject;
    while (target != null && target.renderObject == targetRenderObject) {
      yield target;
      target = target.parent;
    }
  }

  RenderObjectWrapper _ancestor;
  void insertChildRenderObject(RenderObjectWrapper child, dynamic slot);
  void detachChildRenderObject(RenderObjectWrapper child);

  void retainStatefulRenderObjectWrapper(RenderObjectWrapper newNode) {
    newNode._renderObject = _renderObject;
    newNode._ancestor = _ancestor;
  }

  void _sync(RenderObjectWrapper old, dynamic slot) {
    // TODO(abarth): We should split RenderObjectWrapper into two pieces so that
    //               RenderViewObject doesn't need to inherit all this code it
    //               doesn't need.
    assert(parent != null || this is RenderViewWrapper);
    if (old == null) {
      _renderObject = createNode();
      assert(_renderObject != null);
      _ancestor = findAncestorRenderObjectWrapper();
      if (_ancestor is RenderObjectWrapper)
        _ancestor.insertChildRenderObject(this, slot);
    } else {
      assert(_canSync(this, old));
      _renderObject = old.renderObject;
      _ancestor = old._ancestor;
      assert(_renderObject != null);
    }
    assert(_renderObject == renderObject); // in case a subclass reintroduces it
    assert(renderObject != null);
    assert(mounted);
    _nodeMap[renderObject] = this;
    syncRenderObject(old);
  }

  void updateSlot(dynamic newSlot) {
    // We never use the slot except during sync(), in which
    // case our parent is handing it to us anyway.
    // We don't need to propagate this to our children, since
    // we give them their own slots for them to fit into us.
  }

  void syncRenderObject(RenderObjectWrapper old) {
    ParentData parentData = null;
    Widget ancestor = parent;
    while (ancestor != null && ancestor is! RenderObjectWrapper) {
      if (ancestor is ParentDataNode && ancestor.parentData != null) {
        if (parentData != null)
          parentData.merge(ancestor.parentData); // this will throw if the types aren't the same
        else
          parentData = ancestor.parentData;
      }
      ancestor = ancestor.parent;
    }
    if (parentData != null) {
      assert(renderObject.parentData != null);
      renderObject.parentData.merge(parentData); // this will throw if the types aren't appropriate
      if (ancestor != null && ancestor.renderObject != null)
        ancestor.renderObject.markNeedsLayout();
    }
  }

  void dependenciesChanged() {
    // called by Inherited.sync()
    syncRenderObject(this);
  }

  void remove() {
    assert(renderObject != null);
    _nodeMap.remove(renderObject);
    super.remove();
  }

  void detachRenderObject() {
    assert(_ancestor != null);
    assert(renderObject != null);
    _ancestor.detachChildRenderObject(this);
  }

}

abstract class LeafRenderObjectWrapper extends RenderObjectWrapper {

  LeafRenderObjectWrapper({ Key key }) : super(key: key);

  void insertChildRenderObject(RenderObjectWrapper child, dynamic slot) {
    assert(false);
  }

  void detachChildRenderObject(RenderObjectWrapper child) {
    assert(false);
  }

}

abstract class OneChildRenderObjectWrapper extends RenderObjectWrapper {

  OneChildRenderObjectWrapper({ Key key, Widget child })
    : _child = child, super(key: key);

  Widget _child;
  Widget get child => _child;

  void walkChildren(WidgetTreeWalker walker) {
    if (child != null)
      walker(child);
  }

  void syncRenderObject(RenderObjectWrapper old) {
    super.syncRenderObject(old);
    Widget oldChild = old == null ? null : (old as OneChildRenderObjectWrapper).child;
    Widget newChild = child;
    _child = syncChild(newChild, oldChild, null);
    assert((newChild == null && child == null) || (newChild != null && child.parent == this));
    assert(oldChild == null || child == oldChild || oldChild.parent == null);
  }

  void insertChildRenderObject(RenderObjectWrapper child, dynamic slot) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is RenderObjectWithChildMixin);
    assert(slot == null);
    renderObject.child = child.renderObject;
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void detachChildRenderObject(RenderObjectWrapper child) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is RenderObjectWithChildMixin);
    assert(renderObject.child == child.renderObject);
    renderObject.child = null;
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }
}

abstract class MultiChildRenderObjectWrapper extends RenderObjectWrapper {

  // In MultiChildRenderObjectWrapper subclasses, slots are the Widget
  // nodes whose RenderObjects are to be used as the "insert before"
  // sibling in ContainerRenderObjectMixin.add() calls

  MultiChildRenderObjectWrapper({ Key key, List<Widget> children })
    : this.children = children == null ? const [] : children,
      super(key: key) {
    assert(!_debugHasDuplicateIds());
  }

  final List<Widget> children;

  void walkChildren(WidgetTreeWalker walker) {
    for (Widget child in children)
      walker(child);
  }

  void insertChildRenderObject(RenderObjectWrapper child, Widget slot) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    RenderObject nextSibling = slot != null ? slot.renderObject : null;
    assert(nextSibling == null || nextSibling is RenderObject);
    assert(renderObject is ContainerRenderObjectMixin);
    renderObject.add(child.renderObject, before: nextSibling);
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void detachChildRenderObject(RenderObjectWrapper child) {
    final renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is ContainerRenderObjectMixin);
    assert(child.renderObject.parent == renderObject);
    renderObject.remove(child.renderObject);
    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  bool _debugHasDuplicateIds() {
    var idSet = new HashSet<Key>();
    for (var child in children) {
      assert(child != null);
      if (child.key == null)
        continue; // when these nodes are reordered, we just reassign the data

      if (!idSet.add(child.key)) {
        throw '''If multiple keyed nodes exist as children of another node, they must have unique keys. $this has duplicate child key "${child.key}".''';
      }
    }
    return false;
  }

  void syncRenderObject(MultiChildRenderObjectWrapper old) {
    super.syncRenderObject(old);

    final ContainerRenderObjectMixin renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is ContainerRenderObjectMixin);
    assert(old == null || old.renderObject == renderObject);

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

    final List<Widget> newChildren = children;
    final List<Widget> oldChildren = old == null ? const <Widget>[] : old.children;
    int childrenTop = 0;
    int newChildrenBottom = newChildren.length-1;
    int oldChildrenBottom = oldChildren.length-1;

    // top of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Widget oldChild = oldChildren[childrenTop];
      assert(oldChild.mounted);
      Widget newChild = newChildren[childrenTop];
      assert(newChild == oldChild || !newChild.mounted);
      if (!_canSync(oldChild, newChild))
        break;
      childrenTop += 1;
    }

    Widget nextSibling;

    // bottom of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Widget oldChild = oldChildren[oldChildrenBottom];
      assert(oldChild.mounted);
      Widget newChild = newChildren[newChildrenBottom];
      assert(newChild == oldChild || !newChild.mounted);
      if (!_canSync(oldChild, newChild))
        break;
      newChild = syncChild(newChild, oldChild, nextSibling);
      assert(newChild.mounted);
      assert(oldChild == newChild || !oldChild.mounted);
      newChildren[newChildrenBottom] = newChild;
      nextSibling = newChild;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    // middle of the lists - old list
    bool haveOldNodes = childrenTop <= oldChildrenBottom;
    Map<Key, Widget> oldKeyedChildren;
    if (haveOldNodes) {
      oldKeyedChildren = new Map<Key, Widget>();
      while (childrenTop <= oldChildrenBottom) {
        Widget oldChild = oldChildren[oldChildrenBottom];
        assert(oldChild.mounted);
        if (oldChild.key != null) {
          oldKeyedChildren[oldChild.key] = oldChild;
        } else {
          syncChild(null, oldChild, null);
        }
        oldChildrenBottom -= 1;
      }
    }

    // middle of the lists - new list
    while (childrenTop <= newChildrenBottom) {
      Widget oldChild;
      Widget newChild = newChildren[newChildrenBottom];
      if (haveOldNodes) {
        Key key = newChild.key;
        if (key != null) {
          oldChild = oldKeyedChildren[newChild.key];
          if (oldChild != null) {
            if (oldChild.runtimeType != newChild.runtimeType)
              oldChild = null;
            oldKeyedChildren.remove(key);
          }
        }
      }
      assert(newChild == oldChild || !newChild.mounted);
      newChild = syncChild(newChild, oldChild, nextSibling);
      assert(newChild.mounted);
      assert(oldChild == newChild || oldChild == null || !oldChild.mounted);
      newChildren[newChildrenBottom] = newChild;
      nextSibling = newChild;
      newChildrenBottom -= 1;
    }
    assert(oldChildrenBottom == newChildrenBottom);
    assert(childrenTop == newChildrenBottom+1);

    // now sync the top of the list
    while (childrenTop > 0) {
      childrenTop -= 1;
      Widget oldChild = oldChildren[childrenTop];
      assert(oldChild.mounted);
      Widget newChild = newChildren[childrenTop];
      assert(newChild == oldChild || !newChild.mounted);
      assert(_canSync(oldChild, newChild));
      newChild = syncChild(newChild, oldChild, nextSibling);
      assert(newChild.mounted);
      assert(oldChild == newChild || oldChild == null || !oldChild.mounted);
      newChildren[childrenTop] = newChild;
      nextSibling = newChild;
    }

    if (haveOldNodes && !oldKeyedChildren.isEmpty) {
      for (Widget oldChild in oldKeyedChildren.values)
        syncChild(null, oldChild, null);
    }

    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
  }

}

class WidgetSkyBinding extends SkyBinding {

  WidgetSkyBinding({ RenderView renderViewOverride: null })
      : super(renderViewOverride: renderViewOverride);

  static void initWidgetSkyBinding({ RenderView renderViewOverride: null }) {
    if (SkyBinding.instance == null)
      new WidgetSkyBinding(renderViewOverride: renderViewOverride);
    assert(SkyBinding.instance is WidgetSkyBinding);
  }

  EventDisposition dispatchEvent(sky.Event event, HitTestResult result) {
    assert(SkyBinding.instance == this);
    EventDisposition disposition = super.dispatchEvent(event, result);
    if (disposition == EventDisposition.consumed)
      return EventDisposition.consumed;
    for (HitTestEntry entry in result.path.reversed) {
      for (Widget target in RenderObjectWrapper.getWidgetsForRenderObject(entry.target)) {
        if (target is Listener) {
          EventDisposition targetDisposition = target._handleEvent(event);
          if (targetDisposition == EventDisposition.consumed) {
            return targetDisposition;
          } else if (targetDisposition == EventDisposition.processed) {
            disposition = EventDisposition.processed;
          }
        }
        target = target._parent;
      }
    }
    return disposition;
  }

  void beginFrame(double timeStamp) {
    Component.flushBuild();
    super.beginFrame(timeStamp);
  }

}

abstract class App extends StatefulComponent {

  App({ Key key }) : super(key: key);

  void _handleEvent(sky.Event event) {
    if (event.type == 'back')
      onBack();
  }

  void didMount() {
    super.didMount();
    SkyBinding.instance.addEventListener(_handleEvent);
  }

  void didUnmount() {
    super.didUnmount();
    SkyBinding.instance.removeEventListener(_handleEvent);
  }

  void syncFields(Component source) { }

  // Override this to handle back button behavior in your app
  // Call super.onBack() to finish the activity
  void onBack() {
    activity.finishCurrentActivity();
  }
}

abstract class AbstractWidgetRoot extends StatefulComponent {

  AbstractWidgetRoot() {
    _mounted = true;
    _scheduleComponentForRender(this);
  }

  void syncFields(AbstractWidgetRoot source) {
    assert(false);
    // if we get here, it implies that we have a parent
  }

  void _buildIfDirty() {
    assert(_dirty);
    assert(_mounted);
    assert(parent == null);
    _sync(null, null);
  }

}

class RenderViewWrapper extends OneChildRenderObjectWrapper {
  RenderViewWrapper({ Key key, Widget child }) : super(key: key, child: child);
  RenderView get renderObject => super.renderObject;
  RenderView createNode() => SkyBinding.instance.renderView;
}

class AppContainer extends AbstractWidgetRoot {
  AppContainer(this.app) {
    assert(SkyBinding.instance is WidgetSkyBinding);
  }
  final App app;
  Widget build() => new RenderViewWrapper(child: app);
}

AppContainer _container;
void runApp(App app, { RenderView renderViewOverride, bool enableProfilingLoop: false }) {
  WidgetSkyBinding.initWidgetSkyBinding(renderViewOverride: renderViewOverride);
  _container = new AppContainer(app);
  if (enableProfilingLoop) {
    new Timer.periodic(const Duration(milliseconds: 20), (_) {
      app._scheduleBuild();
    });
  }
}
void debugDumpApp() {
  if (_container != null)
    _container.toString().split('\n').forEach(print);
  else
    print("runApp() not yet called");
}


class RenderBoxToWidgetAdapter extends AbstractWidgetRoot {

  RenderBoxToWidgetAdapter(
    RenderObjectWithChildMixin<RenderBox> container,
    this.builder
  ) : _container = container, super() {
    assert(builder != null);
  }

  RenderObjectWithChildMixin<RenderBox> _container;
  RenderObjectWithChildMixin<RenderBox> get container => _container;
  void set container(RenderObjectWithChildMixin<RenderBox> value) {
    if (_container != value) {
      assert(value.child == null);
      if (renderObject != null) {
        assert(_container.child == renderObject);
        _container.child = null;
      }
      _container = value;
      if (renderObject != null) {
        _container.child = renderObject;
        assert(_container.child == renderObject);
      }
    }
  }

  final Builder builder;

  void _buildIfDirty() {
    super._buildIfDirty();
    if (renderObject.parent == null) {
      // we haven't attached it yet
      assert(_container.child == null);
      _container.child = renderObject;
    }
    assert(renderObject.parent == _container);
  }

  Widget build() => builder();
}
