// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.8
import 'dart:convert';
import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:package_config/packages_file.dart'; // ignore: deprecated_member_use
import 'package:package_config/src/package_config_json.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError('Unexpected arguments $args\n\n$usage');
  }
  if (args.first == 'help') {
    print(usage);
    return;
  }
  var packagesUri = Uri.base.resolve(args.first);
  var packagesFile = File.fromUri(packagesUri);
  if (!await packagesFile.exists()) {
    throw ArgumentError('Unable to read file at `$packagesUri`');
  }
  var packageMap = parse(await packagesFile.readAsBytes(), packagesFile.uri);
  var packages = <Package>[];
  for (var packageEntry in packageMap.entries) {
    var name = packageEntry.key;
    var uri = packageEntry.value;
    if (uri.scheme != 'file') {
      throw ArgumentError(
          'Only file: schemes are supported, but the `$name` package has '
          'the following uri: ${uri}');
    }
    Uri packageRoot;
    Uri pubspec;
    LanguageVersion languageVersion;
    // Pub packages will always have a path ending in `lib/`, and a pubspec
    // directly above that.
    if (uri.path.endsWith('lib/')) {
      packageRoot = uri.resolve('../');
      pubspec = packageRoot.resolve('pubspec.yaml');
      if (!File.fromUri(pubspec).existsSync()) {
        continue;
      }
      // Default to 2.8 if not found to prevent all packages from accidentally
      // opting into NNBD.
      languageVersion = await languageVersionFromPubspec(pubspec, name) ??
          LanguageVersion(2, 8);
      packages.add(Package(name, packageRoot,
          languageVersion: languageVersion, packageUriRoot: uri));
    }
  }
  var outputFile =
      File.fromUri(packagesFile.uri.resolve('.dart_tool/package_config.json'));
  if (!outputFile.parent.existsSync()) {
    outputFile.parent.createSync();
  }
  var baseUri = outputFile.uri;
  var sink = outputFile.openWrite(encoding: utf8);
  writePackageConfigJsonUtf8(PackageConfig(packages), baseUri, sink);
  await sink.close();
}

const usage = 'Usage: pub run package_config:generate_from_legacy <input-file>';

Future<LanguageVersion> languageVersionFromPubspec(
    Uri pubspec, String packageName) async {
  var pubspecFile = File.fromUri(pubspec);
  if (!await pubspecFile.exists()) {
    return null;
  }
  var pubspecYaml =
      loadYaml(await pubspecFile.readAsString(), sourceUrl: pubspec) as YamlMap;

  // Find the sdk constraint, or return null if none is present
  var environment = pubspecYaml['environment'] as YamlMap;
  if (environment == null) {
    return null;
  }
  var sdkConstraint = environment['sdk'] as String;
  if (sdkConstraint == null) {
    return null;
  }

  var parsedConstraint = VersionConstraint.parse(sdkConstraint);
  var min = parsedConstraint is Version
      ? parsedConstraint
      : parsedConstraint is VersionRange
          ? parsedConstraint.min
          : throw 'Unsupported version constraint type $parsedConstraint';

  return LanguageVersion(min.major, min.minor);
}
