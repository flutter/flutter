// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// Contains details related to a single preview instance.
final class PreviewDetails {
  PreviewDetails({required this.packageName, required this.functionName, required this.isBuilder});

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
  Expression? get name => _name;
  Expression? _name;

  /// Artificial constraints to be applied to the `child`.
  ///
  /// If not provided, the previewed widget will attempt to set its own
  /// constraints and may result in an unbounded constraint error.
  Expression? get size => _size;
  Expression? _size;

  /// Applies font scaling to text within the `child`.
  ///
  /// If not provided, the default text scaling factor provided by `MediaQuery`
  /// will be used.
  Expression? get textScaleFactor => _textScaleFactor;
  Expression? _textScaleFactor;

  /// The name of a tear-off used to wrap the `Widget` returned by the preview
  /// function defined by [functionName].
  ///
  /// If not provided, the `Widget` returned by [functionName] will be used by
  /// the previewer directly.
  Identifier? get wrapper => _wrapper;
  Identifier? _wrapper;

  /// Set to `true` if `wrapper` is set.
  bool get hasWrapper => _wrapper != null;

  /// A callback to return Material and Cupertino theming data to be applied
  /// to the previewed `Widget`.
  Identifier? get theme => _theme;
  Identifier? _theme;

  /// Sets the initial theme brightness.
  ///
  /// If not provided, the current system default brightness will be used.
  Expression? get brightness => _brightness;
  Expression? _brightness;

  Expression? get localizations => _localizations;
  Expression? _localizations;

  /// Initializes a property based on a argument to the preview declaration.
  ///
  /// Throws a [StateError] if the property has already been initialized.
  void setField({required NamedExpression node}) {
    final String key = node.name.label.name;
    final Expression expression = node.expression;
    switch (key) {
      case kName:
        _expectNotSet(kName, _name);
        _name = expression;
      case kSize:
        _expectNotSet(kSize, _size);
        _size = expression;
      case kTextScaleFactor:
        _expectNotSet(kTextScaleFactor, _textScaleFactor);
        _textScaleFactor = expression;
      case kWrapper:
        _expectNotSet(kWrapper, _wrapper);
        _wrapper = expression as Identifier;
      case kTheme:
        _expectNotSet(kTheme, _theme);
        _theme = expression as Identifier;
      case kBrightness:
        _expectNotSet(kBrightness, _brightness);
        _brightness = expression;
      case kLocalizations:
        _expectNotSet(kLocalizations, _localizations);
        _localizations = expression;
      default:
        throw StateError('Unknown Preview field "$name": ${expression.toSource()}');
    }
  }

  void _expectNotSet(String key, Object? field) {
    if (field != null) {
      throw StateError('$key has already been set.');
    }
  }

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
      '$kTheme: $theme $kBrightness: $_brightness $kLocalizations: $_localizations)';

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
