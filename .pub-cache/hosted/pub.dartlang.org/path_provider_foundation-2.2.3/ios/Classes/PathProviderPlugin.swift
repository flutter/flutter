// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

public class PathProviderPlugin: NSObject, FlutterPlugin, PathProviderApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PathProviderPlugin()
    // Workaround for https://github.com/flutter/flutter/issues/118103.
#if os(iOS)
    let messenger = registrar.messenger()
#else
    let messenger = registrar.messenger
#endif
    PathProviderApiSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func getDirectoryPath(type: DirectoryType) -> String? {
    var path = getDirectory(ofType: fileManagerDirectoryForType(type))
  #if os(macOS)
    // In a non-sandboxed app, this is a shared directory where applications are
    // expected to use its bundle ID as a subdirectory. (For non-sandboxed apps,
    // adding the extra path is harmless).
    // This is not done for iOS, for compatibility with older versions of the
    // plugin.
    if type == .applicationSupport {
      if let basePath = path {
        let basePathURL = URL.init(fileURLWithPath: basePath)
        path = basePathURL.appendingPathComponent(Bundle.main.bundleIdentifier!).path
      }
    }
  #endif
    return path
  }

  // Returns the path for the container of the specified app group.
  func getContainerPath(appGroupIdentifier: String) -> String? {
      return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?.path
  }
}

/// Returns the FileManager constant corresponding to the given type.
private func fileManagerDirectoryForType(_ type: DirectoryType) -> FileManager.SearchPathDirectory {
  switch type {
    case .applicationDocuments:
      return FileManager.SearchPathDirectory.documentDirectory
    case .applicationSupport:
      return FileManager.SearchPathDirectory.applicationSupportDirectory
    case .downloads:
      return FileManager.SearchPathDirectory.downloadsDirectory
    case .library:
      return FileManager.SearchPathDirectory.libraryDirectory
    case .temp:
      return FileManager.SearchPathDirectory.cachesDirectory
  }
}

/// Returns the user-domain directory of the given type.
private func getDirectory(ofType directory: FileManager.SearchPathDirectory) -> String? {
  let paths = NSSearchPathForDirectoriesInDomains(
    directory,
    FileManager.SearchPathDomainMask.userDomainMask,
    true)
  return paths.first
}
