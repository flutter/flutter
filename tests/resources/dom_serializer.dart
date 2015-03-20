// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import "dart:sky";

final kEntityMap = new Map.fromIterable([
  ['\u00a0', '&nbsp;'],
  ['&', '&amp;'],
  ['<', '&lt;'],
  ['>', '&gt;'],
  ['"', '&quot;'],
], key: (item) => item[0], value: (item) => item[1]);

final RegExp kTextEscapePattern = new RegExp(r'&|<|>|"|\u00a0');
final RegExp kAttributeEscapePattern = new RegExp(r'&|>|"|\u00a0');
const kIndent = '  ';

String escapeText(String value, RegExp pattern) {
  if (value == null)
    value = '';
  return value.replaceAllMapped(pattern, (Match match) {
    return kEntityMap[match[0]];
  });
}

String serializeAttributes(Element element) {
  String buffer = '';
  var attributes = element.getAttributes();

  for (var i = 0; i < attributes.length; ++i) {
    var attribute = attributes[i];
    buffer += ' ';
    buffer += attribute.name;
    buffer += '="';
    buffer += escapeText(attribute.value, kAttributeEscapePattern);
    buffer += '"';
  }

  return buffer;
}

Node getFirstChild(ParentNode node) {
  if (node is HTMLTemplateElement)
    return node.content.firstChild;
  return node.firstChild;
}

Node getLastChild(ParentNode node) {
  if (node is HTMLTemplateElement)
    return node.content.lastChild;
  return node.lastChild;
}

String serializeChildren(ParentNode node, int depth) {
  String buffer = '';
  Node firstChild = getFirstChild(node);
  Node lastChild = getLastChild(node);
  if (firstChild is Element && depth != 0)
    buffer += '\n' + (kIndent * depth);
  for (Node child = firstChild; child != null; child = child.nextSibling) {
    buffer += serializeNode(child, depth);
    if (child is Element && child.nextSibling is Element)
      buffer += '\n' + (kIndent * depth);
  }
  if (lastChild is Element) {
    buffer += '\n';
    if (depth != 0)
      buffer += kIndent * (depth - 1);
  }
  return buffer;
}

String serializeElement(Element element, int depth) {
  String buffer = '<' + element.tagName + serializeAttributes(element) + '>';
  buffer += serializeChildren(element, depth + 1);
  buffer += '</' + element.tagName + '>';
  return buffer;
}

String serializeText(Text node) {
  Node parent = node.parentNode;
  if (parent != null && (parent is HTMLScriptElement || parent is HTMLStyleElement))
    return node.data;
  return escapeText(node.data, kTextEscapePattern);
}

String serializeNode(Node node, [int depth = 0]) {
  if (node is Text)
    return serializeText(node);
  if (node is Element)
    return serializeElement(node, depth);
  if (node is Document || node is ShadowRoot)
    return serializeChildren(node, depth);
  throw new Exception('Cannot serialize node');
}
