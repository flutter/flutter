// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'background_fetch.dart';
import 'background_sync.dart';
import 'content_index.dart';
import 'cookie_store.dart';
import 'dom.dart';
import 'fetch.dart';
import 'html.dart';
import 'notifications.dart';
import 'page_lifecycle.dart';
import 'payment_handler.dart';
import 'periodic_background_sync.dart';
import 'push_api.dart';

typedef ServiceWorkerState = String;
typedef ServiceWorkerUpdateViaCache = String;
typedef FrameType = String;
typedef ClientType = String;

@JS('ServiceWorker')
@staticInterop
class ServiceWorker implements EventTarget {}

extension ServiceWorkerExtension on ServiceWorker {
  external void postMessage(
    JSAny? message, [
    JSObject optionsOrTransfer,
  ]);
  external String get scriptURL;
  external ServiceWorkerState get state;
  external set onstatechange(EventHandler value);
  external EventHandler get onstatechange;
  external set onerror(EventHandler value);
  external EventHandler get onerror;
}

@JS('ServiceWorkerRegistration')
@staticInterop
class ServiceWorkerRegistration implements EventTarget {}

extension ServiceWorkerRegistrationExtension on ServiceWorkerRegistration {
  external JSPromise showNotification(
    String title, [
    NotificationOptions options,
  ]);
  external JSPromise getNotifications([GetNotificationOptions filter]);
  external JSPromise update();
  external JSPromise unregister();
  external BackgroundFetchManager get backgroundFetch;
  external SyncManager get sync;
  external ContentIndex get index;
  external CookieStoreManager get cookies;
  external PaymentManager get paymentManager;
  external PeriodicSyncManager get periodicSync;
  external PushManager get pushManager;
  external ServiceWorker? get installing;
  external ServiceWorker? get waiting;
  external ServiceWorker? get active;
  external NavigationPreloadManager get navigationPreload;
  external String get scope;
  external ServiceWorkerUpdateViaCache get updateViaCache;
  external set onupdatefound(EventHandler value);
  external EventHandler get onupdatefound;
}

@JS('ServiceWorkerContainer')
@staticInterop
class ServiceWorkerContainer implements EventTarget {}

extension ServiceWorkerContainerExtension on ServiceWorkerContainer {
  external JSPromise register(
    String scriptURL, [
    RegistrationOptions options,
  ]);
  external JSPromise getRegistration([String clientURL]);
  external JSPromise getRegistrations();
  external void startMessages();
  external ServiceWorker? get controller;
  external JSPromise get ready;
  external set oncontrollerchange(EventHandler value);
  external EventHandler get oncontrollerchange;
  external set onmessage(EventHandler value);
  external EventHandler get onmessage;
  external set onmessageerror(EventHandler value);
  external EventHandler get onmessageerror;
}

@JS()
@staticInterop
@anonymous
class RegistrationOptions {
  external factory RegistrationOptions({
    String scope,
    WorkerType type,
    ServiceWorkerUpdateViaCache updateViaCache,
  });
}

extension RegistrationOptionsExtension on RegistrationOptions {
  external set scope(String value);
  external String get scope;
  external set type(WorkerType value);
  external WorkerType get type;
  external set updateViaCache(ServiceWorkerUpdateViaCache value);
  external ServiceWorkerUpdateViaCache get updateViaCache;
}

@JS('NavigationPreloadManager')
@staticInterop
class NavigationPreloadManager {}

extension NavigationPreloadManagerExtension on NavigationPreloadManager {
  external JSPromise enable();
  external JSPromise disable();
  external JSPromise setHeaderValue(String value);
  external JSPromise getState();
}

@JS()
@staticInterop
@anonymous
class NavigationPreloadState {
  external factory NavigationPreloadState({
    bool enabled,
    String headerValue,
  });
}

extension NavigationPreloadStateExtension on NavigationPreloadState {
  external set enabled(bool value);
  external bool get enabled;
  external set headerValue(String value);
  external String get headerValue;
}

@JS('ServiceWorkerGlobalScope')
@staticInterop
class ServiceWorkerGlobalScope implements WorkerGlobalScope {}

extension ServiceWorkerGlobalScopeExtension on ServiceWorkerGlobalScope {
  external JSPromise skipWaiting();
  external set onbackgroundfetchsuccess(EventHandler value);
  external EventHandler get onbackgroundfetchsuccess;
  external set onbackgroundfetchfail(EventHandler value);
  external EventHandler get onbackgroundfetchfail;
  external set onbackgroundfetchabort(EventHandler value);
  external EventHandler get onbackgroundfetchabort;
  external set onbackgroundfetchclick(EventHandler value);
  external EventHandler get onbackgroundfetchclick;
  external set onsync(EventHandler value);
  external EventHandler get onsync;
  external set oncontentdelete(EventHandler value);
  external EventHandler get oncontentdelete;
  external CookieStore get cookieStore;
  external set oncookiechange(EventHandler value);
  external EventHandler get oncookiechange;
  external set onnotificationclick(EventHandler value);
  external EventHandler get onnotificationclick;
  external set onnotificationclose(EventHandler value);
  external EventHandler get onnotificationclose;
  external set oncanmakepayment(EventHandler value);
  external EventHandler get oncanmakepayment;
  external set onpaymentrequest(EventHandler value);
  external EventHandler get onpaymentrequest;
  external set onperiodicsync(EventHandler value);
  external EventHandler get onperiodicsync;
  external set onpush(EventHandler value);
  external EventHandler get onpush;
  external set onpushsubscriptionchange(EventHandler value);
  external EventHandler get onpushsubscriptionchange;
  external Clients get clients;
  external ServiceWorkerRegistration get registration;
  external ServiceWorker get serviceWorker;
  external set oninstall(EventHandler value);
  external EventHandler get oninstall;
  external set onactivate(EventHandler value);
  external EventHandler get onactivate;
  external set onfetch(EventHandler value);
  external EventHandler get onfetch;
  external set onmessage(EventHandler value);
  external EventHandler get onmessage;
  external set onmessageerror(EventHandler value);
  external EventHandler get onmessageerror;
}

@JS('Client')
@staticInterop
class Client {}

extension ClientExtension on Client {
  external void postMessage(
    JSAny? message, [
    JSObject optionsOrTransfer,
  ]);
  external ClientLifecycleState get lifecycleState;
  external String get url;
  external FrameType get frameType;
  external String get id;
  external ClientType get type;
}

@JS('WindowClient')
@staticInterop
class WindowClient implements Client {}

extension WindowClientExtension on WindowClient {
  external JSPromise focus();
  external JSPromise navigate(String url);
  external DocumentVisibilityState get visibilityState;
  external bool get focused;
  external JSArray get ancestorOrigins;
}

@JS('Clients')
@staticInterop
class Clients {}

extension ClientsExtension on Clients {
  external JSPromise get(String id);
  external JSPromise matchAll([ClientQueryOptions options]);
  external JSPromise openWindow(String url);
  external JSPromise claim();
}

@JS()
@staticInterop
@anonymous
class ClientQueryOptions {
  external factory ClientQueryOptions({
    bool includeUncontrolled,
    ClientType type,
  });
}

extension ClientQueryOptionsExtension on ClientQueryOptions {
  external set includeUncontrolled(bool value);
  external bool get includeUncontrolled;
  external set type(ClientType value);
  external ClientType get type;
}

@JS('ExtendableEvent')
@staticInterop
class ExtendableEvent implements Event {
  external factory ExtendableEvent(
    String type, [
    ExtendableEventInit eventInitDict,
  ]);
}

extension ExtendableEventExtension on ExtendableEvent {
  external void waitUntil(JSPromise f);
}

@JS()
@staticInterop
@anonymous
class ExtendableEventInit implements EventInit {
  external factory ExtendableEventInit();
}

@JS('FetchEvent')
@staticInterop
class FetchEvent implements ExtendableEvent {
  external factory FetchEvent(
    String type,
    FetchEventInit eventInitDict,
  );
}

extension FetchEventExtension on FetchEvent {
  external void respondWith(JSPromise r);
  external Request get request;
  external JSPromise get preloadResponse;
  external String get clientId;
  external String get resultingClientId;
  external String get replacesClientId;
  external JSPromise get handled;
}

@JS()
@staticInterop
@anonymous
class FetchEventInit implements ExtendableEventInit {
  external factory FetchEventInit({
    required Request request,
    JSPromise preloadResponse,
    String clientId,
    String resultingClientId,
    String replacesClientId,
    JSPromise handled,
  });
}

extension FetchEventInitExtension on FetchEventInit {
  external set request(Request value);
  external Request get request;
  external set preloadResponse(JSPromise value);
  external JSPromise get preloadResponse;
  external set clientId(String value);
  external String get clientId;
  external set resultingClientId(String value);
  external String get resultingClientId;
  external set replacesClientId(String value);
  external String get replacesClientId;
  external set handled(JSPromise value);
  external JSPromise get handled;
}

@JS('ExtendableMessageEvent')
@staticInterop
class ExtendableMessageEvent implements ExtendableEvent {
  external factory ExtendableMessageEvent(
    String type, [
    ExtendableMessageEventInit eventInitDict,
  ]);
}

extension ExtendableMessageEventExtension on ExtendableMessageEvent {
  external JSAny? get data;
  external String get origin;
  external String get lastEventId;
  external JSObject? get source;
  external JSArray get ports;
}

@JS()
@staticInterop
@anonymous
class ExtendableMessageEventInit implements ExtendableEventInit {
  external factory ExtendableMessageEventInit({
    JSAny? data,
    String origin,
    String lastEventId,
    JSObject? source,
    JSArray ports,
  });
}

extension ExtendableMessageEventInitExtension on ExtendableMessageEventInit {
  external set data(JSAny? value);
  external JSAny? get data;
  external set origin(String value);
  external String get origin;
  external set lastEventId(String value);
  external String get lastEventId;
  external set source(JSObject? value);
  external JSObject? get source;
  external set ports(JSArray value);
  external JSArray get ports;
}

@JS('Cache')
@staticInterop
class Cache {}

extension CacheExtension on Cache {
  external JSPromise match(
    RequestInfo request, [
    CacheQueryOptions options,
  ]);
  external JSPromise matchAll([
    RequestInfo request,
    CacheQueryOptions options,
  ]);
  external JSPromise add(RequestInfo request);
  external JSPromise addAll(JSArray requests);
  external JSPromise put(
    RequestInfo request,
    Response response,
  );
  external JSPromise delete(
    RequestInfo request, [
    CacheQueryOptions options,
  ]);
  external JSPromise keys([
    RequestInfo request,
    CacheQueryOptions options,
  ]);
}

@JS()
@staticInterop
@anonymous
class CacheQueryOptions {
  external factory CacheQueryOptions({
    bool ignoreSearch,
    bool ignoreMethod,
    bool ignoreVary,
  });
}

extension CacheQueryOptionsExtension on CacheQueryOptions {
  external set ignoreSearch(bool value);
  external bool get ignoreSearch;
  external set ignoreMethod(bool value);
  external bool get ignoreMethod;
  external set ignoreVary(bool value);
  external bool get ignoreVary;
}

@JS('CacheStorage')
@staticInterop
class CacheStorage {}

extension CacheStorageExtension on CacheStorage {
  external JSPromise match(
    RequestInfo request, [
    MultiCacheQueryOptions options,
  ]);
  external JSPromise has(String cacheName);
  external JSPromise open(String cacheName);
  external JSPromise delete(String cacheName);
  external JSPromise keys();
}

@JS()
@staticInterop
@anonymous
class MultiCacheQueryOptions implements CacheQueryOptions {
  external factory MultiCacheQueryOptions({String cacheName});
}

extension MultiCacheQueryOptionsExtension on MultiCacheQueryOptions {
  external set cacheName(String value);
  external String get cacheName;
}
