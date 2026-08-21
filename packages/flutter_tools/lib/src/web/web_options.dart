// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/utils.dart';
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

  static final pwaStrategy = StringOptionDescriptor(
    name: 'pwa-strategy',
    hide: true,
    help:
        'This option is deprecated and will be removed in a future Flutter release.\n'
        'The caching strategy to be used by the PWA service worker.',
    allowed: ServiceWorkerStrategy.values.map((ServiceWorkerStrategy e) => e.cliName).toList(),
    allowedHelp: CliEnum.allowedHelp(ServiceWorkerStrategy.values),
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
