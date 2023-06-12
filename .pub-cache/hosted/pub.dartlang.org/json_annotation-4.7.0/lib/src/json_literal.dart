// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta_meta.dart';

/// An annotation used to generate a private field containing the contents of a
/// JSON file.
///
/// The annotation can be applied to any member, but usually it's applied to
/// top-level getter.
///
/// In this example, the JSON content of `data.json` is populated into a
/// top-level, final field `_$glossaryDataJsonLiteral` in the generated file.
///
/// ```dart
/// @JsonLiteral('data.json')
/// Map get glossaryData => _$glossaryDataJsonLiteral;
/// ```
@Target({TargetKind.getter})
class JsonLiteral {
  /// The relative path from the Dart file with the annotation to the file
  /// containing the source JSON.
  final String path;

  /// `true` if the JSON literal should be written as a constant.
  final bool asConst;

  /// Creates a new [JsonLiteral] instance.
  const JsonLiteral(this.path, {this.asConst = false});
}
