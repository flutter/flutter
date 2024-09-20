// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(joshualitt): This is just a stub so apps can run. We should replace it
// with an actual implementation of deferred loading.

part of "internal_patch.dart";

Map<String, Set<String>> _loadedLibraries = {};

class DeferredNotLoadedError extends Error implements NoSuchMethodError {
  final String libraryName;
  final String prefix;

  DeferredNotLoadedError(this.libraryName, this.prefix);

  String toString() {
    return 'Deferred library $libraryName has not loaded $prefix.';
  }
}

@pragma("wasm:entry-point")
Future<void> loadLibrary(String enclosingLibrary, String importPrefix) {
  (_loadedLibraries[enclosingLibrary] ??= {}).add(importPrefix);
  return Future<void>.value();
}

@pragma("wasm:entry-point")
Object checkLibraryIsLoaded(String enclosingLibrary, String importPrefix) {
  bool? isLoaded = _loadedLibraries[enclosingLibrary]?.contains(importPrefix);
  if (isLoaded == null || isLoaded == false) {
    throw DeferredNotLoadedError(enclosingLibrary, importPrefix);
  }
  return true;
}
