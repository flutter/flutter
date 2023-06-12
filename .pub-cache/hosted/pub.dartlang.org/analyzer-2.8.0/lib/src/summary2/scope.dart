// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/reference.dart';

class Scope {
  final Scope? parent;
  final Map<String, Reference> map;

  Scope(this.parent, this.map);

  Scope.top() : this(null, <String, Reference>{});

  void declare(String name, Reference reference) {
    map[name] = reference;
  }

  void forEach(void Function(String name, Reference reference) f) {
    map.forEach(f);
  }

  Reference? lookup(String name) {
    var reference = map[name];
    if (reference != null) return reference;

    return parent?.lookup(name);
  }
}
