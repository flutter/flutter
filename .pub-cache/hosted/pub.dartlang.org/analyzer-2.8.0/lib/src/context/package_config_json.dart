// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

/// Parse the content of a `package_config.json` file located at the [uri].
PackageConfigJson parsePackageConfigJson(Uri uri, String content) {
  assert(uri.isAbsolute);
  return _PackageConfigJsonParser(uri, content).parse();
}

class LanguageVersion {
  final int major;
  final int minor;

  const LanguageVersion(this.major, this.minor);

  @override
  bool operator ==(Object other) {
    return other is LanguageVersion &&
        other.major == major &&
        other.minor == minor;
  }

  @override
  String toString() => '$major.$minor';
}

/// Information about packages used by a Pub package.
///
/// It represents a parsed and processed `package_config.json` file.
class PackageConfigJson {
  /// The absolute URI of the file.
  final Uri uri;

  /// The version of the format.
  final int configVersion;

  /// The list of packages.
  final List<PackageConfigJsonPackage> packages;

  /// The timestamp for when the file was generated.
  ///
  /// Might be `null`.
  final DateTime? generated;

  /// The generator which created the file, typically "pub".
  ///
  /// Might be `null`.
  final String? generator;

  /// The version of the generator, if the generator wants to remember that
  /// information. The version must be a Semantic Version. Pub can use the
  /// SDK version.
  ///
  /// Might be `null`.
  final Version? generatorVersion;

  PackageConfigJson({
    required this.uri,
    required this.configVersion,
    required this.packages,
    required this.generated,
    required this.generator,
    required this.generatorVersion,
  });
}

/// Description of a single package in [PackageConfigJson].
class PackageConfigJsonPackage {
  /// The name of the package.
  final String name;

  /// The root directory of the package. All files inside this directory,
  /// including any  subdirectories, are considered to belong to the package.
  final Uri rootUri;

  /// The package directory, containing files available to Dart programs
  /// using `package:packageName/...` URIs. It is either the [rootUri], or a
  /// sub-directory of the [rootUri].
  final Uri packageUri;

  /// The language version for the package, or `null` if not specified.
  final LanguageVersion? languageVersion;

  PackageConfigJsonPackage({
    required this.name,
    required this.rootUri,
    required this.packageUri,
    required this.languageVersion,
  });
}

class _PackageConfigJsonParser {
  final RegExp _languageVersionRegExp = RegExp(r'(0|[1-9]\d*)\.(0|[1-9]\d*)');

  final Uri uri;
  final String content;

  late int version;
  List<PackageConfigJsonPackage> packages = [];
  DateTime? generated;
  String? generator;
  Version? generatorVersion;

  _PackageConfigJsonParser(this.uri, this.content);

  PackageConfigJson parse() {
    var contentObject = json.decode(content);
    if (contentObject is Map<String, dynamic>) {
      _parseVersion(contentObject);
      _parsePackages(contentObject);
      _parseGenerated(contentObject);
      return PackageConfigJson(
        uri: uri,
        configVersion: version,
        packages: packages,
        generated: generated,
        generator: generator,
        generatorVersion: generatorVersion,
      );
    } else {
      throw FormatException("Expected a JSON object.", content);
    }
  }

  T? _getOptionalField<T>(Map<String, dynamic> map, String name) {
    var object = map[name];
    if (object is T?) {
      return object;
    } else {
      var actualType = object.runtimeType;
      throw FormatException(
        "Expected '$T' value for the '$name' field, found '$actualType'.",
        content,
      );
    }
  }

  T _getRequiredField<T>(Map<String, dynamic> map, String name) {
    var object = map[name];
    if (object is T) {
      return object;
    } else if (object == null) {
      throw FormatException("Missing the '$name' field.", content);
    } else {
      var actualType = object.runtimeType;
      throw FormatException(
        "Expected '$T' value for the '$name' field, found '$actualType'.",
        content,
      );
    }
  }

  void _parseGenerated(Map<String, dynamic> map) {
    var generatedStr = _getOptionalField<String>(map, 'generated');
    if (generatedStr != null) {
      generated = DateTime.parse(generatedStr);
    }

    generator = _getOptionalField<String>(map, 'generator');

    var generatorVersionStr = _getOptionalField<String>(
      map,
      'generatorVersion',
    );
    if (generatorVersionStr != null) {
      generatorVersion = Version.parse(generatorVersionStr);
    }
  }

  void _parsePackage(Map<String, Object?> map) {
    var name = _getRequiredField<String>(map, 'name');

    var rootUriStr = _getRequiredField<String>(map, 'rootUri');
    var rootUri = uri.resolve(rootUriStr);
    rootUri = _ensureDirectoryUri(rootUri);

    var packageUri = rootUri;
    var packageUriStr = _getOptionalField<String>(map, 'packageUri');
    if (packageUriStr != null) {
      var packageUriRel = Uri.parse(packageUriStr);
      if (packageUriRel.isAbsolute) {
        throw FormatException(
          "The value of the field 'packageUri' must be relative, "
          "actually '$packageUriStr', for the package '$name'.",
          content,
        );
      }

      packageUri = rootUri.resolveUri(packageUriRel);
      packageUri = _ensureDirectoryUri(packageUri);

      if (!_isNestedUri(packageUri, rootUri)) {
        throw FormatException(
          "The resolved 'packageUri' must be inside the rootUri, "
          "actually '$packageUri' is not in '$rootUri', "
          "for the package '$name'.",
          content,
        );
      }
    }

    var languageVersion = _parsePackageLanguageVersion(map);

    packages.add(
      PackageConfigJsonPackage(
        name: name,
        rootUri: rootUri,
        packageUri: packageUri,
        languageVersion: languageVersion,
      ),
    );
  }

  LanguageVersion? _parsePackageLanguageVersion(Map<String, Object?> map) {
    var versionStr = _getOptionalField<String>(map, 'languageVersion');
    if (versionStr == null) {
      return null;
    }

    var match = _languageVersionRegExp.matchAsPrefix(versionStr);
    if (match != null && match.end == versionStr.length) {
      var major = int.parse(match.group(1)!);
      var minor = int.parse(match.group(2)!);
      return LanguageVersion(major, minor);
    } else {
      throw FormatException(
        "Invalid 'languageVersion' format '$versionStr'.",
        content,
      );
    }
  }

  void _parsePackages(Map<String, Object?> map) {
    var packagesObject = _getRequiredField<List<Object?>>(map, 'packages');
    for (var packageObject in packagesObject) {
      if (packageObject is Map<String, dynamic>) {
        _parsePackage(packageObject);
      }
    }
  }

  void _parseVersion(Map<String, Object?> map) {
    version = _getRequiredField(map, 'configVersion');
    if (version != 2) {
      throw FormatException("Unsupported config version: $version");
    }
  }

  static Uri _ensureDirectoryUri(Uri uri) {
    var path = uri.path;
    if (path.endsWith('/')) {
      return uri;
    } else {
      return uri.replace(path: '$path/');
    }
  }

  /// Return `true` if the [nested] is the [enclosing], or is in it.
  static bool _isNestedUri(Uri nested, Uri enclosing) {
    var nestedStr = '$nested';
    var enclosingStr = '$enclosing';
    return nestedStr.contains(enclosingStr);
  }
}
