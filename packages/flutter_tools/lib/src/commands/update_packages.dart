// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/net.dart';
import '../base/platform.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

/// Map from package name to package version, used to artificially pin a pub
/// package version in cases when upgrading to the latest breaks Flutter.
///
/// Example:
///
/// ```
///   'linter': '0.1.35', // TODO(yjbanov): https://github.com/dart-lang/linter/issues/824
/// ```
const Map<String, String> _kManuallyPinnedDependencies = const <String, String>{
  // Add pinned packages here.
};

class UpdatePackagesCommand extends FlutterCommand {
  UpdatePackagesCommand({ this.hidden: false }) {
    argParser
      ..addFlag(
        'force-upgrade',
        help: 'Attempt to update all the dependencies to their latest versions.\n'
              'This will actually modify the pubspec.yaml files in your checkout.',
        defaultsTo: false,
      )
      ..addFlag(
        'paths',
        help: 'Finds paths in the dependency chain leading from package specified '
              'in --from to package specified in --to.',
        defaultsTo: false,
      )
      ..addOption(
        'from',
        help: 'Used with flag --dependency-path. Specifies the package to begin '
              'searching dependency path from.',
      )
      ..addOption(
        'to',
        help: 'Used with flag --dependency-path. Specifies the package that the '
              'sought after dependency path leads to.',
      )
      ..addFlag(
        'transitive-closure',
        help: 'Prints the dependency graph that is the transitive closure of '
              'packages the Flutter SDK depends on.',
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
    final String urlBase = platform.environment['FLUTTER_STORAGE_BASE_URL'] ?? 'https://storage.googleapis.com';
    final List<int> data = await fetchUrl(Uri.parse('$urlBase/flutter_infra/flutter/coverage/lcov.info'));
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
    final bool isPrintPaths = argResults['paths'];
    final bool isPrintTransitiveClosure = argResults['transitive-closure'];
    if (upgrade || isPrintPaths || isPrintTransitiveClosure) {
      printStatus('Upgrading packages...');
      // This feature attempts to collect all the packages used across all the
      // pubspec.yamls in the repo (including via transitive dependencies), and
      // find the latest version of each that can be used while keeping each
      // such package fixed at a single version across all the pubspec.yamls.
      //
      // First, collect up the explicit dependencies:
      final List<PubspecYaml> pubspecs = <PubspecYaml>[];
      final Map<String, PubspecDependency> dependencies = <String, PubspecDependency>{};
      final Set<String> specialDependencies = new Set<String>();
      for (Directory directory in packages) { // these are all the directories with pubspec.yamls we care about
        printTrace('Reading pubspec.yaml from: ${directory.path}');
        final PubspecYaml pubspec = new PubspecYaml(directory); // this parses the pubspec.yaml
        pubspecs.add(pubspec); // remember it for later
        for (PubspecDependency dependency in pubspec.dependencies) { // this is all the explicit dependencies
          if (dependencies.containsKey(dependency.name)) {
            // If we've seen the dependency before, make sure that we are
            // importing it the same way. There's several ways to import a
            // dependency. Hosted (from pub via version number), by path (e.g.
            // pointing at the version of a package we get from the Dart SDK
            // that we download with Flutter), by SDK (e.g. the "flutter"
            // package is explicitly from "sdk: flutter").
            //
            // This makes sure that we don't import a package in two different
            // ways, e.g. by saying "sdk: flutter" in one pubspec.yaml and
            // saying "path: ../../..." in another.
            final PubspecDependency previous = dependencies[dependency.name];
            if (dependency.kind != previous.kind || dependency.lockTarget != previous.lockTarget) {
              throw 'Inconsistent requirements around ${dependency.name}; '
                    'saw ${dependency.kind} (${dependency.lockTarget}) in "${dependency.sourcePath}" '
                    'and ${previous.kind} (${previous.lockTarget}) in "${previous.sourcePath}".';
            }
          }
          // Remember this dependency by name so we can look it up again.
          dependencies[dependency.name] = dependency;
          // Normal dependencies are those we get from pub. The others we
          // already implicitly pin since we pull down one version of the
          // Flutter and Dart SDKs, so we track which those are here so that we
          // can omit them from our list of pinned dependencies later.
          if (dependency.kind != DependencyKind.normal)
            specialDependencies.add(dependency.name);
        }
      }

      // Now that we have all the dependencies we explicitly care about, we are
      // going to create a fake package and then run "pub upgrade" on it. The
      // pub tool will attempt to bring these dependencies up to the most recent
      // possible versions while honoring all their constraints.
      final PubDependencyTree tree = new PubDependencyTree(); // object to collect results
      final Directory temporaryDirectory = fs.systemTempDirectory.createTempSync('flutter_update_packages_');
      try {
        final File fakePackage = _pubspecFor(temporaryDirectory);
        fakePackage.createSync();
        fakePackage.writeAsStringSync(_generateFakePubspec(dependencies.values));
        // First we run "pub upgrade" on this generated package:
        await pubGet(context: PubContext.updatePackages, directory: temporaryDirectory.path, upgrade: true, checkLastModified: false);
        // Then we run "pub deps --style=compact" on the result. We pipe all the
        // output to tree.fill(), which parses it so that it can create a graph
        // of all the dependencies so that we can figure out the transitive
        // dependencies later. It also remembers which version was selected for
        // each package.
        await pub(
          <String>['deps', '--style=compact'],
          context: PubContext.updatePackages,
          directory: temporaryDirectory.path,
          filter: tree.fill,
          retry: false, // errors here are usually fatal since we're not hitting the network
        );
      } finally {
        temporaryDirectory.deleteSync(recursive: true);
      }

      // The transitive dependency tree for the fake package does not contain
      // dependencies between Flutter SDK packages and pub packages. We add them
      // here.
      for (PubspecYaml pubspec in pubspecs) {
        final String package = pubspec.name;
        final String version = pubspec.version;
        for (PubspecDependency dependency in pubspec.dependencies) {
          if (dependency.kind == DependencyKind.normal) {
            tree._versions[package] = version;
            tree._dependencyTree[package] ??= new Set<String>();
            tree._dependencyTree[package].add(dependency.name);
          }
        }
      }

      if (isPrintTransitiveClosure) {
        tree._dependencyTree.forEach((String from, Set<String> to) {
          printStatus('$from -> $to');
        });
        return;
      }

      if (isPrintPaths) {
        showDependencyPaths(from: argResults['from'], to: argResults['to'], tree: tree);
        return;
      }

      // Now that we have collected all the data, we can apply our dependency
      // versions to each pubspec.yaml that we collected. This mutates the
      // pubspec.yaml files.
      //
      // The specialDependencies argument is the set of package names to not pin
      // to specific versions because they are explicitly pinned by their
      // constraints. Here we list the names we earlier established we didn't
      // need to pin because they come from the Dart or Flutter SDKs.
      for (PubspecYaml pubspec in pubspecs)
        pubspec.apply(tree, specialDependencies);

      // Now that the pubspec.yamls are updated, we run "pub get" on each one so
      // that the various packages are ready to use. This is what "flutter
      // update-packages" does without --force-upgrade, so we can just fall into
      // the regular code path.
    }

    final Stopwatch timer = new Stopwatch()..start();
    int count = 0;

    for (Directory dir in packages) {
      await pubGet(context: PubContext.updatePackages, directory: dir.path, checkLastModified: false);
      count += 1;
    }

    await _downloadCoverageData();

    final double seconds = timer.elapsedMilliseconds / 1000.0;
    printStatus('\nRan \'pub\' $count time${count == 1 ? "" : "s"} and fetched coverage data in ${seconds.toStringAsFixed(1)}s.');
  }

  void showDependencyPaths({
    @required String from,
    @required String to,
    @required PubDependencyTree tree,
  }) {
    if (!tree.contains(from))
      throw new ToolExit('Package $from not found in the dependency tree.');
    if (!tree.contains(to))
      throw new ToolExit('Package $to not found in the dependency tree.');

    final Queue<_DependencyLink> traversalQueue = new Queue<_DependencyLink>();
    final Set<String> visited = new Set<String>();
    final List<_DependencyLink> paths = <_DependencyLink>[];

    traversalQueue.addFirst(new _DependencyLink(from: null, to: from));
    while (traversalQueue.isNotEmpty) {
      final _DependencyLink link = traversalQueue.removeLast();
      if (link.to == to)
        paths.add(link);
      if (link.from != null)
        visited.add(link.from.to);
      for (String dependency in tree._dependencyTree[link.to]) {
        if (!visited.contains(dependency)) {
          traversalQueue.addFirst(new _DependencyLink(from: link, to: dependency));
        }
      }
    }

    for (_DependencyLink path in paths) {
      final StringBuffer buf = new StringBuffer();
      while (path != null) {
        buf.write('${path.to}');
        path = path.from;
        if (path != null)
          buf.write(' <- ');
      }
      printStatus(buf.toString());
    }

    if (paths.isEmpty) {
      printStatus('No paths found from $from to $to');
    }
  }
}

class _DependencyLink {
  _DependencyLink({
    @required this.from,
    @required this.to,
  });

  final _DependencyLink from;
  final String to;

  @override
  String toString() => '${from?.to} -> $to';
}

/// The various sections of a pubspec.yaml file.
///
/// We care about the "dependencies", "dev_dependencies", and
/// "dependency_overrides" sections, as well as the "name" and "version" fields
/// in the pubspec header bucketed into [header]. The others are all bucketed
/// into [other].
enum Section { header, dependencies, devDependencies, dependencyOverrides, other }

/// The various kinds of dependencies we know and care about.
enum DependencyKind {
  // Dependencies that will be path or sdk dependencies but
  // for which we haven't yet parsed the data.
  unknown,

  // Regular dependencies with a specified version range.
  normal,

  // Dependency that uses an explicit path, e.g. into the Dart SDK.
  path,

  // Dependency defined as coming from an SDK (typically "sdk: flutter").
  sdk,

  // A dependency that was "normal", but for which we later found a "path" or
  // "sdk" dependency in the dependency_overrides section.
  overridden,
}

/// This is the string we output next to each of our autogenerated transitive
/// dependencies so that we can ignore them the next time we parse the
/// pubspec.yaml file.
const String kTransitiveMagicString = '# TRANSITIVE DEPENDENCY';

/// This class represents a pubspec.yaml file for the purposes of upgrading the
/// dependencies as done by this file.
class PubspecYaml {
  /// You create one of these by providing a directory, from which we obtain the
  /// pubspec.yaml and parse it into a line-by-line form.
  factory PubspecYaml(Directory directory) {
    final File file = _pubspecFor(directory);
    return _parse(file, file.readAsLinesSync());
  }

  PubspecYaml._(this.file, this.name, this.version, this.inputData);

  final File file; // The actual pubspec.yaml file.

  /// The package name.
  final String name;

  /// The package version.
  final String version;

  final List<PubspecLine> inputData; // Each line of the pubspec.yaml file, parsed(ish).

  /// This parses each line of a pubspec.yaml file (a list of lines) into
  /// slightly more structured data (in the form of a list of PubspecLine
  /// objects). We don't just use a YAML parser because we care about comments
  /// and also because we can just define the style of pubspec.yaml files we care
  /// about (since they're all under our control).
  static PubspecYaml _parse(File file, List<String> lines) {
    final String filename = file.path;
    String packageName;
    String packageVersion;
    final List<PubspecLine> result = <PubspecLine>[]; // The output buffer.
    Section section = Section.other; // Which section we're currently reading from.
    bool seenMain = false; // Whether we've seen the "dependencies:" section.
    bool seenDev = false; // Whether we've seen the "dev_dependencies:" section.
    // The masterDependencies map is used to keep track of the objects
    // representing actual dependencies we've seen so far in this file so that
    // if we see dependency overrides we can update the actual dependency so it
    // knows that it's not really a dependency.
    final Map<String, PubspecDependency> masterDependencies = <String, PubspecDependency>{};
    // The "special" dependencies (the ones that use git: or path: or sdk: or
    // whatnot) have the style of having extra data after the line that declares
    // the dependency. So we track what is the "current" (or "last") dependency
    // that we are dealing with using this variable.
    PubspecDependency lastDependency;
    for (String line in lines) {
      if (lastDependency == null) {
        // First we look to see if we're transitioning to a new top-level section.
        // The PubspecHeader.parse static method can recognize those headers.
        final PubspecHeader header = PubspecHeader.parse(line); // See if it's a header.
        if (header != null) { // It is!
          section = header.section; // The parser determined what kind of section it is.
          if (section == Section.header) {
            if (header.name == 'name')
              packageName = header.value;
            else if (header.name == 'version')
              packageVersion = header.value;
          } else if (section == Section.dependencies) {
            // If we're entering the "dependencies" section, we want to make sure that
            // it's the first section (of those we care about) that we've seen so far.
            if (seenMain)
              throw 'Two dependencies sections found in $filename. There should only be one.';
            if (seenDev) {
              throw 'The dependencies section was after the dev_dependencies section in $filename. '
                    'To enable one-pass processing, the dependencies section must come before the '
                    'dev_dependencies section.';
            }
            seenMain = true;
          } else if (section == Section.devDependencies) {
            // Similarly, if we're entering the dev_dependencies section, we should verify
            // that we've not seen one already.
            if (seenDev)
              throw 'Two dev_dependencies sections found in $filename. There should only be one.';
            seenDev = true;
          }
          result.add(header);
        } else if (section == Section.other) {
          // This line isn't a section header, and we're not in a section we care about.
          // We just stick the line into the output unmodified.
          result.add(new PubspecLine(line));
        } else {
          // We're in a section we care about. Try to parse out the dependency:
          final PubspecDependency dependency = PubspecDependency.parse(line, filename: filename);
          if (dependency != null) { // We got one!
            result.add(dependency);
            if (dependency.kind == DependencyKind.unknown) {
              // If we didn't get a version number, then we need to be ready to
              // read the next line as part of this dependency, so keep track of
              // this dependency object.
              lastDependency = dependency;
            }
            if (section != Section.dependencyOverrides) {
              // If we're not in the overrides section, then just remember the
              // dependency, in case it comes up again later in the overrides
              // section.
              //
              // First, make sure it's a unique dependency. Listing dependencies
              // twice doesn't make sense.
              if (masterDependencies.containsKey(dependency.name))
                throw '$filename contains two dependencies on ${dependency.name}.';
              masterDependencies[dependency.name] = dependency;
            } else {
              // If we _are_ in the overrides section, then go tell the version
              // we saw earlier (if any -- there might not be, we might be
              // overriding a transitive dependency) that we have overridden it,
              // so that later when we output the dependencies we can leave
              // the line unmodified.
              masterDependencies[dependency.name]?.markOverridden(dependency);
            }
          } else {
            // We're in a section we care about but got a line we didn't
            // recognize. Maybe it's a comment or a blank line or something.
            // Just pass it through.
            result.add(new PubspecLine(line));
          }
        }
      } else {
        // If we're here it means the last line was a dependency that needed
        // extra information to be parsed from the next line.
        //
        // Try to parse the line by giving it to the last PubspecDependency
        // object we created. If parseLock fails to recognize the line, it will
        // throw. If it does recognize the line but decides it's one we don't
        // care about (specifically, "git:" dependencies), it'll return false.
        // Otherwise it returns true.
        //
        // If it returns true, then it will have updated itself internally to
        // store the information from this line.
        if (!lastDependency.parseLock(line, filename, lockIsOverride: section == Section.dependencyOverrides)) {
          // Ok we're dealing with some "git:" dependency. Let's pretend we
          // never saw it. In practice this is only used for the flutter gallery
          // assets dependency which we don't care about especially since it has
          // no subdependencies and it's pinned by git hash.
          //
          // Remove the PubspecDependency entry we had for it and replace it
          // with a PubspecLine entry, and add such an entry for this line.
          result.removeLast();
          result.add(new PubspecLine(lastDependency.line));
          result.add(new PubspecLine(line));
        }
        // We're done with this special dependency, so reset back to null so
        // we'll go in the top section next time instead.
        lastDependency = null;
      }
    }
    return new PubspecYaml._(file, packageName, packageVersion, result);
  }

  /// This returns all the explicit dependencies that this pubspec.yaml lists.
  Iterable<PubspecDependency> get dependencies sync* {
    // It works by iterating over the parsed data from _parse above, collecting
    // all the dependencies that were found, ignoring any that are flagged as as
    // overridden by subsequent entries in the same file and any that have the
    // magic comment flagging them as auto-generated transitive dependencies
    // that we added in a previous run.
    for (PubspecLine data in inputData) {
      if (data is PubspecDependency && data.kind != DependencyKind.overridden && !data.isTransitive)
        yield data;
    }
  }

  /// Take a dependency graph with explicit version numbers, and apply them to
  /// the pubspec.yaml, ignoring any that we know are special dependencies (those
  /// that depend on the Flutter or Dart SDK directly and are thus automatically
  /// pinned).
  void apply(PubDependencyTree versions, Set<String> specialDependencies) {
    assert(versions != null);
    final List<String> output = <String>[]; // the string data to output to the file, line by line
    final Set<String> directDependencies = new Set<String>(); // packages this pubspec directly depends on (i.e. not transitive)
    Section section = Section.other; // the section we're currently handling
    int lastPossiblePlace; // the line number where we're going to insert the transitive dependencies
    // Walk the pre-parsed input file, outputting it unmodified except for
    // updating version numbers, removing the old transitive dependencies lines,
    // and adding our new transitive dependencies lines. We also do a little
    // cleanup, removing trailing spaces, removing double-blank lines, leading
    // blank lines, and trailing blank lines, and ensuring the file ends with a
    // newline. This cleanup lets us be a little more aggressive while building
    // the output.
    for (PubspecLine data in inputData) {
      if (data is PubspecHeader) {
        // This line was a header of some sort.
        //
        // If we're leaving one of the sections in which we can list transitive
        // dependencies, then remember this as the current last known valid
        // place to insert our transitive dependencies.
        if (section == Section.dependencies || section == Section.devDependencies)
          lastPossiblePlace = output.length;
        section = data.section; // track which section we're now in.
        output.add(data.line); // insert the header into the output
      } else if (data is PubspecDependency) {
        // This was a dependency of some sort.
        // How we handle this depends on the section.
        switch (section) {
          case Section.dependencies:
          case Section.devDependencies:
            // For the dependencies and dev_dependencies sections, we reinsert
            // the dependency if it wasn't one of our autogenerated transitive
            // dependency lines.
            if (!data.isTransitive) {
              // Assert that we haven't seen it in this file already.
              assert(!directDependencies.contains(data.name));
              if (data.kind == DependencyKind.normal) {
                // This is a regular dependency, so we need to update the
                // version number.
                //
                // We output data that matches the format that
                // PubspecDependency.parse can handle. The data.suffix is any
                // previously-specified trailing comment.
                assert(versions.contains(data.name));
                output.add('  ${data.name}: ${versions.versionFor(data.name)}${data.suffix}');
              } else {
                // If it wasn't a regular dependency, then we output the line
                // unmodified. If there was an additional line (e.g. an "sdk:
                // flutter" line) then we output that too.
                output.add(data.line);
                if (data.lockLine != null)
                  output.add(data.lockLine);
              }
              // Remember that we've dealt with this dependency so we don't
              // mention it again when doing the transitive dependencies.
              directDependencies.add(data.name);
            }
            // Since we're in one of the places where we can list dependencies,
            // remember this as the current last known valid place to insert our
            // transitive dependencies.
            lastPossiblePlace = output.length;
            break;
          default:
            // In other sections, pass everything through in its original form.
            output.add(data.line);
            if (data.lockLine != null)
              output.add(data.lockLine);
            break;
        }
      } else {
        // Not a header, not a dependency, just pass that through unmodified.
        output.add(data.line);
      }
    }

    // By this point we should know where to put our transitive dependencies.
    // Only if there were no dependencies: or dev_dependencies: sections could
    // we get here with this still null, and we should not have any such files
    // in our repo.
    assert(lastPossiblePlace != null);

    // Now include all the transitive dependencies.
    final List<String> transitiveDependencyOutput = <String>[]; // the block of text to insert
    final Set<String> transitiveDependencies = new Set<String>(); // which dependencies we need to handle
    // Merge the list of dependencies we've seen in this file and the dependencies we know this
    // file mentions that are already pinned (and which didn't get special processing above).
    final Set<String> implied = new Set<String>.from(directDependencies)..addAll(specialDependencies);
    // Create a new set to hold the list of packages we've already processed, so
    // that we don't redundantly process them multiple times.
    final Set<String> done = new Set<String>();
    for (String package in directDependencies.toList())
      transitiveDependencies.addAll(versions.getTransitiveDependenciesFor(package, seen: done, exclude: implied));
    // Sort that list lexically so that we don't get noisy diffs when upgrading.
    final List<String> transitiveDependenciesAsList = transitiveDependencies.toList()..sort();
    // Add a blank line to keep the output clean. It doesn't matter if this adds
    // redundant blank lines because we'll clean them out later.
    transitiveDependencyOutput.add('');
    // Add a line for each transitive dependency using our magic string to recognize them later.
    for (String package in transitiveDependenciesAsList)
      transitiveDependencyOutput.add('  $package: ${versions.versionFor(package)} $kTransitiveMagicString');
    // Add a blank line on the other end to keep the output clean again, as before.
    transitiveDependencyOutput.add('');
    // Insert the block of transitive dependency declarations into the output in
    // the place we previously established was optimal.
    output.insertAll(lastPossiblePlace, transitiveDependencyOutput);

    // Remove trailing lines.
    while (output.last.isEmpty)
      output.removeLast();

    // Output the result to the pubspec.yaml file, skipping leading and
    // duplicate blank lines and removing trailing spaces.
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

/// This is the base class for the objects that represent lines in the
/// pubspec.yaml files.
class PubspecLine {
  PubspecLine(this.line);

  /// The raw line as we saw it in the original file. This is used so that we can
  /// output the same line unmodified for the majority of lines.
  final String line;
}

/// A header, e.g. "dependencies:".
class PubspecHeader extends PubspecLine {
  PubspecHeader(String line, this.section, { this.name, this.value }) : super(line);

  /// The section of the pubspec where the parse [line] appears.
  final Section section;

  /// The name in the pubspec line providing a name/value pair, such as "name"
  /// and "version".
  ///
  /// Example:
  ///
  /// The value of this field extracted from the following line is "version".
  ///
  /// ```
  /// version: 0.16.5
  /// ```
  final String name;

  /// The value in the pubspec line providing a name/value pair, such as "name"
  /// and "version".
  ///
  /// Example:
  ///
  /// The value of this field extracted from the following line is "0.16.5".
  ///
  /// ```
  /// version: 0.16.5
  /// ```
  final String value;

  static PubspecHeader parse(String line) {
    // We recognize any line that:
    //  * doesn't start with a space (i.e. is aligned on the left edge)
    //  * ignoring trailing spaces and comments, ends with a colon
    //  * has contents before the colon
    // We also try to recognize which of the kinds of Sections it is
    // by comparing those contents against known strings.
    if (line.startsWith(' '))
      return null;
    final String strippedLine = _stripComments(line);
    if (!strippedLine.contains(':') || strippedLine.length <= 1)
      return null;
    final List<String> parts = strippedLine.split(':');
    final String sectionName = parts.first;
    final String value = parts.last.trim();
    switch (sectionName) {
      case 'dependencies':
        return new PubspecHeader(line, Section.dependencies);
      case 'dev_dependencies':
        return new PubspecHeader(line, Section.devDependencies);
      case 'dependency_overrides':
        return new PubspecHeader(line, Section.dependencyOverrides);
      case 'name':
      case 'version':
        return new PubspecHeader(line, Section.header, name: sectionName, value: value);
      default:
        return new PubspecHeader(line, Section.other);
    }
  }

  /// Returns the input after removing trailing spaces and anything after the
  /// first "#".
  static String _stripComments(String line) {
    final int hashIndex = line.indexOf('#');
    if (hashIndex < 0)
      return line.trimRight();
    return line.substring(0, hashIndex).trimRight();
  }
}

/// A dependency, as represented by a line (or two) from a pubspec.yaml file.
class PubspecDependency extends PubspecLine {
  PubspecDependency(String line, this.name, this.suffix, {
    @required this.isTransitive,
    DependencyKind kind,
    this.sourcePath,
  }) : _kind = kind, super(line);

  static PubspecDependency parse(String line, { @required String filename }) {
    // We recognize any line that:
    //  * starts with exactly two spaces, no more or less
    //  * has some content, then a colon
    //
    // If we recognize the line, then we look to see if there's anything after
    // the colon, ignoring comments. If there is, then this is a normal
    // dependency, otherwise it's an unknown one.
    //
    // We also look at the trailing comment, if any, to see if it is the magic
    // string that identifies the line as a transitive dependency that we
    // previously pinned, so we can ignore it.
    //
    // We remember the trailing comment, if any, so that we can reconstruct the
    // line later. We forget the specified version range, if any.
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

  final String name; // the package name
  final String suffix; // any trailing comment we found
  final bool isTransitive; // whether the suffix matched kTransitiveMagicString
  final String sourcePath; // the filename of the pubspec.yaml file, for error messages

  DependencyKind get kind => _kind;
  DependencyKind _kind = DependencyKind.normal;

  /// If we're a path or sdk dependency, the path or sdk in question.
  String get lockTarget => _lockTarget;
  String _lockTarget;

  /// If we were a two-line dependency, the second line (see the inherited [line]
  /// for the first).
  String get lockLine => _lockLine;
  String _lockLine;

  /// If we're a path or sdk dependency, whether we were found in a
  /// dependencies/dev_dependencies section, or a dependency_overrides section.
  /// We track this so that we can put ourselves in the right section when
  /// generating the fake pubspec.yaml.
  bool get lockIsOverride => _lockIsOverride;
  bool _lockIsOverride;

  static const String _kPathPrefix = '    path: ';
  static const String _kSdkPrefix = '    sdk: ';
  static const String _kGitPrefix = '    git:';

  /// Whether the dependency points to a package in the Flutter SDK.
  ///
  /// There are two ways one can point to a Flutter package:
  ///
  /// - Using a "sdk: flutter" dependency.
  /// - Using a "path" dependency that points somewhere in the Flutter
  ///   repository other than the "bin" directory.
  bool get pointsToSdk {
    if (_kind == DependencyKind.sdk)
      return true;

    if (_kind == DependencyKind.path &&
        !fs.path.isWithin(fs.path.join(Cache.flutterRoot, 'bin'), _lockTarget) &&
        fs.path.isWithin(Cache.flutterRoot, _lockTarget))
      return true;

    return false;
  }

  /// If parse decided we were a two-line dependency, this is called to parse the second line.
  /// We throw if we couldn't parse this line.
  /// We return true if we parsed it and stored the line in lockLine.
  /// We return false if we parsed it but want to forget the whole thing.
  bool parseLock(String line, String pubspecPath, { @required bool lockIsOverride }) {
    assert(lockIsOverride != null);
    assert(kind == DependencyKind.unknown);
    if (line.startsWith(_kPathPrefix)) {
      // We're a path dependency; remember the (absolute) path.
      _lockTarget = fs.path.absolute(fs.path.dirname(pubspecPath), line.substring(_kPathPrefix.length, line.length));
      _kind = DependencyKind.path;
    } else if (line.startsWith(_kSdkPrefix)) {
      // We're an SDK dependency.
      _lockTarget = line.substring(_kSdkPrefix.length, line.length);
      _kind = DependencyKind.sdk;
    } else if (line.startsWith(_kGitPrefix)) {
      // We're a git: dependency. Return false so we'll be forgotten.
      return false;
    } else {
      throw 'Could not parse additional details for dependency $name; line was: "$line"';
    }
    _lockIsOverride = lockIsOverride;
    _lockLine = line;
    return true;
  }

  void markOverridden(PubspecDependency sibling) {
    // This is called when we find a dependency is mentioned a second time,
    // first in dependencies/dev_dependencies, and then in dependency_overrides.
    // It is called on the one found in dependencies/dev_dependencies, so that
    // we'll later know to report our version as "any" in the fake pubspec.yaml
    // and unmodified in the official pubspec.yamls.
    assert(sibling.name == name);
    assert(sibling.sourcePath == sourcePath);
    assert(sibling.kind != DependencyKind.normal);
    _kind = DependencyKind.overridden;
  }

  /// This generates the entry for this dependency for the pubspec.yaml for the
  /// fake package that we'll use to get the version numbers figured out.
  void describeForFakePubspec(StringBuffer dependencies, StringBuffer overrides) {
    switch (kind) {
      case DependencyKind.unknown:
      case DependencyKind.overridden:
        assert(kind != DependencyKind.unknown);
        break;
      case DependencyKind.normal:
        dependencies.writeln('  $name: ${_kManuallyPinnedDependencies[name] ?? 'any'}');
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

/// Generates the File object for the pubspec.yaml file of a given Directory.
File _pubspecFor(Directory directory) {
  return fs.file('${directory.path}/pubspec.yaml');
}

/// Generates the source of a fake pubspec.yaml file given a list of
/// dependencies.
String _generateFakePubspec(Iterable<PubspecDependency> dependencies) {
  if (_kManuallyPinnedDependencies.isNotEmpty) {
    final String hardCodedConstraints = _kManuallyPinnedDependencies.keys
      .map((String packageName) {
        return '  - $packageName: ${_kManuallyPinnedDependencies[packageName]}';
      })
      .join('\n');
    printStatus(
      'WARNING: the following packages use hard-coded version constraints:\n'
      '$hardCodedConstraints',
    );
  }
  final StringBuffer result = new StringBuffer();
  final StringBuffer overrides = new StringBuffer();
  result.writeln('name: flutter_update_packages');
  result.writeln('dependencies:');
  overrides.writeln('dependency_overrides:');
  for (PubspecDependency dependency in dependencies)
    if (!dependency.pointsToSdk)
      dependency.describeForFakePubspec(result, overrides);
  result.write(overrides.toString());
  return result.toString();
}

/// This object tracks the output of a call to "pub deps --style=compact".
///
/// It ends up holding the full graph of dependencies, and the version number for
/// each one.
class PubDependencyTree {
  final Map<String, String> _versions = <String, String>{};
  final Map<String, Set<String>> _dependencyTree = <String, Set<String>>{};

  /// Handles the output from "pub deps --style=compact".
  ///
  /// That output is of this form:
  ///
  /// ```
  /// package_name 0.0.0
  ///
  /// dependencies:
  /// - analyzer 0.31.0-alpha.0 [watcher args package_config collection]
  /// - archive 1.0.31 [crypto args path]
  /// - args 0.13.7
  /// - cli_util 0.1.2+1 [path]
  ///
  /// dev dependencies:
  /// - async 1.13.3 [collection]
  /// - barback 0.15.2+11 [stack_trace source_span pool async collection path]
  ///
  /// dependency overrides:
  /// - analyzer 0.31.0-alpha.0 [watcher args package_config collection]
  /// ```
  ///
  /// We ignore all the lines that don't start with a hyphen. For each other
  /// line, we ignore any line that mentions a package we've already seen (this
  /// happens when the overrides section mentions something that was in the
  /// dependencies section). We ignore if something is a dependency or
  /// dev_dependency (pub won't use different versions for those two).
  ///
  /// We then parse out the package name, version number, and subdependencies for
  /// each entry, and store than in our _versions and _dependencyTree fields
  /// above.
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

  /// Whether we know about this package.
  bool contains(String package) {
    return _versions.containsKey(package);
  }

  /// The transitive closure of all the dependencies for the given package,
  /// excluding any listen in `seen`.
  Iterable<String> getTransitiveDependenciesFor(String package, {
    @required Set<String> seen,
    @required Set<String> exclude,
  }) sync* {
    assert(seen != null);
    assert(exclude != null);
    if (!_dependencyTree.containsKey(package)) {
      // We have no transitive dependencies extracted for flutter_sdk packages
      // because they were omitted from pubspec.yaml used for 'pub upgrade' run.
      return;
    }
    for (String dependency in _dependencyTree[package]) {
      if (!seen.contains(dependency)) {
        if (!exclude.contains(dependency))
          yield dependency;
        seen.add(dependency);
        yield* getTransitiveDependenciesFor(dependency, seen: seen, exclude: exclude);
      }
    }
  }

  /// The version that a particular package ended up with.
  String versionFor(String package) {
    return _versions[package];
  }
}
