// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';

@JS('Selection')
@staticInterop
class Selection {}

extension SelectionExtension on Selection {
  external Range getRangeAt(int index);
  external void addRange(Range range);
  external void removeRange(Range range);
  external void removeAllRanges();
  external void empty();
  external JSArray getComposedRanges(ShadowRoot shadowRoots);
  external void collapse(
    Node? node, [
    int offset,
  ]);
  external void setPosition(
    Node? node, [
    int offset,
  ]);
  external void collapseToStart();
  external void collapseToEnd();
  external void extend(
    Node node, [
    int offset,
  ]);
  external void setBaseAndExtent(
    Node anchorNode,
    int anchorOffset,
    Node focusNode,
    int focusOffset,
  );
  external void selectAllChildren(Node node);
  external void modify([
    String alter,
    String direction,
    String granularity,
  ]);
  external void deleteFromDocument();
  external bool containsNode(
    Node node, [
    bool allowPartialContainment,
  ]);
  external Node? get anchorNode;
  external int get anchorOffset;
  external Node? get focusNode;
  external int get focusOffset;
  external bool get isCollapsed;
  external int get rangeCount;
  external String get type;
  external String get direction;
}
