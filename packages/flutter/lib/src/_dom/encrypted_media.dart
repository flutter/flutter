// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'webidl.dart';

typedef MediaKeysRequirement = String;
typedef MediaKeySessionType = String;
typedef MediaKeySessionClosedReason = String;
typedef MediaKeyStatus = String;
typedef MediaKeyMessageType = String;

@JS()
@staticInterop
@anonymous
class MediaKeySystemConfiguration {
  external factory MediaKeySystemConfiguration({
    String label,
    JSArray initDataTypes,
    JSArray audioCapabilities,
    JSArray videoCapabilities,
    MediaKeysRequirement distinctiveIdentifier,
    MediaKeysRequirement persistentState,
    JSArray sessionTypes,
  });
}

extension MediaKeySystemConfigurationExtension on MediaKeySystemConfiguration {
  external set label(String value);
  external String get label;
  external set initDataTypes(JSArray value);
  external JSArray get initDataTypes;
  external set audioCapabilities(JSArray value);
  external JSArray get audioCapabilities;
  external set videoCapabilities(JSArray value);
  external JSArray get videoCapabilities;
  external set distinctiveIdentifier(MediaKeysRequirement value);
  external MediaKeysRequirement get distinctiveIdentifier;
  external set persistentState(MediaKeysRequirement value);
  external MediaKeysRequirement get persistentState;
  external set sessionTypes(JSArray value);
  external JSArray get sessionTypes;
}

@JS()
@staticInterop
@anonymous
class MediaKeySystemMediaCapability {
  external factory MediaKeySystemMediaCapability({
    String contentType,
    String? encryptionScheme,
    String robustness,
  });
}

extension MediaKeySystemMediaCapabilityExtension
    on MediaKeySystemMediaCapability {
  external set contentType(String value);
  external String get contentType;
  external set encryptionScheme(String? value);
  external String? get encryptionScheme;
  external set robustness(String value);
  external String get robustness;
}

@JS('MediaKeySystemAccess')
@staticInterop
class MediaKeySystemAccess {}

extension MediaKeySystemAccessExtension on MediaKeySystemAccess {
  external MediaKeySystemConfiguration getConfiguration();
  external JSPromise createMediaKeys();
  external String get keySystem;
}

@JS('MediaKeys')
@staticInterop
class MediaKeys {}

extension MediaKeysExtension on MediaKeys {
  external MediaKeySession createSession([MediaKeySessionType sessionType]);
  external JSPromise setServerCertificate(BufferSource serverCertificate);
}

@JS('MediaKeySession')
@staticInterop
class MediaKeySession implements EventTarget {}

extension MediaKeySessionExtension on MediaKeySession {
  external JSPromise generateRequest(
    String initDataType,
    BufferSource initData,
  );
  external JSPromise load(String sessionId);
  external JSPromise update(BufferSource response);
  external JSPromise close();
  external JSPromise remove();
  external String get sessionId;
  external num get expiration;
  external JSPromise get closed;
  external MediaKeyStatusMap get keyStatuses;
  external set onkeystatuseschange(EventHandler value);
  external EventHandler get onkeystatuseschange;
  external set onmessage(EventHandler value);
  external EventHandler get onmessage;
}

@JS('MediaKeyStatusMap')
@staticInterop
class MediaKeyStatusMap {}

extension MediaKeyStatusMapExtension on MediaKeyStatusMap {
  external bool has(BufferSource keyId);
  external MediaKeyStatus? get(BufferSource keyId);
  external int get size;
}

@JS('MediaKeyMessageEvent')
@staticInterop
class MediaKeyMessageEvent implements Event {
  external factory MediaKeyMessageEvent(
    String type,
    MediaKeyMessageEventInit eventInitDict,
  );
}

extension MediaKeyMessageEventExtension on MediaKeyMessageEvent {
  external MediaKeyMessageType get messageType;
  external JSArrayBuffer get message;
}

@JS()
@staticInterop
@anonymous
class MediaKeyMessageEventInit implements EventInit {
  external factory MediaKeyMessageEventInit({
    required MediaKeyMessageType messageType,
    required JSArrayBuffer message,
  });
}

extension MediaKeyMessageEventInitExtension on MediaKeyMessageEventInit {
  external set messageType(MediaKeyMessageType value);
  external MediaKeyMessageType get messageType;
  external set message(JSArrayBuffer value);
  external JSArrayBuffer get message;
}

@JS('MediaEncryptedEvent')
@staticInterop
class MediaEncryptedEvent implements Event {
  external factory MediaEncryptedEvent(
    String type, [
    MediaEncryptedEventInit eventInitDict,
  ]);
}

extension MediaEncryptedEventExtension on MediaEncryptedEvent {
  external String get initDataType;
  external JSArrayBuffer? get initData;
}

@JS()
@staticInterop
@anonymous
class MediaEncryptedEventInit implements EventInit {
  external factory MediaEncryptedEventInit({
    String initDataType,
    JSArrayBuffer? initData,
  });
}

extension MediaEncryptedEventInitExtension on MediaEncryptedEventInit {
  external set initDataType(String value);
  external String get initDataType;
  external set initData(JSArrayBuffer? value);
  external JSArrayBuffer? get initData;
}
