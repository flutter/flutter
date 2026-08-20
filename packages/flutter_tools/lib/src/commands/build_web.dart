// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../web/compile.dart';
import '../web/file_generators/flutter_service_worker_js.dart';
import '../web/web_constants.dart';
import '../web/web_options.dart';
import '../web_template.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand({
    required super.logger,
    required FileSystem fileSystem,
    required bool verboseHelp,
  }) : _fileSystem = fileSystem,
       super(verboseHelp: verboseHelp) {
    registerOptionBundles(<OptionBundle>[
      CommonBuildOptionsBundle(verboseHelp: verboseHelp),
      BuildModeOptionsBundle(verboseHelp: verboseHelp),
      DartCompileOptionsBundle(verboseHelp: verboseHelp),
      WebOptionsBundle(verboseHelp: verboseHelp),
    ]);
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

    final String? optimizationLevelArg = getValue(WebOptions.optimizationLevel);
    final int? optimizationLevel = optimizationLevelArg != null
        ? int.parse(optimizationLevelArg)
        : null;

    final String? dart2jsOptimizationLevelValue = getValue(WebOptions.dart2jsOptimization);
    final int? jsOptimizationLevel = dart2jsOptimizationLevelValue != null
        ? int.parse(dart2jsOptimizationLevelValue.substring(1))
        : optimizationLevel;

    final List<String> dartDefines = extractDartDefines(
      defineConfigJsonMap: extractDartDefineConfigJsonMap(),
    );
    final bool useWasm = getValue(WebOptions.wasm);
    // See also: RunCommandBase.webRenderer and TestCommand.webRenderer.
    final webRenderer = WebRendererMode.fromDartDefines(dartDefines, useWasm: useWasm);

    final bool sourceMaps = getValue(WebOptions.sourceMaps);
    final bool? minifyJs = getParsedValue(WebOptions.minifyJs);
    final bool? minifyWasm = getParsedValue(WebOptions.minifyWasm);

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
          stripWasm: getValue(WebOptions.stripWasm),
          sourceMaps: sourceMaps,
          minify: minifyWasm,
          enableWasmDeferredLoading: getValue(WebOptions.enableWasmDeferredLoading),
        ),
        JsCompilerConfig(
          csp: getValue(WebOptions.csp),
          dumpInfo: getValue(WebOptions.dumpInfo),
          minify: minifyJs,
          nativeNullAssertions: getValue(CommonOptions.nativeNullAssertions),
          useFrequencyBasedMinification: !getValue(WebOptions.noFrequencyBasedMinification),
          optimizationLevel: jsOptimizationLevel,
          sourceMaps: sourceMaps,
        ),
      ];
    } else {
      compilerConfigs = <WebCompilerConfig>[
        JsCompilerConfig(
          csp: getValue(WebOptions.csp),
          dumpInfo: getValue(WebOptions.dumpInfo),
          minify: minifyJs,
          nativeNullAssertions: getValue(CommonOptions.nativeNullAssertions),
          useFrequencyBasedMinification: !getValue(WebOptions.noFrequencyBasedMinification),
          optimizationLevel: jsOptimizationLevel,
          sourceMaps: sourceMaps,
          renderer: webRenderer,
        ),

        if (getValue(WebOptions.wasmDryRun))
          WasmCompilerConfig(
            optimizationLevel: optimizationLevel,
            stripWasm: getValue(WebOptions.stripWasm),
            sourceMaps: sourceMaps,
            minify: minifyWasm,
            enableWasmDeferredLoading: getValue(WebOptions.enableWasmDeferredLoading),
            dryRun: true,
          ),
      ];
    }

    final BuildInfo buildInfo = await getBuildInfo();
    final String? baseHref = getValue(WebOptions.baseHref);
    final String? staticAssetsUrl = getValue(WebOptions.staticAssetsUrl);
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

    final String? outputDirectoryPath = getValue(CommonOptions.outputDir);

    final Map<String, String> webDefines = extractWebDefines();

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
      ServiceWorkerStrategy.fromCliName(getValue(WebOptions.pwaStrategy)),
      compilerConfigs: compilerConfigs,
      baseHref: baseHref,
      staticAssetsUrl: staticAssetsUrl,
      outputDirectoryPath: outputDirectoryPath,
      webDefines: webDefines,
    );
    return FlutterCommandResult.success();
  }
}
