// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';

extension LibraryElementExtension on LibraryElement {
  /// Locates an [Element] in this library by its [ElementLocation].
  ///
  /// It is assumed that the first component of [location] matches this library.
  ///
  /// Local elements such as variables inside functions cannot be found using
  /// this method.
  Element? locateElement(ElementLocation location) =>
      _locateElement(location, 0);
}

extension _ElementExtension on Element {
  /// Locates an [Element] by its [ElementLocation] assuming this element
  /// is a match up to [thisIndex].
  Element? _locateElement(ElementLocation location, int thisIndex) {
    final components = location.components;
    // TODO(paulberry): once the analyzer's pubspec specifies a minimum SDK
    // version that supports [IndexError.check], switch to using that instead.
    RangeError.checkValidIndex(thisIndex, components);

    final nextIndex = thisIndex + 1;
    if (nextIndex == components.length) {
      // This element matches the last component so return it.
      return this;
    }

    // Search for a matching child.
    final identifier = components[nextIndex];
    for (final child in children) {
      if ((child as ElementImpl).identifier == identifier) {
        return child._locateElement(location, nextIndex);
      }
    }

    return null;
  }
}
