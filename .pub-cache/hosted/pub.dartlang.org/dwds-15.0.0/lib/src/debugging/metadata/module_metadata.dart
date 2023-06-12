// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Module metadata format version
///
/// Module reader always creates the current version but is able to read
/// metadata files with later versions as long as the changes are backward
/// compatible, i.e. only minor or patch versions have changed.
///
/// See: https://goto.google.com/dart-web-debugger-metadata
class ModuleMetadataVersion {
  final int majorVersion;
  final int minorVersion;
  final int patchVersion;

  const ModuleMetadataVersion(
    this.majorVersion,
    this.minorVersion,
    this.patchVersion,
  );

  /// Current metadata version
  ///
  /// Version follows simple semantic versioning format 'major.minor.patch'
  /// See https://semver.org
  static const ModuleMetadataVersion current = ModuleMetadataVersion(2, 0, 0);

  /// Previous version supported by the metadata reader
  static const ModuleMetadataVersion previous = ModuleMetadataVersion(1, 0, 0);

  /// Current metadata version created by the reader
  String get version => '$majorVersion.$minorVersion.$patchVersion';

  /// Is this metadata version compatible with the given version
  ///
  /// The minor and patch version changes never remove any fields that current
  /// version supports, so the reader can create current metadata version from
  /// any file created with a later writer, as long as the major version does
  /// not change.
  bool isCompatibleWith(String version) {
    final parts = version.split('.');
    if (parts.length != 3) {
      throw FormatException('Version: $version'
          'does not follow simple semantic versioning format');
    }
    final major = int.parse(parts[0]);
    final minor = int.parse(parts[1]);
    final patch = int.parse(parts[2]);
    return major == majorVersion &&
        minor >= minorVersion &&
        patch >= patchVersion;
  }
}

/// Library metadata
///
/// Represents library metadata used in the debugger,
/// supports reading from and writing to json
/// See: https://goto.google.com/dart-web-debugger-metadata
class LibraryMetadata {
  /// Library name as defined in pubspec.yaml
  final String name;

  /// Library importUri
  ///
  /// Example package:path/path.dart
  final String importUri;

  /// All file uris from the library
  ///
  /// Can be relative paths to the directory of the fileUri
  final List<String> partUris;

  LibraryMetadata(this.name, this.importUri, this.partUris);

  LibraryMetadata.fromJson(Map<String, dynamic> json)
      : name = _readRequiredField(json, 'name'),
        importUri = _readRequiredField(json, 'importUri'),
        partUris = _readOptionalList(json, 'partUris') ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'importUri': importUri,
      'partUris': [...partUris]
    };
  }
}

/// Module metadata
///
/// Represents module metadata used in the debugger,
/// supports reading from and writing to json
/// See: https://goto.google.com/dart-web-debugger-metadata
class ModuleMetadata {
  /// Metadata format version
  late final String version;

  /// Module name
  ///
  /// Used as a name of the js module created by the compiler and
  /// as key to store and load modules in the debugger and the browser
  final String name;

  /// Name of the function enclosing the module
  ///
  /// Used by debugger to determine the top dart scope
  final String closureName;

  /// Source map uri
  final String sourceMapUri;

  /// Module uri
  final String moduleUri;

  /// True if the module corresponding to this metadata was compiled with sound
  /// null safety enabled.
  final bool soundNullSafety;

  final Map<String, LibraryMetadata> libraries = {};

  ModuleMetadata(this.name, this.closureName, this.sourceMapUri, this.moduleUri,
      this.soundNullSafety,
      {String? ver}) {
    version = ver ?? ModuleMetadataVersion.current.version;
  }

  /// Add [library] to metadata
  ///
  /// Used for filling the metadata in the compiler or for reading from
  /// stored metadata files.
  void addLibrary(LibraryMetadata library) {
    if (!libraries.containsKey(library.importUri)) {
      libraries[library.importUri] = library;
    } else {
      throw Exception('Metadata creation error: '
          'Cannot add library $library with uri ${library.importUri}: '
          'another library "${libraries[library.importUri]}" is found '
          'with the same uri');
    }
  }

  ModuleMetadata.fromJson(Map<String, dynamic> json)
      : version = _readRequiredField(json, 'version'),
        name = _readRequiredField(json, 'name'),
        closureName = _readRequiredField(json, 'closureName'),
        sourceMapUri = _readRequiredField(json, 'sourceMapUri'),
        moduleUri = _readRequiredField(json, 'moduleUri'),
        soundNullSafety = _readOptionalField(json, 'soundNullSafety') ?? false {
    if (!ModuleMetadataVersion.current.isCompatibleWith(version) &&
        !ModuleMetadataVersion.previous.isCompatibleWith(version)) {
      throw Exception('Unsupported metadata version $version. '
          '\n  Supported versions: '
          '\n    ${ModuleMetadataVersion.current.version} '
          '\n    ${ModuleMetadataVersion.previous.version}');
    }

    for (var l in _readRequiredList(json, 'libraries')) {
      addLibrary(LibraryMetadata.fromJson(l as Map<String, dynamic>));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'name': name,
      'closureName': closureName,
      'sourceMapUri': sourceMapUri,
      'moduleUri': moduleUri,
      'libraries': [for (var lib in libraries.values) lib.toJson()],
      'soundNullSafety': soundNullSafety
    };
  }
}

T _readRequiredField<T>(Map<String, dynamic> json, String field) {
  if (!json.containsKey(field)) {
    throw FormatException('Required field $field is not set in $json');
  }
  return json[field]! as T;
}

T? _readOptionalField<T>(Map<String, dynamic> json, String field) =>
    json[field] as T?;

List<T> _readRequiredList<T>(Map<String, dynamic> json, String field) {
  final list = _readRequiredField<List<dynamic>>(json, field);
  return List.castFrom<dynamic, T>(list);
}

List<T>? _readOptionalList<T>(Map<String, dynamic> json, String field) {
  final list = _readOptionalField<List<dynamic>>(json, field);
  return list == null ? null : List.castFrom<dynamic, T>(list);
}
