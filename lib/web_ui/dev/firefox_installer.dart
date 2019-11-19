// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'common.dart';
import 'environment.dart';

class FirefoxArgParser extends BrowserArgParser {
  static final FirefoxArgParser _singletonInstance = FirefoxArgParser._();

  /// The [ChromeArgParser] singleton.
  static FirefoxArgParser get instance => _singletonInstance;

  String _version;

  FirefoxArgParser._();

  @override
  void populateOptions(ArgParser argParser) {
    final YamlMap browserLock = BrowserLock.instance.configuration;
    String firefoxVersion = browserLock['firefox']['version'];

    argParser
      ..addOption(
        'firefox-version',
        defaultsTo: '$firefoxVersion',
        help: 'The Firefox version to use while running tests. If the requested '
            'version has not been installed, it will be downloaded and installed '
            'automatically. Value "latest" will use the latest '
            'stable build of Firefox, installing it if necessary. Value "system" '
            'will use the manually installed version of Firefox on this computer.',
      );
  }

  @override
  void parseOptions(ArgResults argResults) {
    _version = argResults['firefox-version'];
  }

  @override
  String get version => _version;
}

/// Returns the installation of Firefox, installing it if necessary.
///
/// If [requestedVersion] is null, uses the version specified on the
/// command-line. If not specified on the command-line, uses the version
/// specified in the "browser_lock.yaml" file.
///
/// If [requestedVersion] is not null, installs that version. The value
/// may be "latest" (the latest stable Firefox version), "system"
/// (manually installed Firefox on the current operating system), or an
/// exact version number such as 69.0.3. Versions of Firefox can be found here:
///
/// https://download-installer.cdn.mozilla.net/pub/firefox/releases/
Future<BrowserInstallation> getOrInstallFirefox(
  String requestedVersion, {
  StringSink infoLog,
}) async {
  // These tests are aimed to run only on the Linux containers in Cirrus.
  // Therefore Firefox installation is implemented only for Linux now.
  if (!io.Platform.isLinux) {
    throw UnimplementedError();
  }

  infoLog ??= io.stdout;

  if (requestedVersion == 'system') {
    return BrowserInstallation(
      version: 'system',
      executable: await _findSystemFirefoxExecutable(),
    );
  }

  FirefoxInstaller installer;
  try {
    installer = requestedVersion == 'latest'
        ? await FirefoxInstaller.latest()
        : FirefoxInstaller(version: requestedVersion);

    if (installer.isInstalled) {
      infoLog.writeln(
          'Installation was skipped because Firefox version ${installer.version} is already installed.');
    } else {
      infoLog.writeln('Installing Firefox version: ${installer.version}');
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

/// Manages the installation of a particular [version] of Firefox.
class FirefoxInstaller {
  factory FirefoxInstaller({
    @required String version,
  }) {
    if (version == 'system') {
      throw BrowserInstallerException(
          'Cannot install system version of Firefox. System Firefox must be installed manually.');
    }
    if (version == 'latest') {
      throw BrowserInstallerException(
          'Expected a concrete Firefox version, but got $version. Maybe use FirefoxInstaller.latest()?');
    }
    final io.Directory firefoxInstallationDir = io.Directory(
      path.join(environment.webUiDartToolDir.path, 'firefox'),
    );
    final io.Directory versionDir = io.Directory(
      path.join(firefoxInstallationDir.path, version),
    );
    return FirefoxInstaller._(
      version: version,
      firefoxInstallationDir: firefoxInstallationDir,
      versionDir: versionDir,
    );
  }

  static Future<FirefoxInstaller> latest() async {
    final String latestVersion = await fetchLatestFirefoxVersion();
    return FirefoxInstaller(version: latestVersion);
  }

  FirefoxInstaller._({
    @required this.version,
    @required this.firefoxInstallationDir,
    @required this.versionDir,
  });

  /// Firefox version managed by this installer.
  final String version;

  /// HTTP client used to download Firefox.
  final Client client = Client();

  /// Root directory that contains Firefox versions.
  final io.Directory firefoxInstallationDir;

  /// Installation directory for Firefox of the requested [version].
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
      executable: PlatformBinding.instance.getFirefoxExecutablePath(versionDir),
    );
  }

  /// Install the browser by downloading from the web.
  Future<void> install() async {
    final io.File downloadedFile = await _download();
    await _uncompress(downloadedFile);
    downloadedFile.deleteSync();
  }

  /// Downloads the browser version from web.
  /// See [version].
  Future<io.File> _download() async {
    if (versionDir.existsSync()) {
      versionDir.deleteSync(recursive: true);
    }

    versionDir.createSync(recursive: true);
    final String url = PlatformBinding.instance.getFirefoxDownloadUrl(version);
    final StreamedResponse download = await client.send(Request(
      'GET',
      Uri.parse(url),
    ));

    final io.File downloadedFile =
        io.File(path.join(versionDir.path, 'firefox-${version}.tar.bz2'));
    await download.stream.pipe(downloadedFile.openWrite());

    return downloadedFile;
  }

  /// Uncompress the downloaded browser files.
  /// See [version].
  Future<void> _uncompress(io.File downloadedFile) async {
    final io.ProcessResult unzipResult = await io.Process.run('tar', <String>[
      '-x',
      '-f',
      downloadedFile.path,
      '-C',
      versionDir.path,
    ]);

    if (unzipResult.exitCode != 0) {
      throw BrowserInstallerException(
          'Failed to unzip the downloaded Firefox archive ${downloadedFile.path}.\n'
          'The unzip process exited with code ${unzipResult.exitCode}.');
    }
  }

  void close() {
    client.close();
  }
}

Future<String> _findSystemFirefoxExecutable() async {
  final io.ProcessResult which =
      await io.Process.run('which', <String>['firefox']);

  if (which.exitCode != 0) {
    throw BrowserInstallerException(
        'Failed to locate system Firefox installation.');
  }

  return which.stdout;
}

/// Fetches the latest available Chrome build version.
Future<String> fetchLatestFirefoxVersion() async {
  final RegExp forFirefoxVersion = RegExp("firefox-[0-9.]\+[0-9]");
  final io.HttpClientRequest request = await io.HttpClient()
      .getUrl(Uri.parse(PlatformBinding.instance.getFirefoxLatestVersionUrl()));
  request.followRedirects = false;
  // We will parse the HttpHeaders to find the redirect location.
  final io.HttpClientResponse response = await request.close();

  final String location = response.headers.value('location');
  final String version = forFirefoxVersion.stringMatch(location);

  return version.substring(version.lastIndexOf('-') + 1);
}
