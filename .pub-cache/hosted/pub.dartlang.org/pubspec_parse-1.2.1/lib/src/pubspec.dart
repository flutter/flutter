// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:checked_yaml/checked_yaml.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pub_semver/pub_semver.dart';

import 'dependency.dart';
import 'screenshot.dart';

part 'pubspec.g.dart';

@JsonSerializable()
class Pubspec {
  // TODO: executables

  final String name;

  @JsonKey(fromJson: _versionFromString)
  final Version? version;

  final String? description;

  /// This should be a URL pointing to the website for the package.
  final String? homepage;

  /// Specifies where to publish this package.
  ///
  /// Accepted values: `null`, `'none'` or an `http` or `https` URL.
  ///
  /// [More information](https://dart.dev/tools/pub/pubspec#publish_to).
  final String? publishTo;

  /// Optional field to specify the source code repository of the package.
  /// Useful when a package has both a home page and a repository.
  final Uri? repository;

  /// Optional field to a web page where developers can report new issues or
  /// view existing ones.
  final Uri? issueTracker;

  /// Optional field to list the URLs where the package authors accept
  /// support or funding.
  final List<Uri>? funding;

  /// Optional field for specifying included screenshot files.
  @JsonKey(fromJson: parseScreenshots)
  final List<Screenshot>? screenshots;

  /// If there is exactly 1 value in [authors], returns it.
  ///
  /// If there are 0 or more than 1, returns `null`.
  @Deprecated(
    'See https://dart.dev/tools/pub/pubspec#authorauthors',
  )
  String? get author {
    if (authors.length == 1) {
      return authors.single;
    }
    return null;
  }

  @Deprecated(
    'See https://dart.dev/tools/pub/pubspec#authorauthors',
  )
  final List<String> authors;
  final String? documentation;

  @JsonKey(fromJson: _environmentMap)
  final Map<String, VersionConstraint?>? environment;

  @JsonKey(fromJson: parseDeps)
  final Map<String, Dependency> dependencies;

  @JsonKey(fromJson: parseDeps)
  final Map<String, Dependency> devDependencies;

  @JsonKey(fromJson: parseDeps)
  final Map<String, Dependency> dependencyOverrides;

  /// Optional configuration specific to [Flutter](https://flutter.io/)
  /// packages.
  ///
  /// May include
  /// [assets](https://flutter.io/docs/development/ui/assets-and-images)
  /// and other settings.
  final Map<String, dynamic>? flutter;

  /// If [author] and [authors] are both provided, their values are combined
  /// with duplicates eliminated.
  Pubspec(
    this.name, {
    this.version,
    this.publishTo,
    @Deprecated(
      'See https://dart.dev/tools/pub/pubspec#authorauthors',
    )
        String? author,
    @Deprecated(
      'See https://dart.dev/tools/pub/pubspec#authorauthors',
    )
        List<String>? authors,
    Map<String, VersionConstraint?>? environment,
    this.homepage,
    this.repository,
    this.issueTracker,
    this.funding,
    this.screenshots,
    this.documentation,
    this.description,
    Map<String, Dependency>? dependencies,
    Map<String, Dependency>? devDependencies,
    Map<String, Dependency>? dependencyOverrides,
    this.flutter,
  })  :
        // ignore: deprecated_member_use_from_same_package
        authors = _normalizeAuthors(author, authors),
        environment = environment ?? const {},
        dependencies = dependencies ?? const {},
        devDependencies = devDependencies ?? const {},
        dependencyOverrides = dependencyOverrides ?? const {} {
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', '"name" cannot be empty.');
    }

    if (publishTo != null && publishTo != 'none') {
      try {
        final targetUri = Uri.parse(publishTo!);
        if (!(targetUri.isScheme('http') || targetUri.isScheme('https'))) {
          throw const FormatException('Must be an http or https URL.');
        }
      } on FormatException catch (e) {
        throw ArgumentError.value(publishTo, 'publishTo', e.message);
      }
    }
  }

  factory Pubspec.fromJson(Map json, {bool lenient = false}) {
    if (lenient) {
      while (json.isNotEmpty) {
        // Attempting to remove top-level properties that cause parsing errors.
        try {
          return _$PubspecFromJson(json);
        } on CheckedFromJsonException catch (e) {
          if (e.map == json && json.containsKey(e.key)) {
            json = Map.from(json)..remove(e.key);
            continue;
          }
          rethrow;
        }
      }
    }

    return _$PubspecFromJson(json);
  }

  /// Parses source [yaml] into [Pubspec].
  ///
  /// When [lenient] is set, top-level property-parsing or type cast errors are
  /// ignored and `null` values are returned.
  factory Pubspec.parse(String yaml, {Uri? sourceUrl, bool lenient = false}) =>
      checkedYamlDecode(
        yaml,
        (map) => Pubspec.fromJson(map!, lenient: lenient),
        sourceUrl: sourceUrl,
      );

  static List<String> _normalizeAuthors(String? author, List<String>? authors) {
    final value = <String>{
      if (author != null) author,
      ...?authors,
    };
    return value.toList();
  }
}

Version? _versionFromString(String? input) =>
    input == null ? null : Version.parse(input);

Map<String, VersionConstraint?>? _environmentMap(Map? source) =>
    source?.map((k, value) {
      final key = k as String;
      if (key == 'dart') {
        // github.com/dart-lang/pub/blob/d84173eeb03c3/lib/src/pubspec.dart#L342
        // 'dart' is not allowed as a key!
        throw CheckedFromJsonException(
          source,
          'dart',
          'VersionConstraint',
          'Use "sdk" to for Dart SDK constraints.',
          badKey: true,
        );
      }

      VersionConstraint? constraint;
      if (value == null) {
        constraint = null;
      } else if (value is String) {
        try {
          constraint = VersionConstraint.parse(value);
        } on FormatException catch (e) {
          throw CheckedFromJsonException(source, key, 'Pubspec', e.message);
        }

        return MapEntry(key, constraint);
      } else {
        throw CheckedFromJsonException(
          source,
          key,
          'VersionConstraint',
          '`$value` is not a String.',
        );
      }

      return MapEntry(key, constraint);
    });
