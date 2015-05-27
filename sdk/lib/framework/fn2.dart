// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fn;

import 'dart:async';
import 'dart:collection';
import 'dart:mirrors';
import 'dart:sky' as sky;
import 'reflect.dart' as reflect;
import 'layout2.dart';
import 'app.dart';

// final sky.Tracing _tracing = sky.window.tracing;

final bool _shouldLogRenderDuration = false;
final bool _shouldTrace = false;

enum _SyncOperation { IDENTICAL, INSERTION, STATEFUL, STATELESS, REMOVAL }

/*
 * All Effen nodes derive from UINode. All nodes have a _parent, a _key and
 * can be sync'd.
 */
abstract class UINode {
  String _key;
  UINode _parent;
  UINode get parent => _parent;
  RenderNode root;
  bool _defunct = false;

  UINode({ Object key }) {
    _key = key == null ? "$runtimeType" : "$runtimeType-$key";
    assert(this is App || _inRenderDirtyComponents); // you should not build the UI tree ahead of time, build it only during build()
  }

  // Subclasses which implements Nodes that become stateful may return true
  // if the |old| node has become stateful and should be retained.
  bool _willSync(UINode old) => false;

  bool get interchangeable => false; // if true, then keys can be duplicated

  void _sync(UINode old, dynamic slot);
  // 'slot' is the identifier that the parent RenderNodeWrapper uses to know
  // where to put this descendant

  void _remove() {
    _defunct = true;
    root = null;
    handleRemoved();
  }
  void handleRemoved() { }

  UINode findAncestor(Type targetType) {
    var ancestor = _parent;
    while (ancestor != null && !reflectClass(ancestor.runtimeType).isSubtypeOf(reflectClass(targetType)))
      ancestor = ancestor._parent;
    return ancestor;
  }

  int _nodeDepth;
  void _ensureDepth() {
    if (_nodeDepth == null) {
      if (_parent != null) {
        _parent._ensureDepth();
        _nodeDepth = _parent._nodeDepth + 1;
      } else {
        _nodeDepth = 0;
      }
    }
  }

  void _trace(String message) {
    if (!_shouldTrace)
      return;

    _ensureDepth();
    print((' ' * _nodeDepth) + message);
  }

  void _traceSync(_SyncOperation op, String key) {
    if (!_shouldTrace)
      return;

    String opString = op.toString().toLowerCase();
    String outString = opString.substring(opString.indexOf('.') + 1);
    _trace('_sync($outString) $key');
  }

  void removeChild(UINode node) {
    _traceSync(_SyncOperation.REMOVAL, node._key);
    node._remove();
  }

  // Returns the child which should be retained as the child of this node.
  UINode syncChild(UINode node, UINode oldNode, dynamic slot) {
    if (node == oldNode) {
      _traceSync(_SyncOperation.IDENTICAL, node == null ? '*null*' : node._key);
      return node; // Nothing to do. Subtrees must be identical.
    }

    if (node == null) {
      // the child in this slot has gone away
      removeChild(oldNode);
      return null;
    }
    assert(oldNode == null || node._key == oldNode._key);

    // TODO(rafaelw): This eagerly removes the old DOM. It may be that a
    // new component was built that could re-use some of it. Consider
    // syncing the new VDOM against the old one.
    if (oldNode != null && node._key != oldNode._key) {
      removeChild(oldNode);
    }

    if (node._willSync(oldNode)) {
      _traceSync(_SyncOperation.STATEFUL, node._key);
      oldNode._sync(node, slot);
      node._defunct = true;
      assert(oldNode.root is RenderNode);
      return oldNode;
    }

    assert(!node._defunct);
    node._parent = this;

    if (oldNode == null) {
      _traceSync(_SyncOperation.INSERTION, node._key);
    } else {
      _traceSync(_SyncOperation.STATELESS, node._key);
    }
    node._sync(oldNode, slot);
    if (oldNode != null)
      oldNode._defunct = true;

    assert(node.root is RenderNode);
    return node;
  }
}

abstract class ContentNode extends UINode {
  UINode content;

  ContentNode(UINode content) : this.content = content, super(key: content._key);

  void _sync(UINode old, dynamic slot) {
    UINode oldContent = old == null ? null : (old as ContentNode).content;
    content = syncChild(content, oldContent, slot);
    assert(content.root != null);
    root = content.root;
  }

  void _remove() {
    if (content != null)
      removeChild(content);
    super._remove();
  }
}

class ParentDataNode extends ContentNode {
  final ParentData parentData;

  ParentDataNode(UINode content, this.parentData): super(content);
}

typedef GestureEventListener(sky.GestureEvent e);
typedef PointerEventListener(sky.PointerEvent e);
typedef EventListener(sky.Event e);

class EventListenerNode extends ContentNode  {
  final Map<String, sky.EventListener> listeners;

  static final Set<String> _registeredEvents = new HashSet<String>();

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

  void _handleEvent(sky.Event e) {
    sky.EventListener listener = listeners[e.type];
    if (listener != null) {
      listener(e);
    }
  }

  static void _dispatchEvent(sky.Event e) {
    UINode target = RenderNodeWrapper._getMounted(bridgeEventTargetToRenderNode(e.target));

    // TODO(rafaelw): StopPropagation?
    while (target != null) {
      if (target is EventListenerNode) {
        target._handleEvent(e);
      }

      target = target._parent;
    }
  }

  static void _ensureDocumentListener(String eventType) {
    if (_registeredEvents.add(eventType)) {
      sky.document.addEventListener(eventType, _dispatchEvent);
    }
  }

  void _sync(UINode old, dynamic slot) {
    for (var type in listeners.keys) {
      _ensureDocumentListener(type);
    }
    super._sync(old, slot);
  }
}

/*
 * RenderNodeWrappers correspond to a desired state of a RenderNode.
 * They are fully immutable, with one exception: A UINode which is a
 * Component which lives within an OneChildListRenderNodeWrapper's
 * children list, may be replaced with the "old" instance if it has
 * become stateful.
 */
abstract class RenderNodeWrapper extends UINode {

  static final Map<RenderNode, RenderNodeWrapper> _nodeMap =
      new HashMap<RenderNode, RenderNodeWrapper>();

  static RenderNodeWrapper _getMounted(RenderNode node) => _nodeMap[node];

  RenderNodeWrapper({
    Object key
  }) : super(key: key);

  RenderNode createNode();
  RenderNodeWrapper get emptyNode;

  void insert(RenderNodeWrapper child, dynamic slot);

  void _sync(UINode old, dynamic slot) {
    if (old == null) {
      root = createNode();
      assert(root != null);
      var ancestor = findAncestor(RenderNodeWrapper);
      if (ancestor is RenderNodeWrapper)
        ancestor.insert(this, slot);
      old = emptyNode;
    } else {
      root = old.root;
      assert(root != null);
    }

    _nodeMap[root] = this;
    syncRenderNode(old);
  }

  void syncRenderNode(RenderNodeWrapper old) {
    ParentData parentData = null;
    UINode parent = _parent;
    while (parent != null && parent is! RenderNodeWrapper) {
      if (parent is ParentDataNode && parent.parentData != null) {
        if (parentData != null)
          parentData.merge(parent.parentData); // this will throw if the types aren't the same
        else
          parentData = parent.parentData;
      }
      parent = parent._parent;
    }
    if (parentData != null) {
      assert(root.parentData != null);
      root.parentData.merge(parentData); // this will throw if the types aren't approriate
      assert(parent != null);
      assert(parent.root != null);
      parent.root.markNeedsLayout();
    }
  }

  void removeChild(UINode node) {
    root.remove(node.root);
    super.removeChild(node);
  }

  void _remove() {
    assert(root != null);
    _nodeMap.remove(root);
    super._remove();
  }
}

final List<UINode> _emptyList = new List<UINode>();

abstract class OneChildListRenderNodeWrapper extends RenderNodeWrapper {

  // In OneChildListRenderNodeWrapper subclasses, slots are RenderNode nodes
  // to use as the "insert before" sibling in ContainerRenderNodeMixin.add() calls

  final List<UINode> children;

  OneChildListRenderNodeWrapper({
    Object key,
    List<UINode> children
  }) : this.children = children == null ? _emptyList : children,
  super(
    key: key
  ) {
    assert(!_debugHasDuplicateIds());
  }

  void insert(RenderNodeWrapper child, dynamic slot) {
    assert(slot == null || slot is RenderNode);
    root.add(child.root, before: slot);
  }

  void _remove() {
    assert(children != null);
    for (var child in children) {
      assert(child != null);
      removeChild(child);
    }
    super._remove();
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

  void syncRenderNode(OneChildListRenderNodeWrapper old) {
    super.syncRenderNode(old);

    if (root is! ContainerRenderNodeMixin)
      return;

    var startIndex = 0;
    var endIndex = children.length;

    var oldChildren = old.children;
    var oldStartIndex = 0;
    var oldEndIndex = oldChildren.length;

    RenderNode nextSibling = null;
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
      assert(root is ContainerRenderNodeMixin);
      assert(oldNode.root is ContainerRenderNodeMixin);

      old.root.remove(oldNode.root);
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
  }
}

class Container extends OneChildListRenderNodeWrapper {

  RenderCSSContainer root;
  RenderCSSContainer createNode() => new RenderCSSContainer(this);

  static final Container _emptyContainer = new Container();

  RenderNodeWrapper get emptyNode => _emptyContainer;

  Container({
    Object key,
    List<UINode> children
  }) : super(
    key: key,
    children: children
  );
}

class Paragraph extends OneChildListRenderNodeWrapper {

  RenderCSSParagraph root;
  RenderCSSParagraph createNode() => new RenderCSSParagraph(this);

  static final Paragraph _emptyContainer = new Paragraph();

  RenderNodeWrapper get emptyNode => _emptyContainer;

  Paragraph({
    Object key,
    List<UINode> children
  }) : super(
    key: key,
    children: children
  );
}

class FlexContainer extends OneChildListRenderNodeWrapper {

  RenderFlex root;
  RenderFlex createNode() => new RenderFlex(this, this.direction);

  static final FlexContainer _emptyContainer = new FlexContainer();
    // direction doesn't matter if it's empty

  RenderNodeWrapper get emptyNode => _emptyContainer;

  final FlexDirection direction;

  FlexContainer({
    Object key,
    List<UINode> children,
    this.direction: FlexDirection.Horizontal
  }) : super(
    key: key,
    children: children
  );

  void syncRenderNode(UINode old) {
    super.syncRenderNode(old);
    root.direction = direction;
  }
}

class FlexExpandingChild extends ParentDataNode {
  FlexExpandingChild(UINode content, [int flex = 1]): super(content, new FlexBoxParentData()..flex = flex);
}

class FillStackContainer extends OneChildListRenderNodeWrapper {

  RenderCSSStack root;
  RenderCSSStack createNode() => new RenderCSSStack(this);

  static final FillStackContainer _emptyContainer = new FillStackContainer();

  RenderNodeWrapper get emptyNode => _emptyContainer;

  FillStackContainer({
    Object key,
    List<UINode> children
  }) : super(
    key: key,
    children: _positionNodesToFill(children)
  );

  static StackParentData _fillParentData = new StackParentData()
                                                 ..top = 0.0
                                                 ..left = 0.0
                                                 ..right = 0.0
                                                 ..bottom = 0.0;

  static List<UINode> _positionNodesToFill(List<UINode> input) {
    if (input == null)
      return null;
    return input.map((node) {
      return new ParentDataNode(node, _fillParentData);
    }).toList();
  }
}

abstract class OneChildRenderNodeWrapper extends RenderNodeWrapper {

  final UINode child;
  RenderNodeWithChildMixin root;

  OneChildRenderNodeWrapper({
    Object key,
    this.child
  }) : super(key: key);

  void insert(RenderNodeWrapper child, dynamic slot) {
    assert(slot == null);
    root.child = child.root;
  }

  void _remove() {
    assert(child != null);
    removeChild(child);
    super._remove();
  }
}

class TextFragment extends RenderNodeWrapper {

  RenderCSSInline root;
  RenderCSSInline createNode() => new RenderCSSInline(this, this.data);

  static final TextFragment _emptyText = new TextFragment('');

  RenderNodeWrapper get emptyNode => _emptyText;

  final String data;

  TextFragment(this.data, {
    Object key
  }) : super(
    key: key
  );

  void syncRenderNode(UINode old) {
    super.syncRenderNode(old);
    root.data = data;
  }
}

class Image extends RenderNodeWrapper {

  RenderCSSImage root;
  RenderCSSImage createNode() => new RenderCSSImage(this, this.src, this.width, this.height);

  static final Image _emptyImage = new Image();

  RenderNodeWrapper get emptyNode => _emptyImage;

  final String src;
  final int width;
  final int height;

  Image({
    Object key,
    this.width,
    this.height,
    this.src
  }) : super(
    key: key
  );

  void syncRenderNode(UINode old) {
    super.syncRenderNode(old);
    root.configure(this.src, this.width, this.height);
  }
}


Set<Component> _mountedComponents = new HashSet<Component>();
Set<Component> _unmountedComponents = new HashSet<Component>();

void _enqueueDidMount(Component c) {
  assert(!_notifingMountStatus);
  _mountedComponents.add(c);
}

void _enqueueDidUnmount(Component c) {
  assert(!_notifingMountStatus);
  _unmountedComponents.add(c);
}

bool _notifingMountStatus = false;

void _notifyMountStatusChanged() {
  try {
    _notifingMountStatus = true;
    _unmountedComponents.forEach((c) => c._didUnmount());
    _mountedComponents.forEach((c) => c._didMount());
    _mountedComponents.clear();
    _unmountedComponents.clear();
  } finally {
    _notifingMountStatus = false;
  }
}

List<Component> _dirtyComponents = new List<Component>();
bool _buildScheduled = false;
bool _inRenderDirtyComponents = false;

void _buildDirtyComponents() {
  //_tracing.begin('fn::_buildDirtyComponents');

  Stopwatch sw;
  if (_shouldLogRenderDuration)
    sw = new Stopwatch()..start();

  try {
    _inRenderDirtyComponents = true;

    _dirtyComponents.sort((a, b) => a._order - b._order);
    for (var comp in _dirtyComponents) {
      comp._buildIfDirty();
    }

    _dirtyComponents.clear();
    _buildScheduled = false;
  } finally {
    _inRenderDirtyComponents = false;
  }

  _notifyMountStatusChanged();

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
  bool get _isBuilding => _currentlyBuilding == this;
  bool _dirty = true;

  UINode _built;
  final int _order;
  static int _currentOrder = 0;
  bool _stateful;
  static Component _currentlyBuilding;
  List<Function> _mountCallbacks;
  List<Function> _unmountCallbacks;
  dynamic _slot; // cached slot from the last time we were synced

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


  Component({ Object key, bool stateful })
      : _stateful = stateful != null ? stateful : false,
        _order = _currentOrder + 1,
        super(key: key);

  Component.fromArgs(Object key, bool stateful)
      : this(key: key, stateful: stateful);

  void _didMount() {
    if (_mountCallbacks != null)
      _mountCallbacks.forEach((fn) => fn());
  }

  void _didUnmount() {
    if (_unmountCallbacks != null)
      _unmountCallbacks.forEach((fn) => fn());
  }

  // TODO(rafaelw): It seems wrong to expose DOM at all. This is presently
  // needed to get sizing info.
  RenderNode getRoot() => root;

  void _remove() {
    assert(_built != null);
    assert(root != null);
    removeChild(_built);
    _built = null;
    _enqueueDidUnmount(this);
    super._remove();
  }

  bool _willSync(UINode old) {
    Component oldComponent = old as Component;
    if (oldComponent == null || !oldComponent._stateful)
      return false;

    // Make |this| the "old" Component
    _stateful = false;
    _built = oldComponent._built;
    assert(_built != null);

    // Make |oldComponent| the "new" component
    reflect.copyPublicFields(this, oldComponent);
    oldComponent._built = null;
    oldComponent._dirty = true;
    return true;
  }

  /* There are three cases here:
   * 1) Building for the first time:
   *      assert(_built == null && old == null)
   * 2) Re-building (because a dirty flag got set):
   *      assert(_built != null && old == null)
   * 3) Syncing against an old version
   *      assert(_built == null && old != null)
   */
  void _sync(UINode old, dynamic slot) {
    assert(!_defunct);
    assert(_built == null || old == null);

    Component oldComponent = old as Component;

    _slot = slot;

    var oldBuilt;
    if (oldComponent == null) {
      oldBuilt = _built;
    } else {
      assert(_built == null);
      oldBuilt = oldComponent._built;
    }

    if (oldBuilt == null)
      _enqueueDidMount(this);

    int lastOrder = _currentOrder;
    _currentOrder = _order;
    _currentlyBuilding = this;
    _built = build();
    _currentlyBuilding = null;
    _currentOrder = lastOrder;

    _built = syncChild(_built, oldBuilt, slot);
    _dirty = false;
    root = _built.root;
    assert(root != null);
  }

  void _buildIfDirty() {
    if (!_dirty || _defunct)
      return;

    _trace('$_key rebuilding...');
    assert(root != null);
    _sync(null, _slot);
  }

  void scheduleBuild() {
    setState(() {});
  }

  void setState(Function fn()) {
    _stateful = true;
    fn();
    if (_isBuilding || _dirty || _defunct)
      return;

    _dirty = true;
    _scheduleComponentForRender(this);
  }

  UINode build();
}

abstract class App extends Component {

  App() : super(stateful: true) {
    _appView = new AppView(null);
    _scheduleComponentForRender(this);
  }

  AppView _appView;

  void _buildIfDirty() {
    assert(_dirty);
    assert(!_defunct);
    _trace('$_key rebuilding app...');
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
  UINode build() => new Paragraph(children: [new TextFragment(data)]);
}


// for now, but only for now:

class RenderSolidColor extends RenderDecoratedBox {
  final double desiredHeight;
  final double desiredWidth;
  final int backgroundColor;

  RenderSolidColor(int backgroundColor, { this.desiredHeight: double.INFINITY,
                                          this.desiredWidth: double.INFINITY })
      : backgroundColor = backgroundColor,
        super(new BoxDecoration(backgroundColor: backgroundColor));

  BoxDimensions getIntrinsicDimensions(BoxConstraints constraints) {
    return new BoxDimensions.withConstraints(constraints,
                                             height: desiredHeight,
                                             width: desiredWidth);
  }

  void layout(BoxConstraints constraints, { RenderNode relayoutSubtreeRoot }) {
    width = constraints.constrainWidth(desiredWidth);
    height = constraints.constrainHeight(desiredHeight);
    layoutDone();
  }

  void handlePointer(sky.PointerEvent event) {
    if (event.type == 'pointerdown')
      decoration = new BoxDecoration(backgroundColor: 0xFFFF0000);
    else if (event.type == 'pointerup')
      decoration = new BoxDecoration(backgroundColor: backgroundColor);
  }
}

class Rectangle extends RenderNodeWrapper {

  Rectangle(this.color, {
    Object key
  }) : super(
    key: key
  );

  final int color;

  RenderSolidColor root;
  RenderSolidColor createNode() => new RenderSolidColor(color, desiredWidth: 40.0, desiredHeight: 130.0);

  static final Rectangle _emptyRectangle = new Rectangle(0);
  RenderNodeWrapper get emptyNode => _emptyRectangle;

}
