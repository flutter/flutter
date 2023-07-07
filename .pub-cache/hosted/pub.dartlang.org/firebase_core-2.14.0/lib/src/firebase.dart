// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core;

/// The entry point for accessing Firebase.
class Firebase {
  // Ensures end-users cannot initialize the class.
  Firebase._();

  // Cached & lazily loaded instance of [FirebasePlatform].
  // Avoids a [MethodChannelFirebase] being initialized until the user
  // starts using Firebase.
  // The property is visible for testing to allow tests to set a mock
  // instance directly as a static property since the class is not initialized.
  @visibleForTesting
  // ignore: public_member_api_docs
  static FirebasePlatform? delegatePackingProperty;

  static FirebasePlatform get _delegate {
    return delegatePackingProperty ??= FirebasePlatform.instance;
  }

  /// Returns a list of all [FirebaseApp] instances that have been created.
  static List<FirebaseApp> get apps {
    return _delegate.apps.map(FirebaseApp._).toList(growable: false);
  }

  /// Initializes a new [FirebaseApp] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of FlutterFire plugins.
  ///
  /// The default app instance can be initialized here simply by passing no "name" as an argument
  /// in both Dart & manual initialization flows.
  /// If you have a `google-services.json` file in your android project or a `GoogleService-Info.plist` file in your iOS+ project,
  /// it will automatically create a default (named "[DEFAULT]") app instance on the native platform. However, you will still need to call this method
  /// before using any FlutterFire plugins.
  static Future<FirebaseApp> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    FirebaseAppPlatform app = await _delegate.initializeApp(
      name: name,
      options: options,
    );

    return FirebaseApp._(app);
  }

  /// Returns a [FirebaseApp] instance.
  ///
  /// If no name is provided, the default app instance is returned.
  /// Throws if the app does not exist.
  static FirebaseApp app([String name = defaultFirebaseAppName]) {
    FirebaseAppPlatform app = _delegate.app(name);

    return FirebaseApp._(app);
  }

  // TODO(rrousselGit): remove ==/hashCode
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Firebase) return false;
    return other.hashCode == hashCode;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => toString().hashCode;

  @override
  String toString() => '$Firebase';
}
