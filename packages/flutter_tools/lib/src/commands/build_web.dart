// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../runner/flutter_command.dart'
    show DevelopmentArtifact, FlutterCommandResult, FlutterOptions;
import '../version.dart';
import '../web/compile.dart';
import '../web/file_generators/flutter_service_worker_js.dart';
import '../web/web_constants.dart';
import '../web_template.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand({
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    required bool verboseHelp,
    super.analytics,
    FeatureFlags? featureFlags,
    WebBuilder? webBuilder,
  }) : _buildSystem = buildSystem,
       _featureFlags = featureFlags ?? const _DefaultFeatureFlags(),
       _toolContext = toolContext,
       _webBuilder = webBuilder,
       super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         toolContext: toolContext,
         verboseHelp: verboseHelp,
       ) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    usesOutputDir();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesDartDefineOption();
    usesWebDefineOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNativeNullAssertions();

    //
    // Flutter web-specific options
    //
    argParser.addSeparator('Flutter web options');
    usesBaseHrefOption();
    argParser.addOption(
      'static-assets-url',
      help:
          'Used when serving the static assets from a different domain the application is hosted on. '
          'The value has to end with a slash "/". '
          'When this is set, it will replace all $kStaticAssetsUrlPlaceholder in web/index.html for the given value.',
    );
    argParser.addOption(
      'pwa-strategy',
      hide: true,
      help:
          'This option is deprecated and will be removed in a future Flutter release.\n'
          'The caching strategy to be used by the PWA service worker.',
      allowed: ServiceWorkerStrategy.values.map((ServiceWorkerStrategy e) => e.cliName),
      allowedHelp: CliEnum.allowedHelp(ServiceWorkerStrategy.values),
    );
    usesWebResourcesCdnFlag();

    //
    // Common compilation options among JavaScript and Wasm
    //
    argParser.addOption(
      'optimization-level',
      abbr: 'O',
      help: 'Sets the optimization level used for Dart compilation to JavaScript/Wasm.',
      allowed: const <String>['0', '1', '2', '3', '4'],
    );
    argParser.addFlag(
      'source-maps',
      help:
          'Generate a sourcemap file. These can be used by browsers '
          'to view and debug the original source code of a compiled and minified Dart '
          'application.',
    );

    //
    // JavaScript compilation options
    //
    argParser.addSeparator('JavaScript compilation options');
    argParser.addFlag(
      'csp',
      negatable: false,
      help:
          'Disable dynamic generation of code in the generated output. '
          'This is necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).',
    );
    argParser.addOption(
      'dart2js-optimization',
      help:
          'Sets the optimization level used for Dart compilation to JavaScript. '
          'Deprecated: Please use "-O=<level>" / "--optimization-level=<level>".',
      allowed: const <String>['O1', 'O2', 'O3', 'O4'],
    );
    argParser.addFlag(
      'dump-info',
      negatable: false,
      help:
          'Passes "--dump-info" to the Javascript compiler which generates '
          'information about the generated code in main.dart.js.info.json.',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'minify-js',
      help:
          'Generate minified output for js. '
          'If not explicitly set, uses the compilation mode (debug, profile, release).',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'minify-wasm',
      help:
          'Generate minified output for wasm. '
          'If not explicitly set, uses the compilation mode (debug, profile, release).',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'enable-wasm-deferred-loading',
      help: 'Enable multi-module deferred loading for Wasm.',
      hide: !verboseHelp,
    );
    argParser.addFlag(
      'wasm-dry-run',
      defaultsTo: true,
      help:
          'Compiles wasm in dry run mode during JS only compilations. '
          'Disable to suppress warnings.',
    );
    argParser.addFlag(
      'no-frequency-based-minification',
      negatable: false,
      help:
          'Disables the frequency based minifier. '
          'Useful for comparing the output between builds.',
      hide: !verboseHelp,
    );

    //
    // WebAssembly compilation options
    //
    argParser.addSeparator('WebAssembly compilation options');
    argParser.addFlag(
      FlutterOptions.kWebWasmFlag,
      help: 'Compile to WebAssembly (with fallback to JavaScript).\n$kWasmMoreInfo',
      negatable: false,
    );
    argParser.addFlag(
      'strip-wasm',
      help: 'Whether to strip the resulting wasm file of static symbol names.',
      defaultsTo: true,
    );
  }

  final BuildSystem _buildSystem;
  final FeatureFlags _featureFlags;
  final ToolContext _toolContext;
  final WebBuilder? _webBuilder;

  @visibleForTesting
  BuildSystem get buildSystem => _buildSystem;

  @visibleForTesting
  FeatureFlags get featureFlags => _featureFlags;

  @visibleForTesting
  @override
  ToolContext get toolContext => _toolContext;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.web,
  };

  @override
  final name = 'web';

  @override
  bool get hidden => !_featureFlags.isWebEnabled;

  @override
  final description = 'Build a web application bundle.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = _toolContext.fs;
    final FlutterVersion flutterVersion = _toolContext.flutterVersion;
    final Logger logger = this.logger;
    final ProcessManager processManager = _toolContext.processManager;

    if (!_featureFlags.isWebEnabled) {
      throwToolExit(
        '"build web" is not currently supported. To enable, run "flutter config --enable-web".',
      );
    }

    final String? optimizationLevelArg = stringArg('optimization-level');
    final int? optimizationLevel = optimizationLevelArg != null
        ? int.parse(optimizationLevelArg)
        : null;

    final String? dart2jsOptimizationLevelValue = stringArg('dart2js-optimization');
    final int? jsOptimizationLevel = dart2jsOptimizationLevelValue != null
        ? int.parse(dart2jsOptimizationLevelValue.substring(1))
        : optimizationLevel;

    final List<String> dartDefines = extractDartDefines(
      defineConfigJsonMap: extractDartDefineConfigJsonMap(),
    );
    final bool useWasm = boolArg(FlutterOptions.kWebWasmFlag);
    // See also: RunCommandBase.webRenderer and TestCommand.webRenderer.
    final webRenderer = WebRendererMode.fromDartDefines(dartDefines, useWasm: useWasm);

    final bool sourceMaps = boolArg('source-maps');
    final bool? minifyJs = argResults!.wasParsed('minify-js') ? boolArg('minify-js') : null;
    final bool? minifyWasm = argResults!.wasParsed('minify-wasm') ? boolArg('minify-wasm') : null;

    final List<WebCompilerConfig> compilerConfigs;

    if (useWasm) {
      if (webRenderer != WebRendererMode.getDefault(useWasm: true)) {
        throwToolExit(
          'Do not attempt to set a web renderer when using "--${FlutterOptions.kWebWasmFlag}"',
        );
      }
      logger.printBox(title: 'New feature', '''
  WebAssembly compilation is new. Understand the details before deploying to production.
  $kWasmMoreInfo''');

      compilerConfigs = <WebCompilerConfig>[
        WasmCompilerConfig(
          optimizationLevel: optimizationLevel,
          stripWasm: boolArg('strip-wasm'),
          sourceMaps: sourceMaps,
          minify: minifyWasm,
          enableWasmDeferredLoading: boolArg('enable-wasm-deferred-loading'),
        ),
        JsCompilerConfig(
          csp: boolArg('csp'),
          dumpInfo: boolArg('dump-info'),
          minify: minifyJs,
          nativeNullAssertions: boolArg('native-null-assertions'),
          useFrequencyBasedMinification: !boolArg('no-frequency-based-minification'),
          optimizationLevel: jsOptimizationLevel,
          sourceMaps: sourceMaps,
        ),
      ];
    } else {
      compilerConfigs = <WebCompilerConfig>[
        JsCompilerConfig(
          csp: boolArg('csp'),
          dumpInfo: boolArg('dump-info'),
          minify: minifyJs,
          nativeNullAssertions: boolArg('native-null-assertions'),
          useFrequencyBasedMinification: !boolArg('no-frequency-based-minification'),
          optimizationLevel: jsOptimizationLevel,
          sourceMaps: sourceMaps,
          renderer: webRenderer,
        ),
        if (boolArg('wasm-dry-run'))
          WasmCompilerConfig(
            optimizationLevel: optimizationLevel,
            stripWasm: boolArg('strip-wasm'),
            sourceMaps: sourceMaps,
            minify: minifyWasm,
            enableWasmDeferredLoading: boolArg('enable-wasm-deferred-loading'),
            dryRun: true,
          ),
      ];
    }

    final BuildInfo buildInfo = await getBuildInfo();
    final String? baseHref = stringArg('base-href');
    final String? staticAssetsUrl = stringArg('static-assets-url');
    if (baseHref != null && !(baseHref.startsWith('/') && baseHref.endsWith('/'))) {
      throwToolExit(
        'Received a --base-href value of "$baseHref"\n'
        '--base-href should start and end with /',
      );
    }
    if (staticAssetsUrl != null && !staticAssetsUrl.endsWith('/')) {
      throwToolExit(
        'Received a --static-assets-url value of "$staticAssetsUrl"\n'
        '--static-assets-url should end with /',
      );
    }
    if (!project.web.existsSync()) {
      throwToolExit(
        'This project is not configured for the web.\n'
        'To configure this project for the web, run flutter create . --platforms web',
      );
    }
    if (!fs.currentDirectory
            .childDirectory('web')
            .childFile('index.html')
            .readAsStringSync()
            .contains(kBaseHrefPlaceholder) &&
        baseHref != null) {
      throwToolExit(
        "Couldn't find the placeholder for base href. "
        'Please add `<base href="$kBaseHrefPlaceholder">` to web/index.html',
      );
    }

    // Currently supporting options [output-dir] and [output] as
    // valid approaches for setting output directory of build artifacts
    final String? outputDirectoryPath = stringArg('output');

    final Artifacts artifacts = _toolContext.artifacts;
    final Cache cache = _toolContext.cache;
    final Platform platform = _toolContext.platform;
    final AnsiTerminal terminal = _toolContext.terminal;

    final Map<String, String> webDefines = extractWebDefines();
    final WebBuilder webBuilder =
        _webBuilder ??
        WebBuilder(
          analytics: analytics,
          artifacts: artifacts,
          buildSystem: _buildSystem,
          cache: cache,
          fileSystem: fs,
          flutterVersion: flutterVersion,
          logger: logger,
          platform: platform,
          processManager: processManager,
          terminal: terminal,
        );
    await webBuilder.buildWeb(
      project,
      targetFile,
      buildInfo,
      ServiceWorkerStrategy.fromCliName(stringArg('pwa-strategy')),
      compilerConfigs: compilerConfigs,
      baseHref: baseHref,
      staticAssetsUrl: staticAssetsUrl,
      outputDirectoryPath: outputDirectoryPath,
      webDefines: webDefines,
    );
    return FlutterCommandResult.success();
  }
}

class _DefaultFeatureFlags extends FeatureFlags {
  const _DefaultFeatureFlags();

  @override
  bool isEnabled(Feature feature) => false;
  @override
  bool get isLinuxEnabled => false;
  @override
  bool get isMacOSEnabled => false;
  @override
  bool get isWindowsEnabled => false;
  @override
  bool get isWebEnabled => false;
  @override
  bool get isAndroidEnabled => false;
  @override
  bool get isIOSEnabled => false;
  @override
  bool get isFuchsiaEnabled => false;
  @override
  bool get areCustomDevicesEnabled => false;
  @override
  bool get isCliAnimationEnabled => false;
  @override
  bool get isNativeAssetsEnabled => false;
  @override
  bool get isDartDataAssetsEnabled => false;
  @override
  bool get isRecordUseEnabled => false;
  @override
  bool get isSwiftPackageManagerEnabled => false;
  @override
  bool get isOmitLegacyVersionFileEnabled => false;
  @override
  bool get isWindowingEnabled => false;
  @override
  bool get isAccessibilityEvaluationsEnabled => false;
  @override
  bool get isLLDBDebuggingEnabled => false;
  @override
  bool get isUISceneMigrationEnabled => false;
  @override
  bool get isRiscv64SupportEnabled => false;
  @override
  bool get isMacOSArm64OnlyEnabled => false;
}
