// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

@JS('HTMLPortalElement')
@staticInterop
class HTMLPortalElement implements HTMLElement {
  external factory HTMLPortalElement();
}

extension HTMLPortalElementExtension on HTMLPortalElement {
  external JSPromise activate([PortalActivateOptions options]);
  external void postMessage(
    JSAny? message, [
    StructuredSerializeOptions options,
  ]);
  external set src(String value);
  external String get src;
  external set referrerPolicy(String value);
  external String get referrerPolicy;
  external set onmessage(EventHandler value);
  external EventHandler get onmessage;
  external set onmessageerror(EventHandler value);
  external EventHandler get onmessageerror;
}

@JS()
@staticInterop
@anonymous
class PortalActivateOptions implements StructuredSerializeOptions {
  external factory PortalActivateOptions({JSAny? data});
}

extension PortalActivateOptionsExtension on PortalActivateOptions {
  external set data(JSAny? value);
  external JSAny? get data;
}

@JS('PortalHost')
@staticInterop
class PortalHost implements EventTarget {}

extension PortalHostExtension on PortalHost {
  external void postMessage(
    JSAny? message, [
    StructuredSerializeOptions options,
  ]);
  external set onmessage(EventHandler value);
  external EventHandler get onmessage;
  external set onmessageerror(EventHandler value);
  external EventHandler get onmessageerror;
}

@JS('PortalActivateEvent')
@staticInterop
class PortalActivateEvent implements Event {
  external factory PortalActivateEvent(
    String type, [
    PortalActivateEventInit eventInitDict,
  ]);
}

extension PortalActivateEventExtension on PortalActivateEvent {
  external HTMLPortalElement adoptPredecessor();
  external JSAny? get data;
}

@JS()
@staticInterop
@anonymous
class PortalActivateEventInit implements EventInit {
  external factory PortalActivateEventInit({JSAny? data});
}

extension PortalActivateEventInitExtension on PortalActivateEventInit {
  external set data(JSAny? value);
  external JSAny? get data;
}
