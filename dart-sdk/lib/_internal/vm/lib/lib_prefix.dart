// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

// This type corresponds to the VM-internal class LibraryPrefix.
@pragma("vm:entry-point")
class _LibraryPrefix {
  factory _LibraryPrefix._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:external-name", "LibraryPrefix_isLoaded")
  external bool _isLoaded();
  @pragma("vm:external-name", "LibraryPrefix_setLoaded")
  external void _setLoaded();
  @pragma("vm:external-name", "LibraryPrefix_loadingUnit")
  external Object _loadingUnit();
  @pragma("vm:external-name", "LibraryPrefix_issueLoad")
  external static void _issueLoad(Object unit);

  static final _loads = new Map<Object, Completer<void>>();
}

class _DeferredNotLoadedError extends Error implements NoSuchMethodError {
  final _LibraryPrefix prefix;

  _DeferredNotLoadedError(this.prefix);

  String toString() {
    return "Deferred library $prefix was not loaded.";
  }

  // Implementations needed to implement the `_receiver` and `_invocation`
  // members added in the @patch class of [NoSuchMethodError].

  Object? get _receiver =>
      throw UnsupportedError('_DeferredNotLoadedError._receiver');
  Invocation get _invocation =>
      throw UnsupportedError('_DeferredNotLoadedError._invocation');
}

@pragma("vm:entry-point")
void _completeLoads(Object unit, String? errorMessage, bool transientError) {
  Completer<void>? load = _LibraryPrefix._loads[unit];
  if (load == null) {
    // Embedder loaded even though prefix.loadLibrary() wasn't called.
    _LibraryPrefix._loads[unit] = load = new Completer<void>();
  }
  if (errorMessage == null) {
    load.complete(null);
  } else {
    if (transientError) {
      _LibraryPrefix._loads.remove(unit);
    }
    load.completeError(new DeferredLoadException(errorMessage));
  }
}

@pragma("vm:entry-point")
@pragma("vm:never-inline") // Don't duplicate prefix checking code.
Future<void> _loadLibrary(_LibraryPrefix prefix) async {
  if (!prefix._isLoaded()) {
    Object unit = prefix._loadingUnit();
    // Don't issue a load request for the root unit. A deferred prefix can
    // point to a library in the root unit if there is also an immediate import
    // of that library.
    if (unit != 1) {
      Completer<void>? load = _LibraryPrefix._loads[unit];
      if (load == null) {
        _LibraryPrefix._loads[unit] = load = new Completer<void>();
        _LibraryPrefix._issueLoad(unit);
      }
      await load.future;
    }
  }
  // Ensure the prefix's future does not complete until the next Turn even
  // when loading is a no-op or synchronous. Helps applications avoid writing
  // code that only works when loading isn't really deferred.
  await new Future<void>(() {
    prefix._setLoaded();
  });
}

@pragma("vm:entry-point")
@pragma("vm:never-inline") // Don't duplicate prefix checking code.
void _checkLoaded(_LibraryPrefix prefix) {
  if (!prefix._isLoaded()) {
    throw new _DeferredNotLoadedError(prefix);
  }
}
