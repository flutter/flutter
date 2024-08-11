// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:_internal" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:_internal" as internal;

import "dart:_internal" show patch;

import "dart:async" show Future;

import "dart:collection" show UnmodifiableListView, UnmodifiableMapView;

/// These are the additional parts of this patch library:
part "mirrors_impl.dart";
part "mirror_reference.dart";

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
@patch
MirrorSystem currentMirrorSystem() {
  return _Mirrors.currentMirrorSystem();
}

/**
 * Returns an [InstanceMirror] for some Dart language object.
 *
 * This only works if this mirror system is associated with the
 * current running isolate.
 */
@patch
InstanceMirror reflect(dynamic reflectee) {
  return _Mirrors.reflect(reflectee);
}

/**
 * Returns a [ClassMirror] for the class represented by a Dart
 * Type object.
 *
 * This only works with objects local to the current isolate.
 */
@patch
ClassMirror reflectClass(Type key) {
  return _Mirrors.reflectClass(key);
}

@patch
TypeMirror reflectType(Type key, [List<Type>? typeArguments]) {
  return _Mirrors.reflectType(key, typeArguments);
}

@patch
class MirrorSystem {
  @patch
  LibraryMirror findLibrary(Symbol libraryName) {
    var candidates =
        libraries.values.where((lib) => lib.simpleName == libraryName);
    if (candidates.length == 1) {
      return candidates.single;
    }
    if (candidates.length > 1) {
      var uris = candidates.map((lib) => lib.uri.toString()).toList();
      throw new Exception("There are multiple libraries named "
          "'${getName(libraryName)}': $uris");
    }
    throw new Exception("There is no library named '${getName(libraryName)}'");
  }

  @patch
  static String getName(Symbol symbol) {
    return internal.Symbol.computeUnmangledName(symbol as internal.Symbol);
  }

  @patch
  static Symbol getSymbol(String name, [LibraryMirror? library]) {
    if ((library != null && library is! _LibraryMirror) ||
        ((name.length > 0) && (name[0] == '_') && (library == null))) {
      throw new ArgumentError(library);
    }
    if (library != null) {
      name = _mangleName(name, (library as _LibraryMirror)._reflectee);
    }
    return new internal.Symbol.unvalidated(name);
  }

  @pragma("vm:external-name", "Mirrors_mangleName")
  external static _mangleName(String name, _MirrorReference lib);
}

@patch
class AbstractClassInstantiationError {
  @pragma("vm:entry-point")
  AbstractClassInstantiationError._create(
      this._className, this._url, this._line);

  @patch
  String toString() {
    return "Cannot instantiate abstract class $_className: "
        "_url '$_url' line $_line";
  }

  // These new fields cannot be declared final, because a constructor exists
  // in the original version of this patched class.
  String? _url;
  int _line = 0;
}
