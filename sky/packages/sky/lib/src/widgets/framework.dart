// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:sky' as sky;

import 'package:sky/animation.dart';
import 'package:sky/services.dart';
import 'package:sky/rendering.dart';

export 'package:sky/rendering.dart' show BoxConstraints, BoxDecoration, Border, BorderSide, EdgeDims, Point, Offset, Size, Rect, Color, Paint, Path;

final bool _shouldLogRenderDuration = false; // see also 'enableProfilingLoop' argument to runApp()

typedef Widget Builder();
typedef void WidgetTreeWalker(Widget widget);

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

typedef void GlobalKeySyncListener(GlobalKey key, Widget widget);
typedef void GlobalKeyRemoveListener(GlobalKey key);

abstract class GlobalKey extends Key {
  const GlobalKey.constructor() : super.constructor(); // so that subclasses can call us, since the Key() factory constructor shadows the implicit constructor
  factory GlobalKey({ String label }) => new LabeledGlobalKey(label); // the label is purely for debugging purposes and is otherwise ignored

  static final Map<GlobalKey, Widget> _registry = new Map<GlobalKey, Widget>();
  static final Map<GlobalKey, int> _debugDuplicates = new Map<GlobalKey, int>();
  static final Map<GlobalKey, Set<GlobalKeySyncListener>> _syncListeners = new Map<GlobalKey, Set<GlobalKeySyncListener>>();
  static final Map<GlobalKey, Set<GlobalKeyRemoveListener>> _removeListeners = new Map<GlobalKey, Set<GlobalKeyRemoveListener>>();
  static final Set<GlobalKey> _syncedKeys = new Set<GlobalKey>();
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

  void _didSync() {
    _syncedKeys.add(this);
  }

  static void registerSyncListener(GlobalKey key, GlobalKeySyncListener listener) {
    assert(key != null);
    Set<GlobalKeySyncListener> listeners =
        _syncListeners.putIfAbsent(key, () => new Set<GlobalKeySyncListener>());
    bool added = listeners.add(listener);
    assert(added);
  }

  static void unregisterSyncListener(GlobalKey key, GlobalKeySyncListener listener) {
    assert(key != null);
    assert(_syncListeners.containsKey(key));
    bool removed = _syncListeners[key].remove(listener);
    if (_syncListeners[key].isEmpty)
      _syncListeners.remove(key);
    assert(removed);
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

  static Widget getWidget(GlobalKey key) {
    assert(key != null);
    return _registry[key];
  }

  static void _notifyListeners() {
    assert(!_inBuildDirtyComponents);
    assert(!Widget._notifyingMountStatus);
    assert(() {
      String message = '';
      for (GlobalKey key in _debugDuplicates.keys) {
        message += 'Duplicate GlobalKey found amongst mounted widgets: $key (${_debugDuplicates[key]} instances)\n';
        message += 'Most recently registered instance is:\n${_registry[key]}\n';
      }
      if (!_debugDuplicates.isEmpty)
        throw message;
      return true;
    });
    if (_syncedKeys.isEmpty && _removedKeys.isEmpty)
      return;
    try {
      for (GlobalKey key in _syncedKeys) {
        Widget widget = _registry[key];
        if (widget != null && _syncListeners.containsKey(key)) {
          Set<GlobalKeySyncListener> localListeners = new Set<GlobalKeySyncListener>.from(_syncListeners[key]);
          for (GlobalKeySyncListener listener in localListeners)
            listener(key, widget);
        }
      }
      for (GlobalKey key in _removedKeys) {
        if (!_registry.containsKey(key) && _removeListeners.containsKey(key)) {
          Set<GlobalKeyRemoveListener> localListeners = new Set<GlobalKeyRemoveListener>.from(_removeListeners[key]);
          for (GlobalKeyRemoveListener listener in localListeners)
            listener(key);
        }
      }
    } finally {
      _removedKeys.clear();
      _syncedKeys.clear();
    }
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

  // The "generation" of a Widget is the frame in which it was last
  // synced. We use this to tell if an instance of a Widget has moved
  // to earlier in the tree so that when we come across where it used
  // to be, we pretend it was never there. See syncChild().
  static int _currentGeneration = 1;
  int _generation = 0;
  bool get isFromOldGeneration => _generation < _currentGeneration;
  void _markAsFromCurrentGeneration() { _generation = _currentGeneration; }

  bool get _hasState => false;
  static bool _canSync(Widget a, Widget b) {
    assert(a != null);
    assert(b != null);
    return (a == b) ||
           (a.runtimeType == b.runtimeType &&
            a.key == b.key &&
            (!a._hasState || !b._hasState));
  }

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

  /// Walks the immediate children of this widget.
  ///
  /// Override this if you have children and call walker on each child.
  /// Note that you may be called before the child has had its parent
  /// pointer set to point to you. Your walker, and any methods it
  /// invokes on your descendants, should not rely on the ancestor
  /// chain being correctly configured at this point.
  void walkChildren(WidgetTreeWalker walker) { }

  /// If the object has a single child, return it. Override this if
  /// you define a new child model with only one child.
  Widget get singleChild => null;

  /// Detaches the single child of this object from this object,
  /// without calling remove() on that child.
  /// Only called when singleChild returns a non-null node.
  /// Override this if you override singleChild to return non-null.
  void takeChild() {
    assert(singleChild != null);
    throw '${runtimeType} does not define a "takeChild()" method';
  }

  static void _notifyMountStatusChanged() {
    try {
      sky.tracing.begin('Widget._notifyMountStatusChanged');
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
      sky.tracing.end('Widget._notifyMountStatusChanged');
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
  // Component.retainStatefulNodeIfPossible() calls syncConstructorArguments().
  // This is only ever called on a node A with an argument B if _canSync(A, B)
  // is true. It's ok if after calling retainStatefulNodeIfPossible(), the two
  // nodes no longer return true from _canSync().
  bool retainStatefulNodeIfPossible(Widget newNode) => false;

  void _sync(Widget old, dynamic slot) {
    // When this is called, old must be from an old generation. It's a violation
    // of the _sync() contract to call _sync() with an old node that has already
    // been synced this generation, as this means that that node is elsewhere in
    // the tree by now.
    // By the time we get here, though, syncChild() has already been called on
    // our children (by the subclasses overriding this). This means 'old' may
    // have been moved to somewhere else in the tree and might therefore already
    // be from a new generation.
    assert(isFromOldGeneration);
    _markAsFromCurrentGeneration();
    if (old != null && old != this)
      old._markAsFromCurrentGeneration();
    if (key is GlobalKey)
      (key as GlobalKey)._didSync(); // TODO(ianh): Remove the cast once the analyzer is cleverer.
  }
  void updateSlot(dynamic newSlot);
  // 'slot' is the identifier that the ancestor RenderObjectWrapper uses to know
  // where to put this descendant. If you just defer to a child, then make sure
  // to pass them the slot.

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
    walkChildren((Widget child) {
      if (child.isFromOldGeneration || !isFromOldGeneration) {
        assert(child.parent == this);
        child.remove();
      } else {
        // if it's from the current generation and we're not, it means it's been moved somewhere else in the tree already and isn't really our child anymore
        assert(child.parent != this);
      }
    });
    _renderObject = null;
    setParent(null);
  }

  void detachRenderObject();

  Widget _getCandidateSingleChildFrom(Widget oldChild) {
    Widget candidate = oldChild.singleChild;
    if (candidate != null && !candidate.isFromOldGeneration)
      candidate = null;
    assert(candidate == null || candidate.parent == oldChild);
    return candidate;
  }

  // Returns the child which should be retained as the child of this node.
  Widget syncChild(Widget newNode, Widget oldNode, dynamic slot) {
    String debugDetails;
    assert(() {
      // we save this information early because by the time the exception fires we might have changed everything around
      debugDetails = '  old child: $oldNode\n  new child: $newNode';
      return true;
    });
    try {

      // At this point, oldNode might have been moved to a new part in the tree.
      // If this has happened, it will already have been synced, in which case
      // it will be from a new generation. Our contract with _sync() is that we
      // will not pass an old child that has been moved to elsewhere in the
      // tree, so it's important that we verify at each step here that we're not
      // dealing with such a child. This is why this function keeps checking
      // isFromOldGeneration on the candidate "old" children.

      if (newNode == oldNode) {
        // If our child literally hasn't changed identity, short-circuit the
        // work. That subtree hasn't changed. We still need to set the parent
        // because _we_ might have changed identity, even if the child hasn't.
        assert(newNode is! RenderObjectWrapper ||
               (newNode is RenderObjectWrapper && newNode._ancestor != null)); // if the child didn't change, it had better be configured
        assert(newNode is! StatefulComponent ||
               (newNode is StatefulComponent && newNode._isStateInitialized)); // if the child didn't change, it had better be configured
        // TODO(ianh): Simplify the two asserts above once the analyzer is cleverer
        if (newNode != null) {
          newNode.setParent(this);
          newNode._markAsFromCurrentGeneration();
        }
        return newNode; // Nothing to do. Subtrees must be identical.
      }

      // if the old node isn't the same as the new node and has already been synced, then
      // we must assume that it has been moved elsewhere in the tree and isn't really a
      // match for the node we're trying to insert.
      if (oldNode != null && !oldNode.isFromOldGeneration)
        oldNode = null;

      if (newNode == null) {
        // the child in this slot has gone away
        // remove it if they old one is still here
        if (oldNode != null) {
          assert(oldNode != null);
          assert(oldNode.isFromOldGeneration);
          assert(oldNode.mounted);
          oldNode.detachRenderObject();
          oldNode.remove();
          assert(!oldNode.mounted);
          // we don't update the generation of oldNode, because there's
          // still a chance it could be reused as-is later in the tree.
        }
        return null;
      }

      if (oldNode != null) {
        assert(newNode != null);
        assert(newNode.isFromOldGeneration);
        assert(oldNode.isFromOldGeneration);
        if (!Widget._canSync(newNode, oldNode)) {
          assert(oldNode.mounted);
          // We want to handle the case where there is a removal of zero
          // or more widgets. In this case, we should be able to sync
          // ourselves with a Widget that is a descendant of the
          // oldNode, skipping the nodes in between. Let's try that.
          Widget deadNode = oldNode;
          Widget candidate = _getCandidateSingleChildFrom(oldNode);
          oldNode = null;

          while (candidate != null) {
            if (Widget._canSync(newNode, candidate)) {
              assert(candidate.parent != null);
              assert(candidate.parent.singleChild == candidate);
              if (candidate.renderObject != deadNode.renderObject) {
                // TODO(ianh): Handle removal across RenderNode boundaries
              } else {
                candidate.parent.takeChild();
                oldNode = candidate;
              }
              break;
            }
            candidate = _getCandidateSingleChildFrom(candidate);
          }

          // TODO(ianh): Handle insertion, too...

          if (oldNode == null)
            deadNode.detachRenderObject();
          deadNode.remove();
        }
        if (oldNode != null) {
          assert(newNode.isFromOldGeneration);
          assert(oldNode.isFromOldGeneration);
          assert(Widget._canSync(newNode, oldNode));
          if (oldNode == newNode) {
            newNode.setParent(this);
            newNode._markAsFromCurrentGeneration();
            return newNode;
          } else if (oldNode.retainStatefulNodeIfPossible(newNode)) {
            assert(oldNode.mounted);
            assert(!newNode.mounted);
            oldNode.setParent(this);
            oldNode._sync(newNode, slot);
            assert(oldNode.renderObject is RenderObject);
            return oldNode;
          } else {
            oldNode.setParent(null);
          }
        }
      }

      assert(oldNode == null || (oldNode.mounted == false && oldNode.parent == null && newNode.mounted == false && oldNode.isFromOldGeneration && newNode.isFromOldGeneration));
      assert(oldNode != newNode);
      newNode.setParent(this);
      newNode._sync(oldNode, slot);
      assert(newNode.renderObject is RenderObject);
      return newNode;

    } catch (e, stack) {
      _debugReportException('syncing children of $this\n$debugDetails', e, stack);
      return null;
    }
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

  String toString() {
    List<String> details = <String>[];
    debugAddDetails(details);
    String detailString = details.join('; ');
    return '$runtimeType($detailString})';
  }
  void debugAddDetails(List<String> details) {
    if (key != null)
      details.add('$key');
    details.add('hashCode=$hashCode');
    details.add(mounted ? 'mounted' : 'not mounted');
    if (_generation != _currentGeneration) {
      if (_generation == 0) {
        details.add('never synced');
      } else {
        int delta = _generation - _currentGeneration;
        String sign = delta < 0 ? '' : '+';
        details.add('gen$sign$delta');
      }
    }
  }
  String toStringDeep([String prefix = '', String startPrefix = '']) {
    String childrenString = '';
    List<Widget> children = new List<Widget>();
    walkChildren(children.add);
    if (children.length > 0) {
      Widget lastChild = children.removeLast();
      String nextStartPrefix = prefix + ' +-';
      String nextPrefix = prefix + ' | ';
      for (Widget child in children)
        childrenString += child.toStringDeep(nextPrefix, _adjustPrefixWithParentCheck(child, nextStartPrefix));
      nextStartPrefix = prefix + ' \'-';
      nextPrefix = prefix + '   ';
      childrenString += lastChild.toStringDeep(nextPrefix, _adjustPrefixWithParentCheck(lastChild, nextStartPrefix));
    }
    return '$startPrefix$this\n$childrenString';
  }
  String _adjustPrefixWithParentCheck(Widget child, String prefix) {
    if (child.parent == this)
      return prefix;
    if (child.parent == null)
      return '$prefix [[DISCONNECTED]] ';
    return '$prefix [[PARENT IS ${child.parent}]] ';
  }
}


// Descendants of TagNode provide a way to tag RenderObjectWrapper and
// Component nodes with annotations, such as event listeners,
// stylistic information, etc.
abstract class TagNode extends Widget {

  TagNode({ Key key, Widget child })
    : child = child, super(key: key) {
    assert(child != null);
  }

  // TODO(jackson): Remove this workaround for limitation of Dart mixins
  TagNode._withKey(Widget child, Key key)
    : child = child, super._withKey(key);

  Widget child;

  void walkChildren(WidgetTreeWalker walker) {
    if (child != null)
      walker(child);
  }

  Widget get singleChild => child;

  bool _debugChildTaken = false;

  void takeChild() {
    assert(!_debugChildTaken);
    assert(singleChild == child);
    assert(child != null);
    child = null;
    _renderObject = null;
    assert(() { _debugChildTaken = true; return true; });
  }

  void _sync(TagNode old, dynamic slot) {
    assert(!_debugChildTaken);
    child = syncChild(child, old?.child, slot);
    if (child != null) {
      assert(child.parent == this);
      assert(child.renderObject != null);
      _renderObject = child.renderObject;
      assert(_renderObject == renderObject); // in case a subclass reintroduces it
    } else {
      _renderObject = null;
    }
    super._sync(old, slot);
  }

  void updateSlot(dynamic newSlot) {
    child.updateSlot(newSlot);
  }

  void detachRenderObject() {
    assert(!_debugChildTaken);
    if (child != null)
      child.detachRenderObject();
  }

}

abstract class ParentDataNode extends TagNode {
  ParentDataNode({ Key key, Widget child })
    : super(key: key, child: child);

  /// Subclasses should override this function to ensure that they are placed
  /// inside widgets that expect them.
  ///
  /// The given ancestor is the first non-component ancestor of this widget.
  void debugValidateAncestor(Widget ancestor);
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

class Listener extends TagNode  {
  Listener({
    Key key,
    Widget child,
    PointerEventListener this.onPointerDown,
    PointerEventListener this.onPointerMove,
    PointerEventListener this.onPointerUp,
    PointerEventListener this.onPointerCancel
  }) : super(key: key, child: child);

  final PointerEventListener onPointerDown;
  final PointerEventListener onPointerMove;
  final PointerEventListener onPointerUp;
  final PointerEventListener onPointerCancel;

  void _handleEvent(sky.Event event) {
    if (onPointerDown != null && event.type == 'pointerdown')
      return onPointerDown(event);
    if (onPointerMove != null && event.type == 'pointermove')
      return onPointerMove(event);
    if (onPointerUp != null && event.type == 'pointerup')
      return onPointerUp(event);
    if (onPointerCancel != null && event.type == 'pointercancel')
      return onPointerCancel(event);
  }
}

abstract class Component extends Widget {

  Component({ Key key })
      : _order = _currentOrder + 1,
        super._withKey(key);

  bool _debugIsBuilding = false;
  static Queue<Component> _debugComponentBuildTree = new Queue<Component>();

  bool _dirty = true;
  Widget _child;

  void walkChildren(WidgetTreeWalker walker) {
    if (_child != null)
      walker(_child);
  }

  Widget get singleChild => _child;

  bool _debugChildTaken = false;

  void takeChild() {
    assert(!_debugChildTaken);
    assert(singleChild == _child);
    assert(_child != null);
    _child = null;
    _renderObject = null;
    assert(() { _debugChildTaken = true; return true; });
  }

  void remove() {
    assert(_debugChildTaken || (_child != null && _renderObject != null));
    super.remove();
    _child = null;
    _renderObject = null;
  }

  void detachRenderObject() {
    assert(!_debugChildTaken);
    if (_child != null)
      _child.detachRenderObject();
  }

  void dependenciesChanged() {
    // called by Inherited.sync()
    _scheduleBuild();
  }

  dynamic _slot; // cached slot from the last time we were synced

  void updateSlot(dynamic newSlot) {
    _slot = newSlot;
    if (_child != null)
      _child.updateSlot(newSlot);
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
  // 3) Syncing against an old version (we are either new, or Stateful and pretending to be new)
  //      assert(_child == null && old != null)
  void _sync(Component old, dynamic slot) {
    assert(!_debugChildTaken);
    assert(_child == null || old == null);
    assert(old == null || old.isFromOldGeneration);

    updateSlot(slot);

    Widget oldChild;
    if (old == null) {
      oldChild = _child;
      _child = null;
    } else {
      oldChild = old._child;
      old._child = null;
      assert(_child == null);
    }

    assert(() {
      _debugIsBuilding = true;
      _debugComponentBuildTree.add(this);
      return true;
    });

    int lastOrder = _currentOrder;
    _currentOrder = _order;
    try {
      _child = build();
      assert(_child != null);
    } catch (e, stack) {
      _debugReportException('building $this', e, stack);
    }
    _currentOrder = lastOrder;
    assert(() { _debugChildTaken = false; return true; });
    try {
      // even if build() failed (i.e. _child == null), we still call syncChild(), to remove the oldChild
      _child = syncChild(_child, oldChild, slot);
      assert(!_debugChildTaken); // we shouldn't be able to lose our child when we're syncing it!
      assert(_child == null || _child.parent == this);
      assert(_child == null || _child.renderObject != null);
    } catch (e, stack) {
      _debugReportException('syncing build output of $this\n  old child: $oldChild\n  new child: $_child', e, stack);
      _child = null;
    }
    assert(() {
      if (_child == null) {
        try {
          _child = new ErrorWidget()..setParent(this).._sync(null, slot);
        } catch (e) {
          print('(application is now in an unstable state - ignore any subsequent exceptions)');
        }
      }
      _debugIsBuilding = false;
      return identical(_debugComponentBuildTree.removeLast(), this);
    });

    _dirty = false;
    _renderObject = _child.renderObject;
    assert(_renderObject == renderObject); // in case a subclass reintroduces it
    super._sync(old, slot);
  }

  void _markAsFromCurrentGeneration() {
    if (_dirty)
      return;
    super._markAsFromCurrentGeneration();
  }

  void _buildIfDirty() {
    if (!_dirty || !_mounted)
      return;
    assert(isFromOldGeneration);
    assert(renderObject != null);
    _sync(null, _slot);
  }

  void _scheduleBuild() {
    assert(!_debugIsBuilding);
    if (_dirty || !_mounted)
      return;
    _dirty = true;
    _scheduleComponentForBuild(this);
  }

  static void flushBuild() {
    if (!_dirtyComponents.isEmpty)
      _buildDirtyComponents();
  }

  Widget build();

  void debugAddDetails(List<String> details) {
    super.debugAddDetails(details);
    if (_dirty)
      details.add('dirty');
  }
}

abstract class StatefulComponent extends Component {

  StatefulComponent({ Key key }) : super(key: key);

  bool _isStateInitialized = false;

  bool get _hasState => _isStateInitialized;

  bool retainStatefulNodeIfPossible(StatefulComponent newNode) {
    assert(newNode != null);
    assert(!newNode._isStateInitialized);
    assert(this != newNode);
    assert(Widget._canSync(this, newNode));
    assert(_child != null);

    newNode._child = _child;
    _child = null;
    _dirty = true;

    return true;
  }

  // because our retainStatefulNodeIfPossible() method returns true,
  // when _sync is called, our 'old' is actually the new instance that
  // we are to copy state from.
  void _sync(StatefulComponent old, dynamic slot) {
    if (old == null) {
      if (!_isStateInitialized) {
        assert(mounted);
        assert(!_wasMounted);
        initState();
        _isStateInitialized = true;
      }
    } else {
      assert(_isStateInitialized);
      assert(!old._isStateInitialized);
      assert(old.isFromOldGeneration);
      syncConstructorArguments(old);
    }
    super._sync(old, slot);
    assert(_child != null);
  }

  // Stateful components can override initState if they want
  // to do non-trivial work to initialize state. This is
  // always called before build().
  void initState() { }

  // This is called by _sync(). Derived classes should override this
  // method to update `this` to account for the new values the parent
  // passed to `source`. Make sure to call super.syncConstructorArguments(source)
  // unless you are extending StatefulComponent directly.
  // A given source can be used multiple times as a source.
  // The source must not be mutated.
  void syncConstructorArguments(Component source);

  // Calls function fn immediately and then schedules another build
  // for this Component.
  void setState(void fn()) {
    assert(!_debugIsBuilding);
    assert(_isStateInitialized);
    fn();
    _scheduleBuild();
  }

  void debugAddDetails(List<String> details) {
    super.debugAddDetails(details);
    details.add(_isStateInitialized ? 'stateful' : 'stateless');
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
  _endSyncPhase();
}

List<int> _debugFrameTimes = <int>[];

// TODO(ianh): Move this to Component
void _absorbDirtyComponents(List<Component> list) {
  list.addAll(_dirtyComponents);
  _dirtyComponents.clear();
  list.sort((Component a, Component b) => a._order - b._order);
}

// TODO(ianh): Move this to Component
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
    _endSyncPhase();
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

// TODO(ianh): Move this to Widget
void _endSyncPhase() {
  try {
    Widget._currentGeneration += 1;
    Widget._notifyMountStatusChanged();
  } catch (e, stack) {
    _debugReportException('sending post-sync notifications', e, stack);
    return null;
  }
}

// TODO(ianh): Move this to Component
void _scheduleComponentForBuild(Component component) {
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

  bool get _hasState => _renderObject != null;

  void retainStatefulRenderObjectWrapper(RenderObjectWrapper newNode) {
    newNode._renderObject = _renderObject;
    newNode._ancestor = _ancestor;
  }

  RenderObjectWrapper findAncestorRenderObjectWrapper() {
    Widget ancestor = parent;
    while (ancestor != null && ancestor is! RenderObjectWrapper)
      ancestor = ancestor.parent;
    return ancestor;
  }

  void _sync(RenderObjectWrapper old, dynamic slot) {
    // TODO(abarth): We should split RenderObjectWrapper into two pieces so that
    //               RenderViewObject doesn't need to inherit all this code it
    //               doesn't need.
    assert(parent != null || this is RenderViewWrapper);
    assert(old == null || old.isFromOldGeneration);
    if (old == null) {
      _renderObject = createNode();
      assert(_renderObject != null);
      _ancestor = findAncestorRenderObjectWrapper();
      if (_ancestor != null)
        _ancestor.insertChildRenderObject(this, slot);
    } else {
      _renderObject = old.renderObject;
      _ancestor = old._ancestor;
      assert(_renderObject != null);
    }
    assert(() {
      _renderObject.debugExceptionContext = Component._debugComponentBuildTree.fold('  Widget build stack:', (String result, Component component) => result + '\n    $component');
      return true;
    });
    assert(_renderObject == renderObject); // in case a subclass reintroduces it
    assert(renderObject != null);
    assert(mounted);
    _nodeMap[renderObject] = this;
    syncRenderObject(old);
    super._sync(old, slot);
  }

  void updateSlot(dynamic newSlot) {
    // We never use the slot except during sync(), in which
    // case our parent is handing it to us anyway.
    // We don't need to propagate this to our children, since
    // we give them their own slots for them to fit into us.
  }

  /// Override this function if your RenderObjectWrapper uses a [ParentDataNode]
  /// to program parent data into children.
  void updateParentData(RenderObject child, ParentDataNode node) { }

  void syncRenderObject(RenderObjectWrapper old) {
    assert(old == null || old.renderObject == renderObject);
    ParentDataNode parentDataNode = null;
    for (Widget current = parent; current != null; current = current.parent) {
      assert(() {
        if (current is ParentDataNode) {
          Widget ancestor = current.parent;
          while (ancestor is Component)
            ancestor = ancestor.parent;
          // ancestor might be null in two cases:
          //  - asking for the ancestor of a Widget that has no non-Component
          //    ancestors between itself and its AbstractWidgetRoot ancestor
          //  - if the node is just being synced to get its intrinsic
          //    dimensions, as e.g. MixedViewport does.
          if (ancestor != null)
            current.debugValidateAncestor(ancestor);
        }
        return true;
      });
      if (current is ParentDataNode) {
        assert(parentDataNode == null);
        parentDataNode = current;
      } else if (current is RenderObjectWrapper) {
        current.updateParentData(renderObject, parentDataNode);
        break;
      }
    }
  }

  // for use by subclasses that manage their children using lists
  void syncChildren(List<Widget> newChildren, List<Widget> oldChildren) {
    assert(newChildren != null);
    assert(oldChildren != null);
    assert(!identical(newChildren, oldChildren));

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

    final ContainerRenderObjectMixin renderObject = this.renderObject; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(renderObject is ContainerRenderObjectMixin);

    int childrenTop = 0;
    int newChildrenBottom = newChildren.length-1;
    int oldChildrenBottom = oldChildren.length-1;

    // top of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Widget oldChild = oldChildren[childrenTop];
      Widget newChild = newChildren[childrenTop];
      if (oldChild != newChild && !oldChild.isFromOldGeneration) {
        // even if the two nodes could in theory be synced, they can't really because
        // it would seem that the old node has already been synced elsewhere in the tree.
        break;
      }
      assert(oldChild.mounted);
      if (!Widget._canSync(oldChild, newChild))
        break;
      childrenTop += 1;
    }

    Widget nextSibling;

    // bottom of the lists
    while ((childrenTop <= oldChildrenBottom) && (childrenTop <= newChildrenBottom)) {
      Widget oldChild = oldChildren[oldChildrenBottom];
      Widget newChild = newChildren[newChildrenBottom];
      if (oldChild != newChild && !oldChild.isFromOldGeneration) {
        // even if the two nodes could in theory be synced, they can't really because
        // it would seem that the old node has already been synced elsewhere in the tree.
        break;
      }
      assert(oldChild.mounted);
      if (!Widget._canSync(oldChild, newChild))
        break;
      assert(oldChild == newChild || !newChild.mounted);
      newChild = syncChild(newChild, oldChild, nextSibling);
      assert(newChild.mounted);
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
          // Let's give up trying to sync this node with a new node. If this
          // child is from the old generation, then we'll remove it from our
          // child list. It it's not, then that means it's already been synced
          // elsewhere and we should leave it alone.
          if (oldChild.isFromOldGeneration)
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
            if ((Widget._canSync(oldChild, newChild)) &&
                (oldChild == newChild || oldChild.isFromOldGeneration)) {
              // we found a match!
              // remove it from oldKeyedChildren so we don't unsync it later
              oldKeyedChildren.remove(key);
            } else {
              // Either it wasn't a match, or it's already been synced elsewhere in the tree.
              // In either case, let's pretend we didn't see it for now.
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || Widget._canSync(oldChild, newChild));
      assert(oldChild == newChild || !newChild.mounted);
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
      assert(Widget._canSync(oldChild, newChild));
      newChild = syncChild(newChild, oldChild, nextSibling);
      assert(newChild.mounted);
      assert(oldChild == newChild || oldChild == null || !oldChild.mounted);
      newChildren[childrenTop] = newChild;
      nextSibling = newChild;
    }

    // clean up any of the remaining middle nodes from the old list
    if (haveOldNodes && !oldKeyedChildren.isEmpty) {
      for (Widget oldChild in oldKeyedChildren.values)
        if (oldChild.isFromOldGeneration)
          syncChild(null, oldChild, null);
    }

    assert(renderObject == this.renderObject); // TODO(ianh): Remove this once the analyzer is cleverer
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
    assert(renderObject != null);
    assert(_ancestor != null);
    assert(_ancestor.renderObject != null);
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

  Widget get singleChild => _child;

  bool _debugChildTaken = false;

  void takeChild() {
    assert(!_debugChildTaken);
    assert(singleChild == child);
    assert(child != null);
    _child = null;
    assert(() { _debugChildTaken = true; return true; });
  }

  void syncRenderObject(RenderObjectWrapper old) {
    assert(!_debugChildTaken);
    super.syncRenderObject(old);
    Widget oldChild = (old as OneChildRenderObjectWrapper)?.child;
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
    RenderObject nextSibling = slot?.renderObject;
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
        throw 'If multiple keyed nodes exist as children of another node, they must have unique keys. $this has multiple children with key "${child.key}".';
      }
    }
    return false;
  }

  void syncRenderObject(MultiChildRenderObjectWrapper old) {
    super.syncRenderObject(old);
    List<Widget> oldChildren = old == null ? const <Widget>[] : old.children;
    if (oldChildren == children) {
      int index = children.length;
      Widget nextSibling = null;
      while (index > 0) {
        index -= 1;
        Widget child = children[index];
        nextSibling = syncChild(child, child, nextSibling);
        children[index] = nextSibling;
      }
    } else {
      syncChildren(children, oldChildren);
    }
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

  void handleEvent(sky.Event event, BindingHitTestEntry entry) {
    for (HitTestEntry entry in entry.result.path) {
      if (entry.target is! RenderObject)
        continue;
      for (Widget target in RenderObjectWrapper.getWidgetsForRenderObject(entry.target)) {
        if (target is Listener)
          target._handleEvent(event);
      }
    }
    super.handleEvent(event, entry);
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

  void syncConstructorArguments(Component source) { }

  // Override this to handle back button behavior in your app
  // Call super.onBack() to finish the activity
  void onBack() {
    activity.finishCurrentActivity();
  }
}

abstract class AbstractWidgetRoot extends StatefulComponent {

  AbstractWidgetRoot() {
    _mounted = true;
    _scheduleComponentForBuild(this);
  }

  void syncConstructorArguments(AbstractWidgetRoot source) {
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

/// Prints a textual representation of the entire widget tree
void debugDumpApp() {
  if (_container != null)
    _container.toStringDeep().split('\n').forEach(print);
  else
    print('runApp() not yet called');
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

class ErrorWidget extends LeafRenderObjectWrapper {
  RenderBox createNode() => new RenderErrorBox();
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
  print('Build stack:');
  Component._debugComponentBuildTree.forEach((Component component) { print('  $component'); });
  if (debugWidgetsExceptionHandler != null)
    debugWidgetsExceptionHandler(context, exception, stack);
  print('------------------------------------------------------------------------');
}
