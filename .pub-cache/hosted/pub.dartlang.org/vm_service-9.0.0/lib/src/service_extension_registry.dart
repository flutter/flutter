// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../vm_service.dart' show VmServerConnection, RPCError, Event, EventKind;
import 'stream_helpers.dart';

/// A registry of custom service extensions to [VmServerConnection]s in which
/// they were registered.
class ServiceExtensionRegistry {
  /// Maps service extensions registered through the protocol to the
  /// [VmServerConnection] in which they were registered.
  ///
  /// Note: this does not track services registered through `dart:developer`,
  /// only the services registered through the `_registerService` rpc method.
  final _extensionToConnection = <String, VmServerConnection>{};

  /// Controller for tracking registration and unregistration events.
  final _eventController = StreamController<Event>.broadcast();

  ServiceExtensionRegistry();

  /// Registers [extension] for [client].
  ///
  /// All future requests for [extension] will be routed to [client].
  void registerExtension(String extension, VmServerConnection client) {
    if (_extensionToConnection.containsKey(extension)) {
      throw RPCError('registerExtension', 111, 'Service already registered');
    }
    _eventController.sink.add(_toRegistrationEvent(extension));
    _extensionToConnection[extension] = client;
    // Remove the mapping if the client disconnects.
    client.done.whenComplete(() {
      _extensionToConnection.remove(extension);
      _eventController.sink.add(_toRegistrationEvent(extension,
          kind: EventKind.kServiceUnregistered));
    });
  }

  /// Returns the [VmServerConnection] for a given [extension], or `null` if
  /// none is registered.
  ///
  /// The result of this function should not be stored, because clients may
  /// shut down at any time.
  VmServerConnection? clientFor(String extension) =>
      _extensionToConnection[extension];

  /// All of the currently registered extensions
  Iterable<String> get registeredExtensions => _extensionToConnection.keys;

  /// Emits an [Event] of type `ServiceRegistered` for all current and future
  /// extensions that are registered, and `ServiceUnregistered` when those
  /// clients disconnect.
  Stream<Event> get onExtensionEvent => _eventController.stream
      .transform(startWithMany(registeredExtensions.map(_toRegistrationEvent)));

  /// Creates a `_Service` stream event, with a default kind of
  /// [EventKind.kServiceRegistered].
  Event _toRegistrationEvent(String method,
          {String kind = EventKind.kServiceRegistered}) =>
      Event(
        kind: kind,
        service: method,
        method: method,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
}
