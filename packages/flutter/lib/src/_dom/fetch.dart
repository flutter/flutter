// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'attribution_reporting_api.dart';
import 'dom.dart';
import 'private_network_access.dart';
import 'referrer_policy.dart';
import 'streams.dart';
import 'trust_token_api.dart';

typedef HeadersInit = JSAny;
typedef XMLHttpRequestBodyInit = JSAny;
typedef BodyInit = JSAny;
typedef RequestInfo = JSAny;
typedef RequestDestination = String;
typedef RequestMode = String;
typedef RequestCredentials = String;
typedef RequestCache = String;
typedef RequestRedirect = String;
typedef RequestDuplex = String;
typedef RequestPriority = String;
typedef ResponseType = String;

@JS('Headers')
@staticInterop
class Headers {
  external factory Headers([HeadersInit init]);
}

extension HeadersExtension on Headers {
  external void append(
    String name,
    String value,
  );
  external void delete(String name);
  external String? get(String name);
  external JSArray getSetCookie();
  external bool has(String name);
  external void set(
    String name,
    String value,
  );
}

@JS('Request')
@staticInterop
class Request {
  external factory Request(
    RequestInfo input, [
    RequestInit init,
  ]);
}

extension RequestExtension on Request {
  external Request clone();
  external JSPromise arrayBuffer();
  external JSPromise blob();
  external JSPromise formData();
  external JSPromise json();
  external JSPromise text();
  external String get method;
  external String get url;
  external Headers get headers;
  external RequestDestination get destination;
  external String get referrer;
  external ReferrerPolicy get referrerPolicy;
  external RequestMode get mode;
  external RequestCredentials get credentials;
  external RequestCache get cache;
  external RequestRedirect get redirect;
  external String get integrity;
  external bool get keepalive;
  external bool get isReloadNavigation;
  external bool get isHistoryNavigation;
  external AbortSignal get signal;
  external RequestDuplex get duplex;
  external ReadableStream? get body;
  external bool get bodyUsed;
}

@JS()
@staticInterop
@anonymous
class RequestInit {
  external factory RequestInit({
    AttributionReportingRequestOptions attributionReporting,
    String method,
    HeadersInit headers,
    BodyInit? body,
    String referrer,
    ReferrerPolicy referrerPolicy,
    RequestMode mode,
    RequestCredentials credentials,
    RequestCache cache,
    RequestRedirect redirect,
    String integrity,
    bool keepalive,
    AbortSignal? signal,
    RequestDuplex duplex,
    RequestPriority priority,
    JSAny? window,
    RequestTargetAddressSpace targetAddressSpace,
    bool sharedStorageWritable,
    PrivateToken privateToken,
  });
}

extension RequestInitExtension on RequestInit {
  external set attributionReporting(AttributionReportingRequestOptions value);
  external AttributionReportingRequestOptions get attributionReporting;
  external set method(String value);
  external String get method;
  external set headers(HeadersInit value);
  external HeadersInit get headers;
  external set body(BodyInit? value);
  external BodyInit? get body;
  external set referrer(String value);
  external String get referrer;
  external set referrerPolicy(ReferrerPolicy value);
  external ReferrerPolicy get referrerPolicy;
  external set mode(RequestMode value);
  external RequestMode get mode;
  external set credentials(RequestCredentials value);
  external RequestCredentials get credentials;
  external set cache(RequestCache value);
  external RequestCache get cache;
  external set redirect(RequestRedirect value);
  external RequestRedirect get redirect;
  external set integrity(String value);
  external String get integrity;
  external set keepalive(bool value);
  external bool get keepalive;
  external set signal(AbortSignal? value);
  external AbortSignal? get signal;
  external set duplex(RequestDuplex value);
  external RequestDuplex get duplex;
  external set priority(RequestPriority value);
  external RequestPriority get priority;
  external set window(JSAny? value);
  external JSAny? get window;
  external set targetAddressSpace(RequestTargetAddressSpace value);
  external RequestTargetAddressSpace get targetAddressSpace;
  external set sharedStorageWritable(bool value);
  external bool get sharedStorageWritable;
  external set privateToken(PrivateToken value);
  external PrivateToken get privateToken;
}

@JS('Response')
@staticInterop
class Response {
  external factory Response([
    BodyInit? body,
    ResponseInit init,
  ]);

  external static Response error();
  external static Response redirect(
    String url, [
    int status,
  ]);
  @JS('json')
  external static Response json_(
    JSAny? data, [
    ResponseInit init,
  ]);
}

extension ResponseExtension on Response {
  external Response clone();
  external JSPromise arrayBuffer();
  external JSPromise blob();
  external JSPromise formData();
  external JSPromise json();
  external JSPromise text();
  external ResponseType get type;
  external String get url;
  external bool get redirected;
  external int get status;
  external bool get ok;
  external String get statusText;
  external Headers get headers;
  external ReadableStream? get body;
  external bool get bodyUsed;
}

@JS()
@staticInterop
@anonymous
class ResponseInit {
  external factory ResponseInit({
    int status,
    String statusText,
    HeadersInit headers,
  });
}

extension ResponseInitExtension on ResponseInit {
  external set status(int value);
  external int get status;
  external set statusText(String value);
  external String get statusText;
  external set headers(HeadersInit value);
  external HeadersInit get headers;
}
