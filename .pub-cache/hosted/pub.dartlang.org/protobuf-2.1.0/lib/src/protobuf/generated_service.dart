// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

/// Server side context.
class ServerContext {
  // TODO: Place server specific information in this class.
}

/// The implementation of a Service API.
///
/// The protoc plugin generates subclasses (with names ending with ServiceBase)
/// that extend GeneratedService and dispatch requests by method.
abstract class GeneratedService {
  /// Creates a message object that can deserialize a request.
  GeneratedMessage createRequest(String methodName);

  /// Dispatches the call. The request object should come from [createRequest].
  Future<GeneratedMessage> handleCall(
      ServerContext ctx, String methodName, GeneratedMessage request);
}
