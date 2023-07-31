// Copyright 2015 Google. All rights reserved. Use of this source code is
// governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import '../webkit_inspection_protocol.dart';

/// Implementation of the
/// https://developer.chrome.com/devtools/docs/protocol/1.1/dom
class WipDom extends WipDomain {
  WipDom(WipConnection connection) : super(connection);

  Future<Map<String, String>> getAttributes(int nodeId) async {
    WipResponse resp =
        await sendCommand('DOM.getAttributes', params: {'nodeId': nodeId});
    return _attributeListToMap((resp.result!['attributes'] as List).cast());
  }

  Future<Node> getDocument() async =>
      Node((await sendCommand('DOM.getDocument')).result!['root']
          as Map<String, dynamic>);

  Future<String> getOuterHtml(int nodeId) async =>
      (await sendCommand('DOM.getOuterHTML', params: {'nodeId': nodeId}))
          .result!['root'] as String;

  Future<void> hideHighlight() => sendCommand('DOM.hideHighlight');

  Future<void> highlightNode(
    int nodeId, {
    Rgba? borderColor,
    Rgba? contentColor,
    Rgba? marginColor,
    Rgba? paddingColor,
    bool? showInfo,
  }) {
    var params = <String, dynamic>{
      'nodeId': nodeId,
      'highlightConfig': <String, dynamic>{
        if (borderColor != null) 'borderColor': borderColor,
        if (contentColor != null) 'contentColor': contentColor,
        if (marginColor != null) 'marginColor': marginColor,
        if (paddingColor != null) 'paddingColor': paddingColor,
        if (showInfo != null) 'showInfo': showInfo,
      },
    };

    return sendCommand('DOM.highlightNode', params: params);
  }

  Future<void> highlightRect(int x, int y, int width, int height,
      {Rgba? color, Rgba? outlineColor}) {
    var params = <String, dynamic>{
      'x': x,
      'y': y,
      'width': width,
      'height': height
    };

    if (color != null) {
      params['color'] = color;
    }

    if (outlineColor != null) {
      params['outlineColor'] = outlineColor;
    }

    return sendCommand('DOM.highlightRect', params: params);
  }

  Future<int> moveTo(int nodeId, int targetNodeId,
      {int? insertBeforeNodeId}) async {
    var params = {'nodeId': nodeId, 'targetNodeId': targetNodeId};

    if (insertBeforeNodeId != null) {
      params['insertBeforeNodeId'] = insertBeforeNodeId;
    }

    var resp = await sendCommand('DOM.moveTo', params: params);
    return resp.result!['nodeId'] as int;
  }

  Future<int> querySelector(int nodeId, String selector) async {
    var resp = await sendCommand('DOM.querySelector',
        params: {'nodeId': nodeId, 'selector': selector});
    return resp.result!['nodeId'] as int;
  }

  Future<List<int>> querySelectorAll(int nodeId, String selector) async {
    var resp = await sendCommand('DOM.querySelectorAll',
        params: {'nodeId': nodeId, 'selector': selector});
    return (resp.result!['nodeIds'] as List).cast();
  }

  Future<void> removeAttribute(int nodeId, String name) =>
      sendCommand('DOM.removeAttribute',
          params: {'nodeId': nodeId, 'name': name});

  Future<void> removeNode(int nodeId) =>
      sendCommand('DOM.removeNode', params: {'nodeId': nodeId});

  Future<void> requestChildNodes(int nodeId) =>
      sendCommand('DOM.requestChildNodes', params: {'nodeId': nodeId});

  Future<int> requestNode(String objectId) async {
    var resp =
        await sendCommand('DOM.requestNode', params: {'objectId': objectId});
    return resp.result!['nodeId'] as int;
  }

  Future<RemoteObject> resolveNode(int nodeId, {String? objectGroup}) async {
    var params = <String, dynamic>{'nodeId': nodeId};
    if (objectGroup != null) {
      params['objectGroup'] = objectGroup;
    }

    var resp = await sendCommand('DOM.resolveNode', params: params);
    return RemoteObject(resp.result!['object'] as Map<String, dynamic>);
  }

  Future<void> setAttributeValue(int nodeId, String name, String value) =>
      sendCommand('DOM.setAttributeValue',
          params: {'nodeId': nodeId, 'name': name, 'value': value});

  Future<void> setAttributesAsText(int nodeId, String text, {String? name}) {
    var params = {'nodeId': nodeId, 'text': text};
    if (name != null) {
      params['name'] = name;
    }
    return sendCommand('DOM.setAttributeValue', params: params);
  }

  Future<int> setNodeName(int nodeId, String name) async {
    var resp = await sendCommand('DOM.setNodeName',
        params: {'nodeId': nodeId, 'name': name});
    return resp.result!['nodeId'] as int;
  }

  Future<void> setNodeValue(int nodeId, String value) =>
      sendCommand('DOM.setNodeValue',
          params: {'nodeId': nodeId, 'value': value});

  Future<void> setOuterHtml(int nodeId, String outerHtml) =>
      sendCommand('DOM.setOuterHTML',
          params: {'nodeId': nodeId, 'outerHtml': outerHtml});

  Stream<AttributeModifiedEvent> get onAttributeModified => eventStream(
      'DOM.attributeModified',
      (WipEvent event) => AttributeModifiedEvent(event.json));

  Stream<AttributeRemovedEvent> get onAttributeRemoved => eventStream(
      'DOM.attributeRemoved',
      (WipEvent event) => AttributeRemovedEvent(event.json));

  Stream<CharacterDataModifiedEvent> get onCharacterDataModified => eventStream(
      'DOM.characterDataModified',
      (WipEvent event) => CharacterDataModifiedEvent(event.json));

  Stream<ChildNodeCountUpdatedEvent> get onChildNodeCountUpdated => eventStream(
      'DOM.childNodeCountUpdated',
      (WipEvent event) => ChildNodeCountUpdatedEvent(event.json));

  Stream<ChildNodeInsertedEvent> get onChildNodeInserted => eventStream(
      'DOM.childNodeInserted',
      (WipEvent event) => ChildNodeInsertedEvent(event.json));

  Stream<ChildNodeRemovedEvent> get onChildNodeRemoved => eventStream(
      'DOM.childNodeRemoved',
      (WipEvent event) => ChildNodeRemovedEvent(event.json));

  Stream<DocumentUpdatedEvent> get onDocumentUpdated => eventStream(
      'DOM.documentUpdated',
      (WipEvent event) => DocumentUpdatedEvent(event.json));

  Stream<SetChildNodesEvent> get onSetChildNodes => eventStream(
      'DOM.setChildNodes', (WipEvent event) => SetChildNodesEvent(event.json));
}

class AttributeModifiedEvent extends WipEvent {
  AttributeModifiedEvent(Map<String, dynamic> json) : super(json);

  int get nodeId => params!['nodeId'] as int;

  String get name => params!['name'] as String;

  String get value => params!['value'] as String;
}

class AttributeRemovedEvent extends WipEvent {
  AttributeRemovedEvent(Map<String, dynamic> json) : super(json);

  int get nodeId => params!['nodeId'] as int;

  String get name => params!['name'] as String;
}

class CharacterDataModifiedEvent extends WipEvent {
  CharacterDataModifiedEvent(Map<String, dynamic> json) : super(json);

  int get nodeId => params!['nodeId'] as int;

  String get characterData => params!['characterData'] as String;
}

class ChildNodeCountUpdatedEvent extends WipEvent {
  ChildNodeCountUpdatedEvent(Map<String, dynamic> json) : super(json);

  int get nodeId => params!['nodeId'] as int;

  int get childNodeCount => params!['childNodeCount'] as int;
}

class ChildNodeInsertedEvent extends WipEvent {
  ChildNodeInsertedEvent(Map<String, dynamic> json) : super(json);

  int get parentNodeId => params!['parentNodeId'] as int;

  int get previousNodeId => params!['previousNodeId'] as int;

  late final node = Node(params!['node'] as Map<String, dynamic>);
}

class ChildNodeRemovedEvent extends WipEvent {
  ChildNodeRemovedEvent(Map<String, dynamic> json) : super(json);

  int get parentNodeId => params!['parentNodeId'] as int;

  int get nodeId => params!['nodeId'] as int;
}

class DocumentUpdatedEvent extends WipEvent {
  DocumentUpdatedEvent(Map<String, dynamic> json) : super(json);
}

class SetChildNodesEvent extends WipEvent {
  SetChildNodesEvent(Map<String, dynamic> json) : super(json);

  int get nodeId => params!['parentId'] as int;

  Iterable<Node> get nodes sync* {
    for (Map node in params!['nodes']) {
      yield Node(node as Map<String, dynamic>);
    }
  }

  @override
  String toString() => 'SetChildNodes $nodeId: $nodes';
}

/// The backend keeps track of which DOM nodes have been sent,
/// will only send each node once, and will only send events
/// for nodes that have been sent.
class Node {
  final Map<String, dynamic> _map;

  Node(this._map);

  late final Map<String, String>? attributes = _map.containsKey('attributes')
      ? _attributeListToMap((_map['attributes'] as List).cast())
      : null;

  int? get childNodeCount => _map['childNodeCount'] as int?;

  late final List<Node>? children = _map.containsKey('children')
      ? UnmodifiableListView((_map['children'] as List)
          .map((c) => Node(c as Map<String, dynamic>)))
      : null;

  Node? get contentDocument {
    if (_map.containsKey('contentDocument')) {
      return Node(_map['contentDocument'] as Map<String, dynamic>);
    }
    return null;
  }

  String? get documentUrl => _map['documentURL'] as String?;

  String? get internalSubset => _map['internalSubset'] as String?;

  String get localName => _map['localName'] as String;

  String? get name => _map['name'] as String?;

  int get nodeId => _map['nodeId'] as int;

  String get nodeName => _map['nodeName'] as String;

  int get nodeType => _map['nodeType'] as int;

  String get nodeValue => _map['nodeValue'] as String;

  String? get publicId => _map['publicId'] as String?;

  String? get systemId => _map['systemId'] as String?;

  String? get value => _map['value'] as String?;

  String? get xmlVersion => _map['xmlVersion'] as String?;

  @override
  String toString() => '$nodeName: $nodeId $attributes';
}

class Rgba {
  final int? a;
  final int b;
  final int r;
  final int g;

  Rgba(this.r, this.g, this.b, [this.a]);

  Map<String, int> toJson() {
    var json = {'r': r, 'g': g, 'b': b};
    if (a != null) {
      json['a'] = a!;
    }
    return json;
  }
}

Map<String, String> _attributeListToMap(List<String> attrList) {
  var attributes = <String, String>{};
  for (int i = 0; i < attrList.length; i += 2) {
    attributes[attrList[i]] = attrList[i + 1];
  }
  return UnmodifiableMapView(attributes);
}
