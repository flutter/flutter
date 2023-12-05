// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

// ignore_for_file: public_member_api_docs

import 'dart:js_interop';

import 'dom.dart';
import 'fetch.dart';
import 'html.dart';
import 'service_workers.dart';

typedef BackgroundFetchResult = String;
typedef BackgroundFetchFailureReason = String;

@JS('BackgroundFetchManager')
@staticInterop
class BackgroundFetchManager {}

extension BackgroundFetchManagerExtension on BackgroundFetchManager {
  external JSPromise fetch(
    String id,
    JSAny requests, [
    BackgroundFetchOptions options,
  ]);
  external JSPromise get(String id);
  external JSPromise getIds();
}

@JS()
@staticInterop
@anonymous
class BackgroundFetchUIOptions {
  external factory BackgroundFetchUIOptions({
    JSArray icons,
    String title,
  });
}

extension BackgroundFetchUIOptionsExtension on BackgroundFetchUIOptions {
  external set icons(JSArray value);
  external JSArray get icons;
  external set title(String value);
  external String get title;
}

@JS()
@staticInterop
@anonymous
class BackgroundFetchOptions implements BackgroundFetchUIOptions {
  external factory BackgroundFetchOptions({int downloadTotal});
}

extension BackgroundFetchOptionsExtension on BackgroundFetchOptions {
  external set downloadTotal(int value);
  external int get downloadTotal;
}

@JS('BackgroundFetchRegistration')
@staticInterop
class BackgroundFetchRegistration implements EventTarget {}

extension BackgroundFetchRegistrationExtension on BackgroundFetchRegistration {
  external JSPromise abort();
  external JSPromise match(
    RequestInfo request, [
    CacheQueryOptions options,
  ]);
  external JSPromise matchAll([
    RequestInfo request,
    CacheQueryOptions options,
  ]);
  external String get id;
  external int get uploadTotal;
  external int get uploaded;
  external int get downloadTotal;
  external int get downloaded;
  external BackgroundFetchResult get result;
  external BackgroundFetchFailureReason get failureReason;
  external bool get recordsAvailable;
  external set onprogress(EventHandler value);
  external EventHandler get onprogress;
}

@JS('BackgroundFetchRecord')
@staticInterop
class BackgroundFetchRecord {}

extension BackgroundFetchRecordExtension on BackgroundFetchRecord {
  external Request get request;
  external JSPromise get responseReady;
}

@JS('BackgroundFetchEvent')
@staticInterop
class BackgroundFetchEvent implements ExtendableEvent {
  external factory BackgroundFetchEvent(
    String type,
    BackgroundFetchEventInit init,
  );
}

extension BackgroundFetchEventExtension on BackgroundFetchEvent {
  external BackgroundFetchRegistration get registration;
}

@JS()
@staticInterop
@anonymous
class BackgroundFetchEventInit implements ExtendableEventInit {
  external factory BackgroundFetchEventInit(
      {required BackgroundFetchRegistration registration});
}

extension BackgroundFetchEventInitExtension on BackgroundFetchEventInit {
  external set registration(BackgroundFetchRegistration value);
  external BackgroundFetchRegistration get registration;
}

@JS('BackgroundFetchUpdateUIEvent')
@staticInterop
class BackgroundFetchUpdateUIEvent implements BackgroundFetchEvent {
  external factory BackgroundFetchUpdateUIEvent(
    String type,
    BackgroundFetchEventInit init,
  );
}

extension BackgroundFetchUpdateUIEventExtension
    on BackgroundFetchUpdateUIEvent {
  external JSPromise updateUI([BackgroundFetchUIOptions options]);
}
