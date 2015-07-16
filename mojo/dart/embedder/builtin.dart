// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library mojo_builtin;

import 'dart:async';
import 'dart:convert';
import 'dart:mojo.internal';

// import 'root_library'; happens here from C Code

// The root library (aka the script) is imported into this library. The
// embedder uses this to lookup the main entrypoint in the root library's
// namespace.
Function _getMainClosure() => main;

// Corelib 'print' implementation.
void _print(arg) {
  _Logger._printString(arg.toString());
}

class _Logger {
  static void _printString(String s) native "Logger_PrintString";
}

_getPrintClosure() => _print;

const _logBuiltin = false;

Uri _uriBase() {
  return _entryPointScript.resolve('.');
}
_getUriBaseClosure() => _uriBase;

// The current working directory
var _workingDirectoryUri;
// The URI that the entry point script was loaded from. Remembered so that
// package imports can be resolved relative to it.
var _entryPointScript;
// The directory to look in to resolve "package:" scheme URIs.
var _packageRoot;

_setupHooks() {
  VMLibraryHooks.eventHandlerSendData = MojoHandleWatcher.timer;
}

_enforceTrailingSlash(uri) {
  // Ensure we have a trailing slash character.
  if (!uri.endsWith('/')) {
    return '$uri/';
  }
  return uri;
}

void _setWorkingDirectory(cwd) {
  cwd = _enforceTrailingSlash(cwd);
  _workingDirectoryUri = new Uri(scheme: 'file', path: cwd);
  if (_logBuiltin) {
    _print('# Working Directory: $cwd');
  }
}

_setPackageRoot(String packageRoot) {
  packageRoot = _enforceTrailingSlash(packageRoot);

  if (packageRoot.startsWith('file:') ||
      packageRoot.startsWith('http:') ||
      packageRoot.startsWith('https:')) {
    _packageRoot = _workingDirectoryUri.resolve(packageRoot);
  } else {
    _packageRoot = _workingDirectoryUri.resolveUri(new Uri.file(packageRoot));
  }
  if (_logBuiltin) {
    _print('# Package root: $packageRoot -> $_packageRoot');
  }
}

String _resolveScriptUri(String scriptName) {
  if (_workingDirectoryUri == null) {
    throw 'No current working directory set.';
  }

  var scriptUri = Uri.parse(scriptName);
  if (scriptUri.scheme != '') {
    // Script has a scheme, assume that it is fully formed.
    _entryPointScript = scriptUri;
  } else {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    _entryPointScript = _workingDirectoryUri.resolve(scriptName);
  }
  if (_logBuiltin) {
    _print('# Resolved entry point to: $_entryPointScript');
  }
  return _entryPointScript.toString();
}

const _DART_EXT = 'dart-ext:';

String _resolveUri(String base, String userString) {
  if (_logBuiltin) {
    _print('# Resolving: $userString from $base');
  }
  var baseUri = Uri.parse(base);
  if (userString.startsWith(_DART_EXT)) {
    var uri = userString.substring(_DART_EXT.length);
    return '$_DART_EXT${baseUri.resolve(uri)}';
  } else {
    return baseUri.resolve(userString).toString();
  }
}

Uri _resolvePackageUri(Uri uri) {
  if (!uri.host.isEmpty) {
    var path = '${uri.host}${uri.path}';
    var right = 'package:$path';
    var wrong = 'package://$path';

    throw "URIs using the 'package:' scheme should look like "
        "'$right', not '$wrong'.";
  }

  var packageRoot = _packageRoot == null
      ? _entryPointScript.resolve('packages/')
      : _packageRoot;
  return packageRoot.resolve(uri.path);
}

int _numOutstandingLoadRequests = 0;

// TODO(zra): Enable loading libraries over http.
// void _httpGet(Uri uri, String libraryUri, loadCallback(List<int> data)) {
// }

void _signalDoneLoading() native "Builtin_DoneLoading";

void _loadScriptCallback(int tag, String uri, String libraryUri,
    List<int> data) native "Builtin_LoadScript";

void _loadScript(int tag, String uri, String libraryUri, List<int> data) {
  _loadScriptCallback(tag, uri, libraryUri, data);
  assert(_numOutstandingLoadRequests > 0);
  _numOutstandingLoadRequests--;
  if (_logBuiltin) {
    _print("native Builtin_LoadScript($uri) completed, "
        "${_numOutstandingLoadRequests} requests remaining");
  }
  if (_numOutstandingLoadRequests == 0) {
    _signalDoneLoading();
  }
}

void _asyncLoadErrorCallback(
    uri, libraryUri, error) native "Builtin_AsyncLoadError";

void _asyncLoadError(uri, libraryUri, error) {
  assert(_numOutstandingLoadRequests > 0);
  if (_logBuiltin) {
    _print("_asyncLoadError($uri), error: $error");
  }
  _numOutstandingLoadRequests--;
  _asyncLoadErrorCallback(uri, libraryUri, error);
  if (_numOutstandingLoadRequests == 0) {
    _signalDoneLoading();
  }
}

// Create a Uri of 'userUri'. If the input uri is a package uri, then the
// package uri is resolved.
Uri _createUri(String userUri) {
  var uri = Uri.parse(userUri);
  if (_logBuiltin) {
    _print('# Creating uri for: $uri');
  }

  // TODO(zra): Except for the special handling for package:, URI's should just
  // be sent to the network stack to resolve.
  switch (uri.scheme) {
    case '':
    case 'file':
    case 'http':
    case 'https':
      return uri;
    case 'package':
      return _resolvePackageUri(uri);
    default:
      // Only handling file, http[s], and package URIs
      // in standalone binary.
      if (_logBuiltin) {
        _print('# Unknown scheme (${uri.scheme}) in $uri.');
      }
      throw 'Not a known scheme: $uri';
  }
}

// TODO(zra): readSync and enumerateFiles are exposed for testing purposes only.
// Eventually, there will be different builtin libraries for testing and
// production(i.e. the content handler). In the content handler's builtin
// library, File IO capabilities will be removed.
// This uses the synchronous base::ReadFileToString exposed by Mojo.
List<int> readSync(String uri) native "Builtin_ReadSync";

// This uses base::FileEnumerator.
List<String> enumerateFiles(String path) native "Builtin_EnumerateFiles";

// Asynchronously loads script data through a http[s] or file uri.
_loadDataAsync(int tag, String uri, String libraryUri, List<int> source) {
  if (tag == null) {
    uri = _resolveScriptUri(uri);
  }
  Uri resourceUri = _createUri(uri);
  _numOutstandingLoadRequests++;
  if (_logBuiltin) {
    _print("_loadDataAsync($uri), "
        "${_numOutstandingLoadRequests} requests outstanding");
  }
  if (source != null) {
    _loadScript(tag, uri, libraryUri, source);
    return;
  }
  if ((resourceUri.scheme == 'http') || (resourceUri.scheme == 'https')) {
    // TODO(zra): Enable library loading over http.
    // _httpGet(resourceUri, libraryUri, (data) {
    //   _loadScript(tag, uri, libraryUri, data);
    // });
    throw 'Cannot load http, yet.';
  } else {
    // Mojo does not expose any asynchronous file IO calls, but we'll maintain
    // the same structure as the standalone embedder here in case it ever does.
    var data = readSync(resourceUri.toFilePath());
    _loadScript(tag, uri, libraryUri, data);
  }
}
