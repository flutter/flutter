// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation
import Testing

import InternalFlutterSwiftCommon

@Suite struct FlutterCodecsTests {

  // MARK: - FlutterStringCodec Tests

  @Test("FlutterStringCodec encodes and decodes string inputs", arguments: [
    "",
    "hello world",
    "hello \u{263A} world",
    "hello \u{1F602} world",
  ])
  func stringCodecEncoding(value: String) {
    let codec = FlutterStringCodec.sharedInstance()
    let encoded = codec.encode(value)
    let decoded = codec.decode(encoded) as? String
    #expect(decoded == value)
  }

  @Test func stringCodecCanEncodeAndDecodeNil() {
    let codec = FlutterStringCodec.sharedInstance()
    #expect(codec.encode(nil) == nil)
    #expect(codec.decode(nil) == nil)
  }

  // MARK: - FlutterJSONMessageCodec Tests

  @Test("FlutterJSONMessageCodec encodes and decodes complex payloads", arguments: [
    [NSNull(), "hello", 3.14, 47, ["a": "nested"]] as [Any],
    ["a": 3.14, "b": 47, "c": NSNull(), "d": ["nested"]] as [String: Any],
  ])
  func jsonCodecPayloads(value: Any) {
    let codec = FlutterJSONMessageCodec.sharedInstance()
    let encoded = codec.encode(value)
    let decoded = codec.decode(encoded)
    #expect(decoded != nil)
  }

  @Test func jsonCodecCanDecodeZeroLength() {
    let codec = FlutterJSONMessageCodec.sharedInstance()
    #expect(codec.decode(Data()) == nil)
  }

  @Test func jsonCodecCanEncodeAndDecodeNil() {
    let codec = FlutterJSONMessageCodec.sharedInstance()
    #expect(codec.encode(nil) == nil)
    #expect(codec.decode(nil) == nil)
  }

  // MARK: - FlutterJSONMethodCodec Tests

  struct MethodCallTestCase {
    let method: String
    let arguments: Any?
  }

  @Test("FlutterJSONMethodCodec encodes and decodes method calls", arguments: [
    MethodCallTestCase(method: "foo", arguments: ["bar": 42]),
    MethodCallTestCase(method: "ping", arguments: nil),
    MethodCallTestCase(method: "echo", arguments: "hello"),
  ])
  func jsonMethodCodecMethodCalls(testCase: MethodCallTestCase) {
    let codec = FlutterJSONMethodCodec.sharedInstance()
    let call = FlutterMethodCall(methodName: testCase.method, arguments: testCase.arguments)
    let encoded = codec.encodeMethodCall(call)
    let decoded = codec.decodeMethodCall(encoded)
    #expect(decoded.method == testCase.method)
  }

  @Test("FlutterJSONMethodCodec encodes and decodes success envelopes", arguments: [
    "result",
    42,
    ["key": "value"],
    NSNull(),
  ])
  func jsonMethodCodecSuccessEnvelopes(result: Any) {
    let codec = FlutterJSONMethodCodec.sharedInstance()
    let encoded = codec.encodeSuccessEnvelope(result)
    let decoded = codec.decodeEnvelope(encoded)
    #expect(decoded != nil)
  }

  struct ErrorEnvelopeTestCase {
    let code: String
    let message: String?
    let details: Any?
  }

  @Test("FlutterJSONMethodCodec encodes and decodes error envelopes", arguments: [
    ErrorEnvelopeTestCase(code: "404", message: "not found", details: "info"),
    ErrorEnvelopeTestCase(code: "INVALID_ARG", message: nil, details: nil),
  ])
  func jsonMethodCodecErrorEnvelopes(testCase: ErrorEnvelopeTestCase) {
    let codec = FlutterJSONMethodCodec.sharedInstance()
    let error = FlutterError(code: testCase.code, message: testCase.message, details: testCase.details)
    let encoded = codec.encodeErrorEnvelope(error)
    let decoded = codec.decodeEnvelope(encoded) as? FlutterError
    #expect(decoded?.code == testCase.code)
    #expect(decoded?.message == testCase.message)
  }
}
