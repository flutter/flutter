// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({ this.hidden: false }) {
    argParser.addFlag(
      'force-upgrade',
      help: 'Attempt to update all the dependencies to their latest versions.\n'
            'This will actually modify the pubspec.yaml files in your checkout.',
      defaultsTo: false,
    );
  }

  @override
  final String name = 'update-packages';

  @override
  final String description = 'Update the packages inside the Flutter repo.';

  @override
  final bool hidden;

  Future<Null> _downloadCoverageData() async {
    final Status status = logger.startProgress('Downloading lcov data for package:flutter...', expectSlowOperation: true);
    final List<int> data = await fetchUrl(Uri.parse('https://storage.googleapis.com/flutter_infra/flutter/coverage/lcov.info'));
    final String coverageDir = fs.path.join(Cache.flutterRoot, 'packages/flutter/coverage');
    fs.file(fs.path.join(coverageDir, 'lcov.base.info'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data, flush: true);
    fs.file(fs.path.join(coverageDir, 'lcov.info'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data, flush: true);
    status.stop();
  }

  @override
  Future<Null> runCommand() async {
    final List<Directory> packages = runner.getRepoPackages();

    final bool upgrade = argResults['force-upgrade'];
    if (upgrade) {
      printStatus('Upgrading packages...');
      final List<PubspecYaml> pubspecs = <PubspecYaml>[];
      final Map<String, PubspecDependency> dependencies = <String, PubspecDependency>{};
      final Set<String> specialDependencies = new Set<String>();
      for (Directory directory in packages) {
        printTrace('Reading pubspec.yaml from: ${directory.path}');
        final PubspecYaml pubspec = new PubspecYaml(directory);
        pubspecs.add(pubspec);
        for (PubspecDependency dependency in pubspec.dependencies) {
          if (dependencies.containsKey(dependency.name)) {
            final PubspecDependency previous = dependencies[dependency.name];
            if (dependency.kind != previous.kind || dependency.lockTarget != previous.lockTarget)
              throw 'Inconsistent requirements around ${dependency.name}; saw ${dependency.kind} (${dependency.lockTarget}) in "${dependency.sourcePath}" and ${previous.kind} (${previous.lockTarget}) in "${previous.sourcePath}".';
          }
          dependencies[dependency.name] = dependency;
          if (dependency.kind != DependencyKind.normal)
            specialDependencies.add(dependency.name);
        }
      }

      final PubDependencyTree tree = new PubDependencyTree();
      final Directory temporaryDirectory = fs.systemTempDirectory.createTempSync('flutter_update_packages_');
      try {
        final File fakePackage = _pubspecFor(temporaryDirectory);
        fakePackage.createSync();
        fakePackage.writeAsStringSync(_generateFakePubspec(dependencies.values));
        await pubGet(directory: temporaryDirectory.path, upgrade: true, checkLastModified: false);
        await pub(<String>['deps', '--style=compact'], directory: temporaryDirectory.path, filter: tree.fill, retry: true);
      } finally {
        temporaryDirectory.deleteSync(recursive: true);
      }

      for (PubspecYaml pubspec in pubspecs)
        pubspec.apply(tree, specialDependencies);
    }

    final Stopwatch timer = new Stopwatch()..start();
    int count = 0;

    for (Directory dir in packages) {
      await pubGet(directory: dir.path, checkLastModified: false);
      count += 1;
    }

    await _downloadCoverageData();

    final double seconds = timer.elapsedMilliseconds / 1000.0;
    printStatus('\nRan \'pub\' $count time${count == 1 ? "" : "s"} and fetched coverage data in ${seconds.toStringAsFixed(1)}s.');
  }
}

enum Section { dependencies, devDependencies, dependencyOverrides, other }

const String kTransitiveMagicString = '# TRANSITIVE DEPENDENCY';

class PubspecYaml {
  factory PubspecYaml(Directory directory) {
    final File file = _pubspecFor(directory);
    return new PubspecYaml._(file, _parse(file.path, file.readAsLinesSync()));
  }

  PubspecYaml._(this.file, this.inputData);

  final File file;

  final List<PubspecLine> inputData;

  static List<PubspecLine> _parse(String filename, List<String> lines) {
    final List<PubspecLine> result = <PubspecLine>[];
    Section section = Section.other;
    bool seenMain = false;
    bool seenDev = false;
    final Map<String, PubspecDependency> masterDependencies = <String, PubspecDependency>{};
    PubspecDependency lastDependency;
    for (String line in lines) {
      if (lastDependency != null) {
        if (line.trim().isNotEmpty) {
          if (!lastDependency.parseLock(line, filename, lockIsOverride: section == Section.dependencyOverrides)) {
            result.removeLast();
            result.add(new PubspecLine(lastDependency.line));
            result.add(new PubspecLine(line));
          }
          lastDependency = null;
        }
      } else {
        final PubspecHeader header = PubspecHeader.parse(line);
        if (header != null) {
          section = header.section;
          if (section == Section.devDependencies) {
            if (seenDev)
              throw 'Two dev_dependencies sections found in $filename. There should only be one.';
            seenDev = true;
          } else if (section == Section.dependencies) {
            if (seenMain)
              throw 'Two dependencies sections found in $filename. There should only be one.';
            if (seenDev)
              throw 'The dependencies section was after the dev_dependencies section in $filename. To enable one-pass processing, the dependencies section must come before the dev_dependencies section.';
            seenMain = true;
          }
          result.add(header);
        } else if (section == Section.other) {
          result.add(new PubspecLine(line));
        } else {
          final PubspecDependency dependency = PubspecDependency.parse(line, filename: filename);
          if (dependency != null) {
            result.add(dependency);
            if (dependency.kind == DependencyKind.unknown)
              lastDependency = dependency;
            if (section != Section.dependencyOverrides) {
              masterDependencies[dependency.name] = dependency;
            } else {
              masterDependencies[dependency.name]?.markOverridden(dependency);
            }
          } else {
            result.add(new PubspecLine(line));
          }
        }
      }
    }
    return result;
  }

  Set<PubspecDependency> get dependencies {
    final Map<String, PubspecDependency> result = <String, PubspecDependency>{};
    Section section = Section.other;
    for (PubspecLine data in inputData) {
      if (data is PubspecHeader) {
        section = data.section;
      } else if (data is PubspecDependency) {
        if (!data.isTransitive) { // we ignore our magic transitive dependencies entirely
          switch (section) {
            case Section.dependencies:
            case Section.devDependencies:
              if (result.containsKey(data.name))
                throw '${file.path} contains two dependencies on ${data.name}.';
              result[data.name] = data;
              break;
            case Section.dependencyOverrides:
              result[data.name] = data;
              break;
            default:
              // ignore things that look like dependencies in other sections
              break;
          }
        }
      }
    }
    return new Set<PubspecDependency>.from(
      result.values.where((PubspecDependency dependency) => !dependency.isTransitive),
    );
  }

  void apply(PubDependencyTree versions, Set<String> specialDependencies) {
    assert(versions != null);
    final List<String> output = <String>[];
    final Set<String> done = new Set<String>();
    Section section = Section.other;
    int lastPossiblePlace;
    for (PubspecLine data in inputData) {
      if (data is PubspecHeader) {
        if (section == Section.dependencies || section == Section.devDependencies)
          lastPossiblePlace = output.length;
        section = data.section;
        output.add(data.line);
      } else if (data is PubspecDependency) {
        switch (section) {
          case Section.dependencies:
          case Section.devDependencies:
            if (!data.isTransitive) {
              assert(!done.contains(data.name));
              assert(versions.contains(data.name));
              if (data.kind == DependencyKind.normal) {
                output.add('  ${data.name}: ${versions.versionFor(data.name)}${data.suffix}');
              } else {
                output.add(data.line);
                if (data.lockLine != null)
                  output.add(data.lockLine);
              }
              done.add(data.name);
            }
            if (section == Section.dependencies || section == Section.devDependencies)
              lastPossiblePlace = output.length;
            break;
          default:
            // in other sections, pass them through, ignored
            output.add(data.line);
            if (data.lockLine != null)
              output.add(data.lockLine);
            break;
        }
      } else {
        output.add(data.line);
      }
    }

    assert(lastPossiblePlace != null);

    final List<String> transitiveDependencyOutput = <String>[];
    // Now include all the transitive dependencies
    final Set<String> transitiveDependencies = new Set<String>();
    done.addAll(specialDependencies);
    for (String package in done.toList())
      transitiveDependencies.addAll(versions.getTransitiveDependenciesFor(package, seen: new Set<String>.from(done)));
    final List<String> transitiveDependenciesAsList = transitiveDependencies.toList()..sort();
    transitiveDependencyOutput.add('');
    for (String package in transitiveDependenciesAsList)
      transitiveDependencyOutput.add('  $package: ${versions.versionFor(package)} $kTransitiveMagicString');
    transitiveDependencyOutput.add('');
    output.insertAll(lastPossiblePlace, transitiveDependencyOutput);

    while (output.last.isEmpty)
      output.removeLast();

    final StringBuffer contents = new StringBuffer();
    bool hadBlankLine = true;
    for (String line in output) {
      line = line.trimRight();
      if (line == '') {
        if (!hadBlankLine)
          contents.writeln('');
        hadBlankLine = true;
      } else {
        contents.writeln(line);
        hadBlankLine = false;
      }
    }
    file.writeAsStringSync(contents.toString());
  }
}

class PubspecLine {
  PubspecLine(this.line);
  final String line;
}

class PubspecHeader extends PubspecLine {
  PubspecHeader(String line, this.section) : super(line);
  final Section section;

  static PubspecHeader parse(String line) {
    if (line.startsWith(' '))
      return null;
    final String strippedLine = _stripComments(line);
    if (!strippedLine.endsWith(':'))
      return null;
    final String sectionName = strippedLine.substring(0, strippedLine.length - 1);
    switch (sectionName) {
      case 'dependencies':
        return new PubspecHeader(line, Section.dependencies);
      case 'dev_dependencies':
        return new PubspecHeader(line, Section.devDependencies);
      case 'dependency_overrides':
        return new PubspecHeader(line, Section.dependencyOverrides);
      default:
        return new PubspecHeader(line, Section.other);
    }
  }
}

class PubspecOverride extends PubspecLine {
  PubspecOverride(String line, this.package) : super(line);
  final String package;

  static PubspecOverride parse(String line) {
    if (!line.startsWith('  '))
      return null;
    final String strippedLine = _stripComments(line.substring(2));
    if (strippedLine.startsWith(' '))
      return null;
    if (!strippedLine.endsWith(':'))
      return null;
    final String package = strippedLine.substring(0, strippedLine.length - 1);
    return new PubspecOverride(line, package);
  }
}

String _stripComments(String line) {
  final int hashIndex = line.indexOf('#');
  if (hashIndex < 0)
    return line;
  return line.substring(0, hashIndex).trimRight();
}

enum DependencyKind { unknown, overridden, normal, path, sdk }

class PubspecDependency extends PubspecLine {
  PubspecDependency(String line, this.name, this.suffix, {
    @required this.isTransitive,
    DependencyKind kind,
    this.sourcePath,
  }) : _kind = kind, super(line);

  static PubspecDependency parse(String line, { @required String filename }) {
    if (line.length < 4 || line.startsWith('   ') || !line.startsWith('  '))
      return null;
    final int colonIndex = line.indexOf(':');
    final int hashIndex = line.indexOf('#');
    if (colonIndex < 3) // two spaces at 0 and 1, a character at 2
      return null;
    if (hashIndex >= 0 && hashIndex < colonIndex)
      return null;
    final String package = line.substring(2, colonIndex).trimRight();
    assert(package.isNotEmpty);
    assert(line.startsWith('  $package'));
    String suffix = '';
    bool isTransitive = false;
    String stripped;
    if (hashIndex >= 0) {
      assert(hashIndex > colonIndex);
      final String trailingComment = line.substring(hashIndex, line.length);
      assert(line.endsWith(trailingComment));
      isTransitive = trailingComment == kTransitiveMagicString;
      suffix = ' ' + trailingComment;
      stripped = line.substring(colonIndex + 1, hashIndex).trimRight();
    } else {
      stripped = line.substring(colonIndex + 1, line.length).trimRight();
    }
    return new PubspecDependency(line, package, suffix, isTransitive: isTransitive, kind: stripped.isEmpty ? DependencyKind.unknown : DependencyKind.normal, sourcePath: filename);
  }

  final String name;
  final String suffix;
  final bool isTransitive;
  final String sourcePath;

  DependencyKind get kind => _kind;
  DependencyKind _kind = DependencyKind.normal;

  String get lockTarget => _lockTarget;
  String _lockTarget;

  String get lockLine => _lockLine;
  String _lockLine;

  bool get lockIsOverride => _lockIsOverride;
  bool _lockIsOverride;

  static const String _kPathPrefix = '    path: ';
  static const String _kSdkPrefix = '    sdk: ';
  static const String _kGitPrefix = '    git:';

  bool parseLock(String line, String pubspecPath, { @required bool lockIsOverride }) {
    assert(lockIsOverride != null);
    if (line.startsWith(_kPathPrefix)) {
      _lockTarget = fs.path.absolute(fs.path.dirname(pubspecPath), line.substring(_kPathPrefix.length, line.length));
      _kind = DependencyKind.path;
    } else if (line.startsWith(_kSdkPrefix)) {
      _lockTarget = line.substring(_kSdkPrefix.length, line.length);
      _kind = DependencyKind.sdk;
    } else if (line.startsWith(_kGitPrefix)) {
      return false;
    } else {
      throw 'Could not parse additional details for dependency $name; line was: "$line"';
    }
    _lockIsOverride = lockIsOverride;
    _lockLine = line;
    return true;
  }

  void markOverridden(PubspecDependency sibling) {
    assert(sibling.name == name);
    assert(sibling.sourcePath == sourcePath);
    assert(sibling.kind != DependencyKind.normal);
    _kind = DependencyKind.overridden;
  }

  void describeForFakePubspec(StringBuffer dependencies, StringBuffer overrides) {
    switch (kind) {
      case DependencyKind.unknown:
      case DependencyKind.overridden:
        assert(kind != DependencyKind.unknown);
        break;
      case DependencyKind.normal:
        dependencies.writeln('  $name: any');
        break;
      case DependencyKind.path:
        if (_lockIsOverride) {
          dependencies.writeln('  $name: any');
          overrides.writeln('  $name:');
          overrides.writeln('    path: $lockTarget');
        } else {
          dependencies.writeln('  $name:');
          dependencies.writeln('    path: $lockTarget');
        }
        break;
      case DependencyKind.sdk:
        if (_lockIsOverride) {
          dependencies.writeln('  $name: any');
          overrides.writeln('  $name:');
          overrides.writeln('    sdk: $lockTarget');
        } else {
          dependencies.writeln('  $name:');
          dependencies.writeln('    sdk: $lockTarget');
        }
        break;
    }
  }
}

File _pubspecFor(Directory directory) {
  return fs.file('${directory.path}/pubspec.yaml');
}

String _generateFakePubspec(Iterable<PubspecDependency> dependencies) {
  final StringBuffer result = new StringBuffer();
  final StringBuffer overrides = new StringBuffer();
  result.writeln('name: flutter_update_packages');
  result.writeln('dependencies:');
  overrides.writeln('dependency_overrides:');
  for (PubspecDependency dependency in dependencies)
    dependency.describeForFakePubspec(result, overrides);
  result.write(overrides.toString());
  return result.toString();
}

class PubDependencyTree {
  final Map<String, String> _versions = <String, String>{};
  final Map<String, Set<String>> _dependencyTree = <String, Set<String>>{};

  String fill(String message) {
    if (message.startsWith('- ')) {
      final int space2 = message.indexOf(' ', 2);
      int space3 = message.indexOf(' ', space2 + 1);
      if (space3 < 0)
        space3 = message.length;
      final String package = message.substring(2, space2);
      if (!contains(package)) {
        // Some packages get listed in the dependency overrides section too.
        // We just ignore those. The data is the same either way.
        final String version = message.substring(space2 + 1, space3);
        List<String> dependencies;
        if (space3 < message.length) {
          assert(message[space3 + 1] == '[');
          assert(message[message.length - 1] == ']');
          final String allDependencies = message.substring(space3 + 2, message.length - 1);
          dependencies = allDependencies.split(' ');
        } else {
          dependencies = const <String>[];
        }
        _versions[package] = version;
        _dependencyTree[package] = new Set<String>.from(dependencies);
      }
    }
    return null;
  }

  bool contains(String package) {
    return _versions.containsKey(package);
  }

  Iterable<String> getTransitiveDependenciesFor(String package, { Set<String> seen }) sync* {
    seen ??= new Set<String>();
    for (String dependency in _dependencyTree[package]) {
      if (!seen.contains(dependency)) {
        yield dependency;
        seen.add(dependency);
        yield* getTransitiveDependenciesFor(dependency, seen: seen);
      }
    }
  }

  String versionFor(String package) {
    return _versions[package];
  }
}
