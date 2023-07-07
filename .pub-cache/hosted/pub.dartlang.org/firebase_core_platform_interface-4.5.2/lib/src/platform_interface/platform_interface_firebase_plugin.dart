// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// The interface that other FlutterFire plugins must extend.
///
/// This class provides access to common plugin properties and constants which
/// are available once the user has initialized FlutterFire.
abstract class FirebasePluginPlatform extends PlatformInterface {
  // ignore: public_member_api_docs
  FirebasePluginPlatform(this._appName, this._methodChannelName)
      : super(token: _token);

  /// The global data store for all constants, for each plugin and [FirebaseAppPlatform] instance.
  ///
  /// When Firebase is initialized by the user with [FirebasePlatform.initializeApp],
  /// any constant values which are required before the plugins can be consumed are registered
  /// here. For example, calling [FirebaseAppPlatform.isAutomaticDataCollectionEnabled]
  /// requires that the value is synchronously available for use after initialization.
  static Map<dynamic, dynamic> _constantsForPluginApps = {};

  final String _appName;

  final String _methodChannelName;

  static final Object _token = Object();

  // ignore: public_member_api_docs
  static void verify(FirebasePluginPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// Returns any plugin constants this plugin app instance has initialized.
  Map<dynamic, dynamic> get pluginConstants {
    final appConstants =
        _constantsForPluginApps[_appName] as Map<Object?, Object?>?;

    if (appConstants != null && appConstants[_methodChannelName] != null) {
      return appConstants[_methodChannelName]! as Map<dynamic, dynamic>;
    }

    return {};
  }
}
