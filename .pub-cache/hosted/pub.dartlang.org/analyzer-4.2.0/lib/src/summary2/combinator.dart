// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

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

extension CombinatorListExtension on List<Combinator> {
  /// Return `true` if this list of combinators allows the [name].
  bool allows(String name) {
    for (final combinator in this) {
      if (combinator.isShow && !combinator.matches(name)) return false;
      if (combinator.isHide && combinator.matches(name)) return false;
    }
    return true;
  }
}

extension NamespaceCombinatorListExtension on List<NamespaceCombinator> {
  List<Combinator> build() {
    return map((combinator) {
      if (combinator is ShowElementCombinator) {
        return Combinator.show(combinator.shownNames);
      } else if (combinator is HideElementCombinator) {
        return Combinator.hide(combinator.hiddenNames);
      } else {
        throw UnimplementedError();
      }
    }).toList();
  }
}
