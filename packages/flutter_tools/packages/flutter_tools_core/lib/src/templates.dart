// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

const String _packageScheme = 'package';

/// Project template archetype being scaffolded by `flutter create`.
enum ExtensionTemplateType {
  /// A standard Flutter application (`flutter create -t app`).
  app,

  /// A Flutter FFI plugin (`flutter create -t plugin_ffi`).
  ffiPlugin,

  /// A Flutter platform channel plugin (`flutter create -t plugin`).
  plugin,
}

/// Descriptor for a resolved platform template returned by
/// `TemplateService.resolvePlatformTemplate`.
@immutable
final class ExtensionPlatformTemplate {
  /// Creates a platform template descriptor pointing to [templateUri], throwing
  /// an [ArgumentError] if [templateUri] is not a valid
  /// `package:<package>/<path>` directory URI without a trailing slash.
  ExtensionPlatformTemplate({required this.templateUri}) {
    if (!_isValidTemplateUri(templateUri)) {
      throw ArgumentError.value(
        templateUri,
        'templateUri',
        'Expected a package:<package>/<path> directory URI without a trailing slash.',
      );
    }
  }

  /// Deserializes an [ExtensionPlatformTemplate] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if [templateUriKey] is missing, not a [String],
  /// or not a valid `package:<package>/<path>` URI without a trailing slash.
  factory ExtensionPlatformTemplate.fromJson(Map<String, Object?> json) {
    final String rawUri = json.requiredField<String>(templateUriKey);
    final Uri? templateUri = Uri.tryParse(rawUri);
    if (templateUri == null || !_isValidTemplateUri(templateUri)) {
      throw FormatException(
        'Invalid "$templateUriKey" in ExtensionPlatformTemplate '
        '(expected package:<package>/<path> URI): "$rawUri".',
      );
    }
    return ExtensionPlatformTemplate(templateUri: templateUri);
  }

  /// JSON map key for [templateUri].
  @visibleForTesting
  static const String templateUriKey = 'templateUri';

  static bool _isValidTemplateUri(Uri uri) =>
      uri.isScheme(_packageScheme) &&
      !uri.hasAuthority &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      !uri.path.startsWith('/') &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments.every((String segment) => segment.isNotEmpty);

  /// `package:` URI pointing to the Mustache template directory to render.
  final Uri templateUri;

  /// Serializes this [ExtensionPlatformTemplate] to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{templateUriKey: templateUri.toString()};

  @override
  String toString() => 'ExtensionPlatformTemplate(templateUri: $templateUri)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionPlatformTemplate && other.templateUri == templateUri);
  }

  @override
  int get hashCode => templateUri.hashCode;
}
