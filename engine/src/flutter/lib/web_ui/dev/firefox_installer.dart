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

class FirefoxArgParser extends BrowserArgParser {
  static final FirefoxArgParser _singletonInstance = FirefoxArgParser._();

  /// The [FirefoxArgParser] singleton.
  static FirefoxArgParser get instance => _singletonInstance;

  String _version;

  FirefoxArgParser._();

  @override
  void populateOptions(ArgParser argParser) {
    final YamlMap browserLock = BrowserLock.instance.configuration;
    String firefoxVersion = browserLock['firefox']['version'] as String;

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
    _version = argResults['firefox-version'] as String;
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
  if (!io.Platform.isLinux && !io.Platform.isMacOS) {
    throw UnimplementedError('Firefox Installer is only supported on Linux '
        'and Mac operating systems');
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
    final String latestVersion = io.Platform.isLinux
        ? await fetchLatestFirefoxVersionLinux()
        : await fetchLatestFirefoxVersionMacOS();
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
    if (io.Platform.isLinux) {
      await _uncompress(downloadedFile);
    } else if (io.Platform.isMacOS) {
      await _mountDmgAndCopy(downloadedFile);
    }
    downloadedFile.deleteSync();
  }

  /// Downloads the browser version from web into a target file.
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
        io.File(path.join(versionDir.path, PlatformBinding.instance.getFirefoxDownloadFilename(version)));
    io.IOSink sink = downloadedFile.openWrite();
    await download.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    return downloadedFile;
  }

  /// Uncompress the downloaded browser files for operating systems that
  /// use a zip archive.
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

  /// Mounts the dmg file using hdiutil, copies content of the volume to
  /// target path and then unmounts dmg ready for deletion.
  Future<void> _mountDmgAndCopy(io.File dmgFile) async {
    String volumeName = await _hdiUtilMount(dmgFile);

    final String sourcePath = '$volumeName/Firefox.app';
    final String targetPath = path.dirname(dmgFile.path);
    try {
      io.ProcessResult installResult = await io.Process.run('cp', <String>[
        '-r',
        sourcePath,
        targetPath,
      ]);
      if (installResult.exitCode != 0) {
        throw BrowserInstallerException(
            'Failed to copy Firefox disk image contents from '
            '$sourcePath to $targetPath.\n'
            'Exit code ${installResult.exitCode}.\n'
            '${installResult.stderr}');
      }
    } finally {
      await _hdiUtilUnmount(volumeName);
    }
  }

  Future<String> _hdiUtilMount(io.File dmgFile) async {
    io.ProcessResult mountResult = await io.Process.run('hdiutil', <String>[
      'attach',
      '-readonly',
      '${dmgFile.path}',
    ]);
    if (mountResult.exitCode != 0) {
      throw BrowserInstallerException(
          'Failed to mount Firefox disk image ${dmgFile.path}.\n'
              'Exit code ${mountResult.exitCode}.\n${mountResult.stderr}');
    }

    List<String> processOutput = (mountResult.stdout as String).split('\n');
    String volumePath = _volumeFromMountResult(processOutput);
    if (volumePath == null) {
      throw BrowserInstallerException(
          'Failed to parse mount dmg result ${processOutput.join('\n')}.\n'
              'Expected /Volumes/{volume name}');
    }
    return volumePath;
  }

  // Parses volume from mount result.
  // Output is of form: {devicename} /Volumes/{name}.
  String _volumeFromMountResult(List<String> lines) {
    for (String line in lines) {
      int pos = line.indexOf('/Volumes');
      if (pos != -1) {
        return line.substring(pos);
      }
    }
    return null;
  }

  Future<void> _hdiUtilUnmount(String volumeName) async {
    io.ProcessResult unmountResult = await io.Process.run('hdiutil', <String>[
      'unmount',
      '$volumeName',
    ]);
    if (unmountResult.exitCode != 0) {
      throw BrowserInstallerException(
          'Failed to unmount Firefox disk image ${volumeName}.\n'
              'Exit code ${unmountResult.exitCode}. ${unmountResult.stderr}');
    }
  }

  void close() {
    client.close();
  }
}

Future<String> _findSystemFirefoxExecutable() async {
  final io.ProcessResult which =
      await io.Process.run('which', <String>['firefox']);
  bool found = which.exitCode != 0;
  const String fireFoxDefaultInstallPath =
      '/Applications/Firefox.app/Contents/MacOS/firefox';
  if (!found) {
    if (io.Platform.isMacOS &&
        io.File(fireFoxDefaultInstallPath).existsSync()) {
      return Future.value(fireFoxDefaultInstallPath);
    }
    throw BrowserInstallerException(
        'Failed to locate system Firefox installation.');
  }
  return which.stdout as String;
}

/// Fetches the latest available Firefox build version on Linux.
Future<String> fetchLatestFirefoxVersionLinux() async {
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

/// Fetches the latest available Firefox build version on Mac OS.
Future<String> fetchLatestFirefoxVersionMacOS() async {
  final RegExp forFirefoxVersion = RegExp("firefox\/releases\/[0-9.]\+[0-9]");
  final io.HttpClientRequest request = await io.HttpClient()
      .getUrl(Uri.parse(PlatformBinding.instance.getFirefoxLatestVersionUrl()));
  request.followRedirects = false;
  // We will parse the HttpHeaders to find the redirect location.
  final io.HttpClientResponse response = await request.close();

  final String location = response.headers.value('location');
  final String version = forFirefoxVersion.stringMatch(location);
  return version.substring(version.lastIndexOf('/') + 1);
}

Future<BrowserInstallation> getInstaller({String requestedVersion = 'latest'}) async {
  FirefoxInstaller installer;
  try {
    installer = requestedVersion == 'latest'
        ? await FirefoxInstaller.latest()
        : FirefoxInstaller(version: requestedVersion);

    if (installer.isInstalled) {
      print('Installation was skipped because Firefox version '
          '${installer.version} is already installed.');
    } else {
      print('Installing Firefox version: ${installer.version}');
      await installer.install();
      final BrowserInstallation installation = installer.getInstallation();
      print(
          'Installations complete. To launch it run ${installation.executable}');
    }
    return installer.getInstallation();
  } finally {
    installer?.close();
  }
}
