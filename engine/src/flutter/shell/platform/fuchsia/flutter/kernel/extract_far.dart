// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import "dart:io";

import "package:args/args.dart";

Future<void> main(List<String> args) async {
  final parser = new ArgParser();
  parser.addOption("far-tool", help: "Path to `far` tool");
  parser.addOption("archive", help: "Path to the far archive to extract from");
  parser.addOption("out-dir", help: "Path to output directory");
  final usage = """
Usage: extract_far.dart [options] {paths}

Options:
${parser.usage};
""";

  ArgResults options;
  try {
    options = parser.parse(args);
    if (options["far-tool"] == null) {
      throw "Must specify --far-tool";
    }
    if (options["archive"] == null) {
      throw "Must specify --archive";
    }
    if (options["out-dir"] == null) {
      throw "Must specify --out-dir";
    }
  } catch (e) {
    print("ERROR: $e\n");
    print(usage);
    exitCode = 1;
    return;
  }

  await run(options);
}

Future<void> run(ArgResults options) async {
  final far = options["far-tool"];

  Future<void> extract(String archive, String file, String output) async {
    await new File(output).parent.create(recursive: true);
    final args = ["extract-file", "--archive=$archive", "--file=$file", "--output=$output"];
    final result = await Process.run(far, args);
    if (result.exitCode != 0) {
      print(result.stdout);
      print(result.stderr);
      throw "Command failed: $far $args";
    }
  }

  final outerArchive = options["archive"];
  final outDir = options["out-dir"];

  final innerArchive = "$outDir/meta.far";
  await extract(outerArchive, "meta.far", innerArchive);

  final manifest = "$outDir/meta/contents";
  await extract(innerArchive, "meta/contents", manifest);

  final blobNames = <String, String>{};
  for (final line in await new File(manifest).readAsLines()) {
    final pivot = line.lastIndexOf("=");
    blobNames[line.substring(0, pivot)] = line.substring(pivot + 1, line.length);
  }

  for (final path in options.rest) {
    final blobName = blobNames[path];
    if (blobName == null) {
      print("Archive contents: ");
      for (final key in blobNames.keys) {
        print(key);
      }
      throw "$outerArchive does not contain $path";
    }
    await extract(outerArchive, blobName, "$outDir/$path");
  }
}
