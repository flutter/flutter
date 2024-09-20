// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library builtin;

import 'dart:async';
import 'dart:collection' hide LinkedList, LinkedListEntry;
import 'dart:_internal' hide Symbol;
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

// Embedder sets this to true if the --trace-loading flag was passed on the
// command line.
bool _traceLoading = false;

// Before handling an embedder entrypoint we finalize the setup of the
// dart:_builtin library.
bool _setupCompleted = false;

// 'print' implementation.
// The standalone embedder registers the closurized _print function with the
// dart:core library.
@pragma("vm:external-name", "Builtin_PrintString")
external void _printString(String s);

void _print(arg) {
  _printString(arg.toString());
}

@pragma("vm:entry-point")
_getPrintClosure() => _print;

// The current working directory when the embedder was launched.
late Uri _workingDirectory;

// The URI that the root script was loaded from. Remembered so that
// package imports can be resolved relative to it. The root script is the basis
// for the root library in the VM.
Uri? _rootScript;

// packagesConfig specified for the isolate.
Uri? _packagesConfigUri;

// Packages are either resolved looking up in a map or resolved from within a
// package root.
bool get _packagesReady => (_packageMap != null) || (_packageError != null);

// Error string set if there was an error resolving package configuration.
// For example not finding a .packages file or packages/ directory, malformed
// .packages file or any other related error.
String? _packageError = null;

// The map describing how certain package names are mapped to Uris.
Uri? _packageConfig = null;
Map<String, Uri>? _packageMap = null;

// Special handling for Windows paths so that they are compatible with URI
// handling.
// Embedder sets this to true if we are running on Windows.
@pragma("vm:entry-point")
bool _isWindows = false;

// Logging from builtin.dart is prefixed with a '*'.
String _logId = (Isolate.current.hashCode % 0x100000).toRadixString(16);
_log(msg) {
  _print("* $_logId $msg");
}

_sanitizeWindowsPath(path) {
  // For Windows we need to massage the paths a bit according to
  // http://blogs.msdn.com/b/ie/archive/2006/12/06/file-uris-in-windows.aspx
  //
  // Convert
  // C:\one\two\three
  // to
  // /C:/one/two/three

  if (_isWindows == false) {
    // Do nothing when not running Windows.
    return path;
  }

  var fixedPath = "${path.replaceAll('\\', '/')}";

  if ((path.length > 2) && (path[1] == ':')) {
    // Path begins with a drive letter.
    return '/$fixedPath';
  }

  return fixedPath;
}

_setPackagesConfig(String packagesParam) {
  var packagesName = _sanitizeWindowsPath(packagesParam);
  var packagesUri = Uri.parse(packagesName);
  if (!packagesUri.hasScheme) {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    packagesUri = _workingDirectory.resolveUri(packagesUri);
  }
  _packagesConfigUri = packagesUri;
}

// Given a uri with a 'package' scheme, return a Uri that is prefixed with
// the package root or resolved relative to the package configuration.
Uri _resolvePackageUri(Uri uri) {
  assert(uri.isScheme("package"));
  assert(_packagesReady);

  if (uri.host.isNotEmpty) {
    var path = '${uri.host}${uri.path}';
    var right = 'package:$path';
    var wrong = 'package://$path';

    throw "URIs using the 'package:' scheme should look like "
        "'$right', not '$wrong'.";
  }

  var packageNameEnd = uri.path.indexOf('/');
  if (packageNameEnd == 0) {
    // Package URIs must have a non-empty package name (not start with "/").
    throw "URIS using the 'package:' scheme should look like "
        "'package:packageName${uri.path}', not 'package:${uri.path}'";
  }
  if (_traceLoading) {
    _log('Resolving package with uri path: ${uri.path}');
  }
  var resolvedUri;
  final error = _packageError;
  if (error != null) {
    if (_traceLoading) {
      _log("Resolving package with pending resolution error: $error");
    }
    throw error;
  } else {
    if (packageNameEnd < 0) {
      // Package URIs must have a path after the package name, even if it's
      // just "/".
      throw "URIS using the 'package:' scheme should look like "
          "'package:${uri.path}/', not 'package:${uri.path}'";
    }
    var packageName = uri.path.substring(0, packageNameEnd);
    final mapping = _packageMap![packageName];
    if (_traceLoading) {
      _log("Mapped '$packageName' package to '$mapping'");
    }
    if (mapping == null) {
      throw "No mapping for '$packageName' package when resolving '$uri'.";
    }
    var path;
    assert(uri.path.length > packageName.length);
    path = uri.path.substring(packageName.length + 1);
    if (_traceLoading) {
      _log("Path to be resolved in package: $path");
    }
    resolvedUri = mapping.resolve(path);
  }
  if (_traceLoading) {
    _log("Resolved '$uri' to '$resolvedUri'.");
  }
  return resolvedUri;
}

void _requestPackagesMap(Uri? packageConfig) {
  dynamic msg = null;
  if (packageConfig != null) {
    // Explicitly specified .packages path.
    msg = _handlePackagesRequest(_traceLoading, -2, packageConfig);
  } else {
    // Search for .packages starting at the root script.
    msg = _handlePackagesRequest(_traceLoading, -1, _rootScript!);
  }
  if (_traceLoading) {
    _log("Requested packages map for '$_rootScript'.");
  }
  if (msg is String) {
    if (_traceLoading) {
      _log("Got failure response on package port: '$msg'");
    }
    // Remember the error message.
    _packageError = msg;
  } else if (msg is List) {
    // First entry contains the location of the loaded .packages file.
    assert((msg.length % 2) == 0);
    assert(msg.length >= 2);
    assert(msg[1] == null);
    _packageConfig = Uri.parse(msg[0]);
    final pmap = new Map<String, Uri>();
    _packageMap = pmap;
    for (var i = 2; i < msg.length; i += 2) {
      // TODO(iposva): Complain about duplicate entries.
      pmap[msg[i]] = Uri.parse(msg[i + 1]);
    }
    if (_traceLoading) {
      _log("Setup package map: $_packageMap");
    }
  } else {
    _packageError = "Bad type of packages reply: ${msg.runtimeType}";
    if (_traceLoading) {
      _log(_packageError);
    }
  }
}

// The values go from ' ' to DEL and `x` means disallowed.
const String _invalidPackageNameChars =
    'x.xx.x.........x..........x.x.xx...........................xxxx.x..........................xxx.x';

bool _isValidPackageName(String packageName) {
  const space = 0x20;
  const del = 0x7F;
  const dot = 0x2e;
  const lowerX = 0x78;
  for (int i = 0; i < packageName.length; ++i) {
    final int char = packageName.codeUnitAt(i);
    if (char < space || del < char) {
      return false;
    }
    final int allowed = _invalidPackageNameChars.codeUnitAt(char - space);
    assert(allowed == dot || allowed == lowerX);
    if (allowed == lowerX) {
      return false;
    }
  }
  return true;
}

_parsePackagesFile(bool traceLoading, Uri packagesFile, String data) {
  // The first entry contains the location of the identified .packages file
  // instead of a mapping.
  final List result = [packagesFile.toString(), null];

  final lines = LineSplitter.split(data);
  for (String line in lines) {
    final hashIndex = line.indexOf('#');
    if (hashIndex == 0) {
      continue;
    }
    if (hashIndex > 0) {
      line = line.substring(0, hashIndex);
    }
    line = line.trimRight();
    if (line.isEmpty) {
      continue;
    }

    final colonIndex = line.indexOf(':');
    if (colonIndex <= 0) {
      return 'Line in "$packagesFile" should be of the format '
          '`<package-name>:<path>" but was: "$line"';
    }
    final packageName = line.substring(0, colonIndex);
    if (!_isValidPackageName(packageName)) {
      return 'Package name in $packagesFile contains disallowed characters ('
          'was: "$packageName")';
    }

    String packageUri = line.substring(colonIndex + 1);
    if (traceLoading) {
      _log("packageName: $packageName");
      _log("packageUri: $packageUri");
    }
    // Ensure the package uri ends with a /.
    if (!packageUri.endsWith('/')) {
      packageUri += '/';
    }
    final resolvedPackageUri = packagesFile.resolve(packageUri).toString();
    if (traceLoading) {
      _log("mapping: $packageName -> $resolvedPackageUri");
    }
    result.add(packageName);
    result.add(resolvedPackageUri);
  }
  if (traceLoading) {
    _log("Parsed packages file at $packagesFile. Sending:\n$result");
  }
  return result;
}

// The .dart_tool/package_config.json format is described in
//
// https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/package-config-file-v2.md
//
// The returned list has the format:
//
//    [0] Location of package_config.json file.
//    [1] null
//    [n*2] Name of n-th package
//    [n*2 + 1] Location of n-th package's sources (as a String)
//
List _parsePackageConfig(bool traceLoading, Uri packageConfig, String data) {
  final Map packageJson = json.decode(data);
  final version = packageJson['configVersion'];
  if (version != 2) {
    throw 'The package configuration file has an unsupported version.';
  }
  // The first entry contains the location of the identified
  // .dart_tool/package_config.json file instead of a mapping.
  final result = <dynamic>[packageConfig.toString(), null];
  final List packages = packageJson['packages'] ?? [];
  for (final Map package in packages) {
    String rootUri = package['rootUri'];
    if (!rootUri.endsWith('/')) rootUri += '/';
    final String packageName = package['name'];
    final String? packageUri = package['packageUri'];
    final Uri resolvedRootUri = packageConfig.resolve(rootUri);
    final Uri resolvedPackageUri = packageUri != null
        ? resolvedRootUri.resolve(packageUri)
        : resolvedRootUri;
    if (packageUri != null &&
        !'$resolvedPackageUri'.contains('$resolvedRootUri')) {
      throw 'The resolved "packageUri" is not a subdirectory of the "rootUri".';
    }
    if (!_isValidPackageName(packageName)) {
      throw 'Package name in $packageConfig contains disallowed characters ('
          'was: "$packageName")';
    }
    result.add(packageName);
    result.add(resolvedPackageUri.toString());
    if (traceLoading) {
      _log('Resolved package "$packageName" to be at $resolvedPackageUri');
    }
  }
  return result;
}

_findPackagesConfiguration(bool traceLoading, Uri base) {
  try {
    // Walk up the directory hierarchy to check for the existence of either one
    // of
    //   - .packages (preferred)
    //   - .dart_tool/package_config.json
    var currentDir = new File.fromUri(base).parent;
    while (true) {
      final dirUri = currentDir.uri;

      // We prefer using `.dart_tool/package_config.json` over `.packages`.
      final packageConfig = dirUri.resolve(".dart_tool/package_config.json");
      if (traceLoading) {
        _log("Checking for $packageConfig file.");
      }
      File file = File.fromUri(packageConfig);
      bool exists = file.existsSync();
      if (traceLoading) {
        _log("$packageConfig exists: $exists");
      }
      if (exists) {
        final data = utf8.decode(file.readAsBytesSync());
        if (traceLoading) {
          _log("Loaded package config file from $packageConfig:$data\n");
        }
        return _parsePackageConfig(traceLoading, packageConfig, data);
      }

      // We fallback to using `.packages` if it exists.
      final packagesFile = dirUri.resolve(".packages");
      if (traceLoading) {
        _log("Checking for $packagesFile file.");
      }
      file = File.fromUri(packagesFile);
      exists = file.existsSync();
      if (traceLoading) {
        _log("$packagesFile exists: $exists");
      }
      if (exists) {
        final String data = utf8.decode(file.readAsBytesSync());
        if (traceLoading) {
          _log("Loaded packages file from $packagesFile:\n$data");
        }
        return _parsePackagesFile(traceLoading, packagesFile, data);
      }

      final parentDir = currentDir.parent;
      if (dirUri == parentDir.uri) break;
      currentDir = parentDir;
    }

    if (traceLoading) {
      _log("Could not resolve a package configuration from $base");
    }
    return "Could not resolve a package configuration for base at $base";
  } catch (e, s) {
    if (traceLoading) {
      _log("Error loading packages: $e\n$s");
    }
    return "Uncaught error ($e) loading packages file.";
  }
}

int _indexOfFirstNonWhitespaceCharacter(String data) {
  // Whitespace characters ignored in JSON spec:
  // https://tools.ietf.org/html/rfc7159
  const tab = 0x09;
  const lf = 0x0A;
  const cr = 0x0D;
  const space = 0x20;

  int index = 0;
  while (index < data.length) {
    final int char = data.codeUnitAt(index);
    if (char != lf && char != cr && char != space && char != tab) {
      break;
    }
    index++;
  }
  return index;
}

bool _canBeValidJson(String data) {
  const int openCurly = 0x7B;
  final int index = _indexOfFirstNonWhitespaceCharacter(data);
  return index < data.length && data.codeUnitAt(index) == openCurly;
}

_parsePackageConfiguration(bool traceLoading, Uri resource, Uint8List bytes) {
  try {
    final data = utf8.decode(bytes);
    if (_canBeValidJson(data)) {
      return _parsePackageConfig(traceLoading, resource, data);
    } else {
      return _parsePackagesFile(traceLoading, resource, data);
    }
  } catch (e) {
    return "The resource '$resource' is neither a valid '.packages' file nor "
        "a valid '.dart_tool/package_config.json' file.";
  }
}

bool _isValidUtf8DataUrl(UriData data) {
  final mime = data.mimeType;
  if (mime != "text/plain") {
    return false;
  }
  final charset = data.charset;
  if (charset != "utf-8" && charset != "US-ASCII") {
    return false;
  }
  return true;
}

_handlePackagesRequest(bool traceLoading, int tag, Uri resource) {
  try {
    if (tag == -1) {
      if (!resource.hasScheme || resource.isScheme('file')) {
        return _findPackagesConfiguration(traceLoading, resource);
      } else {
        return "Unsupported scheme used to locate .packages file:'$resource'.";
      }
    } else if (tag == -2) {
      if (traceLoading) {
        _log("Handling load of packages map: '$resource'.");
      }
      late Uint8List bytes;
      if (!resource.hasScheme || resource.isScheme('file')) {
        final file = File.fromUri(resource);
        if (!file.existsSync()) {
          return "Packages file '$resource' does not exit.";
        }
        bytes = file.readAsBytesSync();
      } else if (resource.isScheme('data')) {
        final uriData = resource.data!;
        if (!_isValidUtf8DataUrl(uriData)) {
          return "The data resource '$resource' must have a 'text/plain' mime "
              "type and a 'utf-8' or 'US-ASCII' charset.";
        }
        bytes = uriData.contentAsBytes();
      } else {
        return "Unknown scheme (${resource.scheme}) for package file at "
            "'$resource'.";
      }
      return _parsePackageConfiguration(traceLoading, resource, bytes);
    } else {
      return "Unknown packages request tag: $tag for '$resource'.";
    }
  } catch (e, s) {
    if (traceLoading) {
      _log("Error handling packages request: $e\n$s");
    }
    return "Uncaught error ($e) handling packages request.";
  }
}

// Embedder Entrypoint:
// The embedder calls this method to initial the package resolution state.
@pragma("vm:entry-point")
void _Init(
    String? packagesConfig, String workingDirectory, String? rootScript) {
  // Register callbacks and hooks with the rest of core libraries.
  _setupHooks();

  // _workingDirectory must be set first.
  _workingDirectory = new Uri.directory(workingDirectory);

  // setup _rootScript.
  if (rootScript != null) {
    _rootScript = Uri.parse(rootScript);
  }

  // If the --packages flag was passed, setup _packagesConfig.
  if (packagesConfig != null) {
    _packageMap = null;
    _setPackagesConfig(packagesConfig);
  }
}

// Embedder Entrypoint:
// The embedder calls this method with the current working directory.
@pragma("vm:entry-point")
void _setWorkingDirectory(String cwd) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  if (_traceLoading) {
    _log('Setting working directory: $cwd');
  }
  _workingDirectory = new Uri.directory(cwd);
  if (_traceLoading) {
    _log('Working directory URI: $_workingDirectory');
  }
}

// Embedder Entrypoint:
// The embedder calls this method with the value of the --packages command line
// option. It can point to a ".packages" or a ".dart_tool/package_config.json"
// file.
@pragma("vm:entry-point")
String _setPackagesMap(String packagesParam) {
  if (!_setupCompleted) {
    _setupHooks();
  }
  // First convert the packages parameter from the command line to a URI which
  // can be handled by the loader code.
  // TODO(iposva): Consider refactoring the common code below which is almost
  // shared with resolution of the root script.
  if (_traceLoading) {
    _log("Resolving packages map: $packagesParam");
  }
  if (_workingDirectory == null) {
    throw 'No current working directory set.';
  }
  var packagesName = _sanitizeWindowsPath(packagesParam);
  var packagesUri = Uri.parse(packagesName);
  if (!packagesUri.hasScheme) {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    packagesUri = _workingDirectory.resolveUri(packagesUri);
  }
  var packagesUriStr = packagesUri.toString();
  VMLibraryHooks.packageConfigString = packagesUriStr;
  if (_traceLoading) {
    _log('Resolved packages map to: $packagesUri');
  }
  return packagesUriStr;
}

// Resolves the script uri in the current working directory iff the given uri
// did not specify a scheme (e.g. a path to a script file on the command line).
@pragma("vm:entry-point")
String _resolveScriptUri(String scriptName) {
  if (_traceLoading) {
    _log("Resolving script: $scriptName");
  }
  if (_workingDirectory == null) {
    throw 'No current working directory set.';
  }
  scriptName = _sanitizeWindowsPath(scriptName);

  var scriptUri = Uri.parse(scriptName);
  if (!scriptUri.hasScheme) {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    scriptUri = _workingDirectory.resolveUri(scriptUri);
  }

  // Remember the root script URI so that we can resolve packages based on
  // this location.
  _rootScript = scriptUri;

  if (_traceLoading) {
    _log('Resolved entry point to: $_rootScript');
  }
  return scriptUri.toString();
}

// Register callbacks and hooks with the rest of the core libraries.
@pragma("vm:entry-point")
_setupHooks() {
  _setupCompleted = true;
  VMLibraryHooks.packageConfigUriSync = _getPackageConfigSync;
  VMLibraryHooks.resolvePackageUriSync = _resolvePackageUriSync;
}

Uri? _getPackageConfigSync() {
  if (_traceLoading) {
    _log("Request for package config from user code.");
  }
  if (!_packagesReady) {
    _requestPackagesMap(_packagesConfigUri);
  }
  // Respond with the packages config (if any) after package resolution.
  return _packageConfig;
}

Uri? _resolvePackageUriSync(Uri packageUri) {
  if (_traceLoading) {
    _log("Request for package Uri resolution from user code: $packageUri");
  }
  if (!packageUri.isScheme("package")) {
    if (_traceLoading) {
      _log("Non-package Uri, returning unmodified: $packageUri");
    }
    // Return the incoming parameter if not passed a package: URI.
    return packageUri;
  }
  if (!_packagesReady) {
    _requestPackagesMap(_packagesConfigUri);
  }
  Uri? resolvedUri;
  try {
    resolvedUri = _resolvePackageUri(packageUri);
  } catch (e, s) {
    if (_traceLoading) {
      _log("Exception when resolving package URI: $packageUri:\n$e\n$s");
    }
    resolvedUri = null;
  }
  if (_traceLoading) {
    _log("Resolved '$packageUri' to '$resolvedUri'");
  }
  return resolvedUri;
}
