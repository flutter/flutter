// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:meta/meta.dart';

import 'dom.dart';
import 'profiler.dart';

/// An interface for a finalizer that can be used to run a cleanup function when
/// an object is garbage collected.
abstract class Finalizer {
  /// Attaches this finalizer to [target].
  void attach(Object target, Object value, {Object? detach});

  /// Detaches this finalizer from whatever [detach] was used to attach it.
  void detach(Object detach);
}

/// A finalizer that can be used to run a cleanup function when an object is
/// garbage collected.
///
/// This is a wrapper around [DomFinalizationRegistry] that provides a more
/// Dart-friendly API, similar to [NativeFinalizer] from `dart:ffi`.
class NativeMemoryFinalizer implements Finalizer {
  NativeMemoryFinalizer(void Function(Object) cleanup)
    : _registry = DomFinalizationRegistry(
        ((ExternalDartReference value) {
          final Object? object = value.toDartObject;
          if (object != null) {
            cleanup(object);
          }
        }).toJS,
      );

  final DomFinalizationRegistry _registry;

  /// Attaches this finalizer to [target].
  ///
  /// When [target] is garbage collected, the cleanup function of this
  /// finalizer will be called with [value] as the argument.
  ///
  /// If [detach] is provided, it can be used to detach the finalizer later
  /// using [this.detach].
  @override
  void attach(Object target, Object value, {Object? detach}) {
    if (browserSupportsFinalizationRegistry) {
      if (detach != null) {
        _registry.registerWithToken(
          target.toExternalReference,
          value.toExternalReference,
          detach.toExternalReference,
        );
      } else {
        _registry.register(target.toExternalReference, value.toExternalReference);
      }
    }
  }

  /// Detaches this finalizer from whatever [detach] was used to attach it.
  @override
  void detach(Object detach) {
    if (browserSupportsFinalizationRegistry) {
      _registry.unregister(detach.toExternalReference);
    }
  }
}

/// Interface that objects wrapping [UniqueRef] or [CountedRef] must implement
/// to support debugging.
abstract class StackTraceDebugger {
  /// The stack trace pointing to code location that created or upreffed a
  /// [CountedRef].
  StackTrace get debugStackTrace;
}

/// Manages the lifecycle of a native object referenced by a single Dart object.
///
/// It is expected that when the native object is no longer needed [dispose] is
/// called.
///
/// To prevent memory leaks, the underlying native object is disposed by the GC
/// if it wasn't previously disposed of explicitly.
class UniqueRef<T> {
  UniqueRef(
    Object owner,
    T nativeObject,
    this._debugOwnerLabel, {
    required void Function(T) onDispose,
  }) : _nativeObject = nativeObject,
       _onDispose = onDispose {
    if (Instrumentation.enabled) {
      Instrumentation.instance.incrementCounter('$_debugOwnerLabel Created');
    }
    finalizer.attach(owner, this, detach: this);
  }

  /// The finalizer used by all [UniqueRef] instances.
  ///
  /// This can be overridden in tests to verify finalization behavior.
  @visibleForTesting
  static Finalizer finalizer = NativeMemoryFinalizer(
    (Object ref) => (ref as UniqueRef<dynamic>).collect(),
  );

  T? _nativeObject;
  final String _debugOwnerLabel;
  final void Function(T) _onDispose;

  /// Returns the underlying native object reference, if it has not been
  /// disposed of yet.
  T get nativeObject {
    assert(!isDisposed, 'The native object of $_debugOwnerLabel was disposed.');
    return _nativeObject!;
  }

  /// Returns whether the underlying native object has been disposed and
  /// therefore can no longer be used.
  bool get isDisposed => _nativeObject == null;

  /// Whether the underlying native object has been disposed.
  ///
  /// This is only available in debug mode.
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = isDisposed;
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw StateError('debugDisposed is only available when asserts are enabled.');
  }

  /// Disposes the underlying native object.
  void dispose() {
    assert(!isDisposed, 'A native object reference cannot be disposed more than once.');
    finalizer.detach(this);
    if (Instrumentation.enabled) {
      Instrumentation.instance.incrementCounter('$_debugOwnerLabel Deleted');
    }
    final object = _nativeObject as T;
    _onDispose(object);
    _nativeObject = null;
  }

  /// Called by the garbage collector when the owner of this handle is
  /// collected.
  @visibleForTesting
  void collect() {
    if (!isDisposed) {
      if (Instrumentation.enabled) {
        Instrumentation.instance.incrementCounter('$_debugOwnerLabel Leaked');
      }
      dispose();
    }
  }
}

/// Manages the lifecycle of a native object referenced by multiple Dart objects.
///
/// Uses reference counting to manage the lifecycle of the native object.
///
/// If the native object has a unique owner, use [UniqueRef] instead.
///
/// The [ref] method can be used to increment the refcount to tell this box to
/// keep the underlying native object alive.
///
/// The [unref] method can be used to decrement the refcount indicating that a
/// referring object no longer needs it. When the refcount drops to zero the
/// underlying native object is disposed.
class CountedRef<R extends StackTraceDebugger, T> {
  /// Creates a counted reference.
  CountedRef(
    T nativeObject,
    R debugReferrer,
    String debugLabel, {
    required void Function(T) onDispose,
    this.onDisposed,
  }) {
    _ref = UniqueRef<T>(this, nativeObject, debugLabel, onDispose: onDispose);
    assert(() {
      debugReferrers.add(debugReferrer);
      return true;
    }());
    assert(refCount == debugReferrers.length);
  }

  /// The native object reference whose lifecycle is being managed by this ref
  /// count.
  late final UniqueRef<T> _ref;

  /// A callback that is called when the reference count drops to zero and the
  /// underlying native object is disposed.
  final void Function(R)? onDisposed;

  /// Returns the underlying native object reference, if it has not been
  /// disposed of yet.
  T get nativeObject => _ref.nativeObject;

  /// The number of objects sharing references to this box.
  int get refCount => _refCount;
  int _refCount = 1;

  /// Whether the underlying [nativeObject] has been disposed and is no longer
  /// accessible.
  bool get isDisposed => _ref.isDisposed;

  /// Whether the underlying native object has been disposed.
  ///
  /// This is only available in debug mode.
  bool get debugDisposed => _ref.debugDisposed;

  /// When assertions are enabled, stores all objects that share this box.
  final Set<R> debugReferrers = <R>{};

  /// If asserts are enabled, the [StackTrace]s representing when a reference
  /// was created.
  List<StackTrace> debugGetStackTraces() {
    List<StackTrace>? result;
    assert(() {
      result = debugReferrers.map<StackTrace>((R referrer) => referrer.debugStackTrace).toList();
      return true;
    }());

    if (result != null) {
      return result!;
    }

    throw UnsupportedError('StackTrace collection only supported in debug mode.');
  }

  /// Increases the reference count of this box because a new object began
  /// sharing ownership of the underlying [nativeObject].
  void ref(R debugReferrer) {
    assert(!_ref.isDisposed, 'Cannot increment ref count on a deleted handle.');
    assert(_refCount > 0);
    assert(
      debugReferrers.add(debugReferrer),
      'Attempted to increment ref count by the same referrer more than once.',
    );
    _refCount += 1;
    assert(refCount == debugReferrers.length);
  }

  /// Decrements the reference count for the [nativeObject].
  void unref(R debugReferrer) {
    assert(!_ref.isDisposed, 'Attempted to unref an already deleted native object.');
    assert(
      debugReferrers.remove(debugReferrer),
      'Attempted to decrement ref count by the same referrer more than once.',
    );
    _refCount -= 1;
    assert(refCount == debugReferrers.length);
    if (_refCount == 0) {
      onDisposed?.call(debugReferrer);
      _ref.dispose();
    }
  }
}
