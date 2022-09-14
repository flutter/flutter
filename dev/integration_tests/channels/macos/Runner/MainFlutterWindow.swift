// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Cocoa
import FlutterMacOS

let DATE: UInt8 = 128
let PAIR: UInt8 = 129

class Pair {
  let first: Any?
  let second: Any?
  init(first: Any?, second: Any?) {
    self.first = first
    self.second = second
  }
}

class ExtendedWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let date = value as? Date {
      self.writeByte(DATE)
      let time = date.timeIntervalSince1970
      var ms = Int64(time * 1000.0)
      self.writeBytes(&ms, length: UInt(MemoryLayout<Int64>.size))
    } else if let pair = value as? Pair {
      self.writeByte(PAIR)
      self.writeValue(pair.first!)
      self.writeValue(pair.second!)
    } else {
      super.writeValue(value)
    }
  }
}

class ExtendedReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    if type == DATE {
      var ms: Int64 = 0
      self.readBytes(&ms, length: UInt(MemoryLayout<Int64>.size))
      let time: Double = Double(ms) / 1000.0
      return NSDate(timeIntervalSince1970: time)
    } else if type == PAIR {
      return Pair(first: self.readValue(), second: self.readValue())
    } else {
      return super.readValue(ofType: type)
    }
  }
}

class ExtendedReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return ExtendedReader(data: data)
  }
  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return ExtendedWriter(data: data)
  }
}

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    let registrar = flutterViewController.registrar(forPlugin: "channel-integration-test")
    setupMessagingHandshakeOnChannel(
      FlutterBasicMessageChannel(
        name: "binary-msg",
        binaryMessenger: registrar.messenger,
        codec: FlutterBinaryCodec.sharedInstance()))
    setupMessagingHandshakeOnChannel(
      FlutterBasicMessageChannel(
        name: "string-msg",
        binaryMessenger: registrar.messenger,
        codec: FlutterStringCodec.sharedInstance()))
    setupMessagingHandshakeOnChannel(
      FlutterBasicMessageChannel(
        name: "json-msg",
        binaryMessenger: registrar.messenger,
        codec: FlutterJSONMessageCodec.sharedInstance()))
    setupMessagingHandshakeOnChannel(
      FlutterBasicMessageChannel(
        name: "std-msg",
        binaryMessenger: registrar.messenger,
        codec: FlutterStandardMessageCodec(readerWriter: ExtendedReaderWriter())))

    setupMethodHandshakeOnChannel(
      FlutterMethodChannel(
        name: "json-method",
        binaryMessenger: registrar.messenger,
        codec: FlutterJSONMethodCodec.sharedInstance()))
    setupMethodHandshakeOnChannel(
      FlutterMethodChannel(
        name: "std-method",
        binaryMessenger: registrar.messenger,
        codec: FlutterStandardMethodCodec(readerWriter: ExtendedReaderWriter())))

    super.awakeFromNib()
  }

  func setupMessagingHandshakeOnChannel(_ channel: FlutterBasicMessageChannel) {
    channel.setMessageHandler { message, reply in
      channel.sendMessage(message) { messageReply in
        channel.sendMessage(messageReply)
        reply(message)
      }
    }
  }

  func setupMethodHandshakeOnChannel(_ channel: FlutterMethodChannel) {
    channel.setMethodCallHandler { call, result in
      if call.method == "success" {
        channel.invokeMethod(call.method, arguments: call.arguments) { value in
          channel.invokeMethod(call.method, arguments: value)
          result(call.arguments)
        }
      } else if call.method == "error" {
        channel.invokeMethod(call.method, arguments: call.arguments) { value in
          let error = value as! FlutterError
          channel.invokeMethod(call.method, arguments: error.details)
          result(error)
        }
      } else {
        channel.invokeMethod(call.method, arguments: call.arguments) { value in
          channel.invokeMethod(call.method, arguments: nil)
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
