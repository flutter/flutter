// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This script should be run by every project that consumes Mojom IDL
/// interfaces. It populates the 'mojom' package with the generated Dart
/// bindings for the Mojom IDL files.
///
/// From a consuming project, it should be invoked as follows:
///
/// $ dart packages/mojom/generate.dart [-p package-root]
///                                     [-a additional-dirs]
///                                     [-m mojo-sdk]
///                                     [-g]  # Generate from .mojom files
///                                     [-v]  # verbose
///                                     [-d]  # Dry run

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:path/path.dart' as path;

bool verbose;
bool dryRun;

bool isMojomDart(String path) => path.endsWith('.mojom.dart');
bool isMojom(String path) => path.endsWith('.mojom');

/// An Error for problems on the command line.
class CommandLineError extends Error {
  final _msg;
  CommandLineError(this._msg);
  toString() => _msg;
}

/// An Error for failures of the bindings generation script.
class GenerationError extends Error {
  final _msg;
  GenerationError(this._msg);
  toString() => _msg;
}

/// The base type of data passed to actions for [mojomDirIter].
class PackageIterData {
  final Directory _mojomPackage;
  PackageIterData(this._mojomPackage);
  Directory get mojomPackage => _mojomPackage;
}

/// Data for [mojomDirIter] that includes the path to the Mojo SDK for bindings
/// generation.
class GenerateIterData extends PackageIterData {
  final Directory _mojoSdk;
  GenerateIterData(this._mojoSdk, Directory mojomPackage)
      : super(mojomPackage);
  Directory get mojoSdk => _mojoSdk;
}

/// The type of action performed by [mojomDirIter].
typedef Future MojomAction(PackageIterData data, Directory mojomDirectory);

/// Iterates over mojom directories of Dart packages, taking some action for
/// each.
///
/// For each 'mojom' subdirectory of each subdirectory in [packages], runs
/// [action] on the subdirectory passing along [data] to [action].
mojomDirIter(
    Directory packages, PackageIterData data, MojomAction action) async {
  await for (var package in packages.list()) {
    if (package is Directory) {
      if (package.path == data.mojomPackage.path) continue;
      if (verbose) print("package = $package");
      final mojomDirectory = new Directory(path.join(package.path, 'mojom'));
      if (verbose) print("looking for = $mojomDirectory");
      if (await mojomDirectory.exists()) {
        await action(data, mojomDirectory);
      } else if (verbose) {
        print("$mojomDirectory not found");
      }
    }
  }
}


/// Searches for .mojom.dart files under [mojomDirectory] and copies them to
/// the 'mojom' packages.
copyAction(PackageIterData data, Directory mojomDirectory) async {
  await for (var mojom in mojomDirectory.list(recursive: true)) {
    if (mojom is! File) continue;
    if (!isMojomDart(mojom.path)) continue;
    if (verbose) print("Found $mojom");

    final relative = path.relative(mojom.path, from: mojomDirectory.path);
    final dest = path.join(data.mojomPackage.path, relative);
    final destDirectory = new Directory(path.dirname(dest));

    if (verbose || dryRun) {
      print('Copying $mojom to $dest');
    }

    if (!dryRun) {
      final File source = new File(mojom.path);
      if (verbose) print("Ensuring $destDirectory exists");
      await destDirectory.create(recursive: true);
      source.copy(dest);
    }
  }
}


/// Searches for .mojom files under [mojomDirectory], generates .mojom.dart
/// files for them, and copies them to the 'mojom' package.
generateAction(GenerateIterData data, Directory mojomDirectory) async {
  await for (var mojom in mojomDirectory.list(recursive: true)) {
    if (mojom is! File) continue;
    if (!isMojom(mojom.path)) continue;
    if (verbose) print("Found $mojom");

    final script = path.join(data.mojoSdk.path,
        'mojo', 'public', 'tools', 'bindings', 'mojom_bindings_generator.py');
    final outputDir = await data.mojomPackage.createTemp();
    final output = outputDir.path;
    final arguments = [
        '--use_bundled_pylibs',
        '-o', output,
        // TODO(zra): Are other include paths needed?
        '-I', data.mojoSdk.path,
        '-I', mojomDirectory.path,
        mojom.path];

    if (verbose || dryRun) {
      print('Generating $mojom');
      print('$script ${arguments.join(" ")}');
    }
    if (!dryRun) {
      final result = await Process.run(script, arguments);
      if (result.exitCode != 0) {
        throw new GenerationError("$script failed:\n${result.stderr}");
      }
      // Generated .mojom.dart is under $output/dart-gen/mojom/lib/X
      // Move X to $mojomPackage. Then rm -rf $output
      final generatedDirName = path.join(output, 'dart-gen', 'mojom', 'lib');
      final generatedDir = new Directory(generatedDirName);

      await copyAction(data, generatedDir);

      await outputDir.delete(recursive: true);
    }
  }
}


/// Ensures that the directories in [additionalPaths] are absolute and exist,
/// and creates Directories for them, which are returned.
validateAdditionalDirs(Iterable additionalPaths) async {
  var additionalDirs = [];
  for (var mojomPath in additionalPaths) {
    final mojomDir = new Directory(mojomPath);
    if (!mojomDir.isAbsolute) {
      throw new CommandLineError(
          "All --additional-mojom-dir parameters must be absolute paths.");
    }
    if (!(await mojomDir.exists())) {
      throw new CommandLineError(
          "The additional mojom directory $mojomDir must exist");
    }
    additionalDirs.add(mojomDir);
  }
  if (verbose) print("additional_mojom_dirs = $additionalDirs");
  return additionalDirs;
}


main(List<String> arguments) async {
  final parser = new args.ArgParser()
    ..addOption('additional-mojom-dir',
        abbr: 'a',
        allowMultiple: true,
        help: 'Absolute path to an additional directory containing mojom.dart'
        'files to put in the mojom package. May be specified multiple times.')
    ..addFlag('dry-run',
        abbr: 'd',
        defaultsTo: false,
        help: 'Print the copy operations that would have been run, but'
        'do not copy anything.')
    ..addFlag('generate',
        abbr: 'g',
        defaultsTo: false,
        help: 'Generate Dart bindings for .mojom files.')
    ..addOption('mojo-sdk',
        abbr: 'm',
        defaultsTo: Platform.environment['MOJO_SDK'],
        help: 'Absolute path to the Mojo SDK, which can also be specified '
              'with the environment variable MOJO_SDK.')
    ..addOption('package-root',
        abbr: 'p',
        defaultsTo: path.join(Directory.current.path, 'packages'),
        help: 'An absolute path to an application\'s package root')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false);
  final result = parser.parse(arguments);
  verbose = result['verbose'];
  dryRun = result['dry-run'];

  final packages = new Directory(result['package-root']);
  if (!packages.isAbsolute) {
    throw new CommandLineError(
        "The --package-root parameter must be an absolute path.");
  }
  if (verbose) print("packages = $packages");
  if (!(await packages.exists())) {
    throw new CommandLineError(
        "The packages directory $packages must exist");
  }

  final mojomPackage = new Directory(path.join(packages.path, 'mojom'));
  if (verbose) print("mojom package = $mojomPackage");
  if (!(await mojomPackage.exists())) {
    throw new CommandLineError(
        "The mojom package directory $mojomPackage must exist");
  }

  final generate = result['generate'];
  var mojoSdk = null;
  if (generate) {
    final mojoSdkPath = result['mojo-sdk'];
    if (mojoSdkPath == null) {
      throw new CommandLineError(
          "The Mojo SDK directory must be specified with the --mojo-sdk flag or"
          "the MOJO_SDK environment variable.");
    }
    mojoSdk = new Directory(mojoSdkPath);
    if (verbose) print("Mojo SDK = $mojoSdk");
    if (!(await mojoSdk.exists())) {
      throw new CommandLineError(
          "The specified Mojo SDK directory $mojoSdk must exist.");
    }
  }

  await mojomDirIter(packages, new PackageIterData(mojomPackage), copyAction);
  if (generate) {
    await mojomDirIter(packages, new GenerateIterData(mojoSdk, mojomPackage),
                       generateAction);
  }

  final additionalDirs =
      await validateAdditionalDirs(result['additional-mojom-dir']);
  final data = new GenerateIterData(mojoSdk, mojomPackage);
  for (var mojomDir in additionalDirs) {
    await copyAction(data, mojomDir);
    if (generate) {
      await generateAction(data, mojomDir);
    }
  }
}
