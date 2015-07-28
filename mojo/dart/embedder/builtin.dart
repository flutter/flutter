// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library mojo_builtin;

import 'dart:async';
import 'dart:convert';
import 'dart:mojo.internal';

const _logBuiltin = false;

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



Uri _uriBase() {
  return _entryPointScript.resolve('.');
}

_getUriBaseClosure() => _uriBase;

_setupHooks() {
  VMLibraryHooks.eventHandlerSendData = MojoHandleWatcher.timer;
}

Uri _workingDirectory;
Uri _entryPointScript;
Uri _packageRoot;

_enforceTrailingSlash(String uri) {
  // Ensure we have a trailing slash character.
  if (!uri.endsWith('/')) {
    return '$uri/';
  }
  return uri;
}

_setWorkingDirectory(String cwd) {
  cwd = _enforceTrailingSlash(cwd);
  _workingDirectory = new Uri(scheme: 'file', path: cwd);
  if (_logBuiltin) {
    _print('# Working Directory: $_workingDirectory');
  }
}

_setPackageRoot(String packageRoot) {
  packageRoot = _enforceTrailingSlash(packageRoot);
  if (packageRoot.startsWith('file:') ||
      packageRoot.startsWith('http:') ||
      packageRoot.startsWith('https:')) {
    _packageRoot = _workingDirectory.resolve(packageRoot);
  } else {
    _packageRoot = _workingDirectory.resolveUri(new Uri.file(packageRoot));
  }
  if (_logBuiltin) {
    _print('# Package root: $packageRoot -> $_packageRoot');
  }
}

_resolveScriptUri(String scriptName) {
  if (_workingDirectory == null) {
    throw 'No current working directory set.';
  }

  var scriptUri = Uri.parse(scriptName);
  if (scriptUri.scheme != '') {
    // Script has a scheme, assume that it is fully formed.
    _entryPointScript = scriptUri;
  } else {
    // Script does not have a scheme, assume that it is a path,
    // resolve it against the working directory.
    _entryPointScript = _workingDirectory.resolve(scriptName);
  }
  if (_logBuiltin) {
    _print('# Script entry point: $scriptName -> $_entryPointScript');
  }
}
