// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

/// Parse the given [jsonText] into the [AllowedExperiments].
///
/// Throw [FormatException] is any format issues are found.
AllowedExperiments parseAllowedExperiments(String jsonText) {
  return new _AllowedExperimentsParser(jsonText).parse();
}

/// The set of experiments enabled for SDK and packages.
class AllowedExperiments {
  /// The set of experiments that are enabled for all SDK libraries other than
  /// for those which are specified in [sdkLibraryExperiments].
  final List<String> sdkDefaultExperiments;

  /// Mapping from individual SDK libraries, e.g. 'core', to the set of
  /// experiments that are enabled for this library.
  final Map<String, List<String>> sdkLibraryExperiments;

  /// Mapping from package names, e.g. 'path', to the set of experiments that
  /// are enabled for all files of this package.
  final Map<String, List<String>> packageExperiments;

  AllowedExperiments({
    required this.sdkDefaultExperiments,
    required this.sdkLibraryExperiments,
    required this.packageExperiments,
  });

  /// Return the set of enabled experiments for the package with the [name],
  /// e.g. "path", possibly `null`.
  List<String>? forPackage(String name) {
    return packageExperiments[name];
  }

  /// Return the set of enabled experiments for the library with the [name],
  /// e.g. "core".
  List<String> forSdkLibrary(String name) {
    return sdkLibraryExperiments[name] ?? sdkDefaultExperiments;
  }
}

class _AllowedExperimentsParser {
  final String _jsonText;
  final List<String> _parsePath = [];
  final Map<String, List<String>> _experimentSets = {};

  _AllowedExperimentsParser(this._jsonText);

  AllowedExperiments parse() {
    Object rootObject = json.decode(_jsonText);
    Map<String, Object?> map = _mustBeMap(rootObject);

    _ensureVersion(map);

    _withParsePath('experimentSets', () {
      Map<String, Object?> experimentSetMap =
          _requiredMap(map, 'experimentSets');
      for (MapEntry<String, Object?> entry in experimentSetMap.entries) {
        String setName = entry.key;
        _withParsePath(setName, () {
          _experimentSets[setName] = _mustBeListOfStrings(entry.value);
        });
      }
    });

    List<String> sdkDefaultExperimentSet = <String>[];
    Map<String, List<String>> sdkLibraryExperiments = <String, List<String>>{};
    _withParsePath('sdk', () {
      Map<String, Object?> sdkMap = _requiredMap(map, 'sdk');

      _withParsePath('default', () {
        sdkDefaultExperimentSet = _experimentList(
          _requiredMap(sdkMap, 'default'),
        );
      });

      _withParsePath('libraries', () {
        Map<String, Object?>? sdkLibraryExperimentsMap =
            _optionalMap(sdkMap, 'libraries');
        if (sdkLibraryExperimentsMap != null) {
          for (MapEntry<String, Object?> entry
              in sdkLibraryExperimentsMap.entries) {
            String libraryName = entry.key;
            _withParsePath(libraryName, () {
              Map<String, Object?> libraryMap = _mustBeMap(entry.value);
              List<String> experimentList = _experimentList(libraryMap);
              sdkLibraryExperiments[libraryName] = experimentList;
            });
          }
        }
      });
    });

    Map<String, List<String>> packageExperiments = <String, List<String>>{};
    _withParsePath('packages', () {
      Map<String, Object?>? packageExperimentsMap =
          _optionalMap(map, 'packages');
      if (packageExperimentsMap != null) {
        for (MapEntry<String, Object?> entry in packageExperimentsMap.entries) {
          String packageName = entry.key;
          _withParsePath(packageName, () {
            Map<String, Object?> libraryMap = _mustBeMap(entry.value);
            List<String> experimentList = _experimentList(libraryMap);
            packageExperiments[packageName] = experimentList;
          });
        }
      }
    });

    return new AllowedExperiments(
      sdkDefaultExperiments: sdkDefaultExperimentSet,
      sdkLibraryExperiments: sdkLibraryExperiments,
      packageExperiments: packageExperiments,
    );
  }

  void _ensureVersion(Map<String, Object?> map) {
    Object? versionObject = map['version'];
    if (versionObject is! int || versionObject != 1) {
      throw new FormatException(
        "Expected field 'version' with value '1'; "
        "actually ${versionObject.runtimeType}: $versionObject",
        _jsonText,
      );
    }
  }

  List<String> _experimentList(Map<String, Object?> map) {
    String experimentSetName = _requiredString(map, 'experimentSet');
    List<String>? result = _experimentSets[experimentSetName];
    if (result != null) {
      return result;
    }

    throw new FormatException(
      "No experiment set '$experimentSetName in $_experimentSets",
      _jsonText,
    );
  }

  List<String> _mustBeListOfStrings(Object? object) {
    if (object is List<Object?> && object.every((e) => e is String)) {
      return List.castFrom(object);
    }

    String path = _parsePath.join(' / ');
    throw new FormatException(
      "Expected list of strings at $path, "
      "actually ${object.runtimeType}: $object",
      _jsonText,
    );
  }

  Map<String, Object?> _mustBeMap(Object? object) {
    if (object is Map<String, Object?>) {
      return object;
    }

    String path = _parsePath.isNotEmpty ? _parsePath.join(' / ') : 'root';
    throw new FormatException(
      "Expected map at $path, "
      "actually ${object.runtimeType}: $object",
      _jsonText,
    );
  }

  Map<String, Object?>? _optionalMap(Map<String, Object?> map, String name) {
    Object? result = map[name];
    if (result is Map<String, Object?>?) {
      return result;
    }

    String path = _parsePath.join(' / ');
    throw new FormatException(
      "Expected map at $path, actually ${result.runtimeType}: $result",
      _jsonText,
    );
  }

  Map<String, Object?> _requiredMap(Map<String, Object?> map, String name) {
    Object? result = map[name];
    if (result is Map<String, Object?>) {
      return result;
    }

    String path = _parsePath.join(' / ');
    throw new FormatException(
      "Expected map at $path, actually ${result.runtimeType}: $result",
      _jsonText,
    );
  }

  String _requiredString(Map<String, Object?> map, String name) {
    Object? result = map[name];
    if (result is String) {
      return result;
    }

    String path = _parsePath.join(' / ');
    throw new FormatException(
      "Expected string at $path, actually ${result.runtimeType}: $result",
      _jsonText,
    );
  }

  void _withParsePath(String name, void Function() f) {
    _parsePath.add(name);
    try {
      f();
    } finally {
      _parsePath.removeLast();
    }
  }
}
