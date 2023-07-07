// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_web;

/// The entry point for accessing a Firebase app instance.
///
/// To get an instance, call the the `app` method on the [FirebaseCore]
/// instance, for example:
///
/// ```dart
/// Firebase.app('SecondaryApp`);
/// ```
class FirebaseAppWeb extends FirebaseAppPlatform {
  FirebaseAppWeb._(String name, FirebaseOptions options) : super(name, options);

  // TODO(rrousselGit): Either FirebaseAppPlatform shouldn't overrides ==/hashCode or FirebaseAppWeb should be immutable
  /// Returns whether automatic data collection enabled or disabled.
  bool _isAutomaticDataCollectionEnabled = false;

  /// Deletes this app and frees up system resources.
  ///
  /// Once deleted, any plugin functionality using this app instance will throw
  /// an error.
  @override
  Future<void> delete() async {
    await firebase.app(name).delete();
  }

  /// Returns whether automatic data collection enabled or disabled.
  /// This has no affect on web.
  @override
  bool get isAutomaticDataCollectionEnabled =>
      _isAutomaticDataCollectionEnabled;

  /// Sets whether automatic data collection is enabled or disabled.
  /// This has no affect on web.
  @override
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) {
    _isAutomaticDataCollectionEnabled = enabled;
    return Future.value();
  }

  /// Sets whether automatic resource management is enabled or disabled.
  /// This has no affect on web.
  @override
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) {
    return Future.value();
  }
}
