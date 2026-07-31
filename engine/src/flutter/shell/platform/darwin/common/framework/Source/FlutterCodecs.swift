// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

@objc @implementation extension FlutterBinaryCodec {
  private static let shared = FlutterBinaryCodec()

  class func sharedInstance() -> Self {
    shared as! Self
  }

  func encode(_ message: Any?) -> Data? {
    if let message = message {
      assert(message is Data, "Message must be NSData or nil")
      return message as? Data
    }
    return nil
  }

  func decode(_ message: Data?) -> Any? {
    message
  }
}

@objc @implementation extension FlutterStringCodec {
  private static let shared = FlutterStringCodec()

  class func sharedInstance() -> Self {
    shared as! Self
  }

  func encode(_ message: Any?) -> Data? {
    guard let message = message else {
      return nil
    }
    assert(message is String, "Message must be NSString or nil")
    guard let string = message as? String else {
      return nil
    }
    return string.data(using: .utf8)
  }

  func decode(_ message: Data?) -> Any? {
    guard let message = message else {
      return nil
    }
    return String(data: message, encoding: .utf8)
  }
}

@objc @implementation extension FlutterJSONMessageCodec {
  private static let shared = FlutterJSONMessageCodec()

  class func sharedInstance() -> Self {
    shared as! Self
  }

  func encode(_ message: Any?) -> Data? {
    guard let message = message else {
      return nil
    }
    var encoding: Data?
    if message is [Any] || message is [AnyHashable: Any] {
      encoding = try? JSONSerialization.data(withJSONObject: message, options: [])
    } else {
      // NSJSONSerialization does not support top-level simple values.
      // We encode as singleton array, then extract the relevant bytes.
      if let arrayData = try? JSONSerialization.data(withJSONObject: [message], options: []) {
        if arrayData.count >= 2 {
          encoding = arrayData.subdata(in: 1..<(arrayData.count - 1))
        }
      }
    }
    assert(encoding != nil, "Invalid JSON message, encoding failed")
    return encoding
  }

  func decode(_ message: Data?) -> Any? {
    guard let message = message, !message.isEmpty else {
      return nil
    }
    var dataToDecode = message
    var isSimpleValue = false

    let firstByte = message[message.startIndex]
    isSimpleValue = (firstByte != UInt8(ascii: "{") && firstByte != UInt8(ascii: "["))

    if isSimpleValue {
      // NSJSONSerialization does not support top-level simple values.
      // We expand encoding to singleton array, then decode that and extract the single entry.
      var expanded = Data()
      expanded.append(UInt8(ascii: "["))
      expanded.append(message)
      expanded.append(UInt8(ascii: "]"))
      dataToDecode = expanded
    }

    guard let decoded = try? JSONSerialization.jsonObject(with: dataToDecode, options: []) else {
      assertionFailure("Invalid JSON message, decoding failed")
      return nil
    }

    if isSimpleValue, let array = decoded as? [Any], !array.isEmpty {
      return array[0]
    }
    return decoded
  }
}

@objc @implementation extension FlutterJSONMethodCodec {
  private static let shared = FlutterJSONMethodCodec()

  class func sharedInstance() -> Self {
    shared as! Self
  }

  @objc(encodeMethodCall:)
  func encode(_ methodCall: FlutterMethodCall) -> Data {
    guard
      let data = FlutterJSONMessageCodec.sharedInstance().encode([
        "method": methodCall.method,
        "args": wrapNil(methodCall.arguments),
      ])
    else {
      fatalError("Encoding JSON method call failed")
    }
    return data
  }

  func encodeSuccessEnvelope(_ result: Any?) -> Data {
    guard let data = FlutterJSONMessageCodec.sharedInstance().encode([wrapNil(result)]) else {
      fatalError("Encoding JSON success envelope failed")
    }
    return data
  }

  func encodeErrorEnvelope(_ error: FlutterError) -> Data {
    guard
      let data = FlutterJSONMessageCodec.sharedInstance().encode([
        error.code,
        wrapNil(error.message),
        wrapNil(error.details),
      ])
    else {
      fatalError("Encoding JSON error envelope failed")
    }
    return data
  }

  func decodeMethodCall(_ message: Data) -> FlutterMethodCall {
    guard
      let dictionary = FlutterJSONMessageCodec.sharedInstance().decode(message) as? [String: Any],
      let method = dictionary["method"] as? String
    else {
      assertionFailure("Invalid JSON method call")
      return FlutterMethodCall(methodName: "", arguments: nil)
    }
    let arguments = unwrapNil(dictionary["args"])
    return FlutterMethodCall(methodName: method, arguments: arguments)
  }

  func decodeEnvelope(_ envelope: Data) -> Any? {
    guard let array = FlutterJSONMessageCodec.sharedInstance().decode(envelope) as? [Any] else {
      return nil
    }
    if array.count == 1 {
      return unwrapNil(array[0])
    }
    assert(array.count == 3, "Invalid JSON envelope")
    guard let code = array[0] as? String else {
      assertionFailure("Invalid JSON envelope")
      return nil
    }
    let message = unwrapNil(array[1]) as? String
    let details = unwrapNil(array[2])
    return FlutterError(code: code, message: message, details: details)
  }

  private func wrapNil(_ value: Any?) -> Any {
    value ?? NSNull()
  }

  private func unwrapNil(_ value: Any?) -> Any? {
    value is NSNull ? nil : value
  }
}
