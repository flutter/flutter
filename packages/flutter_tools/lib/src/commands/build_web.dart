// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/targets/web.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../html_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart'
    show DevelopmentArtifact, FlutterCommandResult;
import '../web/compile.dart';
import 'build.dart';

class BuildWebCommand extends BuildSubCommand {
  BuildWebCommand({
    required super.logger,
    required FileSystem fileSystem,
    required bool verboseHelp,
  }) : _fileSystem = fileSystem, super(verboseHelp: verboseHelp) {
    addTreeShakeIconsFlag();
    usesTargetOption();
    usesOutputDir();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addBuildModeFlags(verboseHelp: verboseHelp, excludeDebug: true);
    usesDartDefineOption();
    addEnableExperimentation(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addNativeNullAssertions();

    //
    // Flutter web-specific options
    //
    argParser.addSeparator('Flutter web options');
    argParser.addOption('base-href',
      help: 'Overrides the href attribute of the <base> tag in web/index.html. '
          'No change is done to web/index.html file if this flag is not provided. '
          'The value has to start and end with a slash "/". '
          'For more information: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base'
    );
    argParser.addOption('pwa-strategy',
      defaultsTo: kOfflineFirst,
      help: 'The caching strategy to be used by the PWA service worker.',
      allowed: <String>[
        kOfflineFirst,
        kNoneWorker,
      ],
      allowedHelp: <String, String>{
        kOfflineFirst: 'Attempt to cache the application shell eagerly and '
                       'then lazily cache all subsequent assets as they are loaded. When '
                       'making a network request for an asset, the offline cache will be '
                       'preferred.',
        kNoneWorker:   'Generate a service worker with no body. This is useful for '
                       'local testing or in cases where the service worker caching functionality '
                       'is not desirable',
      },
    );
    usesWebRendererOption();
    usesWebResourcesCdnFlag();

    //
    // JavaScript compilation options
    //
    argParser.addSeparator('JavaScript compilation options');
    argParser.addFlag('csp',
      negatable: false,
      help: 'Disable dynamic generation of code in the generated output. '
            'This is necessary to satisfy CSP restrictions (see http://www.w3.org/TR/CSP/).'
    );
    argParser.addFlag(
      'source-maps',
      help: 'Generate a sourcemap file. These can be used by browsers '
            'to view and debug the original source code of a compiled and minified Dart '
            'application.'
    );
    argParser.addOption('dart2js-optimization',
      help: 'Sets the optimization level used for Dart compilation to JavaScript. '
          'Valid values range from O0 to O4.',
          defaultsTo: kDart2jsDefaultOptimizationLevel
    );
    argParser.addFlag('dump-info', negatable: false,
      help: 'Passes "--dump-info" to the Javascript compiler which generates '
          'information about the generated code is a .js.info.json file.'
    );
    argParser.addFlag('no-frequency-based-minification', negatable: false,
      help: 'Disables the frequency based minifier. '
          'Useful for comparing the output between builds.'
    );

    //
    // Experimental options
    //
    if (featureFlags.isFlutterWebWasmEnabled) {
      argParser.addSeparator('Experimental options');
      argParser.addFlag(
        'wasm',
        help: 'Compile to WebAssembly rather than JavaScript.',
        negatable: false,
      );
    } else {
      // Add the flag as hidden. Will give a helpful error message in [runCommand] below.
      argParser.addFlag(
        'wasm',
        hide: true,
      );
    }
  }

  final FileSystem _fileSystem;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async =>
      const <DevelopmentArtifact>{
        DevelopmentArtifact.web,
      };

  @override
  final String name = 'web';

  @override
  bool get hidden => !featureFlags.isWebEnabled;

  @override
  final String description = 'Build a web application bundle.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!featureFlags.isWebEnabled) {
      throwToolExit('"build web" is not currently supported. To enable, run "flutter config --enable-web".');
    }

    final bool wasmRequested = boolArg('wasm');
    if (wasmRequested && !featureFlags.isFlutterWebWasmEnabled) {
      throwToolExit('Compiling to WebAssembly (wasm) is only available on the master channel.');
    }

    final FlutterProject flutterProject = FlutterProject.current();
    final String target = stringArg('target')!;
    final BuildInfo buildInfo = await getBuildInfo();
    if (buildInfo.isDebug) {
      throwToolExit('debug builds cannot be built directly for the web. Try using "flutter run"');
    }
    final String? baseHref = stringArg('base-href');
    if (baseHref != null && !(baseHref.startsWith('/') && baseHref.endsWith('/'))) {
      throwToolExit('base-href should start and end with /');
    }
    if (!flutterProject.web.existsSync()) {
      throwToolExit('Missing index.html.');
    }
    if (!_fileSystem.currentDirectory
        .childDirectory('web')
        .childFile('index.html')
        .readAsStringSync()
        .contains(kBaseHrefPlaceholder) &&
        baseHref != null) {
      throwToolExit(
        "Couldn't find the placeholder for base href. "
        'Please add `<base href="$kBaseHrefPlaceholder">` to web/index.html'
      );
    }

    // Currently supporting options [output-dir] and [output] as
    // valid approaches for setting output directory of build artifacts
    final String? outputDirectoryPath = stringArg('output');

    displayNullSafetyMode(buildInfo);
    final WebBuilder webBuilder = WebBuilder(
      logger: globals.logger,
      buildSystem: globals.buildSystem,
      fileSystem: globals.fs,
      flutterVersion: globals.flutterVersion,
      usage: globals.flutterUsage,
    );
    await webBuilder.buildWeb(
      flutterProject,
      target,
      buildInfo,
      boolArg('csp'),
      stringArg('pwa-strategy')!,
      boolArg('source-maps'),
      boolArg('native-null-assertions'),
      wasmRequested,
      baseHref: baseHref,
      dart2jsOptimization: stringArg('dart2js-optimization') ?? kDart2jsDefaultOptimizationLevel,
      outputDirectoryPath: outputDirectoryPath,
      dumpInfo: boolArg('dump-info'),
      noFrequencyBasedMinification: boolArg('no-frequency-based-minification'),
    );
    return FlutterCommandResult.success();
  }
}
