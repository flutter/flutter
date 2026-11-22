// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/net.dart';
import '../device.dart';
import 'compile.dart';
import 'devfs_config.dart';

/// Configuration options for web debugging and the web development server.
@immutable
class WebDebugConfig implements PlatformDebuggingOptions {
  const WebDebugConfig({
    this.browserDebugPort,
    this.browserFlags = const <String>[],
    bool? crossOriginIsolation,
    this.devServerConfig,
    this.enableExposeUrl = false,
    this.enableExpressionEvaluation = false,
    this.launchUrl,
    this.nativeNullAssertions = false,
    WebRendererMode? renderer,
    this.runHeadless = false,
    this.urlTunneller,
    this.useSseForDebugBackend = true,
    this.useSseForDebugProxy = true,
    this.useSseForInjectedClient = true,
    this.useWasm = false,
    this.webDefines = const <String, String>{},
  }) : crossOriginIsolation = crossOriginIsolation ?? useWasm,
       renderer =
           renderer ?? (useWasm ? WebRendererMode.defaultForWasm : WebRendererMode.defaultForJs);

  static const _kDefaultDevServerPort = 8080;
  static const _kPortKey = 'port';
  static const _kHostnameKey = 'hostname';
  static const _kTlsCertPathKey = 'tlsCertPath';
  static const _kTlsCertKeyPathKey = 'tlsCertKeyPath';
  static const _kWebEnableExposeUrlKey = 'webEnableExposeUrl';
  static const _kWebUseSseForDebugProxyKey = 'webUseSseForDebugProxy';
  static const _kWebUseSseForDebugBackendKey = 'webUseSseForDebugBackend';
  static const _kWebUseSseForInjectedClientKey = 'webUseSseForInjectedClient';
  static const _kWebRunHeadlessKey = 'webRunHeadless';
  static const _kWebBrowserDebugPortKey = 'webBrowserDebugPort';
  static const _kWebBrowserFlagsKey = 'webBrowserFlags';
  static const _kWebEnableExpressionEvaluationKey = 'webEnableExpressionEvaluation';
  static const _kWebLaunchUrlKey = 'webLaunchUrl';
  static const _kWebCrossOriginIsolationKey = 'webCrossOriginIsolation';
  static const _kWebHeadersKey = 'webHeaders';
  static const _kWebRendererKey = 'webRenderer';
  static const _kWebUseWasmKey = 'webUseWasm';
  static const _kNativeNullAssertionsKey = 'nativeNullAssertions';
  static const _kWebDefinesKey = 'webDefines';
  static const _kWebUseLocalCanvaskitKey = 'webUseLocalCanvaskit';

  static const _kJsonKeys = <String>{
    _kPortKey,
    _kHostnameKey,
    _kTlsCertPathKey,
    _kTlsCertKeyPathKey,
    _kWebEnableExposeUrlKey,
    _kWebUseSseForDebugProxyKey,
    _kWebUseSseForDebugBackendKey,
    _kWebUseSseForInjectedClientKey,
    _kWebRunHeadlessKey,
    _kWebBrowserDebugPortKey,
    _kWebBrowserFlagsKey,
    _kWebEnableExpressionEvaluationKey,
    _kWebLaunchUrlKey,
    _kWebCrossOriginIsolationKey,
    _kWebHeadersKey,
    _kWebRendererKey,
    _kWebUseWasmKey,
    _kNativeNullAssertionsKey,
    _kWebDefinesKey,
    _kWebUseLocalCanvaskitKey,
  };

  /// Parses a [WebDebugConfig] from a serialized [DebuggingOptions] JSON map,
  /// returning `null` when no web configuration keys are present.
  static WebDebugConfig? tryFromJson(Map<String, Object?> json) {
    if (!_kJsonKeys.any(json.containsKey)) {
      return null;
    }
    return WebDebugConfig(
      enableExposeUrl: json[_kWebEnableExposeUrlKey] as bool? ?? false,
      useSseForDebugProxy: json[_kWebUseSseForDebugProxyKey] as bool? ?? true,
      useSseForDebugBackend: json[_kWebUseSseForDebugBackendKey] as bool? ?? true,
      useSseForInjectedClient: json[_kWebUseSseForInjectedClientKey] as bool? ?? true,
      runHeadless: json[_kWebRunHeadlessKey] as bool? ?? false,
      browserDebugPort: json[_kWebBrowserDebugPortKey] as int?,
      browserFlags:
          (json[_kWebBrowserFlagsKey] as List<Object?>?)?.cast<String>() ?? const <String>[],
      enableExpressionEvaluation: json[_kWebEnableExpressionEvaluationKey] as bool? ?? false,
      launchUrl: json[_kWebLaunchUrlKey] as String?,
      crossOriginIsolation: json[_kWebCrossOriginIsolationKey] as bool?,
      renderer: json[_kWebRendererKey] is String
          ? WebRendererMode.values.byName(json[_kWebRendererKey]! as String)
          : null,
      useWasm: json[_kWebUseWasmKey] as bool? ?? false,
      nativeNullAssertions: json[_kNativeNullAssertionsKey] as bool? ?? false,
      webDefines:
          (json[_kWebDefinesKey] as Map<Object?, Object?>?)?.cast<String, String>() ??
          const <String, String>{},
      devServerConfig: WebDevServerConfig(
        port: json[_kPortKey] is int ? json[_kPortKey]! as int : _kDefaultDevServerPort,
        host: json[_kHostnameKey] is String
            ? json[_kHostnameKey]! as String
            : webDevServerDefaultHost,
        https: HttpsConfig.parse(json[_kTlsCertPathKey], json[_kTlsCertKeyPathKey]),
        headers:
            (json[_kWebHeadersKey] as Map<Object?, Object?>?)?.cast<String, String>() ??
            const <String, String>{},
      ),
    );
  }

  /// Whether to enable exposing URLs via the daemon URL tunneller.
  final bool enableExposeUrl;

  /// Whether to use Server-Sent Events (SSE) for the debug proxy.
  final bool useSseForDebugProxy;

  /// Whether to use Server-Sent Events (SSE) for the debug backend.
  final bool useSseForDebugBackend;

  /// Whether to use Server-Sent Events (SSE) for the injected client.
  final bool useSseForInjectedClient;

  /// Whether to run the browser in headless mode.
  final bool runHeadless;

  /// The debug port for the browser, or `null` to use the default port.
  final int? browserDebugPort;

  /// Additional command-line flags to pass to the browser when launching.
  final List<String> browserFlags;

  /// Whether expression evaluation is enabled in the web debugger.
  final bool enableExpressionEvaluation;

  /// A custom URL to launch in the browser instead of the default serving URL.
  final String? launchUrl;

  /// Whether Cross-Origin Isolation headers are enabled on the web dev server.
  final bool crossOriginIsolation;

  /// The web rendering backend mode to use.
  final WebRendererMode renderer;

  /// Whether to compile the application to WebAssembly (Wasm).
  final bool useWasm;

  /// Configuration for the local web development server.
  final WebDevServerConfig? devServerConfig;

  /// Additional null runtime checks inserted for web applications.
  ///
  /// See also:
  ///   * https://github.com/dart-lang/sdk/blob/main/sdk/lib/html/doc/NATIVE_NULL_ASSERTIONS.md
  final bool nativeNullAssertions;

  /// Runtime-only callback used by daemon sessions to expose local URLs.
  ///
  /// Omitted from [toJson].
  final UrlTunneller? urlTunneller;

  /// Template placeholder definitions passed to the web build and dev server.
  final Map<String, String> webDefines;

  /// Returns a copy of this [WebDebugConfig] with optional overrides.
  WebDebugConfig copyWith({
    int? browserDebugPort,
    List<String>? browserFlags,
    bool? crossOriginIsolation,
    WebDevServerConfig? devServerConfig,
    bool? enableExposeUrl,
    bool? enableExpressionEvaluation,
    String? launchUrl,
    bool? nativeNullAssertions,
    WebRendererMode? renderer,
    bool? runHeadless,
    UrlTunneller? urlTunneller,
    bool? useSseForDebugBackend,
    bool? useSseForDebugProxy,
    bool? useSseForInjectedClient,
    bool? useWasm,
    Map<String, String>? webDefines,
  }) => WebDebugConfig(
    browserDebugPort: browserDebugPort ?? this.browserDebugPort,
    browserFlags: browserFlags ?? this.browserFlags,
    crossOriginIsolation: crossOriginIsolation ?? this.crossOriginIsolation,
    devServerConfig: devServerConfig ?? this.devServerConfig,
    enableExposeUrl: enableExposeUrl ?? this.enableExposeUrl,
    enableExpressionEvaluation: enableExpressionEvaluation ?? this.enableExpressionEvaluation,
    launchUrl: launchUrl ?? this.launchUrl,
    nativeNullAssertions: nativeNullAssertions ?? this.nativeNullAssertions,
    renderer: renderer ?? this.renderer,
    runHeadless: runHeadless ?? this.runHeadless,
    urlTunneller: urlTunneller ?? this.urlTunneller,
    useSseForDebugBackend: useSseForDebugBackend ?? this.useSseForDebugBackend,
    useSseForDebugProxy: useSseForDebugProxy ?? this.useSseForDebugProxy,
    useSseForInjectedClient: useSseForInjectedClient ?? this.useSseForInjectedClient,
    useWasm: useWasm ?? this.useWasm,
    webDefines: webDefines ?? this.webDefines,
  );

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    _kPortKey: devServerConfig?.port,
    _kHostnameKey: devServerConfig?.host,
    _kTlsCertPathKey: devServerConfig?.https?.certPath,
    _kTlsCertKeyPathKey: devServerConfig?.https?.certKeyPath,
    _kWebEnableExposeUrlKey: enableExposeUrl,
    _kWebUseSseForDebugProxyKey: useSseForDebugProxy,
    _kWebUseSseForDebugBackendKey: useSseForDebugBackend,
    _kWebUseSseForInjectedClientKey: useSseForInjectedClient,
    _kWebRunHeadlessKey: runHeadless,
    _kWebBrowserDebugPortKey: browserDebugPort,
    _kWebBrowserFlagsKey: browserFlags,
    _kWebEnableExpressionEvaluationKey: enableExpressionEvaluation,
    _kWebLaunchUrlKey: launchUrl,
    _kWebCrossOriginIsolationKey: crossOriginIsolation,
    _kWebHeadersKey: devServerConfig?.headers ?? const <String, String>{},
    _kWebRendererKey: renderer.name,
    _kWebUseWasmKey: useWasm,
    _kNativeNullAssertionsKey: nativeNullAssertions,
    _kWebDefinesKey: webDefines,
    // TODO(jsimmons): This field is required for backward compatibility with
    // the flutter_tools binary that is currently checked into Google3.
    // Remove this when that binary has been updated.
    _kWebUseLocalCanvaskitKey: false,
  };
}

/// Web-specific debugging options accessor on [DebuggingOptions].
extension WebDebuggingOptions on DebuggingOptions {
  /// Returns the attached [WebDebugConfig], or default web options if none is attached.
  WebDebugConfig get webConfig => findPlatformOptions<WebDebugConfig>() ?? const WebDebugConfig();
}
