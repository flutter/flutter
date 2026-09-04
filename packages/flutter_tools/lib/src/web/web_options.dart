// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../runner/options/option_bundle.dart';
import '../runner/options/option_descriptor.dart';
import '../web_template.dart';
import 'file_generators/flutter_service_worker_js.dart';
import 'web_constants.dart';

/// Typed option descriptors specific to Flutter Web compilation.
abstract final class WebOptions {
  static const webDefines = MultiOptionDescriptor(
    name: 'web-define',
    splitCommas: false,
    aliases: <String>['web-defines'],
    help:
        'Additional key-value pairs that will be available as constants '
        'from the String.fromEnvironment, bool.fromEnvironment, and int.fromEnvironment '
        'constructors only when compiling for the web. Multiple defines can be passed by repeating "--web-define".',
    valueHelp: 'foo=bar',
  );

  static const webDefineFromFile = MultiOptionDescriptor(
    name: 'web-define-from-file',
    help:
        'The path of a .json or .env file containing key-value pairs that will be available as environment '
        'variables only when compiling for the web. These can be accessed using the String.fromEnvironment, bool.fromEnvironment, and '
        'int.fromEnvironment constructors. Multiple define files can be passed by repeating "--web-define-from-file".',
    valueHelp: 'use-keys.json',
  );

  static const baseHref = StringOptionDescriptor(
    name: 'base-href',
    help:
        'Overrides the href attribute of the <base> tag in web/index.html. '
        'No change is done to web/index.html if this flag is not provided. '
        'The value has to start and end with a slash "/". '
        'For more information: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base',
  );

  static const staticAssetsUrl = StringOptionDescriptor(
    name: 'static-assets-url',
    help:
        'Used when serving the static assets from a different domain the application is hosted on. '
        'The value has to end with a slash "/". '
        'When this is set, it will replace all $kStaticAssetsUrlPlaceholder in web/index.html for the given value.',
  );

  static const pwaStrategy = EnumOptionDescriptor<ServiceWorkerStrategy>(
    name: 'pwa-strategy',
    hide: true,
    help:
        'This option is deprecated and will be removed in a future Flutter release.\n'
        'The caching strategy to be used by the PWA service worker.',
    values: ServiceWorkerStrategy.values,
  );

  static const webResourcesCdn = FlagOptionDescriptor(
    name: 'web-resources-cdn',
    defaultsTo: true,
    help:
        'Use WebAssembly, CanvasKit, and other web resources from a content delivery network (CDN).\n'
        'Set to "--no-web-resources-cdn" to embed all web resources locally in the built app.',
  );

  static const optimizationLevel = StringOptionDescriptor(
    name: 'optimization-level',
    abbr: 'O',
    allowed: <String>['0', '1', '2', '3', '4'],
    help: 'Sets the optimization level used for Dart compilation to JavaScript/Wasm.',
  );

  static const sourceMaps = FlagOptionDescriptor(
    name: 'source-maps',
    help:
        'Generate a sourcemap file. These can be used by browsers '
        'to view and debug the original source code of a compiled and minified Dart '
        'application.',
  );

  static const csp = FlagOptionDescriptor(
    name: 'csp',
    negatable: false,
    help:
        'Disable dynamic generation of code in the generated output. '
        'This is necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).',
  );

  static const dart2jsOptimization = StringOptionDescriptor(
    name: 'dart2js-optimization',
    allowed: <String>['O1', 'O2', 'O3', 'O4'],
    help:
        'Sets the optimization level used for Dart compilation to JavaScript. '
        'Deprecated: Please use "-O=<level>" / "--optimization-level=<level>".',
  );

  static const dumpInfo = FlagOptionDescriptor(
    name: 'dump-info',
    negatable: false,
    verboseOnly: true,
    help:
        'Passes "--dump-info" to the Javascript compiler which generates '
        'information about the generated code in main.dart.js.info.json.',
  );

  static const minifyJs = NullableFlagOptionDescriptor(
    name: 'minify-js',
    verboseOnly: true,
    help:
        'Generate minified output for js. '
        'If not explicitly set, uses the compilation mode (debug, profile, release).',
  );

  static const minifyWasm = NullableFlagOptionDescriptor(
    name: 'minify-wasm',
    verboseOnly: true,
    help:
        'Generate minified output for wasm. '
        'If not explicitly set, uses the compilation mode (debug, profile, release).',
  );

  static const enableWasmDeferredLoading = FlagOptionDescriptor(
    name: 'enable-wasm-deferred-loading',
    verboseOnly: true,
    help: 'Enable multi-module deferred loading for Wasm.',
  );

  static const wasmDryRun = FlagOptionDescriptor(
    name: 'wasm-dry-run',
    defaultsTo: true,
    help:
        'Compiles wasm in dry run mode during JS only compilations. '
        'Disable to suppress warnings.',
  );

  static const noFrequencyBasedMinification = FlagOptionDescriptor(
    name: 'no-frequency-based-minification',
    negatable: false,
    verboseOnly: true,
    help:
        'Disables the frequency based minifier. '
        'Useful for comparing the output between builds.',
  );

  static const wasm = FlagOptionDescriptor(
    name: 'wasm',
    negatable: false,
    help: 'Compile to WebAssembly (with fallback to JavaScript).\n$kWasmMoreInfo',
  );

  static const stripWasm = FlagOptionDescriptor(
    name: 'strip-wasm',
    defaultsTo: true,
    help: 'Whether to strip the resulting wasm file of static symbol names.',
  );

  static const webHeader = MultiOptionDescriptor(
    name: 'web-header',
    splitCommas: false,
    verboseOnly: true,
    help:
        'Additional key-value pairs that will added by the web server '
        'as headers to all responses. Multiple headers can be passed by '
        'repeating "--web-header" multiple times.',
    valueHelp: 'X-Custom-Header=header-value',
  );

  static const webHostname = StringOptionDescriptor(
    name: 'web-hostname',
    verboseOnly: true,
    help:
        'The hostname that the web server will use to resolve an IP to serve '
        'from. The unresolved hostname is used to launch Chrome when using '
        'the chrome Device. The name "any" may also be used to serve on any '
        'IPV4 for either the Chrome or web-server device.',
  );

  static const webPort = StringOptionDescriptor(
    name: 'web-port',
    verboseOnly: true,
    help:
        'The host port to serve the web application from. If not provided, the tool '
        'will select a random open port on the host.',
  );

  static const webTlsCertPath = StringOptionDescriptor(
    name: 'web-tls-cert-path',
    help:
        'The certificate that host will use to serve using TLS connection. '
        'If not provided, the tool will use default http scheme.',
  );

  static const webTlsCertKeyPath = StringOptionDescriptor(
    name: 'web-tls-cert-key-path',
    help:
        'The certificate key that host will use to authenticate cert. '
        'If not provided, the tool will use default http scheme.',
  );

  static const webServerDebugProtocol = DefaultedStringOptionDescriptor(
    name: 'web-server-debug-protocol',
    allowed: <String>['sse', 'ws'],
    defaultsTo: 'ws',
    verboseOnly: true,
    help:
        'The protocol (SSE or WebSockets) to use for the debug service proxy '
        'when using the Web Server device and Dart Debug extension. '
        'This is useful for editors/debug adapters that do not support debugging '
        'over SSE (the default protocol for Web Server/Dart Debugger extension).',
  );

  static const webServerDebugBackendProtocol = DefaultedStringOptionDescriptor(
    name: 'web-server-debug-backend-protocol',
    allowed: <String>['sse', 'ws'],
    defaultsTo: 'ws',
    verboseOnly: true,
    help:
        'The protocol (SSE or WebSockets) to use for the Dart Debug Extension '
        'backend service when using the Web Server device. '
        'Using WebSockets can improve performance but may fail when connecting through '
        'some proxy servers.',
  );

  static const webServerDebugInjectedClientProtocol = DefaultedStringOptionDescriptor(
    name: 'web-server-debug-injected-client-protocol',
    allowed: <String>['sse', 'ws'],
    defaultsTo: 'ws',
    verboseOnly: true,
    help:
        'The protocol (SSE or WebSockets) to use for the injected client '
        'when using the Web Server device. '
        'Using WebSockets can improve performance but may fail when connecting through '
        'some proxy servers.',
  );

  static const webAllowExposeUrl = FlagOptionDescriptor(
    name: 'web-allow-expose-url',
    verboseOnly: true,
    help:
        'Enables daemon-to-editor requests (app.exposeUrl) for exposing URLs '
        'when running on remote machines.',
  );

  static const webRunHeadless = FlagOptionDescriptor(
    name: 'web-run-headless',
    verboseOnly: true,
    help:
        'Launches the browser in headless mode. Currently only Chrome '
        'supports this option.',
  );

  static const webBrowserDebugPort = StringOptionDescriptor(
    name: 'web-browser-debug-port',
    verboseOnly: true,
    help:
        'The debug port the browser should use. If not specified, a '
        'random port is selected. Currently only Chrome supports this option. '
        'It serves the Chrome DevTools Protocol '
        '(https://chromedevtools.github.io/devtools-protocol/).',
  );

  static const webEnableExpressionEvaluation = FlagOptionDescriptor(
    name: 'web-enable-expression-evaluation',
    defaultsTo: true,
    verboseOnly: true,
    help: 'Enables expression evaluation in the debugger.',
  );

  static const webLaunchUrl = StringOptionDescriptor(
    name: 'web-launch-url',
    help:
        'The URL to provide to the browser. Defaults to an HTTP URL with the host '
        'name of "--web-hostname", the port of "--web-port", and the path set to "/".',
  );

  static const webBrowserFlags = MultiOptionDescriptor(
    name: 'web-browser-flag',
    valueHelp: '--foo=bar',
    verboseOnly: true,
    help:
        'Additional flag to pass to a browser instance at startup.\n'
        'Chrome: https://www.chromium.org/developers/how-tos/run-chromium-with-flags/\n'
        'Firefox: https://wiki.mozilla.org/Firefox/CommandLineOptions\n'
        'Multiple flags can be passed by repeating "--web-browser-flag" multiple times.',
  );

  static const crossOriginIsolation = NullableFlagOptionDescriptor(
    name: 'cross-origin-isolation',
    verboseOnly: true,
    help:
        'Adds the Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy '
        'headers to the web server. These headers are required for using APIs like '
        'SharedArrayBuffer. This is on by default for the "skwasm" web renderer, '
        'and this flag can be used to override the default. To disable this for the '
        'skwasm renderer, use "--no-cross-origin-isolation".',
  );
}

/// A bundle encapsulating general Flutter Web options and flags.
class WebCoreOptionsBundle extends OptionBundle {
  const WebCoreOptionsBundle();

  @override
  String? get title => 'Flutter web options';

  @override
  List<OptionDescriptor<Object?>> get descriptors => [
    WebOptions.baseHref,
    WebOptions.staticAssetsUrl,
    WebOptions.pwaStrategy,
    WebOptions.webResourcesCdn,
    WebOptions.webDefines,
    WebOptions.webDefineFromFile,
    WebOptions.optimizationLevel,
    WebOptions.sourceMaps,
  ];
}

/// A bundle encapsulating JavaScript-specific compilation options.
class WebJsOptionsBundle extends OptionBundle {
  const WebJsOptionsBundle();

  @override
  String? get title => 'JavaScript compilation options';

  @override
  List<OptionDescriptor<Object?>> get descriptors => const <OptionDescriptor<Object?>>[
    WebOptions.csp,
    WebOptions.dart2jsOptimization,
    WebOptions.dumpInfo,
    WebOptions.minifyJs,
    WebOptions.noFrequencyBasedMinification,
  ];
}

/// A bundle encapsulating WebAssembly-specific compilation options.
class WebWasmOptionsBundle extends OptionBundle {
  const WebWasmOptionsBundle();

  @override
  String? get title => 'WebAssembly compilation options';

  @override
  List<OptionDescriptor<Object?>> get descriptors => const <OptionDescriptor<Object?>>[
    WebOptions.wasm,
    WebOptions.stripWasm,
    WebOptions.minifyWasm,
    WebOptions.enableWasmDeferredLoading,
    WebOptions.wasmDryRun,
  ];
}

/// A composite bundle encapsulating all options and flags needed for Flutter Web compilation.
class WebOptionsBundle extends OptionBundle {
  const WebOptionsBundle();

  @override
  List<OptionBundle> get subBundles => const <OptionBundle>[
    WebCoreOptionsBundle(),
    WebJsOptionsBundle(),
    WebWasmOptionsBundle(),
  ];
}
