// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'dom.dart';

// iOS 15 launched WebGL 2.0, but there's something broken about it, which
// leads to apps failing to load. For now, we're forcing WebGL 1 on iOS.
//
// TODO(yjbanov): https://github.com/flutter/flutter/issues/91333
bool get _workAroundBug91333 => operatingSystem == OperatingSystem.iOs;

/// The HTML engine used by the current browser.
enum BrowserEngine {
  /// The engine that powers Chrome, Samsung Internet Browser, UC Browser,
  /// Microsoft Edge, Opera, and others.
  ///
  /// Blink is assumed in case when a more precise browser engine wasn't
  /// detected.
  blink,

  /// The engine that powers Safari.
  webkit,

  /// The engine that powers Firefox.
  firefox,
}

/// The signature of [getUserAgent].
typedef UserAgentGetter = String Function();

/// Returns the current user agent string.
///
/// This function is read-writable, so it can be overridden in tests.
UserAgentGetter getUserAgent = defaultGetUserAgent;

/// The default implementation of [getUserAgent].
String defaultGetUserAgent() {
  return domWindow.navigator.userAgent;
}

/// html webgl version qualifier constants.
abstract class WebGLVersion {
  /// WebGL 1.0 is based on OpenGL ES 2.0 / GLSL 1.00
  static const int webgl1 = 1;

  /// WebGL 2.0 is based on OpenGL ES 3.0 / GLSL 3.00
  static const int webgl2 = 2;
}

/// Lazily initialized current browser engine.
final BrowserEngine _browserEngine = _detectBrowserEngine();

/// Override the value of [browserEngine].
///
/// Setting this to `null` lets [browserEngine] detect the browser that the
/// app is running on.
///
/// This is intended to be used for testing and debugging only.
BrowserEngine? debugBrowserEngineOverride;

/// Returns the [BrowserEngine] used by the current browser.
///
/// This is used to implement browser-specific behavior.
BrowserEngine get browserEngine {
  return debugBrowserEngineOverride ?? _browserEngine;
}

BrowserEngine _detectBrowserEngine() {
  final String vendor = domWindow.navigator.vendor;
  final String agent = domWindow.navigator.userAgent.toLowerCase();
  return detectBrowserEngineByVendorAgent(vendor, agent);
}

/// Detects browser engine for a given vendor and agent string.
///
/// Used for testing this library.
@visibleForTesting
BrowserEngine detectBrowserEngineByVendorAgent(String vendor, String agent) {
  if (vendor == 'Google Inc.') {
    return BrowserEngine.blink;
  } else if (vendor == 'Apple Computer, Inc.') {
    return BrowserEngine.webkit;
  } else if (agent.contains('Edg/')) {
    // Chromium based Microsoft Edge has `Edg` in the user-agent.
    // https://docs.microsoft.com/en-us/microsoft-edge/web-platform/user-agent-string
    return BrowserEngine.blink;
  } else if (vendor == '' && agent.contains('firefox')) {
    // An empty string means firefox:
    // https://developer.mozilla.org/en-US/docs/Web/API/Navigator/vendor
    return BrowserEngine.firefox;
  }

  // Assume Blink otherwise, but issue a warning.
  print(
      'WARNING: failed to detect current browser engine. Assuming this is a Chromium-compatible browser.');
  return BrowserEngine.blink;
}

/// Operating system where the current browser runs.
///
/// Taken from the navigator platform.
/// <https://developer.mozilla.org/en-US/docs/Web/API/NavigatorID/platform>
enum OperatingSystem {
  /// iOS: <http://www.apple.com/ios/>
  iOs,

  /// Android: <https://www.android.com/>
  android,

  /// Linux: <https://www.linux.org/>
  linux,

  /// Windows: <https://www.microsoft.com/windows/>
  windows,

  /// MacOs: <https://www.apple.com/macos/>
  macOs,

  /// We were unable to detect the current operating system.
  unknown,
}

/// Lazily initialized current operating system.
final OperatingSystem _operatingSystem = detectOperatingSystem();

/// Returns the [OperatingSystem] the current browsers works on.
///
/// This is used to implement operating system specific behavior such as
/// soft keyboards.
OperatingSystem get operatingSystem {
  return debugOperatingSystemOverride ?? _operatingSystem;
}

/// Override the value of [operatingSystem].
///
/// Setting this to `null` lets [operatingSystem] detect the real OS that the
/// app is running on.
///
/// This is intended to be used for testing and debugging only.
OperatingSystem? debugOperatingSystemOverride;

/// Detects operating system using platform and UA used for unit testing.
@visibleForTesting
OperatingSystem detectOperatingSystem({
  String? overridePlatform,
  int? overrideMaxTouchPoints,
}) {
  final String platform = overridePlatform ?? domWindow.navigator.platform!;
  final String userAgent = getUserAgent();

  if (platform.startsWith('Mac')) {
    // iDevices requesting a "desktop site" spoof their UA so it looks like a Mac.
    // This checks if we're in a touch device, or on a real mac.
    final int maxTouchPoints = overrideMaxTouchPoints ??
        domWindow.navigator.maxTouchPoints?.toInt() ??
        0;
    if (maxTouchPoints > 2) {
      return OperatingSystem.iOs;
    }
    return OperatingSystem.macOs;
  } else if (platform.toLowerCase().contains('iphone') ||
      platform.toLowerCase().contains('ipad') ||
      platform.toLowerCase().contains('ipod')) {
    return OperatingSystem.iOs;
  } else if (userAgent.contains('Android')) {
    // The Android OS reports itself as "Linux armv8l" in
    // [domWindow.navigator.platform]. So we have to check the user-agent to
    // determine if the OS is Android or not.
    return OperatingSystem.android;
  } else if (platform.startsWith('Linux')) {
    return OperatingSystem.linux;
  } else if (platform.startsWith('Win')) {
    return OperatingSystem.windows;
  } else {
    return OperatingSystem.unknown;
  }
}

/// List of Operating Systems we know to be working on laptops/desktops.
///
/// These devices tend to behave differently on many core issues such as events,
/// screen readers, input devices.
const Set<OperatingSystem> _desktopOperatingSystems = <OperatingSystem>{
  OperatingSystem.macOs,
  OperatingSystem.linux,
  OperatingSystem.windows,
};

/// A flag to check if the current operating system is a laptop/desktop
/// operating system.
///
/// See [_desktopOperatingSystems].
bool get isDesktop => _desktopOperatingSystems.contains(operatingSystem);

/// A flag to check if the current browser is running on a mobile device.
///
/// See [_desktopOperatingSystems].
/// See [isDesktop].
bool get isMobile => !isDesktop;

/// Whether the browser is running on macOS or iOS.
///
/// - See [operatingSystem].
/// - See [OperatingSystem].
bool get isMacOrIOS =>
    operatingSystem == OperatingSystem.iOs ||
    operatingSystem == OperatingSystem.macOs;

/// Detect iOS 15.
bool get isIOS15 {
  if (debugIsIOS15 != null) {
    return debugIsIOS15!;
  }
  return operatingSystem == OperatingSystem.iOs &&
      domWindow.navigator.userAgent.contains('OS 15_');
}

/// Detect if running on Chrome version 110 or older.
///
/// These versions of Chrome have a bug which causes rendering to be flipped
/// upside down when using `createImageBitmap`: see
/// https://chromium.googlesource.com/chromium/src/+/a7f9b00e422a1755918f8ca5500380f98b6fddf2
// TODO(harryterkelsen): Remove this check once we stop supporting Chrome 110
// and earlier, https://github.com/flutter/flutter/issues/139186.
bool get isChrome110OrOlder {
  if (debugIsChrome110OrOlder != null) {
    return debugIsChrome110OrOlder!;
  }
  if (_cachedIsChrome110OrOlder != null) {
    return _cachedIsChrome110OrOlder!;
  }
  final RegExp chromeRegexp = RegExp(r'Chrom(e|ium)\/([0-9]+)\.');
  final RegExpMatch? match =
      chromeRegexp.firstMatch(domWindow.navigator.userAgent);
  if (match != null) {
    final int chromeVersion = int.parse(match.group(2)!);
    return _cachedIsChrome110OrOlder = chromeVersion <= 110;
  }
  return _cachedIsChrome110OrOlder = false;
}

// Cache the result of checking if the app is running on Chrome 110 on Windows
// since we check this on every frame.
bool? _cachedIsChrome110OrOlder;

/// If set to true pretends that the current browser is iOS Safari.
///
/// Useful for tests. Do not use in production code.
@visibleForTesting
bool debugEmulateIosSafari = false;

/// Returns true if the browser is iOS Safari, false otherwise.
bool get isIosSafari => debugEmulateIosSafari || _isActualIosSafari;

bool get _isActualIosSafari =>
    browserEngine == BrowserEngine.webkit &&
    operatingSystem == OperatingSystem.iOs;

/// Whether the current browser is Safari.
bool get isSafari => browserEngine == BrowserEngine.webkit;

/// Whether the current browser is Firefox.
bool get isFirefox => browserEngine == BrowserEngine.firefox;

/// Whether the current browser is Edge.
bool get isEdge => domWindow.navigator.userAgent.contains('Edg/');

/// Whether we are running from a wasm module compiled with dart2wasm.
/// Note: Currently the ffi library is available from dart2wasm but not dart2js
/// or dartdevc.
bool get isWasm => const bool.fromEnvironment('dart.library.ffi');

/// Use in tests to simulate the detection of iOS 15.
bool? debugIsIOS15;

/// Use in tests to simulated the detection of Chrome 110 or older on Windows.
bool? debugIsChrome110OrOlder;

int? _cachedWebGLVersion;

/// The highest WebGL version supported by the current browser, or -1 if WebGL
/// is not supported.
int get webGLVersion =>
    _cachedWebGLVersion ?? (_cachedWebGLVersion = _detectWebGLVersion());

/// Detects the highest WebGL version supported by the current browser, or
/// -1 if WebGL is not supported.
///
/// Chrome reports that `WebGL2RenderingContext` is available even when WebGL 2 is
/// disabled due hardware-specific issues. This happens, for example, on Chrome on
/// Moto E5. Therefore checking for the presence of `WebGL2RenderingContext` or
/// using the current [browserEngine] is insufficient.
///
/// Our CanvasKit backend is affected due to: https://github.com/emscripten-core/emscripten/issues/11819
int _detectWebGLVersion() {
  final DomCanvasElement canvas = createDomCanvasElement(
    width: 1,
    height: 1,
  );
  if (canvas.getContext('webgl2') != null) {
    if (_workAroundBug91333) {
      return WebGLVersion.webgl1;
    }
    return WebGLVersion.webgl2;
  }
  if (canvas.getContext('webgl') != null) {
    return WebGLVersion.webgl1;
  }
  return -1;
}

/// Whether the current browser supports the Chromium variant of CanvasKit.
bool get browserSupportsCanvaskitChromium =>
    domIntl.v8BreakIterator != null && domIntl.Segmenter != null;
