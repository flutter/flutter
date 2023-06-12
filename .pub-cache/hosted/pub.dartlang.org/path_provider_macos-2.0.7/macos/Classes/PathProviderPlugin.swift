// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import FlutterMacOS
import Foundation

public class PathProviderPlugin: NSObject, FlutterPlugin, PathProviderApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = PathProviderPlugin()
    PathProviderApiSetup.setUp(binaryMessenger: registrar.messenger, api: instance)
  }

  func getDirectoryPath(type: DirectoryType) -> String? {
    var path = getDirectory(ofType: fileManagerDirectoryForType(type))
    if type == .applicationSupport {
      if let basePath = path {
        let basePathURL = URL.init(fileURLWithPath: basePath)
        path = basePathURL.appendingPathComponent(Bundle.main.bundleIdentifier!).path
      }
    }
    return path
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
