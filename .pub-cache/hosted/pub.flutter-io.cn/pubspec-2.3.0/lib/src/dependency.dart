// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library pubspec.dependency;

import 'dart:convert';

// ignore: import_of_legacy_library_into_null_safe
import 'package:pub_semver/pub_semver.dart';

import 'json_utils.dart';

abstract class DependencyReference implements Jsonable {
  const DependencyReference();

  factory DependencyReference.fromJson(json) {
    if (json is Map) {
      var type = getKnownType(json.keys);
      switch (type) {
        case 'path':
          return PathReference.fromJson(json);
        case 'git':
          return GitReference.fromJson(json);
        case 'hosted':
          return ExternalHostedReference.fromJson(json);
        case 'sdk':
          return SdkReference.fromJson(json);
        default:
          throw StateError('unexpected dependency type ${json.keys.first}');
      }
    } else if (json is String) {
      return HostedReference.fromJson(json);
    } else if (json == null) {
      return HostedReference(VersionConstraint.any);
    } else {
      throw StateError('Unable to parse dependency $json');
    }
  }

  String toString() => json.encode(this);
}

/// The dependency type by convention is the first key
/// however there is no require that it is the first
/// so we need to search the map of keys to see if
/// a know type exits.
String getKnownType(Iterable keys) {
  if (keys.contains('path')) return 'path';
  if (keys.contains('git')) return 'git';
  if (keys.contains('hosted')) return 'hosted';
  if (keys.contains('sdk')) return 'sdk';

  return "";
}

class GitReference extends DependencyReference {
  final String url;
  final String? ref;
  final String? path;

  const GitReference(this.url, [this.ref, this.path]);

  factory GitReference.fromJson(Map json) {
    final git = json['git'];
    if (git is String) {
      return GitReference(git, null);
    } else if (git is Map) {
      Map m = git;
      return GitReference(m['url'], m['ref'], m['path']);
    } else {
      throw StateError('Unexpected format for git dependency $git');
    }
  }

  @override
  Map toJson() {
    if (ref == null && path == null) {
      return {'git': url.toString()};
    }

    var arguments = {'url': url.toString()};

    if (ref != null) arguments['ref'] = ref!;
    if (path != null) arguments['path'] = path!;

    return {'git': arguments};
  }

  bool operator ==(other) =>
      other is GitReference && other.url == url && other.ref == ref;

  int get hashCode => ref.hashCode;
}

class PathReference extends DependencyReference {
  final String? path;

  const PathReference(this.path);

  PathReference.fromJson(Map json) : this(json['path']);

  @override
  Map toJson() => {'path': path};

  bool operator ==(other) => other is PathReference && other.path == path;

  int get hashCode => path.hashCode;
}

class HostedReference extends DependencyReference {
  final VersionConstraint versionConstraint;

  const HostedReference(this.versionConstraint);

  HostedReference.fromJson(String json) : this(VersionConstraint.parse(json));

  @override
  String toJson() => "${versionConstraint.toString()}";

  bool operator ==(other) =>
      other is HostedReference && other.versionConstraint == versionConstraint;

  int get hashCode => versionConstraint.hashCode;
}

class ExternalHostedReference extends DependencyReference {
  final String? name, url;
  final VersionConstraint versionConstraint;
  final bool verboseFormat;

  ExternalHostedReference(this.name, this.url, this.versionConstraint,
      [this.verboseFormat = true]);

  ExternalHostedReference.fromJson(Map json)
      : this(
            json['hosted'] is String ? null : json['hosted']['name'],
            json['hosted'] is String ? json['hosted'] : json['hosted']['url'],
            VersionConstraint.parse(json['version']),
            json['hosted'] is String ? false : true);

  bool operator ==(other) =>
      other is ExternalHostedReference &&
      other.name == name &&
      other.url == url &&
      other.versionConstraint == versionConstraint;

  @override
  toJson() {
    if (verboseFormat) {
      return {
        'hosted': {'name': name, 'url': url},
        'version': versionConstraint.toString()
      };
    } else {
      return {'hosted': url, 'version': versionConstraint.toString()};
    }
  }
}

class SdkReference extends DependencyReference {
  final String? sdk;

  const SdkReference(this.sdk);

  SdkReference.fromJson(Map json) : this(json['sdk']);

  bool operator ==(other) => other is SdkReference && other.sdk == sdk;

  @override
  toJson() {
    return {'sdk': sdk};
  }
}
