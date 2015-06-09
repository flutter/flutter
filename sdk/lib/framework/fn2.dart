// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fn;

import 'app.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:mirrors';
import 'dart:sky' as sky;
import 'package:vector_math/vector_math.dart';
import 'reflect.dart' as reflect;
import 'rendering/block.dart';
import 'rendering/box.dart';
import 'rendering/flex.dart';
import 'rendering/object.dart';
import 'rendering/paragraph.dart';
import 'rendering/stack.dart';
export 'rendering/object.dart' show Point, Size, Rect, Color, Paint, Path;
export 'rendering/box.dart' show BoxConstraints, BoxDecoration, Border, BorderSide, EdgeDims;
export 'rendering/flex.dart' show FlexDirection;

// final sky.Tracing _tracing = sky.window.tracing;

final bool _shouldLogRenderDuration = false;

/*
 * All Effen nodes derive from UINode. All nodes have a _parent, a _key and
 * can be sync'd.
 */
abstract class UINode {

  UINode({ Object key }) {
    _key = key == null ? "$runtimeType" : "$runtimeType-$key";
    assert(this is App || _inRenderDirtyComponents); // you should not build the UI tree ahead of time, build it only during build()
  }

  String _key;
  String get key => _key;

  UINode _parent;
  UINode get parent => _parent;

  bool _mounted = false;
  bool _wasMounted = false;
  bool get mounted => _mounted;
  static bool _notifyingMountStatus = false;
  static Set<UINode> _mountedChanged = new HashSet<UINode>();

  void setParent(UINode newParent) {
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
      for (UINode node in _mountedChanged) {
        if (node._wasMounted != node._mounted) {
          if (node._mounted)
            node._didMount();
          else
            node._didUnmount();
          node._wasMounted = node._mounted;
        }
      }
      _mountedChanged.clear();
    } finally {
      _notifyingMountStatus = false;
    }
  }
  void _didMount() { }
  void _didUnmount() { }

  RenderObject root;

  // Subclasses which implements Nodes that become stateful may return true
  // if the |old| node has become stateful and should be retained.
  bool _willSync(UINode old) => false;

  bool get interchangeable => false; // if true, then keys can be duplicated

  void _sync(UINode old, dynamic slot);
  // 'slot' is the identifier that the parent RenderObjectWrapper uses to know
  // where to put this descendant

  void remove() {
    root = null;
    setParent(null);
  }

  UINode findAncestor(Type targetType) {
    var ancestor = _parent;
    while (ancestor != null && !reflectClass(ancestor.runtimeType).isSubtypeOf(reflectClass(targetType)))
      ancestor = ancestor._parent;
    return ancestor;
  }

  void removeChild(UINode node) {
    node.remove();
  }

  // Returns the child which should be retained as the child of this node.
  UINode syncChild(UINode node, UINode oldNode, dynamic slot) {

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

    if (oldNode != null && node._key == oldNode._key && node._willSync(oldNode)) {
      assert(oldNode.mounted);
      assert(!node.mounted);
      oldNode._sync(node, slot);
      assert(oldNode.root is RenderObject);
      return oldNode;
    }

    if (oldNode != null && node._key != oldNode._key) {
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
abstract class TagNode extends UINode {

  TagNode(UINode content, { Object key }) : this.content = content, super(key: key);

  UINode content;

  void _sync(UINode old, dynamic slot) {
    UINode oldContent = old == null ? null : (old as TagNode).content;
    content = syncChild(content, oldContent, slot);
    assert(content.root != null);
    root = content.root;
  }

  void remove() {
    if (content != null)
      removeChild(content);
    super.remove();
  }

}

class ParentDataNode extends TagNode {
  ParentDataNode(UINode content, this.parentData, { Object key }): super(content, key: key);
  final ParentData parentData;
}

typedef void GestureEventListener(sky.GestureEvent e);
typedef void PointerEventListener(sky.PointerEvent e);
typedef void EventListener(sky.Event e);

class EventListenerNode extends TagNode  {

  EventListenerNode(UINode content, {
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
       super(content);

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

/*
 * RenderObjectWrappers correspond to a desired state of a RenderObject.
 * They are fully immutable, with one exception: A UINode which is a
 * Component which lives within an MultiChildRenderObjectWrapper's
 * children list, may be replaced with the "old" instance if it has
 * become stateful.
 */
abstract class RenderObjectWrapper extends UINode {

  RenderObjectWrapper({
    Object key
  }) : super(key: key);

  RenderObject createNode();

  void insert(RenderObjectWrapper child, dynamic slot);

  static final Map<RenderObject, RenderObjectWrapper> _nodeMap =
      new HashMap<RenderObject, RenderObjectWrapper>();

  static RenderObjectWrapper _getMounted(RenderObject node) => _nodeMap[node];

  void _sync(UINode old, dynamic slot) {
    assert(parent != null);
    if (old == null) {
      root = createNode();
      assert(root != null);
      var ancestor = findAncestor(RenderObjectWrapper);
      if (ancestor is RenderObjectWrapper)
        ancestor.insert(this, slot);
    } else {
      root = old.root;
    }
    assert(mounted);
    assert(root != null);
    _nodeMap[root] = this;
    syncRenderObject(old);
  }

  void syncRenderObject(RenderObjectWrapper old) {
    ParentData parentData = null;
    UINode ancestor = parent;
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

  OneChildRenderObjectWrapper({ UINode child, Object key }) : _child = child, super(key: key);

  UINode _child;
  UINode get child => _child;

  void syncRenderObject(RenderObjectWrapper old) {
    super.syncRenderObject(old);
    UINode oldChild = old == null ? null : (old as OneChildRenderObjectWrapper).child;
    _child = syncChild(child, oldChild, null);
  }

  void insert(RenderObjectWrapper child, dynamic slot) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(slot == null);
    assert(root is RenderObjectWithChildMixin);
    root.child = child.root;
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void removeChild(UINode node) {
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

class Clip extends OneChildRenderObjectWrapper {

  Clip({ UINode child, Object key })
    : super(child: child, key: key);

  RenderClip root;
  RenderClip createNode() => new RenderClip();

}

class Padding extends OneChildRenderObjectWrapper {

  Padding({ this.padding, UINode child, Object key })
    : super(child: child, key: key);

  RenderPadding root;
  final EdgeDims padding;

  RenderPadding createNode() => new RenderPadding(padding: padding);

  void syncRenderObject(Padding old) {
    super.syncRenderObject(old);
    root.padding = padding;
  }

}

class DecoratedBox extends OneChildRenderObjectWrapper {

  DecoratedBox({ this.decoration, UINode child, Object key })
    : super(child: child, key: key);

  RenderDecoratedBox root;
  final BoxDecoration decoration;

  RenderDecoratedBox createNode() => new RenderDecoratedBox(decoration: decoration);

  void syncRenderObject(DecoratedBox old) {
    super.syncRenderObject(old);
    root.decoration = decoration;
  }

}

class SizedBox extends OneChildRenderObjectWrapper {

  SizedBox({
    double width: double.INFINITY,
    double height: double.INFINITY,
    UINode child,
    Object key
  }) : desiredSize = new Size(width, height), super(child: child, key: key);

  RenderSizedBox root;
  final Size desiredSize;

  RenderSizedBox createNode() => new RenderSizedBox(desiredSize: desiredSize);

  void syncRenderObject(SizedBox old) {
    super.syncRenderObject(old);
    root.desiredSize = desiredSize;
  }

}

class ConstrainedBox extends OneChildRenderObjectWrapper {

  ConstrainedBox({ this.constraints, UINode child, Object key })
    : super(child: child, key: key);

  RenderConstrainedBox root;
  final BoxConstraints constraints;

  RenderConstrainedBox createNode() => new RenderConstrainedBox(additionalConstraints: constraints);

  void syncRenderObject(ConstrainedBox old) {
    super.syncRenderObject(old);
    root.additionalConstraints = constraints;
  }

}

class ShrinkWrapWidth extends OneChildRenderObjectWrapper {

  ShrinkWrapWidth({ UINode child, Object key }) : super(child: child, key: key);

  RenderShrinkWrapWidth root;

  RenderShrinkWrapWidth createNode() => new RenderShrinkWrapWidth();

}

class Transform extends OneChildRenderObjectWrapper {

  Transform({ this.transform, UINode child, Object key })
    : super(child: child, key: key);

  RenderTransform root;
  final Matrix4 transform;

  RenderTransform createNode() => new RenderTransform(transform: transform);

  void syncRenderObject(Transform old) {
    super.syncRenderObject(old);
    root.transform = transform;
  }

}

class SizeObserver extends OneChildRenderObjectWrapper {

  SizeObserver({ this.callback, UINode child, Object key })
    : super(child: child, key: key);

  RenderSizeObserver root;
  final SizeChangedCallback callback;

  RenderSizeObserver createNode() => new RenderSizeObserver(callback: callback);

  void syncRenderObject(SizeObserver old) {
    super.syncRenderObject(old);
    root.callback = callback;
  }

  void remove() {
    root.callback = null;
    super.remove();
  }

}

// TODO(jackson) need a mechanism for marking the RenderCustomPaint as needing paint
class CustomPaint extends OneChildRenderObjectWrapper {

  CustomPaint({ this.callback, UINode child, Object key })
    : super(child: child, key: key);

  RenderCustomPaint root;
  final CustomPaintCallback callback;

  RenderCustomPaint createNode() => new RenderCustomPaint(callback: callback);

  void syncRenderObject(CustomPaint old) {
    super.syncRenderObject(old);
    root.callback = callback;
  }

  void remove() {
    root.callback = null;
    super.remove();
  }

}

final List<UINode> _emptyList = new List<UINode>();

abstract class MultiChildRenderObjectWrapper extends RenderObjectWrapper {

  // In MultiChildRenderObjectWrapper subclasses, slots are RenderObject nodes
  // to use as the "insert before" sibling in ContainerRenderObjectMixin.add() calls

  MultiChildRenderObjectWrapper({
    Object key,
    List<UINode> children
  }) : this.children = children == null ? _emptyList : children,
  super(
    key: key
  ) {
    assert(!_debugHasDuplicateIds());
  }

  final List<UINode> children;

  void insert(RenderObjectWrapper child, dynamic slot) {
    final root = this.root; // TODO(ianh): Remove this once the analyzer is cleverer
    assert(slot == null || slot is RenderObject);
    assert(root is ContainerRenderObjectMixin);
    root.add(child.root, before: slot);
    assert(root == this.root); // TODO(ianh): Remove this once the analyzer is cleverer
  }

  void removeChild(UINode node) {
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

      if (!idSet.add(child._key)) {
        throw '''If multiple non-interchangeable nodes of the same type exist as children
                of another node, they must have unique keys.
                Duplicate: "${child._key}"''';
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
    UINode currentNode = null;
    UINode oldNode = null;

    void sync(int atIndex) {
      children[atIndex] = syncChild(currentNode, oldNode, nextSibling);
      assert(children[atIndex] != null);
    }

    // Scan backwards from end of list while nodes can be directly synced
    // without reordering.
    while (endIndex > startIndex && oldEndIndex > oldStartIndex) {
      currentNode = children[endIndex - 1];
      oldNode = oldChildren[oldEndIndex - 1];

      if (currentNode._key != oldNode._key) {
        break;
      }

      endIndex--;
      oldEndIndex--;
      sync(endIndex);
    }

    HashMap<String, UINode> oldNodeIdMap = null;

    bool oldNodeReordered(String key) {
      return oldNodeIdMap != null &&
             oldNodeIdMap.containsKey(key) &&
             oldNodeIdMap[key] == null;
    }

    void advanceOldStartIndex() {
      oldStartIndex++;
      while (oldStartIndex < oldEndIndex &&
             oldNodeReordered(oldChildren[oldStartIndex]._key)) {
        oldStartIndex++;
      }
    }

    void ensureOldIdMap() {
      if (oldNodeIdMap != null)
        return;

      oldNodeIdMap = new HashMap<String, UINode>();
      for (int i = oldStartIndex; i < oldEndIndex; i++) {
        var node = oldChildren[i];
        if (!node.interchangeable)
          oldNodeIdMap.putIfAbsent(node._key, () => node);
      }
    }

    bool searchForOldNode() {
      if (currentNode.interchangeable)
        return false; // never re-order these nodes

      ensureOldIdMap();
      oldNode = oldNodeIdMap[currentNode._key];
      if (oldNode == null)
        return false;

      oldNodeIdMap[currentNode._key] = null; // mark it reordered
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

      if (currentNode._key == oldNode._key) {
        assert(currentNode.runtimeType == oldNode.runtimeType);
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

class BlockContainer extends MultiChildRenderObjectWrapper {

  BlockContainer({ Object key, List<UINode> children })
    : super(key: key, children: children);

  RenderBlock root;
  RenderBlock createNode() => new RenderBlock();

}

class StackContainer extends MultiChildRenderObjectWrapper {

  StackContainer({ Object key, List<UINode> children })
    : super(key: key, children: children);

  RenderStack root;
  RenderStack createNode() => new RenderStack();

}

class StackPositionedChild extends ParentDataNode {
  StackPositionedChild(UINode content, {
    double top, double right, double bottom, double left
  }) : super(content, new StackParentData()..top = top
                                           ..right = right
                                           ..bottom = bottom
                                           ..left = left);
}

class Paragraph extends RenderObjectWrapper {

  Paragraph({ Object key, this.text }) : super(key: key);

  RenderParagraph root;
  RenderParagraph createNode() => new RenderParagraph(text: text);

  final String text;

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    root.text = text;
  }

  void insert(RenderObjectWrapper child, dynamic slot) {
    assert(false);
    // Paragraph does not support having children currently
  }

}

class FlexContainer extends MultiChildRenderObjectWrapper {

  FlexContainer({
    Object key,
    List<UINode> children,
    this.direction: FlexDirection.horizontal,
    this.justifyContent: FlexJustifyContent.flexStart
  }) : super(key: key, children: children);

  RenderFlex root;
  RenderFlex createNode() => new RenderFlex(direction: this.direction);

  final FlexDirection direction;
  final FlexJustifyContent justifyContent;

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    root.direction = direction;
    root.justifyContent = justifyContent;
  }

}

class FlexExpandingChild extends ParentDataNode {
  FlexExpandingChild(UINode content, { int flex: 1, Object key })
    : super(content, new FlexBoxParentData()..flex = flex, key: key);
}

class Image extends RenderObjectWrapper {

  Image({
    Object key,
    this.src,
    this.size
  }) : super(key: key);

  RenderImage root;
  RenderImage createNode() => new RenderImage(this.src, this.size);

  final String src;
  final Size size;

  void syncRenderObject(UINode old) {
    super.syncRenderObject(old);
    root.src = src;
    root.requestedSize = size;
  }

  void insert(RenderObjectWrapper child, dynamic slot) {
    assert(false);
    // Image does not support having children currently
  }

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

  UINode._notifyMountStatusChanged();

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

abstract class Component extends UINode {

  Component({ Object key, bool stateful })
      : _stateful = stateful != null ? stateful : false,
        _order = _currentOrder + 1,
        super(key: key);

  Component.fromArgs(Object key, bool stateful)
      : this(key: key, stateful: stateful);

  static Component _currentlyBuilding;
  bool get _isBuilding => _currentlyBuilding == this;

  bool _stateful;
  bool _dirty = true;
  bool _disqualifiedFromEverAppearingAgain = false;

  List<Function> _mountCallbacks;
  List<Function> _unmountCallbacks;

  void onDidMount(Function fn) {
    if (_mountCallbacks == null)
      _mountCallbacks = new List<Function>();

    _mountCallbacks.add(fn);
  }

  void onDidUnmount(Function fn) {
    if (_unmountCallbacks == null)
      _unmountCallbacks = new List<Function>();

    _unmountCallbacks.add(fn);
  }

  void _didMount() {
    assert(!_disqualifiedFromEverAppearingAgain);
    super._didMount();
    if (_mountCallbacks != null)
      for (Function fn in _mountCallbacks)
        fn();
  }

  void _didUnmount() {
    super._didUnmount();
    if (_unmountCallbacks != null)
      for (Function fn in _unmountCallbacks)
        fn();
  }

  void remove() {
    assert(_built != null);
    assert(root != null);
    removeChild(_built);
    _built = null;
    super.remove();
  }

  bool _willSync(UINode old) {
    assert(!_disqualifiedFromEverAppearingAgain);

    Component oldComponent = old as Component;
    if (oldComponent == null || !oldComponent._stateful)
      return false;

    // Make |this| the "old" Component
    _stateful = false;
    _built = oldComponent._built;
    assert(_built != null);
    _disqualifiedFromEverAppearingAgain = true;

    // Make |oldComponent| the "new" component
    reflect.copyPublicFields(this, oldComponent);
    oldComponent._built = null;
    oldComponent._dirty = true;
    return true;
  }

  final int _order;
  static int _currentOrder = 0;

  /* There are three cases here:
   * 1) Building for the first time:
   *      assert(_built == null && old == null)
   * 2) Re-building (because a dirty flag got set):
   *      assert(_built != null && old == null)
   * 3) Syncing against an old version
   *      assert(_built == null && old != null)
   */
  void _sync(UINode old, dynamic slot) {
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
    root = _built.root;
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

  UINode build();

}

class Container extends Component {

  Container({
    Object key,
    this.child,
    this.constraints,
    this.decoration,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.transform
  }) : super(key: key);

  final UINode child;
  final BoxConstraints constraints;
  final BoxDecoration decoration;
  final EdgeDims margin;
  final EdgeDims padding;
  final Matrix4 transform;
  final double width;
  final double height;

  UINode build() {
    UINode current = child;

    if (child == null && width == null && height == null)
      current = new SizedBox();

    if (padding != null)
      current = new Padding(padding: padding, child: current);

    if (decoration != null)
      current = new DecoratedBox(decoration: decoration, child: current);

    if (width != null || height != null)
      current = new SizedBox(
        width: width == null ? double.INFINITY : width,
        height: height == null ? double.INFINITY : height,
        child: current
      );

    if (constraints != null)
      current = new ConstrainedBox(constraints: constraints, child: current);

    if (margin != null)
      current = new Padding(padding: margin, child: current);

    if (transform != null)
      current = new Transform(transform: transform, child: current);

    return current;
  }

}

class _AppView extends AppView {
  _AppView() : super(null);

  void dispatchEvent(sky.Event event, HitTestResult result) {
    super.dispatchEvent(event, result);

    UINode target = RenderObjectWrapper._getMounted(result.path.first);

    // TODO(rafaelw): StopPropagation?
    while (target != null) {
      if (target is EventListenerNode)
        target._handleEvent(event);
      target = target._parent;
    }
  }
}

abstract class App extends Component {

  App() : super(stateful: true) {
    _appView = new _AppView();
    _scheduleComponentForRender(this);
    _mounted = true;
  }

  AppView _appView;
  AppView get appView => _appView;

  void _buildIfDirty() {
    assert(_dirty);
    assert(_mounted);
    _sync(null, null);
    if (root.parent == null)
      _appView.root = root;
    assert(root.parent is RenderView);
  }

}

class Text extends Component {
  Text(this.data) : super(key: '*text*');
  final String data;
  bool get interchangeable => true;
  UINode build() => new Paragraph(text: data);
}
