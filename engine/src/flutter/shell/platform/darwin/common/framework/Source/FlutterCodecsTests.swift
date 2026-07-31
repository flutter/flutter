// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Testing

import InternalFlutterSwiftCommon

@Suite struct FlutterCodecsTests {

  // MARK: - FlutterStringCodec Tests

  @Test func stringCodecCanEncodeAndDecodeNil() {
    let codec = FlutterStringCodec.sharedInstance()
    #expect(codec.encode(nil) == nil)
    #expect(codec.decode(nil) == nil)
  }

  @Test func stringCodecCanEncodeAndDecodeEmptyString() {
    let codec = FlutterStringCodec.sharedInstance()
    let encoded = codec.encode("")
    #expect(encoded == Data())
    let decoded = codec.decode(Data()) as? String
    #expect(decoded == "")
  }

  @Test func stringCodecCanEncodeAndDecodeAsciiString() {
    let value = "hello world"
    let codec = FlutterStringCodec.sharedInstance()
    let encoded = codec.encode(value)
    let decoded = codec.decode(encoded) as? String
    #expect(decoded == value)
  }

  @Test func stringCodecCanEncodeAndDecodeNonAsciiString() {
    let value = "hello \u{263A} world"
    let codec = FlutterStringCodec.sharedInstance()
    let encoded = codec.encode(value)
    let decoded = codec.decode(encoded) as? String
    #expect(decoded == value)
  }

  @Test func stringCodecCanEncodeAndDecodeNonBMPString() {
    let value = "hello \u{1F602} world"
    let codec = FlutterStringCodec.sharedInstance()
    let encoded = codec.encode(value)
    let decoded = codec.decode(encoded) as? String
    #expect(decoded == value)
  }

  // MARK: - FlutterJSONMessageCodec Tests

  @Test func jsonCodecCanDecodeZeroLength() {
    let codec = FlutterJSONMessageCodec.sharedInstance()
    #expect(codec.decode(Data()) == nil)
  }

  @Test func jsonCodecCanEncodeAndDecodeNil() {
    let codec = FlutterJSONMessageCodec.sharedInstance()
    #expect(codec.encode(nil) == nil)
    #expect(codec.decode(nil) == nil)
  }

  @Test func jsonCodecCanEncodeAndDecodeArray() {
    let value: [Any] = [NSNull(), "hello", 3.14, 47, ["a": "nested"]]
    let codec = FlutterJSONMessageCodec.sharedInstance()
    let encoded = codec.encode(value)
    let decoded = codec.decode(encoded) as? [Any]
    #expect(decoded != nil)
    #expect(decoded?.count == value.count)
  }

  @Test func jsonCodecCanEncodeAndDecodeDictionary() {
    let value: [String: Any] = ["a": 3.14, "b": 47, "c": NSNull(), "d": ["nested"]]
    let codec = FlutterJSONMessageCodec.sharedInstance()
    let encoded = codec.encode(value)
    let decoded = codec.decode(encoded) as? [String: Any]
    #expect(decoded != nil)
  }

  // MARK: - FlutterJSONMethodCodec Tests

  @Test func jsonMethodCodecCanEncodeAndDecodeMethodCall() {
    let codec = FlutterJSONMethodCodec.sharedInstance()
    let call = FlutterMethodCall(methodName: "foo", arguments: ["bar": 42])
    let encoded = codec.encodeMethodCall(call)
    let decoded = codec.decodeMethodCall(encoded)
    #expect(decoded.method == "foo")
    let args = decoded.arguments as? [String: Int]
    #expect(args?["bar"] == 42)
  }

  @Test func jsonMethodCodecCanEncodeAndDecodeSuccessEnvelope() {
    let codec = FlutterJSONMethodCodec.sharedInstance()
    let encoded = codec.encodeSuccessEnvelope("result")
    let decoded = codec.decodeEnvelope(encoded) as? String
    #expect(decoded == "result")
  }

  @Test func jsonMethodCodecCanEncodeAndDecodeErrorEnvelope() {
    let codec = FlutterJSONMethodCodec.sharedInstance()
    let error = FlutterError(code: "404", message: "not found", details: "info")
    let encoded = codec.encodeErrorEnvelope(error)
    let decoded = codec.decodeEnvelope(encoded) as? FlutterError
    #expect(decoded?.code == "404")
    #expect(decoded?.message == "not found")
    #expect(decoded?.details as? String == "info")
  }
}
