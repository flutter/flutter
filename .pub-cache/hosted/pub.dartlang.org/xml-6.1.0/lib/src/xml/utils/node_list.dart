import 'package:collection/collection.dart' show DelegatingList;
import 'package:meta/meta.dart';

import '../enums/node_type.dart';
import '../exceptions/parent_exception.dart';
import '../exceptions/type_exception.dart';
import '../nodes/node.dart';

/// Mutable list of XmlNodes, manages the parenting of the nodes.
class XmlNodeList<E extends XmlNode> extends DelegatingList<E> {
  XmlNodeList() : super(<E>[]);

  late final XmlNode _parent;
  late final Set<XmlNodeType> _nodeTypes;

  /// Internal initializer of the node list with parent and supported
  /// node types.
  @internal
  void initialize(XmlNode parent, Set<XmlNodeType> nodeTypes) {
    _parent = parent;
    _nodeTypes = nodeTypes;
  }

  @override
  void operator []=(int index, E value) {
    RangeError.checkValidIndex(index, this);
    if (value.nodeType == XmlNodeType.DOCUMENT_FRAGMENT) {
      replaceRange(index, index + 1, _expandFragment(value));
    } else {
      XmlNodeTypeException.checkValidType(value, _nodeTypes);
      XmlParentException.checkNoParent(value);
      this[index].detachParent(_parent);
      super[index] = value;
      value.attachParent(_parent);
    }
  }

  @override
  set length(int length) =>
      throw UnsupportedError('Unsupported length change of node list.');

  @override
  void add(E value) {
    if (value.nodeType == XmlNodeType.DOCUMENT_FRAGMENT) {
      addAll(_expandFragment(value));
    } else {
      XmlNodeTypeException.checkValidType(value, _nodeTypes);
      XmlParentException.checkNoParent(value);
      super.add(value);
      value.attachParent(_parent);
    }
  }

  @override
  void addAll(Iterable<E> iterable) {
    final expanded = _expandNodes(iterable);
    super.addAll(expanded);
    for (final node in expanded) {
      node.attachParent(_parent);
    }
  }

  @override
  bool remove(Object? value) {
    final removed = super.remove(value);
    if (removed && value is E) {
      value.detachParent(_parent);
    }
    return removed;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    super.removeWhere((node) {
      final remove = test(node);
      if (remove) {
        node.detachParent(_parent);
      }
      return remove;
    });
  }

  @override
  void retainWhere(bool Function(E node) test) {
    super.retainWhere((node) {
      final retain = test(node);
      if (!retain) {
        node.detachParent(_parent);
      }
      return retain;
    });
  }

  @override
  void clear() {
    for (final node in this) {
      node.detachParent(_parent);
    }
    super.clear();
  }

  @override
  E removeLast() {
    final node = super.removeLast();
    node.detachParent(_parent);
    return node;
  }

  @override
  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    for (var i = start; i < end; i++) {
      this[i].detachParent(_parent);
    }
    super.removeRange(start, end);
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) =>
      throw UnsupportedError('Unsupported range filling of node list.');

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);
    final expanded = _expandNodes(iterable);
    for (var i = start; i < end; i++) {
      this[i].detachParent(_parent);
    }
    super.setRange(start, end, expanded, skipCount);
    for (var i = start; i < end; i++) {
      this[i].attachParent(_parent);
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<E> iterable) {
    RangeError.checkValidRange(start, end, length);
    final expanded = _expandNodes(iterable);
    for (var i = start; i < end; i++) {
      this[i].detachParent(_parent);
    }
    super.replaceRange(start, end, expanded);
    for (final node in expanded) {
      node.attachParent(_parent);
    }
  }

  @override
  void setAll(int index, Iterable<E> iterable) => throw UnimplementedError();

  @override
  void insert(int index, E element) {
    if (element.nodeType == XmlNodeType.DOCUMENT_FRAGMENT) {
      insertAll(index, _expandFragment(element));
    } else {
      XmlNodeTypeException.checkValidType(element, _nodeTypes);
      XmlParentException.checkNoParent(element);
      super.insert(index, element);
      element.attachParent(_parent);
    }
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    final expanded = _expandNodes(iterable);
    super.insertAll(index, expanded);
    for (final node in expanded) {
      node.attachParent(_parent);
    }
  }

  @override
  E removeAt(int index) {
    RangeError.checkValidIndex(index, this);
    this[index].detachParent(_parent);
    return super.removeAt(index);
  }

  Iterable<E> _expandFragment(E fragment) => fragment.children.map((node) {
        XmlNodeTypeException.checkValidType(node, _nodeTypes);
        return node.copy() as E;
      });

  Iterable<E> _expandNodes(Iterable<E> iterable) {
    final expanded = <E>[];
    for (final node in iterable) {
      if (node.nodeType == XmlNodeType.DOCUMENT_FRAGMENT) {
        expanded.addAll(_expandFragment(node));
      } else {
        XmlNodeTypeException.checkValidType(node, _nodeTypes);
        XmlParentException.checkNoParent(node);
        expanded.add(node);
      }
    }
    return expanded;
  }
}
