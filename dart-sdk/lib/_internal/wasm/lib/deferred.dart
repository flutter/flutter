// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

final Map<String, Future> _loadingModules = {};
final Set<String> _loadedModules = {};
final Map<String, Set<String>> _loadedLibraries = {};

external Map<String, Map<String, List<String>>> get _importMapping;

@pragma("wasm:import", "moduleLoadingHelper.loadModule")
external WasmExternRef _loadModule(WasmExternRef moduleName);

class DeferredNotLoadedError extends Error implements NoSuchMethodError {
  final String libraryName;
  final String prefix;

  DeferredNotLoadedError(this.libraryName, this.prefix);

  String toString() {
    return 'Deferred library $libraryName has not loaded $prefix.';
  }
}

Future<void> loadLibrary(String enclosingLibrary, String importPrefix) {
  if (_importMapping.isEmpty) {
    // Only contains one unit.
    (_loadedLibraries[enclosingLibrary] ??= {}).add(importPrefix);
    return Future.value();
  }
  final loadedImports = _loadedLibraries[enclosingLibrary];
  if (loadedImports != null && loadedImports.contains(importPrefix)) {
    // Import already loaded.
    return Future.value();
  }
  final importNameMapping = _importMapping[enclosingLibrary];
  final moduleNames = importNameMapping?[importPrefix];

  if (moduleNames == null) {
    // Since loadLibrary calls get lowered to static invocations of this method,
    // TFA will tree-shake libraries (and their associated imports) that are
    // only referenced via a loadLibrary call. In this case, we won't have an
    // import mapping for the lowered loadLibrary call.
    // This can also occur in module test mode where all imports are deferred
    // but loaded eagerly.
    (_loadedLibraries[enclosingLibrary] ??= {}).add(importPrefix);
    return Future.value();
  }

  if (!deferredLoadingEnabled) {
    throw DeferredLoadException('Compiler did not enable deferred loading.');
  }

  // Start loading modules
  final List<Future> loadFutures = [];
  for (final moduleName in moduleNames) {
    if (_loadedModules.contains(moduleName)) {
      // Already loaded module
      continue;
    }
    final existingLoad = _loadingModules[moduleName];
    if (existingLoad != null) {
      // Already loading module
      loadFutures.add(existingLoad);
      continue;
    }

    // Start module load
    final promise =
        (_loadModule(moduleName.toJS.toExternRef!).toJS as JSPromise);
    final future = promise.toDart.then(
      (_) {
        // Module loaded
        _loadedModules.add(moduleName);
      },
      onError: (e) {
        throw DeferredLoadException('Error loading module: $moduleName\n$e');
      },
    );
    loadFutures.add(future);
    _loadingModules[moduleName] = future;
  }
  return Future.wait(loadFutures).then((_) {
    (_loadedLibraries[enclosingLibrary] ??= {}).add(importPrefix);
  });
}

Object checkLibraryIsLoaded(String enclosingLibrary, String importPrefix) {
  final loadedImports = _loadedLibraries[enclosingLibrary];
  if (loadedImports == null || !loadedImports.contains(importPrefix)) {
    throw DeferredNotLoadedError(enclosingLibrary, importPrefix);
  }
  return true;
}
