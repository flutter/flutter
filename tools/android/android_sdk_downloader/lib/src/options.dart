// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:meta/meta.dart';

import 'android_repository.dart';

const Map<String, OSType> osTypeMap = <String, OSType>{
  'windows': OSType.windows,
  'macos': OSType.mac,
  'linux': OSType.linux,
};

class OptionsRevision {
  const OptionsRevision(
    this.raw, [
    this.major = 0,
    this.minor = 0,
    this.micro = 0,
    this.preview = 0,
  ]);

  /// Accepted formats: 1.2.3 or 1.2.3.4
  factory OptionsRevision.fromRaw(String raw) {
    final List<String> rawParts = raw.split('.');
    if (rawParts == null || (rawParts.length != 3 && rawParts.length != 4)) {
      throw ArgumentError('Invalid revision string $raw.');
    }
    return OptionsRevision(
      raw,
      int.parse(rawParts[0]),
      int.parse(rawParts[1]),
      int.parse(rawParts[2]),
      rawParts.length == 4 ? int.parse(rawParts[3]) : 0,
    );
  }

  final String raw;
  final int major;
  final int minor;
  final int micro;
  final int preview;
}

class Options {
  const Options({
    @required this.platformApiLevel,
    @required this.platformRevision,
    @required this.repositoryXml,
    @required this.repositoryXmlUri,
    @required this.buildToolsRevision,
    @required this.platformToolsRevision,
    @required this.toolsRevision,
    @required this.ndkRevision,
    @required this.outDirectory,
    @required this.repositoryBase,
    @required this.osType,
    this.acceptLicenses = false,
    this.overwrite = false,
  });

  static Options parseAndValidate(List<String> args, ArgParser argParser) {
    final ArgResults argResults = argParser.parse(args);
    final int platformApiLevel = int.parse(argResults['platform']);
    final int platformRevision = int.parse(argResults['platform-revision']);
    final Directory outDirectory = Directory(argResults['out']);

    final String rawRepositoryXmlUri = argResults['repository-xml'];
    final Uri repositoryXmlUri = Uri.tryParse(rawRepositoryXmlUri);
    final int lastSlash = rawRepositoryXmlUri.lastIndexOf('/');
    final String repositoryBase =
        rawRepositoryXmlUri.substring(0, lastSlash + 1);

    if (repositoryXmlUri == null) {
      throw ArgumentError(
          'Error: could not parse $rawRepositoryXmlUri as a valid URL.');
    }

    String getRawVersion(String argName) {
      final String raw = argResults[argName];
      if (raw?.isEmpty == true) {
        print('Could not parse required argument $argName.');
        print(argParser.usage);
        exit(-1);
      }
      return raw;
    }

    final String rawBuildToolsVersion = getRawVersion('build-tools-version');
    final String rawPlatformToolsVersion =
        getRawVersion('platform-tools-version');
    final String rawToolsVersion = getRawVersion('tools-version');
    final String rawNdkVersion = getRawVersion('ndk-version');

    return Options(
      platformApiLevel: platformApiLevel,
      platformRevision: platformRevision,
      outDirectory: outDirectory,
      repositoryXml: rawRepositoryXmlUri,
      repositoryXmlUri: repositoryXmlUri,
      repositoryBase: repositoryBase,
      buildToolsRevision: OptionsRevision.fromRaw(rawBuildToolsVersion),
      platformToolsRevision: OptionsRevision.fromRaw(rawPlatformToolsVersion),
      toolsRevision: OptionsRevision.fromRaw(rawToolsVersion),
      ndkRevision: OptionsRevision.fromRaw(rawNdkVersion),
      osType: osTypeMap[argResults['os']],
      acceptLicenses: argResults['accept-licenses'],
      overwrite: argResults['overwrite'],
    );
  }

  final int platformApiLevel;
  final String repositoryXml;
  final Uri repositoryXmlUri;
  final int platformRevision;
  final OptionsRevision buildToolsRevision;
  final OptionsRevision platformToolsRevision;
  final OptionsRevision toolsRevision;
  final OptionsRevision ndkRevision;
  final String repositoryBase;
  final Directory outDirectory;
  final OSType osType;
  final bool acceptLicenses;
  final bool overwrite;
}
