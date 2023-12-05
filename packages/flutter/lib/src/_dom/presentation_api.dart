// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'websockets.dart';

typedef PresentationConnectionState = String;
typedef PresentationConnectionCloseReason = String;

@JS('Presentation')
@staticInterop
class Presentation {}

extension PresentationExtension on Presentation {
  external set defaultRequest(PresentationRequest? value);
  external PresentationRequest? get defaultRequest;
  external PresentationReceiver? get receiver;
}

@JS('PresentationRequest')
@staticInterop
class PresentationRequest implements EventTarget {
  external factory PresentationRequest(JSAny urlOrUrls);
}

extension PresentationRequestExtension on PresentationRequest {
  external JSPromise start();
  external JSPromise reconnect(String presentationId);
  external JSPromise getAvailability();
  external set onconnectionavailable(EventHandler value);
  external EventHandler get onconnectionavailable;
}

@JS('PresentationAvailability')
@staticInterop
class PresentationAvailability implements EventTarget {}

extension PresentationAvailabilityExtension on PresentationAvailability {
  external bool get value;
  external set onchange(EventHandler value);
  external EventHandler get onchange;
}

@JS('PresentationConnectionAvailableEvent')
@staticInterop
class PresentationConnectionAvailableEvent implements Event {
  external factory PresentationConnectionAvailableEvent(
    String type,
    PresentationConnectionAvailableEventInit eventInitDict,
  );
}

extension PresentationConnectionAvailableEventExtension
    on PresentationConnectionAvailableEvent {
  external PresentationConnection get connection;
}

@JS()
@staticInterop
@anonymous
class PresentationConnectionAvailableEventInit implements EventInit {
  external factory PresentationConnectionAvailableEventInit(
      {required PresentationConnection connection});
}

extension PresentationConnectionAvailableEventInitExtension
    on PresentationConnectionAvailableEventInit {
  external set connection(PresentationConnection value);
  external PresentationConnection get connection;
}

@JS('PresentationConnection')
@staticInterop
class PresentationConnection implements EventTarget {}

extension PresentationConnectionExtension on PresentationConnection {
  external void close();
  external void terminate();
  external void send(JSAny dataOrMessage);
  external String get id;
  external String get url;
  external PresentationConnectionState get state;
  external set onconnect(EventHandler value);
  external EventHandler get onconnect;
  external set onclose(EventHandler value);
  external EventHandler get onclose;
  external set onterminate(EventHandler value);
  external EventHandler get onterminate;
  external set binaryType(BinaryType value);
  external BinaryType get binaryType;
  external set onmessage(EventHandler value);
  external EventHandler get onmessage;
}

@JS('PresentationConnectionCloseEvent')
@staticInterop
class PresentationConnectionCloseEvent implements Event {
  external factory PresentationConnectionCloseEvent(
    String type,
    PresentationConnectionCloseEventInit eventInitDict,
  );
}

extension PresentationConnectionCloseEventExtension
    on PresentationConnectionCloseEvent {
  external PresentationConnectionCloseReason get reason;
  external String get message;
}

@JS()
@staticInterop
@anonymous
class PresentationConnectionCloseEventInit implements EventInit {
  external factory PresentationConnectionCloseEventInit({
    required PresentationConnectionCloseReason reason,
    String message,
  });
}

extension PresentationConnectionCloseEventInitExtension
    on PresentationConnectionCloseEventInit {
  external set reason(PresentationConnectionCloseReason value);
  external PresentationConnectionCloseReason get reason;
  external set message(String value);
  external String get message;
}

@JS('PresentationReceiver')
@staticInterop
class PresentationReceiver {}

extension PresentationReceiverExtension on PresentationReceiver {
  external JSPromise get connectionList;
}

@JS('PresentationConnectionList')
@staticInterop
class PresentationConnectionList implements EventTarget {}

extension PresentationConnectionListExtension on PresentationConnectionList {
  external JSArray get connections;
  external set onconnectionavailable(EventHandler value);
  external EventHandler get onconnectionavailable;
}
