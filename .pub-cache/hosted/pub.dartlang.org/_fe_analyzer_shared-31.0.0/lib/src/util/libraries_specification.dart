// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library specification in-memory representation.
///
/// Many dart tools are configurable to support different target platforms.  For
/// a given target, they need to know what libraries are available and where are
/// the sources and target-specific patches.
///
/// Here we define APIs to represent this specification and implement
/// serialization to (and deserialization from) a JSON file.
///
/// Here is an example specification JSON file:
///
///     {
///       "vm": {
///         "libraries": {
///             "core": {
///                "uri": "async/core.dart",
///                "patches": [
///                    "path/to/core_patch.dart",
///                    "path/to/list_patch.dart"
///                ]
///             }
///             "async": {
///                "uri": "async/async.dart",
///                "patches": "path/to/async_patch.dart"
///             }
///             "convert": {
///                "uri": "convert/convert.dart",
///             }
///             "mirrors": {
///                "uri": "mirrors/mirrors.dart",
///                "supported": false
///             }
///         }
///       }
///     }
///
/// The format contains:
///   - a top level entry for each target. Keys are target names (e.g. "vm"
///     above), and values contain the entire specification of a target.
///
///   - each target specification is a map. Today, only one key is supported on
///     this map: "libraries".
///
///   - The "libraries" entry contains details for how each platform library is
///     implemented. The entry is a map, where keys are the name of the platform
///     library and values contain details for where to find the implementation
///     fo that library.
///
///   - The name of the library is a single token (e.g. "core") that matches the
///     Uri path used after `dart:` (e.g. "dart:core").
///
///   - The "uri" entry on the library information is mandatory. The value is a
///     string URI reference. The "patches" entry is optional and may have as a
///     value a string URI reference or a list of URI references.
///
///     All URI references can either be a file URI or a relative URI path,
///     which will be resolved relative to the location of the library
///     specification file.
///
///   - The "supported" entry on the library information is optional. The value
///     is a boolean indicating whether the library is supported in the
///     underlying target.  However, since the libraries are assumed to be
///     supported by default, we only expect users to use `false`.
///
///     The purpose of this value is to configure conditional imports and
///     environment constants. By default every platform library that is
///     available in the "libraries" section implicitly defines an environment
///     variable `dart.library.name` as `"true"`, to indicate that the library
///     is supported.  Some backends allow imports to an unsupported platform
///     library (turning a static error into a runtime error when the library is
///     eventually accessed). These backends can use `supported: false` to
///     report that such library is still not supported in conditional imports
///     and const `fromEnvironment` expressions.
///
///
/// Note: we currently have several different files that need to be updated
/// when changing libraries, sources, and patch files:
///    * .platform files (for dart2js)
///    * .gypi files (for vm)
///    * sdk_library_metadata/lib/libraries.dart (for analyzer, ddc)
///
/// we are in the process of unifying them all under this format (see
/// https://github.com/dart-lang/sdk/issues/28836), but for now we need to pay
/// close attention to change them consistently.

import 'dart:convert' show jsonDecode, jsonEncode;

import 'relativize.dart' show relativizeUri, isWindows;

/// Contents from a single library specification file.
///
/// Contains information about all libraries on all target platforms defined in
/// that file.
class LibrariesSpecification {
  final Map<String, TargetLibrariesSpecification> _targets;

  const LibrariesSpecification(
      [this._targets = const <String, TargetLibrariesSpecification>{}]);

  /// The library specification for a given [target], or throws if none is
  /// available.
  TargetLibrariesSpecification specificationFor(String target) {
    TargetLibrariesSpecification? targetSpec = _targets[target];
    if (targetSpec == null) {
      throw new LibrariesSpecificationException(
          'No library specification for target "$target"');
    }
    return targetSpec;
  }

  /// Parse the given [json] as a library specification, resolving any relative
  /// paths from [baseUri].
  ///
  /// May throw an exception if [json] is not properly formatted or contains
  /// invalid values.
  static LibrariesSpecification parse(Uri baseUri, String? json) {
    if (json == null) return const LibrariesSpecification();
    Map<String, dynamic> jsonData;
    try {
      dynamic data = jsonDecode(json);
      if (data is! Map<String, dynamic>) {
        return _reportError('top-level specification is not a map');
      }
      jsonData = data;
    } on FormatException catch (e) {
      throw new LibrariesSpecificationException(e);
    }
    Map<String, TargetLibrariesSpecification> targets =
        <String, TargetLibrariesSpecification>{};
    jsonData.forEach((String targetName, targetData) {
      if (targetName.startsWith("comment:")) return null;
      Map<String, LibraryInfo> libraries = <String, LibraryInfo>{};
      if (targetData is! Map) {
        _reportError("target specification for '$targetName' is not a map");
      }
      if (!targetData.containsKey("libraries")) {
        _reportError("target specification "
            "for '$targetName' doesn't have a libraries entry");
      }
      dynamic librariesData = targetData["libraries"];
      if (librariesData is! Map<String, dynamic>) {
        _reportError("libraries entry for '$targetName' is not a map");
      }
      librariesData.forEach((String name, data) {
        if (data is! Map<String, dynamic>) {
          _reportError(
              "library data for '$name' in target '$targetName' is not a map");
        }
        Uri checkAndResolve(uriString) {
          if (uriString is! String) {
            return _reportError("uri value '$uriString' is not a string"
                "(from library '$name' in target '$targetName')");
          }
          Uri uri = Uri.parse(uriString);
          if (uri.scheme != '' && uri.scheme != 'file') {
            return _reportError("uri scheme in '$uriString' is not supported.");
          }
          return baseUri.resolveUri(uri);
        }

        Uri uri = checkAndResolve(data['uri']);
        List<Uri> patches;
        if (data['patches'] is List) {
          patches =
              data['patches'].map<Uri>((s) => baseUri.resolve(s)).toList();
        } else if (data['patches'] is String) {
          patches = [checkAndResolve(data['patches'])];
        } else if (data['patches'] == null) {
          patches = const [];
        } else {
          _reportError("patches entry for '$name' is not a list or a string");
        }

        dynamic supported = data['supported'] ?? true;
        if (supported is! bool) {
          _reportError("\"supported\" entry: expected a 'bool' but "
              "got a '${supported.runtimeType}' ('$supported')");
        }
        libraries[name] =
            new LibraryInfo(name, uri, patches, isSupported: supported);
      });
      targets[targetName] =
          new TargetLibrariesSpecification(targetName, libraries);
    });
    return new LibrariesSpecification(targets);
  }

  static Never _reportError(String error) =>
      throw new LibrariesSpecificationException(error);

  /// Serialize this specification to json.
  ///
  /// If possible serializes paths relative to [outputUri].
  String toJsonString(Uri outputUri) => jsonEncode(toJsonMap(outputUri));

  Map toJsonMap(Uri outputUri) {
    Map result = {};
    Uri dir = outputUri.resolve('.');
    String pathFor(Uri uri) => relativizeUri(dir, uri, isWindows);
    _targets.forEach((targetName, target) {
      Map libraries = {};
      target._libraries.forEach((name, lib) {
        libraries[name] = {
          'uri': pathFor(lib.uri),
          'patches': lib.patches.map(pathFor).toList(),
        };
        if (!lib.isSupported) {
          libraries[name]['supported'] = false;
        }
      });
      result[targetName] = {'libraries': libraries};
    });
    return result;
  }
}

/// Specifies information about all libraries supported by a given target.
class TargetLibrariesSpecification {
  /// Name of the target platform.
  final String targetName;

  final Map<String, LibraryInfo> _libraries;

  const TargetLibrariesSpecification(this.targetName,
      [this._libraries = const <String, LibraryInfo>{}]);

  /// Details about a library whose import is `dart:$name`.
  LibraryInfo? libraryInfoFor(String name) => _libraries[name];

  Iterable<LibraryInfo> get allLibraries => _libraries.values;
}

/// Information about a `dart:` library in a specific target platform.
class LibraryInfo {
  /// The name of the library, which is the path developers use to import this
  /// library (as `dart:$name`).
  final String name;

  /// The file defining the main implementation of the library.
  final Uri uri;

  /// Patch files used for this library in the target platform, if any.
  final List<Uri> patches;

  /// Whether the library is supported and thus `dart.library.name` is "true"
  /// for conditional imports and fromEnvironment constants.
  final bool isSupported;

  const LibraryInfo(this.name, this.uri, this.patches,
      {this.isSupported: true});

  /// The import uri for the defined library.
  Uri get importUri => Uri.parse('dart:${name}');
}

class LibrariesSpecificationException {
  Object error;
  LibrariesSpecificationException(this.error);

  @override
  String toString() => '$error';
}
