// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// The HTML engine used by the current browser.
enum BrowserEngine {
  /// The engine that powers Chrome, Samsung Internet Browser, UC Browser,
  /// Microsoft Edge, Opera, and others.
  blink,

  /// The engine that powers Safari.
  webkit,

  /// The engine that powers Firefox.
  firefox,

  /// The engine that powers Edge.
  edge,

  /// The engine that powers Internet Explorer 11.
  ie11,

  /// We were unable to detect the current browser engine.
  unknown,
}

/// html webgl version qualifier constants.
abstract class WebGLVersion {
  // WebGL 1.0 is based on OpenGL ES 2.0 / GLSL 1.00
  static const int webgl1 = 1;
  // WebGL 2.0 is based on OpenGL ES 3.0 / GLSL 3.00
  static const int webgl2 = 2;
}

/// Lazily initialized current browser engine.
late final BrowserEngine _browserEngine = _detectBrowserEngine();

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
  final String vendor = html.window.navigator.vendor;
  final String agent = html.window.navigator.userAgent.toLowerCase();
  if (vendor == 'Google Inc.') {
    return BrowserEngine.blink;
  } else if (vendor == 'Apple Computer, Inc.') {
    return BrowserEngine.webkit;
  } else if (agent.contains('edge/')) {
    return BrowserEngine.edge;
  } else if (agent.contains('Edg/')) {
    // Chromium based Microsoft Edge has `Edg` in the user-agent.
    // https://docs.microsoft.com/en-us/microsoft-edge/web-platform/user-agent-string
    return BrowserEngine.blink;
  } else if (agent.contains('trident/7.0')) {
    return BrowserEngine.ie11;
  } else if (vendor == '' && agent.contains('firefox')) {
    // An empty string means firefox:
    // https://developer.mozilla.org/en-US/docs/Web/API/Navigator/vendor
    return BrowserEngine.firefox;
  }

  // Assume unknown otherwise, but issue a warning.
  print('WARNING: failed to detect current browser engine.');
  return BrowserEngine.unknown;
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
late final OperatingSystem _operatingSystem = _detectOperatingSystem();

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

OperatingSystem _detectOperatingSystem() {
  final String platform = html.window.navigator.platform!;
  final String userAgent = html.window.navigator.userAgent;

  if (platform.startsWith('Mac')) {
    return OperatingSystem.macOs;
  } else if (platform.toLowerCase().contains('iphone') ||
      platform.toLowerCase().contains('ipad') ||
      platform.toLowerCase().contains('ipod')) {
    return OperatingSystem.iOs;
  } else if (userAgent.contains('Android')) {
    // The Android OS reports itself as "Linux armv8l" in
    // [html.window.navigator.platform]. So we have to check the user-agent to
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
const Set<OperatingSystem> _desktopOperatingSystems = {
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

int? _cachedWebGLVersion;

/// The highest WebGL version supported by the current browser, or -1 if WebGL
/// is not supported.
int get webGLVersion => _cachedWebGLVersion ?? (_cachedWebGLVersion = _detectWebGLVersion());

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
  final html.CanvasElement canvas = html.CanvasElement(
    width: 1,
    height: 1,
  );
  if (canvas.getContext('webgl2') != null) {
    return WebGLVersion.webgl2;
  }
  if (canvas.getContext('webgl') != null) {
    return WebGLVersion.webgl1;
  }
  return -1;
}
