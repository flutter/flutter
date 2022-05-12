// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import '../src/convert.dart';
import 'android/gradle_utils.dart' as gradle;
import 'base/common.dart';
import 'base/error_handling_io.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/utils.dart';
import 'bundle.dart' as bundle;
import 'cmake_project.dart';
import 'features.dart';
import 'flutter_manifest.dart';
import 'flutter_plugins.dart';
import 'globals.dart' as globals;
import 'platform_plugins.dart';
import 'reporting/reporting.dart';
import 'template.dart';
import 'xcode_project.dart';

export 'cmake_project.dart';
export 'xcode_project.dart';

/// Emum for each officially supported platform.
enum SupportedPlatform {
  android,
  ios,
  linux,
  macos,
  web,
  windows,
  windowsuwp,
  fuchsia,
  root, // Special platform to represent the root project directory
}

class FlutterProjectFactory {
  FlutterProjectFactory({
    required Logger logger,
    required FileSystem fileSystem,
  }) : _logger = logger,
       _fileSystem = fileSystem;

  final Logger _logger;
  final FileSystem _fileSystem;

  @visibleForTesting
  final Map<String, FlutterProject> projects =
      <String, FlutterProject>{};

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  FlutterProject fromDirectory(Directory directory) {
    assert(directory != null);
    return projects.putIfAbsent(directory.path, () {
      final FlutterManifest manifest = FlutterProject._readManifest(
        directory.childFile(bundle.defaultManifestPath).path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      final FlutterManifest exampleManifest = FlutterProject._readManifest(
        FlutterProject._exampleDirectory(directory)
            .childFile(bundle.defaultManifestPath)
            .path,
        logger: _logger,
        fileSystem: _fileSystem,
      );
      return FlutterProject(directory, manifest, exampleManifest);
    });
  }
}

/// Represents the contents of a Flutter project at the specified [directory].
///
/// [FlutterManifest] information is read from `pubspec.yaml` and
/// `example/pubspec.yaml` files on construction of a [FlutterProject] instance.
/// The constructed instance carries an immutable snapshot representation of the
/// presence and content of those files. Accordingly, [FlutterProject] instances
/// should be discarded upon changes to the `pubspec.yaml` files, but can be
/// used across changes to other files, as no other file-level information is
/// cached.
class FlutterProject {
  @visibleForTesting
  FlutterProject(this.directory, this.manifest, this._exampleManifest)
    : assert(directory != null),
      assert(manifest != null),
      assert(_exampleManifest != null);

  /// Returns a [FlutterProject] view of the given directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject fromDirectory(Directory directory) => globals.projectFactory.fromDirectory(directory);

  /// Returns a [FlutterProject] view of the current directory or a ToolExit error,
  /// if `pubspec.yaml` or `example/pubspec.yaml` is invalid.
  static FlutterProject current() => globals.projectFactory.fromDirectory(globals.fs.currentDirectory);

  /// Create a [FlutterProject] and bypass the project caching.
  @visibleForTesting
  static FlutterProject fromDirectoryTest(Directory directory, [Logger? logger]) {
    final FileSystem fileSystem = directory.fileSystem;
    logger ??= BufferLogger.test();
    final FlutterManifest manifest = FlutterProject._readManifest(
      directory.childFile(bundle.defaultManifestPath).path,
      logger: logger,
      fileSystem: fileSystem,
    );
    final FlutterManifest exampleManifest = FlutterProject._readManifest(
      FlutterProject._exampleDirectory(directory)
        .childFile(bundle.defaultManifestPath)
        .path,
      logger: logger,
      fileSystem: fileSystem,
    );
    return FlutterProject(directory, manifest, exampleManifest);
  }

  /// The location of this project.
  final Directory directory;

  /// The manifest of this project.
  final FlutterManifest manifest;

  /// The manifest of the example sub-project of this project.
  final FlutterManifest _exampleManifest;

  /// The set of organization names found in this project as
  /// part of iOS product bundle identifier, Android application ID, or
  /// Gradle group ID.
  Future<Set<String>> get organizationNames async {
    final List<String> candidates = <String>[];

    if (ios.existsSync()) {
      // Don't require iOS build info, this method is only
      // used during create as best-effort, use the
      // default target bundle identifier.
      final String? bundleIdentifier = await ios.productBundleIdentifier(null);
      if (bundleIdentifier != null) {
        candidates.add(bundleIdentifier);
      }
    }
    if (android.existsSync()) {
      final String? applicationId = android.applicationId;
      final String? group = android.group;
      candidates.addAll(<String>[
        if (applicationId != null)
          applicationId,
        if (group != null)
          group,
      ]);
    }
    if (example.android.existsSync()) {
      final String? applicationId = example.android.applicationId;
      if (applicationId != null) {
        candidates.add(applicationId);
      }
    }
    if (example.ios.existsSync()) {
      final String? bundleIdentifier = await example.ios.productBundleIdentifier(null);
      if (bundleIdentifier != null) {
        candidates.add(bundleIdentifier);
      }
    }
    return Set<String>.of(candidates.map<String?>(_organizationNameFromPackageName).whereType<String>());
  }

  String? _organizationNameFromPackageName(String packageName) {
    if (packageName != null && 0 <= packageName.lastIndexOf('.')) {
      return packageName.substring(0, packageName.lastIndexOf('.'));
    }
    return null;
  }

  /// The iOS sub project of this project.
  late final IosProject ios = IosProject.fromFlutter(this);

  /// The Android sub project of this project.
  late final AndroidProject android = AndroidProject._(this);

  /// The web sub project of this project.
  late final WebProject web = WebProject._(this);

  /// The MacOS sub project of this project.
  late final MacOSProject macos = MacOSProject.fromFlutter(this);

  /// The Linux sub project of this project.
  late final LinuxProject linux = LinuxProject.fromFlutter(this);

  /// The Windows sub project of this project.
  late final WindowsProject windows = WindowsProject.fromFlutter(this);

  /// The Windows UWP sub project of this project.
  late final WindowsUwpProject windowsUwp = WindowsUwpProject.fromFlutter(this);

  /// The Fuchsia sub project of this project.
  late final FuchsiaProject fuchsia = FuchsiaProject._(this);

  /// The `pubspec.yaml` file of this project.
  File get pubspecFile => directory.childFile('pubspec.yaml');

  /// The `.packages` file of this project.
  File get packagesFile => directory.childFile('.packages');

  /// The `package_config.json` file of the project.
  ///
  /// This is the replacement for .packages which contains language
  /// version information.
  File get packageConfigFile => directory.childDirectory('.dart_tool').childFile('package_config.json');

  /// The `.metadata` file of this project.
  File get metadataFile => directory.childFile('.metadata');

  /// The `.flutter-plugins` file of this project.
  File get flutterPluginsFile => directory.childFile('.flutter-plugins');

  /// The `.flutter-plugins-dependencies` file of this project,
  /// which contains the dependencies each plugin depends on.
  File get flutterPluginsDependenciesFile => directory.childFile('.flutter-plugins-dependencies');

  /// The `.dart-tool` directory of this project.
  Directory get dartTool => directory.childDirectory('.dart_tool');

  /// The directory containing the generated code for this project.
  Directory get generated => directory
    .absolute
    .childDirectory('.dart_tool')
    .childDirectory('build')
    .childDirectory('generated')
    .childDirectory(manifest.appName);

  /// The generated Dart plugin registrant for non-web platforms.
  File get dartPluginRegistrant => dartTool
    .childDirectory('flutter_build')
    .childFile('dart_plugin_registrant.dart');

  /// The example sub-project of this project.
  FlutterProject get example => FlutterProject(
    _exampleDirectory(directory),
    _exampleManifest,
    FlutterManifest.empty(logger: globals.logger),
  );

  /// True if this project is a Flutter module project.
  bool get isModule => manifest.isModule;

  /// True if this project is a Flutter plugin project.
  bool get isPlugin => manifest.isPlugin;

  /// True if the Flutter project is using the AndroidX support library.
  bool get usesAndroidX => manifest.usesAndroidX;

  /// True if this project has an example application.
  bool get hasExampleApp => _exampleDirectory(directory).existsSync();

  /// Returns a list of platform names that are supported by the project.
  List<SupportedPlatform> getSupportedPlatforms({bool includeRoot = false}) {
    final List<SupportedPlatform> platforms = includeRoot ? <SupportedPlatform>[SupportedPlatform.root] : <SupportedPlatform>[];
    if (android.existsSync()) {
      platforms.add(SupportedPlatform.android);
    }
    if (ios.exists) {
      platforms.add(SupportedPlatform.ios);
    }
    if (web.existsSync()) {
      platforms.add(SupportedPlatform.web);
    }
    if (macos.existsSync()) {
      platforms.add(SupportedPlatform.macos);
    }
    if (linux.existsSync()) {
      platforms.add(SupportedPlatform.linux);
    }
    if (windows.existsSync()) {
      platforms.add(SupportedPlatform.windows);
    }
    if (windowsUwp.existsSync()) {
      platforms.add(SupportedPlatform.windowsuwp);
    }
    if (fuchsia.existsSync()) {
      platforms.add(SupportedPlatform.fuchsia);
    }
    return platforms;
  }

  /// The directory that will contain the example if an example exists.
  static Directory _exampleDirectory(Directory directory) => directory.childDirectory('example');

  /// Reads and validates the `pubspec.yaml` file at [path], asynchronously
  /// returning a [FlutterManifest] representation of the contents.
  ///
  /// Completes with an empty [FlutterManifest], if the file does not exist.
  /// Completes with a ToolExit on validation error.
  static FlutterManifest _readManifest(String path, {
    required Logger logger,
    required FileSystem fileSystem,
  }) {
    FlutterManifest? manifest;
    try {
      manifest = FlutterManifest.createFromPath(
        path,
        logger: logger,
        fileSystem: fileSystem,
      );
    } on YamlException catch (e) {
      logger.printStatus('Error detected in pubspec.yaml:', emphasis: true);
      logger.printError('$e');
    } on FormatException catch (e) {
      logger.printError('Error detected while parsing pubspec.yaml:', emphasis: true);
      logger.printError('$e');
    } on FileSystemException catch (e) {
      logger.printError('Error detected while reading pubspec.yaml:', emphasis: true);
      logger.printError('$e');
    }
    if (manifest == null) {
      throwToolExit('Please correct the pubspec.yaml file at $path');
    }
    return manifest;
  }

  /// Reapplies template files and regenerates project files and plugin
  /// registrants for app and module projects only.
  ///
  /// Will not create project platform directories if they do not already exist.
  Future<void> regeneratePlatformSpecificTooling({DeprecationBehavior deprecationBehavior = DeprecationBehavior.none}) async {
    return ensureReadyForPlatformSpecificTooling(
      androidPlatform: android.existsSync(),
      iosPlatform: ios.existsSync(),
      // TODO(stuartmorgan): Revisit the conditions here once the plans for handling
      // desktop in existing projects are in place.
      linuxPlatform: featureFlags.isLinuxEnabled && linux.existsSync(),
      macOSPlatform: featureFlags.isMacOSEnabled && macos.existsSync(),
      windowsPlatform: featureFlags.isWindowsEnabled && windows.existsSync(),
      webPlatform: featureFlags.isWebEnabled && web.existsSync(),
      winUwpPlatform: featureFlags.isWindowsUwpEnabled && windowsUwp.existsSync(),
      deprecationBehavior: deprecationBehavior,
    );
  }

  /// Applies template files and generates project files and plugin
  /// registrants for app and module projects only for the specified platforms.
  Future<void> ensureReadyForPlatformSpecificTooling({
    bool androidPlatform = false,
    bool iosPlatform = false,
    bool linuxPlatform = false,
    bool macOSPlatform = false,
    bool windowsPlatform = false,
    bool webPlatform = false,
    bool winUwpPlatform = false,
    DeprecationBehavior deprecationBehavior = DeprecationBehavior.none,
  }) async {
    if (!directory.existsSync() || isPlugin) {
      return;
    }
    await refreshPluginsList(this, iosPlatform: iosPlatform, macOSPlatform: macOSPlatform);
    if (androidPlatform) {
      await android.ensureReadyForPlatformSpecificTooling(deprecationBehavior: deprecationBehavior);
    }
    if (iosPlatform) {
      await ios.ensureReadyForPlatformSpecificTooling();
    }
    if (linuxPlatform) {
      await linux.ensureReadyForPlatformSpecificTooling();
    }
    if (macOSPlatform) {
      await macos.ensureReadyForPlatformSpecificTooling();
    }
    if (windowsPlatform) {
      await windows.ensureReadyForPlatformSpecificTooling();
    }
    if (webPlatform) {
      await web.ensureReadyForPlatformSpecificTooling();
    }
    if (winUwpPlatform) {
      await windowsUwp.ensureReadyForPlatformSpecificTooling();
    }
    await injectPlugins(
      this,
      androidPlatform: androidPlatform,
      iosPlatform: iosPlatform,
      linuxPlatform: linuxPlatform,
      macOSPlatform: macOSPlatform,
      windowsPlatform: windowsPlatform,
      webPlatform: webPlatform,
      winUwpPlatform: winUwpPlatform,
    );
  }

  void checkForDeprecation({DeprecationBehavior deprecationBehavior = DeprecationBehavior.none}) {
    if (android.existsSync()) {
      android.checkForDeprecation(deprecationBehavior: deprecationBehavior);
    }
  }

  /// Returns a json encoded string containing the [appName], [version], and [buildNumber] that is used to generate version.json
  String getVersionInfo()  {
    final String? buildName = manifest.buildName;
    final String? buildNumber = manifest.buildNumber;
    final Map<String, String> versionFileJson = <String, String>{
      'app_name': manifest.appName,
      if (buildName != null)
        'version': buildName,
      if (buildNumber != null)
        'build_number': buildNumber,
      'package_name': manifest.appName,
    };
    return jsonEncode(versionFileJson);
  }
}

/// Base class for projects per platform.
abstract class FlutterProjectPlatform {

  /// Plugin's platform config key, e.g., "macos", "ios".
  String get pluginConfigKey;

  /// Whether the platform exists in the project.
  bool existsSync();
}

/// Represents the Android sub-project of a Flutter project.
///
/// Instances will reflect the contents of the `android/` sub-folder of
/// Flutter applications and the `.android/` sub-folder of Flutter module projects.
class AndroidProject extends FlutterProjectPlatform {
  AndroidProject._(this.parent);

  /// The parent of this project.
  final FlutterProject parent;

  @override
  String get pluginConfigKey => AndroidPlugin.kConfigKey;

  static final RegExp _applicationIdPattern = RegExp('^\\s*applicationId\\s+[\'"](.*)[\'"]\\s*\$');
  static final RegExp _kotlinPluginPattern = RegExp('^\\s*apply plugin\\:\\s+[\'"]kotlin-android[\'"]\\s*\$');
  static final RegExp _groupPattern = RegExp('^\\s*group\\s+[\'"](.*)[\'"]\\s*\$');

  /// The Gradle root directory of the Android host app. This is the directory
  /// containing the `app/` subdirectory and the `settings.gradle` file that
  /// includes it in the overall Gradle project.
  Directory get hostAppGradleRoot {
    if (!isModule || _editableHostAppDirectory.existsSync()) {
      return _editableHostAppDirectory;
    }
    return ephemeralDirectory;
  }

  /// The Gradle root directory of the Android wrapping of Flutter and plugins.
  /// This is the same as [hostAppGradleRoot] except when the project is
  /// a Flutter module with an editable host app.
  Directory get _flutterLibGradleRoot => isModule ? ephemeralDirectory : _editableHostAppDirectory;

  Directory get ephemeralDirectory => parent.directory.childDirectory('.android');
  Directory get _editableHostAppDirectory => parent.directory.childDirectory('android');

  /// True if the parent Flutter project is a module.
  bool get isModule => parent.isModule;

  /// True if the parent Flutter project is a plugin.
  bool get isPlugin => parent.isPlugin;

  /// True if the Flutter project is using the AndroidX support library.
  bool get usesAndroidX => parent.usesAndroidX;

  /// Returns true if the current version of the Gradle plugin is supported.
  late final bool isSupportedVersion = _computeSupportedVersion();

  bool _computeSupportedVersion() {
    final FileSystem fileSystem = hostAppGradleRoot.fileSystem;
    final File plugin = hostAppGradleRoot.childFile(
        fileSystem.path.join('buildSrc', 'src', 'main', 'groovy', 'FlutterPlugin.groovy'));
    if (plugin.existsSync()) {
      return false;
    }
    final File appGradle = hostAppGradleRoot.childFile(
        fileSystem.path.join('app', 'build.gradle'));
    if (!appGradle.existsSync()) {
      return false;
    }
    for (final String line in appGradle.readAsLinesSync()) {
      if (line.contains(RegExp(r'apply from: .*/flutter.gradle')) ||
          line.contains("def flutterPluginVersion = 'managed'")) {
        return true;
      }
    }
    return false;
  }

  /// True, if the app project is using Kotlin.
  bool get isKotlin {
    final File gradleFile = hostAppGradleRoot.childDirectory('app').childFile('build.gradle');
    return firstMatchInFile(gradleFile, _kotlinPluginPattern) != null;
  }

  File get appManifestFile {
    return isUsingGradle
        ? globals.fs.file(globals.fs.path.join(hostAppGradleRoot.path, 'app', 'src', 'main', 'AndroidManifest.xml'))
        : hostAppGradleRoot.childFile('AndroidManifest.xml');
  }

  File get gradleAppOutV1File => gradleAppOutV1Directory.childFile('app-debug.apk');

  Directory get gradleAppOutV1Directory {
    return globals.fs.directory(globals.fs.path.join(hostAppGradleRoot.path, 'app', 'build', 'outputs', 'apk'));
  }

  /// Whether the current flutter project has an Android sub-project.
  @override
  bool existsSync() {
    return parent.isModule || _editableHostAppDirectory.existsSync();
  }

  bool get isUsingGradle {
    return hostAppGradleRoot.childFile('build.gradle').existsSync();
  }

  String? get applicationId {
    final File gradleFile = hostAppGradleRoot.childDirectory('app').childFile('build.gradle');
    return firstMatchInFile(gradleFile, _applicationIdPattern)?.group(1);
  }

  String? get group {
    final File gradleFile = hostAppGradleRoot.childFile('build.gradle');
    return firstMatchInFile(gradleFile, _groupPattern)?.group(1);
  }

  /// The build directory where the Android artifacts are placed.
  Directory get buildDirectory {
    return parent.directory.childDirectory('build');
  }

  Future<void> ensureReadyForPlatformSpecificTooling({DeprecationBehavior deprecationBehavior = DeprecationBehavior.none}) async {
    if (isModule && _shouldRegenerateFromTemplate()) {
      await _regenerateLibrary();
      // Add ephemeral host app, if an editable host app does not already exist.
      if (!_editableHostAppDirectory.existsSync()) {
        await _overwriteFromTemplate(globals.fs.path.join('module', 'android', 'host_app_common'), ephemeralDirectory);
        await _overwriteFromTemplate(globals.fs.path.join('module', 'android', 'host_app_ephemeral'), ephemeralDirectory);
      }
    }
    if (!hostAppGradleRoot.existsSync()) {
      return;
    }
    gradle.updateLocalProperties(project: parent, requireAndroidSdk: false);
  }

  bool _shouldRegenerateFromTemplate() {
    return globals.fsUtils.isOlderThanReference(
      entity: ephemeralDirectory,
      referenceFile: parent.pubspecFile,
    ) || globals.cache.isOlderThanToolsStamp(ephemeralDirectory);
  }

  File get localPropertiesFile => _flutterLibGradleRoot.childFile('local.properties');

  Directory get pluginRegistrantHost => _flutterLibGradleRoot.childDirectory(isModule ? 'Flutter' : 'app');

  Future<void> _regenerateLibrary() async {
    ErrorHandlingFileSystem.deleteIfExists(ephemeralDirectory, recursive: true);
    await _overwriteFromTemplate(globals.fs.path.join(
      'module',
      'android',
      'library_new_embedding',
    ), ephemeralDirectory);
    await _overwriteFromTemplate(globals.fs.path.join('module', 'android', 'gradle'), ephemeralDirectory);
    globals.gradleUtils?.injectGradleWrapperIfNeeded(ephemeralDirectory);
  }

  Future<void> _overwriteFromTemplate(String path, Directory target) async {
    final Template template = await Template.fromName(
      path,
      fileSystem: globals.fs,
      templateManifest: null,
      logger: globals.logger,
      templateRenderer: globals.templateRenderer,
    );
    final String androidIdentifier = parent.manifest.androidPackage ?? 'com.example.${parent.manifest.appName}';
    template.render(
      target,
      <String, Object>{
        'android': true,
        'projectName': parent.manifest.appName,
        'androidIdentifier': androidIdentifier,
        'androidX': usesAndroidX,
        'agpVersion': gradle.templateAndroidGradlePluginVersion,
        'agpVersionForModule': gradle.templateAndroidGradlePluginVersionForModule,
        'kotlinVersion': gradle.templateKotlinGradlePluginVersion,
        'gradleVersion': gradle.templateDefaultGradleVersion,
      },
      printStatusWhenWriting: false,
    );
  }

  void checkForDeprecation({DeprecationBehavior deprecationBehavior = DeprecationBehavior.none}) {
    if (deprecationBehavior == DeprecationBehavior.none) {
      return;
    }
    final AndroidEmbeddingVersionResult result = computeEmbeddingVersion();
    if (result.version != AndroidEmbeddingVersion.v1) {
      return;
    }
    globals.printStatus(
'''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Warning
──────────────────────────────────────────────────────────────────────────────
Your Flutter application is created using an older version of the Android
embedding. It is being deprecated in favor of Android embedding v2. Follow the
steps at

https://flutter.dev/go/android-project-migration

to migrate your project. You may also pass the --ignore-deprecation flag to
ignore this check and continue with the deprecated v1 embedding. However,
the v1 Android embedding will be removed in future versions of Flutter.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
The detected reason was:

  ${result.reason}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
    if (deprecationBehavior == DeprecationBehavior.ignore) {
      BuildEvent('deprecated-v1-android-embedding-ignored', type: 'gradle', flutterUsage: globals.flutterUsage).send();
    } else { // DeprecationBehavior.exit
      BuildEvent('deprecated-v1-android-embedding-failed', type: 'gradle', flutterUsage: globals.flutterUsage).send();
      throwToolExit(
        'Build failed due to use of deprecated Android v1 embedding.',
        exitCode: 1,
      );
    }
  }

  AndroidEmbeddingVersion getEmbeddingVersion() {
    return computeEmbeddingVersion().version;
  }

  AndroidEmbeddingVersionResult computeEmbeddingVersion() {
    if (isModule) {
      // A module type's Android project is used in add-to-app scenarios and
      // only supports the V2 embedding.
      return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v2, 'Is add-to-app module');
    }
    if (isPlugin) {
      // Plugins do not use an appManifest, so we stop here.
      //
      // TODO(garyq): This method does not currently check for code references to
      // the v1 embedding, we should check for this once removal is further along.
      return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v2, 'Is plugin');
    }
    if (appManifestFile == null || !appManifestFile.existsSync()) {
      return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v1, 'No `${appManifestFile.absolute.path}` file');
    }
    XmlDocument document;
    try {
      document = XmlDocument.parse(appManifestFile.readAsStringSync());
    } on XmlParserException {
      throwToolExit('Error parsing $appManifestFile '
                    'Please ensure that the android manifest is a valid XML document and try again.');
    } on FileSystemException {
      throwToolExit('Error reading $appManifestFile even though it exists. '
                    'Please ensure that you have read permission to this file and try again.');
    }
    for (final XmlElement application in document.findAllElements('application')) {
      final String? applicationName = application.getAttribute('android:name');
      if (applicationName == 'io.flutter.app.FlutterApplication') {
        return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v1, '${appManifestFile.absolute.path} uses `android:name="io.flutter.app.FlutterApplication"`');
      }
    }
    for (final XmlElement metaData in document.findAllElements('meta-data')) {
      final String? name = metaData.getAttribute('android:name');
      if (name == 'flutterEmbedding') {
        final String? embeddingVersionString = metaData.getAttribute('android:value');
        if (embeddingVersionString == '1') {
          return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v1, '${appManifestFile.absolute.path} `<meta-data android:name="flutterEmbedding"` has value 1');
        }
        if (embeddingVersionString == '2') {
          return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v2, '${appManifestFile.absolute.path} `<meta-data android:name="flutterEmbedding"` has value 2');
        }
      }
    }
    return AndroidEmbeddingVersionResult(AndroidEmbeddingVersion.v1, 'No `<meta-data android:name="flutterEmbedding" android:value="2"/>` in ${appManifestFile.absolute.path}');
  }
}

/// Iteration of the embedding Java API in the engine used by the Android project.
enum AndroidEmbeddingVersion {
  /// V1 APIs based on io.flutter.app.FlutterActivity.
  v1,
  /// V2 APIs based on io.flutter.embedding.android.FlutterActivity.
  v2,
}

/// Data class that holds the results of checking for embedding version.
///
/// This class includes the reason why a particular embedding was selected.
class AndroidEmbeddingVersionResult {
  AndroidEmbeddingVersionResult(this.version, this.reason);

  /// The embedding version.
  AndroidEmbeddingVersion version;

  /// The reason why the embedding version was selected.
  String reason;
}

// What the tool should do when encountering deprecated API in applications.
enum DeprecationBehavior {
  // The command being run does not care about deprecation status.
  none,
  // The command should continue and ignore the deprecation warning.
  ignore,
  // The command should exit the tool.
  exit,
}

/// Represents the web sub-project of a Flutter project.
class WebProject extends FlutterProjectPlatform {
  WebProject._(this.parent);

  final FlutterProject parent;

  @override
  String get pluginConfigKey => WebPlugin.kConfigKey;

  /// Whether this flutter project has a web sub-project.
  @override
  bool existsSync() {
    return parent.directory.childDirectory('web').existsSync()
      && indexFile.existsSync();
  }

  /// The 'lib' directory for the application.
  Directory get libDirectory => parent.directory.childDirectory('lib');

  /// The directory containing additional files for the application.
  Directory get directory => parent.directory.childDirectory('web');

  /// The html file used to host the flutter web application.
  File get indexFile => parent.directory
      .childDirectory('web')
      .childFile('index.html');

  Future<void> ensureReadyForPlatformSpecificTooling() async {}
}

/// The Fuchsia sub project.
class FuchsiaProject {
  FuchsiaProject._(this.project);

  final FlutterProject project;

  Directory? _editableHostAppDirectory;
  Directory get editableHostAppDirectory =>
      _editableHostAppDirectory ??= project.directory.childDirectory('fuchsia');

  bool existsSync() => editableHostAppDirectory.existsSync();

  Directory? _meta;
  Directory get meta =>
      _meta ??= editableHostAppDirectory.childDirectory('meta');
}
