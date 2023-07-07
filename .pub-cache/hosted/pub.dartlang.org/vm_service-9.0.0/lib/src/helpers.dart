// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../vm_service.dart';

class IsolateHelper {
  static List<TagCounter> getTagCounters(Isolate isolate) {
    Map m = isolate.json!['_tagCounters']!;
    List<String> names = m['names'];
    List<int> counters = m['counters'];

    List<TagCounter> result = [];
    for (int i = 0; i < counters.length; i++) {
      result.add(TagCounter(names[i], counters[i]));
    }
    return result;
  }
}

class TagCounter {
  final String name;
  final int count;

  TagCounter(this.name, this.count);
}
