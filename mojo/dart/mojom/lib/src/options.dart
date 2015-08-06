// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of generate;

class GenerateOptions {
  final Directory packages;
  final Directory mojoSdk;
  final Directory mojomPackage;
  final List<Directory> additionalDirs;
  final bool download;
  final bool generate;
  final bool errorOnDuplicate;
  final bool verbose;
  final bool dryRun;
  GenerateOptions(this.packages, this.mojomPackage, this.mojoSdk,
      this.additionalDirs, this.download, this.generate, this.errorOnDuplicate,
      this.verbose, this.dryRun);
}

/// Ensures that the directories in [additionalPaths] are absolute and exist,
/// and creates Directories for them, which are returned.
Future<List<Directory>> validateAdditionalDirs(Iterable additionalPaths) async {
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
  return additionalDirs;
}

Future<GenerateOptions> parseArguments(List<String> arguments) async {
  final parser = new args.ArgParser()
    ..addOption('additional-mojom-dir',
        abbr: 'a',
        allowMultiple: true,
        help: 'Absolute path to an additional directory containing mojom.dart'
        'files to put in the mojom package. May be specified multiple times.')
    ..addFlag('download',
        abbr: 'd',
        defaultsTo: false,
        help: 'Searches packages for a .mojoms file, and downloads .mojom files'
        'as speficied in that file. Implies -g.')
    ..addFlag('fake',
        abbr: 'f',
        defaultsTo: false,
        help: 'Print the operations that would have been run, but'
        'do not run anything.')
    ..addFlag('generate',
        abbr: 'g',
        defaultsTo: false,
        help: 'Generate Dart bindings for .mojom files.')
    ..addFlag('ignore-duplicates',
        abbr: 'i',
        defaultsTo: false,
        help: 'Ignore generation of a .mojom.dart file into the same location '
        'as an existing file. By default this is an error')
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
  bool verbose = result['verbose'];
  bool dryRun = result['fake'];
  bool errorOnDuplicate = !result['ignore-duplicates'];

  final packages = new Directory(result['package-root']);
  if (!packages.isAbsolute) {
    throw new CommandLineError(
        "The --package-root parameter must be an absolute path.");
  }
  if (verbose) print("packages = $packages");
  if (!(await packages.exists())) {
    throw new CommandLineError("The packages directory $packages must exist");
  }

  final mojomPackage = new Directory(path.join(packages.path, 'mojom'));
  if (verbose) print("mojom package = $mojomPackage");
  if (!(await mojomPackage.exists())) {
    throw new CommandLineError(
        "The mojom package directory $mojomPackage must exist");
  }

  final download = result['download'];
  final generate = result['generate'] || download;
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

  final additionalDirs =
      await validateAdditionalDirs(result['additional-mojom-dir']);
  if (verbose) print("additional_mojom_dirs = $additionalDirs");

  return new GenerateOptions(packages, mojomPackage, mojoSdk, additionalDirs,
      download, generate, errorOnDuplicate, verbose, dryRun);
}
