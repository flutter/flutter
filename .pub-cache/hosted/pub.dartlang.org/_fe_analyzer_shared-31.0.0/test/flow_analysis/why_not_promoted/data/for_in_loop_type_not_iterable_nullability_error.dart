// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `ForInLoopTypeNotIterableNullability` or
// `ForInLoopTypeNotIterablePartNullability` errors, for which we wish to report
// "why not promoted" context information.

class C1 {
  List<int>? bad;
}

forStatement(C1 c) {
  if (c.bad == null) return;
  for (var x in c.
      /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad) {}
}

forElementInList(C1 c) {
  if (c.bad == null) return;
  [
    for (var x in c.
        /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad)
      null
  ];
}

forElementInSet(C1 c) {
  if (c.bad == null) return;
  <dynamic>{
    for (var x in c.
        /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad)
      null
  };
}

forElementInMap(C1 c) {
  if (c.bad == null) return;
  <dynamic, dynamic>{
    for (var x in c.
        /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad)
      null: null
  };
}

forElementInAmbiguousSet_resolvableDuringParsing(C1 c) {
  if (c.bad == null) return;
  ({
    for (var x in c.
        /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad)
      null
  });
}

forElementInAmbiguousMap_resolvableDuringParsing(C1 c) {
  if (c.bad == null) return;
  ({
    for (var x in c.
        /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad)
      null: null
  });
}

forElementInAmbiguousSet_notResolvableDuringParsing(C1 c, List list) {
  if (c.bad == null) return;
  ({
    for (var x in c.
        /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad)
      ...list
  });
}

forElementInAmbiguousMap_notResolvableDuringParsing(C1 c, Map map) {
  if (c.bad == null) return;
  ({
    for (var x in c.
        /*notPromoted(propertyNotPromoted(target: member:C1.bad, type: List<int>?))*/ bad)
      ...map
  });
}
