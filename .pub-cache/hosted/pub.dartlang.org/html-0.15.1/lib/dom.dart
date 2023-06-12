/// A simple tree API that results from parsing html. Intended to be compatible
/// with dart:html, but it is missing many types and APIs.
library dom;

// ignore_for_file: constant_identifier_names

// TODO(jmesserly): lots to do here. Originally I wanted to generate this using
// our Blink IDL generator, but another idea is to directly use the excellent
// http://dom.spec.whatwg.org/ and http://html.spec.whatwg.org/ and just
// implement that.

import 'dart:collection';

import 'package:source_span/source_span.dart';

import 'dom_parsing.dart';
import 'parser.dart';
import 'src/constants.dart';
import 'src/css_class_set.dart';
import 'src/list_proxy.dart';
import 'src/query_selector.dart' as query;
import 'src/token.dart';
import 'src/tokenizer.dart';

export 'src/css_class_set.dart' show CssClassSet;

// TODO(jmesserly): this needs to be replaced by an AttributeMap for attributes
// that exposes namespace info.
class AttributeName implements Comparable<Object> {
  /// The namespace prefix, e.g. `xlink`.
  final String? prefix;

  /// The attribute name, e.g. `title`.
  final String name;

  /// The namespace url, e.g. `http://www.w3.org/1999/xlink`
  final String namespace;

  const AttributeName(this.prefix, this.name, this.namespace);

  @override
  String toString() {
    // Implement:
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#serializing-html-fragments
    // If we get here we know we are xml, xmlns, or xlink, because of
    // [HtmlParser.adjustForeignAttriubtes] is the only place we create
    // an AttributeName.
    return prefix != null ? '$prefix:$name' : name;
  }

  @override
  int get hashCode {
    var h = prefix.hashCode;
    h = 37 * (h & 0x1FFFFF) + name.hashCode;
    h = 37 * (h & 0x1FFFFF) + namespace.hashCode;
    return h & 0x3FFFFFFF;
  }

  @override
  int compareTo(Object other) {
    // Not sure about this sort order
    if (other is! AttributeName) return 1;
    var cmp = (prefix ?? '').compareTo((other.prefix ?? ''));
    if (cmp != 0) return cmp;
    cmp = name.compareTo(other.name);
    if (cmp != 0) return cmp;
    return namespace.compareTo(other.namespace);
  }

  @override
  bool operator ==(Object other) =>
      other is AttributeName &&
      prefix == other.prefix &&
      name == other.name &&
      namespace == other.namespace;
}

// http://dom.spec.whatwg.org/#parentnode
abstract class _ParentNode implements Node {
  // TODO(jmesserly): this is only a partial implementation

  /// Seaches for the first descendant node matching the given selectors, using
  /// a preorder traversal.
  ///
  /// NOTE: Not all selectors from
  /// [selectors level 4](http://dev.w3.org/csswg/selectors-4/)
  /// are implemented. For example, nth-child does not implement An+B syntax
  /// and *-of-type is not implemented. If a selector is not implemented this
  /// method will throw [UnimplementedError].
  Element? querySelector(String selector) =>
      query.querySelector(this, selector);

  /// Returns all descendant nodes matching the given selectors, using a
  /// preorder traversal.
  ///
  /// NOTE: Not all selectors from
  /// [selectors level 4](http://dev.w3.org/csswg/selectors-4/)
  /// are implemented. For example, nth-child does not implement An+B syntax
  /// and *-of-type is not implemented. If a selector is not implemented this
  /// method will throw [UnimplementedError].
  List<Element> querySelectorAll(String selector) =>
      query.querySelectorAll(this, selector);
}

// http://dom.spec.whatwg.org/#interface-nonelementparentnode
abstract class _NonElementParentNode implements _ParentNode {
  // TODO(jmesserly): could be faster, should throw on invalid id.
  Element? getElementById(String id) => querySelector('#$id');
}

// This doesn't exist as an interface in the spec, but it's useful to merge
// common methods from these:
// http://dom.spec.whatwg.org/#interface-document
// http://dom.spec.whatwg.org/#element
abstract class _ElementAndDocument implements _ParentNode {
  // TODO(jmesserly): could be faster, should throw on invalid tag/class names.

  List<Element> getElementsByTagName(String localName) =>
      querySelectorAll(localName);

  List<Element> getElementsByClassName(String classNames) =>
      querySelectorAll(classNames.splitMapJoin(' ',
          onNonMatch: (m) => m.isNotEmpty ? '.$m' : m, onMatch: (m) => ''));
}

/// Really basic implementation of a DOM-core like Node.
abstract class Node {
  static const int ATTRIBUTE_NODE = 2;
  static const int CDATA_SECTION_NODE = 4;
  static const int COMMENT_NODE = 8;
  static const int DOCUMENT_FRAGMENT_NODE = 11;
  static const int DOCUMENT_NODE = 9;
  static const int DOCUMENT_TYPE_NODE = 10;
  static const int ELEMENT_NODE = 1;
  static const int ENTITY_NODE = 6;
  static const int ENTITY_REFERENCE_NODE = 5;
  static const int NOTATION_NODE = 12;
  static const int PROCESSING_INSTRUCTION_NODE = 7;
  static const int TEXT_NODE = 3;

  /// The parent of the current node (or null for the document node).
  Node? parentNode;

  /// The parent element of this node.
  ///
  /// Returns null if this node either does not have a parent or its parent is
  /// not an element.
  Element? get parent {
    final parentNode = this.parentNode;
    return parentNode is Element ? parentNode : null;
  }

  // TODO(jmesserly): should move to Element.
  /// A map holding name, value pairs for attributes of the node.
  ///
  /// Note that attribute order needs to be stable for serialization, so we use
  /// a LinkedHashMap. Each key is a [String] or [AttributeName].
  LinkedHashMap<Object, String> attributes = LinkedHashMap();

  /// A list of child nodes of the current node. This must
  /// include all elements but not necessarily other node types.
  late final nodes = NodeList._(this);

  late final List<Element> children = FilteredElementList(this);

  // TODO(jmesserly): consider using an Expando for this, and put it in
  // dom_parsing. Need to check the performance affect.
  /// The source span of this node, if it was created by the [HtmlParser].
  FileSpan? sourceSpan;

  /// The attribute spans if requested. Otherwise null.
  LinkedHashMap<Object, FileSpan>? _attributeSpans;
  LinkedHashMap<Object, FileSpan>? _attributeValueSpans;

  Node._();

  /// If [sourceSpan] is available, this contains the spans of each attribute.
  /// The span of an attribute is the entire attribute, including the name and
  /// quotes (if any). For example, the span of "attr" in `<a attr="value">`
  /// would be the text `attr="value"`.
  LinkedHashMap<Object, FileSpan>? get attributeSpans {
    _ensureAttributeSpans();
    return _attributeSpans;
  }

  /// If [sourceSpan] is available, this contains the spans of each attribute's
  /// value. Unlike [attributeSpans], this span will include only the value.
  /// For example, the value span of "attr" in `<a attr="value">` would be the
  /// text `value`.
  LinkedHashMap<Object, FileSpan>? get attributeValueSpans {
    _ensureAttributeSpans();
    return _attributeValueSpans;
  }

  /// Returns a copy of this node.
  ///
  /// If [deep] is `true`, then all of this node's children and decendents are
  /// copied as well. If [deep] is `false`, then only this node is copied.
  Node clone(bool deep);

  int get nodeType;

  // http://domparsing.spec.whatwg.org/#extensions-to-the-element-interface
  String get _outerHtml {
    final str = StringBuffer();
    _addOuterHtml(str);
    return str.toString();
  }

  String get _innerHtml {
    final str = StringBuffer();
    _addInnerHtml(str);
    return str.toString();
  }

  // Implemented per: http://dom.spec.whatwg.org/#dom-node-textcontent
  String? get text => null;

  set text(String? value) {}

  void append(Node node) => nodes.add(node);

  Node? get firstChild => nodes.isNotEmpty ? nodes[0] : null;

  void _addOuterHtml(StringBuffer str);

  void _addInnerHtml(StringBuffer str) {
    for (var child in nodes) {
      child._addOuterHtml(str);
    }
  }

  Node remove() {
    // TODO(jmesserly): is parent == null an error?
    parentNode?.nodes.remove(this);
    return this;
  }

  /// Insert [node] as a child of the current node, before [refNode] in the
  void insertBefore(Node node, Node? refNode) {
    if (refNode == null) {
      nodes.add(node);
    } else {
      nodes.insert(nodes.indexOf(refNode), node);
    }
  }

  /// Replaces this node with another node.
  Node replaceWith(Node otherNode) {
    if (parentNode == null) {
      throw UnsupportedError('Node must have a parent to replace it.');
    }
    parentNode!.nodes[parentNode!.nodes.indexOf(this)] = otherNode;
    return this;
  }

  // TODO(jmesserly): should this be a property or remove?
  /// Return true if the node has children or text.
  bool hasContent() => nodes.isNotEmpty;

  /// Move all the children of the current node to [newParent].
  /// This is needed so that trees that don't store text as nodes move the
  /// text in the correct way.
  void reparentChildren(Node newParent) {
    newParent.nodes.addAll(nodes);
    nodes.clear();
  }

  bool hasChildNodes() => nodes.isNotEmpty;

  bool contains(Node node) => nodes.contains(node);

  /// Initialize [attributeSpans] using [sourceSpan].
  void _ensureAttributeSpans() {
    if (_attributeSpans != null) return;

    final attributeSpans = _attributeSpans = LinkedHashMap<Object, FileSpan>();
    final attributeValueSpans =
        _attributeValueSpans = LinkedHashMap<Object, FileSpan>();

    if (sourceSpan == null) return;

    final tokenizer = HtmlTokenizer(sourceSpan!.text,
        generateSpans: true, attributeSpans: true);

    tokenizer.moveNext();
    final token = tokenizer.current as StartTagToken;

    if (token.attributeSpans == null) return; // no attributes

    for (var attr in token.attributeSpans!) {
      final offset = sourceSpan!.start.offset;
      final name = attr.name!;
      attributeSpans[name] =
          sourceSpan!.file.span(offset + attr.start, offset + attr.end);
      if (attr.startValue != null) {
        attributeValueSpans[name] = sourceSpan!.file
            .span(offset + attr.startValue!, offset + attr.endValue);
      }
    }
  }

  T _clone<T extends Node>(T shallowClone, bool deep) {
    if (deep) {
      for (var child in nodes) {
        shallowClone.append(child.clone(true));
      }
    }
    return shallowClone;
  }
}

class Document extends Node
    with _ParentNode, _NonElementParentNode, _ElementAndDocument {
  Document() : super._();

  factory Document.html(String html) => parse(html);

  @override
  int get nodeType => Node.DOCUMENT_NODE;

  // TODO(jmesserly): optmize this if needed
  Element? get documentElement => querySelector('html');

  Element? get head => documentElement?.querySelector('head');

  Element? get body => documentElement?.querySelector('body');

  /// Returns a fragment of HTML or XML that represents the element and its
  /// contents.
  // TODO(jmesserly): this API is not specified in:
  // <http://domparsing.spec.whatwg.org/> nor is it in dart:html, instead
  // only Element has outerHtml. However it is quite useful. Should we move it
  // to dom_parsing, where we keep other custom APIs?
  String get outerHtml => _outerHtml;

  @override
  String toString() => '#document';

  @override
  void _addOuterHtml(StringBuffer str) => _addInnerHtml(str);

  @override
  Document clone(bool deep) => _clone(Document(), deep);

  Element createElement(String tag) => Element.tag(tag);

  // TODO(jmesserly): this is only a partial implementation of:
  // http://dom.spec.whatwg.org/#dom-document-createelementns
  Element createElementNS(String? namespaceUri, String? tag) {
    if (namespaceUri == '') namespaceUri = null;
    return Element._(tag, namespaceUri);
  }

  DocumentFragment createDocumentFragment() => DocumentFragment();
}

class DocumentFragment extends Node with _ParentNode, _NonElementParentNode {
  DocumentFragment() : super._();

  factory DocumentFragment.html(String html) => parseFragment(html);

  @override
  int get nodeType => Node.DOCUMENT_FRAGMENT_NODE;

  /// Returns a fragment of HTML or XML that represents the element and its
  /// contents.
  // TODO(jmesserly): this API is not specified in:
  // <http://domparsing.spec.whatwg.org/> nor is it in dart:html, instead
  // only Element has outerHtml. However it is quite useful. Should we move it
  // to dom_parsing, where we keep other custom APIs?
  String get outerHtml => _outerHtml;

  @override
  String toString() => '#document-fragment';

  @override
  DocumentFragment clone(bool deep) => _clone(DocumentFragment(), deep);

  @override
  void _addOuterHtml(StringBuffer str) => _addInnerHtml(str);

  @override
  String? get text => _getText(this);

  @override
  set text(String? value) => _setText(this, value);
}

class DocumentType extends Node {
  final String? name;
  final String? publicId;
  final String? systemId;

  DocumentType(this.name, this.publicId, this.systemId) : super._();

  @override
  int get nodeType => Node.DOCUMENT_TYPE_NODE;

  @override
  String toString() {
    if (publicId != null || systemId != null) {
      // TODO(jmesserly): the html5 serialization spec does not add these. But
      // it seems useful, and the parser can handle it, so for now keeping it.
      final pid = publicId ?? '';
      final sid = systemId ?? '';
      return '<!DOCTYPE $name "$pid" "$sid">';
    } else {
      return '<!DOCTYPE $name>';
    }
  }

  @override
  void _addOuterHtml(StringBuffer str) {
    str.write(toString());
  }

  @override
  DocumentType clone(bool deep) => DocumentType(name, publicId, systemId);
}

class Text extends Node {
  /// The text node's data, stored as either a String or StringBuffer.
  /// We support storing a StringBuffer here to support fast [appendData].
  /// It will flatten back to a String on read.
  Object _data;

  Text(String? data)
      : _data = data ?? '',
        super._();

  @override
  int get nodeType => Node.TEXT_NODE;

  String get data => _data = _data.toString();

  set data(String value) {
    // Handle unsound null values.
    _data = identical(value, null) ? '' : value;
  }

  @override
  String toString() => '"$data"';

  @override
  void _addOuterHtml(StringBuffer str) => writeTextNodeAsHtml(str, this);

  @override
  Text clone(bool deep) => Text(data);

  void appendData(String data) {
    if (_data is! StringBuffer) _data = StringBuffer(_data);
    final sb = _data as StringBuffer;
    sb.write(data);
  }

  @override
  String get text => data;

  @override
  // Text has a non-nullable `text` field, while Node has a nullable field.
  set text(covariant String value) {
    data = value;
  }
}

// TODO(jmesserly): Elements should have a pointer back to their document
class Element extends Node with _ParentNode, _ElementAndDocument {
  final String? namespaceUri;

  /// The [local name](http://dom.spec.whatwg.org/#concept-element-local-name)
  /// of this element.
  final String? localName;

  // TODO(jmesserly): consider using an Expando for this, and put it in
  // dom_parsing. Need to check the performance affect.
  /// The source span of the end tag this element, if it was created by the
  /// [HtmlParser]. May be `null` if does not have an implicit end tag.
  FileSpan? endSourceSpan;

  Element._(this.localName, [this.namespaceUri]) : super._();

  Element.tag(this.localName)
      : namespaceUri = Namespaces.html,
        super._();

  static final _startTagRegexp = RegExp('<(\\w+)');

  static final _customParentTagMap = const {
    'body': 'html',
    'head': 'html',
    'caption': 'table',
    'td': 'tr',
    'colgroup': 'table',
    'col': 'colgroup',
    'tr': 'tbody',
    'tbody': 'table',
    'tfoot': 'table',
    'thead': 'table',
    'track': 'audio',
  };

  // TODO(jmesserly): this is from dart:html _ElementFactoryProvider...
  // TODO(jmesserly): have a look at fixing some things in dart:html, in
  // particular: is the parent tag map complete? Is it faster without regexp?
  // TODO(jmesserly): for our version we can do something smarter in the parser.
  // All we really need is to set the correct parse state.
  factory Element.html(String html) {
    // TODO(jacobr): this method can be made more robust and performant.
    // 1) Cache the dummy parent elements required to use innerHTML rather than
    //    creating them every call.
    // 2) Verify that the html does not contain leading or trailing text nodes.
    // 3) Verify that the html does not contain both <head> and <body> tags.
    // 4) Detach the created element from its dummy parent.
    var parentTag = 'div';
    String? tag;
    final match = _startTagRegexp.firstMatch(html);
    if (match != null) {
      tag = match.group(1)!.toLowerCase();
      if (_customParentTagMap.containsKey(tag)) {
        parentTag = _customParentTagMap[tag]!;
      }
    }

    final fragment = parseFragment(html, container: parentTag);
    Element element;
    if (fragment.children.length == 1) {
      element = fragment.children[0];
    } else if (parentTag == 'html' && fragment.children.length == 2) {
      // You'll always get a head and a body when starting from html.
      element = fragment.children[tag == 'head' ? 0 : 1];
    } else {
      throw ArgumentError('HTML had ${fragment.children.length} '
          'top level elements but 1 expected');
    }
    element.remove();
    return element;
  }

  @override
  int get nodeType => Node.ELEMENT_NODE;

  // TODO(jmesserly): we can make this faster
  Element? get previousElementSibling {
    if (parentNode == null) return null;
    final siblings = parentNode!.nodes;
    for (var i = siblings.indexOf(this) - 1; i >= 0; i--) {
      final s = siblings[i];
      if (s is Element) return s;
    }
    return null;
  }

  Element? get nextElementSibling {
    final parentNode = this.parentNode;
    if (parentNode == null) return null;
    final siblings = parentNode.nodes;
    for (var i = siblings.indexOf(this) + 1; i < siblings.length; i++) {
      final s = siblings[i];
      if (s is Element) return s;
    }
    return null;
  }

  @override
  String toString() {
    final prefix = Namespaces.getPrefix(namespaceUri);
    return "<${prefix == null ? '' : '$prefix '}$localName>";
  }

  @override
  String get text => _getText(this);

  @override
  set text(String? value) => _setText(this, value);

  /// Returns a fragment of HTML or XML that represents the element and its
  /// contents.
  String get outerHtml => _outerHtml;

  /// Returns a fragment of HTML or XML that represents the element's contents.
  /// Can be set, to replace the contents of the element with nodes parsed from
  /// the given string.
  String get innerHtml => _innerHtml;

  // TODO(jmesserly): deprecate in favor of:
  // <https://api.dartlang.org/apidocs/channels/stable/#dart-dom-html.Element@id_setInnerHtml>
  set innerHtml(String value) {
    nodes.clear();
    // TODO(jmesserly): should be able to get the same effect by adding the
    // fragment directly.
    nodes.addAll(parseFragment(value, container: localName!).nodes);
  }

  @override
  void _addOuterHtml(StringBuffer str) {
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/the-end.html#serializing-html-fragments
    // Element is the most complicated one.
    str.write('<');
    str.write(_getSerializationPrefix(namespaceUri));
    str.write(localName);

    if (attributes.isNotEmpty) {
      attributes.forEach((key, v) {
        // Note: AttributeName.toString handles serialization of attribute
        // namespace, if needed.
        str.write(' ');
        str.write(key);
        str.write('="');
        str.write(htmlSerializeEscape(v, attributeMode: true));
        str.write('"');
      });
    }

    str.write('>');

    if (nodes.isNotEmpty) {
      if (localName == 'pre' ||
          localName == 'textarea' ||
          localName == 'listing') {
        final first = nodes[0];
        if (first is Text && first.data.startsWith('\n')) {
          // These nodes will remove a leading \n at parse time, so if we still
          // have one, it means we started with two. Add it back.
          str.write('\n');
        }
      }

      _addInnerHtml(str);
    }

    // void elements must not have an end tag
    // http://dev.w3.org/html5/markup/syntax.html#void-elements
    if (!isVoidElement(localName)) str.write('</$localName>');
  }

  static String _getSerializationPrefix(String? uri) {
    if (uri == null ||
        uri == Namespaces.html ||
        uri == Namespaces.mathml ||
        uri == Namespaces.svg) {
      return '';
    }
    final prefix = Namespaces.getPrefix(uri);
    // TODO(jmesserly): the spec doesn't define "qualified name".
    // I'm not sure if this is correct, but it should parse reasonably.
    return prefix == null ? '' : '$prefix:';
  }

  @override
  Element clone(bool deep) {
    final result = Element._(localName, namespaceUri)
      ..attributes = LinkedHashMap.from(attributes);
    return _clone(result, deep);
  }

  // http://dom.spec.whatwg.org/#dom-element-id
  String get id {
    final result = attributes['id'];
    return result ?? '';
  }

  set id(String value) {
    attributes['id'] = value;
  }

  // http://dom.spec.whatwg.org/#dom-element-classname
  String get className {
    final result = attributes['class'];
    return result ?? '';
  }

  set className(String value) {
    attributes['class'] = value;
  }

  /// The set of CSS classes applied to this element.
  ///
  /// This set makes it easy to add, remove or toggle the classes applied to
  /// this element.
  ///
  ///     element.classes.add('selected');
  ///     element.classes.toggle('isOnline');
  ///     element.classes.remove('selected');
  CssClassSet get classes => ElementCssClassSet(this);
}

class Comment extends Node {
  String? data;

  Comment(this.data) : super._();

  @override
  int get nodeType => Node.COMMENT_NODE;

  @override
  String toString() => '<!-- $data -->';

  @override
  void _addOuterHtml(StringBuffer str) {
    str.write('<!--$data-->');
  }

  @override
  Comment clone(bool deep) => Comment(data);

  @override
  String? get text => data;

  @override
  set text(String? value) {
    data = value;
  }
}

// TODO(jmesserly): fix this to extend one of the corelib classes if possible.
// (The requirement to remove the node from the old node list makes it tricky.)
// TODO(jmesserly): is there any way to share code with the _NodeListImpl?
class NodeList extends ListProxy<Node> {
  final Node _parent;

  NodeList._(this._parent);

  Node _setParent(Node node) {
    // Note: we need to remove the node from its previous parent node, if any,
    // before updating its parent pointer to point at our parent.
    node.remove();
    node.parentNode = _parent;
    return node;
  }

  @override
  void add(Node element) {
    if (element is DocumentFragment) {
      addAll(element.nodes);
    } else {
      super.add(_setParent(element));
    }
  }

  void addLast(Node value) => add(value);

  @override
  void addAll(Iterable<Node> iterable) {
    // Note: we need to be careful if collection is another NodeList.
    // In particular:
    //   1. we need to copy the items before updating their parent pointers,
    //     _flattenDocFragments does a copy internally.
    //   2. we should update parent pointers in reverse order. That way they
    //      are removed from the original NodeList (if any) from the end, which
    //      is faster.
    final list = _flattenDocFragments(iterable);
    for (var node in list.reversed) {
      _setParent(node);
    }
    super.addAll(list);
  }

  @override
  void insert(int index, Node element) {
    if (element is DocumentFragment) {
      insertAll(index, element.nodes);
    } else {
      super.insert(index, _setParent(element));
    }
  }

  @override
  Node removeLast() => super.removeLast()..parentNode = null;

  @override
  Node removeAt(int index) => super.removeAt(index)..parentNode = null;

  @override
  void clear() {
    for (var node in this) {
      node.parentNode = null;
    }
    super.clear();
  }

  @override
  void operator []=(int index, Node value) {
    if (value is DocumentFragment) {
      removeAt(index);
      insertAll(index, value.nodes);
    } else {
      this[index].parentNode = null;
      super[index] = _setParent(value);
    }
  }

  // TODO(jmesserly): These aren't implemented in DOM _NodeListImpl, see
  // http://code.google.com/p/dart/issues/detail?id=5371
  @override
  void setRange(int start, int end, Iterable<Node> iterable,
      [int skipCount = 0]) {
    var fromVar = iterable as List<Node>;
    if (fromVar is NodeList) {
      // Note: this is presumed to make a copy
      fromVar = fromVar.sublist(skipCount, skipCount + end);
    }
    // Note: see comment in [addAll]. We need to be careful about the order of
    // operations if [from] is also a NodeList.
    for (var i = end - 1; i >= 0; i--) {
      this[start + i] = fromVar[skipCount + i];
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<Node> newContents) {
    removeRange(start, end);
    insertAll(start, newContents);
  }

  @override
  void removeRange(int start, int end) {
    for (var i = start; i < end; i++) {
      this[i].parentNode = null;
    }
    super.removeRange(start, end);
  }

  @override
  void removeWhere(bool Function(Node) test) {
    for (var node in where(test)) {
      node.parentNode = null;
    }
    super.removeWhere(test);
  }

  @override
  void retainWhere(bool Function(Node) test) {
    for (var node in where((n) => !test(n))) {
      node.parentNode = null;
    }
    super.retainWhere(test);
  }

  @override
  void insertAll(int index, Iterable<Node> iterable) {
    // Note: we need to be careful how we copy nodes. See note in addAll.
    final list = _flattenDocFragments(iterable);
    for (var node in list.reversed) {
      _setParent(node);
    }
    super.insertAll(index, list);
  }

  List<Node> _flattenDocFragments(Iterable<Node> collection) {
    // Note: this function serves two purposes:
    //  * it flattens document fragments
    //  * it creates a copy of [collections] when `collection is NodeList`.
    final result = <Node>[];
    for (var node in collection) {
      if (node is DocumentFragment) {
        result.addAll(node.nodes);
      } else {
        result.add(node);
      }
    }
    return result;
  }
}

/// An indexable collection of a node's descendants in the document tree,
/// filtered so that only elements are in the collection.
// TODO(jmesserly): this was copied from dart:html
// TODO(jmesserly): "implements List<Element>" is a workaround for analyzer bug.
class FilteredElementList extends IterableBase<Element>
    with ListMixin<Element>
    implements List<Element> {
  final List<Node> _childNodes;

  /// Creates a collection of the elements that descend from a node.
  ///
  /// Example usage:
  ///
  ///     var filteredElements = new FilteredElementList(query("#container"));
  ///     // filteredElements is [a, b, c].
  FilteredElementList(Node node) : _childNodes = node.nodes;

  // We can't memoize this, since it's possible that children will be messed
  // with externally to this class.
  //
  // TODO(nweiz): we don't always need to create a new list. For example
  // forEach, every, any, ... could directly work on the _childNodes.
  List<Element> get _filtered =>
      _childNodes.whereType<Element>().toList(growable: false);

  @override
  void forEach(void Function(Element) action) {
    _filtered.forEach(action);
  }

  @override
  void operator []=(int index, Element value) {
    this[index].replaceWith(value);
  }

  @override
  set length(int newLength) {
    final len = length;
    if (newLength >= len) {
      return;
    } else if (newLength < 0) {
      throw ArgumentError('Invalid list length');
    }

    removeRange(newLength, len);
  }

  @override
  String join([String separator = '']) => _filtered.join(separator);

  @override
  void add(Element element) {
    _childNodes.add(element);
  }

  @override
  void addAll(Iterable<Element> iterable) {
    for (var element in iterable) {
      add(element);
    }
  }

  @override
  bool contains(Object? element) {
    return element is Element && _childNodes.contains(element);
  }

  @override
  Iterable<Element> get reversed => _filtered.reversed;

  @override
  void sort([int Function(Element, Element)? compare]) {
    throw UnsupportedError('TODO(jacobr): should we impl?');
  }

  @override
  void setRange(int start, int end, Iterable<Element> iterable,
      [int skipCount = 0]) {
    throw UnimplementedError();
  }

  @override
  void fillRange(int start, int end, [Element? fill]) {
    throw UnimplementedError();
  }

  @override
  void replaceRange(int start, int end, Iterable<Element> newContents) {
    throw UnimplementedError();
  }

  @override
  void removeRange(int start, int end) {
    _filtered.sublist(start, end).forEach((el) => el.remove());
  }

  @override
  void clear() {
    // Currently, ElementList#clear clears even non-element nodes, so we follow
    // that behavior.
    _childNodes.clear();
  }

  @override
  Element removeLast() {
    return last..remove();
  }

  @override
  Iterable<T> map<T>(T Function(Element) f) => _filtered.map(f);

  @override
  Iterable<Element> where(bool Function(Element) test) => _filtered.where(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(Element) f) => _filtered.expand(f);

  @override
  void insert(int index, Element element) {
    _childNodes.insert(index, element);
  }

  @override
  void insertAll(int index, Iterable<Element> iterable) {
    _childNodes.insertAll(index, iterable);
  }

  @override
  Element removeAt(int index) {
    final result = this[index];
    result.remove();
    return result;
  }

  @override
  bool remove(Object? element) {
    if (element is! Element) return false;
    for (var i = 0; i < length; i++) {
      final indexElement = this[i];
      if (identical(indexElement, element)) {
        indexElement.remove();
        return true;
      }
    }
    return false;
  }

  @override
  Element reduce(Element Function(Element, Element) combine) {
    return _filtered.reduce(combine);
  }

  @override
  T fold<T>(
      T initialValue, T Function(T previousValue, Element element) combine) {
    return _filtered.fold(initialValue, combine);
  }

  @override
  bool every(bool Function(Element) test) => _filtered.every(test);

  @override
  bool any(bool Function(Element) test) => _filtered.any(test);

  @override
  List<Element> toList({bool growable = true}) =>
      List<Element>.of(this, growable: growable);

  @override
  Set<Element> toSet() => Set<Element>.from(this);

  @override
  Element firstWhere(bool Function(Element) test,
      {Element Function()? orElse}) {
    return _filtered.firstWhere(test, orElse: orElse);
  }

  @override
  Element lastWhere(bool Function(Element) test, {Element Function()? orElse}) {
    return _filtered.lastWhere(test, orElse: orElse);
  }

  @override
  Element singleWhere(bool Function(Element) test,
      {Element Function()? orElse}) {
    if (orElse != null) throw UnimplementedError('orElse');
    return _filtered.singleWhere(test);
  }

  @override
  Element elementAt(int index) {
    return this[index];
  }

  @override
  bool get isEmpty => _filtered.isEmpty;

  @override
  int get length => _filtered.length;

  @override
  Element operator [](int index) => _filtered[index];

  @override
  Iterator<Element> get iterator => _filtered.iterator;

  @override
  List<Element> sublist(int start, [int? end]) => _filtered.sublist(start, end);

  @override
  Iterable<Element> getRange(int start, int end) =>
      _filtered.getRange(start, end);

  @override
  int indexOf(Object? element, [int start = 0]) =>
      // Cast forced by ListMixin https://github.com/dart-lang/sdk/issues/31311
      _filtered.indexOf(element as Element, start);

  @override
  int lastIndexOf(Object? element, [int? start]) {
    start ??= length - 1;
    // Cast forced by ListMixin https://github.com/dart-lang/sdk/issues/31311
    return _filtered.lastIndexOf(element as Element, start);
  }

  @override
  Element get first => _filtered.first;

  @override
  Element get last => _filtered.last;

  @override
  Element get single => _filtered.single;
}

// http://dom.spec.whatwg.org/#dom-node-textcontent
// For Element and DocumentFragment
String _getText(Node node) => (_ConcatTextVisitor()..visit(node)).toString();

void _setText(Node node, String? value) {
  node.nodes.clear();
  node.append(Text(value));
}

class _ConcatTextVisitor extends TreeVisitor {
  final _str = StringBuffer();

  @override
  String toString() => _str.toString();

  @override
  void visitText(Text node) {
    _str.write(node.data);
  }
}
