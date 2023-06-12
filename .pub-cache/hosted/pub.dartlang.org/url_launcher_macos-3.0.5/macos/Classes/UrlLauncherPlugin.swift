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

public class UrlLauncherPlugin: NSObject, FlutterPlugin, UrlLauncherApi {

  private var workspace: SystemURLHandler

  public init(_ workspace: SystemURLHandler = NSWorkspace.shared) {
    self.workspace = workspace
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = UrlLauncherPlugin()
    UrlLauncherApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func canLaunch(url: String) throws -> UrlLauncherBoolResult {
    guard let nsurl = URL.init(string: url) else {
      return UrlLauncherBoolResult(value: false, error: .invalidUrl)
    }
    let canOpen = workspace.urlForApplication(toOpen: nsurl) != nil
    return UrlLauncherBoolResult(value: canOpen, error: nil)
  }

  func launch(url: String) throws -> UrlLauncherBoolResult {
    guard let nsurl = URL.init(string: url) else {
      return UrlLauncherBoolResult(value: false, error: .invalidUrl)
    }
    let success = workspace.open(nsurl)
    return UrlLauncherBoolResult(value: success, error: nil)
  }
}
