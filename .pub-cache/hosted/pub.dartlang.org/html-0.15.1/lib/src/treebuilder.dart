/// Internals to the tree builders.
library treebuilder;

import 'dart:collection';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show getElementNameTuple;
import 'package:source_span/source_span.dart';
import 'constants.dart';
import 'list_proxy.dart';
import 'token.dart';
import 'utils.dart';

/// Open elements in the formatting category, most recent element last.
///
/// `null` is used as the "marker" entry to prevent style from leaking when
/// entering some elements.
///
/// https://html.spec.whatwg.org/multipage/parsing.html#list-of-active-formatting-elements
class ActiveFormattingElements extends ListProxy<Element?> {
  /// Push an element into the active formatting elements.
  ///
  /// Prevents equivalent elements from appearing more than 3 times following
  /// the last `null` marker. If adding [node] would cause there to be more than
  /// 3 equivalent elements the earliest identical element is removed.
  // TODO - Earliest equivalent following a marker, as opposed to earliest
  // identical regardless of marker position, should be removed.
  @override
  void add(Element? node) {
    var equalCount = 0;
    if (node != null) {
      for (var element in reversed) {
        if (element == null) {
          break;
        }
        if (_nodesEqual(element, node)) {
          equalCount += 1;
        }
        if (equalCount == 3) {
          // TODO - https://github.com/dart-lang/html/issues/135
          remove(element);
          break;
        }
      }
    }
    super.add(node);
  }
}

// TODO(jmesserly): this should exist in corelib...
bool _mapEquals(Map a, Map b) {
  if (a.length != b.length) return false;
  if (a.isEmpty) return true;

  for (var keyA in a.keys) {
    final valB = b[keyA];
    if (valB == null && !b.containsKey(keyA)) {
      return false;
    }

    if (a[keyA] != valB) {
      return false;
    }
  }
  return true;
}

bool _nodesEqual(Element node1, Element node2) {
  return getElementNameTuple(node1) == getElementNameTuple(node2) &&
      _mapEquals(node1.attributes, node2.attributes);
}

/// Basic treebuilder implementation.
class TreeBuilder {
  final String? defaultNamespace;

  late Document document;

  final List<Element> openElements = <Element>[];

  final activeFormattingElements = ActiveFormattingElements();

  Node? headPointer;

  Element? formPointer;

  /// Switch the function used to insert an element from the
  /// normal one to the misnested table one and back again
  var insertFromTable = false;

  TreeBuilder(bool namespaceHTMLElements)
      : defaultNamespace = namespaceHTMLElements ? Namespaces.html : null {
    reset();
  }

  void reset() {
    openElements.clear();
    activeFormattingElements.clear();

    //XXX - rename these to headElement, formElement
    headPointer = null;
    formPointer = null;

    insertFromTable = false;

    document = Document();
  }

  bool elementInScope(target, {String? variant}) {
    //If we pass a node in we match that. if we pass a string
    //match any node with that name
    final exactNode = target is Node;

    var listElements1 = scopingElements;
    var listElements2 = const <Pair>[];
    var invert = false;
    if (variant != null) {
      switch (variant) {
        case 'button':
          listElements2 = const [Pair(Namespaces.html, 'button')];
          break;
        case 'list':
          listElements2 = const [
            Pair(Namespaces.html, 'ol'),
            Pair(Namespaces.html, 'ul')
          ];
          break;
        case 'table':
          listElements1 = const [
            Pair(Namespaces.html, 'html'),
            Pair(Namespaces.html, 'table')
          ];
          break;
        case 'select':
          listElements1 = const [
            Pair(Namespaces.html, 'optgroup'),
            Pair(Namespaces.html, 'option')
          ];
          invert = true;
          break;
        default:
          throw StateError('We should never reach this point');
      }
    }

    for (var node in openElements.reversed) {
      if (!exactNode && node.localName == target ||
          exactNode && node == target) {
        return true;
      } else if (invert !=
          (listElements1.contains(getElementNameTuple(node)) ||
              listElements2.contains(getElementNameTuple(node)))) {
        return false;
      }
    }

    throw StateError('We should never reach this point');
  }

  void reconstructActiveFormattingElements() {
    // Within this algorithm the order of steps described in the
    // specification is not quite the same as the order of steps in the
    // code. It should still do the same though.

    // Step 1: stop the algorithm when there's nothing to do.
    if (activeFormattingElements.isEmpty) {
      return;
    }

    // Step 2 and step 3: we start with the last element. So i is -1.
    var i = activeFormattingElements.length - 1;
    var entry = activeFormattingElements[i];
    if (entry == null || openElements.contains(entry)) {
      return;
    }

    // Step 6
    while (entry != null && !openElements.contains(entry)) {
      if (i == 0) {
        //This will be reset to 0 below
        i = -1;
        break;
      }
      i -= 1;
      // Step 5: let entry be one earlier in the list.
      entry = activeFormattingElements[i];
    }

    while (true) {
      // Step 7
      i += 1;

      // Step 8
      entry = activeFormattingElements[i];

      // TODO(jmesserly): optimize this. No need to create a token.
      final cloneToken = StartTagToken(entry!.localName,
          namespace: entry.namespaceUri,
          data: LinkedHashMap.from(entry.attributes))
        ..span = entry.sourceSpan;

      // Step 9
      final element = insertElement(cloneToken);

      // Step 10
      activeFormattingElements[i] = element;

      // Step 11
      if (element == activeFormattingElements.last) {
        break;
      }
    }
  }

  void clearActiveFormattingElements() {
    var entry = activeFormattingElements.removeLast();
    while (activeFormattingElements.isNotEmpty && entry != null) {
      entry = activeFormattingElements.removeLast();
    }
  }

  /// Check if an element exists between the end of the active
  /// formatting elements and the last marker. If it does, return it, else
  /// return null.
  Element? elementInActiveFormattingElements(String? name) {
    for (var item in activeFormattingElements.reversed) {
      // Check for Marker first because if it's a Marker it doesn't have a
      // name attribute.
      if (item == null) {
        break;
      } else if (item.localName == name) {
        return item;
      }
    }
    return null;
  }

  void insertRoot(StartTagToken token) {
    final element = createElement(token);
    openElements.add(element);
    document.nodes.add(element);
  }

  void insertDoctype(DoctypeToken token) {
    final doctype = DocumentType(token.name, token.publicId, token.systemId)
      ..sourceSpan = token.span;
    document.nodes.add(doctype);
  }

  void insertComment(StringToken token, [Node? parent]) {
    parent ??= openElements.last;
    parent.nodes.add(Comment(token.data)..sourceSpan = token.span);
  }

  /// Create an element but don't insert it anywhere
  Element createElement(StartTagToken token) {
    final name = token.name;
    final namespace = token.namespace ?? defaultNamespace;
    final element = document.createElementNS(namespace, name)
      ..attributes = token.data
      ..sourceSpan = token.span;
    return element;
  }

  Element insertElement(StartTagToken token) {
    if (insertFromTable) return insertElementTable(token);
    return insertElementNormal(token);
  }

  Element insertElementNormal(StartTagToken token) {
    final name = token.name;
    final namespace = token.namespace ?? defaultNamespace;
    final element = document.createElementNS(namespace, name)
      ..attributes = token.data
      ..sourceSpan = token.span;
    openElements.last.nodes.add(element);
    openElements.add(element);
    return element;
  }

  Element insertElementTable(StartTagToken token) {
    /// Create an element and insert it into the tree
    final element = createElement(token);
    if (!tableInsertModeElements.contains(openElements.last.localName)) {
      return insertElementNormal(token);
    } else {
      // We should be in the InTable mode. This means we want to do
      // special magic element rearranging
      final nodePos = getTableMisnestedNodePosition();
      if (nodePos[1] == null) {
        // TODO(jmesserly): I don't think this is reachable. If insertFromTable
        // is true, there will be a <table> element open, and it always has a
        // parent pointer.
        nodePos[0]!.nodes.add(element);
      } else {
        nodePos[0]!.insertBefore(element, nodePos[1]);
      }
      openElements.add(element);
    }
    return element;
  }

  /// Insert text data.
  void insertText(String data, FileSpan? span) {
    final parent = openElements.last;

    if (!insertFromTable ||
        insertFromTable &&
            !tableInsertModeElements.contains(openElements.last.localName)) {
      _insertText(parent, data, span);
    } else {
      // We should be in the InTable mode. This means we want to do
      // special magic element rearranging
      final nodePos = getTableMisnestedNodePosition();
      _insertText(nodePos[0]!, data, span, nodePos[1] as Element?);
    }
  }

  /// Insert [data] as text in the current node, positioned before the
  /// start of node [refNode] or to the end of the node's text.
  static void _insertText(Node parent, String data, FileSpan? span,
      [Element? refNode]) {
    final nodes = parent.nodes;
    if (refNode == null) {
      if (nodes.isNotEmpty && nodes.last is Text) {
        final last = nodes.last as Text;
        last.appendData(data);

        if (span != null) {
          last.sourceSpan =
              span.file.span(last.sourceSpan!.start.offset, span.end.offset);
        }
      } else {
        nodes.add(Text(data)..sourceSpan = span);
      }
    } else {
      final index = nodes.indexOf(refNode);
      if (index > 0 && nodes[index - 1] is Text) {
        final last = nodes[index - 1] as Text;
        last.appendData(data);
      } else {
        nodes.insert(index, Text(data)..sourceSpan = span);
      }
    }
  }

  /// Get the foster parent element, and sibling to insert before
  /// (or null) when inserting a misnested table node
  List<Node?> getTableMisnestedNodePosition() {
    // The foster parent element is the one which comes before the most
    // recently opened table element
    // XXX - this is really inelegant
    Element? lastTable;
    Node? fosterParent;
    Node? insertBefore;
    for (var elm in openElements.reversed) {
      if (elm.localName == 'table') {
        lastTable = elm;
        break;
      }
    }
    if (lastTable != null) {
      // XXX - we should really check that this parent is actually a
      // node here
      if (lastTable.parentNode != null) {
        fosterParent = lastTable.parentNode;
        insertBefore = lastTable;
      } else {
        fosterParent = openElements[openElements.indexOf(lastTable) - 1];
      }
    } else {
      fosterParent = openElements[0];
    }
    return [fosterParent, insertBefore];
  }

  void generateImpliedEndTags([String? exclude]) {
    final name = openElements.last.localName;
    // XXX td, th and tr are not actually needed
    if (name != exclude &&
        const ['dd', 'dt', 'li', 'option', 'optgroup', 'p', 'rp', 'rt']
            .contains(name)) {
      openElements.removeLast();
      // XXX This is not entirely what the specification says. We should
      // investigate it more closely.
      generateImpliedEndTags(exclude);
    }
  }

  /// Return the final tree.
  Document getDocument() => document;

  /// Return the final fragment.
  DocumentFragment getFragment() {
    //XXX assert innerHTML
    final fragment = DocumentFragment();
    openElements[0].reparentChildren(fragment);
    return fragment;
  }
}
