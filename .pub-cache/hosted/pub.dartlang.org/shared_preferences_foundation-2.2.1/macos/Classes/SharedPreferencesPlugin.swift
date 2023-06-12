// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Foundation

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif

public class SharedPreferencesPlugin: NSObject, FlutterPlugin, UserDefaultsApi {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SharedPreferencesPlugin()
    // Workaround for https://github.com/flutter/flutter/issues/118103.
#if os(iOS)
    let messenger = registrar.messenger()
#else
    let messenger = registrar.messenger
#endif
    UserDefaultsApiSetup.setUp(binaryMessenger: messenger, api: instance)
  }

  func getAllWithPrefix(prefix: String) -> [String? : Any?] {
    return getAllPrefs(prefix: prefix)
  }

  func setBool(key: String, value: Bool) {
    UserDefaults.standard.set(value, forKey: key)
  }

  func setDouble(key: String, value: Double) {
    UserDefaults.standard.set(value, forKey: key)
  }

  func setValue(key: String, value: Any) {
    UserDefaults.standard.set(value, forKey: key)
  }

  func remove(key: String) {
    UserDefaults.standard.removeObject(forKey: key)
  }

  func clearWithPrefix(prefix: String) {
    let defaults = UserDefaults.standard
    for (key, _) in getAllPrefs(prefix: prefix) {
      defaults.removeObject(forKey: key)
    }
  }

  /// Returns all preferences stored with specified prefix.
  func getAllPrefs(prefix: String) -> [String: Any] {
    var filteredPrefs: [String: Any] = [:]
    if let appDomain = Bundle.main.bundleIdentifier,
      let prefs = UserDefaults.standard.persistentDomain(forName: appDomain)
    {
      for (key, value) in prefs where key.hasPrefix(prefix) {
        filteredPrefs[key] = value
      }
    }
    return filteredPrefs
  }
}
