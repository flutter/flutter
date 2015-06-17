// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:mirrors';
import 'dart:sky' as sky;

import '../app/view.dart';
import '../rendering/box.dart';
import '../rendering/object.dart';

export '../rendering/box.dart' show BoxConstraints, BoxDecoration, Border, BorderSide, EdgeDims;
export '../rendering/flex.dart' show FlexDirection;
export '../rendering/object.dart' show Point, Size, Rect, Color, Paint, Path;

final bool _shouldLogRenderDuration = false;

// All Effen nodes derive from Widget. All nodes have a _parent, a _key and
// can be sync'd.
abstract class Widget {

  Widget({ String key }) {
    _key = key != null ? key : runtimeType.toString();
    assert(this is AbstractWidgetRoot || _inRenderDirtyComponents); // you should not build the UI tree ahead of time, build it only during build()
  }

  String _key;
  String get key => _key;

  Widget _parent;
  Widget get parent => _parent;

  bool _mounted = false;
  bool _wasMounted = false;
  bool get mounted => _mounted;
  static bool _notifyingMountStatus = false;
  static Set<Widget> _mountedChanged = new HashSet<Widget>();

  void setParent(Widget newParent) {
    assert(!_notifyingMountStatus);
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

  static void _notifyMountStatusChanged() {
    try {
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

  bool get interchangeable => false; // if true, then keys can be duplicated

  void _sync(Widget old, dynamic slot);
  // 'slot' is the identifier that the parent RenderObjectWrapper uses to know
  // where to put this descendant

  void remove() {
    _root = null;
    setParent(null);
  }

  Widget findAncestor(Type targetType) {
    var ancestor = _parent;
    while (ancestor != null && !reflectClass(ancestor.runtimeType).isSubtypeOf(reflectClass(targetType)))
      ancestor = ancestor._parent;
    return ancestor;
  }

  void removeChild(Widget node) {
    node.remove();
  }

  // Returns the child which should be retained as the child of this node.
  Widget syncChild(Widget node, Widget oldNode, dynamic slot) {

    assert(oldNode is! Component || !oldNode._disqualifiedFromEverAppearingAgain);

    if (node == oldNode) {
      assert(node == null || node.mounted);
      return node; // Nothing to do. Subtrees must be identical.
    }

    if (node == null) {
      // the child in this slot has gone away
      assert(oldNode.mounted);
      removeChild(oldNode);
      assert(!oldNode.mounted);
      return null;
    }

    if (oldNode != null &&
        oldNode.runtimeType == node.runtimeType &&
        oldNode.key == node.key &&
        node._retainStatefulNodeIfPossible(oldNode)) {
      assert(oldNode.mounted);
      assert(!node.mounted);
      oldNode._sync(node, slot);
      assert(oldNode.root is RenderObject);
      return oldNode;
    }

    if (oldNode != null &&
        (oldNode.runtimeType != node.runtimeType || oldNode.key != node.key)) {
      assert(oldNode.mounted);
      removeChild(oldNode);
      oldNode = null;
    }

    assert(!node.mounted);
    node.setParent(this);
    node._sync(oldNode, slot);
    assert(node.root is RenderObject);
    return node;
  }
}


// Descendants of TagNode provide a way to tag RenderObjectWrapper and
// Component nodes with annotations, such as event listeners,
// stylistic information, etc.
abstract class TagNode extends Widget {

  TagNode(Widget content, { String key })
    : this.content = content, super(key: key);

  Widget content;

  void _sync(Widget old, dynamic slot) {
    Widget oldContent = old == null ? null : (old as TagNode).content;
    content = syncChild(content, oldContent, slot);
    assert(content.root != null);
    _root = content.root;
    assert(_root == root); // in case a subclass reintroduces it
  }

  void remove() {
    if (content != null)
      removeChild(content);
    super.remove();
  }

}

class ParentDataNode extends TagNode {
  ParentDataNode(Widget content, this.parentData, { String key })
    : super(content, key: key);
  final ParentData parentData;
}

typedef void GestureEventListener(sky.GestureEvent e);
typedef void PointerEventListener(sky.PointerEvent e);
typedef void EventListener(sky.Event e);

class Listener extends TagNode  {

  Listener({
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
       super(child);

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
        super(key: key);

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

  bool _retainStatefulNodeIfPossible(Widget old) {
    assert(!_disqualifiedFromEverAppearingAgain);

    Component oldComponent = old as Component;
    if (oldComponent == null || !oldComponent._stateful)
      return false;

    assert(runtimeType == oldComponent.runtimeType);
    assert(key == oldComponent.key);

    // Make |this|, the newly-created object, into the "old" Component, and kill it
    _stateful = false;
    _built = oldComponent._built;
    assert(_built != null);
    _disqualifiedFromEverAppearingAgain = true;

    // Make |oldComponent| the "new" component
    oldComponent._built = null;
    oldComponent._dirty = true;
    oldComponent.syncFields(this);
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
    setState(() {});
  }

  void setState(Function fn()) {
    assert(!_disqualifiedFromEverAppearingAgain);
    _stateful = true;
    fn();
    if (_isBuilding || _dirty || !_mounted)
      return;

    _dirty = true;
    _scheduleComponentForRender(this);
  }

  Widget build();

}

Set<Component> _dirtyComponents = new Set<Component>();
bool _buildScheduled = false;
bool _inRenderDirtyComponents = false;

void _buildDirtyComponents() {
  //_tracing.begin('fn::_buildDirtyComponents');

  Stopwatch sw;
  if (_shouldLogRenderDuration)
    sw = new Stopwatch()..start();

  try {
    _inRenderDirtyComponents = true;

    List<Component> sortedDirtyComponents = _dirtyComponents.toList();
    sortedDirtyComponents.sort((Component a, Component b) => a._order - b._order);
    for (var comp in sortedDirtyComponents) {
      comp._buildIfDirty();
    }

    _dirtyComponents.clear();
    _buildScheduled = false;
  } finally {
    _inRenderDirtyComponents = false;
  }

  Widget._notifyMountStatusChanged();

  if (_shouldLogRenderDuration) {
    sw.stop();
    print('Render took ${sw.elapsedMicroseconds} microseconds');
  }

  //_tracing.end('fn::_buildDirtyComponents');
}

void _scheduleComponentForRender(Component c) {
  assert(!_inRenderDirtyComponents);
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

  void insert(RenderObjectWrapper child, dynamic slot);

  static final Map<RenderObject, RenderObjectWrapper> _nodeMap =
      new HashMap<RenderObject, RenderObjectWrapper>();

  static RenderObjectWrapper _getMounted(RenderObject node) => _nodeMap[node];

  void _sync(Widget old, dynamic slot) {
    assert(parent != null);
    if (old == null) {
      _root = createNode();
      var ancestor = findAncestor(RenderObjectWrapper);
      if (ancestor is RenderObjectWrapper)
        ancestor.insert(this, slot);
    } else {
      _root = old.root;
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
}

abstract class OneChildRenderObjectWrapper extends RenderObjectWrapper {

  OneChildRenderObjectWrapper({ String key, Widget child })
    : _child = child, super(key: key);

  Widget _child;
  Widget get child => _child;

  void syncRenderObject(RenderObjectWrapper old) {
    super.syncRenderObject(old);
    Widget oldChild = old == null ? null : (old as OneChildRenderObjectWrapper).child;
    _child = syncChild(child, oldChild, null);
  }

  void insert(RenderObjectWrapper child, dynamic slot) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(slot == null);
    assert(root is RenderObjectWithChildMixin);
    root.child = child.root;
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void removeChild(Widget node) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(root is RenderObjectWithChildMixin);
    root.child = null;
    super.removeChild(node);
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

  void insert(RenderObjectWrapper child, dynamic slot) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(slot == null || slot is RenderObject);
    assert(root is ContainerRenderObjectMixin);
    root.add(child.root, before: slot);
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void removeChild(Widget node) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(root is ContainerRenderObjectMixin);
    assert(node.root.parent == root);
    root.remove(node.root);
    super.removeChild(node);
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
      if (child.interchangeable)
        continue; // when these nodes are reordered, we just reassign the data

      if (!idSet.add(child.key)) {
        throw '''If multiple non-interchangeable nodes exist as children of another node, they must have unique keys. Duplicate: "${child.key}"''';
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
        if (!node.interchangeable)
          oldNodeIdMap.putIfAbsent(node.key, () => node);
      }
    }

    bool searchForOldNode() {
      if (currentNode.interchangeable)
        return false; // never re-order these nodes

      ensureOldIdMap();
      oldNode = oldNodeIdMap[currentNode.key];
      if (oldNode == null)
        return false;

      oldNodeIdMap[currentNode.key] = null; // mark it reordered
      assert(root is ContainerRenderObjectMixin);
      assert(old.root is ContainerRenderObjectMixin);
      assert(oldNode.root != null);

      (old.root as ContainerRenderObjectMixin).remove(oldNode.root); // TODO(ianh): Remove cast once the analyzer is cleverer
      root.add(oldNode.root, before: nextSibling);

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
      removeChild(oldNode);
      advanceOldStartIndex();
    }

    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

}

class WidgetAppView extends AppView {

  WidgetAppView({ RenderView renderViewOverride: null })
      : super(renderViewOverride: renderViewOverride) {
    assert(_appView == null);
  }

  static WidgetAppView _appView;
  static AppView get appView => _appView;
  static void initWidgetAppView({ RenderView renderViewOverride: null }) {
    if (_appView == null)
      _appView = new WidgetAppView(renderViewOverride: renderViewOverride);
  }

  void dispatchEvent(sky.Event event, HitTestResult result) {
    assert(_appView == this);
    super.dispatchEvent(event, result);
    for (HitTestEntry entry in result.path.reversed) {
      Widget target = RenderObjectWrapper._getMounted(entry.target);
      if (target == null)
        continue;
      RenderObject targetRoot = target.root;
      while (target != null && target.root == targetRoot) {
        if (target is EventListener)
          target._handleEvent(event);
        target = target._parent;
      }
    }
  }

}

abstract class AbstractWidgetRoot extends Component {

  AbstractWidgetRoot({ RenderView renderViewOverride }) : super(stateful: true) {
    WidgetAppView.initWidgetAppView(renderViewOverride: renderViewOverride);
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

abstract class App extends AbstractWidgetRoot {

  App({ RenderView renderViewOverride }) : super(renderViewOverride: renderViewOverride);

  void _buildIfDirty() {
    super._buildIfDirty();

    if (root.parent == null) {
      // we haven't attached it yet
      WidgetAppView._appView.root = root;
    }
    assert(root.parent is RenderView);
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
