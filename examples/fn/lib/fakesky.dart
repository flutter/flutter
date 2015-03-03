import 'dart:async';

void assertHasParentNode(Node n) { assert(n.parentNode != null); }
void assertHasParentNodes(List<Node> list) {
  for (var n in list) {
    assertHasParentNode(n);
  }
}

class Node {

  ParentNode parentNode;
  Node nextSibling;
  Node previousSibling;
  Node();

  void insertBefore(List<Node> nodes) {
    int count = nodes.length;
    while (count-- > 0) {
      parentNode._insertBefore(nodes[count], this);
    }

    assertHasParentNodes(nodes);
  }

  remove() {
    if (parentNode == null) {
      return;
    }

    if (nextSibling != null) {
      nextSibling.previousSibling = previousSibling;
    } else {
      parentNode.lastChild = previousSibling;
    }

    if (previousSibling != null) {
      previousSibling.nextSibling = nextSibling;
    } else {
      parentNode.firstChild = nextSibling;
    }

    parentNode = null;
    nextSibling = null;
    previousSibling = null;
  }
}

class Text extends Node {
  String data;
  Text(this.data) : super();
}

class ParentNode extends Node {
  Node firstChild;
  Node lastChild;

  ParentNode() : super();

  Node setChild(Node node) {
    firstChild = node;
    lastChild = node;
    node.parentNode = this;
    assertHasParentNode(node);
    return node;
  }

  Node _insertBefore(Node node, Node ref) {
    assert(ref == null || ref.parentNode == this);

    if (node.parentNode != null) {
      node.remove();
    }

    node.parentNode = this;

    if (firstChild == null && lastChild == null) {
      firstChild = node;
      lastChild = node;
    } else if (ref == null) {
      node.previousSibling = lastChild;
      lastChild.nextSibling = node;
      lastChild = node;
    } else {
      if (ref == firstChild) {
        assert(ref.previousSibling == null);
        firstChild = node;
      }
      node.previousSibling = ref.previousSibling;
      ref.previousSibling = node;
      node.nextSibling = ref;
    }

    assertHasParentNode(node);
    return node;
  }

  Node appendChild(Node node) {
    return _insertBefore(node, null);
  }
}

class Element extends ParentNode {
  void addEventListener(String type, EventListener listener, [bool useCapture = false]) {}
  void removeEventListener(String type, EventListener listener) {}
  void setAttribute(String name, [String value]) {}
}

class Document extends ParentNode {
  Document();
  Element createElement(String tagName) {
    switch (tagName) {
      case 'img' : return new HTMLImageElement();
      default : return new Element();
    }
  }
}

class HTMLImageElement extends Element {
  Image();
  String src;
  Object style = {};
}

class Event {
  Event();
}

typedef EventListener(Event event);

void _callRAF(Function fn) {
  fn(new DateTime.now().millisecondsSinceEpoch.toDouble());
}

class Window {
  int requestAnimationFrame(Function fn) {
    new Timer(const Duration(milliseconds: 16), () {
      _callRAF(fn);
    });
  }

  void cancelAnimationFrame(int id) {
  }
}

Document document = new Document();

Window window = new Window();
