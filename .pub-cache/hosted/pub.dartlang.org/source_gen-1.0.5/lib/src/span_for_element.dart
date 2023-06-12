// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:source_span/source_span.dart';

import 'utils.dart';

/// Returns a source span that spans the location where [element] is defined.
///
/// May be used to emit user-friendly warning and error messages:
/// ```dart
/// void invalidClass(ClassElement class) {
///   log.warning(spanForElement.message('Cannot implement "Secret"'));
/// }
/// ```
///
/// Not all results from the analyzer API may return source information as part
/// of the element, so [file] may need to be manually provided in those cases.
SourceSpan spanForElement(Element element, [SourceFile? file]) {
  final url = assetToPackageUrl(element.source!.uri);
  if (file == null) {
    final contents = element.source?.contents;
    if (contents == null) {
      return SourceSpan(
        SourceLocation(
          element.nameOffset,
          sourceUrl: url,
        ),
        SourceLocation(
          element.nameOffset + element.nameLength,
          sourceUrl: url,
        ),
        element.name!,
      );
    }
    file = SourceFile.fromString(contents.data, url: url);
  }
  if (element.nameOffset < 0) {
    if (element is PropertyInducingElement) {
      if (element.getter != null) {
        return spanForElement(element.getter!);
      }

      if (element.setter != null) {
        return spanForElement(element.setter!);
      }
    }
  }

  return file.span(element.nameOffset, element.nameOffset + element.nameLength);
}
