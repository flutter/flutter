// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library enables one to create a service scope in which code can run.
///
/// A service scope is an environment in which code runs. The environment is a
/// [Zone] with added functionality. Code can be run inside a new service scope
/// by using the `fork(callback)` method. This will call `callback` inside a new
/// service scope and will keep the scope alive until the Future returned by the
/// callback completes. At this point the service scope ends.
///
/// Code running inside a new service scope can
///
///  - register objects (e.g. a database connection pool or a logging service)
///  - look up previously registered objects
///  - register on-scope-exit handlers
///
/// Service scopes can be nested. All registered values from the parent service
/// scope are still accessible as long as they have not been overridden. The
/// callback passed to `fork()` is responsible for not completing it's returned
/// Future until all nested service scopes have ended.
///
/// The on-scope-exit callbacks will be called when the service scope ends. The
/// callbacks are run in reverse registration order and are guaranteed to be
/// executed. During a scope exit callback the active service scope cannot
/// be modified anymore and `lookup()`s will only return values which were
/// registered before the registration of the on-scope-exit callback.
///
/// One use-case of this is making services available to a server application.
/// The server application will run inside a service scope which will have all
/// necessary services registered.
/// Once the server app shuts down, the registered on-scope-exit callbacks will
/// automatically be invoked and the process will shut down cleanly.
///
/// Here is an example use case:
///
///      import 'dart:async';
///      import 'package:gcloud/service_scope.dart' as scope;
///
///      class DBPool { ... }
///
///      DBPool get dbService => scope.lookup(#dbpool);
///
///      Future runApp() {
///        // The application can use the registered objects (here the
///        // dbService). It does not need to pass it around, but can use a
///        // global getter.
///        return dbService.query( ... ).listen(print).asFuture();
///      }
///
///      main() {
///        // Creates a new service scope and runs the given closure inside it.
///        ss.fork(() {
///          // We create a new database pool with a 10 active connections and
///          // add it to the current service scope with key `#dbpool`.
///          // In addition we insert a on-scope-exit callback which will be
///          // called once the application is done.
///          var pool = new DBPool(connections: 10);
///          scope.register(#dbpool, pool, onScopeExit: () => pool.close());
///          return runApp();
///       }).then((_) {
///         print('Server application shut down cleanly');
///       });
///     }
///
/// As an example, the `package:appengine/appengine.dart` package runs request
/// handlers inside a service scope, which has most `package:gcloud` services
/// registered.
///
/// The core application code can then be independent of `package:appengine`
/// and instead depend only on the services needed (e.g.
/// `package:gcloud/storage.dart`) by using getters in the service library (e.g.
/// the `storageService`) which are implemented with service scope lookups.
library gcloud.service_scope;

import 'dart:async';

/// The Symbol used as index in the zone map for the service scope object.
const Symbol _serviceScopeKey = #gcloud.service_scope;

/// An empty service scope.
///
/// New service scope can be created by calling [fork] on the empty
/// service scope.
final _ServiceScope _emptyServiceScope = _ServiceScope();

/// Returns the current [_ServiceScope] object.
_ServiceScope? get _serviceScope =>
    Zone.current[_serviceScopeKey] as _ServiceScope?;

/// Start a new zone with a new service scope and run [func] inside it.
///
/// The function [func] must return a `Future` and the service scope will end
/// when this future completes.
///
/// If an uncaught error occurs and [onError] is given, it will be called. The
/// `onError` parameter can take the same values as `Zone.current.fork`.
Future fork(Future Function() func, {Function? onError}) {
  var currentServiceScope = _serviceScope;
  currentServiceScope ??= _emptyServiceScope;
  return currentServiceScope._fork(func, onError: onError);
}

/// Register a new [object] into the current service scope using the given
/// [key].
///
/// If [onScopeExit] is provided, it will be called when the service scope ends.
///
/// The registered on-scope-exit functions are executed in reverse registration
/// order.
void register(Object key, Object value, {ScopeExitCallback? onScopeExit}) {
  var serviceScope = _serviceScope;
  if (serviceScope == null) {
    throw StateError('Not running inside a service scope zone.');
  }
  serviceScope.register(key, value, onScopeExit: onScopeExit);
}

/// Register a [onScopeExitCallback] to be invoked when this service scope ends.
///
/// The registered on-scope-exit functions are executed in reverse registration
/// order.
void registerScopeExitCallback(ScopeExitCallback onScopeExitCallback) {
  var serviceScope = _serviceScope;
  if (serviceScope == null) {
    throw StateError('Not running inside a service scope zone.');
  }
  serviceScope.registerOnScopeExitCallback(onScopeExitCallback);
}

/// Look up an item by it's key in the currently active service scope.
///
/// Returns `null` if there is no entry with the given key.
Object? lookup(Object key) {
  var serviceScope = _serviceScope;
  if (serviceScope == null) {
    throw StateError('Not running inside a service scope zone.');
  }
  return serviceScope.lookup(key);
}

/// Represents a global service scope of values stored via zones.
class _ServiceScope {
  /// A mapping of keys to values stored inside the service scope.
  final Map<Object, _RegisteredEntry> _key2Values =
      <Object, _RegisteredEntry>{};

  /// A set which indicates whether an object was copied from it's parent.
  final Set<Object> _parentCopies = <Object>{};

  /// On-Scope-Exit functions which will be called in reverse insertion order.
  final List<_RegisteredEntry> _registeredEntries = [];

  bool _cleaningUp = false;
  bool _destroyed = false;

  /// Looks up an object by it's service scope key - returns `null` if not
  /// found.
  Object? lookup(Object serviceScope) {
    _ensureNotInDestroyingState();
    var entry = _key2Values[serviceScope];
    return entry?.value;
  }

  /// Inserts a new item to the service scope using [serviceScopeKey].
  ///
  /// Optionally calls a [onScopeExit] function once this service scope ends.
  void register(Object serviceScopeKey, Object value,
      {ScopeExitCallback? onScopeExit}) {
    _ensureNotInCleaningState();
    _ensureNotInDestroyingState();

    var isParentCopy = _parentCopies.contains(serviceScopeKey);
    if (!isParentCopy && _key2Values.containsKey(serviceScopeKey)) {
      throw ArgumentError(
          'Service scope already contains key $serviceScopeKey.');
    }

    var entry = _RegisteredEntry(serviceScopeKey, value, onScopeExit);

    _key2Values[serviceScopeKey] = entry;
    if (isParentCopy) _parentCopies.remove(serviceScopeKey);

    _registeredEntries.add(entry);
  }

  /// Inserts a new on-scope-exit function to be called once this service scope
  /// ends.
  void registerOnScopeExitCallback(ScopeExitCallback onScopeExitCallback) {
    _ensureNotInCleaningState();
    _ensureNotInDestroyingState();

    _registeredEntries.add(_RegisteredEntry(null, null, onScopeExitCallback));
  }

  /// Start a new zone with a forked service scope.
  Future _fork(Future Function() func, {Function? onError}) {
    _ensureNotInCleaningState();
    _ensureNotInDestroyingState();

    var serviceScope = _copy();
    var map = {_serviceScopeKey: serviceScope};
    return runZoned(() {
      var f = func();
      return f.whenComplete(serviceScope._runScopeExitHandlers);
      // ignore: deprecated_member_use
    }, zoneValues: map, onError: onError);
  }

  void _ensureNotInDestroyingState() {
    if (_destroyed) {
      throw StateError(
          'The service scope has already been exited. It is therefore '
          'forbidden to use this service scope anymore. '
          'Please make sure that your code waits for all asynchronous tasks '
          'before the closure passed to fork() completes.');
    }
  }

  void _ensureNotInCleaningState() {
    if (_cleaningUp) {
      throw StateError(
          'The service scope is in the process of cleaning up. It is therefore '
          'forbidden to make any modifications to the current service scope. '
          'Please make sure that your code waits for all asynchronous tasks '
          'before the closure passed to fork() completes.');
    }
  }

  /// Copies all service scope entries to a new service scope, but not their
  /// on-scope-exit handlers.
  _ServiceScope _copy() {
    var serviceScopeCopy = _ServiceScope();
    serviceScopeCopy._key2Values.addAll(_key2Values);
    serviceScopeCopy._parentCopies.addAll(_key2Values.keys);
    return serviceScopeCopy;
  }

  /// Runs all on-scope-exit functions in [_ServiceScope].
  Future _runScopeExitHandlers() {
    _cleaningUp = true;
    var errors = [];

    // We are running all on-scope-exit functions in reverse registration order.
    // Even if one fails, we continue cleaning up and report then the list of
    // errors (if there were any).
    return Future.forEach(_registeredEntries.reversed,
        (_RegisteredEntry registeredEntry) {
      if (registeredEntry.key != null) {
        _key2Values.remove(registeredEntry.key);
      }
      if (registeredEntry.scopeExitCallback != null) {
        return Future.sync(registeredEntry.scopeExitCallback!)
            .catchError((e, s) => errors.add(e));
      } else {
        return Future.value();
      }
    }).then((_) {
      _cleaningUp = true;
      _destroyed = true;
      if (errors.isNotEmpty) {
        throw Exception(
            'The following errors occured while running scope exit handlers'
            ': $errors');
      }
    });
  }
}

typedef ScopeExitCallback = FutureOr Function();

class _RegisteredEntry {
  final Object? key;
  final Object? value;
  final ScopeExitCallback? scopeExitCallback;

  _RegisteredEntry(this.key, this.value, this.scopeExitCallback);
}
