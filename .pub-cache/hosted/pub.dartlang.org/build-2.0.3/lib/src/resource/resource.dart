// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

typedef CreateInstance<T> = FutureOr<T> Function();
typedef DisposeInstance<T> = FutureOr<void> Function(T instance);
typedef BeforeExit = FutureOr<void> Function();

/// A [Resource] encapsulates the logic for creating and disposing of some
/// expensive object which has a lifecycle.
///
/// Actual [Resource]s should be retrieved using `BuildStep#fetchResource`.
///
/// Build system implementations should be the only users that directly
/// instantiate a [ResourceManager] since they can handle the lifecycle
/// guarantees in a sane way.
class Resource<T> {
  /// Factory method which creates an instance of this resource.
  final CreateInstance<T> _create;

  /// Optional method which is given an existing instance that is ready to be
  /// disposed.
  final DisposeInstance<T>? _userDispose;

  /// Optional method which is called before the process is going to exit.
  ///
  /// This allows resources to do any final cleanup, and is not given an
  /// instance.
  final BeforeExit? _userBeforeExit;

  /// A Future instance of this resource if one has ever been requested.
  final _instanceByManager = <ResourceManager, Future<T>>{};

  Resource(this._create, {DisposeInstance<T>? dispose, BeforeExit? beforeExit})
      : _userDispose = dispose,
        _userBeforeExit = beforeExit;

  /// Fetches an actual instance of this resource for [manager].
  Future<T> _fetch(ResourceManager manager) =>
      _instanceByManager.putIfAbsent(manager, () async => await _create());

  /// Disposes the actual instance of this resource for [manager] if present.
  Future<void> _dispose(ResourceManager manager) {
    if (!_instanceByManager.containsKey(manager)) return Future.value(null);
    var oldInstance = _fetch(manager);
    _instanceByManager.remove(manager);
    if (_userDispose != null) {
      return oldInstance.then(_userDispose!);
    } else {
      return Future.value(null);
    }
  }
}

/// Manages fetching and disposing of a group of [Resource]s.
///
/// This is an internal only API which should only be used by build system
/// implementations and not general end users. Instead end users should use
/// the `buildStep#fetchResource` method to get [Resource]s.
class ResourceManager {
  final _resources = <Resource<void>>{};

  /// The [Resource]s that we need to call `beforeExit` on.
  ///
  /// We have to hang on to these forever, but they should be small in number,
  /// and we don't hold on to the actual created instances, just the [Resource]
  /// instances.
  final _resourcesWithBeforeExit = <Resource<void>>{};

  /// Fetches an instance of [resource].
  Future<T> fetch<T>(Resource<T> resource) async {
    if (resource._userBeforeExit != null) {
      _resourcesWithBeforeExit.add(resource);
    }
    _resources.add(resource);
    return resource._fetch(this);
  }

  /// Disposes of all [Resource]s fetched since the last call to [disposeAll].
  Future<Null> disposeAll() {
    var done = Future.wait(_resources.map((r) => r._dispose(this)));
    _resources.clear();
    return done.then((_) => null);
  }

  /// Invokes the `beforeExit` callbacks of all [Resource]s that had one.
  Future<Null> beforeExit() async {
    await Future.wait(_resourcesWithBeforeExit.map((r) async {
      return r._userBeforeExit?.call();
    }));
    _resourcesWithBeforeExit.clear();
  }
}
