// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

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

const _pubspecName = 'pubspec.yaml';

typedef _ProjectDeps = ({FlutterProject project, ResolvedDependencies deps});

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({required bool verboseHelp}) {
    argParser
      ..addFlag(
        _keyForceUpgrade,
        help:
            'Attempt to update all the dependencies to their latest versions.\n'
            'This will actually modify the pubspec.yaml files in your checkout.',
        negatable: false,
      )
      ..addFlag(
        _keyUpdateHashes,
        help: 'Update the hashes of the pubspecs.',
        negatable: false,
        // We don't want to promote usage, to not circumvent using this script to update
        hide: !verboseHelp,
      )
      ..addMultiOption(
        _keyCherryPick,
        help:
            'Attempt to update only the specified package. To be specified as [pub package name]:[pub package version],[pub package2 name]:[pub package2 version].',
      )
      ..addFlag(
        _keyOffline,
        help: 'Use cached packages instead of accessing the network.',
        negatable: false,
      )
      ..addFlag(
        _keyUpgradeMajor,
        help: 'Upgrade major versions as well. Only makes sense with force-upgrade.',
      )
      ..addFlag(
        _keyExcludeTools,
        help: "Don't update the deps in tools. For example when unpinning a dep.",
      )
      ..addFlag(
        _keyCrash,
        help: 'For Flutter CLI testing only, forces this command to throw an unhandled exception.',
        negatable: false,
        hide: !verboseHelp,
      );
  }

  final _keyForceUpgrade = 'force-upgrade';
  final _keyUpdateHashes = 'update-hashes';
  final _keyCherryPick = 'cherry-pick';
  final _keyOffline = 'offline';
  final _keyUpgradeMajor = 'upgrade-major';
  final _keyExcludeTools = 'exclude-tools';
  final _keyCrash = 'crash';

  static const fixedPackages = <String>{'test_api', 'test_core'};

  @override
  final name = 'update-packages';

  @override
  final description =
      'Update the packages inside the Flutter repo. '
      'This is intended for CI and repo maintainers. '
      'Normal Flutter developers should not have to '
      'use this command.';

  @override
  final aliases = <String>['upgrade-packages'];

  @override
  final hidden = true;

  // Lazy-initialize the net utilities with values from the context.
  late final _net = Net(
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
    final bool updateHashes = boolArg(_keyUpdateHashes);
    final bool offline = boolArg(_keyOffline);
    final List<CherryPick> cherryPicks = stringsArg(_keyCherryPick)
        .map((String e) => e.split(':'))
        .map((List<String> e) => (package: e[0], version: e[1]))
        .toList();
    final bool relaxToAny = boolArg(_keyUpgradeMajor);
    final bool excludeTools = boolArg(_keyExcludeTools);

    if (boolArg('crash')) {
      throw StateError('test crash please ignore.');
    }

    if (forceUpgrade && offline) {
      throwToolExit('--force-upgrade cannot be used with the --offline flag');
    }

    if (forceUpgrade && cherryPicks.isNotEmpty) {
      throwToolExit('--force-upgrade cannot be used with the --cherry-pick-package flag');
    }

    if (cherryPicks.isNotEmpty && offline) {
      throwToolExit('--cherry-pick-package cannot be used with the --offline flag');
    }

    if (forceUpgrade) {
      // This feature attempts to collect all the packages used across all the
      // pubspec.yamls in the repo (including via transitive dependencies), and
      // find the latest version of each that can be used while keeping each
      // such package fixed at a single version across all the pubspec.yamls.
      globals.printStatus('Upgrading packages...');
    }
    final FlutterProject rootProject = FlutterProject.fromDirectory(rootDirectory);
    final FlutterProject toolProject = FlutterProject.fromDirectory(
      rootDirectory.childDirectory('packages').childDirectory('flutter_tools'),
    );

    // This package is intentionally not part of the workspace as it's a rehydrated template.
    final FlutterProject widgetPreviewScaffoldProject = FlutterProject.fromDirectory(
      rootProject.directory
          .childDirectory('dev')
          .childDirectory('integration_tests')
          .childDirectory('widget_preview_scaffold'),
    );

    // This package is intentionally not part of the workspace to test
    // user-defines in its local pubspec.
    final Directory hooksUserDefineIntegrationTestDirectory = rootDirectory
        .childDirectory('dev')
        .childDirectory('integration_tests')
        .childDirectory('hook_user_defines');

    final packages = <Directory>[...runner!.getRepoPackages(), rootDirectory];

    if (!updateHashes) {
      _verifyPubspecs(packages);
    }
    if (forceUpgrade || cherryPicks.isNotEmpty) {
      if (!excludeTools) {
        final List<_ProjectDeps> toolDeps = await _upgrade(forceUpgrade, cherryPicks, [
          // The widget_preview_scaffold project has a path dependency on flutter_tools, so we must
          // upgrade the projects together.
          toolProject,
          widgetPreviewScaffoldProject,
        ], relaxToAny);
        for (final (:project, :deps) in toolDeps) {
          _updatePubspec(project.directory, deps);
        }
      }

      final (project: _, :ResolvedDependencies deps) = (await _upgrade(forceUpgrade, cherryPicks, [
        rootProject,
      ], relaxToAny)).single;

      for (final package in <Directory>[
        rootDirectory,
        rootDirectory.childDirectory('packages').childDirectory('flutter'),
        rootDirectory.childDirectory('packages').childDirectory('flutter_test'),
        rootDirectory.childDirectory('packages').childDirectory('flutter_localizations'),
        widgetPreviewScaffoldProject.directory,
        hooksUserDefineIntegrationTestDirectory,
      ]) {
        _updatePubspec(package, deps);
      }
    }
    globals.printStatus('Running pub get only...');
    if (updateHashes || forceUpgrade || cherryPicks.isNotEmpty) {
      _writeHashesToPubspecs(packages);
    }
    _verifyPubspecs(packages);
    _checkWithFlutterTools(rootDirectory);
    _checkPins(rootDirectory);

    // Pub get for the workspace.
    await _pubGet(rootProject, !forceUpgrade && cherryPicks.isEmpty && !updateHashes);

    // Manually do a pub get for packages not part of the workspace.
    // See https://github.com/flutter/flutter/pull/170364.
    await _pubGet(toolProject, false);
    await _pubGet(widgetPreviewScaffoldProject, false);
    await _pubGet(FlutterProject.fromDirectory(hooksUserDefineIntegrationTestDirectory), false);

    await _downloadCoverageData();

    return FlutterCommandResult.success();
  }

  Future<void> _pubGet(FlutterProject project, bool enforceLockfile) async =>
      pub.get(context: PubContext.pubGet, project: project, enforceLockfile: enforceLockfile);

  Future<List<_ProjectDeps>> _upgrade(
    bool forceUpgrade,
    List<CherryPick> cherryPicks,
    List<FlutterProject> projects,
    bool relaxToAny,
  ) async {
    final Map<String, String> pinnedDeps;
    if (forceUpgrade) {
      globals.printStatus('Upgrading packages versions...');
      pinnedDeps = kManuallyPinnedDependencies;
    } else if (cherryPicks.isNotEmpty) {
      globals.printStatus('Pinning packages "$cherryPicks"...');
      pinnedDeps = <String, String>{
        for (final CherryPick cherryPick in cherryPicks) cherryPick.package: cherryPick.version,
      };
    } else {
      throw StateError('To get here, either forceUpgrade or cherry pick should be set.');
    }

    final Directory tempDir = globals.fs.systemTempDirectory.createTempSync(
      'flutter_upgrade_packages.',
    );
    final deps = <_ProjectDeps>[];
    for (final project in projects) {
      final Directory projectTempDir = tempDir.childDirectory(
        globals.fs.path.relative(project.directory.path, from: Cache.flutterRoot),
      );
      final File tempPubspec = projectTempDir.childFile(project.pubspecFile.basename)
        ..createSync(recursive: true);
      globals.printStatus('Writing to temp pubspec at $tempPubspec');
      final String pubspecContents = project.pubspecFile.readAsStringSync();
      final yamlEditor = YamlEditor(pubspecContents);
      final ResolvedDependencies oldDeps = _fetchDeps(yamlEditor);
      final workspacePath = <String>['workspace'];
      if (yamlEditor.parseAt(workspacePath, orElse: () => wrapAsYamlNode(null)).value != null) {
        yamlEditor.remove(workspacePath);
      }
      final RelaxMode relaxMode = switch (cherryPicks.isNotEmpty) {
        true => RelaxMode.strict,
        false => relaxToAny ? RelaxMode.any : RelaxMode.caret,
      };
      _relaxDeps(yamlEditor, relaxMode, pinnedDeps);
      tempPubspec.writeAsStringSync(yamlEditor.toString());
      globals.printStatus('Upgrade in $projectTempDir (for project: ${project.manifest.appName})');
      await pub.interactively(
        <String>['upgrade', '--tighten', '-C', projectTempDir.path],
        context: PubContext.updatePackages,
        project: FlutterProject.fromDirectory(projectTempDir),
        command: 'update',
      );

      final ResolvedDependencies newDeps = _fetchDeps(YamlEditor(tempPubspec.readAsStringSync()));

      deps.add((
        project: project,
        deps: ResolvedDependencies.mergeDeps(oldDeps, newDeps, cherryPicks),
      ));
    }

    tempDir.deleteSync(recursive: true);
    return deps;
  }

  void _relaxDeps(YamlEditor yamlEditor, RelaxMode relaxMode, Map<String, String> fixedDeps) {
    ResolvedDependencies().forEach(
      yamlEditor: yamlEditor,
      func:
          (Map<String, String> dependencies, String depType, String packageName, Object? version) {
            if (version is String) {
              if (fixedDeps.containsKey(packageName)) {
                yamlEditor.update(<String>[depType, packageName], fixedDeps[packageName]);
              } else {
                yamlEditor.update(
                  <String>[depType, packageName],
                  switch (relaxMode) {
                    RelaxMode.any => 'any',
                    RelaxMode.caret => _versionWithCaret(version),
                    RelaxMode.strict => _versionWithoutCaret(version),
                  },
                );
              }
            }
          },
    );
  }

  ResolvedDependencies _fetchDeps(YamlEditor yamlEditor) {
    return ResolvedDependencies()..forEach(
      yamlEditor: yamlEditor,
      func:
          (Map<String, String> dependencies, String depType, String packageName, Object? version) {
            if (version is String) {
              dependencies[packageName] = version;
            }
          },
    );
  }

  void _updatePubspec(Directory package, ResolvedDependencies dependencies) {
    final File pubspecFile = package.childFile(_pubspecName);
    final yamlEditor = YamlEditor(pubspecFile.readAsStringSync());
    dependencies.forEach(
      yamlEditor: yamlEditor,
      func:
          (Map<String, String> dependencies, String depType, String packageName, Object? version) {
            if (dependencies.containsKey(packageName)) {
              final String version = dependencies[packageName]!;
              yamlEditor.update(<String>[depType, packageName], version);
            }
          },
    );
    pubspecFile.writeAsStringSync(yamlEditor.toString());
  }

  void _verifyPubspecs(List<Directory> packages) {
    globals.printStatus('Verifying pubspecs...');
    for (final directory in packages) {
      globals.printTrace('Reading pubspec.yaml from ${directory.path}');
      final String pubspecString = directory.childFile(_pubspecName).readAsStringSync();
      _checkHash(pubspecString, directory);
    }
  }

  void _checkWithFlutterTools(Directory rootDirectory) {
    final pubspec = Pubspec.parse(rootDirectory.childFile(_pubspecName).readAsStringSync());
    final pubspecTools = Pubspec.parse(
      rootDirectory
          .childDirectory('packages')
          .childDirectory('flutter_tools')
          .childFile(_pubspecName)
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

  void _checkPins(Directory directory) {
    final pubspec = Pubspec.parse(directory.childFile(_pubspecName).readAsStringSync());
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
        SdkDependency(:final VersionConstraint version) ||
        HostedDependency(:final VersionConstraint version) => version,
        GitDependency() || PathDependency() => null,
      };
      if (version != null && version.toString() != pin.value) {
        throwToolExit(
          "${pin.key} should be pinned in $directory to version ${pin.value}, but isn't",
        );
      }
    }
  }

  void _checkHash(String pubspec, Directory directory) {
    final RegExpMatch? firstMatch = checksumRegex.firstMatch(pubspec);
    if (firstMatch == null) {
      throwToolExit('Pubspec in ${directory.path} does not contain a checksum.');
    }
    final String checksum = firstMatch[1]!;
    final String actualChecksum = _computeChecksum(pubspec);
    if (checksum != actualChecksum) {
      throwToolExit(
        'Pubspec in ${directory.path} has out of date dependencies. '
        'Please run "flutter update-packages --force-upgrade --update-hashes" to '
        'update them correctly. The hash ($checksum) does not match the '
        'expectation ($actualChecksum).',
      );
    }
  }

  void _writeHashesToPubspecs(List<Directory> packages) {
    globals.printStatus('Writing hashes to pubspecs...');
    for (final directory in packages) {
      globals.printTrace('Reading pubspec.yaml from ${directory.path}');
      final File pubspecFile = directory.childFile(_pubspecName);
      String pubspec = pubspecFile.readAsStringSync();
      final String actualChecksum = _computeChecksum(pubspec);
      final RegExpMatch? firstMatch = checksumRegex.firstMatch(pubspec);
      if (firstMatch != null) {
        pubspec = pubspec.replaceRange(
          firstMatch.start,
          firstMatch.end,
          '$kDependencyChecksum$actualChecksum',
        );
      } else {
        pubspec += '\n$kDependencyChecksum$actualChecksum';
      }
      pubspecFile.writeAsStringSync(pubspec);
    }
    globals.printStatus('All pubspecs are now up to date.');
  }

  String _computeChecksum(String pubspecString) {
    final pubspec = Pubspec.parse(pubspecString);
    return SplayTreeMap<String, Dependency>.from(<String, Dependency>{
          ...pubspec.dependencies.map(
            (String key, Dependency value) => MapEntry<String, Dependency>('dep:$key', value),
          ),
          ...pubspec.devDependencies.map(
            (String key, Dependency value) => MapEntry<String, Dependency>('dev_dep:$key', value),
          ),
          ...pubspec.dependencyOverrides.map(
            (String key, Dependency value) => MapEntry<String, Dependency>('dep_over:$key', value),
          ),
        }).entries
        .map((MapEntry<String, Dependency> entry) => '${entry.key}${entry.value}')
        .join()
        .hashCode
        .toRadixString(32);
  }

  /// This is the string we output next to each of our autogenerated transitive
  /// dependencies so that we can ignore them the next time we parse the
  /// pubspec.yaml file.
  static const kTransitiveMagicString =
      '# THIS LINE IS AUTOGENERATED - TO UPDATE USE "flutter update-packages --force-upgrade"';

  /// This is the string output before a checksum of the packages used.
  static const kDependencyChecksum = '# PUBSPEC CHECKSUM: ';
  final checksumRegex = RegExp('$kDependencyChecksum([a-zA-Z0-9]+)');
}

class ResolvedDependencies {
  ResolvedDependencies([Map<String, Map<String, String>>? data])
    : data = data ?? <String, Map<String, String>>{};

  static const _dependencies = 'dependencies';
  static const _devDependencies = 'dev_dependencies';
  final Map<String, Map<String, String>> data;

  void forEach({
    required YamlEditor yamlEditor,
    required void Function(
      Map<String, String> dependencies,
      String depType,
      String packageName,
      Object? version,
    )
    func,
  }) {
    for (final dependencyType in <String>[_dependencies, _devDependencies]) {
      data[dependencyType] ??= <String, String>{};
      final Map<Object?, Object?> map =
          yamlEditor.parseAt(<String>[dependencyType], orElse: () => YamlMap()) as YamlMap;
      for (final MapEntry<Object?, Object?> dep in map.entries) {
        final packageName = dep.key! as String;
        final Object? restriction = dep.value;
        func(data[dependencyType]!, dependencyType, packageName, restriction);
      }
    }
  }

  static ResolvedDependencies mergeDeps(
    ResolvedDependencies oldDeps,
    ResolvedDependencies newDeps,
    List<CherryPick> cherryPicks,
  ) {
    final mergedDeps = ResolvedDependencies(<String, Map<String, String>>{...newDeps.data});
    for (final MapEntry<String, Map<String, String>> entry in mergedDeps.data.entries) {
      final String dependencyType = entry.key;
      final Map<String, String>? oldData = oldDeps.data[dependencyType];
      for (final MapEntry<String, String> dep in entry.value.entries) {
        final String packageName = dep.key;
        final String newVersion = dep.value;
        final String? oldVersion =
            cherryPicks
                .where((CherryPick pick) => pick.package == packageName)
                .map((CherryPick pick) => pick.version)
                .firstOrNull ??
            oldData?[packageName];
        mergedDeps.data[dependencyType]![packageName] = oldVersion?.startsWith('^') ?? false
            ? _versionWithCaret(newVersion)
            : _versionWithoutCaret(newVersion);
      }
    }
    return mergedDeps;
  }
}

typedef CherryPick = ({String package, String version});

/// How much dependencies should be relaxed when fetching new versions.
enum RelaxMode {
  /// Relax to an `any` dep, so major changes can be made.
  any,

  /// Relax to `^...`, so only minor changes can be made.
  caret,

  /// Do not relax, so keep the exact version.
  strict,
}

String _versionWithCaret(String version) => version.startsWith('^') ? version : '^$version';

String _versionWithoutCaret(String version) =>
    version.startsWith('^') ? version.substring(1) : version;
