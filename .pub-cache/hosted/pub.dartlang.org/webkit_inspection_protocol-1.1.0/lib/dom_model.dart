// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

library wip.dom_model;

import 'dart:async' show EventSink, Future, Stream, StreamTransformer;
import 'dart:collection' show UnmodifiableListView, UnmodifiableMapView;
import 'dart:mirrors' show reflect;

import 'package:logging/logging.dart' show Logger;

import 'webkit_inspection_protocol.dart'
    show
        AttributeModifiedEvent,
        AttributeRemovedEvent,
        CharacterDataModifiedEvent,
        ChildNodeCountUpdatedEvent,
        ChildNodeInsertedEvent,
        ChildNodeRemovedEvent,
        DocumentUpdatedEvent,
        Node,
        SetChildNodesEvent,
        WipDom,
        WipEvent;

/// Implementation of WipDom that maintains and updates a model of the DOM
/// based on incoming events.
class WipDomModel implements WipDom {
  static final _log = Logger('WipDomModel');

  final WipDom _dom;

  final Map<int, _Node> _nodeCache = {};
  Future<_Node>? _root;

  @override
  late final Stream<AttributeModifiedEvent> onAttributeModified =
      StreamTransformer.fromHandlers(handleData: _onAttributeModified)
          .bind(_dom.onAttributeModified);
  @override
  late final Stream<AttributeRemovedEvent> onAttributeRemoved =
      StreamTransformer.fromHandlers(handleData: _onAttributeRemoved)
          .bind(_dom.onAttributeRemoved);
  @override
  late final Stream<CharacterDataModifiedEvent> onCharacterDataModified =
      StreamTransformer.fromHandlers(handleData: _onCharacterDataModified)
          .bind(_dom.onCharacterDataModified);
  @override
  late final Stream<ChildNodeCountUpdatedEvent> onChildNodeCountUpdated =
      StreamTransformer.fromHandlers(handleData: _onChildNodeCountUpdated)
          .bind(_dom.onChildNodeCountUpdated);
  @override
  late final Stream<ChildNodeInsertedEvent> onChildNodeInserted =
      StreamTransformer.fromHandlers(handleData: _onChildNodeInserted)
          .bind(_dom.onChildNodeInserted);
  @override
  late final Stream<ChildNodeRemovedEvent> onChildNodeRemoved =
      StreamTransformer.fromHandlers(handleData: _onChildNodeRemoved)
          .bind(_dom.onChildNodeRemoved);
  @override
  late final Stream<DocumentUpdatedEvent> onDocumentUpdated =
      StreamTransformer.fromHandlers(handleData: _onDocumentUpdated)
          .bind(_dom.onDocumentUpdated);
  @override
  late final Stream<SetChildNodesEvent> onSetChildNodes =
      StreamTransformer.fromHandlers(handleData: _onSetChildNodes)
          .bind(_dom.onSetChildNodes);

  WipDomModel(this._dom) {
    onAttributeModified.listen(_logEvent);
    onAttributeRemoved.listen(_logEvent);
    onCharacterDataModified.listen(_logEvent);
    onChildNodeCountUpdated.listen(_logEvent);
    onChildNodeInserted.listen(_logEvent);
    onChildNodeRemoved.listen(_logEvent);
    onDocumentUpdated.listen(_logEvent);
    onSetChildNodes.listen(_logEvent);
  }

  void _logEvent(WipEvent event) {
    _log.finest('Event $event');
  }

  void _onAttributeModified(
      AttributeModifiedEvent event, EventSink<AttributeModifiedEvent> sink) {
    var node = _getOrCreateNode(event.nodeId);
    node._attributes![event.name] = event.value;
    sink.add(event);
  }

  void _onAttributeRemoved(
      AttributeRemovedEvent event, EventSink<AttributeRemovedEvent> sink) {
    var node = _getOrCreateNode(event.nodeId);
    node._attributes!.remove(event.name);
    sink.add(event);
  }

  void _onCharacterDataModified(CharacterDataModifiedEvent event,
      EventSink<CharacterDataModifiedEvent> sink) {
    var node = _getOrCreateNode(event.nodeId);
    node._nodeValue = event.characterData;
    sink.add(event);
  }

  void _onChildNodeCountUpdated(ChildNodeCountUpdatedEvent event,
      EventSink<ChildNodeCountUpdatedEvent> sink) {
    var node = _getOrCreateNode(event.nodeId);
    node._childNodeCount = event.childNodeCount;
    sink.add(event);
  }

  void _onChildNodeInserted(
      ChildNodeInsertedEvent event, EventSink<ChildNodeInsertedEvent> sink) {
    var parent = _getOrCreateNode(event.parentNodeId);
    int index =
        parent._children!.indexOf(_getOrCreateNode(event.previousNodeId)) + 1;
    var node = _getOrCreateNodeFromNode(event.node);
    parent._children!.insert(index, node);
    parent._childNodeCount = parent._children!.length;
    sink.add(event);
  }

  void _onChildNodeRemoved(
      ChildNodeRemovedEvent event, EventSink<ChildNodeRemovedEvent> sink) {
    var parent = _getOrCreateNode(event.parentNodeId);
    var node = _nodeCache.remove(event.nodeId);
    parent._children!.remove(node);
    parent._childNodeCount = parent._children!.length;
    sink.add(event);
  }

  void _onDocumentUpdated(
      DocumentUpdatedEvent event, EventSink<DocumentUpdatedEvent> sink) {
    _nodeCache.clear();
    _root = null;
    sink.add(event);
  }

  void _onSetChildNodes(
      SetChildNodesEvent event, EventSink<SetChildNodesEvent> sink) {
    var parent = _getOrCreateNode(event.nodeId);
    parent._children =
        event.nodes.map(_getOrCreateNodeFromNode).toList(growable: true);
    parent._childNodeCount = parent._children!.length;
    sink.add(event);
  }

  @override
  Future<Map<String, String>> getAttributes(int nodeId) async {
    Map<String, String> attributes = await _dom.getAttributes(nodeId);
    var node = _getOrCreateNode(nodeId);
    node._attributes = Map.from(attributes);
    return attributes;
  }

  /// Unlike the standard [WipDom.getDocument] call, this will not
  /// reset the internal state of the debugger remote end when called
  /// multiple times on the same page.
  @override
  Future<Node> getDocument() {
    _root ??= _dom.getDocument().then((n) => _getOrCreateNodeFromNode(n));
    return _root!;
  }

  _Node _getOrCreateNode(int nodeId) =>
      _nodeCache.putIfAbsent(nodeId, () => _Node(nodeId));

  _Node _getOrCreateNodeFromNode(Node src) {
    try {
      var node = _getOrCreateNode(src.nodeId);
      if (src.attributes != null) {
        node._attributes = Map.of(src.attributes!);
      }
      if (src.children != null) {
        node._children =
            src.children!.map(_getOrCreateNodeFromNode).toList(growable: true);
      }
      node._childNodeCount = src.childNodeCount ?? 0;
      if (src.contentDocument != null) {
        node._contentDocument = _getOrCreateNodeFromNode(src.contentDocument!);
      }
      node._documentUrl = src.documentUrl;
      node._internalSubset = src.internalSubset;
      node._localName = src.localName;
      node._name = src.name;
      node._nodeName = src.nodeName;
      node._nodeType = src.nodeType;
      node._nodeValue = src.nodeValue;
      node._publicId = src.publicId;
      node._systemId = src.systemId;
      node._value = src.value;
      node._xmlVersion = src.xmlVersion;
      return node;
    } catch (e, s) {
      _log.severe('Error parsing: $src.nodeId', e, s);
      rethrow;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      reflect(_dom).delegate(invocation);
}

class _Node implements Node {
  Map<String, String>? _attributes;

  @override
  Map<String, String>? get attributes =>
      _attributes != null ? UnmodifiableMapView(_attributes!) : null;

  int? _childNodeCount;

  @override
  int? get childNodeCount => _childNodeCount;

  List<_Node>? _children;

  @override
  List<Node>? get children =>
      _children != null ? UnmodifiableListView(_children!) : null;

  _Node? _contentDocument;

  @override
  Node? get contentDocument => _contentDocument;

  String? _documentUrl;

  @override
  String? get documentUrl => _documentUrl;

  String? _internalSubset;

  @override
  String? get internalSubset => _internalSubset;

  String? _localName;

  @override
  String get localName => _localName!;

  String? _name;

  @override
  String? get name => _name;

  @override
  final int nodeId;

  String? _nodeName;

  @override
  String get nodeName => _nodeName!;

  int? _nodeType;

  @override
  int get nodeType => _nodeType!;

  String? _nodeValue;

  @override
  String get nodeValue => _nodeValue!;

  String? _publicId;

  @override
  String? get publicId => _publicId;

  String? _systemId;

  @override
  String? get systemId => _systemId;

  String? _value;

  @override
  String? get value => _value;

  String? _xmlVersion;

  @override
  String? get xmlVersion => _xmlVersion;

  _Node(this.nodeId);

  Map toJson() => _toJsonInternal({});

  Map _toJsonInternal(Set visited) {
    var map = {
      'localName': localName,
      'nodeId': nodeId,
      'nodeName': nodeName,
      'nodeType': nodeType,
      'nodeValue': nodeValue
    };
    if (visited.add(nodeId)) {
      if (attributes != null && attributes!.isNotEmpty) {
        map['attributes'] = flattenAttributesMap(attributes!);
      }
      if (childNodeCount != null) {
        map['childNodeCount'] = childNodeCount!;
      }
      if (_children != null && _children!.isNotEmpty) {
        var newChildren = [];
        for (var child in _children!) {
          newChildren.add(child._toJsonInternal(visited));
        }
        map['children'] = newChildren;
      }
      if (_contentDocument != null) {
        map['contentDocument'] = _contentDocument!._toJsonInternal(visited);
      }
      if (documentUrl != null) {
        map['documentUrl'] = documentUrl!;
      }
      if (internalSubset != null) {
        map['internalSubset'] = internalSubset!;
      }
      if (name != null) {
        map['name'] = name!;
      }
      if (publicId != null) {
        map['publicId'] = publicId!;
      }
      if (systemId != null) {
        map['systemId'] = systemId!;
      }
      if (value != null) {
        map['value'] = value!;
      }
      if (xmlVersion != null) {
        map['xmlVersion'] = xmlVersion!;
      }
    }
    return map;
  }
}

List<String> flattenAttributesMap(Map<String, String> attributes) {
  var result = <String>[];
  attributes.forEach((k, v) {
    result
      ..add(k)
      ..add(v);
  });
  return result;
}
