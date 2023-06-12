// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Combinator {
  final bool isShow;
  final Set<String> names;

  Combinator(this.isShow, this.names);

  Combinator.hide(Iterable<String> names) : this(false, names.toSet());

  Combinator.show(Iterable<String> names) : this(true, names.toSet());

  bool get isHide => !isShow;

  bool matches(String name) {
    if (name.endsWith('=')) {
      name = name.substring(0, name.length - 1);
    }
    return names.contains(name);
  }
}
