// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:io' as io;

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'common.dart';
import 'environment.dart';

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

  /// Root directory that contains Chrome versions.
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
        io.File(path.join(versionDir.path, 'firefox.zip'));
    await download.stream.pipe(downloadedFile.openWrite());

    return downloadedFile;
  }

  /// Uncompress the downloaded browser files.
  /// See [version].
  Future<void> _uncompress(io.File downloadedFile) async {
    /// TODO(nturgut): Implement Install.
  }

  void close() {
    client.close();
  }
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
