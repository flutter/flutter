// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/net.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../update_packages_pins.dart';

// Pub packages are rolled automatically by the flutter-pub-roller-bot
// by using the `flutter update-packages --force-upgrade`.
// For the latest status, see:
//   https://github.com/pulls?q=author%3Aflutter-pub-roller-bot

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand() {
    argParser
      ..addFlag(
        _keyForceUpgrade,
        help:
            'Attempt to update all the dependencies to their latest versions.\n'
            'This will actually modify the pubspec.yaml files in your checkout.',
        negatable: false,
      )
      ..addOption(
        _keyCherryPickPackage,
        help:
            'Attempt to update only the specified package. The "--cherry-pick-version" version must be specified also.',
      )
      ..addOption(
        _keyCherryPickVersion,
        help:
            'Attempt to update the package to the specified version. The "--cherry-pick-package" option must be specified also.',
      )
      ..addFlag(
        _keyOffline,
        help: 'Use cached packages instead of accessing the network.',
        negatable: false,
      )
      ..addFlag(
        _keyCrash,
        help: 'For Flutter CLI testing only, forces this command to throw an unhandled exception.',
        negatable: false,
      );
  }

  final String _keyForceUpgrade = 'force-upgrade';
  final String _keyCherryPickPackage = 'cherry-pick-package';
  final String _keyCherryPickVersion = 'cherry-pick-version';
  final String _keyOffline = 'offline';
  final String _keyCrash = 'crash';

  static const Set<String> fixedPackages = <String>{'test_api', 'test_core'};

  @override
  final String name = 'update-packages';

  @override
  final String description =
      'Update the packages inside the Flutter repo. '
      'This is intended for CI and repo maintainers. '
      'Normal Flutter developers should not have to '
      'use this command.';

  @override
  final List<String> aliases = <String>['upgrade-packages'];

  @override
  final bool hidden = true;

  // Lazy-initialize the net utilities with values from the context.
  late final Net _net = Net(
    httpClientFactory: context.get<HttpClientFactory>(),
    logger: globals.logger,
    platform: globals.platform,
  );

  Future<void> _downloadCoverageData() async {
    final String urlBase =
        globals.platform.environment[kFlutterStorageBaseUrl] ?? 'https://storage.googleapis.com';
    final Uri coverageUri = Uri.parse('$urlBase/flutter_infra_release/flutter/coverage/lcov.info');
    final List<int>? data = await _net.fetchUrl(coverageUri, maxAttempts: 3);
    if (data == null) {
      throwToolExit('Failed to fetch coverage data from $coverageUri');
    }
    final String coverageDir = globals.fs.path.join(
      Cache.flutterRoot!,
      'packages/flutter/coverage',
    );
    globals.fs.file(globals.fs.path.join(coverageDir, 'lcov.base.info'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data, flush: true);
    globals.fs.file(globals.fs.path.join(coverageDir, 'lcov.info'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data, flush: true);
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    // Add the root directory to the list of packages, to capture the workspace
    // `pubspec.yaml`.
    final Directory rootDirectory = globals.fs.directory(
      globals.fs.path.absolute(Cache.flutterRoot!),
    );

    final bool forceUpgrade = boolArg(_keyForceUpgrade);
    final bool offline = boolArg(_keyOffline);
    final String? cherryPickPackage = stringArg(_keyCherryPickPackage);
    final String? cherryPickVersion = stringArg(_keyCherryPickVersion);

    if (boolArg('crash')) {
      throw StateError('test crash please ignore.');
    }

    if (forceUpgrade && offline) {
      throwToolExit('--force-upgrade cannot be used with the --offline flag');
    }

    if (forceUpgrade && cherryPickPackage != null) {
      throwToolExit('--force-upgrade cannot be used with the --cherry-pick-package flag');
    }

    if (cherryPickPackage != null && offline) {
      throwToolExit('--cherry-pick-package cannot be used with the --offline flag');
    }

    if (cherryPickPackage != null && cherryPickVersion == null) {
      throwToolExit('--cherry-pick-version is required when using --cherry-pick-package flag');
    }

    ({String package, String version})? cherryPick;
    if (cherryPickPackage != null && cherryPickVersion != null) {
      cherryPick = (package: cherryPickPackage, version: cherryPickVersion);
    }

    if (forceUpgrade) {
      // This feature attempts to collect all the packages used across all the
      // pubspec.yamls in the repo (including via transitive dependencies), and
      // find the latest version of each that can be used while keeping each
      // such package fixed at a single version across all the pubspec.yamls.
      globals.printStatus('Upgrading packages...');
    }

    final FlutterProject project = FlutterProject.fromDirectory(rootDirectory);
    final List<Directory> packages = <Directory>[...runner!.getRepoPackages(), rootDirectory];

    if (cherryPick != null) {
      globals.printStatus(
        'Pinning package "${cherryPick.package}" to version "${cherryPick.version}"...',
      );

      await pub.interactively(
        <String>['${cherryPick.package}:${cherryPick.version}'],
        context: PubContext.pubAdd,
        project: project,
        command: 'add',
      );

      _writePubspecs(packages);
    } else if (forceUpgrade) {
      globals.printStatus('Upgrading packages versions...');

      await pub.interactively(
        <String>['--force-upgrade'],
        context: PubContext.updatePackages,
        project: project,
        command: 'update',
      );

      _writePubspecs(packages);
      _checkWithFlutterTools(rootDirectory);
    } else {
      globals.printStatus('Running pub get only...');
      _verifyPubspecs(packages);

      await pub.get(context: PubContext.pubGet, project: project);
    }

    await _downloadCoverageData();

    return FlutterCommandResult.success();
  }

  void _verifyPubspecs(List<Directory> packages) {
    globals.printStatus('Verifying pubspecs...');
    for (final Directory directory in packages) {
      globals.printTrace('Reading pubspec.yaml from ${directory.path}');
      final String pubspecString = directory.childFile('pubspec.yaml').readAsStringSync();
      _checkHash(pubspecString, directory);
      _checkPins(pubspecString, directory);
    }
  }

  void _checkWithFlutterTools(Directory rootDirectory) {
    final Pubspec pubspec = Pubspec.parse(
      rootDirectory.childFile('pubspec.yaml').readAsStringSync(),
    );
    final Pubspec pubspecTools = Pubspec.parse(
      rootDirectory
          .childDirectory('packages')
          .childDirectory('flutter_tools')
          .childFile('pubspec.yaml')
          .readAsStringSync(),
    );
    for (final String package in fixedPackages) {
      if (!(pubspec.dependencies[package] == pubspecTools.dependencies[package] &&
          pubspec.devDependencies[package] == pubspecTools.devDependencies[package] &&
          pubspec.dependencyOverrides[package] == pubspecTools.dependencyOverrides[package])) {
        throwToolExit('The dependency on $package must be fixed between flutter and flutter_tools');
      }
    }
  }

  void _checkPins(String pubspecString, Directory directory) {
    final Pubspec pubspec = Pubspec.parse(pubspecString);
    for (final MapEntry<String, String> pin in kManuallyPinnedDependencies.entries) {
      Dependency dependency;
      if (pubspec.dependencies.containsKey(pin.key)) {
        dependency = pubspec.dependencies[pin.key]!;
      } else if (pubspec.devDependencies.containsKey(pin.key)) {
        dependency = pubspec.devDependencies[pin.key]!;
      } else if (pubspec.dependencyOverrides.containsKey(pin.key)) {
        dependency = pubspec.dependencyOverrides[pin.key]!;
      } else {
        continue;
      }
      final VersionConstraint? version = switch (dependency) {
        SdkDependency() => dependency.version,
        GitDependency() => null,
        PathDependency() => null,
        HostedDependency() => dependency.version,
      };
      if (version != null && version.toString() != pin.value) {
        throwToolExit(
          "${pin.key} should be pinned in $directory to version ${pin.value}, but isn't",
        );
      }
    }
  }

  void _checkHash(String pubspec, Directory directory) {
    final RegExpMatch? firstMatch = dependencyRegex.firstMatch(pubspec);
    if (firstMatch != null) {
      final String checksum = firstMatch[1]!;
      final String actualChecksum = _computeChecksum(pubspec);
      if (checksum != actualChecksum) {
        throwToolExit(
          'Pubspec in ${directory.path} has out of date dependencies. '
          'Please run "flutter update-packages --force-upgrade" to update them correctly. '
          'The hash does not match the expectation.',
        );
      }
    } else {
      throwToolExit('Pubspec in ${directory.path} does not contain a checksum.');
    }
  }

  void _writePubspecs(List<Directory> packages) {
    globals.printStatus('Writing hashes to pubspecs...');
    for (final Directory directory in packages) {
      globals.printTrace('Reading pubspec.yaml from ${directory.path}');
      String pubspec = directory.childFile('pubspec.yaml').readAsStringSync();
      final String actualChecksum = _computeChecksum(pubspec);
      final RegExpMatch? firstMatch = dependencyRegex.firstMatch(pubspec);
      if (firstMatch != null) {
        pubspec.replaceFirst(dependencyRegex, '$kDependencyChecksum$actualChecksum');
        directory.childFile('pubspec.yaml').writeAsStringSync(pubspec);
      } else {
        pubspec += '\n$kDependencyChecksum$actualChecksum';
        directory.childFile('pubspec.yaml').writeAsStringSync(pubspec);
      }
    }
    globals.printStatus('All pubspecs are now up to date.');
  }

  String _computeChecksum(String pubspecString) {
    final Pubspec pubspec = Pubspec.parse(pubspecString);
    return SplayTreeMap<String, Dependency>.from(<String, Dependency>{
          ...pubspec.dependencies,
          ...pubspec.devDependencies,
          ...pubspec.dependencyOverrides,
        }).entries
        .map((MapEntry<String, Dependency> entry) => '${entry.key}${entry.value}')
        .join()
        .hashCode
        .toRadixString(32);
  }

  /// This is the string we output next to each of our autogenerated transitive
  /// dependencies so that we can ignore them the next time we parse the
  /// pubspec.yaml file.
  static const String kTransitiveMagicString =
      '# THIS LINE IS AUTOGENERATED - TO UPDATE USE "flutter update-packages --force-upgrade"';

  /// This is the string output before a checksum of the packages used.
  static const String kDependencyChecksum = '# PUBSPEC CHECKSUM: ';
  final RegExp dependencyRegex = RegExp('$kDependencyChecksum([a-zA-Z0-9]+)');
}
