// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

part 'dependency.g.dart';

Map<String, Dependency> parseDeps(Map? source) =>
    source?.map((k, v) {
      final key = k as String;
      Dependency? value;
      try {
        value = _fromJson(v, k);
      } on CheckedFromJsonException catch (e) {
        if (e.map is! YamlMap) {
          // This is likely a "synthetic" map created from a String value
          // Use `source` to throw this exception with an actual YamlMap and
          // extract the associated error information.
          throw CheckedFromJsonException(source, key, e.className!, e.message);
        }
        rethrow;
      }

      if (value == null) {
        throw CheckedFromJsonException(
          source,
          key,
          'Pubspec',
          'Not a valid dependency value.',
        );
      }
      return MapEntry(key, value);
    }) ??
    {};

const _sourceKeys = ['sdk', 'git', 'path', 'hosted'];

/// Returns `null` if the data could not be parsed.
Dependency? _fromJson(Object? data, String name) {
  if (data is String || data == null) {
    return _$HostedDependencyFromJson({'version': data});
  }

  if (data is Map) {
    final matchedKeys =
        data.keys.cast<String>().where((key) => key != 'version').toList();

    if (data.isEmpty || (matchedKeys.isEmpty && data.containsKey('version'))) {
      return _$HostedDependencyFromJson(data);
    } else {
      final firstUnrecognizedKey =
          matchedKeys.firstWhereOrNull((k) => !_sourceKeys.contains(k));

      return $checkedNew<Dependency>('Dependency', data, () {
        if (firstUnrecognizedKey != null) {
          throw UnrecognizedKeysException(
            [firstUnrecognizedKey],
            data,
            _sourceKeys,
          );
        }
        if (matchedKeys.length > 1) {
          throw CheckedFromJsonException(
            data,
            matchedKeys[1],
            'Dependency',
            'A dependency may only have one source.',
          );
        }

        final key = matchedKeys.single;

        switch (key) {
          case 'git':
            return GitDependency.fromData(data[key]);
          case 'path':
            return PathDependency.fromData(data[key]);
          case 'sdk':
            return _$SdkDependencyFromJson(data);
          case 'hosted':
            final hosted = _$HostedDependencyFromJson(data);
            hosted.hosted?._nameOfPackage = name;
            return hosted;
        }
        throw StateError('There is a bug in pubspec_parse.');
      });
    }
  }

  // Not a String or a Map – return null so parent logic can throw proper error
  return null;
}

abstract class Dependency {
  Dependency._();

  String get _info;

  @override
  String toString() => '$runtimeType: $_info';
}

@JsonSerializable()
class SdkDependency extends Dependency {
  final String sdk;
  @JsonKey(fromJson: _constraintFromString)
  final VersionConstraint version;

  SdkDependency(this.sdk, {VersionConstraint? version})
      : version = version ?? VersionConstraint.any,
        super._();

  @override
  String get _info => sdk;
}

@JsonSerializable()
class GitDependency extends Dependency {
  @JsonKey(fromJson: parseGitUri)
  final Uri url;
  final String? ref;
  final String? path;

  GitDependency(this.url, {this.ref, this.path}) : super._();

  factory GitDependency.fromData(Object? data) {
    if (data is String) {
      data = {'url': data};
    }

    if (data is Map) {
      return _$GitDependencyFromJson(data);
    }

    throw ArgumentError.value(data, 'git', 'Must be a String or a Map.');
  }

  @override
  String get _info => 'url@$url';
}

Uri? parseGitUriOrNull(String? value) =>
    value == null ? null : parseGitUri(value);

Uri parseGitUri(String value) => _tryParseScpUri(value) ?? Uri.parse(value);

/// Supports URIs like `[user@]host.xz:path/to/repo.git/`
/// See https://git-scm.com/docs/git-clone#_git_urls_a_id_urls_a
Uri? _tryParseScpUri(String value) {
  final colonIndex = value.indexOf(':');

  if (colonIndex < 0) {
    return null;
  } else if (colonIndex == value.indexOf('://')) {
    // If the first colon is part of a scheme, it's not an scp-like URI
    return null;
  }
  final slashIndex = value.indexOf('/');

  if (slashIndex >= 0 && slashIndex < colonIndex) {
    // Per docs: This syntax is only recognized if there are no slashes before
    // the first colon. This helps differentiate a local path that contains a
    // colon. For example the local path foo:bar could be specified as an
    // absolute path or ./foo:bar to avoid being misinterpreted as an ssh url.
    return null;
  }

  final atIndex = value.indexOf('@');
  if (colonIndex > atIndex) {
    final user = atIndex >= 0 ? value.substring(0, atIndex) : null;
    final host = value.substring(atIndex + 1, colonIndex);
    final path = value.substring(colonIndex + 1);
    return Uri(scheme: 'ssh', userInfo: user, host: host, path: path);
  }
  return null;
}

class PathDependency extends Dependency {
  final String path;

  PathDependency(this.path) : super._();

  factory PathDependency.fromData(Object? data) {
    if (data is String) {
      return PathDependency(data);
    }
    throw ArgumentError.value(data, 'path', 'Must be a String.');
  }

  @override
  String get _info => 'path@$path';
}

@JsonSerializable(disallowUnrecognizedKeys: true)
class HostedDependency extends Dependency {
  @JsonKey(fromJson: _constraintFromString)
  final VersionConstraint version;

  @JsonKey(disallowNullValue: true)
  final HostedDetails? hosted;

  HostedDependency({VersionConstraint? version, this.hosted})
      : version = version ?? VersionConstraint.any,
        super._();

  @override
  String get _info => version.toString();
}

@JsonSerializable(disallowUnrecognizedKeys: true)
class HostedDetails {
  /// The name of the target dependency as declared in a `hosted` block.
  ///
  /// This may be null if no explicit name is present, for instance because the
  /// hosted dependency was declared as a string (`hosted: pub.example.org`).
  @JsonKey(name: 'name')
  final String? declaredName;

  @JsonKey(fromJson: parseGitUriOrNull, disallowNullValue: true)
  final Uri? url;

  @JsonKey(ignore: true)
  String? _nameOfPackage;

  /// The name of this package on the package repository.
  ///
  /// If this hosted block has a [declaredName], that one will be used.
  /// Otherwise, the name will be inferred from the surrounding package name.
  String get name => declaredName ?? _nameOfPackage!;

  HostedDetails(this.declaredName, this.url);

  factory HostedDetails.fromJson(Object data) {
    if (data is String) {
      data = {'url': data};
    }

    if (data is Map) {
      return _$HostedDetailsFromJson(data);
    }

    throw ArgumentError.value(data, 'hosted', 'Must be a Map or String.');
  }
}

VersionConstraint _constraintFromString(String? input) =>
    input == null ? VersionConstraint.any : VersionConstraint.parse(input);
