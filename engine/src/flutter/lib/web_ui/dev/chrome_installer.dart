// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'environment.dart';

void addChromeVersionOption(ArgParser argParser) {
  final String pinnedChromeVersion =
      io.File(path.join(environment.webUiRootDir.path, 'dev', 'chrome.lock'))
          .readAsStringSync()
          .trim();

  argParser
    ..addOption(
      'chrome-version',
      defaultsTo: pinnedChromeVersion,
      help: 'The Chrome version to use while running tests. If the requested '
          'version has not been installed, it will be downloaded and installed '
          'automatically. A specific Chrome build version number, such as 695653 '
          'this use that version of Chrome. Value "latest" will use the latest '
          'available build of Chrome, installing it if necessary. Value "system" '
          'will use the manually installed version of Chrome on this computer.',
    );
}

/// Returns the installation of Chrome, installing it if necessary.
///
/// If [requestedVersion] is null, uses the version specified on the
/// command-line. If not specified on the command-line, uses the version
/// specified in the "chrome.lock" file.
///
/// If [requestedVersion] is not null, installs that version. The value
/// may be "latest" (the latest available build of Chrome), "system"
/// (manually installed Chrome on the current operating system), or an
/// exact build nuber, such as 695653. Build numbers can be found here:
///
/// https://commondatastorage.googleapis.com/chromium-browser-snapshots/index.html?prefix=Linux_x64/
Future<ChromeInstallation> getOrInstallChrome(
  String requestedVersion, {
  StringSink infoLog,
}) async {
  infoLog ??= io.stdout;

  if (requestedVersion == 'system') {
    return ChromeInstallation(
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
      infoLog.writeln('Installation was skipped because Chrome version ${installer.version} is already installed.');
    } else {
      infoLog.writeln('Installing Chrome version: ${installer.version}');
      await installer.install();
      final ChromeInstallation installation = installer.getInstallation();
      infoLog.writeln('Installations complete. To launch it run ${installation.executable}');
    }
    return installer.getInstallation();
  } finally {
    installer?.close();
  }
}

Future<String> _findSystemChromeExecutable() async {
  final io.ProcessResult which = await io.Process.run('which', <String>['google-chrome']);

  if (which.exitCode != 0) {
    throw ChromeInstallerException(
      'Failed to locate system Chrome installation.'
    );
  }

  return which.stdout;
}

class ChromeInstallation {
  const ChromeInstallation({
    @required this.version,
    @required this.executable,
  });

  /// Chrome version.
  final String version;

  /// Path the the Chrome executable.
  final String executable;
}

/// Manages the installation of a particular [version] of Chrome.
class ChromeInstaller {
  factory ChromeInstaller({
    @required String version,
  }) {
    if (version == 'system') {
      throw ChromeInstallerException(
        'Cannot install system version of Chrome. System Chrome must be installed manually.'
      );
    }
    if (version == 'latest') {
      throw ChromeInstallerException(
        'Expected a concrete Chromer version, but got $version. Maybe use ChromeInstaller.latest()?'
      );
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

  ChromeInstallation getInstallation() {
    if (!isInstalled) {
      return null;
    }

    return ChromeInstallation(
      version: version,
      executable: path.join(versionDir.path, 'chrome-linux', 'chrome'),
    );
  }

  Future<void> install() async {
    if (versionDir.existsSync()) {
      versionDir.deleteSync(recursive: true);
    }

    versionDir.createSync(recursive: true);
    final String url = 'https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F$version%2Fchrome-linux.zip?alt=media';
    final StreamedResponse download = await client.send(Request(
      'GET',
      Uri.parse(url),
    ));

    final io.File downloadedFile = io.File(path.join(versionDir.path, 'chrome.zip'));
    await download.stream.pipe(downloadedFile.openWrite());

    final io.ProcessResult unzipResult = await io.Process.run('unzip', <String>[
      downloadedFile.path,
      '-d',
      versionDir.path,
    ]);

    if (unzipResult.exitCode != 0) {
      throw ChromeInstallerException(
        'Failed to unzip the downloaded Chrome archive ${downloadedFile.path}.\n'
        'The unzip process exited with code ${unzipResult.exitCode}.'
      );
    }

    downloadedFile.deleteSync();
  }

  void close() {
    client.close();
  }
}

class ChromeInstallerException implements Exception {
  ChromeInstallerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches the latest available Chrome build version.
Future<String> fetchLatestChromeVersion() async {
  final Client client = Client();
  try {
    final Response response = await client.get('https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2FLAST_CHANGE?alt=media');
    if (response.statusCode != 200) {
      throw ChromeInstallerException(
        'Failed to fetch latest Chrome version. Server returned status code ${response.statusCode}'
      );
    }
    return response.body;
  } finally {
    client.close();
  }
}
