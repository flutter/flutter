// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import FlutterMacOS
import Foundation

public class PathProviderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plugins.flutter.io/path_provider_macos",
      binaryMessenger: registrar.messenger)
    let instance = PathProviderPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getTemporaryDirectory":
      result(getDirectory(ofType: FileManager.SearchPathDirectory.cachesDirectory))
    case "getApplicationDocumentsDirectory":
      result(getDirectory(ofType: FileManager.SearchPathDirectory.documentDirectory))
    case "getApplicationSupportDirectory":
      var path = getDirectory(ofType: FileManager.SearchPathDirectory.applicationSupportDirectory)
      if let basePath = path {
        let basePathURL = URL.init(fileURLWithPath: basePath)
        path = basePathURL.appendingPathComponent(Bundle.main.bundleIdentifier!).path
      }
      result(path)
    case "getLibraryDirectory":
      result(getDirectory(ofType: FileManager.SearchPathDirectory.libraryDirectory))
    case "getDownloadsDirectory":
      result(getDirectory(ofType: FileManager.SearchPathDirectory.downloadsDirectory))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

/// Returns the user-domain director of the given type.
private func getDirectory(ofType directory: FileManager.SearchPathDirectory) -> String? {
  let paths = NSSearchPathForDirectoriesInDomains(
    directory,
    FileManager.SearchPathDomainMask.userDomainMask,
    true)
  return paths.first
}
