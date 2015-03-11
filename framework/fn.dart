// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fn;

import 'dart:async';
import 'dart:collection';
import 'dart:sky' as sky;
import 'reflect.dart' as reflect;

bool _initIsInCheckedMode() {
  String testFn(i) { double d = i; return d.toString(); }
  try {
    testFn('not a double');
  } catch (ex) {
    return true;
  }
  return false;
}

final bool _isInCheckedMode = _initIsInCheckedMode();
final bool _shouldLogRenderDuration = false;

class EventHandler {
  final String type;
  final sky.EventListener listener;

  EventHandler(this.type, this.listener);
}

class EventMap {
  final List<EventHandler> _handlers = new List<EventHandler>();

  void listen(String type, sky.EventListener listener) {
    assert(listener != null);
    _handlers.add(new EventHandler(type, listener));
  }

  void addAll(EventMap events) {
    _handlers.addAll(events._handlers);
  }
}

class Style {
  final String _className;
  static final Map<String, Style> _cache = new HashMap<String, Style>();

  static int nextStyleId = 1;

  static String nextClassName(String styles) {
    assert(sky.document != null);
    String className = "style$nextStyleId";
    nextStyleId++;

    sky.Element styleNode = sky.document.createElement('style');
    styleNode.setChild(new sky.Text(".$className { $styles }"));
    sky.document.appendChild(styleNode);

    return className;
  }

  factory Style(String styles) {
    return _cache.putIfAbsent(styles, () {
      return new Style._internal(nextClassName(styles));
    });
  }

  Style._internal(this._className);
}

void _parentInsertBefore(sky.ParentNode parent,
                         sky.Node node,
                         sky.Node ref) {
  if (ref != null) {
    ref.insertBefore([node]);
  } else {
    parent.appendChild(node);
  }
}

abstract class Node {
  String _key = null;
  sky.Node _root = null;

  // TODO(abarth): Both Elements and Components have |events| but |Text|
  // doesn't. Should we add a common base class to contain |events|?
  final EventMap events = new EventMap();

  Node({ Object key }) {
    _key = key == null ? "$runtimeType" : "$runtimeType-$key";
  }

  // Return true IFF the old node has *become* the new node (should be
  // retained because it is stateful)
  bool _sync(Node old, sky.ParentNode host, sky.Node insertBefore);

  void _remove() {
    assert(_root != null);
    _root.remove();
    _root = null;
  }
}

class Text extends Node {
  String data;

  // Text nodes are special cases of having non-unique keys (which don't need
  // to be assigned as part of the API). Since they are unique in not having
  // children, there's little point to reordering, so we always just re-assign
  // the data.
  Text(this.data) : super(key:'*text*');

  bool _sync(Node old, sky.ParentNode host, sky.Node insertBefore) {
    if (old == null) {
      _root = new sky.Text(data);
      _parentInsertBefore(host, _root, insertBefore);
      return false;
    }

    _root = old._root;
    (_root as sky.Text).data = data;
    return false;
  }
}

final List<Node> _emptyList = new List<Node>();

abstract class Element extends Node {

  String get _tagName;

  Element get _emptyElement;

  String inlineStyle;

  List<Node> _children = null;
  String _class = '';

  Element({
    Object key,
    List<Node> children,
    List<Style> styles,

    this.inlineStyle
  }) : super(key:key) {
    _class = styles == null ? '' : styles.map((s) => s._className).join(' ');
    _children = children == null ? _emptyList : children;

    if (_isInCheckedMode) {
      _debugReportDuplicateIds();
    }
  }

  void _remove() {
    super._remove();
    if (_children != null) {
      for (var child in _children) {
        child._remove();
      }
    }
    _children = null;
  }

  void _debugReportDuplicateIds() {
    var idSet = new HashSet<String>();
    for (var child in _children) {
      if (child is Text) {
        continue; // Text nodes all have the same key and are never reordered.
      }

      if (!idSet.add(child._key)) {
        throw '''If multiple (non-Text) nodes of the same type exist as children
                 of another node, they must have unique keys.''';
      }
    }
  }

  void _syncEvents([Element old]) {
    List<EventHandler> newHandlers = events._handlers;
    int newStartIndex = 0;
    int newEndIndex = newHandlers.length;

    List<EventHandler> oldHandlers = old.events._handlers;
    int oldStartIndex = 0;
    int oldEndIndex = oldHandlers.length;

    // Skip over leading handlers that match.
    while (newStartIndex < newEndIndex && oldStartIndex < oldEndIndex) {
      EventHandler newHandler = newHandlers[newStartIndex];
      EventHandler oldHandler = oldHandlers[oldStartIndex];
      if (newHandler.type != oldHandler.type
          || newHandler.listener != oldHandler.listener)
        break;
      ++newStartIndex;
      ++oldStartIndex;
    }

    // Skip over trailing handlers that match.
    while (newStartIndex < newEndIndex && oldStartIndex < oldEndIndex) {
      EventHandler newHandler = newHandlers[newEndIndex - 1];
      EventHandler oldHandler = oldHandlers[oldEndIndex - 1];
      if (newHandler.type != oldHandler.type
          || newHandler.listener != oldHandler.listener)
        break;
      --newEndIndex;
      --oldEndIndex;
    }

    sky.Element root = _root as sky.Element;

    for (int i = oldStartIndex; i < oldEndIndex; ++i) {
      EventHandler oldHandler = oldHandlers[i];
      root.removeEventListener(oldHandler.type, oldHandler.listener);
    }

    for (int i = newStartIndex; i < newEndIndex; ++i) {
      EventHandler newHandler = newHandlers[i];
      root.addEventListener(newHandler.type, newHandler.listener);
    }
  }

  void _syncNode([Element old]) {
    if (old == null) {
      old = _emptyElement;
    }

    _syncEvents(old);

    sky.Element root = _root as sky.Element;
    if (_class != old._class) {
      root.setAttribute('class', _class);
    }

    if (inlineStyle != old.inlineStyle) {
      root.setAttribute('style', inlineStyle);
    }
  }

  bool _sync(Node old, sky.ParentNode host, sky.Node insertBefore) {
    // print("---Syncing children of $_key");

    Element oldElement = old as Element;

    if (oldElement == null) {
      // print("...no oldElement, initial build");

      _root = sky.document.createElement(_tagName);
      _parentInsertBefore(host, _root, insertBefore);
      _syncNode();

      for (var child in _children) {
        child._sync(null, _root, null);
        assert(child._root is sky.Node);
      }

      return false;
    }

    if (this == oldElement)
      return false;

    _root = oldElement._root;
    oldElement._root = null;
    sky.Element root = (_root as sky.Element);

    _syncNode(oldElement);

    var startIndex = 0;
    var endIndex = _children.length;

    var oldChildren = oldElement._children;
    var oldStartIndex = 0;
    var oldEndIndex = oldChildren.length;

    sky.Node nextSibling = null;
    Node currentNode = null;
    Node oldNode = null;

    void sync(int atIndex) {
      if (currentNode._sync(oldNode, root, nextSibling)) {
        // oldNode was stateful and must be retained.
        assert(oldNode != null);
        currentNode = oldNode;
        _children[atIndex] = currentNode;
      }
      assert(currentNode._root is sky.Node);
    }

    // Scan backwards from end of list while nodes can be directly synced
    // without reordering.
    // print("...scanning backwards");
    while (endIndex > startIndex && oldEndIndex > oldStartIndex) {
      currentNode = _children[endIndex - 1];
      oldNode = oldChildren[oldEndIndex - 1];

      if (currentNode._key != oldNode._key) {
        break;
      }

      // print('> syncing matched at: $endIndex : $oldEndIndex');
      endIndex--;
      oldEndIndex--;
      sync(endIndex);
      nextSibling = currentNode._root;
    }

    HashMap<String, Node> oldNodeIdMap = null;

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

      oldNodeIdMap = new HashMap<String, Node>();
      for (int i = oldStartIndex; i < oldEndIndex; i++) {
        var node = oldChildren[i];
        if (node is! Text) {
          oldNodeIdMap.putIfAbsent(node._key, () => node);
        }
      }
    }

    bool searchForOldNode() {
      if (currentNode is Text)
        return false; // Never re-order Text nodes.

      ensureOldIdMap();
      oldNode = oldNodeIdMap[currentNode._key];
      if (oldNode == null)
        return false;

      oldNodeIdMap[currentNode._key] = null; // mark it reordered.
      // print("Reparenting ${currentNode._key}");
      _parentInsertBefore(root, oldNode._root, nextSibling);
      return true;
    }

    // Scan forwards, this time we may re-order;
    // print("...scanning forward");
    nextSibling = root.firstChild;
    while (startIndex < endIndex && oldStartIndex < oldEndIndex) {
      currentNode = _children[startIndex];
      oldNode = oldChildren[oldStartIndex];

      if (currentNode._key == oldNode._key) {
        // print('> syncing matched at: $startIndex : $oldStartIndex');
        assert(currentNode.runtimeType == oldNode.runtimeType);
        nextSibling = nextSibling.nextSibling;
        sync(startIndex);
        startIndex++;
        advanceOldStartIndex();
        continue;
      }

      oldNode = null;
      if (searchForOldNode()) {
        // print('> reordered to $startIndex');
      } else {
        // print('> inserting at $startIndex');
      }

      sync(startIndex);
      startIndex++;
    }

    // New insertions
    oldNode = null;
    // print('...processing remaining insertions');
    while (startIndex < endIndex) {
      // print('> inserting at $startIndex');
      currentNode = _children[startIndex];
      sync(startIndex);
      startIndex++;
    }

    // Removals
    // print('...processing remaining removals');
    currentNode = null;
    while (oldStartIndex < oldEndIndex) {
      oldNode = oldChildren[oldStartIndex];
      // print('> ${oldNode._key} removing from $oldEndIndex');
      oldNode._remove();
      advanceOldStartIndex();
    }

    oldElement._children = null;
    return false;
  }
}

class Container extends Element {

  String get _tagName => 'div';

  static final Container _emptyContainer = new Container();
  Element get _emptyElement => _emptyContainer;

  Container({
    Object key,
    List<Node> children,
    List<Style> styles,
    String inlineStyle
  }) : super(
    key: key,
    children: children,
    styles: styles,
    inlineStyle: inlineStyle
  );
}

class Image extends Element {

  String get _tagName => 'img';

  static final Image _emptyImage = new Image();
  Element get _emptyElement => _emptyImage;

  String src;
  int width;
  int height;

  Image({
    Object key,
    List<Node> children,
    List<Style> styles,
    String inlineStyle,
    this.width,
    this.height,
    this.src
  }) : super(
    key: key,
    children: children,
    styles: styles,
    inlineStyle: inlineStyle
  );

  void _syncNode([Element old]) {
    super._syncNode(old);

    Image oldImage = old != null ? old : _emptyImage;
    sky.HTMLImageElement skyImage = _root as sky.HTMLImageElement;
    if (src != oldImage.src) {
      skyImage.src = src;
    }

    if (width != oldImage.width) {
      skyImage.style['width'] = '${width}px';
    }
    if (height != oldImage.height) {
      skyImage.style['height'] = '${height}px';
    }
  }
}

class Anchor extends Element {

  String get _tagName => 'a';

  static final Anchor _emptyAnchor = new Anchor();
  Element get _emptyElement => _emptyAnchor;

  String href;
  int width;
  int height;

  Anchor({
    Object key,
    List<Node> children,
    List<Style> styles,
    String inlineStyle,
    this.width,
    this.height,
    this.href
  }) : super(
    key: key,
    children: children,
    styles: styles,
    inlineStyle: inlineStyle
  );

  void _syncNode([Element old]) {
    Anchor oldAnchor = old != null ? old as Anchor : _emptyAnchor;
    super._syncNode(oldAnchor);

    sky.HTMLAnchorElement skyAnchor = _root as sky.HTMLAnchorElement;
    if (href != oldAnchor.href) {
      skyAnchor.href = href;
    }
  }
}

List<Component> _dirtyComponents = new List<Component>();
bool _buildScheduled = false;
bool _inRenderDirtyComponents = false;

void _buildDirtyComponents() {
  try {
    _inRenderDirtyComponents = true;
    Stopwatch sw = new Stopwatch()..start();

    _dirtyComponents.sort((a, b) => a._order - b._order);
    for (var comp in _dirtyComponents) {
      comp._buildIfDirty();
    }

    _dirtyComponents.clear();
    _buildScheduled = false;

    sw.stop();
    if (_shouldLogRenderDuration)
      print("Render took ${sw.elapsedMicroseconds} microseconds");
  } finally {
    _inRenderDirtyComponents = false;
  }
}

void _scheduleComponentForRender(Component c) {
  assert(!_inRenderDirtyComponents);
  _dirtyComponents.add(c);

  if (!_buildScheduled) {
    _buildScheduled = true;
    new Future.microtask(_buildDirtyComponents);
  }
}

abstract class Component extends Node {
  bool _dirty = true; // components begin dirty because they haven't built.
  Node _vdom = null;
  bool _removed = false;
  final int _order;
  static int _currentOrder = 0;
  bool _stateful;
  static Component _currentlyRendering;

  Component({ Object key, bool stateful })
      : _stateful = stateful != null ? stateful : false,
        _order = _currentOrder + 1,
        super(key:key);

  void didMount() {}
  void didUnmount() {}

  void _remove() {
    assert(_vdom != null);
    assert(_root != null);
    _vdom._remove();
    _vdom = null;
    _root = null;
    _removed = true;
    didUnmount();
  }

  // TODO(rafaelw): It seems wrong to expose DOM at all. This is presently
  // needed to get sizing info.
  sky.Node getRoot() => _root;

  bool _sync(Node old, sky.Node host, sky.Node insertBefore) {
    Component oldComponent = old as Component;

    if (oldComponent == null || oldComponent == this) {
      _buildInternal(host, insertBefore);
      return false;
    }

    assert(oldComponent != null);
    assert(_dirty);
    assert(_vdom == null);

    if (oldComponent._stateful) {
      _stateful = false; // prevent iloop from _buildInternal below.

      reflect.copyPublicFields(this, oldComponent);

      oldComponent._dirty = true;
      _dirty = false;

      oldComponent._buildInternal(host, insertBefore);
      return true;  // Must retain old component
    }

    _vdom = oldComponent._vdom;
    _buildInternal(host, insertBefore);
    return false;
  }

  void _buildInternal(sky.Node host, sky.Node insertBefore) {
    if (!_dirty) {
      assert(_vdom != null);
      return;
    }

    var oldRendered = _vdom;
    bool mounting = oldRendered == null;
    int lastOrder = _currentOrder;
    _currentOrder = _order;
    _currentlyRendering = this;
    _vdom = build();
    _currentlyRendering = null;
    _currentOrder = lastOrder;

    _vdom.events.addAll(events);

    _dirty = false;

    // TODO(rafaelw): This eagerly removes the old DOM. It may be that a
    // new component was built that could re-use some of it. Consider
    // syncing the new VDOM against the old one.
    if (oldRendered != null &&
        _vdom.runtimeType != oldRendered.runtimeType) {
      oldRendered._remove();
      oldRendered = null;
    }

    if (_vdom._sync(oldRendered, host, insertBefore)) {
      _vdom = oldRendered; // retain stateful component
    }
    _root = _vdom._root;
    assert(_vdom._root is sky.Node);

    if (mounting) {
      didMount();
    }
  }

  void _buildIfDirty() {
    if (_removed)
      return;

    assert(_vdom != null);

    var vdom = _vdom;
    while (vdom is Component) {
      vdom = vdom._vdom;
    }

    assert(vdom._root != null);
    sky.Node root = vdom._root;

    _buildInternal(root.parentNode, root.nextSibling);
  }

  void setState(Function fn()) {
    assert(_vdom != null || _removed); // cannot setState before mounting.
    _stateful = true;
    fn();
    if (!_removed && _currentlyRendering != this) {
      _dirty = true;
      _scheduleComponentForRender(this);
    }
  }

  Node build();
}

abstract class App extends Component {
  sky.Node _host = null;
  App() : super(stateful: true) {
    _host = sky.document.createElement('div');
    sky.document.appendChild(_host);

    new Future.microtask(() {
      Stopwatch sw = new Stopwatch()..start();

      _sync(null, _host, null);
      assert(_root is sky.Node);

      sw.stop();
      if (_shouldLogRenderDuration)
        print("Initial build: ${sw.elapsedMicroseconds} microseconds");
    });
  }
}
