// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'common.dart';
import 'environment.dart';
import 'exceptions.dart';

class ChromeArgParser extends BrowserArgParser {
  static final ChromeArgParser _singletonInstance = ChromeArgParser._();

  /// The [ChromeArgParser] singleton.
  static ChromeArgParser get instance => _singletonInstance;

  String _version;

  ChromeArgParser._();

  @override
  void populateOptions(ArgParser argParser) {
    final YamlMap browserLock = BrowserLock.instance.configuration;
    final int pinnedChromeVersion =
        PlatformBinding.instance.getChromeBuild(browserLock);

    argParser
      ..addOption(
        'chrome-version',
        defaultsTo: '$pinnedChromeVersion',
        help: 'The Chrome version to use while running tests. If the requested '
            'version has not been installed, it will be downloaded and installed '
            'automatically. A specific Chrome build version number, such as 695653, '
            'will use that version of Chrome. Value "latest" will use the latest '
            'available build of Chrome, installing it if necessary. Value "system" '
            'will use the manually installed version of Chrome on this computer.',
      );
  }

  @override
  void parseOptions(ArgResults argResults) {
    _version = argResults['chrome-version'] as String;
  }

  @override
  String get version => _version;
}

/// Returns the installation of Chrome, installing it if necessary.
///
/// If [requestedVersion] is null, uses the version specified on the
/// command-line. If not specified on the command-line, uses the version
/// specified in the "browser_lock.yaml" file.
///
/// If [requestedVersion] is not null, installs that version. The value
/// may be "latest" (the latest available build of Chrome), "system"
/// (manually installed Chrome on the current operating system), or an
/// exact build nuber, such as 695653. Build numbers can be found here:
///
/// https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/
Future<BrowserInstallation> getOrInstallChrome(
  String requestedVersion, {
  StringSink infoLog,
}) async {
  infoLog ??= io.stdout;

  if (requestedVersion == 'system') {
    return BrowserInstallation(
      version: 'system',
      executable: await _findSystemChromeExecutable(),
    );
  }

  ChromeInstaller installer;
  try {
    installer = requestedVersion == 'latest'
        ? await ChromeInstaller.latest()
        : ChromeInstaller(version: requestedVersion);

    if (installer.isInstalled) {
      infoLog.writeln(
          'Installation was skipped because Chrome version ${installer.version} is already installed.');
    } else {
      infoLog.writeln('Installing Chrome version: ${installer.version}');
      await installer.install();
      final BrowserInstallation installation = installer.getInstallation();
      infoLog.writeln(
          'Installations complete. To launch it run ${installation.executable}');
    }
    return installer.getInstallation();
  } finally {
    installer?.close();
  }
}

Future<String> _findSystemChromeExecutable() async {
  final io.ProcessResult which =
      await io.Process.run('which', <String>['google-chrome']);

  if (which.exitCode != 0) {
    throw BrowserInstallerException(
        'Failed to locate system Chrome installation.');
  }

  return which.stdout as String;
}

/// Manages the installation of a particular [version] of Chrome.
class ChromeInstaller {
  factory ChromeInstaller({
    @required String version,
  }) {
    if (version == 'system') {
      throw BrowserInstallerException(
          'Cannot install system version of Chrome. System Chrome must be installed manually.');
    }
    if (version == 'latest') {
      throw BrowserInstallerException(
          'Expected a concrete Chromer version, but got $version. Maybe use ChromeInstaller.latest()?');
    }
    final io.Directory chromeInstallationDir = io.Directory(
      path.join(environment.webUiDartToolDir.path, 'chrome'),
    );
    final io.Directory versionDir = io.Directory(
      path.join(chromeInstallationDir.path, version),
    );
    return ChromeInstaller._(
      version: version,
      chromeInstallationDir: chromeInstallationDir,
      versionDir: versionDir,
    );
  }

  static Future<ChromeInstaller> latest() async {
    final String latestVersion = await fetchLatestChromeVersion();
    return ChromeInstaller(version: latestVersion);
  }

  ChromeInstaller._({
    @required this.version,
    @required this.chromeInstallationDir,
    @required this.versionDir,
  });

  /// Chrome version managed by this installer.
  final String version;

  /// HTTP client used to download Chrome.
  final Client client = Client();

  /// Root directory that contains Chrome versions.
  final io.Directory chromeInstallationDir;

  /// Installation directory for Chrome of the requested [version].
  final io.Directory versionDir;

  bool get isInstalled {
    return versionDir.existsSync();
  }

  BrowserInstallation getInstallation() {
    if (!isInstalled) {
      return null;
    }

    return BrowserInstallation(
      version: version,
      executable: PlatformBinding.instance.getChromeExecutablePath(versionDir),
    );
  }

  Future<void> install() async {
    if (versionDir.existsSync()) {
      versionDir.deleteSync(recursive: true);
    }

    versionDir.createSync(recursive: true);
    final String url = PlatformBinding.instance.getChromeDownloadUrl(version);
    final StreamedResponse download = await client.send(Request(
      'GET',
      Uri.parse(url),
    ));

    final io.File downloadedFile =
        io.File(path.join(versionDir.path, 'chrome.zip'));
    await download.stream.pipe(downloadedFile.openWrite());

    final io.ProcessResult unzipResult = await io.Process.run('unzip', <String>[
      downloadedFile.path,
      '-d',
      versionDir.path,
    ]);

    if (unzipResult.exitCode != 0) {
      throw BrowserInstallerException(
          'Failed to unzip the downloaded Chrome archive ${downloadedFile.path}.\n'
          'With the version path ${versionDir.path}\n'
          'The unzip process exited with code ${unzipResult.exitCode}.');
    }

    downloadedFile.deleteSync();
  }

  void close() {
    client.close();
  }
}

/// Fetches the latest available Chrome build version.
Future<String> fetchLatestChromeVersion() async {
  final Client client = Client();
  try {
    final Response response = await client.get(
        'https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2FLAST_CHANGE?alt=media');
    if (response.statusCode != 200) {
      throw BrowserInstallerException(
          'Failed to fetch latest Chrome version. Server returned status code ${response.statusCode}');
    }
    return response.body;
  } finally {
    client.close();
  }
}

/// Get the Chrome Driver version for the system Chrome.
// TODO(nurhan): https://github.com/flutter/flutter/issues/53179
Future<String> queryChromeDriverVersion() async {
  final int chromeVersion = await _querySystemChromeMajorVersion();
  final io.File lockFile = io.File(
      path.join(environment.webUiRootDir.path, 'dev', 'driver_version.yaml'));
  YamlMap _configuration = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  final String chromeDriverVersion =
      _configuration['chrome'][chromeVersion] as String;
  return chromeDriverVersion;
}

Future<int> _querySystemChromeMajorVersion() async {
  String chromeExecutable = '';
  if (io.Platform.isLinux) {
    chromeExecutable = 'google-chrome';
  } else if (io.Platform.isMacOS) {
    chromeExecutable = await _findChromeExecutableOnMac();
  } else {
    throw UnimplementedError('Web installers only work on Linux and Mac.');
  }

  final io.ProcessResult versionResult =
      await io.Process.run('$chromeExecutable', <String>['--version']);

  if (versionResult.exitCode != 0) {
    throw Exception('Failed to locate system Chrome.');
  }
  // The output looks like: Google Chrome 79.0.3945.36.
  final String output = versionResult.stdout as String;

  print('INFO: chrome version in use $output');

  // Version number such as 79.0.3945.36.
  try {
    final String versionAsString = output.trim().split(' ').last;
    final String majorVersion = versionAsString.split('.')[0];
    return int.parse(majorVersion);
  } catch (e) {
    throw Exception(
        'Was expecting a version of the form Google Chrome 79.0.3945.36., '
        'received $output');
  }
}

/// Find Google Chrome App on Mac.
Future<String> _findChromeExecutableOnMac() async {
  io.Directory chromeDirectory = io.Directory('/Applications')
      .listSync()
      .whereType<io.Directory>()
      .firstWhere(
        (d) => path.basename(d.path).endsWith('Chrome.app'),
        orElse: () => throw Exception('Failed to locate system Chrome'),
      );

  final io.File chromeExecutableDir = io.File(
      path.join(chromeDirectory.path, 'Contents', 'MacOS', 'Google Chrome'));

  return chromeExecutableDir.path;
}
