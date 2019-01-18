// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'src/android_repository.dart';
import 'src/checksums.dart';
import 'src/http.dart';
import 'src/options.dart';
import 'src/zip.dart';

const String _kAndroidRepositoryXml = 'https://dl.google.com/android/repository/repository2-1.xml';


Future<void> main(List<String> args) async {
  final ArgParser argParser = ArgParser()
    ..addOption(
      'repository-xml',
      abbr: 'r',
      help: 'Specifies the location of the Android Repository XML file.',
      defaultsTo: _kAndroidRepositoryXml,
    )
    ..addOption(
      'platform',
      abbr: 'p',
      help: 'Specifies the Android platform version, e.g. 28',
    )
    ..addOption(
      'platform-revision',
      help: 'Specifies the Android platform revision, e.g. 6 for 28_r06',
    )
    ..addOption(
      'out',
      abbr: 'o',
      help: 'The directory to write downloaded files to.',
      defaultsTo: '.',
    )
    ..addOption(
      'os',
      help: 'The OS type to download for.  Defaults to current platform.',
      defaultsTo: Platform.operatingSystem,
      allowed: osTypeMap.keys,
    )
    ..addOption(
      'build-tools-version',
      help: 'The build-tools version to download.  Must be in format of '
          '<major>.<minor>.<micro>, e.g. 28.0.3; '
          'or <major>.<minor>.<micro>.<rc/preview>, e.g. 28.0.0.2',
    )
    ..addOption(
      'platform-tools-version',
      help: 'The platform-tools version to download.  Must be in format of '
          '<major>.<minor>.<micro>, e.g. 28.0.1; '
          'or <major>.<minor>.<micro>.<rc/preview>, e.g. 28.0.0.2',
    )
    ..addOption(
      'tools-version',
      help: 'The tools version to download.  Must be in format of '
          '<major>.<minor>.<micro>, e.g. 26.1.1; '
          'or <major>.<minor>.<micro>.<rc/preview>, e.g. 28.1.1.2',
    )
    ..addOption(
      'ndk-version',
      help: 'The ndk version to download.  Must be in format of '
          '<major>.<minor>.<micro>, e.g. 28.0.3; '
          'or <major>.<minor>.<micro>.<rc/preview>, e.g. 28.0.0.2',
    )
    ..addFlag('accept-licenses',
        abbr: 'y',
        defaultsTo: false,
        help: 'Automatically accept Android SDK licenses.')
    ..addFlag(
      'overwrite',
      defaultsTo: false,
      help: 'Skip download if the target directory exists.',
    );

  final bool help = args.contains('-h')
                 || args.contains('--help')
                 || (args.isNotEmpty && args.first == 'help');
  if (help) {
    print(argParser.usage);
    return;
  }

  final Options options = Options.parseAndValidate(args, argParser);

  final AndroidRepository androidRepository = await _getAndroidRepository(options.repositoryXmlUri);
  assert(androidRepository.platforms.isNotEmpty);
  assert(androidRepository.buildTools.isNotEmpty);

  if (!options.acceptLicenses) {
    for (final AndroidRepositoryLicense license in androidRepository.licenses) {
      print('================================================================================\n\n');
      print(license.text);
      stdout.write('Do you accept? (Y/n): ');
      final String result = stdin.readLineSync().trim().toLowerCase();
      if (result != '' && result.startsWith('y') == false) {
        print('Ending.');
        exit(-1);
      }
    }
  }

  await options.outDirectory.create(recursive: true);

  final Directory tempDir = await Directory(options.outDirectory.path).createTemp();
  await tempDir.create(recursive: true);

  final Directory ndkDir = Directory(path.join(options.outDirectory.path, 'ndk'));
  final Directory sdkDir = Directory(path.join(options.outDirectory.path, 'sdk'));
  final Directory platformDir = Directory(path.join(sdkDir.path, 'platforms', 'android-${options.platformApiLevel}'));
  final Directory buildToolsDir = Directory(path.join(sdkDir.path, 'build-tools', options.buildToolsRevision.raw));
  final Directory platformToolsDir = Directory(path.join(sdkDir.path, 'platform-tools'));
  final Directory toolsDir = Directory(path.join(sdkDir.path, 'tools'));

  final Map<String, String> checksums =
      await loadChecksums(options.outDirectory);

  print('Downloading Android SDK and NDK artifacts...');
  final List<Future<void>> futures = <Future<void>>[];

  futures.add(downloadArchive(
    androidRepository.platforms,
    OptionsRevision(null, options.platformRevision),
    options.repositoryBase,
    tempDir,
    checksumToSkip: options.overwrite ? null : checksums[platformDir.path],
  ).then((ArchiveDownloadResult result) {
    if (result != ArchiveDownloadResult.empty) {
      return unzipFile(result.zipFileName, platformDir).then((_) {
        checksums[platformDir.path] = result.checksum;
        return writeChecksums(checksums, options.outDirectory);
      });
    }
    return null;
  }));
  futures.add(downloadArchive(
    androidRepository.buildTools,
    options.buildToolsRevision,
    options.repositoryBase,
    tempDir,
    osType: options.osType,
    checksumToSkip: options.overwrite ? null : checksums[buildToolsDir.path],
  ).then((ArchiveDownloadResult result) {
    if (result != ArchiveDownloadResult.empty) {
      return unzipFile(result.zipFileName, buildToolsDir).then((_) {
        checksums[buildToolsDir.path] = result.checksum;
        return writeChecksums(checksums, options.outDirectory);
      });
    }
    return null;
  }));
  futures.add(downloadArchive(
    androidRepository.platformTools,
    options.platformToolsRevision,
    options.repositoryBase,
    tempDir,
    osType: options.osType,
    checksumToSkip: options.overwrite ? null : checksums[platformToolsDir.path],
  ).then((ArchiveDownloadResult result) {
    if (result != ArchiveDownloadResult.empty) {
      return unzipFile(result.zipFileName, platformToolsDir).then((_) {
        checksums[platformToolsDir.path] = result.checksum;
        return writeChecksums(checksums, options.outDirectory);
      });
    }
    return null;
  }));
  futures.add(downloadArchive(
    androidRepository.tools,
    options.toolsRevision,
    options.repositoryBase,
    tempDir,
    osType: options.osType,
    checksumToSkip: options.overwrite ? null : checksums[toolsDir.path],
  ).then((ArchiveDownloadResult result) {
    if (result != ArchiveDownloadResult.empty) {
      return unzipFile(result.zipFileName, toolsDir).then((_) {
        checksums[toolsDir.path] = result.checksum;
        return writeChecksums(checksums, options.outDirectory);
      });
    }
    return null;
  }));
  futures.add(downloadArchive(
    androidRepository.ndkBundles,
    options.ndkRevision,
    options.repositoryBase,
    tempDir,
    osType: options.osType,
    checksumToSkip: options.overwrite ? null : checksums[ndkDir.path],
  ).then((ArchiveDownloadResult result) {
    if (result != ArchiveDownloadResult.empty) {
      return unzipFile(result.zipFileName, ndkDir).then((_) {
        checksums[ndkDir.path] = result.checksum;
        return writeChecksums(checksums, options.outDirectory);
      });
    }
    return null;
  }));
  await Future.wait<void>(futures);
  await tempDir.delete(recursive: true);
}

Future<AndroidRepository> _getAndroidRepository(Uri repositoryXmlUri) async {
  final StringBuffer repoXmlBuffer = StringBuffer();
  Future<void> _repositoryXmlHandler(HttpClientResponse response) async {
    await response.transform(utf8.decoder).forEach(repoXmlBuffer.write);
  }

  await httpGet(repositoryXmlUri, _repositoryXmlHandler);

  return parseAndroidRepositoryXml(repoXmlBuffer.toString());
}
