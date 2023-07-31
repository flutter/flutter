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
///   - each target specification is a map. The supported keys are "libraries"
///     and "include".
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
///     Internal libraries are never supported through conditional imports and
///     const `fromEnvironment` expressions.
///
///   - The "include" entry is a list of maps, each containing either a "path"
///     and a "target" entry, or only a "target" entry.
///
///     If both "path" and "target" entries are present, the libraries
///     specification file located at "path", relative to the location current
///     libraries specification file is loaded, and the libraries defined
///     in the target with the target name of the "target" entry are included in
///     this target.
///
///     If only the "target" is present, the libraries in the target in the
///     current libraries specification file with the target name of the
///     "target" entry are included in this target.
///
///     The "include" mechanism support transitive inclusion but doesn't allow
///     cyclic dependencies.
///
///     If the same library is defined in multiple included target
///     specifications, the last included takes precedence. This means that
///     if a target specification include a library and also defines it itself,
///     the latter is used.
///
///     Currently it is not supported to include a subset of the libraries from
///     an included target specifications.
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
  final Uri specUri;
  final Map<String, TargetLibrariesSpecification> _targets;

  const LibrariesSpecification(this.specUri,
      [this._targets = const <String, TargetLibrariesSpecification>{}]);

  /// The library specification for a given [target], or throws if none is
  /// available.
  TargetLibrariesSpecification specificationFor(String target) {
    TargetLibrariesSpecification? targetSpec = _targets[target];
    if (targetSpec == null) {
      throw new LibrariesSpecificationException(
          messageMissingTarget(target, specUri));
    }
    return targetSpec;
  }

  static Future<LibrariesSpecification> load(
      Uri uri, Future<String> Function(Uri uri) read) {
    Map<Uri, LibrariesSpecification?> cache = {};
    Future<LibrariesSpecification> loadSpecification(Uri uri) async {
      if (cache.containsKey(uri)) {
        LibrariesSpecification? specification = cache[uri];
        if (specification == null) {
          throw new LibrariesSpecificationException(messageCyclicSpec(uri));
        }
        return specification;
      }
      cache[uri] = null;
      String json;
      try {
        json = await read(uri);
      } catch (e) {
        throw new LibrariesSpecificationException(
            messageIncludePathCouldNotBeRead(uri, e));
      }
      return cache[uri] =
          await LibrariesSpecification.parse(uri, json, loadSpecification);
    }

    return loadSpecification(uri);
  }

  /// Parse the given [json] as a library specification, resolving any relative
  /// paths from [specUri].
  ///
  /// May throw an exception if [json] is not properly formatted or contains
  /// invalid values.
  static Future<LibrariesSpecification> parse(
      Uri specUri,
      String? json,
      Future<LibrariesSpecification> Function(Uri uri)
          loadSpecification) async {
    if (json == null) return new LibrariesSpecification(specUri);
    Map<String, dynamic> jsonData;
    try {
      dynamic data = jsonDecode(json);
      if (data is! Map<String, dynamic>) {
        return _reportError(messageTopLevelIsNotAMap(specUri));
      }
      jsonData = data;
    } on FormatException catch (e) {
      throw new LibrariesSpecificationException(e);
    }
    Map<String, TargetLibrariesSpecification> targets =
        <String, TargetLibrariesSpecification>{};

    Set<String> currentTargets = {};

    Future<TargetLibrariesSpecification> resolveTargetData(
        String targetName) async {
      TargetLibrariesSpecification? spec = targets[targetName];
      if (spec != null) {
        return spec;
      }
      if (currentTargets.contains(targetName)) {
        _reportError(messageCyclicInternalInclude(targetName, specUri));
      }

      currentTargets.add(targetName);
      Map<String, LibraryInfo> libraries = <String, LibraryInfo>{};
      Object? targetData = jsonData[targetName];
      if (targetData is! Map) {
        _reportError(messageTargetIsNotAMap(targetName, specUri));
      }

      Object? include = targetData["include"];
      if (include != null) {
        if (include is! List) {
          _reportError(messageIncludeIsNotAList(targetName, specUri));
        }
        for (Object? map in include) {
          if (map is! Map<String, dynamic>) {
            _reportError(messageIncludeEntryIsNotAMap(targetName, specUri));
          }
          if (!map.containsKey("target")) {
            _reportError(messageIncludeTargetMissing(targetName, specUri));
          }
          Object? target = map["target"];
          if (target is! String) {
            _reportError(messageIncludeTargetIsNotAString(targetName, specUri));
          }
          if (!map.containsKey("path")) {
            if (!jsonData.containsKey(target)) {
              _reportError(messageMissingTarget(target, specUri));
            }
            TargetLibrariesSpecification targetLibrariesSpecification =
                await resolveTargetData(target);
            libraries.addAll(targetLibrariesSpecification._libraries);
          } else {
            Object? path = map["path"];
            if (path is! String) {
              _reportError(messageIncludePathIsNotAString(targetName, specUri));
            }
            Uri uri = Uri.parse(path);
            if (uri.hasScheme && !uri.isScheme('file')) {
              return _reportError(messageUnsupportedUriScheme(path, specUri));
            }
            LibrariesSpecification specification =
                await loadSpecification(specUri.resolveUri(uri));
            TargetLibrariesSpecification targetSpecification =
                specification.specificationFor(target);
            for (LibraryInfo libraryInfo in targetSpecification.allLibraries) {
              libraries[libraryInfo.name] = libraryInfo;
            }
          }
        }
      }
      if (!targetData.containsKey("libraries")) {
        _reportError(messageTargetLibrariesMissing(targetName, specUri));
      }
      Object? librariesData = targetData["libraries"];
      if (librariesData is! Map<String, dynamic>) {
        _reportError(messageLibrariesEntryIsNotAMap(targetName, specUri));
      }
      librariesData.forEach((String libraryName, Object? data) {
        if (data is! Map<String, dynamic>) {
          _reportError(
              messageLibraryDataIsNotAMap(libraryName, targetName, specUri));
        }
        Uri checkAndResolve(Object? uriString) {
          if (uriString is! String) {
            return _reportError(messageLibraryUriIsNotAString(
                uriString, libraryName, targetName, specUri));
          }
          Uri uri = Uri.parse(uriString);
          if (uri.hasScheme && !uri.isScheme('file')) {
            return _reportError(
                messageUnsupportedUriScheme(uriString, specUri));
          }
          return specUri.resolveUri(uri);
        }

        if (!data.containsKey('uri')) {
          _reportError(
              messageLibraryUriMissing(libraryName, targetName, specUri));
        }
        Uri uri = checkAndResolve(data['uri']);
        List<Uri> patches;
        if (data['patches'] is List) {
          patches =
              data['patches'].map<Uri>((s) => specUri.resolve(s)).toList();
        } else if (data['patches'] is String) {
          patches = [checkAndResolve(data['patches'])];
        } else if (data['patches'] == null) {
          patches = const [];
        } else {
          _reportError(messagePatchesMustBeListOrString(libraryName));
        }

        dynamic supported = data['supported'] ?? true;
        if (supported is! bool) {
          _reportError(messageSupportedIsNotABool(supported));
        }
        libraries[libraryName] = new LibraryInfo(libraryName, uri, patches,
            // Internal libraries are never supported through conditional
            // imports and const `fromEnvironment` expressions.
            isSupported: supported && !libraryName.startsWith('_'));
      });
      currentTargets.remove(targetName);
      return targets[targetName] =
          new TargetLibrariesSpecification(targetName, libraries);
    }

    for (String targetName in jsonData.keys) {
      if (targetName.startsWith("comment:")) {
        continue;
      }
      await resolveTargetData(targetName);
    }
    return new LibrariesSpecification(specUri, targets);
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
      {this.isSupported = true});

  /// The import uri for the defined library.
  Uri get importUri => Uri.parse('dart:${name}');
}

class LibrariesSpecificationException {
  Object error;
  LibrariesSpecificationException(this.error);

  @override
  String toString() => '$error';
}

String messageMissingTarget(String targetName, Uri specUri) =>
    'No library specification for target "$targetName" in ${specUri}.';

String messageCyclicSpec(Uri specUri) => 'Cyclic dependency in ${specUri}.';

String messageCyclicInternalInclude(String targetName, Uri specUri) =>
    'Cyclic dependency of target "$targetName" in ${specUri}.';

String messageTopLevelIsNotAMap(Uri specUri) =>
    'Top-level specification is not a map in ${specUri}.';

String messageTargetIsNotAMap(String targetName, Uri specUri) =>
    'Target specification for "$targetName" is not a map in $specUri.';

String messageIncludeIsNotAList(String targetName, Uri specUri) =>
    '"include" specification for "$targetName" is not a list in $specUri.';

String messageIncludeEntryIsNotAMap(String targetName, Uri specUri) =>
    '"include" entry in "$targetName" is not a map in $specUri.';

String messageIncludePathIsNotAString(String targetName, Uri specUri) =>
    '"include" path in "$targetName" is not a string in  $specUri.';

String messageIncludePathCouldNotBeRead(Uri includeUri, Object error) =>
    '"include" path \'$includeUri\' could not be read: $error';

String messageIncludeTargetMissing(String targetName, Uri specUri) =>
    '"include" target in "$targetName" is missing in $specUri.';

String messageIncludeTargetIsNotAString(String targetName, Uri specUri) =>
    '"include" target in "$targetName" is not a string in $specUri.';

String messageTargetLibrariesMissing(String targetName, Uri specUri) =>
    'Target specification '
    'for "$targetName" doesn\'t have a libraries entry in $specUri.';

String messageLibrariesEntryIsNotAMap(String targetName, Uri specUri) =>
    '"libraries" entry for "$targetName" is not a map in $specUri.';

String messageLibraryDataIsNotAMap(
        String libraryName, String targetName, Uri specUri) =>
    'Library data for \'$libraryName\' in target "$targetName" is not a map '
    'in $specUri.';

String messageLibraryUriMissing(
        String libraryName, String targetName, Uri specUri) =>
    '"uri" is missing '
    'from library \'$libraryName\' in target "$targetName" in $specUri.';

String messageLibraryUriIsNotAString(
        Object? uriValue, String libraryName, String targetName, Uri specUri) =>
    'Uri value `$uriValue` is not a string '
    '(from library \'$libraryName\' in target "$targetName" in $specUri).';

String messageUnsupportedUriScheme(String uriValue, Uri specUri) =>
    "Uri scheme in '$uriValue' is not supported in $specUri.";

String messagePatchesMustBeListOrString(String libraryName) =>
    '"patches" entry for "$libraryName" is not a list or a string.';

String messageSupportedIsNotABool(Object supportedValue) =>
    '"supported" entry: expected a `bool` but '
    'got a `${supportedValue.runtimeType}` ("$supportedValue").';
