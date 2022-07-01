// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// JavaScript API a Flutter Web application can use to configure the Web
/// Engine.
///
/// The configuration is a plain JavaScript object set as the
/// `flutterConfiguration` property of the top-level `window` object.
///
/// Example:
///
///     <head>
///       <script>
///         window.flutterConfiguration = {
///           canvasKitBaseUrl: "https://example.com/my-custom-canvaskit/"
///         };
///       </script>
///     </head>
///
/// Configuration properties supplied via `window.flutterConfiguration`
/// override those supplied using the corresponding environment variables. For
/// example, if both `window.flutterConfiguration.canvasKitBaseUrl` and the
/// `FLUTTER_WEB_CANVASKIT_URL` environment variables are provided,
/// `window.flutterConfiguration.canvasKitBaseUrl` is used.

@JS()
library configuration;

import 'package:js/js.dart';

/// The version of CanvasKit used by the web engine by default.
// DO NOT EDIT THE NEXT LINE OF CODE MANUALLY
// See `lib/web_ui/README.md` for how to roll CanvasKit to a new version.
const String _canvaskitVersion = '0.35.0';

/// The Web Engine configuration for the current application.
FlutterConfiguration get configuration => _configuration ??= FlutterConfiguration(_jsConfiguration);
FlutterConfiguration? _configuration;

/// Sets the given configuration as the current one.
///
/// This must be called before the engine is initialized. Calling it after the
/// engine is initialized will result in some of the properties not taking
/// effect because they are consumed during initialization.
void debugSetConfiguration(FlutterConfiguration configuration) {
  _configuration = configuration;
}

/// Supplies Web Engine configuration properties.
class FlutterConfiguration {
  /// Constructs a configuration from a JavaScript object containing
  /// runtime-supplied properties.
  FlutterConfiguration(this._js);

  final JsFlutterConfiguration? _js;

  // Static constant parameters.
  //
  // These properties affect tree shaking and therefore cannot be supplied at
  // runtime. They must be static constants for the compiler to remove dead
  // effectively.

  /// Auto detect which rendering backend to use.
  ///
  /// Using flutter tools option "--web-render=auto" or not specifying one
  /// would set the value to true. Otherwise, it would be false.
  static const bool flutterWebAutoDetect =
      bool.fromEnvironment('FLUTTER_WEB_AUTO_DETECT', defaultValue: true);

  /// Enable the Skia-based rendering backend.
  ///
  /// Using flutter tools option "--web-render=canvaskit" would set the value to
  /// true.
  ///
  /// Using flutter tools option "--web-render=html" would set the value to false.
  static const bool useSkia =
      bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false);


  // Runtime parameters.
  //
  // These parameters can be supplied either as environment variables, or at
  // runtime. Runtime-supplied values take precedence over environment
  // variables.

  /// The URL to use when downloading the CanvasKit script and associated wasm.
  ///
  /// The expected directory structure nested under this URL is as follows:
  ///
  ///     /canvaskit.js              - the release build of CanvasKit JS API bindings
  ///     /canvaskit.wasm            - the release build of CanvasKit WASM module
  ///     /profiling/canvaskit.js    - the profile build of CanvasKit JS API bindings
  ///     /profiling/canvaskit.wasm  - the profile build of CanvasKit WASM module
  ///
  /// The base URL can be overridden using the `FLUTTER_WEB_CANVASKIT_URL`
  /// environment variable or using the configuration API for JavaScript.
  ///
  /// When specifying using the environment variable set it in the Flutter tool
  /// using the `--dart-define` option. The value must end with a `/`.
  ///
  /// Example:
  ///
  /// ```
  /// flutter run \
  ///   -d chrome \
  ///   --web-renderer=canvaskit \
  ///   --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://example.com/custom-canvaskit-build/
  /// ```
  String get canvasKitBaseUrl => _js?.canvasKitBaseUrl ?? _defaultCanvasKitBaseUrl;
  static const String _defaultCanvasKitBaseUrl = String.fromEnvironment(
    'FLUTTER_WEB_CANVASKIT_URL',
    defaultValue: 'https://unpkg.com/canvaskit-wasm@$_canvaskitVersion/bin/',
  );

  /// If set to true, forces CPU-only rendering in CanvasKit (i.e. the engine
  /// won't use WebGL).
  ///
  /// This is mainly used for testing or for apps that want to ensure they
  /// run on devices which don't support WebGL.
  bool get canvasKitForceCpuOnly => _js?.canvasKitForceCpuOnly ?? _defaultCanvasKitForceCpuOnly;
  static const bool _defaultCanvasKitForceCpuOnly = bool.fromEnvironment(
    'FLUTTER_WEB_CANVASKIT_FORCE_CPU_ONLY',
    defaultValue: false,
  );

  /// The maximum number of overlay surfaces that the CanvasKit renderer will use.
  ///
  /// Overlay surfaces are extra WebGL `<canvas>` elements used to paint on top
  /// of platform views. Too many platform views can cause the browser to run
  /// out of resources (memory, CPU, GPU) to handle the content efficiently.
  /// The number of overlay surfaces is therefore limited.
  ///
  /// This value can be specified using either the `FLUTTER_WEB_MAXIMUM_SURFACES`
  /// environment variable, or using the runtime configuration.
  int get canvasKitMaximumSurfaces => _js?.canvasKitMaximumSurfaces ?? _defaultCanvasKitMaximumSurfaces;
  static const int _defaultCanvasKitMaximumSurfaces = int.fromEnvironment(
    'FLUTTER_WEB_MAXIMUM_SURFACES',
    defaultValue: 8,
  );

  /// Set this flag to `true` to cause the engine to visualize the semantics tree
  /// on the screen for debugging.
  ///
  /// This only works in profile and release modes. Debug mode does not support
  /// passing compile-time constants.
  ///
  /// Example:
  ///
  /// ```
  /// flutter run -d chrome --profile --dart-define=FLUTTER_WEB_DEBUG_SHOW_SEMANTICS=true
  /// ```
  bool get debugShowSemanticsNodes => _js?.debugShowSemanticsNodes ?? _defaultDebugShowSemanticsNodes;
  static const bool _defaultDebugShowSemanticsNodes = bool.fromEnvironment(
    'FLUTTER_WEB_DEBUG_SHOW_SEMANTICS',
    defaultValue: false,
  );
}

@JS('window.flutterConfiguration')
external JsFlutterConfiguration? get _jsConfiguration;

/// The JS bindings for the object that's set as `window.flutterConfiguration`.
@JS()
@staticInterop
class JsFlutterConfiguration {}

extension JsFlutterConfigurationExtension on JsFlutterConfiguration {
  external String? get canvasKitBaseUrl;
  external bool? get canvasKitForceCpuOnly;
  external bool? get debugShowSemanticsNodes;

  external int? get canvasKitMaximumSurfaces;
  external set canvasKitMaximumSurfaces(int? maxSurfaces);
}

/// A JavaScript entrypoint that allows developer to set rendering backend
/// at runtime before launching the application.
@JS('window.flutterWebRenderer')
external String? get requestedRendererType;
