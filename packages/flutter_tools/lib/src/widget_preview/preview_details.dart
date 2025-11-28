// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';

typedef PreviewProperty = ({String key, DartObject object, bool isCallback});

/// Contains details related to a single preview instance.
final class PreviewDetails {
  PreviewDetails({
    required this.scriptUri,
    required this.line,
    required this.column,
    required this.packageName,
    required this.functionName,
    required this.isBuilder,
    required this.isMultiPreview,
    required this.previewAnnotation,
  });

  /// The file:// URI pointing to the script in which the preview is defined.
  final Uri scriptUri;

  /// The 1-based line at which the Preview annotation was applied.
  final int line;

  /// The 1-based column at which the Preview annotation was applied.
  final int column;

  /// The name of the package in which the preview was defined.
  ///
  /// For example, if this preview is defined in 'package:foo/src/bar.dart', this
  /// will have the value 'foo'.
  ///
  /// This should only be null if the preview is defined in a file that's not
  /// part of a Flutter library (e.g., is defined in a test).
  final String? packageName;

  /// The name of the function returning the preview.
  final String functionName;

  /// Set to `true` if the preview function is returning a `WidgetBuilder`
  /// instead of a `Widget`.
  final bool isBuilder;

  /// The annotation marking a function as a preview.
  ///
  /// This can be any object which extends `Preview` or `MultiPreview`.
  final DartObject previewAnnotation;

  /// Set to true if [previewAnnotation] is a `MultiPreview`.
  final bool isMultiPreview;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is PreviewDetails &&
        other.scriptUri == scriptUri &&
        other.packageName == packageName &&
        other.functionName == functionName &&
        other.isBuilder == isBuilder &&
        other.previewAnnotation == previewAnnotation &&
        other.isMultiPreview == isMultiPreview;
  }

  @override
  String toString() =>
      '''
PreviewDetails(
  scriptUri: $scriptUri
  function: $functionName
  packageName: $packageName
  isBuilder: $isBuilder
  isMultiPreview: $isMultiPreview
  previewAnnotation: $previewAnnotation
)
''';

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(<Object?>[
    scriptUri,
    packageName,
    functionName,
    isBuilder,
    previewAnnotation,
    isMultiPreview,
  ]);
}
