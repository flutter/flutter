// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'extension_request.g.dart';

const authenticationPath = '\$dwdsExtensionAuthentication';

/// A request to run a command in the Dart Debug Extension.
abstract class ExtensionRequest
    implements Built<ExtensionRequest, ExtensionRequestBuilder> {
  static Serializer<ExtensionRequest> get serializer =>
      _$extensionRequestSerializer;

  factory ExtensionRequest([Function(ExtensionRequestBuilder) updates]) =
      _$ExtensionRequest;

  ExtensionRequest._();

  /// Used to associate a request with an [ExtensionResponse].
  int get id;

  String get command;

  /// Contains JSON-encoded parameters, if avaiable.
  String? get commandParams;
}

/// A response to an [ExtensionRequest].
abstract class ExtensionResponse
    implements Built<ExtensionResponse, ExtensionResponseBuilder> {
  static Serializer<ExtensionResponse> get serializer =>
      _$extensionResponseSerializer;

  factory ExtensionResponse([Function(ExtensionResponseBuilder) updates]) =
      _$ExtensionResponse;

  ExtensionResponse._();

  /// Used to associate a response with an [ExtensionRequest].
  int get id;

  bool get success;

  /// Contains a JSON-encoded payload.
  String get result;

  /// Contains an error, if avaiable.
  String? get error;
}

/// An event for Dart Debug Extension.
abstract class ExtensionEvent
    implements Built<ExtensionEvent, ExtensionEventBuilder> {
  static Serializer<ExtensionEvent> get serializer =>
      _$extensionEventSerializer;

  factory ExtensionEvent([Function(ExtensionEventBuilder) updates]) =
      _$ExtensionEvent;

  ExtensionEvent._();

  /// Contains a JSON-encoded payload.
  String get params;

  String get method;
}

/// A batched group of events, currently always Debugger.scriptParsed
abstract class BatchedEvents
    implements Built<BatchedEvents, BatchedEventsBuilder> {
  static Serializer<BatchedEvents> get serializer => _$batchedEventsSerializer;

  factory BatchedEvents([Function(BatchedEventsBuilder) updates]) =
      _$BatchedEvents;

  BatchedEvents._();

  BuiltList<ExtensionEvent> get events;
}
