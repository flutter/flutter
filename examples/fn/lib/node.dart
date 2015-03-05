// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of fn;

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
  String _className = '';

  Element({
    Object key,
    List<Node> children,
    Style style,

    this.inlineStyle
  }) : super(key:key) {

    _className = style == null ? '': style._className;
    _children = children == null ? _emptyList : children;

    if (_debugWarnings()) {
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
      EventHandler newHander = newHandlers[newStartIndex];
      EventHandler oldHandler = oldHandlers[oldStartIndex];
      if (newHander.type != oldHandler.type
          || newHander.listener != oldHandler.listener)
        break;
      ++newStartIndex;
      ++oldStartIndex;
    }

    // Skip over trailing handlers that match.
    while (newStartIndex < newEndIndex && oldStartIndex < oldEndIndex) {
      EventHandler newHander = newHandlers[newEndIndex - 1];
      EventHandler oldHandler = oldHandlers[oldEndIndex - 1];
      if (newHander.type != oldHandler.type
          || newHander.listener != oldHandler.listener)
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
      EventHandler newHander = newHandlers[i];
      root.addEventListener(newHander.type, newHander.listener);
    }
  }

  void _syncNode([Element old]) {
    if (old == null) {
      old = _emptyElement;
    }

    _syncEvents(old);

    sky.Element root = _root as sky.Element;
    if (_className != old._className) {
      root.setAttribute('class', _className);
    }

    if (inlineStyle != old.inlineStyle) {
      root.setAttribute('style', inlineStyle);
    }
  }

  bool _sync(Node old, sky.ParentNode host, sky.Node insertBefore) {
    // print("---Syncing children of $_key");

    Element oldElement = old as Element;

    if (oldElement == null) {
      // print("...no oldElement, initial render");

      _root = sky.document.createElement(_tagName);
      _syncNode();

      for (var child in _children) {
        child._sync(null, _root, null);
        assert(child._root is sky.Node);
      }

      _parentInsertBefore(host, _root, insertBefore);
      return false;
    }

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
    Style style,
    String inlineStyle
  }) : super(
    key: key,
    children: children,
    style: style,
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
    Style style,
    String inlineStyle,
    this.width,
    this.height,
    this.src
  }) : super(
    key: key,
    children: children,
    style: style,
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

  String href;

  Anchor({
    Object key,
    List<Node> children,
    Style style,
    String inlineStyle,
    this.width,
    this.height,
    this.href
  }) : super(
    key: key,
    children: children,
    style: style,
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
