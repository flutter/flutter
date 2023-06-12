// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import FlutterMacOS
import Foundation

/// A handler that can launch other apps, check if any app is able to open the URL.
public protocol SystemURLHandler {

  /// Opens the location at the specified URL.
  ///
  /// - Parameters:
  ///   - url: A URL specifying the location to open.
  /// - Returns: true if the location was successfully opened; otherwise, false.
  func open(_ url: URL) -> Bool

  /// Returns the URL to the default app that would be opened.
  ///
  /// - Parameters:
  ///   - toOpen: The URL of the file to open.
  /// - Returns: The URL of the default app that would open the specified url.
  ///   Returns nil if no app is able to open the URL, or if the file URL does not exist.
  func urlForApplication(toOpen: URL) -> URL?
}

extension NSWorkspace: SystemURLHandler {}

public class UrlLauncherPlugin: NSObject, FlutterPlugin {

  private var workspace: SystemURLHandler

  public init(_ workspace: SystemURLHandler = NSWorkspace.shared) {
    self.workspace = workspace
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plugins.flutter.io/url_launcher_macos",
      binaryMessenger: registrar.messenger)
    let instance = UrlLauncherPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let urlString: String? = (call.arguments as? [String: Any])?["url"] as? String
    switch call.method {
    case "canLaunch":
      guard let unwrappedURLString = urlString,
        let url = URL.init(string: unwrappedURLString)
      else {
        result(invalidURLError(urlString))
        return
      }
      result(workspace.urlForApplication(toOpen: url) != nil)
    case "launch":
      guard let unwrappedURLString = urlString,
        let url = URL.init(string: unwrappedURLString)
      else {
        result(invalidURLError(urlString))
        return
      }
      result(workspace.open(url))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

/// Returns an error for the case where a URL string can't be parsed as a URL.
private func invalidURLError(_ url: String?) -> FlutterError {
  return FlutterError(
    code: "argument_error",
    message: "Unable to parse URL",
    details: "Provided URL: \(String(describing: url))")
}
