// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';
import 'streams.dart';
import 'webcryptoapi.dart';

typedef RTCRtpTransform = JSObject;
typedef SmallCryptoKeyID = int;
typedef CryptoKeyID = JSAny;
typedef SFrameTransformRole = String;
typedef SFrameTransformErrorEventType = String;
typedef RTCEncodedVideoFrameType = String;

@JS()
@staticInterop
@anonymous
class SFrameTransformOptions {
  external factory SFrameTransformOptions({SFrameTransformRole role});
}

extension SFrameTransformOptionsExtension on SFrameTransformOptions {
  external set role(SFrameTransformRole value);
  external SFrameTransformRole get role;
}

@JS('SFrameTransform')
@staticInterop
class SFrameTransform implements EventTarget {
  external factory SFrameTransform([SFrameTransformOptions options]);
}

extension SFrameTransformExtension on SFrameTransform {
  external JSPromise setEncryptionKey(
    CryptoKey key, [
    CryptoKeyID keyID,
  ]);
  external set onerror(EventHandler value);
  external EventHandler get onerror;
  external ReadableStream get readable;
  external WritableStream get writable;
}

@JS('SFrameTransformErrorEvent')
@staticInterop
class SFrameTransformErrorEvent implements Event {
  external factory SFrameTransformErrorEvent(
    String type,
    SFrameTransformErrorEventInit eventInitDict,
  );
}

extension SFrameTransformErrorEventExtension on SFrameTransformErrorEvent {
  external SFrameTransformErrorEventType get errorType;
  external CryptoKeyID? get keyID;
  external JSAny? get frame;
}

@JS()
@staticInterop
@anonymous
class SFrameTransformErrorEventInit implements EventInit {
  external factory SFrameTransformErrorEventInit({
    required SFrameTransformErrorEventType errorType,
    required JSAny? frame,
    CryptoKeyID? keyID,
  });
}

extension SFrameTransformErrorEventInitExtension
    on SFrameTransformErrorEventInit {
  external set errorType(SFrameTransformErrorEventType value);
  external SFrameTransformErrorEventType get errorType;
  external set frame(JSAny? value);
  external JSAny? get frame;
  external set keyID(CryptoKeyID? value);
  external CryptoKeyID? get keyID;
}

@JS()
@staticInterop
@anonymous
class RTCEncodedVideoFrameMetadata {
  external factory RTCEncodedVideoFrameMetadata({
    int frameId,
    JSArray dependencies,
    int width,
    int height,
    int spatialIndex,
    int temporalIndex,
    int synchronizationSource,
    int payloadType,
    JSArray contributingSources,
    int timestamp,
    int rtpTimestamp,
  });
}

extension RTCEncodedVideoFrameMetadataExtension
    on RTCEncodedVideoFrameMetadata {
  external set frameId(int value);
  external int get frameId;
  external set dependencies(JSArray value);
  external JSArray get dependencies;
  external set width(int value);
  external int get width;
  external set height(int value);
  external int get height;
  external set spatialIndex(int value);
  external int get spatialIndex;
  external set temporalIndex(int value);
  external int get temporalIndex;
  external set synchronizationSource(int value);
  external int get synchronizationSource;
  external set payloadType(int value);
  external int get payloadType;
  external set contributingSources(JSArray value);
  external JSArray get contributingSources;
  external set timestamp(int value);
  external int get timestamp;
  external set rtpTimestamp(int value);
  external int get rtpTimestamp;
}

@JS('RTCEncodedVideoFrame')
@staticInterop
class RTCEncodedVideoFrame {}

extension RTCEncodedVideoFrameExtension on RTCEncodedVideoFrame {
  external RTCEncodedVideoFrameMetadata getMetadata();
  external RTCEncodedVideoFrameType get type;
  external set data(JSArrayBuffer value);
  external JSArrayBuffer get data;
}

@JS()
@staticInterop
@anonymous
class RTCEncodedAudioFrameMetadata {
  external factory RTCEncodedAudioFrameMetadata({
    int synchronizationSource,
    int payloadType,
    JSArray contributingSources,
    int sequenceNumber,
    int rtpTimestamp,
  });
}

extension RTCEncodedAudioFrameMetadataExtension
    on RTCEncodedAudioFrameMetadata {
  external set synchronizationSource(int value);
  external int get synchronizationSource;
  external set payloadType(int value);
  external int get payloadType;
  external set contributingSources(JSArray value);
  external JSArray get contributingSources;
  external set sequenceNumber(int value);
  external int get sequenceNumber;
  external set rtpTimestamp(int value);
  external int get rtpTimestamp;
}

@JS('RTCEncodedAudioFrame')
@staticInterop
class RTCEncodedAudioFrame {}

extension RTCEncodedAudioFrameExtension on RTCEncodedAudioFrame {
  external RTCEncodedAudioFrameMetadata getMetadata();
  external set data(JSArrayBuffer value);
  external JSArrayBuffer get data;
}

@JS('RTCTransformEvent')
@staticInterop
class RTCTransformEvent implements Event {}

extension RTCTransformEventExtension on RTCTransformEvent {
  external RTCRtpScriptTransformer get transformer;
}

@JS('RTCRtpScriptTransformer')
@staticInterop
class RTCRtpScriptTransformer {}

extension RTCRtpScriptTransformerExtension on RTCRtpScriptTransformer {
  external JSPromise generateKeyFrame([String rid]);
  external JSPromise sendKeyFrameRequest();
  external ReadableStream get readable;
  external WritableStream get writable;
  external JSAny? get options;
}

@JS('RTCRtpScriptTransform')
@staticInterop
class RTCRtpScriptTransform {
  external factory RTCRtpScriptTransform(
    Worker worker, [
    JSAny? options,
    JSArray transfer,
  ]);
}
