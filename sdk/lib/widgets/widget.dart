// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:mirrors';
import 'dart:sky' as sky;

import '../base/hit_test.dart';
import '../rendering/box.dart';
import '../rendering/object.dart';
import '../rendering/sky_binding.dart';

export '../rendering/box.dart' show BoxConstraints, BoxDecoration, Border, BorderSide, EdgeDims;
export '../rendering/flex.dart' show FlexDirection;
export '../rendering/object.dart' show Point, Offset, Size, Rect, Color, Paint, Path;

final bool _shouldLogRenderDuration = false;

typedef void WidgetTreeWalker(Widget);

// All Effen nodes derive from Widget. All nodes have a _parent, a _key and
// can be sync'd.
abstract class Widget {

  Widget({ String key }) : _key = key {
    assert(_isConstructedDuringBuild());
  }

  // TODO(jackson): Remove this workaround for limitation of Dart mixins
  Widget._withKey(String key) : _key = key {
    assert(_isConstructedDuringBuild());
  }

  // you should not build the UI tree ahead of time, build it only during build()
  bool _isConstructedDuringBuild() => this is AbstractWidgetRoot || this is App || _inRenderDirtyComponents;

  String _key;
  String get key => _key;

  Widget _parent;
  Widget get parent => _parent;

  bool _mounted = false;
  bool _wasMounted = false;
  bool get mounted => _mounted;
  static bool _notifyingMountStatus = false;
  static List<Widget> _mountedChanged = new List<Widget>();

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

  // Override this if you have children and call walker on each child
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
  }
  void didMount() { }
  void didUnmount() { }

  RenderObject _root;
  RenderObject get root => _root;

  // Subclasses which implements Nodes that become stateful may return true
  // if the |old| node has become stateful and should be retained.
  // This is called immediately before _sync().
  // Component._retainStatefulNodeIfPossible() calls syncFields().
  bool _retainStatefulNodeIfPossible(Widget old) => false;

  void _sync(Widget old, dynamic slot);
  // 'slot' is the identifier that the parent RenderObjectWrapper uses to know
  // where to put this descendant

  Widget findAncestor(Type targetType) {
    var ancestor = _parent;
    while (ancestor != null && !reflectClass(ancestor.runtimeType).isSubtypeOf(reflectClass(targetType)))
      ancestor = ancestor._parent;
    return ancestor;
  }

  void remove() {
    _root = null;
    setParent(null);
  }

  void removeChild(Widget node) {
    node.remove();
  }

  void detachRoot();

  // Returns the child which should be retained as the child of this node.
  Widget syncChild(Widget node, Widget oldNode, dynamic slot) {

    assert(oldNode is! Component || (oldNode is Component && !oldNode._disqualifiedFromEverAppearingAgain)); // TODO(ianh): Simplify this once the analyzer is cleverer

    if (node == oldNode) {
      assert(node == null || node.mounted);
      assert(node is! RenderObjectWrapper || (node is RenderObjectWrapper && node._ancestor != null)); // TODO(ianh): Simplify this once the analyzer is cleverer
      return node; // Nothing to do. Subtrees must be identical.
    }

    if (node == null) {
      // the child in this slot has gone away
      assert(oldNode.mounted);
      oldNode.detachRoot();
      removeChild(oldNode);
      assert(!oldNode.mounted);
      return null;
    }

    if (oldNode != null) {
      if (oldNode.runtimeType == node.runtimeType && oldNode.key == node.key) {
        if (node._retainStatefulNodeIfPossible(oldNode)) {
          assert(oldNode.mounted);
          assert(!node.mounted);
          oldNode.setParent(this);
          oldNode._sync(node, slot);
          assert(oldNode.root is RenderObject);
          return oldNode;
        }
      } else {
        assert(oldNode.mounted);
        oldNode.detachRoot();
        removeChild(oldNode);
        oldNode = null;
      }
    }

    assert(!node.mounted);
    node.setParent(this);
    node._sync(oldNode, slot);
    assert(node.root is RenderObject);
    return node;
  }

  String toString() {
    if (key == null)
      return '$runtimeType(unkeyed)';
    return '$runtimeType("$key")';
  }

}


// Descendants of TagNode provide a way to tag RenderObjectWrapper and
// Component nodes with annotations, such as event listeners,
// stylistic information, etc.
abstract class TagNode extends Widget {

  TagNode(Widget child, { String key })
    : this.child = child, super(key: key);

  // TODO(jackson): Remove this workaround for limitation of Dart mixins
  TagNode._withKey(Widget child, String key)
    : this.child = child, super._withKey(key);

  Widget child;

  void walkChildren(WidgetTreeWalker walker) {
    walker(child);
  }

  void _sync(Widget old, dynamic slot) {
    Widget oldChild = old == null ? null : (old as TagNode).child;
    child = syncChild(child, oldChild, slot);
    assert(child.root != null);
    _root = child.root;
    assert(_root == root); // in case a subclass reintroduces it
  }

  void remove() {
    if (child != null)
      removeChild(child);
    super.remove();
  }

  void detachRoot() {
    if (child != null)
      child.detachRoot();
  }

}

class ParentDataNode extends TagNode {
  ParentDataNode(Widget child, this.parentData, { String key })
    : super(child, key: key);
  final ParentData parentData;
}

abstract class Inherited extends TagNode {

  Inherited({ String key, Widget child }) : super._withKey(child, key);

  void _sync(Widget old, dynamic slot) {
    if (old != null && syncShouldNotify(old)) {
      final Type ourRuntimeType = runtimeType;
      void notifyChildren(Widget child) {
        if (child is Component &&
            child._dependencies != null &&
            child._dependencies.contains(ourRuntimeType))
          child._dependenciesChanged();
        if (child.runtimeType != ourRuntimeType)
          child.walkChildren(notifyChildren);
      }
      walkChildren(notifyChildren);
    }
    super._sync(old, slot);
  }

  bool syncShouldNotify(Inherited old);

}

typedef void GestureEventListener(sky.GestureEvent e);
typedef void PointerEventListener(sky.PointerEvent e);
typedef void EventListener(sky.Event e);

class Listener extends TagNode  {

  Listener({
    String key,
    Widget child,
    EventListener onWheel,
    GestureEventListener onGestureFlingCancel,
    GestureEventListener onGestureFlingStart,
    GestureEventListener onGestureScrollStart,
    GestureEventListener onGestureScrollUpdate,
    GestureEventListener onGestureTap,
    GestureEventListener onGestureTapDown,
    PointerEventListener onPointerCancel,
    PointerEventListener onPointerDown,
    PointerEventListener onPointerMove,
    PointerEventListener onPointerUp,
    Map<String, sky.EventListener> custom
  }) : listeners = _createListeners(
         onWheel: onWheel,
         onGestureFlingCancel: onGestureFlingCancel,
         onGestureFlingStart: onGestureFlingStart,
         onGestureScrollUpdate: onGestureScrollUpdate,
         onGestureScrollStart: onGestureScrollStart,
         onGestureTap: onGestureTap,
         onGestureTapDown: onGestureTapDown,
         onPointerCancel: onPointerCancel,
         onPointerDown: onPointerDown,
         onPointerMove: onPointerMove,
         onPointerUp: onPointerUp,
         custom: custom
       ),
       super(child, key: key);

  final Map<String, sky.EventListener> listeners;

  static Map<String, sky.EventListener> _createListeners({
    EventListener onWheel,
    GestureEventListener onGestureFlingCancel,
    GestureEventListener onGestureFlingStart,
    GestureEventListener onGestureScrollStart,
    GestureEventListener onGestureScrollUpdate,
    GestureEventListener onGestureTap,
    GestureEventListener onGestureTapDown,
    PointerEventListener onPointerCancel,
    PointerEventListener onPointerDown,
    PointerEventListener onPointerMove,
    PointerEventListener onPointerUp,
    Map<String, sky.EventListener> custom
  }) {
    var listeners = custom != null ?
        new HashMap<String, sky.EventListener>.from(custom) :
        new HashMap<String, sky.EventListener>();

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

  void _handleEvent(sky.Event e) {
    sky.EventListener listener = listeners[e.type];
    if (listener != null) {
      listener(e);
    }
  }

}

abstract class Component extends Widget {

  Component({ String key, bool stateful })
      : _stateful = stateful != null ? stateful : false,
        _order = _currentOrder + 1,
        super._withKey(key);

  static Component _currentlyBuilding;
  bool get _isBuilding => _currentlyBuilding == this;

  bool _stateful;
  bool _dirty = true;
  bool _disqualifiedFromEverAppearingAgain = false;

  Widget _built;
  dynamic _slot; // cached slot from the last time we were synced

  void didMount() {
    assert(!_disqualifiedFromEverAppearingAgain);
    super.didMount();
  }

  void remove() {
    assert(_built != null);
    assert(root != null);
    removeChild(_built);
    _built = null;
    super.remove();
  }

  void detachRoot() {
    assert(_built != null);
    assert(root != null);
    _built.detachRoot();
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
  void _dependenciesChanged() {
    // called by Inherited.sync()
    scheduleBuild();
  }

  bool _retainStatefulNodeIfPossible(Component old) {
    assert(!_disqualifiedFromEverAppearingAgain);

    if (old == null || !old._stateful)
      return false;

    assert(runtimeType == old.runtimeType);
    assert(key == old.key);

    // Make |this|, the newly-created object, into the "old" Component, and kill it
    _stateful = false;
    _built = old._built;
    assert(_built != null);
    _disqualifiedFromEverAppearingAgain = true;

    // Make |old| the "new" component
    old._built = null;
    old._dirty = true;
    old.syncFields(this);
    return true;
  }

  // This is called by _retainStatefulNodeIfPossible(), during
  // syncChild(), just before _sync() is called.
  // This must be implemented on any subclass that can become stateful
  // (but don't call super.syncFields() if you inherit directly from
  // Component, since that'll fire an assert).
  // If you don't ever become stateful, then don't override this.
  void syncFields(Component source) {
    assert(false);
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
  //      assert(_built == null && old == null)
  // 2) Re-building (because a dirty flag got set):
  //      assert(_built != null && old == null)
  // 3) Syncing against an old version
  //      assert(_built == null && old != null)
  void _sync(Widget old, dynamic slot) {
    assert(_built == null || old == null);
    assert(!_disqualifiedFromEverAppearingAgain);

    Component oldComponent = old as Component;

    _slot = slot;

    var oldBuilt;
    if (oldComponent == null) {
      oldBuilt = _built;
    } else {
      assert(_built == null);
      oldBuilt = oldComponent._built;
    }

    int lastOrder = _currentOrder;
    _currentOrder = _order;
    _currentlyBuilding = this;
    _built = build();
    assert(_built != null);
    _currentlyBuilding = null;
    _currentOrder = lastOrder;

    _built = syncChild(_built, oldBuilt, slot);
    assert(_built != null);
    _dirty = false;
    _root = _built.root;
    assert(_root == root); // in case a subclass reintroduces it
    assert(root != null);
  }

  void _buildIfDirty() {
    assert(!_disqualifiedFromEverAppearingAgain);
    if (!_dirty || !_mounted)
      return;

    assert(root != null);
    _sync(null, _slot);
  }

  void scheduleBuild() {
    assert(!_disqualifiedFromEverAppearingAgain);
    if (_isBuilding || _dirty || !_mounted)
      return;
    _dirty = true;
    _scheduleComponentForRender(this);
  }

  void setState(Function fn()) {
    assert(_stateful);
    fn();
    scheduleBuild();
  }

  Widget build();

}

Set<Component> _dirtyComponents = new Set<Component>();
bool _buildScheduled = false;
bool _inRenderDirtyComponents = false;

List<int> _debugFrameTimes = <int>[];

void _absorbDirtyComponents(List<Component> list) {
  list.addAll(_dirtyComponents);
  _dirtyComponents.clear();
  list.sort((Component a, Component b) => a._order - b._order);
}

void _buildDirtyComponents() {
  Stopwatch sw;
  if (_shouldLogRenderDuration)
    sw = new Stopwatch()..start();

  _inRenderDirtyComponents = true;
  try {
    sky.tracing.begin('Widgets._buildDirtyComponents');
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
    _inRenderDirtyComponents = false;
    sky.tracing.end('Widgets._buildDirtyComponents');
  }

  Widget._notifyMountStatusChanged();

  if (_shouldLogRenderDuration) {
    sw.stop();
    _debugFrameTimes.add(sw.elapsedMicroseconds);
    if (_debugFrameTimes.length >= 1000) {
      _debugFrameTimes.sort();
      const int i = 99;
      print('_buildDirtyComponents: ${i+1}th fastest frame out of the last ${_debugFrameTimes.length}: ${_debugFrameTimes[i]} microseconds');
      _debugFrameTimes.clear();
    }
  }
}

void _scheduleComponentForRender(Component c) {
  _dirtyComponents.add(c);
  if (!_buildScheduled) {
    _buildScheduled = true;
    new Future.microtask(_buildDirtyComponents);
  }
}


// RenderObjectWrappers correspond to a desired state of a RenderObject.
// They are fully immutable, with one exception: A Widget which is a
// Component which lives within an MultiChildRenderObjectWrapper's
// children list, may be replaced with the "old" instance if it has
// become stateful.
abstract class RenderObjectWrapper extends Widget {

  RenderObjectWrapper({ String key }) : super(key: key);

  RenderObject createNode();

  static final Map<RenderObject, RenderObjectWrapper> _nodeMap =
      new HashMap<RenderObject, RenderObjectWrapper>();
  static RenderObjectWrapper _getMounted(RenderObject node) => _nodeMap[node];

  RenderObjectWrapper _ancestor;
  void insertChildRoot(RenderObjectWrapper child, dynamic slot);
  void detachChildRoot(RenderObjectWrapper child);

  void _sync(RenderObjectWrapper old, dynamic slot) {
    // TODO(abarth): We should split RenderObjectWrapper into two pieces so that
    //               RenderViewObject doesn't need to inherit all this code it
    //               doesn't need.
    assert(parent != null || this is RenderViewWrapper);
    if (old == null) {
      _root = createNode();
      _ancestor = findAncestor(RenderObjectWrapper);
      if (_ancestor is RenderObjectWrapper)
        _ancestor.insertChildRoot(this, slot);
    } else {
      assert(old is RenderObjectWrapper);
      _root = old.root;
      _ancestor = old._ancestor;
    }
    assert(_root == root); // in case a subclass reintroduces it
    assert(root != null);
    assert(mounted);
    _nodeMap[root] = this;
    syncRenderObject(old);
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
      assert(root.parentData != null);
      root.parentData.merge(parentData); // this will throw if the types aren't appropriate
      if (parent.root != null)
        parent.root.markNeedsLayout();
    }
  }

  void remove() {
    assert(root != null);
    _nodeMap.remove(root);
    super.remove();
  }

  void detachRoot() {
    assert(_ancestor != null);
    assert(root != null);
    _ancestor.detachChildRoot(this);
  }

}

abstract class LeafRenderObjectWrapper extends RenderObjectWrapper {

  LeafRenderObjectWrapper({ String key }) : super(key: key);

  void insertChildRoot(RenderObjectWrapper child, dynamic slot) {
    assert(false);
  }

  void detachChildRoot(RenderObjectWrapper child) {
    assert(false);
  }

}

abstract class OneChildRenderObjectWrapper extends RenderObjectWrapper {

  OneChildRenderObjectWrapper({ String key, Widget child })
    : _child = child, super(key: key);

  Widget _child;
  Widget get child => _child;

  void walkChildren(WidgetTreeWalker walker) {
    walker(child);
  }

  void syncRenderObject(RenderObjectWrapper old) {
    super.syncRenderObject(old);
    Widget oldChild = old == null ? null : (old as OneChildRenderObjectWrapper).child;
    _child = syncChild(child, oldChild, null);
  }

  void insertChildRoot(RenderObjectWrapper child, dynamic slot) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(root is RenderObjectWithChildMixin);
    assert(slot == null);
    root.child = child.root;
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void detachChildRoot(RenderObjectWrapper child) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(root is RenderObjectWithChildMixin);
    assert(root.child == child.root);
    root.child = null;
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void remove() {
    if (child != null)
      removeChild(child);
    super.remove();
  }
}

abstract class MultiChildRenderObjectWrapper extends RenderObjectWrapper {

  // In MultiChildRenderObjectWrapper subclasses, slots are RenderObject nodes
  // to use as the "insert before" sibling in ContainerRenderObjectMixin.add() calls

  MultiChildRenderObjectWrapper({ String key, List<Widget> children })
    : this.children = children == null ? const [] : children,
      super(key: key) {
    assert(!_debugHasDuplicateIds());
  }

  final List<Widget> children;

  void walkChildren(WidgetTreeWalker walker) {
    for(Widget child in children)
      walker(child);
  }

  void insertChildRoot(RenderObjectWrapper child, dynamic slot) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(slot == null || slot is RenderObject);
    assert(root is ContainerRenderObjectMixin);
    root.add(child.root, before: slot);
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void detachChildRoot(RenderObjectWrapper child) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(root is ContainerRenderObjectMixin);
    assert(child.root.parent == root);
    root.remove(child.root);
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void remove() {
    assert(children != null);
    for (var child in children) {
      assert(child != null);
      removeChild(child);
    }
    super.remove();
  }

  bool _debugHasDuplicateIds() {
    var idSet = new HashSet<String>();
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

    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    if (root is! ContainerRenderObjectMixin)
      return;

    var startIndex = 0;
    var endIndex = children.length;

    var oldChildren = old == null ? [] : old.children;
    var oldStartIndex = 0;
    var oldEndIndex = oldChildren.length;

    RenderObject nextSibling = null;
    Widget currentNode = null;
    Widget oldNode = null;

    void sync(int atIndex) {
      children[atIndex] = syncChild(currentNode, oldNode, nextSibling);
      assert(children[atIndex] != null);
    }

    // Scan backwards from end of list while nodes can be directly synced
    // without reordering.
    while (endIndex > startIndex && oldEndIndex > oldStartIndex) {
      currentNode = children[endIndex - 1];
      oldNode = oldChildren[oldEndIndex - 1];

      if (currentNode.runtimeType != oldNode.runtimeType || currentNode.key != oldNode.key) {
        break;
      }

      endIndex--;
      oldEndIndex--;
      sync(endIndex);
      nextSibling = children[endIndex].root;
    }

    HashMap<String, Widget> oldNodeIdMap = null;

    bool oldNodeReordered(String key) {
      return oldNodeIdMap != null &&
             oldNodeIdMap.containsKey(key) &&
             oldNodeIdMap[key] == null;
    }

    void advanceOldStartIndex() {
      oldStartIndex++;
      while (oldStartIndex < oldEndIndex &&
             oldNodeReordered(oldChildren[oldStartIndex].key)) {
        oldStartIndex++;
      }
    }

    void ensureOldIdMap() {
      if (oldNodeIdMap != null)
        return;

      oldNodeIdMap = new HashMap<String, Widget>();
      for (int i = oldStartIndex; i < oldEndIndex; i++) {
        var node = oldChildren[i];
        if (node.key != null)
          oldNodeIdMap.putIfAbsent(node.key, () => node);
      }
    }

    bool searchForOldNode() {
      if (currentNode.key == null)
        return false; // never re-order these nodes

      ensureOldIdMap();
      oldNode = oldNodeIdMap[currentNode.key];
      if (oldNode == null)
        return false;

      oldNodeIdMap[currentNode.key] = null; // mark it reordered
      assert(root is ContainerRenderObjectMixin);
      assert(old.root is ContainerRenderObjectMixin);
      assert(oldNode.root != null);

      if (old.root == root) {
        root.move(oldNode.root, before: nextSibling);
      } else {
        (old.root as ContainerRenderObjectMixin).remove(oldNode.root); // TODO(ianh): Remove cast once the analyzer is cleverer
        root.add(oldNode.root, before: nextSibling);
      }

      return true;
    }

    // Scan forwards, this time we may re-order;
    nextSibling = root.firstChild;
    while (startIndex < endIndex && oldStartIndex < oldEndIndex) {
      currentNode = children[startIndex];
      oldNode = oldChildren[oldStartIndex];

      if (currentNode.runtimeType == oldNode.runtimeType && currentNode.key == oldNode.key) {
        nextSibling = root.childAfter(nextSibling);
        sync(startIndex);
        startIndex++;
        advanceOldStartIndex();
        continue;
      }

      oldNode = null;
      searchForOldNode();
      sync(startIndex);
      startIndex++;
    }

    // New insertions
    oldNode = null;
    while (startIndex < endIndex) {
      currentNode = children[startIndex];
      sync(startIndex);
      startIndex++;
    }

    // Removals
    currentNode = null;
    while (oldStartIndex < oldEndIndex) {
      oldNode = oldChildren[oldStartIndex];
      syncChild(null, oldNode, null);
      advanceOldStartIndex();
    }

    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
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

  void dispatchEvent(sky.Event event, HitTestResult result) {
    assert(SkyBinding.instance == this);
    super.dispatchEvent(event, result);
    for (HitTestEntry entry in result.path.reversed) {
      Widget target = RenderObjectWrapper._getMounted(entry.target);
      if (target == null)
        continue;
      RenderObject targetRoot = target.root;
      while (target != null && target.root == targetRoot) {
        if (target is Listener)
          target._handleEvent(event);
        target = target._parent;
      }
    }
  }

}

abstract class App extends Component {

  // Apps are assumed to be stateful
  App({ String key }) : super(key: key, stateful: true);

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

  // Override this to handle back button behavior in your app
  void onBack() { }
}

abstract class AbstractWidgetRoot extends Component {

  AbstractWidgetRoot() : super(stateful: true) {
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
  RenderViewWrapper({ String key, Widget child }) : super(key: key, child: child);
  RenderView get root => super.root;
  RenderView createNode() => SkyBinding.instance.renderView;
}

class AppContainer extends AbstractWidgetRoot {
  AppContainer(this.app) {
    assert(SkyBinding.instance is WidgetSkyBinding);
  }
  final App app;
  Widget build() => new RenderViewWrapper(child: app);
}

void runApp(App app, { RenderView renderViewOverride, bool enableProfilingLoop: false }) {
  WidgetSkyBinding.initWidgetSkyBinding(renderViewOverride: renderViewOverride);
  new AppContainer(app);
  if (enableProfilingLoop) {
    new Timer.periodic(const Duration(milliseconds: 20), (_) {
      app.scheduleBuild();
    });
  }
}

typedef Widget Builder();

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
      if (root != null) {
        assert(_container.child == root);
        _container.child = null;
      }
      _container = value;
      if (root != null) {
        _container.child = root;
        assert(_container.child == root);
      }
    }
  }

  final Builder builder;

  void _buildIfDirty() {
    super._buildIfDirty();
    if (root.parent == null) {
      // we haven't attached it yet
      assert(_container.child == null);
      _container.child = root;
    }
    assert(root.parent == _container);
  }

  Widget build() => builder();
}
