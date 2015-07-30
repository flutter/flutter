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
///                                     [-d]  # Download from .mojoms files
///                                     [-v]  # verbose
///                                     [-f]  # Fake (dry) run

library generate;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:path/path.dart' as path;

part 'src/utils.dart';

bool verbose;
bool dryRun;
Map<String, String> duplicateDetection = new Map<String, String>();

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

    if (duplicateDetection.containsKey(dest)) {
      String original = duplicateDetection[dest];
      throw new GenerationError('Conflict: Both ${original} and ${mojom.path} supply ${dest}');
    }
    duplicateDetection[dest] = mojom.path;

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
        'tools', 'bindings', 'mojom_bindings_generator.py');
    final sdkInc = path.normalize(path.join(data.mojoSdk.path, '..', '..'));
    final outputDir = await data.mojomPackage.createTemp();
    final output = outputDir.path;
    final arguments = [
        '--use_bundled_pylibs',
        '-g', 'dart',
        '-o', output,
        // TODO(zra): Are other include paths needed?
        '-I', sdkInc,
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

/// In each package, look for a file named .mojoms. Populate a package's
/// mojom directory with the downloaded mojoms, creating the directory if
/// needed. The .mojoms file should be formatted as follows:
/// '''
/// root: https://www.example.com/mojoms
/// path/to/some/mojom1.mojom
/// path/to/some/other/mojom2.mojom
///
/// root: https://www.example-two.com/mojoms
/// path/to/example/two/mojom1.mojom
/// ...
///
/// Lines beginning with '#' are ignored.
downloadAction(GenerateIterData data, Directory packageDirectory) async {
  var mojomsPath = path.join(packageDirectory.path, '.mojoms');
  var mojomsFile = new File(mojomsPath);
  if (!await mojomsFile.exists()) return;
  if (verbose) print("Found .mojoms file: $mojomsPath");

  Directory mojomsDir;
  var httpClient = new HttpClient();
  int repoCount = 0;
  int mojomCount = 0;
  String repoRoot;
  for (String line in await mojomsFile.readAsLines()) {
    line = line.trim();
    if (line.isEmpty || line.startsWith('#')) continue;

    if (line.startsWith('root:')) {
      if ((mojomsDir != null) && (mojomCount == 0)) {
        throw new DownloadError("root with no mojoms: $repoRoot");
      }
      mojomCount = 0;
      var rootWords = line.split(" ");
      if (rootWords.length != 2) {
        throw new DownloadError("Malformed root: $line");
      }
      repoRoot = rootWords[1];
      if (verbose) print("Found repo root: $repoRoot");
      if (!repoRoot.startsWith('http://') &&
          !repoRoot.startsWith('https://')) {
        throw new DownloadError(
            'Mojom repo "root" should be an http or https URL: $line');
      }
      mojomsDir = new Directory(path.join(
          packageDirectory.parent.path, 'mojm.repo.$repoCount', 'mojom'));
      await mojomsDir.create(recursive: true);
      repoCount++;
    } else {
      if (mojomsDir == null) {
        throw new DownloadError('Malformed .mojoms file: $mojomsPath');
      }
      String url = "$repoRoot/$line";
      if (verbose) print("Found $url");
      String fileString = await getUrl(httpClient, url);
      if (verbose) print("Downloaded $url");
      String filePath = path.join(mojomsDir.path, line);
      var file = new File(filePath);
      if (!await file.exists()) {
        await file.create(recursive: true);
        await file.writeAsString(fileString);
        if (verbose) print("Wrote $filePath");
      }
      mojomCount++;
    }
  }
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
  if (verbose) print("additional_mojom_dirs = $additionalDirs");
  return additionalDirs;
}

class GenerateOptions {
  final Directory packages;
  final Directory mojomPackage;
  final Directory mojoSdk;
  final List<Directory> additionalDirs;
  final bool download;
  final bool generate;
  GenerateOptions(
      this.packages, this.mojomPackage, this.mojoSdk, this.additionalDirs,
      this.download, this.generate);
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
  dryRun = result['fake'];

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

  return new GenerateOptions(
      packages, mojomPackage, mojoSdk, additionalDirs, download, generate);
}

main(List<String> arguments) async {
  var options = await parseArguments(arguments);

  // Copy any pregenerated files form packages.
  await mojomDirIter(
      options.packages,
      new PackageIterData(options.mojomPackage),
      copyAction);

  // Download .mojom files. These will be picked up by the generation step
  // below.
  if (options.download) {
    await packageDirIter(options.packages, null, downloadAction);
  }

  // Generate mojom files.
  if (options.generate) {
    await mojomDirIter(
        options.packages,
        new GenerateIterData(options.mojoSdk, options.mojomPackage),
        generateAction);
  }

  // Copy pregenerated files from specified external directories.
  final data = new GenerateIterData(options.mojoSdk, options.mojomPackage);
  for (var mojomDir in options.additionalDirs) {
    await copyAction(data, mojomDir);
    if (options.generate) {
      await generateAction(data, mojomDir);
    }
  }
}
