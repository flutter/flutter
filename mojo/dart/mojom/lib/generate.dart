// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This script generates Mojo bindings for a Dart package. See README.md for
/// details.

library generate;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:path/path.dart' as path;

part 'src/options.dart';
part 'src/utils.dart';

bool errorOnDuplicate;
bool verbose;
bool dryRun;
Map<String, String> duplicateDetection;

/// Searches for .mojom.dart files under [mojomDirectory] and copies them to
/// [data.currentPackage].
copyAction(PackageIterData data, Directory mojomDirectory) async {
  await for (var mojom in mojomDirectory.list(recursive: true)) {
    if (mojom is! File) continue;
    if (!isMojomDart(mojom.path)) continue;
    if (verbose) print("Found $mojom");

    final relative = path.relative(mojom.path, from: mojomDirectory.path);
    final dest = path.join(data.currentPackage.path, relative);
    final destDirectory = new Directory(path.dirname(dest));

    if (errorOnDuplicate && duplicateDetection.containsKey(dest)) {
      String original = duplicateDetection[dest];
      throw new GenerationError(
          'Conflict: Both ${original} and ${mojom.path} supply ${dest}');
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
  final packageRoot = data.currentPackage.parent;
  await for (var mojom in mojomDirectory.list(recursive: true)) {
    if (mojom is! File) continue;
    if (!isMojom(mojom.path)) continue;
    if (verbose) print("Found $mojom");

    final script = path.join(
        data.mojoSdk.path, 'tools', 'bindings', 'mojom_bindings_generator.py');
    final sdkInc = path.normalize(path.join(data.mojoSdk.path, '..', '..'));
    final outputDir = await data.currentPackage.createTemp();
    final output = outputDir.path;
    final arguments = [
      '--use_bundled_pylibs',
      '-g',
      'dart',
      '-o',
      output,
      // TODO(zra): Are other include paths needed?
      '-I',
      sdkInc,
      '-I',
      mojomDirectory.path,
      mojom.path
    ];

    if (verbose || dryRun) {
      print('Generating $mojom');
      print('$script ${arguments.join(" ")}');
    }
    if (!dryRun) {
      final result = await Process.run(script, arguments);
      if (result.exitCode != 0) {
        throw new GenerationError("$script failed:\n${result.stderr}");
      }

      // Generated .mojom.dart is under $output/dart-pkg/$PACKAGE/lib/$X
      // Move $X to $PACKAGE_ROOT/$PACKAGE/$X
      final generatedDirName = path.join(output, 'dart-pkg');
      final generatedDir = new Directory(generatedDirName);
      await for (var genpack in generatedDir.list()) {
        if (genpack is! Directory) continue;
        var libDir = new Directory(path.join(genpack.path, 'lib'));
        var name = path.relative(genpack.path, from: generatedDirName);
        var copyData = new GenerateIterData(data.mojoSdk);
        copyData.currentPackage =
            new Directory(path.join(packageRoot.path, name));
        await copyAction(copyData, libDir);
      }

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
downloadAction(GenerateIterData _, Directory packageDirectory) async {
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
      if (!repoRoot.startsWith('http://') && !repoRoot.startsWith('https://')) {
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

/// The "mojom" entry in [packages] is a symbolic link to the mojom package in
/// the global pub cache directory. Because we might need to write package
/// specific .mojom.dart files into the mojom package, we need to make a local
/// copy of it.
copyMojomPackage(Directory packages) async {
  var link = new Link(path.join(packages.path, "mojom"));
  if (!await link.exists()) {
    // If the "mojom" entry in packages is not a symbolic link, then do nothing.
    return;
  }

  var realpath = await link.resolveSymbolicLinks();
  var realDir = new Directory(realpath);
  var mojomDir = new Directory(path.join(packages.path, "mojom"));

  await link.delete();
  await mojomDir.create();
  await for (var file in realDir.list(recursive: true)) {
    if (file is File) {
      var relative = path.relative(file.path, from: realDir.path);
      var destPath = path.join(mojomDir.path, relative);
      var destDir = new Directory(path.dirname(destPath));
      await destDir.create(recursive: true);
      await file.copy(path.join(mojomDir.path, relative));
    }
  }
}

main(List<String> arguments) async {
  var options = await parseArguments(arguments);
  duplicateDetection = new Map<String, String>();
  errorOnDuplicate = options.errorOnDuplicate;
  verbose = options.verbose;
  dryRun = options.dryRun;

  // mojoms without a DartPackage annotation, and pregenerated mojoms from
  // [options.additionalDirs] will go into the mojom package, so we make a local
  // copy of it so we don't pollute the global pub cache.
  //
  // TODO(zra): Fail if a mojom has no DartPackage annotation, and remove the
  // need for [options.additionalDirs].
  if (!dryRun) {
    await copyMojomPackage(options.packages);
  }

  // Download .mojom files. These will be picked up by the generation step
  // below.
  if (options.download) {
    await packageDirIter(options.packages, null, downloadAction);
  }

  // Generate mojom files.
  if (options.generate) {
    await mojomDirIter(options.packages, new GenerateIterData(options.mojoSdk),
        generateAction);
  }

  // TODO(zra): As mentioned above, this should go away.
  // Copy pregenerated files from specified external directories into the
  // mojom package.
  final data = new GenerateIterData(options.mojoSdk);
  data.currentPackage = options.mojomPackage;
  for (var mojomDir in options.additionalDirs) {
    await copyAction(data, mojomDir);
    if (options.generate) {
      await generateAction(data, mojomDir);
    }
  }
}
