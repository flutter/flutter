// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/build_targets.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../isolated/build_targets.dart';
import '../runner/flutter_command.dart';
import '../web/compile.dart';
import '../web/web_constants.dart';
import '../web/web_options.dart';
import '../web_template.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand({
    required BuildSystem buildSystem,
    required FeatureFlags featureFlags,
    required ToolContext toolContext,
    required super.verboseHelp,
    @visibleForTesting BuildTargets? buildTargets,
    @visibleForTesting WebBuilder? webBuilder,
  }) : _buildSystem = buildSystem,
       _buildTargets = buildTargets,
       _featureFlags = featureFlags,
       _webBuilder = webBuilder,
       super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         toolContext: toolContext,
       ) {
    registerOptionBundles(const <OptionBundle>[
      CommonBuildOptionsBundle(),
      BuildModeOptionsBundle(),
      DartCompileOptionsBundle(),
      WebOptionsBundle(),
    ]);
  }

  final BuildSystem _buildSystem;
  final BuildTargets? _buildTargets;
  final FeatureFlags _featureFlags;
  final WebBuilder? _webBuilder;

  @visibleForTesting
  BuildSystem get buildSystem => _buildSystem;

  @override
  ToolContext get toolContext => super.toolContext!;

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
    final FileSystem fs = toolContext.fs;
    final Logger logger = this.logger;

    if (!_featureFlags.isWebEnabled) {
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
    final bool? minifyJs = getValue(WebOptions.minifyJs);
    final bool? minifyWasm = getValue(WebOptions.minifyWasm);

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

    final String? outputDirectoryPath = getValue(CommonOptions.outputDir);

    final Map<String, String> webDefines = extractWebDefines();

    final WebBuilder webBuilder =
        _webBuilder ??
        WebBuilder(
          analytics: analytics,
          buildSystem: _buildSystem,
          buildTargets: _buildTargets ?? const BuildTargetsImpl(),
          fileSystem: fs,
          flutterVersion: toolContext.flutterVersion,
          logger: toolContext.logger,
          processManager: toolContext.processManager,
          toolContext: toolContext,
        );
    await webBuilder.buildWeb(
      project,
      targetFile,
      buildInfo,
      getValue(WebOptions.pwaStrategy),
      compilerConfigs: compilerConfigs,
      baseHref: baseHref,
      staticAssetsUrl: staticAssetsUrl,
      outputDirectoryPath: outputDirectoryPath,
      webDefines: webDefines,
    );
    return FlutterCommandResult.success();
  }
}
