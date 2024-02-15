// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/utils.dart';
import 'parse_list.dart';
import 'parse_result.dart';

/// Represents an entry under the `assets` section of a pubspec.
@immutable
class AssetsEntry {
  const AssetsEntry({
    required this.uri,
    this.flavors = const <String>{},
  });

  final Uri uri;
  final Set<String> flavors;

  static const String _pathKey = 'path';
  static const String _flavorKey = 'flavors';

  static ParseResult<AssetsEntry> parseFromYaml(Object? yaml) {

    ParseResult<Uri> tryParseUri(String uri) {
      try {
        return ParseResult<Uri>.value(Uri(pathSegments: uri.split('/')));
      } on FormatException {
        return ParseResult<Uri>.error('Asset manifest contains invalid uri: $uri.');
      }
    }

    if (yaml == null || yaml == '') {
      return ParseResult<AssetsEntry>.error('Asset manifest contains a null or empty uri.');
    }

    if (yaml is String) {
      final ParseResult<Uri> uriParseResult = tryParseUri(yaml);
      if (uriParseResult.hasValue) {
        return ParseResult<AssetsEntry>.value(AssetsEntry(uri: uriParseResult.value()));
      }
      return ParseResult<AssetsEntry>.errors(uriParseResult.errors);
    }

    if (yaml is! Map) {
      return ParseResult<AssetsEntry>.error(
        'Assets entry had unexpected shape. Expected a string or an object. '
        'Got ${yaml.runtimeType} instead.',
       );
    }

    final Object? path = yaml[_pathKey];
    final Object? flavorsYaml = yaml[_flavorKey];

    if (path == null || path is! String) {
      return ParseResult<AssetsEntry>.error(
        'Asset manifest entry is malformed. Expected asset entry to be '
        'either a string or a map containing a "$_pathKey" entry. '
        'Got ${path.runtimeType} instead.',
      );
    }

    final Uri uri = Uri(pathSegments: path.split('/'));

    if (flavorsYaml == null) {
      return ParseResult<AssetsEntry>.value(AssetsEntry(uri: uri));
    }

    final ParseResult<List<String>> flavorsParseResult = parseList<String>(
      flavorsYaml,
      'flavors list of assets entry "$path"',
      'String',
    );

    if (flavorsParseResult.hasErrors) {
      return ParseResult<AssetsEntry>.errors(flavorsParseResult.errors);
    }

    final AssetsEntry entry = AssetsEntry(
      uri: Uri(pathSegments: path.split('/')),
      flavors: Set<String>.from(flavorsParseResult.value()),
    );

    return ParseResult<AssetsEntry>.value(entry);
  }

  @override
  bool operator ==(Object other) {
    if (other is! AssetsEntry) {
      return false;
    }

    return uri == other.uri && setEquals(flavors, other.flavors);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    uri.hashCode,
    Object.hashAllUnordered(flavors),
  ]);

  @override
  String toString() => 'AssetsEntry(uri: $uri, flavors: $flavors)';
}
