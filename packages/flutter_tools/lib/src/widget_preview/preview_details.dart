// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';

/// Contains details related to a single preview instance.
final class PreviewDetails {
  PreviewDetails({
    required this.packageName,
    required this.functionName,
    required this.isBuilder,
    required DartObject previewAnnotation,
  }) : name = previewAnnotation.getField(kName)!,
       size = previewAnnotation.getField(kSize)!,
       textScaleFactor = previewAnnotation.getField(kTextScaleFactor)!,
       wrapper = previewAnnotation.getField(kWrapper)!,
       theme = previewAnnotation.getField(kTheme)!,
       brightness = previewAnnotation.getField(kBrightness)!,
       localizations = previewAnnotation.getField(kLocalizations)!;

  static const kPackageName = 'packageName';
  static const kName = 'name';
  static const kSize = 'size';
  static const kTextScaleFactor = 'textScaleFactor';
  static const kWrapper = 'wrapper';
  static const kTheme = 'theme';
  static const kBrightness = 'brightness';
  static const kLocalizations = 'localizations';

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

  /// A description to be displayed alongside the preview.
  ///
  /// If not provided, no name will be associated with the preview.
  final DartObject name;

  /// Artificial constraints to be applied to the `child`.
  ///
  /// If not provided, the previewed widget will attempt to set its own
  /// constraints and may result in an unbounded constraint error.
  final DartObject size;

  /// Applies font scaling to text within the `child`.
  ///
  /// If not provided, the default text scaling factor provided by `MediaQuery`
  /// will be used.
  final DartObject textScaleFactor;

  /// The name of a tear-off used to wrap the `Widget` returned by the preview
  /// function defined by [functionName].
  ///
  /// If not provided, the `Widget` returned by [functionName] will be used by
  /// the previewer directly.
  final DartObject wrapper;

  /// Set to `true` if `wrapper` is set.
  bool get hasWrapper => !wrapper.isNull;

  /// A callback to return Material and Cupertino theming data to be applied
  /// to the previewed `Widget`.
  final DartObject theme;

  /// Sets the initial theme brightness.
  ///
  /// If not provided, the current system default brightness will be used.
  final DartObject brightness;

  final DartObject localizations;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other.runtimeType == runtimeType &&
        other is PreviewDetails &&
        other.packageName == packageName &&
        other.functionName == functionName &&
        other.isBuilder == isBuilder &&
        other.size == size &&
        other.textScaleFactor == textScaleFactor &&
        other.wrapper == wrapper &&
        other.theme == theme &&
        other.brightness == brightness &&
        other.localizations == localizations;
  }

  @override
  String toString() =>
      'PreviewDetails(function: $functionName packageName: $packageName isBuilder: $isBuilder '
      '$kName: $name $kSize: $size $kTextScaleFactor: $textScaleFactor $kWrapper: $wrapper '
      '$kTheme: $theme $kBrightness: $brightness $kLocalizations: $localizations)';

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(<Object?>[
    packageName,
    functionName,
    isBuilder,
    size,
    textScaleFactor,
    wrapper,
    theme,
    brightness,
    localizations,
  ]);
}
