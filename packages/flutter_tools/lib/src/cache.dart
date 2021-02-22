// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:file/memory.dart';
import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import 'android/android_studio.dart';
import 'base/common.dart';
import 'base/error_handling_io.dart';
import 'base/file_system.dart';
import 'base/io.dart' show HttpClient, HttpClientRequest, HttpClientResponse, HttpHeaders, HttpStatus, SocketException;
import 'base/logger.dart';
import 'base/net.dart';
import 'base/os.dart' show OperatingSystemUtils;
import 'base/platform.dart';
import 'base/process.dart';
import 'base/user_messages.dart';
import 'build_info.dart';
import 'convert.dart';
import 'dart/package_map.dart';
import 'dart/pub.dart';
import 'features.dart';
import 'globals.dart' as globals;
import 'runner/flutter_command.dart';
import 'runner/flutter_command_runner.dart';

/// A tag for a set of development artifacts that need to be cached.
class DevelopmentArtifact {

  const DevelopmentArtifact._(this.name, {this.feature});

  /// The name of the artifact.
  ///
  /// This should match the flag name in precache.dart.
  final String name;

  /// A feature to control the visibility of this artifact.
  final Feature feature;

  /// Artifacts required for Android development.
  static const DevelopmentArtifact androidGenSnapshot = DevelopmentArtifact._('android_gen_snapshot', feature: flutterAndroidFeature);
  static const DevelopmentArtifact androidMaven = DevelopmentArtifact._('android_maven', feature: flutterAndroidFeature);

  // Artifacts used for internal builds.
  static const DevelopmentArtifact androidInternalBuild = DevelopmentArtifact._('android_internal_build', feature: flutterAndroidFeature);

  /// Artifacts required for iOS development.
  static const DevelopmentArtifact iOS = DevelopmentArtifact._('ios', feature: flutterIOSFeature);

  /// Artifacts required for web development.
  static const DevelopmentArtifact web = DevelopmentArtifact._('web', feature: flutterWebFeature);

  /// Artifacts required for desktop macOS.
  static const DevelopmentArtifact macOS = DevelopmentArtifact._('macos', feature: flutterMacOSDesktopFeature);

  /// Artifacts required for desktop Windows.
  static const DevelopmentArtifact windows = DevelopmentArtifact._('windows', feature: flutterWindowsDesktopFeature);

  /// Artifacts required for desktop Linux.
  static const DevelopmentArtifact linux = DevelopmentArtifact._('linux', feature: flutterLinuxDesktopFeature);

  /// Artifacts required for Fuchsia.
  static const DevelopmentArtifact fuchsia = DevelopmentArtifact._('fuchsia', feature: flutterFuchsiaFeature);

  /// Artifacts required for the Flutter Runner.
  static const DevelopmentArtifact flutterRunner = DevelopmentArtifact._('flutter_runner', feature: flutterFuchsiaFeature);

  /// Artifacts required for any development platform.
  ///
  /// This does not need to be explicitly returned from requiredArtifacts as
  /// it will always be downloaded.
  static const DevelopmentArtifact universal = DevelopmentArtifact._('universal');

  /// The values of DevelopmentArtifacts.
  static final List<DevelopmentArtifact> values = <DevelopmentArtifact>[
    androidGenSnapshot,
    androidMaven,
    androidInternalBuild,
    iOS,
    web,
    macOS,
    windows,
    linux,
    fuchsia,
    universal,
    flutterRunner,
  ];

  @override
  String toString() => 'Artifact($name)';
}

/// A wrapper around the `bin/cache/` directory.
class Cache {
  /// [rootOverride] is configurable for testing.
  /// [artifacts] is configurable for testing.
  Cache({
    @protected Directory rootOverride,
    @protected List<ArtifactSet> artifacts,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Platform platform,
    @required OperatingSystemUtils osUtils,
  }) : _rootOverride = rootOverride,
       _logger = logger,
       _fileSystem = fileSystem,
       _platform = platform,
       _osUtils = osUtils,
      _net = Net(logger: logger, platform: platform),
      _fsUtils = FileSystemUtils(fileSystem: fileSystem, platform: platform) {
    if (artifacts == null) {
      _artifacts.add(MaterialFonts(this));
      _artifacts.add(GradleWrapper(this));
      _artifacts.add(AndroidGenSnapshotArtifacts(this, platform: _platform));
      _artifacts.add(AndroidInternalBuildArtifacts(this));
      _artifacts.add(IOSEngineArtifacts(this, platform: _platform));
      _artifacts.add(FlutterWebSdk(this, platform: _platform));
      _artifacts.add(FlutterSdk(this, platform: _platform));
      _artifacts.add(WindowsEngineArtifacts(this, platform: _platform));
      _artifacts.add(MacOSEngineArtifacts(this, platform: _platform));
      _artifacts.add(LinuxEngineArtifacts(this, platform: _platform));
      _artifacts.add(LinuxFuchsiaSDKArtifacts(this, platform: _platform));
      _artifacts.add(MacOSFuchsiaSDKArtifacts(this, platform: _platform));
      _artifacts.add(FlutterRunnerSDKArtifacts(this, platform: _platform));
      _artifacts.add(FlutterRunnerDebugSymbols(this, platform: _platform));
      for (final String artifactName in IosUsbArtifacts.artifactNames) {
        _artifacts.add(IosUsbArtifacts(artifactName, this, platform: _platform));
      }
      _artifacts.add(FontSubsetArtifacts(this, platform: _platform));
      _artifacts.add(PubDependencies(
        logger: _logger,
        // flutter root and pub must be lazily initialized to avoid accessing
        // before the version is determined.
        flutterRoot: () => flutterRoot,
        pub: () => pub,
      ));
    } else {
      _artifacts.addAll(artifacts);
    }
  }

  /// Create a [Cache] for testing.
  ///
  /// Defaults to a memory file system, fake platform,
  /// buffer logger, and no accessible artifacts.
  /// By default, the root cache directory path is "cache".
  @visibleForTesting
  factory Cache.test({
    Directory rootOverride,
    List<ArtifactSet> artifacts,
    Logger logger,
    FileSystem fileSystem,
    Platform platform,
    ProcessManager processManager,
  }) {
    fileSystem ??= rootOverride?.fileSystem ?? MemoryFileSystem.test();
    platform ??= FakePlatform(environment: <String, String>{});
    logger ??= BufferLogger.test();
    return Cache(
      rootOverride: rootOverride ??= fileSystem.directory('cache'),
      artifacts: artifacts ?? <ArtifactSet>[],
      logger: logger,
      fileSystem: fileSystem,
      platform: platform,
      osUtils: OperatingSystemUtils(
        fileSystem: fileSystem,
        logger: logger,
        platform: platform,
        processManager: processManager,
      ),
    );
  }

  final Logger _logger;
  final Platform _platform;
  final FileSystem _fileSystem;
  final OperatingSystemUtils _osUtils;

  ArtifactUpdater get _artifactUpdater => __artifactUpdater ??= _createUpdater();
  ArtifactUpdater __artifactUpdater;

  /// This has to be lazy because it requires FLUTTER_ROOT to be initialized.
  ArtifactUpdater _createUpdater() {
    return ArtifactUpdater(
      operatingSystemUtils: _osUtils,
      logger: _logger,
      fileSystem: _fileSystem,
      tempStorage: getDownloadDir(),
      platform: _platform,
      httpClient: HttpClient(),
    );
  }

  Net _net;
  FileSystemUtils _fsUtils;

  static const List<String> _hostsBlockedInChina = <String> [
    'storage.googleapis.com',
  ];

  final Directory _rootOverride;
  final List<ArtifactSet> _artifacts = <ArtifactSet>[];

  // Initialized by FlutterCommandRunner on startup.
  static String flutterRoot;

  /// Determine the absolute and normalized path for the root of the current
  /// Flutter checkout.
  ///
  /// This method has a series of fallbacks for determining the repo location. The
  /// first success will immediately return the root without further checks.
  ///
  /// The order of these tests is:
  ///   1. FLUTTER_ROOT environment variable contains the path.
  ///   2. Platform script is a data URI scheme, returning `../..` to support
  ///      tests run from `packages/flutter_tools`.
  ///   3. Platform script is package URI scheme, returning the grandparent directory
  ///      of the package config file location from `packages/flutter_tools/.packages`.
  ///   4. Platform script file path is the snapshot path generated by `bin/flutter`,
  ///      returning the grandparent directory from `bin/cache`.
  ///   5. Platform script file name is the entrypoint in `packages/flutter_tools/bin/flutter_tools.dart`,
  ///      returning the 4th parent directory.
  ///   6. The current directory
  ///
  /// If an exception is thrown during any of these checks, an error message is
  /// printed and `.` is returned by default (6).
  static String defaultFlutterRoot({
    @required Platform platform,
    @required FileSystem fileSystem,
    @required UserMessages userMessages,
  }) {
    String normalize(String path) {
      return fileSystem.path.normalize(fileSystem.path.absolute(path));
    }
    if (platform.environment.containsKey(kFlutterRootEnvironmentVariableName)) {
      return normalize(platform.environment[kFlutterRootEnvironmentVariableName]);
    }
    try {
      if (platform.script.scheme == 'data') {
        return normalize('../..'); // The tool is running as a test.
      }
      final String Function(String) dirname = fileSystem.path.dirname;

      if (platform.script.scheme == 'package') {
        final String packageConfigPath = Uri.parse(platform.packageConfig).toFilePath(
          windows: platform.isWindows,
        );
        return normalize(dirname(dirname(dirname(packageConfigPath))));
      }

      if (platform.script.scheme == 'file') {
        final String script = platform.script.toFilePath(
          windows: platform.isWindows,
        );
        if (fileSystem.path.basename(script) == kSnapshotFileName) {
          return normalize(dirname(dirname(fileSystem.path.dirname(script))));
        }
        if (fileSystem.path.basename(script) == kFlutterToolsScriptFileName) {
          return normalize(dirname(dirname(dirname(dirname(script)))));
        }
      }
    } on Exception catch (error) {
      // There is currently no logger attached since this is computed at startup.
      print(userMessages.runnerNoRoot('$error'));
    }
    return normalize('.');
  }

  // Whether to cache artifacts for all platforms. Defaults to only caching
  // artifacts for the current platform.
  bool includeAllPlatforms = false;

  // Names of artifacts which should be cached even if they would normally
  // be filtered out for the current platform.
  Set<String> platformOverrideArtifacts;

  // Whether to cache the unsigned mac binaries. Defaults to caching the signed binaries.
  bool useUnsignedMacBinaries = false;

  static RandomAccessFile _lock;
  static bool _lockEnabled = true;

  /// Turn off the [lock]/[releaseLock] mechanism.
  ///
  /// This is used by the tests since they run simultaneously and all in one
  /// process and so it would be a mess if they had to use the lock.
  @visibleForTesting
  static void disableLocking() {
    _lockEnabled = false;
  }

  /// Turn on the [lock]/[releaseLock] mechanism.
  ///
  /// This is used by the tests.
  @visibleForTesting
  static void enableLocking() {
    _lockEnabled = true;
  }

  /// Check if lock acquired, skipping FLUTTER_ALREADY_LOCKED reentrant checks.
  ///
  /// This is used by the tests.
  @visibleForTesting
  static bool isLocked() {
    return _lock != null;
  }

  /// Lock the cache directory.
  ///
  /// This happens while required artifacts are updated
  /// (see [FlutterCommandRunner.runCommand]).
  ///
  /// This uses normal POSIX flock semantics.
  Future<void> lock() async {
    if (!_lockEnabled) {
      return;
    }
    assert(_lock == null);
    final File lockFile =
      _fileSystem.file(_fileSystem.path.join(flutterRoot, 'bin', 'cache', 'lockfile'));
    try {
      _lock = lockFile.openSync(mode: FileMode.write);
    } on FileSystemException catch (e) {
      _logger.printError('Failed to open or create the artifact cache lockfile: "$e"');
      _logger.printError('Please ensure you have permissions to create or open ${lockFile.path}');
      throwToolExit('Failed to open or create the lockfile');
    }
    bool locked = false;
    bool printed = false;
    while (!locked) {
      try {
        _lock.lockSync();
        locked = true;
      } on FileSystemException {
        if (!printed) {
          _logger.printTrace('Waiting to be able to obtain lock of Flutter binary artifacts directory: ${_lock.path}');
          _logger.printStatus('Waiting for another flutter command to release the startup lock...');
          printed = true;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  /// Releases the lock.
  ///
  /// This happens automatically on startup (see [FlutterCommand.verifyThenRunCommand])
  /// after the command's required artifacts are updated.
  void releaseLock() {
    if (!_lockEnabled || _lock == null) {
      return;
    }
    _lock.closeSync();
    _lock = null;
  }

  /// Checks if the current process owns the lock for the cache directory at
  /// this very moment; throws a [StateError] if it doesn't.
  void checkLockAcquired() {
    if (_lockEnabled && _lock == null && _platform.environment['FLUTTER_ALREADY_LOCKED'] != 'true') {
      throw StateError(
        'The current process does not own the lock for the cache directory. This is a bug in Flutter CLI tools.',
      );
    }
  }

  /// The current version of Dart used to build Flutter and run the tool.
  String get dartSdkVersion {
    if (_dartSdkVersion == null) {
      // Make the version string more customer-friendly.
      // Changes '2.1.0-dev.8.0.flutter-4312ae32' to '2.1.0 (build 2.1.0-dev.8.0 4312ae32)'
      final String justVersion = _platform.version.split(' ')[0];
      _dartSdkVersion = justVersion.replaceFirstMapped(RegExp(r'(\d+\.\d+\.\d+)(.+)'), (Match match) {
        final String noFlutter = match[2].replaceAll('.flutter-', ' ');
        return '${match[1]} (build ${match[1]}$noFlutter)';
      });
    }
    return _dartSdkVersion;
  }
  String _dartSdkVersion;

  /// The current version of the Flutter engine the flutter tool will download.
  String get engineRevision {
    _engineRevision ??= getVersionFor('engine');
    return _engineRevision;
  }
  String _engineRevision;

  String get storageBaseUrl {
    final String overrideUrl = _platform.environment['FLUTTER_STORAGE_BASE_URL'];
    if (overrideUrl == null) {
      return 'https://storage.googleapis.com';
    }
    // verify that this is a valid URI.
    try {
      Uri.parse(overrideUrl);
    } on FormatException catch (err) {
      throwToolExit('"FLUTTER_STORAGE_BASE_URL" contains an invalid URI:\n$err');
    }
    _maybeWarnAboutStorageOverride(overrideUrl);
    return overrideUrl;
  }

  bool _hasWarnedAboutStorageOverride = false;

  void _maybeWarnAboutStorageOverride(String overrideUrl) {
    if (_hasWarnedAboutStorageOverride) {
      return;
    }
    _logger.printStatus(
      'Flutter assets will be downloaded from $overrideUrl. Make sure you trust this source!',
      emphasis: true,
    );
    _hasWarnedAboutStorageOverride = true;
  }

  /// Return the top-level directory in the cache; this is `bin/cache`.
  Directory getRoot() {
    if (_rootOverride != null) {
      return _fileSystem.directory(_fileSystem.path.join(_rootOverride.path, 'bin', 'cache'));
    } else {
      return _fileSystem.directory(_fileSystem.path.join(flutterRoot, 'bin', 'cache'));
    }
  }

  String getHostPlatformArchName() {
    return getNameForHostPlatformArch(_osUtils.hostPlatform);
  }

  /// Return a directory in the cache dir. For `pkg`, this will return `bin/cache/pkg`.
  Directory getCacheDir(String name) {
    final Directory dir = _fileSystem.directory(_fileSystem.path.join(getRoot().path, name));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      _osUtils.chmod(dir, '755');
    }
    return dir;
  }

  /// Return the top-level directory for artifact downloads.
  Directory getDownloadDir() => getCacheDir('downloads');

  /// Return the top-level mutable directory in the cache; this is `bin/cache/artifacts`.
  Directory getCacheArtifacts() => getCacheDir('artifacts');

  /// Location of LICENSE file.
  File getLicenseFile() => _fileSystem.file(_fileSystem.path.join(flutterRoot, 'LICENSE'));

  /// Get a named directory from with the cache's artifact directory; for example,
  /// `material_fonts` would return `bin/cache/artifacts/material_fonts`.
  Directory getArtifactDirectory(String name) {
    return getCacheArtifacts().childDirectory(name);
  }

  MapEntry<String, String> get dyLdLibEntry {
    if (_dyLdLibEntry != null) {
      return _dyLdLibEntry;
    }
    final List<String> paths = <String>[];
    for (final ArtifactSet artifact in _artifacts) {
      final Map<String, String> env = artifact.environment;
      if (env == null || !env.containsKey('DYLD_LIBRARY_PATH')) {
        continue;
      }
      final String path = env['DYLD_LIBRARY_PATH'];
      if (path.isEmpty) {
        continue;
      }
      paths.add(path);
    }
    _dyLdLibEntry = MapEntry<String, String>('DYLD_LIBRARY_PATH', paths.join(':'));
    return _dyLdLibEntry;
  }
  MapEntry<String, String> _dyLdLibEntry;

  /// The web sdk has to be co-located with the dart-sdk so that they can share source
  /// code.
  Directory getWebSdkDirectory() {
    return getRoot().childDirectory('flutter_web_sdk');
  }

  String getVersionFor(String artifactName) {
    final File versionFile = _fileSystem.file(_fileSystem.path.join(
      _rootOverride?.path ?? flutterRoot,
      'bin',
      'internal',
      '$artifactName.version',
    ));
    return versionFile.existsSync() ? versionFile.readAsStringSync().trim() : null;
  }

    /// Delete all stamp files maintained by the cache.
  void clearStampFiles() {
    try {
      getStampFileFor('flutter_tools').deleteSync();
      for (final ArtifactSet artifact in _artifacts) {
        final File file = getStampFileFor(artifact.stampName);
        ErrorHandlingFileSystem.deleteIfExists(file);
      }
    } on FileSystemException catch (err) {
      _logger.printError('Failed to delete some stamp files: $err');
    }
  }

  /// Read the stamp for [artifactName].
  ///
  /// If the file is missing or cannot be parsed, returns `null`.
  String getStampFor(String artifactName) {
    final File stampFile = getStampFileFor(artifactName);
    if (!stampFile.existsSync()) {
      return null;
    }
    try {
      return stampFile.readAsStringSync().trim();
    } on FileSystemException {
      return null;
    }
  }

  void setStampFor(String artifactName, String version) {
    getStampFileFor(artifactName).writeAsStringSync(version);
  }

  File getStampFileFor(String artifactName) {
    return _fileSystem.file(_fileSystem.path.join(getRoot().path, '$artifactName.stamp'));
  }

  /// Returns `true` if either [entity] is older than the tools stamp or if
  /// [entity] doesn't exist.
  bool isOlderThanToolsStamp(FileSystemEntity entity) {
    final File flutterToolsStamp = getStampFileFor('flutter_tools');
    return _fsUtils.isOlderThanReference(
      entity: entity,
      referenceFile: flutterToolsStamp,
    );
  }

  Future<bool> isUpToDate() async {
    for (final ArtifactSet artifact in _artifacts) {
      if (!await artifact.isUpToDate(_fileSystem)) {
        return false;
      }
    }
    return true;
  }

  /// Update the cache to contain all `requiredArtifacts`.
  Future<void> updateAll(Set<DevelopmentArtifact> requiredArtifacts) async {
    if (!_lockEnabled) {
      return;
    }
    for (final ArtifactSet artifact in _artifacts) {
      if (!requiredArtifacts.contains(artifact.developmentArtifact)) {
        _logger.printTrace('Artifact $artifact is not required, skipping update.');
        continue;
      }
      if (await artifact.isUpToDate(_fileSystem)) {
        continue;
      }
      try {
        await artifact.update(_artifactUpdater, _logger, _fileSystem, _osUtils);
      } on SocketException catch (e) {
        if (_hostsBlockedInChina.contains(e.address?.host)) {
          _logger.printError(
            'Failed to retrieve Flutter tool dependencies: ${e.message}.\n'
            "If you're in China, please see this page: "
            'https://flutter.dev/community/china',
            emphasis: true,
          );
        }
        rethrow;
      }
    }
  }

  Future<bool> areRemoteArtifactsAvailable({
    String engineVersion,
    bool includeAllPlatforms = true,
  }) async {
    final bool includeAllPlatformsState = this.includeAllPlatforms;
    bool allAvailable = true;
    this.includeAllPlatforms = includeAllPlatforms;
    for (final ArtifactSet cachedArtifact in _artifacts) {
      if (cachedArtifact is EngineCachedArtifact) {
        allAvailable &= await cachedArtifact.checkForArtifacts(engineVersion);
      }
    }
    this.includeAllPlatforms = includeAllPlatformsState;
    return allAvailable;
  }

  Future<bool> doesRemoteExist(String message, Uri url) async {
    final Status status = _logger.startProgress(
      message,
    );
    bool exists;
    try {
      exists = await _net.doesRemoteFileExist(url);
    } finally {
      status.stop();
    }
    return exists;
  }
}

/// Representation of a set of artifacts used by the tool.
abstract class ArtifactSet {
  ArtifactSet(this.developmentArtifact) : assert(developmentArtifact != null);

  /// The development artifact.
  final DevelopmentArtifact developmentArtifact;

  /// [true] if the artifact is up to date.
  Future<bool> isUpToDate(FileSystem fileSystem);

  /// The environment variables (if any) required to consume the artifacts.
  Map<String, String> get environment {
    return const <String, String>{};
  }

  /// Updates the artifact.
  Future<void> update(
    ArtifactUpdater artifactUpdater,
    Logger logger,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  );

  /// The canonical name of the artifact.
  String get name;

  // The name of the stamp file. Defaults to the same as the
  // artifact name.
  String get stampName => name;
}

/// An artifact set managed by the cache.
abstract class CachedArtifact extends ArtifactSet {
  CachedArtifact(
    this.name,
    this.cache,
    DevelopmentArtifact developmentArtifact,
  ) : super(developmentArtifact);

  final Cache cache;

  @override
  final String name;

  @override
  String get stampName => name;

  Directory get location => cache.getArtifactDirectory(name);
  String get version => cache.getVersionFor(name);

  // Whether or not to bypass normal platform filtering for this artifact.
  bool get ignorePlatformFiltering {
    return cache.includeAllPlatforms ||
      (cache.platformOverrideArtifacts != null && cache.platformOverrideArtifacts.contains(developmentArtifact.name));
  }

  @override
  Future<bool> isUpToDate(FileSystem fileSystem) async {
    if (!location.existsSync()) {
      return false;
    }
    if (version != cache.getStampFor(stampName)) {
      return false;
    }
    return isUpToDateInner(fileSystem);
  }

  @override
  Future<void> update(
    ArtifactUpdater artifactUpdater,
    Logger logger,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    if (!location.existsSync()) {
      try {
        location.createSync(recursive: true);
      } on FileSystemException catch (err) {
        logger.printError(err.toString());
        throwToolExit(
          'Failed to create directory for flutter cache at ${location.path}. '
          'Flutter may be missing permissions in its cache directory.'
        );
      }
    }
    await updateInner(artifactUpdater, fileSystem, operatingSystemUtils);
    try {
      cache.setStampFor(stampName, version);
    } on FileSystemException catch (err) {
      logger.printError(
        'The new artifact "$name" was downloaded, but Flutter failed to update '
        'its stamp file, receiving the error "$err". '
        'Flutter can continue, but the artifact may be re-downloaded on '
        'subsequent invocations until the problem is resolved.',
      );
    }
    artifactUpdater.removeDownloadedFiles();
  }

  /// Hook method for extra checks for being up-to-date.
  bool isUpToDateInner(FileSystem fileSystem) => true;

  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  );

  Uri _toStorageUri(String path) => Uri.parse('${cache.storageBaseUrl}/$path');
}

/// Ensures that the source files for all of the dependencies for the
/// flutter_tool are present.
///
/// This does not handle cases where the source files are modified or the
/// directory contents are incomplete.
class PubDependencies extends ArtifactSet {
  PubDependencies({
    // Needs to be lazy to avoid reading from the cache before the root is initialized.
    @required String Function() flutterRoot,
    @required Logger logger,
    @required Pub Function() pub,
  }) : _logger = logger,
       _flutterRoot = flutterRoot,
       _pub = pub,
       super(DevelopmentArtifact.universal);

  final String Function() _flutterRoot;
  final Logger _logger;
  final Pub Function() _pub;

  @override
  Future<bool> isUpToDate(
    FileSystem fileSystem,
  ) async {
    final File toolPackageConfig = fileSystem.file(
      fileSystem.path.join(_flutterRoot(), 'packages', 'flutter_tools', '.dart_tool', 'package_config.json'),
    );
    if (!toolPackageConfig.existsSync()) {
      return false;
    }
    final PackageConfig packageConfig = await loadPackageConfigWithLogging(
      toolPackageConfig,
      logger: _logger,
      throwOnError: false,
    );
    if (packageConfig == null || packageConfig == PackageConfig.empty) {
      return false;
    }
    for (final Package package in packageConfig.packages) {
      if (!fileSystem.directory(package.packageUriRoot).existsSync()) {
        return false;
      }
    }
    return true;
  }

  @override
  String get name => 'pub_dependencies';

  @override
  Future<void> update(
    ArtifactUpdater artifactUpdater,
    Logger logger,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    await _pub().get(
      context: PubContext.pubGet,
      directory: fileSystem.path.join(_flutterRoot(), 'packages', 'flutter_tools'),
      generateSyntheticPackage: false,
    );
  }
}

/// A cached artifact containing fonts used for Material Design.
class MaterialFonts extends CachedArtifact {
  MaterialFonts(Cache cache) : super(
    'material_fonts',
    cache,
    DevelopmentArtifact.universal,
  );

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) {
    final Uri archiveUri = _toStorageUri(version);
    return artifactUpdater.downloadZipArchive('Downloading Material fonts...', archiveUri, location);
  }
}

/// A cached artifact containing the web dart:ui sources, platform dill files,
/// and libraries.json.
///
/// This SDK references code within the regular Dart sdk to reduce download size.
class FlutterWebSdk extends CachedArtifact {
  FlutterWebSdk(Cache cache, {@required Platform platform})
   : _platform = platform,
     super(
      'flutter_web_sdk',
      cache,
      DevelopmentArtifact.web,
    );

  final Platform _platform;

  @override
  Directory get location => cache.getWebSdkDirectory();

  @override
  String get version => cache.getVersionFor('engine');

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    String platformName = 'flutter-web-sdk-';
    if (_platform.isMacOS) {
      platformName += 'darwin-x64';
    } else if (_platform.isLinux) {
      platformName += 'linux-x64';
    } else if (_platform.isWindows) {
      platformName += 'windows-x64';
    }
    final Uri url = Uri.parse('${cache.storageBaseUrl}/flutter_infra_release/flutter/$version/$platformName.zip');
    if (location.existsSync()) {
      location.deleteSync(recursive: true);
    }
    await artifactUpdater.downloadZipArchive('Downloading Web SDK...', url, location);
    // This is a temporary work-around for not being able to safely download into a shared directory.
    final FileSystem fileSystem = location.fileSystem;
    for (final FileSystemEntity entity in location.listSync(recursive: true)) {
      if (entity is File) {
        final List<String> segments = fileSystem.path.split(entity.path);
        segments.remove('flutter_web_sdk');
        final String newPath = fileSystem.path.joinAll(segments);
        final File newFile = fileSystem.file(newPath);
        if (!newFile.existsSync()) {
          newFile.createSync(recursive: true);
        }
        entity.copySync(newPath);
      }
    }
  }
}

abstract class EngineCachedArtifact extends CachedArtifact {
  EngineCachedArtifact(
    this.stampName,
    Cache cache,
    DevelopmentArtifact developmentArtifact,
  ) : super('engine', cache, developmentArtifact);

  @override
  final String stampName;

  /// Return a list of (directory path, download URL path) tuples.
  List<List<String>> getBinaryDirs();

  /// A list of cache directory paths to which the LICENSE file should be copied.
  List<String> getLicenseDirs();

  /// A list of the dart package directories to download.
  List<String> getPackageDirs();

  @override
  bool isUpToDateInner(FileSystem fileSystem) {
    final Directory pkgDir = cache.getCacheDir('pkg');
    for (final String pkgName in getPackageDirs()) {
      final String pkgPath = fileSystem.path.join(pkgDir.path, pkgName);
      if (!fileSystem.directory(pkgPath).existsSync()) {
        return false;
      }
    }

    for (final List<String> toolsDir in getBinaryDirs()) {
      final Directory dir = fileSystem.directory(fileSystem.path.join(location.path, toolsDir[0]));
      if (!dir.existsSync()) {
        return false;
      }
    }

    for (final String licenseDir in getLicenseDirs()) {
      final File file = fileSystem.file(fileSystem.path.join(location.path, licenseDir, 'LICENSE'));
      if (!file.existsSync()) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    final String url = '${cache.storageBaseUrl}/flutter_infra_release/flutter/$version/';

    final Directory pkgDir = cache.getCacheDir('pkg');
    for (final String pkgName in getPackageDirs()) {
      await artifactUpdater.downloadZipArchive('Downloading package $pkgName...', Uri.parse(url + pkgName + '.zip'), pkgDir);
    }

    for (final List<String> toolsDir in getBinaryDirs()) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      final Directory dir = fileSystem.directory(fileSystem.path.join(location.path, cacheDir));

      // Avoid printing things like 'Downloading linux-x64 tools...' multiple times.
      final String friendlyName = urlPath.replaceAll('/artifacts.zip', '').replaceAll('.zip', '');
      await artifactUpdater.downloadZipArchive('Downloading $friendlyName tools...', Uri.parse(url + urlPath), dir);

      _makeFilesExecutable(dir, operatingSystemUtils);

      final File frameworkZip = fileSystem.file(fileSystem.path.join(dir.path, 'FlutterMacOS.framework.zip'));
      if (frameworkZip.existsSync()) {
        final Directory framework = fileSystem.directory(fileSystem.path.join(dir.path, 'FlutterMacOS.framework'));
        framework.createSync();
        operatingSystemUtils.unzip(frameworkZip, framework);
      }
    }

    final File licenseSource = cache.getLicenseFile();
    for (final String licenseDir in getLicenseDirs()) {
      final String licenseDestinationPath = fileSystem.path.join(location.path, licenseDir, 'LICENSE');
      await licenseSource.copy(licenseDestinationPath);
    }
  }

  Future<bool> checkForArtifacts(String engineVersion) async {
    engineVersion ??= version;
    final String url = '${cache.storageBaseUrl}/flutter_infra_release/flutter/$engineVersion/';

    bool exists = false;
    for (final String pkgName in getPackageDirs()) {
      exists = await cache.doesRemoteExist('Checking package $pkgName is available...', Uri.parse(url + pkgName + '.zip'));
      if (!exists) {
        return false;
      }
    }

    for (final List<String> toolsDir in getBinaryDirs()) {
      final String cacheDir = toolsDir[0];
      final String urlPath = toolsDir[1];
      exists = await cache.doesRemoteExist('Checking $cacheDir tools are available...',
          Uri.parse(url + urlPath));
      if (!exists) {
        return false;
      }
    }
    return true;
  }

  void _makeFilesExecutable(Directory dir, OperatingSystemUtils operatingSystemUtils) {
    operatingSystemUtils.chmod(dir, 'a+r,a+x');
    for (final File file in dir.listSync(recursive: true).whereType<File>()) {
      final FileStat stat = file.statSync();
      final bool isUserExecutable = ((stat.mode >> 6) & 0x1) == 1;
      if (file.basename == 'flutter_tester' || isUserExecutable) {
        // Make the file readable and executable by all users.
        operatingSystemUtils.chmod(file, 'a+r,a+x');
      }
    }
  }
}

/// A cached artifact containing the dart:ui source code.
class FlutterSdk extends EngineCachedArtifact {
  FlutterSdk(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
      super(
        'flutter_sdk',
        cache,
        DevelopmentArtifact.universal,
      );

  final Platform _platform;

  @override
  List<String> getPackageDirs() => const <String>['sky_engine'];

  @override
  List<List<String>> getBinaryDirs() {
    // Currently only Linux supports both arm64 and x64.
    final String arch = cache.getHostPlatformArchName();
    return <List<String>>[
      <String>['common', 'flutter_patched_sdk.zip'],
      <String>['common', 'flutter_patched_sdk_product.zip'],
      if (cache.includeAllPlatforms) ...<List<String>>[
        <String>['windows-x64', 'windows-x64/artifacts.zip'],
        <String>['linux-$arch', 'linux-$arch/artifacts.zip'],
        <String>['darwin-x64', 'darwin-x64/artifacts.zip'],
      ]
      else if (_platform.isWindows)
        <String>['windows-x64', 'windows-x64/artifacts.zip']
      else if (_platform.isMacOS)
        <String>['darwin-x64', 'darwin-x64/artifacts.zip']
      else if (_platform.isLinux)
        <String>['linux-$arch', 'linux-$arch/artifacts.zip'],
    ];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

class MacOSEngineArtifacts extends EngineCachedArtifact {
  MacOSEngineArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
        super(
        'macos-sdk',
        cache,
        DevelopmentArtifact.macOS,
      );

  final Platform _platform;

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    if (_platform.isMacOS || ignorePlatformFiltering) {
      return _macOSDesktopBinaryDirs;
    }
    return const <List<String>>[];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

/// Artifacts required for desktop Windows builds.
class WindowsEngineArtifacts extends EngineCachedArtifact {
  WindowsEngineArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
       super(
        'windows-sdk',
         cache,
         DevelopmentArtifact.windows,
       );

  final Platform _platform;

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    if (_platform.isWindows || ignorePlatformFiltering) {
      return _windowsDesktopBinaryDirs;
    }
    return const <List<String>>[];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

/// Artifacts required for desktop Linux builds.
class LinuxEngineArtifacts extends EngineCachedArtifact {
  LinuxEngineArtifacts(Cache cache, {
    @required Platform platform
  }) : _platform = platform,
       super(
        'linux-sdk',
        cache,
        DevelopmentArtifact.linux,
      );

  final Platform _platform;

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    if (_platform.isLinux || ignorePlatformFiltering) {
      final String arch = cache.getHostPlatformArchName();
      return <List<String>>[
        <String>['linux-$arch', 'linux-$arch/linux-$arch-flutter-gtk.zip'],
        <String>['linux-$arch-profile', 'linux-$arch-profile/linux-$arch-flutter-gtk.zip'],
        <String>['linux-$arch-release', 'linux-$arch-release/linux-$arch-flutter-gtk.zip'],
      ];
    }
    return const <List<String>>[];
  }

  @override
  List<String> getLicenseDirs() => const <String>[];
}

/// The artifact used to generate snapshots for Android builds.
class AndroidGenSnapshotArtifacts extends EngineCachedArtifact {
  AndroidGenSnapshotArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
        super(
        'android-sdk',
        cache,
        DevelopmentArtifact.androidGenSnapshot,
      );

  final Platform _platform;

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    return <List<String>>[
      if (cache.includeAllPlatforms) ...<List<String>>[
        ..._osxBinaryDirs,
        ..._linuxBinaryDirs,
        ..._windowsBinaryDirs,
        ..._dartSdks,
      ] else if (_platform.isWindows)
        ..._windowsBinaryDirs
      else if (_platform.isMacOS)
        ..._osxBinaryDirs
      else if (_platform.isLinux)
        ..._linuxBinaryDirs,
    ];
  }

  @override
  List<String> getLicenseDirs() { return <String>[]; }
}

/// A cached artifact containing the Maven dependencies used to build Android projects.
///
/// This is a no-op if the android SDK is not available.
class AndroidMavenArtifacts extends ArtifactSet {
  AndroidMavenArtifacts(this.cache, {
    @required Platform platform,
  }) : _platform = platform,
       super(DevelopmentArtifact.androidMaven);

  final Platform _platform;
  final Cache cache;

  @override
  Future<void> update(
    ArtifactUpdater artifactUpdater,
    Logger logger,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    if (globals.androidSdk == null) {
      return;
    }
    final Directory tempDir = cache.getRoot().createTempSync(
      'flutter_gradle_wrapper.',
    );
    globals.gradleUtils.injectGradleWrapperIfNeeded(tempDir);

    final Status status = logger.startProgress('Downloading Android Maven dependencies...');
    final File gradle = tempDir.childFile(
      _platform.isWindows ? 'gradlew.bat' : 'gradlew',
    );
    try {
      final String gradleExecutable = gradle.absolute.path;
      final String flutterSdk = globals.fsUtils.escapePath(Cache.flutterRoot);
      final RunResult processResult = await globals.processUtils.run(
        <String>[
          gradleExecutable,
          '-b', globals.fs.path.join(flutterSdk, 'packages', 'flutter_tools', 'gradle', 'resolve_dependencies.gradle'),
          '--project-cache-dir', tempDir.path,
          'resolveDependencies',
        ],
        environment: <String, String>{
          if (javaPath != null)
            'JAVA_HOME': javaPath,
        },
      );
      if (processResult.exitCode != 0) {
        logger.printError('Failed to download the Android dependencies');
      }
    } finally {
      status.stop();
      tempDir.deleteSync(recursive: true);
      globals.androidSdk?.reinitialize();
    }
  }

  @override
  Future<bool> isUpToDate(FileSystem fileSystem) async {
    // The dependencies are downloaded and cached by Gradle.
    // The tool doesn't know if the dependencies are already cached at this point.
    // Therefore, call Gradle to figure this out.
    return false;
  }

  @override
  String get name => 'android-maven-artifacts';
}

/// Artifacts used for internal builds. The flutter tool builds Android projects
/// using the artifacts cached by [AndroidMavenArtifacts].
class AndroidInternalBuildArtifacts extends EngineCachedArtifact {
  AndroidInternalBuildArtifacts(Cache cache) : super(
    'android-internal-build-artifacts',
    cache,
    DevelopmentArtifact.androidInternalBuild,
  );

  @override
  List<String> getPackageDirs() => const <String>[];

  @override
  List<List<String>> getBinaryDirs() {
    return _androidBinaryDirs;
  }

  @override
  List<String> getLicenseDirs() { return <String>[]; }
}

class IOSEngineArtifacts extends EngineCachedArtifact {
  IOSEngineArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
        super(
        'ios-sdk',
        cache,
        DevelopmentArtifact.iOS,
      );

  final Platform _platform;

  @override
  List<List<String>> getBinaryDirs() {
    return <List<String>>[
      if (_platform.isMacOS || ignorePlatformFiltering)
        ..._iosBinaryDirs,
    ];
  }

  @override
  List<String> getLicenseDirs() {
    if (_platform.isMacOS || ignorePlatformFiltering) {
      return const <String>['ios', 'ios-profile', 'ios-release'];
    }
    return const <String>[];
  }

  @override
  List<String> getPackageDirs() {
    return <String>[];
  }
}

/// A cached artifact containing Gradle Wrapper scripts and binaries.
///
/// While this is only required for Android, we need to always download it due
/// the ensurePlatformSpecificTooling logic.
class GradleWrapper extends CachedArtifact {
  GradleWrapper(Cache cache) : super(
    'gradle_wrapper',
    cache,
    DevelopmentArtifact.universal,
  );

  List<String> get _gradleScripts => <String>['gradlew', 'gradlew.bat'];

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    final Uri archiveUri = _toStorageUri(version);
    await  artifactUpdater.downloadZippedTarball('Downloading Gradle Wrapper...', archiveUri, location);
    // Delete property file, allowing templates to provide it.
    fileSystem.file(fileSystem.path.join(location.path, 'gradle', 'wrapper', 'gradle-wrapper.properties')).deleteSync();
    // Remove NOTICE file. Should not be part of the template.
    fileSystem.file(fileSystem.path.join(location.path, 'NOTICE')).deleteSync();
  }

  @override
  bool isUpToDateInner(
    FileSystem fileSystem,
  ) {
    final String gradleWrapper = fileSystem.path.join('gradle', 'wrapper', 'gradle-wrapper.jar');
    final Directory wrapperDir = cache.getCacheDir(fileSystem.path.join('artifacts', 'gradle_wrapper'));
    if (!fileSystem.directory(wrapperDir).existsSync()) {
      return false;
    }
    for (final String scriptName in _gradleScripts) {
      final File scriptFile = fileSystem.file(fileSystem.path.join(wrapperDir.path, scriptName));
      if (!scriptFile.existsSync()) {
        return false;
      }
    }
    final File gradleWrapperJar = fileSystem.file(fileSystem.path.join(wrapperDir.path, gradleWrapper));
    if (!gradleWrapperJar.existsSync()) {
      return false;
    }
    return true;
  }
}

const String _cipdBaseUrl = 'https://chrome-infra-packages.appspot.com/dl';

/// Common functionality for pulling Fuchsia SDKs.
abstract class _FuchsiaSDKArtifacts extends CachedArtifact {
  _FuchsiaSDKArtifacts(Cache cache, String platform) :
    _path = 'fuchsia/sdk/core/$platform-amd64',
    super(
      'fuchsia-$platform',
      cache,
      DevelopmentArtifact.fuchsia,
    );

  final String _path;

  @override
  Directory get location => cache.getArtifactDirectory('fuchsia');

  Future<void> _doUpdate(ArtifactUpdater artifactUpdater) {
    final String url = '$_cipdBaseUrl/$_path/+/$version';
    return artifactUpdater.downloadZipArchive('Downloading package fuchsia SDK...',
                               Uri.parse(url), location);
  }
}

/// The pre-built flutter runner for Fuchsia development.
class FlutterRunnerSDKArtifacts extends CachedArtifact {
  FlutterRunnerSDKArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
        super(
        'flutter_runner',
        cache,
        DevelopmentArtifact.flutterRunner,
      );

  final Platform _platform;

  @override
  Directory get location => cache.getArtifactDirectory('flutter_runner');

  @override
  String get version => cache.getVersionFor('engine');

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    if (!_platform.isLinux && !_platform.isMacOS) {
      return;
    }
    final String url = '$_cipdBaseUrl/flutter/fuchsia/+/git_revision:$version';
    await artifactUpdater.downloadZipArchive('Downloading package flutter runner...', Uri.parse(url), location);
  }
}

/// Implementations of this class can resolve URLs for packages that are versioned.
///
/// See also [CipdArchiveResolver].
abstract class VersionedPackageResolver {
  const VersionedPackageResolver();

  /// Returns the URL for the artifact.
  String resolveUrl(String packageName, String version);
}

/// Resolves the CIPD archive URL for a given package and version.
class CipdArchiveResolver extends VersionedPackageResolver {
  const CipdArchiveResolver();

  @override
  String resolveUrl(String packageName, String version) {
    return '$_cipdBaseUrl/flutter/$packageName/+/git_revision:$version';
  }
}

/// The debug symbols for flutter runner for Fuchsia development.
class FlutterRunnerDebugSymbols extends CachedArtifact {
  FlutterRunnerDebugSymbols(Cache cache, {
    @required Platform platform,
    this.packageResolver = const CipdArchiveResolver(),
  }) : _platform = platform,
      super('flutter_runner_debug_symbols', cache, DevelopmentArtifact.flutterRunner);

  final VersionedPackageResolver packageResolver;
  final Platform _platform;

  @override
  Directory get location => cache.getArtifactDirectory(name);

  @override
  String get version => cache.getVersionFor('engine');

  Future<void> _downloadDebugSymbols(String targetArch, ArtifactUpdater artifactUpdater) async {
    final String packageName = 'fuchsia-debug-symbols-$targetArch';
    final String url = packageResolver.resolveUrl(packageName, version);
    await artifactUpdater.downloadZipArchive(
      'Downloading debug symbols for flutter runner - arch:$targetArch...',
      Uri.parse(url),
      location,
    );
  }

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    if (!_platform.isLinux && !_platform.isMacOS) {
      return;
    }
    await _downloadDebugSymbols('x64', artifactUpdater);
    await _downloadDebugSymbols('arm64', artifactUpdater);
  }
}

/// The Fuchsia core SDK for Linux.
class LinuxFuchsiaSDKArtifacts extends _FuchsiaSDKArtifacts {
  LinuxFuchsiaSDKArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
       super(cache, 'linux');

  final Platform _platform;

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    if (!_platform.isLinux) {
      return;
    }
    return _doUpdate(artifactUpdater);
  }
}

/// The Fuchsia core SDK for MacOS.
class MacOSFuchsiaSDKArtifacts extends _FuchsiaSDKArtifacts {
  MacOSFuchsiaSDKArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
       super(cache, 'mac');

  final Platform _platform;

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    if (!_platform.isMacOS) {
      return;
    }
    return _doUpdate(artifactUpdater);
  }
}

/// Cached artifacts for font subsetting.
class FontSubsetArtifacts extends EngineCachedArtifact {
  FontSubsetArtifacts(Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
       super(artifactName, cache, DevelopmentArtifact.universal);

  final Platform _platform;

  static const String artifactName = 'font-subset';

  @override
  List<List<String>> getBinaryDirs() {
    // Currently only Linux supports both arm64 and x64.
    final String arch = cache.getHostPlatformArchName();
    final Map<String, List<String>> artifacts = <String, List<String>> {
      'macos': <String>['darwin-x64', 'darwin-x64/$artifactName.zip'],
      'linux': <String>['linux-$arch', 'linux-$arch/$artifactName.zip'],
      'windows': <String>['windows-x64', 'windows-x64/$artifactName.zip'],
    };
    if (cache.includeAllPlatforms) {
      return artifacts.values.toList();
    } else {
      final List<String> binaryDirs = artifacts[_platform.operatingSystem];
      if (binaryDirs == null) {
        throwToolExit('Unsupported operating system: ${_platform.operatingSystem}');
      }
      return <List<String>>[binaryDirs];
    }
  }

  @override
  List<String> getLicenseDirs() => const <String>[];

  @override
  List<String> getPackageDirs() => const <String>[];
}

/// Cached iOS/USB binary artifacts.
class IosUsbArtifacts extends CachedArtifact {
  IosUsbArtifacts(String name, Cache cache, {
    @required Platform platform,
  }) : _platform = platform,
       super(
        name,
        cache,
        DevelopmentArtifact.universal,
      );

  final Platform _platform;

  static const List<String> artifactNames = <String>[
    'libimobiledevice',
    'usbmuxd',
    'libplist',
    'openssl',
    'ios-deploy',
  ];

  // For unknown reasons, users are getting into bad states where libimobiledevice is
  // downloaded but some executables are missing from the zip. The names here are
  // used for additional download checks below, so we can re-download if they are
  // missing.
  static const Map<String, List<String>> _kExecutables = <String, List<String>>{
    'libimobiledevice': <String>[
      'idevicescreenshot',
      'idevicesyslog',
    ],
    'usbmuxd': <String>[
      'iproxy',
    ],
  };

  @override
  Map<String, String> get environment {
    return <String, String>{
      'DYLD_LIBRARY_PATH': cache.getArtifactDirectory(name).path,
    };
  }

  @override
  bool isUpToDateInner(FileSystem fileSystem) {
    final List<String> executables =_kExecutables[name];
    if (executables == null) {
      return true;
    }
    for (final String executable in executables) {
      if (!location.childFile(executable).existsSync()) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> updateInner(
    ArtifactUpdater artifactUpdater,
    FileSystem fileSystem,
    OperatingSystemUtils operatingSystemUtils,
  ) async {
    if (!_platform.isMacOS && !ignorePlatformFiltering) {
      return;
    }
    if (location.existsSync()) {
      location.deleteSync(recursive: true);
    }
    await artifactUpdater.downloadZipArchive('Downloading $name...', archiveUri, location);
  }

  @visibleForTesting
  Uri get archiveUri => Uri.parse('${cache.storageBaseUrl}/flutter_infra_release/ios-usb-dependencies${cache.useUnsignedMacBinaries ? '/unsigned' : ''}/$name/$version/$name.zip');
}

// Many characters are problematic in filenames, especially on Windows.
final Map<int, List<int>> _flattenNameSubstitutions = <int, List<int>>{
  r'@'.codeUnitAt(0): '@@'.codeUnits,
  r'/'.codeUnitAt(0): '@s@'.codeUnits,
  r'\'.codeUnitAt(0): '@bs@'.codeUnits,
  r':'.codeUnitAt(0): '@c@'.codeUnits,
  r'%'.codeUnitAt(0): '@per@'.codeUnits,
  r'*'.codeUnitAt(0): '@ast@'.codeUnits,
  r'<'.codeUnitAt(0): '@lt@'.codeUnits,
  r'>'.codeUnitAt(0): '@gt@'.codeUnits,
  r'"'.codeUnitAt(0): '@q@'.codeUnits,
  r'|'.codeUnitAt(0): '@pip@'.codeUnits,
  r'?'.codeUnitAt(0): '@ques@'.codeUnits,
};

/// Given a name containing slashes, colons, and backslashes, expand it into
/// something that doesn't.
String _flattenNameNoSubdirs(String fileName) {
  final List<int> replacedCodeUnits = <int>[
    for (int codeUnit in fileName.codeUnits)
      ..._flattenNameSubstitutions[codeUnit] ?? <int>[codeUnit],
  ];
  return String.fromCharCodes(replacedCodeUnits);
}

// TODO(jonahwilliams): upload debug desktop artifacts to host-debug and
// remove from existing host folder.
// https://github.com/flutter/flutter/issues/38935
const List<List<String>> _windowsDesktopBinaryDirs = <List<String>>[
  <String>['windows-x64', 'windows-x64/windows-x64-flutter.zip'],
  <String>['windows-x64', 'windows-x64/flutter-cpp-client-wrapper.zip'],
  <String>['windows-x64-profile', 'windows-x64-profile/windows-x64-flutter.zip'],
  <String>['windows-x64-release', 'windows-x64-release/windows-x64-flutter.zip'],
];

const List<List<String>> _macOSDesktopBinaryDirs = <List<String>>[
  <String>['darwin-x64', 'darwin-x64/FlutterMacOS.framework.zip'],
  <String>['darwin-x64-profile', 'darwin-x64-profile/FlutterMacOS.framework.zip'],
  <String>['darwin-x64-profile', 'darwin-x64-profile/artifacts.zip'],
  <String>['darwin-x64-release', 'darwin-x64-release/FlutterMacOS.framework.zip'],
  <String>['darwin-x64-release', 'darwin-x64-release/artifacts.zip'],
];

const List<List<String>> _osxBinaryDirs = <List<String>>[
  <String>['android-arm-profile/darwin-x64', 'android-arm-profile/darwin-x64.zip'],
  <String>['android-arm-release/darwin-x64', 'android-arm-release/darwin-x64.zip'],
  <String>['android-arm64-profile/darwin-x64', 'android-arm64-profile/darwin-x64.zip'],
  <String>['android-arm64-release/darwin-x64', 'android-arm64-release/darwin-x64.zip'],
  <String>['android-x64-profile/darwin-x64', 'android-x64-profile/darwin-x64.zip'],
  <String>['android-x64-release/darwin-x64', 'android-x64-release/darwin-x64.zip'],
];

const List<List<String>> _linuxBinaryDirs = <List<String>>[
  <String>['android-arm-profile/linux-x64', 'android-arm-profile/linux-x64.zip'],
  <String>['android-arm-release/linux-x64', 'android-arm-release/linux-x64.zip'],
  <String>['android-arm64-profile/linux-x64', 'android-arm64-profile/linux-x64.zip'],
  <String>['android-arm64-release/linux-x64', 'android-arm64-release/linux-x64.zip'],
  <String>['android-x64-profile/linux-x64', 'android-x64-profile/linux-x64.zip'],
  <String>['android-x64-release/linux-x64', 'android-x64-release/linux-x64.zip'],
];

const List<List<String>> _windowsBinaryDirs = <List<String>>[
  <String>['android-arm-profile/windows-x64', 'android-arm-profile/windows-x64.zip'],
  <String>['android-arm-release/windows-x64', 'android-arm-release/windows-x64.zip'],
  <String>['android-arm64-profile/windows-x64', 'android-arm64-profile/windows-x64.zip'],
  <String>['android-arm64-release/windows-x64', 'android-arm64-release/windows-x64.zip'],
  <String>['android-x64-profile/windows-x64', 'android-x64-profile/windows-x64.zip'],
  <String>['android-x64-release/windows-x64', 'android-x64-release/windows-x64.zip'],
];

const List<List<String>> _iosBinaryDirs = <List<String>>[
  <String>['ios', 'ios/artifacts.zip'],
  <String>['ios-profile', 'ios-profile/artifacts.zip'],
  <String>['ios-release', 'ios-release/artifacts.zip'],
];

const List<List<String>> _androidBinaryDirs = <List<String>>[
  <String>['android-x86', 'android-x86/artifacts.zip'],
  <String>['android-x64', 'android-x64/artifacts.zip'],
  <String>['android-arm', 'android-arm/artifacts.zip'],
  <String>['android-arm-profile', 'android-arm-profile/artifacts.zip'],
  <String>['android-arm-release', 'android-arm-release/artifacts.zip'],
  <String>['android-arm64', 'android-arm64/artifacts.zip'],
  <String>['android-arm64-profile', 'android-arm64-profile/artifacts.zip'],
  <String>['android-arm64-release', 'android-arm64-release/artifacts.zip'],
  <String>['android-x64-profile', 'android-x64-profile/artifacts.zip'],
  <String>['android-x64-release', 'android-x64-release/artifacts.zip'],
  <String>['android-x86-jit-release', 'android-x86-jit-release/artifacts.zip'],
];

const List<List<String>> _dartSdks = <List<String>> [
  <String>['darwin-x64', 'dart-sdk-darwin-x64.zip'],
  <String>['linux-x64', 'dart-sdk-linux-x64.zip'],
  <String>['windows-x64', 'dart-sdk-windows-x64.zip'],
];

/// An API for downloading and un-archiving artifacts, such as engine binaries or
/// additional source code.
class ArtifactUpdater {
  ArtifactUpdater({
    @required OperatingSystemUtils operatingSystemUtils,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required Directory tempStorage,
    @required HttpClient httpClient,
    @required Platform platform,
  }) : _operatingSystemUtils = operatingSystemUtils,
       _httpClient = httpClient,
       _logger = logger,
       _fileSystem = fileSystem,
       _tempStorage = tempStorage,
       _platform = platform;

  /// The number of times the artifact updater will repeat the artifact download loop.
  static const int _kRetryCount = 2;

  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;
  final FileSystem _fileSystem;
  final Directory _tempStorage;
  final HttpClient _httpClient;
  final Platform _platform;

  /// Keep track of the files we've downloaded for this execution so we
  /// can delete them after completion. We don't delete them right after
  /// extraction in case [update] is interrupted, so we can restart without
  /// starting from scratch.
  @visibleForTesting
  final List<File> downloadedFiles = <File>[];

  /// Download a zip archive from the given [url] and unzip it to [location].
  Future<void> downloadZipArchive(
    String message,
    Uri url,
    Directory location,
  ) {
    return _downloadArchive(
      message,
      url,
      location,
      _operatingSystemUtils.unzip,
    );
  }

  /// Download a gzipped tarball from the given [url] and unpack it to [location].
  Future<void> downloadZippedTarball(String message, Uri url, Directory location) {
    return _downloadArchive(
      message,
      url,
      location,
      _operatingSystemUtils.unpack,
    );
  }

  /// Download an archive from the given [url] and unzip it to [location].
  Future<void> _downloadArchive(
    String message,
    Uri url,
    Directory location,
    void Function(File, Directory) extractor,
  ) async {
    final String downloadPath = flattenNameSubdirs(url, _fileSystem);
    final File tempFile = _createDownloadFile(downloadPath);
    Status status;
    int retries = _kRetryCount;

    while (retries > 0) {
      status = _logger.startProgress(
        message,
      );
      try {
        _ensureExists(tempFile.parent);
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
        await _download(url, tempFile);

        if (!tempFile.existsSync()) {
          throw Exception('Did not find downloaded file ${tempFile.path}');
        }
      } on Exception catch (err) {
        _logger.printTrace(err.toString());
        retries -= 1;
        if (retries == 0) {
          throwToolExit(
            'Failed to download $url. Ensure you have network connectivity and then try again.\n$err',
          );
        }
        continue;
      } on ArgumentError catch (error) {
        final String overrideUrl = _platform.environment['FLUTTER_STORAGE_BASE_URL'];
        if (overrideUrl != null && url.toString().contains(overrideUrl)) {
          _logger.printError(error.toString());
          throwToolExit(
            'The value of FLUTTER_STORAGE_BASE_URL ($overrideUrl) could not be '
            'parsed as a valid url. Please see https://flutter.dev/community/china '
            'for an example of how to use it.\n'
            'Full URL: $url',
            exitCode: kNetworkProblemExitCode,
          );
        }
        // This error should not be hit if there was not a storage URL override, allow the
        // tool to crash.
        rethrow;
      } finally {
        status.stop();
      }
      /// Unzipping multiple file into a directory will not remove old files
      /// from previous versions that are not present in the new bundle.
      final Directory destination = location.childDirectory(
        tempFile.fileSystem.path.basenameWithoutExtension(tempFile.path)
      );
      try {
        ErrorHandlingFileSystem.deleteIfExists(
          destination,
          recursive: true,
        );
      } on FileSystemException catch (error) {
        // Error that indicates another program has this file open and that it
        // cannot be deleted. For the cache, this is either the analyzer reading
        // the sky_engine package or a running flutter_tester device.
        const int kSharingViolation = 32;
        if (_platform.isWindows && error.osError.errorCode == kSharingViolation) {
          throwToolExit(
            'Failed to delete ${destination.path} because the local file/directory is in use '
            'by another process. Try closing any running IDEs or editors and trying '
            'again'
          );
        }
      }
      _ensureExists(location);

      try {
        extractor(tempFile, location);
      } on Exception catch (err) {
        retries -= 1;
        if (retries == 0) {
          throwToolExit(
            'Flutter could not download and/or extract $url. Ensure you have '
            'network connectivity and all of the required dependencies listed at'
            'flutter.dev/setup.\nThe original exception was: $err.'
          );
        }
        _deleteIgnoringErrors(tempFile);
        continue;
      }
      return;
    }
  }

  /// Download bytes from [url], throwing non-200 responses as an exception.
  ///
  /// Validates that the md5 of the content bytes matches the provided
  /// `x-goog-hash` header, if present. This header should contain an md5 hash
  /// if the download source is Google cloud storage.
  ///
  /// See also:
  ///   * https://cloud.google.com/storage/docs/xml-api/reference-headers#xgooghash
  Future<void> _download(Uri url, File file) async {
    final HttpClientRequest request = await _httpClient.getUrl(url);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(response.statusCode);
    }

    final String md5Hash = _expectedMd5(response.headers);
    ByteConversionSink inputSink;
    StreamController<Digest> digests;
    if (md5Hash != null) {
      _logger.printTrace('Content $url md5 hash: $md5Hash');
      digests = StreamController<Digest>();
      inputSink = md5.startChunkedConversion(digests);
    }
    final RandomAccessFile randomAccessFile = file.openSync(mode: FileMode.writeOnly);
    await response.forEach((List<int> chunk) {
      inputSink?.add(chunk);
      randomAccessFile.writeFromSync(chunk);
    });
    randomAccessFile.closeSync();
    if (inputSink != null) {
      inputSink.close();
      final Digest digest = await digests.stream.last;
      final String rawDigest = base64.encode(digest.bytes);
      if (rawDigest != md5Hash) {
        throw Exception(''
          'Expected $url to have md5 checksum $md5Hash, but was $rawDigest. This '
          'may indicate a problem with your connection to the Flutter backend servers. '
          'Please re-try the download after confirming that your network connection is '
          'stable.'
        );
      }
    }
  }

  String _expectedMd5(HttpHeaders httpHeaders) {
    final List<String> values = httpHeaders['x-goog-hash'];
    if (values == null) {
      return null;
    }
    final String rawMd5Hash = values.firstWhere((String value) {
      return value.startsWith('md5=');
    }, orElse: () => null);
    if (rawMd5Hash == null) {
      return null;
    }
    final List<String> segments = rawMd5Hash.split('md5=');
    if (segments.length < 2) {
      return null;
    }
    final String md5Hash = segments[1];
    if (md5Hash.isEmpty) {
      return null;
    }
    return md5Hash;
  }

  /// Create a temporary file and invoke [onTemporaryFile] with the file as
  /// argument, then add the temporary file to the [downloadedFiles].
  File _createDownloadFile(String name) {
    final File tempFile = _fileSystem.file(_fileSystem.path.join(_tempStorage.path, name));
    downloadedFiles.add(tempFile);
    return tempFile;
  }

  /// Create the given [directory] and parents, as necessary.
  void _ensureExists(Directory directory) {
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

    /// Clear any zip/gzip files downloaded.
  void removeDownloadedFiles() {
    for (final File file in downloadedFiles) {
      if (!file.existsSync()) {
        continue;
      }
      try {
        file.deleteSync();
      } on FileSystemException catch (e) {
        _logger.printError('Failed to delete "${file.path}". Please delete manually. $e');
        continue;
      }
      for (Directory directory = file.parent; directory.absolute.path != _tempStorage.absolute.path; directory = directory.parent) {
        if (directory.listSync().isNotEmpty) {
          break;
        }
        _deleteIgnoringErrors(directory);
      }
    }
  }

  static void _deleteIgnoringErrors(FileSystemEntity entity) {
    if (!entity.existsSync()) {
      return;
    }
    try {
      entity.deleteSync();
    } on FileSystemException {
      // Ignore errors.
    }
  }
}

@visibleForTesting
String flattenNameSubdirs(Uri url, FileSystem fileSystem){
  final List<String> pieces = <String>[url.host, ...url.pathSegments];
  final Iterable<String> convertedPieces = pieces.map<String>(_flattenNameNoSubdirs);
  return fileSystem.path.joinAll(convertedPieces);
}
