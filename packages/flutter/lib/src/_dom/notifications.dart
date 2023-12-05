// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'hr_time.dart';
import 'html.dart';
import 'service_workers.dart';
import 'vibration.dart';

typedef NotificationPermissionCallback = JSFunction;
typedef NotificationPermission = String;
typedef NotificationDirection = String;

@JS('Notification')
@staticInterop
class Notification implements EventTarget {
  external factory Notification(
    String title, [
    NotificationOptions options,
  ]);

  external static JSPromise requestPermission(
      [NotificationPermissionCallback deprecatedCallback]);
  external static NotificationPermission get permission;
  external static int get maxActions;
}

extension NotificationExtension on Notification {
  external void close();
  external set onclick(EventHandler value);
  external EventHandler get onclick;
  external set onshow(EventHandler value);
  external EventHandler get onshow;
  external set onerror(EventHandler value);
  external EventHandler get onerror;
  external set onclose(EventHandler value);
  external EventHandler get onclose;
  external String get title;
  external NotificationDirection get dir;
  external String get lang;
  external String get body;
  external String get tag;
  external String get image;
  external String get icon;
  external String get badge;
  external JSArray get vibrate;
  external EpochTimeStamp get timestamp;
  external bool get renotify;
  external bool? get silent;
  external bool get requireInteraction;
  external JSAny? get data;
  external JSArray get actions;
}

@JS()
@staticInterop
@anonymous
class NotificationOptions {
  external factory NotificationOptions({
    NotificationDirection dir,
    String lang,
    String body,
    String tag,
    String image,
    String icon,
    String badge,
    VibratePattern vibrate,
    EpochTimeStamp timestamp,
    bool renotify,
    bool? silent,
    bool requireInteraction,
    JSAny? data,
    JSArray actions,
  });
}

extension NotificationOptionsExtension on NotificationOptions {
  external set dir(NotificationDirection value);
  external NotificationDirection get dir;
  external set lang(String value);
  external String get lang;
  external set body(String value);
  external String get body;
  external set tag(String value);
  external String get tag;
  external set image(String value);
  external String get image;
  external set icon(String value);
  external String get icon;
  external set badge(String value);
  external String get badge;
  external set vibrate(VibratePattern value);
  external VibratePattern get vibrate;
  external set timestamp(EpochTimeStamp value);
  external EpochTimeStamp get timestamp;
  external set renotify(bool value);
  external bool get renotify;
  external set silent(bool? value);
  external bool? get silent;
  external set requireInteraction(bool value);
  external bool get requireInteraction;
  external set data(JSAny? value);
  external JSAny? get data;
  external set actions(JSArray value);
  external JSArray get actions;
}

@JS()
@staticInterop
@anonymous
class NotificationAction {
  external factory NotificationAction({
    required String action,
    required String title,
    String icon,
  });
}

extension NotificationActionExtension on NotificationAction {
  external set action(String value);
  external String get action;
  external set title(String value);
  external String get title;
  external set icon(String value);
  external String get icon;
}

@JS()
@staticInterop
@anonymous
class GetNotificationOptions {
  external factory GetNotificationOptions({String tag});
}

extension GetNotificationOptionsExtension on GetNotificationOptions {
  external set tag(String value);
  external String get tag;
}

@JS('NotificationEvent')
@staticInterop
class NotificationEvent implements ExtendableEvent {
  external factory NotificationEvent(
    String type,
    NotificationEventInit eventInitDict,
  );
}

extension NotificationEventExtension on NotificationEvent {
  external Notification get notification;
  external String get action;
}

@JS()
@staticInterop
@anonymous
class NotificationEventInit implements ExtendableEventInit {
  external factory NotificationEventInit({
    required Notification notification,
    String action,
  });
}

extension NotificationEventInitExtension on NotificationEventInit {
  external set notification(Notification value);
  external Notification get notification;
  external set action(String value);
  external String get action;
}
