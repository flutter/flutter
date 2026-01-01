// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

/// Contains active futures for any entities (either module names or IDs)
/// currently being loaded.
final Map<int, Future<void>> _loading = {};

/// Contains the set of entities (either modules or IDs) already loaded.
final Set<int> _loaded = {};

/// Only used when loading modules directly, will get populated by the compiler.
external ImmutableWasmArray<ImmutableWasmArray<WasmExternRef>> get _loadingMap;

/// Maps load id to (import uri, import prefix).
external ImmutableWasmArray<WasmExternRef> get _loadingMapNames;

@pragma("wasm:import", "moduleLoadingHelper.loadDeferredModules")
external WasmExternRef _loadDeferredModules(WasmExternRef moduleNames);

@pragma("wasm:import", "moduleLoadingHelper.loadDeferredId")
external WasmExternRef _loadDeferredId(WasmI32 loadId);

String _importUri(int loadId) =>
    JSStringImpl.fromRefUnchecked(_loadingMapNames[2 * loadId + 0]);
String _prefixName(int loadId) =>
    JSStringImpl.fromRefUnchecked(_loadingMapNames[2 * loadId + 1]);

int _loadIdInJson(int loadId) {
  // The load-id.json will contain 1-based indexing.
  return loadId + 1;
}

class DeferredLoadIdNotLoadedError extends Error implements NoSuchMethodError {
  final int loadId;

  DeferredLoadIdNotLoadedError(this.loadId);

  String toString() {
    if (minify) {
      return 'Deferred load id ${_loadIdInJson(loadId)} has not loaded.';
    }
    return 'Deferred library ${_importUri(loadId)} has not '
        'loaded ${_prefixName(loadId)}.';
  }
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
bool checkLibraryIsLoadedFromLoadId(int loadId) {
  if (_loaded.contains(loadId)) {
    return true;
  }
  throw DeferredLoadIdNotLoadedError(loadId);
}

// NOTE: We'll inject a `@pragma('wasm:entry-point')` before TFA if we need this
// method at runtime.
Future<void> loadLibraryFromLoadId(int loadId) {
  if (!deferredLoadingEnabled) {
    _loaded.add(loadId);
    return Future.value();
  }
  if (_loaded.contains(loadId)) {
    return Future.value();
  }
  final existingFuture = _loading[loadId];
  if (existingFuture != null) {
    return existingFuture;
  }
  final future = deferredLoadingViaEmbedderLoadId
      ? _loadLibraryViaEmbedderLoadId(loadId)
      : _loadLibraryViaEmbedderModuleNames(loadId);
  return _loading[loadId] = future.then(
    (_) {
      _loaded.add(loadId);
      _loading.remove(loadId);
    },
    onError: (e) {
      if (minify) {
        throw DeferredLoadException(
          'Error loading load ID: ${_loadIdInJson(loadId)}\n$e',
        );
      }
      return 'Error loading ${_prefixName(loadId)} of library '
          '${_importUri(loadId)}\n$e';
    },
  );
}

Future<void> _loadLibraryViaEmbedderLoadId(int loadId) {
  final promise =
      (_loadDeferredId(_loadIdInJson(loadId).toWasmI32()).toJS as JSPromise);
  return promise.toDart;
}

Future<void> _loadLibraryViaEmbedderModuleNames(int loadId) {
  assert(loadId < _loadingMap.length);

  final ImmutableWasmArray<WasmExternRef> moduleNames = _loadingMap[loadId];
  if (moduleNames.length == 0) {
    // No modules to load.
    return Future.value();
  }
  final moduleNamesAsList = <JSString>[];
  for (int i = 0; i < moduleNames.length; ++i) {
    moduleNamesAsList.add(JSValue(moduleNames[i]) as JSString);
  }
  final promise =
      (_loadDeferredModules(moduleNamesAsList.toJS.toExternRef!).toJS
          as JSPromise);
  return promise.toDart;
}
