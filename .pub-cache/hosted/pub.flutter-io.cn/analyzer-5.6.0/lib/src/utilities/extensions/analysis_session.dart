// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/utilities/extensions/library_element.dart';

extension AnalysisSessionExtension on AnalysisSession {
  /// Locates the [Element] that [location] represents.
  ///
  /// Local elements such as variables inside functions cannot be found using
  /// this method.
  ///
  /// Returns `null` if the element cannot be found.
  Future<Element?> locateElement(ElementLocation location) async {
    final components = location.components;
    if (location.components.isEmpty) {
      return null;
    }

    // The first component is the library which we'll use to start the search.
    final libraryUri = components.first;
    final result = await getLibraryByUri(libraryUri);
    return result is LibraryElementResult
        ? result.element.locateElement(location)
        : null;
  }
}
