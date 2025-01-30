// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/deferred_component.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../bundle.dart' as bundle;
import '../cache.dart';
import '../convert.dart';
import '../dart/pub.dart';
import '../device.dart';
import '../flutter_manifest.dart';

import '../globals.dart' as globals;
import '../linux/build_linux.dart';
import '../macos/build_macos.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../widget_preview/preview_code_generator.dart';
import '../widget_preview/preview_detector.dart';
import '../windows/build_windows.dart';
import 'create_base.dart';
import 'daemon.dart';

// TODO(bkonyi): use dependency injection instead of global accessors throughout this file.
class WidgetPreviewCommand extends FlutterCommand {
  // TODO(bkonyi): use dependency injection instead of globals for these commands.
  WidgetPreviewCommand() {
    addSubcommand(WidgetPreviewStartCommand());
    addSubcommand(WidgetPreviewCleanCommand());
  }

  @override
  String get description => 'Manage the widget preview environment.';

  @override
  String get name => 'widget-preview';

  @override
  String get category => FlutterCommandCategory.tools;

  // TODO(bkonyi): show when --verbose is not provided when this feature is
  // ready to ship.
  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();
}

/// Common utilities for the 'start' and 'clean' commands.
mixin WidgetPreviewSubCommandMixin on FlutterCommand {
  FlutterProject getRootProject() {
    final ArgResults results = argResults!;
    final Directory projectDir;
    if (results.rest case <String>[final String directory]) {
      projectDir = globals.fs.directory(directory);
      if (!projectDir.existsSync()) {
        throwToolExit('Could not find ${projectDir.path}.');
      }
    } else if (results.rest.length > 1) {
      throwToolExit('Only one directory should be provided.');
    } else {
      projectDir = globals.fs.currentDirectory;
    }
    return validateFlutterProjectForPreview(projectDir);
  }

  FlutterProject validateFlutterProjectForPreview(Directory directory) {
    globals.logger.printTrace('Verifying that ${directory.path} is a Flutter project.');
    final FlutterProject flutterProject = globals.projectFactory.fromDirectory(directory);
    if (!flutterProject.dartTool.existsSync()) {
      throwToolExit('${flutterProject.directory.path} is not a valid Flutter project.');
    }
    return flutterProject;
  }
}

class WidgetPreviewStartCommand extends FlutterCommand
    with CreateBase, WidgetPreviewSubCommandMixin {
  WidgetPreviewStartCommand() {
    addPubOptions();
    argParser.addFlag(
      kLaunchPreviewer,
      defaultsTo: true,
      help: 'Launches the widget preview environment.',
    );
  }

  static const String kWidgetPreviewScaffoldName = 'widget_preview_scaffold';
  static const String kLaunchPreviewer = 'launch-previewer';

  @override
  String get description => 'Starts the widget preview environment.';

  @override
  String get name => 'start';

  bool get launchPreviewer => boolArg(kLaunchPreviewer);

  late final PreviewDetector _previewDetector = PreviewDetector(
    logger: globals.logger,
    onChangeDetected: onChangeDetected,
  );

  late final PreviewCodeGenerator _previewCodeGenerator;

  /// The currently running instance of the widget preview scaffold.
  AppInstance? _widgetPreviewApp;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject rootProject = getRootProject();
    final Directory widgetPreviewScaffold = rootProject.widgetPreviewScaffold;

    // Check to see if a preview scaffold has already been generated. If not,
    // generate one.
    final bool generateScaffoldProject = !widgetPreviewScaffold.existsSync();
    widgetPreviewScaffold.createSync();

    if (generateScaffoldProject) {
      globals.logger.printStatus(
        'Creating widget preview scaffolding at: ${widgetPreviewScaffold.path}',
      );
      await generateApp(
        <String>['app', kWidgetPreviewScaffoldName],
        widgetPreviewScaffold,
        createTemplateContext(
          organization: 'flutter',
          projectName: kWidgetPreviewScaffoldName,
          titleCaseProjectName: 'Widget Preview Scaffold',
          flutterRoot: Cache.flutterRoot!,
          dartSdkVersionBounds: '^${globals.cache.dartSdkBuild}',
          linux: globals.platform.isLinux,
          macos: globals.platform.isMacOS,
          windows: globals.platform.isWindows,
        ),
        overwrite: true,
        generateMetadata: false,
      );

      // WARNING: this access of widgetPreviewScaffoldProject needs to happen after we generate the
      // scaffold project as invoking the getter triggers lazy initialization of the preview scaffold's
      // FlutterManifest before the scaffold project's pubspec has been generated.
      // TODO(bkonyi): add logic to rebuild after SDK updates
      await initialBuild(widgetPreviewScaffoldProject: rootProject.widgetPreviewScaffoldProject);
    }

    _previewCodeGenerator = PreviewCodeGenerator(
      widgetPreviewScaffoldProject: rootProject.widgetPreviewScaffoldProject,
      fs: globals.fs,
    );

    // TODO(matanlurey): Remove this comment once flutter_gen is removed.
    //
    // Tracking removal: https://github.com/flutter/flutter/issues/102983.
    //
    // Populate the pubspec after the initial build to avoid blowing away the package_config.json
    // which may have manual changes for flutter_gen support.
    await _populatePreviewPubspec(rootProject: rootProject);

    final PreviewMapping initialPreviews = await _previewDetector.initialize(rootProject.directory);
    _previewCodeGenerator.populatePreviewsInGeneratedPreviewScaffold(initialPreviews);

    if (launchPreviewer) {
      globals.shutdownHooks.addShutdownHook(() async {
        await _widgetPreviewApp?.stop();
      });
      _widgetPreviewApp = await runPreviewEnvironment(
        widgetPreviewScaffoldProject: rootProject.widgetPreviewScaffoldProject,
      );

      final int result = await _widgetPreviewApp!.runner.waitForAppToFinish();
      if (result != 0) {
        throwToolExit(null, exitCode: result);
      }
    }

    await _previewDetector.dispose();
    return FlutterCommandResult.success();
  }

  void onChangeDetected(PreviewMapping previews) {
    globals.logger.printStatus('Triggering reload based on change to preview set: $previews');
    _widgetPreviewApp?.restart();
  }

  /// Builds the application binary for the widget preview scaffold the first time the widget preview
  /// command is run.
  ///
  /// The resulting binary is used to speed up subsequent widget previewer launches by acting as a
  /// basic scaffold to load previews into using hot reload / restart.
  Future<void> initialBuild({required FlutterProject widgetPreviewScaffoldProject}) async {
    // TODO(bkonyi): handle error case where desktop device isn't enabled.
    await widgetPreviewScaffoldProject.ensureReadyForPlatformSpecificTooling(
      linuxPlatform: globals.platform.isLinux,
      macOSPlatform: globals.platform.isMacOS,
      windowsPlatform: globals.platform.isWindows,
      allowedPlugins: const <String>[],
    );

    // Generate initial package_config.json, otherwise the build will fail.
    await pub.get(
      context: PubContext.create,
      project: widgetPreviewScaffoldProject,
      offline: offline,
      outputMode: PubOutputMode.summaryOnly,
    );

    globals.logger.printStatus('Performing initial build of the Widget Preview Scaffold...');

    final BuildInfo buildInfo = BuildInfo(
      BuildMode.debug,
      null,
      treeShakeIcons: false,
      packageConfigPath: widgetPreviewScaffoldProject.packageConfig.path,
    );

    if (globals.platform.isMacOS) {
      globals.logger.printStatus('Windows architecture: ${globals.os.hostPlatform}');
      await buildMacOS(
        flutterProject: widgetPreviewScaffoldProject,
        buildInfo: buildInfo,
        verboseLogging: false,
      );
    } else if (globals.platform.isLinux) {
      await buildLinux(
        widgetPreviewScaffoldProject.linux,
        buildInfo,
        targetPlatform:
            globals.os.hostPlatform == HostPlatform.linux_x64
                ? TargetPlatform.linux_x64
                : TargetPlatform.linux_arm64,
        logger: globals.logger,
      );
    } else if (globals.platform.isWindows) {
      print('Windows architecture: ${globals.os.hostPlatform}');
      await buildWindows(
        widgetPreviewScaffoldProject.windows,
        buildInfo,
        globals.os.hostPlatform == HostPlatform.windows_x64
            ? TargetPlatform.windows_x64
            : TargetPlatform.windows_arm64,
      );
    } else {
      throw UnimplementedError();
    }
    globals.logger.printStatus('Widget Preview Scaffold initial build complete.');
  }

  /// Returns the path to a prebuilt widget_preview_scaffold application binary.
  String prebuiltApplicationBinaryPath({required FlutterProject widgetPreviewScaffoldProject}) {
    assert(globals.platform.isLinux || globals.platform.isMacOS || globals.platform.isWindows);
    String path;
    if (globals.platform.isMacOS) {
      path = 'build/macos/Build/Products/Debug/widget_preview_scaffold.app';
    } else if (globals.platform.isLinux) {
      // TODO(bkonyi): verify on Linux
      path = 'build/linux/x64/debug/bundle/widget_preview_scaffold';
    } else if (globals.platform.isWindows) {
      // TODO(bkonyi): verify on Windows
      path = 'build/windows/x64/runner/Debug/widget_preview_scaffold.exe';
    } else {
      throw StateError('Unknown OS');
    }
    path = globals.fs.path.join(widgetPreviewScaffoldProject.directory.path, path);
    if (globals.fs.typeSync(path) == FileSystemEntityType.notFound) {
      globals.logger.printStatus(globals.fs.currentDirectory.toString());
      throw StateError('Could not find prebuilt application binary at $path.');
    }
    return path;
  }

  Future<AppInstance> runPreviewEnvironment({
    required FlutterProject widgetPreviewScaffoldProject,
  }) async {
    final AppInstance app;
    try {
      // Since the only target supported by the widget preview scaffold is the host's desktop
      // device, only a single desktop device should be returned.
      final List<Device> devices = await globals.deviceManager!.getDevices(
        filter: DeviceDiscoveryFilter(
          supportFilter: DeviceDiscoverySupportFilter.excludeDevicesUnsupportedByFlutterOrProject(
            flutterProject: widgetPreviewScaffoldProject,
          ),
          deviceConnectionInterface: DeviceConnectionInterface.attached,
        ),
      );
      assert(devices.length == 1);
      final Device device = devices.first;

      // We launch from a prebuilt widget preview scaffold instance to reduce launch times after
      // the first run.
      final File prebuiltApplicationBinary = globals.fs.file(
        prebuiltApplicationBinaryPath(widgetPreviewScaffoldProject: widgetPreviewScaffoldProject),
      );
      const String? kEmptyRoute = null;
      const bool kEnableHotReload = true;

      app = await Daemon.createMachineDaemon().appDomain.startApp(
        device,
        widgetPreviewScaffoldProject.directory.path,
        bundle.defaultMainPath,
        kEmptyRoute, // route
        DebuggingOptions.enabled(
          BuildInfo(
            BuildMode.debug,
            null,
            treeShakeIcons: false,
            packageConfigPath: widgetPreviewScaffoldProject.packageConfig.path,
          ),
        ),
        kEnableHotReload, // hot mode
        applicationBinary: prebuiltApplicationBinary,
        trackWidgetCreation: false,
        projectRootPath: widgetPreviewScaffoldProject.directory.path,
      );
    } on Exception catch (error) {
      throwToolExit(error.toString());
    }
    // Immediately perform a hot restart to ensure new previews are loaded into the prebuilt
    // application.
    globals.logger.printStatus('Loading previews into the Widget Preview Scaffold...');
    await app.restart(fullRestart: true);
    globals.logger.printStatus('Done loading previews.');
    return app;
  }

  @visibleForTesting
  static const Map<String, String> flutterGenPackageConfigEntry = <String, String>{
    'name': 'flutter_gen',
    'rootUri': '../../flutter_gen',
    'languageVersion': '2.12',
  };

  /// Maps asset URIs to relative paths for the widget preview project to
  /// include.
  @visibleForTesting
  static Uri transformAssetUri(Uri uri) {
    // Assets provided by packages always start with 'packages' and do not
    // require their URIs to be updated.
    if (uri.path.startsWith('packages')) {
      return uri;
    }
    // Otherwise, the asset is contained within the root project and needs
    // to be referenced from the widget preview scaffold project's pubspec.
    return Uri(path: '../../${uri.path}');
  }

  @visibleForTesting
  static AssetsEntry transformAssetsEntry(AssetsEntry asset) {
    return AssetsEntry(
      uri: transformAssetUri(asset.uri),
      flavors: asset.flavors,
      transformers: asset.transformers,
    );
  }

  @visibleForTesting
  static FontAsset transformFontAsset(FontAsset asset) {
    return FontAsset(transformAssetUri(asset.assetUri), weight: asset.weight, style: asset.style);
  }

  @visibleForTesting
  static DeferredComponent transformDeferredComponent(DeferredComponent component) {
    return DeferredComponent(
      name: component.name,
      // TODO(bkonyi): verify these library paths are always package: paths from the parent project.
      libraries: component.libraries,
      assets: component.assets.map(transformAssetsEntry).toList(),
    );
  }

  @visibleForTesting
  FlutterManifest buildPubspec({
    required FlutterManifest rootManifest,
    required FlutterManifest widgetPreviewManifest,
  }) {
    final List<AssetsEntry> assets = rootManifest.assets.map(transformAssetsEntry).toList();

    final List<Font> fonts =
        rootManifest.fonts.map((Font font) {
          return Font(font.familyName, font.fontAssets.map(transformFontAsset).toList());
        }).toList();

    final List<Uri> shaders = rootManifest.shaders.map(transformAssetUri).toList();

    final List<Uri> models = rootManifest.models.map(transformAssetUri).toList();

    final List<DeferredComponent>? deferredComponents =
        rootManifest.deferredComponents?.map(transformDeferredComponent).toList();

    return widgetPreviewManifest.copyWith(
      logger: globals.logger,
      assets: assets,
      fonts: fonts,
      shaders: shaders,
      models: models,
      deferredComponents: deferredComponents,
    );
  }

  Future<void> _populatePreviewPubspec({required FlutterProject rootProject}) async {
    final FlutterProject widgetPreviewScaffoldProject = rootProject.widgetPreviewScaffoldProject;

    // Overwrite the pubspec for the preview scaffold project to include assets
    // from the root project.
    widgetPreviewScaffoldProject.replacePubspec(
      buildPubspec(
        rootManifest: rootProject.manifest,
        widgetPreviewManifest: widgetPreviewScaffoldProject.manifest,
      ),
    );

    // Adds a path dependency on the parent project so previews can be
    // imported directly into the preview scaffold.
    const String pubAdd = 'add';
    await pub.interactively(
      <String>[
        pubAdd,
        '--directory',
        widgetPreviewScaffoldProject.directory.path,
        '${rootProject.manifest.appName}:{"path":${rootProject.directory.path}}',
      ],
      context: PubContext.pubAdd,
      command: pubAdd,
      touchesPackageConfig: true,
    );

    // Generate package_config.json.
    await pub.get(
      context: PubContext.create,
      project: widgetPreviewScaffoldProject,
      offline: offline,
      outputMode: PubOutputMode.summaryOnly,
    );

    maybeAddFlutterGenToPackageConfig(rootProject: rootProject);
  }

  /// Manually adds an entry for package:flutter_gen to the preview scaffold's
  /// package_config.json if the target project makes use of localization.
  ///
  /// The Flutter Tool does this when running a Flutter project with
  /// localization instead of modifying the user's pubspec.yaml to depend on it
  /// as a path dependency. Unfortunately, the preview scaffold still needs to
  /// add it directly to its package_config.json as the generated package name
  /// isn't actually flutter_gen, which pub doesn't really like, and using the
  /// actual package name will break applications which import
  /// package:flutter_gen.
  @visibleForTesting
  void maybeAddFlutterGenToPackageConfig({required FlutterProject rootProject}) {
    // TODO(matanlurey): Remove this once flutter_gen is removed.
    //
    // This is actually incorrect logic; the presence of a `generate: true`
    // does *NOT* mean that we need to add `flutter_gen` to the package config,
    // and never did, but the name of the manifest field was labeled and
    // described incorrectly.
    //
    // Tracking removal: https://github.com/flutter/flutter/issues/102983.
    if (!rootProject.manifest.generateLocalizations) {
      return;
    }
    final FlutterProject widgetPreviewScaffoldProject = rootProject.widgetPreviewScaffoldProject;
    final File packageConfig = widgetPreviewScaffoldProject.packageConfig;
    final String previewPackageConfigPath = packageConfig.path;
    if (!packageConfig.existsSync()) {
      throw StateError(
        "Could not find preview project's package_config.json at "
        '$previewPackageConfigPath',
      );
    }
    final Map<String, Object?> packageConfigJson =
        json.decode(packageConfig.readAsStringSync()) as Map<String, Object?>;
    (packageConfigJson['packages'] as List<dynamic>?)!.cast<Map<String, String>>().add(
      flutterGenPackageConfigEntry,
    );
    packageConfig.writeAsStringSync(json.encode(packageConfigJson));
    globals.logger.printStatus('Added flutter_gen dependency to $previewPackageConfigPath');
  }
}

class WidgetPreviewCleanCommand extends FlutterCommand with WidgetPreviewSubCommandMixin {
  @override
  String get description => 'Cleans up widget preview state.';

  @override
  String get name => 'clean';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Directory widgetPreviewScaffold = getRootProject().widgetPreviewScaffold;
    if (widgetPreviewScaffold.existsSync()) {
      final String scaffoldPath = widgetPreviewScaffold.path;
      globals.logger.printStatus('Deleting widget preview scaffold at $scaffoldPath.');
      widgetPreviewScaffold.deleteSync(recursive: true);
    } else {
      globals.logger.printStatus('Nothing to clean up.');
    }
    return FlutterCommandResult.success();
  }
}
