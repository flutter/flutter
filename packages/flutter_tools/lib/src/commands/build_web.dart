// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart'
    show DevelopmentArtifact, FlutterCommandResult, FlutterOptions;
import '../web/compile.dart';
import '../web/file_generators/flutter_service_worker_js.dart';
import '../web/web_constants.dart';
import '../web_template.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand({
    required super.logger,
    required FileSystem fileSystem,
    required bool verboseHelp,
  }) : _fileSystem = fileSystem,
       super(verboseHelp: verboseHelp) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    usesOutputDir();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesDartDefineOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNativeNullAssertions();

    //
    // Flutter web-specific options
    //
    argParser.addSeparator('Flutter web options');
    argParser.addOption(
      'base-href',
      help:
          'Overrides the href attribute of the <base> tag in web/index.html. '
          'No change is done to web/index.html file if this flag is not provided. '
          'The value has to start and end with a slash "/". '
          'For more information: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base',
    );
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

  final FileSystem _fileSystem;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.web,
  };

  @override
  final name = 'web';

  @override
  bool get hidden => !featureFlags.isWebEnabled;

  @override
  final description = 'Build a web application bundle.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!featureFlags.isWebEnabled) {
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
      globals.logger.printBox(title: 'New feature', '''
  WebAssembly compilation is new. Understand the details before deploying to production.
  $kWasmMoreInfo''');

      compilerConfigs = <WebCompilerConfig>[
        WasmCompilerConfig(
          optimizationLevel: optimizationLevel,
          stripWasm: boolArg('strip-wasm'),
          sourceMaps: sourceMaps,
          minify: minifyWasm,
        ),
        JsCompilerConfig(
          csp: boolArg('csp'),
          dumpInfo: boolArg('dump-info'),
          minify: minifyJs,
          nativeNullAssertions: boolArg('native-null-assertions'),
          noFrequencyBasedMinification: boolArg('no-frequency-based-minification'),
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
          noFrequencyBasedMinification: boolArg('no-frequency-based-minification'),
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
    if (!_fileSystem.currentDirectory
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

    final webBuilder = WebBuilder(
      logger: globals.logger,
      processManager: globals.processManager,
      buildSystem: globals.buildSystem,
      fileSystem: globals.fs,
      flutterVersion: globals.flutterVersion,
      analytics: globals.analytics,
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
    );
    return FlutterCommandResult.success();
  }
}
