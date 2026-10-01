// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'java.dart';
library;

import 'package:meta/meta.dart';
import 'package:process/process.dart';

import '../base/common.dart';
import '../base/config.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/signals.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../base/version.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../ios/plist_parser.dart';

@visibleForTesting
const String kSpotlightMdfindCommand =
    r'( '
    r'  for ((i = 0; i < 30; i++)); do '
    r'    sleep .1; '
    r'    kill -0 $$ || exit 0; '
    r'  done; '
    r'  kill -9 $$; '
    r') 2>/dev/null & '
    'exec mdfind \'kMDItemCFBundleIdentifier="com.google.android.studio*"\'';

const _androidStudioTitle = 'Android Studio';
const _androidStudioId = 'AndroidStudio';
const _androidStudioPreviewTitle = 'Android Studio Preview';
const _androidStudioPreviewId = 'AndroidStudioPreview';

// Android Studio layout:

// Linux/Windows:
// $HOME/.AndroidStudioX.Y/system/.home
// $HOME/.cache/Google/AndroidStudioX.Y/.home

// macOS:
// /Applications/Android Studio.app/Contents/
// $HOME/Applications/Android Studio.app/Contents/

// Match Android Studio >= 4.1 base folder (AndroidStudio*.*)
// and < 4.1 (.AndroidStudio*.*)
final _dotHomeStudioVersionMatcher = RegExp(r'^\.?(AndroidStudio[^\d]*)([\d.]+)');

FileSystem _createDefaultFileSystem(Platform platform) => ErrorHandlingFileSystem(
  delegate: LocalFileSystem(LocalSignals.instance, Signals.defaultExitSignals, ShutdownHooks()),
  platform: platform,
);

Logger _createDefaultLogger(Platform platform) {
  final stdio = Stdio();
  return StdoutLogger(
    terminal: AnsiTerminal(platform: platform, stdio: stdio),
    stdio: stdio,
    outputPreferences: OutputPreferences(
      wrapText: stdio.hasTerminal,
      showColor: platform.stdoutSupportsAnsi,
      stdio: stdio,
    ),
  );
}

class AndroidStudio {
  /// A [version] value of null represents an unknown version.
  factory AndroidStudio(
    String directory, {
    String? configuredPath,
    FileSystem? fileSystem,
    FileSystemUtils? fileSystemUtils,
    Logger? logger,
    Platform? platform,
    String? presetPluginsPath,
    ProcessManager? processManager,
    String studioAppName = 'AndroidStudio',
    ToolContext? toolContext,
    Version? version,
  }) {
    final Platform resolvedPlatform = platform ?? toolContext?.platform ?? const LocalPlatform();
    final FileSystem resolvedFileSystem =
        fileSystem ?? toolContext?.fs ?? _createDefaultFileSystem(resolvedPlatform);
    final FileSystemUtils resolvedFileSystemUtils =
        fileSystemUtils ??
        toolContext?.fileSystemUtils ??
        FileSystemUtils(fileSystem: resolvedFileSystem, platform: resolvedPlatform);
    final Logger resolvedLogger =
        logger ?? toolContext?.logger ?? _createDefaultLogger(resolvedPlatform);
    final ProcessManager resolvedProcessManager =
        processManager ?? toolContext?.processManager ?? const LocalProcessManager();
    return AndroidStudio._(
      directory,
      configuredPath: configuredPath,
      fileSystem: resolvedFileSystem,
      fileSystemUtils: resolvedFileSystemUtils,
      logger: resolvedLogger,
      platform: resolvedPlatform,
      presetPluginsPath: presetPluginsPath,
      processManager: resolvedProcessManager,
      studioAppName: studioAppName,
      version: version,
    );
  }

  AndroidStudio._(
    this.directory, {
    required this._fileSystem,
    required this._fileSystemUtils,
    required Logger logger,
    required this._platform,
    required ProcessManager processManager,
    this.configuredPath,
    this.presetPluginsPath,
    this.studioAppName = 'AndroidStudio',
    this.version,
  }) : _processManager = processManager,
       _processUtils = ProcessUtils(logger: logger, processManager: processManager) {
    _initAndValidate();
  }

  static AndroidStudio? fromMacOSBundle(
    String bundlePath, {
    String? configuredPath,
    FileSystem? fileSystem,
    FileSystemUtils? fileSystemUtils,
    Logger? logger,
    Platform? platform,
    PlistParser? plistParser,
    ProcessManager? processManager,
    ToolContext? toolContext,
  }) {
    final Platform resolvedPlatform = platform ?? toolContext?.platform ?? const LocalPlatform();
    final FileSystem resolvedFileSystem =
        fileSystem ?? toolContext?.fs ?? _createDefaultFileSystem(resolvedPlatform);
    final FileSystemUtils resolvedFileSystemUtils =
        fileSystemUtils ??
        toolContext?.fileSystemUtils ??
        FileSystemUtils(fileSystem: resolvedFileSystem, platform: resolvedPlatform);
    final Logger resolvedLogger =
        logger ?? toolContext?.logger ?? _createDefaultLogger(resolvedPlatform);
    final ProcessManager resolvedProcessManager =
        processManager ?? toolContext?.processManager ?? const LocalProcessManager();
    final PlistParser resolvedPlistParser =
        plistParser ??
        PlistParser(
          fileSystem: resolvedFileSystem,
          logger: resolvedLogger,
          processManager: resolvedProcessManager,
        );

    final String studioPath = resolvedFileSystem.path.join(bundlePath, 'Contents');
    final String plistFile = resolvedFileSystem.path.join(studioPath, 'Info.plist');
    final Map<String, Object> plistValues = resolvedPlistParser.parseFile(plistFile);
    // If we've found a JetBrainsToolbox wrapper, ignore it.
    if (plistValues.containsKey('JetBrainsToolboxApp')) {
      return null;
    }

    final versionString = plistValues[PlistParser.kCFBundleShortVersionStringKey] as String?;

    Version? version;
    if (versionString != null) {
      version = _parseVersion(versionString);
    }

    String? pathsSelectorValue;
    if (castStringKeyedMap(plistValues['JVMOptions']) case final jvmOptions?) {
      if (castStringKeyedMap(jvmOptions['Properties']) case final jvmProperties?) {
        pathsSelectorValue = jvmProperties['idea.paths.selector'] as String?;
      }
    }

    final int? major = version?.major;
    final int? minor = version?.minor;
    String? presetPluginsPath;
    final String? homeDirPath = resolvedFileSystemUtils.homeDirPath;
    if (homeDirPath != null && pathsSelectorValue != null) {
      if (major != null && major >= 4 && minor != null && minor >= 1) {
        presetPluginsPath = resolvedFileSystem.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'Google',
          pathsSelectorValue,
        );
      } else {
        presetPluginsPath = resolvedFileSystem.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          pathsSelectorValue,
        );
      }
    }
    return AndroidStudio(
      studioPath,
      configuredPath: configuredPath,
      fileSystem: resolvedFileSystem,
      fileSystemUtils: resolvedFileSystemUtils,
      logger: resolvedLogger,
      platform: resolvedPlatform,
      presetPluginsPath: presetPluginsPath,
      processManager: resolvedProcessManager,
      toolContext: toolContext,
      version: version,
    );
  }

  static AndroidStudio? fromHomeDot(
    Directory homeDotDir, {
    FileSystem? fileSystem,
    FileSystemUtils? fileSystemUtils,
    Logger? logger,
    Platform? platform,
    ProcessManager? processManager,
    ToolContext? toolContext,
  }) {
    final FileSystem resolvedFileSystem = fileSystem ?? toolContext?.fs ?? homeDotDir.fileSystem;
    final Match? versionMatch = _dotHomeStudioVersionMatcher.firstMatch(homeDotDir.basename);
    if (versionMatch?.groupCount != 2) {
      return null;
    }
    final Version? version = Version.parse(versionMatch![2]);
    final String? studioAppName = versionMatch[1];
    if (studioAppName == null || version == null) {
      return null;
    }

    final int major = version.major;
    final int minor = version.minor;

    // The install path is written in a .home text file,
    // it location is in <base dir>/.home for Android Studio >= 4.1
    // and <base dir>/system/.home for Android Studio < 4.1
    String dotHomeFilePath;

    if (major >= 4 && minor >= 1) {
      dotHomeFilePath = resolvedFileSystem.path.join(homeDotDir.path, '.home');
    } else {
      dotHomeFilePath = resolvedFileSystem.path.join(homeDotDir.path, 'system', '.home');
    }

    String? installPath;

    try {
      installPath = resolvedFileSystem.file(dotHomeFilePath).readAsStringSync();
    } on Exception {
      // ignored, installPath will be null, which is handled below
    }

    if (installPath != null && resolvedFileSystem.isDirectorySync(installPath)) {
      return AndroidStudio(
        installPath,
        fileSystem: resolvedFileSystem,
        fileSystemUtils: fileSystemUtils,
        logger: logger,
        platform: platform,
        processManager: processManager,
        studioAppName: studioAppName,
        toolContext: toolContext,
        version: version,
      );
    }
    return null;
  }

  final String directory;
  final String studioAppName;

  /// The version of Android Studio.
  ///
  /// A null value represents an unknown version.
  final Version? version;

  final String? configuredPath;
  final String? presetPluginsPath;

  final FileSystem _fileSystem;
  final FileSystemUtils _fileSystemUtils;
  final Platform _platform;
  final ProcessManager _processManager;
  final ProcessUtils _processUtils;

  String? _javaPath;
  var _isValid = false;
  final _validationMessages = <String>[];

  /// The path of the JDK bundled with Android Studio.
  ///
  /// This will be null if the bundled JDK could not be found or run.
  ///
  /// If you looking to invoke the java binary or add it to the system
  /// environment variables, consider using the [Java] class instead.
  String? get javaPath => _javaPath;

  bool get isValid => _isValid;

  String? get pluginsPath {
    if (presetPluginsPath != null) {
      return presetPluginsPath!;
    }

    // JetBrains Toolbox writes plugins to a sibling directory with a ".plugins" suffix.
    if (!_platform.isMacOS) {
      final toolboxPluginsPath = '$directory.plugins';
      if (_fileSystem.directory(toolboxPluginsPath).existsSync()) {
        return toolboxPluginsPath;
      }
    }

    if (version == null) {
      return null;
    }

    final int major = version!.major;
    final int minor = version!.minor;
    final String? homeDirPath = _fileSystemUtils.homeDirPath;
    if (homeDirPath == null) {
      return null;
    }
    if (_platform.isMacOS) {
      /// plugin path of Android Studio has been changed after version 4.1.
      if (major >= 4 && minor >= 1) {
        return _fileSystem.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'Google',
          'AndroidStudio$major.$minor',
        );
      } else {
        return _fileSystem.path.join(
          homeDirPath,
          'Library',
          'Application Support',
          'AndroidStudio$major.$minor',
        );
      }
    } else {
      if (major >= 4 && minor >= 1 && _platform.isLinux) {
        return _fileSystem.path.join(
          homeDirPath,
          '.local',
          'share',
          'Google',
          '$studioAppName$major.$minor',
        );
      }

      return _fileSystem.path.join(
        homeDirPath,
        '.$studioAppName$major.$minor',
        'config',
        'plugins',
      );
    }
  }

  List<String> get validationMessages => _validationMessages;

  /// Locates the newest, valid version of Android Studio.
  ///
  /// In the case that `--android-studio-dir` is configured, the version of
  /// Android Studio found at that location is always returned, even if it is
  /// invalid.
  static AndroidStudio? latestValid({
    Config? config,
    FileSystem? fileSystem,
    FileSystemUtils? fileSystemUtils,
    Logger? logger,
    Platform? platform,
    PlistParser? plistParser,
    ProcessManager? processManager,
    ToolContext? toolContext,
  }) {
    final Platform resolvedPlatform = platform ?? toolContext?.platform ?? const LocalPlatform();
    final FileSystem resolvedFileSystem =
        fileSystem ?? toolContext?.fs ?? _createDefaultFileSystem(resolvedPlatform);
    final FileSystemUtils resolvedFileSystemUtils =
        fileSystemUtils ??
        toolContext?.fileSystemUtils ??
        FileSystemUtils(fileSystem: resolvedFileSystem, platform: resolvedPlatform);
    final Logger resolvedLogger =
        logger ?? toolContext?.logger ?? _createDefaultLogger(resolvedPlatform);
    final ProcessManager resolvedProcessManager =
        processManager ?? toolContext?.processManager ?? const LocalProcessManager();
    final Config resolvedConfig =
        config ??
        toolContext?.config ??
        Config(
          Config.kFlutterSettings,
          fileSystem: resolvedFileSystem,
          logger: resolvedLogger,
          platform: resolvedPlatform,
        );

    final Directory? configuredStudioDir = _configuredDir(
      config: resolvedConfig,
      fileSystem: resolvedFileSystem,
    );

    // Find all available Studio installations.
    final studios = <AndroidStudio>[
      ...allInstalled(
        config: resolvedConfig,
        fileSystem: resolvedFileSystem,
        fileSystemUtils: resolvedFileSystemUtils,
        logger: resolvedLogger,
        platform: resolvedPlatform,
        plistParser: plistParser,
        processManager: resolvedProcessManager,
        toolContext: toolContext,
      ),
    ];
    if (studios.isEmpty) {
      return null;
    }

    final AndroidStudio? manuallyConfigured = studios
        .where(
          (AndroidStudio studio) =>
              studio.configuredPath != null &&
              configuredStudioDir != null &&
              _pathsAreEqual(
                studio.configuredPath!,
                configuredStudioDir.path,
                fileSystem: resolvedFileSystem,
              ),
        )
        .firstOrNull;

    if (manuallyConfigured != null) {
      return manuallyConfigured;
    }

    AndroidStudio? newest;
    for (final AndroidStudio studio in studios.where((AndroidStudio s) => s.isValid)) {
      if (newest == null) {
        newest = studio;
        continue;
      }

      // We prefer installs with known versions.
      if (studio.version != null && newest.version == null) {
        newest = studio;
      } else if (studio.version != null &&
          newest.version != null &&
          studio.version! > newest.version!) {
        newest = studio;
      } else if (studio.version == null &&
          newest.version == null &&
          studio.directory.compareTo(newest.directory) > 0) {
        newest = studio;
      }
    }

    return newest;
  }

  static List<AndroidStudio> allInstalled({
    Config? config,
    FileSystem? fileSystem,
    FileSystemUtils? fileSystemUtils,
    Logger? logger,
    Platform? platform,
    PlistParser? plistParser,
    ProcessManager? processManager,
    ToolContext? toolContext,
  }) {
    final Platform resolvedPlatform = platform ?? toolContext?.platform ?? const LocalPlatform();
    final FileSystem resolvedFileSystem =
        fileSystem ?? toolContext?.fs ?? _createDefaultFileSystem(resolvedPlatform);
    final FileSystemUtils resolvedFileSystemUtils =
        fileSystemUtils ??
        toolContext?.fileSystemUtils ??
        FileSystemUtils(fileSystem: resolvedFileSystem, platform: resolvedPlatform);
    final Logger resolvedLogger =
        logger ?? toolContext?.logger ?? _createDefaultLogger(resolvedPlatform);
    final ProcessManager resolvedProcessManager =
        processManager ?? toolContext?.processManager ?? const LocalProcessManager();
    final Config resolvedConfig =
        config ??
        toolContext?.config ??
        Config(
          Config.kFlutterSettings,
          fileSystem: resolvedFileSystem,
          logger: resolvedLogger,
          platform: resolvedPlatform,
        );

    return resolvedPlatform.isMacOS
        ? _allMacOS(
            config: resolvedConfig,
            fileSystem: resolvedFileSystem,
            fileSystemUtils: resolvedFileSystemUtils,
            logger: resolvedLogger,
            platform: resolvedPlatform,
            plistParser: plistParser,
            processManager: resolvedProcessManager,
            toolContext: toolContext,
          )
        : _allLinuxOrWindows(
            config: resolvedConfig,
            fileSystem: resolvedFileSystem,
            fileSystemUtils: resolvedFileSystemUtils,
            logger: resolvedLogger,
            platform: resolvedPlatform,
            processManager: resolvedProcessManager,
            toolContext: toolContext,
          );
  }

  static List<AndroidStudio> _allMacOS({
    required Config config,
    required FileSystem fileSystem,
    required FileSystemUtils fileSystemUtils,
    required Logger logger,
    required Platform platform,
    required ProcessManager processManager,
    PlistParser? plistParser,
    ToolContext? toolContext,
  }) {
    final PlistParser resolvedPlistParser =
        plistParser ??
        PlistParser(fileSystem: fileSystem, logger: logger, processManager: processManager);
    final candidatePaths = <FileSystemEntity>[];

    void checkForStudio(String path) {
      if (!fileSystem.isDirectorySync(path)) {
        return;
      }
      try {
        final Iterable<Directory> directories = fileSystem
            .directory(path)
            .listSync(followLinks: false)
            .whereType<Directory>();
        for (final directory in directories) {
          final String name = directory.basename;
          // An exact match, or something like 'Android Studio 3.0 Preview.app'.
          if (name.startsWith('Android Studio') && name.endsWith('.app')) {
            candidatePaths.add(directory);
          } else if (!directory.path.endsWith('.app')) {
            checkForStudio(directory.path);
          }
        }
      } on Exception catch (e) {
        logger.printTrace('Exception while looking for Android Studio: $e');
      }
    }

    checkForStudio('/Applications');
    final String? homeDirPath = fileSystemUtils.homeDirPath;
    if (homeDirPath != null) {
      checkForStudio(fileSystem.path.join(homeDirPath, 'Applications'));
    }

    Directory? configuredStudioDir = _configuredDir(config: config, fileSystem: fileSystem);
    if (configuredStudioDir != null) {
      if (configuredStudioDir.basename == 'Contents') {
        configuredStudioDir = configuredStudioDir.parent;
      }
      if (!candidatePaths.any(
        (FileSystemEntity e) =>
            _pathsAreEqual(e.path, configuredStudioDir!.path, fileSystem: fileSystem),
      )) {
        candidatePaths.add(configuredStudioDir);
      }
    }

    // Query Spotlight for unexpected installation locations.
    // Spotlight (mds_stores/mdworker) can become unresponsive or hang during heavy indexing on macOS.
    // Wrap mdfind in a shell execution with a 3-second timeout to prevent flutter doctor
    // and flutter daemon from hanging indefinitely (https://github.com/flutter/flutter/issues/189177).
    var spotlightQueryResult = '';
    try {
      final ProcessResult spotlightResult = processManager.runSync(<String>[
        'sh',
        '-c',
        // com.google.android.studio, com.google.android.studio-EAP
        kSpotlightMdfindCommand,
      ]);
      if (spotlightResult.exitCode != 0) {
        logger.printTrace(
          'Spotlight mdfind query failed or timed out with exit code ${spotlightResult.exitCode}',
        );
      }
      spotlightQueryResult = spotlightResult.stdout as String;
    } on ProcessException {
      // The Spotlight query is a nice-to-have, continue checking known installation locations.
    }
    for (final String studioPath in LineSplitter.split(spotlightQueryResult)) {
      final Directory appBundle = fileSystem.directory(studioPath);
      if (!candidatePaths.any((FileSystemEntity e) => e.path == studioPath)) {
        candidatePaths.add(appBundle);
      }
    }

    return candidatePaths
        .map<AndroidStudio?>((FileSystemEntity e) {
          if (configuredStudioDir == null) {
            return AndroidStudio.fromMacOSBundle(
              e.path,
              fileSystem: fileSystem,
              fileSystemUtils: fileSystemUtils,
              logger: logger,
              platform: platform,
              plistParser: resolvedPlistParser,
              processManager: processManager,
              toolContext: toolContext,
            );
          }

          return AndroidStudio.fromMacOSBundle(
            e.path,
            configuredPath: _pathsAreEqual(configuredStudioDir.path, e.path, fileSystem: fileSystem)
                ? configuredStudioDir.path
                : null,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            logger: logger,
            platform: platform,
            plistParser: resolvedPlistParser,
            processManager: processManager,
            toolContext: toolContext,
          );
        })
        .whereType<AndroidStudio>()
        .toList();
  }

  static const _idToTitle = <String, String>{
    _androidStudioId: _androidStudioTitle,
    _androidStudioPreviewId: _androidStudioPreviewTitle,
  };

  static List<AndroidStudio> _allLinuxOrWindows({
    required Config config,
    required FileSystem fileSystem,
    required FileSystemUtils fileSystemUtils,
    required Logger logger,
    required Platform platform,
    required ProcessManager processManager,
    ToolContext? toolContext,
  }) {
    final studios = <AndroidStudio>[];

    bool alreadyFoundStudioAt(String path, {Version? newerThan}) {
      return studios.any((AndroidStudio studio) {
        if (studio.directory != path) {
          return false;
        }
        if (newerThan != null) {
          if (studio.version == null) {
            return false;
          }
          return studio.version!.compareTo(newerThan) >= 0;
        }
        return true;
      });
    }

    // Read all $HOME/.AndroidStudio*/system/.home
    // or $HOME/.cache/Google/AndroidStudio*/.home files.
    // There may be several pointing to the same installation,
    // so we grab only the latest one.
    final String? homeDirPath = fileSystemUtils.homeDirPath;

    if (homeDirPath != null && fileSystem.directory(homeDirPath).existsSync()) {
      // >=4.1 has new install location at $HOME/.cache/Google
      final String cacheDirPath = fileSystem.path.join(homeDirPath, '.cache', 'Google');
      final directoriesToSearch = <Directory>[
        fileSystem.directory(homeDirPath),
        if (fileSystem.isDirectorySync(cacheDirPath)) fileSystem.directory(cacheDirPath),
      ];

      final entities = <Directory>[];

      for (final baseDir in directoriesToSearch) {
        final Iterable<Directory> directories = baseDir
            .listSync(followLinks: false)
            .whereType<Directory>();
        entities.addAll(
          directories.where(
            (Directory directory) => _dotHomeStudioVersionMatcher.hasMatch(directory.basename),
          ),
        );
      }

      for (final entity in entities) {
        final AndroidStudio? studio = AndroidStudio.fromHomeDot(
          entity,
          fileSystem: fileSystem,
          fileSystemUtils: fileSystemUtils,
          logger: logger,
          platform: platform,
          processManager: processManager,
          toolContext: toolContext,
        );
        if (studio != null && !alreadyFoundStudioAt(studio.directory, newerThan: studio.version)) {
          studios.removeWhere((AndroidStudio other) => other.directory == studio.directory);
          studios.add(studio);
        }
      }
    }

    // Discover Android Studio > 4.1
    if (platform.isWindows && platform.environment.containsKey('LOCALAPPDATA')) {
      final Directory cacheDir = fileSystem.directory(
        fileSystem.path.join(platform.environment['LOCALAPPDATA']!, 'Google'),
      );
      if (!cacheDir.existsSync()) {
        return studios;
      }
      for (final Directory dir in cacheDir.listSync().whereType<Directory>()) {
        final String name = fileSystem.path.basename(dir.path);
        _idToTitle.forEach((String id, String title) {
          if (name.startsWith(id)) {
            final String version = name.substring(id.length);
            String? installPath;

            try {
              installPath = fileSystem
                  .file(fileSystem.path.join(dir.path, '.home'))
                  .readAsStringSync();
            } on FileSystemException {
              // ignored
            }
            if (installPath != null && fileSystem.isDirectorySync(installPath)) {
              final studio = AndroidStudio(
                installPath,
                fileSystem: fileSystem,
                fileSystemUtils: fileSystemUtils,
                logger: logger,
                platform: platform,
                processManager: processManager,
                studioAppName: title,
                toolContext: toolContext,
                version: Version.parse(version),
              );
              if (!alreadyFoundStudioAt(studio.directory, newerThan: studio.version)) {
                studios.removeWhere(
                  (AndroidStudio other) =>
                      _pathsAreEqual(other.directory, studio.directory, fileSystem: fileSystem),
                );
                studios.add(studio);
              }
            }
          }
        });
      }
    }

    final configuredStudioDir = config.getValue('android-studio-dir') as String?;
    if (configuredStudioDir != null) {
      final AndroidStudio? matchingAlreadyFoundInstall = studios
          .where(
            (AndroidStudio other) =>
                _pathsAreEqual(configuredStudioDir, other.directory, fileSystem: fileSystem),
          )
          .firstOrNull;
      if (matchingAlreadyFoundInstall != null) {
        studios.remove(matchingAlreadyFoundInstall);
        studios.add(
          AndroidStudio(
            configuredStudioDir,
            configuredPath: configuredStudioDir,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            logger: logger,
            platform: platform,
            processManager: processManager,
            toolContext: toolContext,
            version: matchingAlreadyFoundInstall.version,
          ),
        );
      } else {
        studios.add(
          AndroidStudio(
            configuredStudioDir,
            configuredPath: configuredStudioDir,
            fileSystem: fileSystem,
            fileSystemUtils: fileSystemUtils,
            logger: logger,
            platform: platform,
            processManager: processManager,
            toolContext: toolContext,
          ),
        );
      }
    }

    if (platform.isLinux) {
      void checkWellKnownPath(String path) {
        if (fileSystem.isDirectorySync(path) && !alreadyFoundStudioAt(path)) {
          studios.add(
            AndroidStudio(
              path,
              fileSystem: fileSystem,
              fileSystemUtils: fileSystemUtils,
              logger: logger,
              platform: platform,
              processManager: processManager,
              toolContext: toolContext,
            ),
          );
        }
      }

      // Add /opt/android-studio and $HOME/android-studio, if they exist.
      checkWellKnownPath('/opt/android-studio');
      checkWellKnownPath('${fileSystemUtils.homeDirPath}/android-studio');
    }
    return studios;
  }

  /// Gets the Android Studio install directory set by the user, if it is configured.
  ///
  /// The returned [Directory], if not null, is guaranteed to have existed during
  /// this function's execution.
  static Directory? _configuredDir({required Config config, required FileSystem fileSystem}) {
    final configuredPath = config.getValue('android-studio-dir') as String?;
    if (configuredPath == null) {
      return null;
    }
    final Directory result = fileSystem.directory(configuredPath);

    bool? configuredStudioPathExists;
    String? exceptionMessage;
    try {
      configuredStudioPathExists = result.existsSync();
    } on FileSystemException catch (e) {
      exceptionMessage = e.toString();
    }

    if (configuredStudioPathExists == false || exceptionMessage != null) {
      throwToolExit('''
Could not find the Android Studio installation at the manually configured path "$configuredPath".
${exceptionMessage == null ? '' : 'Encountered exception: $exceptionMessage\n\n'}
Please verify that the path is correct and update it by running this command: flutter config --android-studio-dir '<path>'
To have flutter search for Android Studio installations automatically, remove
the configured path by running this command: flutter config --android-studio-dir
''');
    }

    return result;
  }

  static String? extractStudioPlistValueWithMatcher(String plistValue, RegExp keyMatcher) {
    return keyMatcher.stringMatch(plistValue)?.split('=').last.trim().replaceAll('"', '');
  }

  void _initAndValidate() {
    _isValid = false;
    _validationMessages.clear();

    if (configuredPath != null) {
      _validationMessages.add('android-studio-dir = $configuredPath');
    }

    if (!_fileSystem.isDirectorySync(directory)) {
      _validationMessages.add('Android Studio not found at $directory');
      return;
    }

    final String javaPath;
    if (_platform.isMacOS) {
      if (version != null && version!.major < 2020) {
        javaPath = _fileSystem.path.join(directory, 'jre', 'jdk', 'Contents', 'Home');
      } else if (version != null && version!.major < 2022) {
        javaPath = _fileSystem.path.join(directory, 'jre', 'Contents', 'Home');
        // See https://github.com/flutter/flutter/issues/125246 for more context.
      } else {
        javaPath = _fileSystem.path.join(directory, 'jbr', 'Contents', 'Home');
      }
    } else {
      if (version != null && version!.major < 2022) {
        javaPath = _fileSystem.path.join(directory, 'jre');
      } else {
        javaPath = _fileSystem.path.join(directory, 'jbr');
      }
    }
    final String javaExecutable = _fileSystem.path.join(javaPath, 'bin', 'java');
    if (!_processManager.canRun(javaExecutable)) {
      _validationMessages.add('Unable to find bundled Java version.');
    } else {
      RunResult? result;
      try {
        result = _processUtils.runSync(<String>[javaExecutable, '-version']);
      } on ProcessException catch (e) {
        _validationMessages.add('Failed to run Java: $e');
      }
      if (result != null && result.exitCode == 0) {
        final versionLines = <String>[...result.stderr.split('\n')];
        final String javaVersion = versionLines.length >= 2 ? versionLines[1] : versionLines[0];
        _validationMessages.add('Java version $javaVersion');
        _javaPath = javaPath;
        _isValid = true;
      } else {
        _validationMessages.add('Unable to determine bundled Java version.');
      }
    }
  }

  static Version? _parseVersion(String text) {
    // Matches the version string for Preview builds on macOS.
    // Example match: EAP AI-242.21829.142.2422.12358220
    // We try to capture "2422" here, which can be translated to a
    // more human-friendly "24.2.2".
    final eapVersionPattern = RegExp(r'EAP\s+[A-Z]{2}-\d+\.\d+\.\d+\.(\d+)\.\d+');
    final Match? eapVersionMatch = eapVersionPattern.firstMatch(text);

    if (eapVersionMatch == null) {
      return Version.parse(text);
    }

    final String? rawVersionMatch = eapVersionMatch.group(1);

    // length of 4 is because that how version is encrypted: first two digits
    // for year (part of major version), third for minor version, fourth for patch.
    if (rawVersionMatch == null || rawVersionMatch.length != 4) {
      return null;
    }

    final int? major = int.tryParse('20${rawVersionMatch[0]}${rawVersionMatch[1]}');
    final int? minor = int.tryParse(rawVersionMatch[2]);
    final int? patch = int.tryParse(rawVersionMatch[3]);
    if (major == null || minor == null || patch == null) {
      return null;
    }
    return Version(major, minor, patch);
  }

  @override
  String toString() => 'Android Studio ($version)';
}

bool _pathsAreEqual(String path, String other, {required FileSystem fileSystem}) {
  return fileSystem.path.canonicalize(path) == fileSystem.path.canonicalize(other);
}
