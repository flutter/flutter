// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

@pragma("wasm:import", "moduleLoadingHelper.loadDynamicModuleFromUri")
external WasmExternRef _loadModuleFromUri(
  WasmExternRef moduleUri,
  WasmExternRef jsUri,
);

@patch
Future<Object?> loadDynamicModule({Uri? uri, Uint8List? bytes}) {
  JSPromise loadPromise;
  if (uri != null) {
    final uriString = '$uri';
    if (!uriString.endsWith('.wasm')) {
      throw ArgumentError('Malformed dynamic module URI.');
    }
    final jsUriString =
        '${uriString.substring(0, uriString.length - '.wasm'.length)}.mjs';
    loadPromise =
        (_loadModuleFromUri(
              uriString.toJS.toExternRef!,
              jsUriString.toJS.toExternRef!,
            ).toJS
            as JSPromise);
  } else {
    throw ArgumentError('Wasm only supports `uri` for `loadDynamicModule`');
  }
  return loadPromise.toDart.then(
    (entryPoint) =>
        dartifyRaw(((entryPoint as JSFunction).callAsFunction())?.toExternRef),
  );
}

/// Only classes defined in the main module require runtime canonicalization.
/// Classes defined in the dynamic modules cannot be shared outside of that
/// module so can be canonicalized at compile time. So this will always only be
/// the number of classes in the main module.
external int get _numClassesForConstCaches;

/// Stores caches to canonicalize instances of objects. The i'th entry contains
/// a cache of entities for type Class_i where Class_i is the class with
/// ID i.
@pragma('dyn-module:callable')
final WasmArray<WasmConstCache?> _constCacheByType = WasmArray.filled(
  _numClassesForConstCaches,
  null,
);

@pragma('dyn-module:callable')
WasmConstCache getConstCache(int classId) {
  return _constCacheByType[classId] ??= WasmConstCache();
}

/// Runtime cache containing constant values for a particular class.
///
/// Contains growable wasm arrays to store values in. Doesn't use a Dart
/// growable List since Lists require a runtime type to be instantiated. This
/// would cause an instantiation loop since runtime types are constants.
///
/// Values of type WasmArray<T> are stored separately from values of type T,
/// so that the appropriate equality function can be used to compare them.
///
/// Note: The functions in here avoid polymorphic helpers as this would require
/// instantiating Type constants and we cannot use constants in code to create
/// constants.
class WasmConstCache {
  int _nextIndex = 0;
  WasmArray<Object> _data = WasmArray<Object>.filled(
    2,
    WasmAnyRef.fromObject(Object()),
  );

  @pragma('dyn-module:callable')
  WasmConstCache();

  @pragma('dyn-module:callable', 'call')
  Object canonicalizeValue(
    Object value,
    WasmFunction<bool Function(Object val1, Object val2)> check,
  ) {
    for (int i = 0; i < _nextIndex; i++) {
      final cachedValue = _data[i];
      if (check.call(value, cachedValue)) {
        return cachedValue;
      }
    }
    if (_data.length == _nextIndex) {
      final newCache = WasmArray<Object>.filled(_data.length * 2, _data[0]);
      newCache.copy(0, _data, 0, _data.length);
      _data = newCache;
    }
    _data[_nextIndex++] = value;
    return value;
  }
}

@pragma('dyn-module:callable')
final objectConstArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final stringConstArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final stringConstImmutableArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final typeConstArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final typeArrayConstArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final nameParameterConstArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final i8ConstImmutableArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final i32ConstArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final i64ConstImmutableArray = WasmArrayConstCache();
@pragma('dyn-module:callable')
final boxedIntImmutableArray = WasmArrayConstCache();

class WasmArrayConstCache {
  // Guaranteed by construction to contain only arrays with the same type.
  WasmArray<WasmArrayRef>? _data;
  int _nextIndex = 0;

  WasmArrayConstCache();

  @pragma('dyn-module:callable', 'call')
  WasmArrayRef canonicalizeArrayValue(
    WasmArrayRef value,
    WasmFunction<bool Function(WasmArrayRef val1, WasmArrayRef val2)> check,
  ) {
    var data = _data ??= WasmArray<WasmArrayRef>.filled(
      2,
      WasmArray.filled(0, WasmAnyRef.fromObject(Object())),
    );
    for (int i = 0; i < _nextIndex; i++) {
      final cachedValue = data[i];
      if (value.length != cachedValue.length) continue;
      // The cachedValue must be the second value here so that it's type is
      // verified.
      if (check.call(value, cachedValue)) {
        return cachedValue;
      }
    }
    if (data.length == _nextIndex) {
      final newCache = WasmArray<WasmArrayRef>.filled(data.length * 2, data[0]);
      newCache.copy(0, data, 0, data.length);
      data = _data = newCache;
    }
    data[_nextIndex++] = value;
    return value;
  }
}

/// A table where there is one row per module and each column represents the
/// updateable function for the corresponding allocated key index. The compiler
/// tracks updateable functions via a unique string key which is converted to an
/// integer index at either compile time or runtime. Each module may have an
/// implementation of that function key.
WasmArray<WasmArray<WasmFuncRef?>> _updateableRefs = WasmArray.literal(
  const [],
);

/// Get the function reference implementation for allocated index [key] as
/// defined by module [moduleId].
@pragma('dyn-module:callable')
WasmFuncRef? getUpdateableFuncRef(int moduleId, int key) {
  final moduleRefs = _updateableRefs[moduleId];
  if (key >= moduleRefs.length) return null;
  return moduleRefs[key];
}

/// Register the updateable function ref implementations into a new module.
/// [refs] contains implementations of pre-allocated (i.e. defined in main)
/// keys.
@pragma('dyn-module:callable')
void registerUpdateableFuncRefs(WasmArray<WasmFuncRef?> refs) {
  final oldUpdateableRefs = _updateableRefs;
  final oldSize = oldUpdateableRefs.length;
  final newUpdateableRefs = WasmArray<WasmArray<WasmFuncRef?>>.filled(
    oldSize + 1,
    refs,
  );
  newUpdateableRefs.copy(0, oldUpdateableRefs, 0, oldSize);
  _updateableRefs = newUpdateableRefs;
}

Set<String> _loadedLibraryUris = {};

@pragma('dyn-module:callable')
void registerLibraryUris(List<String> uris) {
  for (final uri in uris) {
    if (!_loadedLibraryUris.add(uri)) {
      throw StateError(
        'Cannot define the same library twice in dynamic modules.',
      );
    }
  }
}
