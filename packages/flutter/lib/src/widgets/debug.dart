// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'framework.dart';
import 'media_query.dart';

bool debugCheckHasMediaQuery(BuildContext context) {
  assert(() {
    if (MediaQuery.of(context) == null) {
      Element element = context;
      throw new FlutterError(
        'No MediaQuery widget found.\n'
        '${element.widget.runtimeType} widgets require a MediaQuery widget ancestor.\n'
        'The specific widget that could not find a MediaQuery ancestor was:\n'
        '  ${element.widget}'
        'The ownership chain for the affected widget is:\n'
        '  ${element.debugGetOwnershipChain(10)}'
      );
    }
    return true;
  });
  return true;
}

bool debugHasDuplicateKeys(Widget parent, Iterable<Widget> children) {
  assert(() {
    Set<Key> keySet = new HashSet<Key>();
    for (Widget child in children) {
      assert(child != null);
      if (child.key == null)
        continue;
      if (!keySet.add(child.key)) {
        throw new FlutterError(
          'Duplicate keys found.\n'
          'If multiple keyed nodes exist as children of another node, they must have unique keys.\n'
          '$parent has multiple children with key "${child.key}".'
        );
      }
    }
    return true;
  });
  return false;
}
