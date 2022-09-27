// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The server uses async code to be able to listen for incoming Echo requests and connections
// asynchronously.
import 'dart:async';

// The fidl package contains general utility code for using FIDL in Dart.
import 'package:fidl/fidl.dart' as fidl;
// The generated Dart bindings for the Echo FIDL protocol
import 'package:fidl_flutter_example_echo/fidl_async.dart' as fidl_echo;
// The fuchsia_services package interfaces with the Fuchsia system. In particular, it is used
// to expose a service to other components
import 'package:fuchsia_services/services.dart' as sys;

// Create an implementation for the Echo protocol by overriding the
// fidl_echo.Echo class from the bindings
class _EchoImpl extends fidl_echo.Echo {
  // The stream controller for the stream of OnString events
  final _onStringStreamController = StreamController<String>();

  // Implementation of EchoString that just echoes the request value back
  @override
  Future<String?> echoString(String? value) async {
    return value;
  }
}

void main(List<String> args) {
  // Create the component context. We should not serve outgoing before we add
  // the services.
  final context = sys.ComponentContext.create();
  // Each FIDL protocol class has an accompanying Binding class, which takes
  // an implementation of the protocol and a channel, and dispatches incoming
  // requests on the channel to the protocol implementation.
  final binding = fidl_echo.EchoBinding();
  // Serves the implementation by passing it a handler for incoming requests,
  // and the name of the protocol it is providing.
  final echo = _EchoImpl();
  // Add the outgoing service, and then serve the outgoing directory.
  context.outgoing
    ..addPublicService<fidl_echo.Echo>(
        (fidl.InterfaceRequest<fidl_echo.Echo> serverEnd) =>
            binding.bind(echo, serverEnd),
        fidl_echo.Echo.$serviceName)
    ..serveFromStartupInfo();
}
