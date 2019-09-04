// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(flutter_web): the Web-only API below need to be cleaned up.

part of ui;

/// Used to track when the platform is initialized. This ensures the test fonts
/// are available.
Future<void> _testPlatformInitializedFuture;

/// If the platform is already initialized (by a previous test), then run the test
/// body immediately. Otherwise, initialize the platform then run the test.
Future<dynamic> ensureTestPlatformInitializedThenRunTest(
    dynamic Function() body) {
  if (_testPlatformInitializedFuture == null) {
    debugEmulateFlutterTesterEnvironment = true;

    // Initializing the platform will ensure that the test font is loaded.
    _testPlatformInitializedFuture = webOnlyInitializePlatform(
        assetManager: engine.WebOnlyMockAssetManager());
  }
  return _testPlatformInitializedFuture.then<dynamic>((_) => body());
}

/// Used to track when the platform is initialized. This ensures the test fonts
/// are available.
Future<void> _platformInitializedFuture;

/// Initializes domRenderer with specific devicePixelRation and physicalSize.
Future<void> webOnlyInitializeTestDomRenderer({double devicePixelRatio = 3.0}) {
  // Force-initialize DomRenderer so it doesn't overwrite test pixel ratio.
  engine.domRenderer;

  // The following parameters are hard-coded in Flutter's test embedder. Since
  // we don't have an embedder yet this is the lowest-most layer we can put
  // this stuff in.
  engine.window.debugOverrideDevicePixelRatio(devicePixelRatio);
  engine.window.webOnlyDebugPhysicalSizeOverride =
      Size(800 * devicePixelRatio, 600 * devicePixelRatio);
  webOnlyScheduleFrameCallback = () {};
  debugEmulateFlutterTesterEnvironment = true;

  if (_platformInitializedFuture != null) {
    return _platformInitializedFuture;
  }

  // Only load the Ahem font once and await the same future in all tests.
  return _platformInitializedFuture =
      webOnlyInitializePlatform(assetManager: engine.WebOnlyMockAssetManager())
          .timeout(const Duration(seconds: 2), onTimeout: () async {
    throw Exception('Timed out loading Ahem font.');
  });
}
