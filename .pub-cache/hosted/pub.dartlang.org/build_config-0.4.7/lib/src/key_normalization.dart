// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const _defaultTargetNamePlaceholder = r'$default';

/// Returns the normalized [builderKey] definition when used from [packageName].
///
/// Example normalizations:
///
///   - "some_builder" => "$packageName:some_builder"
///   - ":some_builder" => "$packageName:some_builder"
///   - "some_package:some_builder" => "some_package:some_builder"
///
/// If the legacy separator `|` is used it will be transformed to `:`
String normalizeBuilderKeyDefinition(String builderKey, String packageName) =>
    _normalizeDefinition(
        builderKey.contains('|')
            ? builderKey.replaceFirst('|', ':')
            : builderKey,
        packageName);

/// Returns the normalized [builderKey] usage when used from [packageName].
///
/// Example normalizations:
///
///   - "some_package" => "some_package:some_package"
///   - ":some_builder" => "$packageName:some_builder"
///   - "some_package:some_builder" => "some_package:some_builder"
///
/// If the legacy separator `|` is used it will be transformed to `:`
String normalizeBuilderKeyUsage(String builderKey, String packageName) =>
    _normalizeUsage(
        builderKey.contains('|')
            ? builderKey.replaceFirst('|', ':')
            : builderKey,
        packageName);

/// Returns the normalized [targetKey] definition when used from [packageName].
///
/// Example normalizations:
///
///   - "$default" => "$packageName:$packageName"
///   - "some_target" => "$packageName:some_target"
///   - ":some_target" => "$packageName:some_target"
///   - "some_package:some_target" => "some_package|some_target"
String normalizeTargetKeyDefinition(String targetKey, String packageName) =>
    targetKey == _defaultTargetNamePlaceholder
        ? '$packageName:$packageName'
        : _normalizeDefinition(targetKey, packageName);

/// Returns the normalized [targetKey] usage when used from [packageName].
///
/// Example normalizations:
///
///   - "$default" => "$packageName:$packageName"
///   - ":$default" => "$packageName:$packageName"
///   - "$default:$default" => "$packageName:$packageName"
///   - "some_package" => "some_package:some_package"
///   - ":some_target" => "$packageName:some_target"
///   - "some_package:some_target" => "some_package:some_target"
String normalizeTargetKeyUsage(String targetKey, String packageName) {
  switch (targetKey) {
    case _defaultTargetNamePlaceholder:
    case ':$_defaultTargetNamePlaceholder':
    case '$_defaultTargetNamePlaceholder:$_defaultTargetNamePlaceholder':
      return '$packageName:$packageName';
    default:
      return _normalizeUsage(targetKey, packageName);
  }
}

/// Gives a full unique key for [name] used from [packageName].
///
/// If [name] omits the separator we assume it's referring to a target or
/// builder named after a package (which is not this package). If [name] starts
/// with the separator we assume it's referring to a target within the package
/// it's used from.
///
/// For example: If I depend on `angular` from `my_package` it is treated as a
/// dependency on the globally unique `angular:angular`.
String _normalizeUsage(String name, String packageName) {
  if (name.startsWith(':')) return '$packageName$name';
  if (!name.contains(':')) return '$name:$name';
  return name;
}

/// Gives a full unique key for [name] definied within [packageName].
///
/// The result is always '$packageName$separator$name since at definition the
/// key must be referring to something within [packageName].
///
/// For example: If I expose a builder `my_builder` within `my_package` it is
/// turned into the globally unique `my_package|my_builder`.
String _normalizeDefinition(String name, String packageName) {
  if (name.startsWith(':')) return '$packageName$name';
  if (!name.contains(':')) return '$packageName:$name';
  return name;
}
