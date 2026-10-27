// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// To run this, from the root of the Flutter repository:
//   bin/cache/dart-sdk/bin/dart --enable-asserts dev/bots/check_code_samples.dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

final String _scriptLocation = path.fromUri(Platform.script);
final String _flutterRoot = path.dirname(path.dirname(path.dirname(_scriptLocation)));
final String _exampleDirectoryPath = path.join(
  _flutterRoot,
  'packages',
  'flutter',
  'examples',
  'api',
);
final String _packageDirectoryPath = path.join(_flutterRoot, 'packages');
final String _dartUIDirectoryPath = path.join(
  _flutterRoot,
  'bin',
  'cache',
  'pkg',
  'sky_engine',
  'lib',
);

final List<String> _knownUnlinkedExamples = <String>[
  // These are template files that aren't expected to be linked.
  'examples/api/lib/sample_templates/cupertino.0.dart',
  'examples/api/lib/sample_templates/widgets.0.dart',
  'examples/api/lib/sample_templates/material.0.dart',
];

void main(List<String> args) {
  final argParser = ArgParser();
  argParser.addFlag('help', negatable: false, help: 'Print help for this command.');
  argParser.addOption(
    'examples',
    valueHelp: 'path',
    defaultsTo: _exampleDirectoryPath,
    help: 'A location where the API doc examples are found.',
  );
  argParser.addOption(
    'packages',
    valueHelp: 'path',
    defaultsTo: _packageDirectoryPath,
    help: 'A location where the source code that should link the API doc examples is found.',
  );
  argParser.addOption(
    'dart-ui',
    valueHelp: 'path',
    defaultsTo: _dartUIDirectoryPath,
    help: 'A location where the source code that should link the API doc examples is found.',
  );
  argParser.addOption(
    'flutter-root',
    valueHelp: 'path',
    defaultsTo: _flutterRoot,
    help: 'The path to the root of the Flutter repo.',
  );
  final ArgResults parsedArgs;

  void usage() {
    print('dart --enable-asserts ${path.basename(_scriptLocation)} [options]');
    print(argParser.usage);
  }

  try {
    parsedArgs = argParser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    usage();
    exit(1);
  }

  if (parsedArgs['help'] as bool) {
    usage();
    exit(0);
  }

  const FileSystem filesystem = LocalFileSystem();
  final Directory examples = filesystem.directory(parsedArgs['examples']! as String);
  final Directory packages = filesystem.directory(parsedArgs['packages']! as String);
  final Directory dartUIPath = filesystem.directory(parsedArgs['dart-ui']! as String);
  final Directory flutterRoot = filesystem.directory(parsedArgs['flutter-root']! as String);

  final checker = SampleChecker(
    examples: examples,
    packages: packages,
    dartUIPath: dartUIPath,
    flutterRoot: flutterRoot,
  );

  if (!checker.checkCodeSamples()) {
    reportErrorsAndExit('Some errors were found in the API docs code samples.');
  }
  reportSuccessAndExit('All examples are linked and have tests.');
}

class LinkInfo {
  const LinkInfo(this.link, this.file, this.line);

  final String link;
  final File file;
  final int line;

  @override
  String toString() {
    return '${file.path}:$line: $link';
  }
}

class SampleChecker {
  SampleChecker({
    required this.examples,
    required this.packages,
    required this.dartUIPath,
    required this.flutterRoot,
    this.filesystem = const LocalFileSystem(),
  });

  final Directory examples;
  final Directory packages;
  final Directory dartUIPath;
  final Directory flutterRoot;
  final FileSystem filesystem;

  // The `exampleBase` is where the paths in "See code in" or "{@example}" are
  // relative to.  Defaults to <flutter_root>/packages/flutter.
  Directory get exampleBase => examples.parent.parent;

  bool checkCodeSamples() {
    filesystem.currentDirectory = flutterRoot;

    // Get a list of all the filenames in the source directory that end in "[0-9]+.dart".
    final List<File> exampleFilenames = getExampleFilenames(examples);

    // Get a list of all the example link paths that appear in the source files.
    final (
      Set<String> exampleLinks,
      Set<LinkInfo> legacyMalformedLinks,
      Set<LinkInfo> standardMalformedLinks,
    ) = getExampleLinks(
      packages,
    );
    // Also add in any that might be found in the dart:ui directory.
    final (
      Set<String> uiExampleLinks,
      Set<LinkInfo> uiLegacyMalformedLinks,
      Set<LinkInfo> uiStandardMalformedLinks,
    ) = getExampleLinks(
      dartUIPath,
    );

    exampleLinks.addAll(uiExampleLinks);
    legacyMalformedLinks.addAll(uiLegacyMalformedLinks);
    standardMalformedLinks.addAll(uiStandardMalformedLinks);

    // Get a list of the filenames that were not found in the source files.
    final List<String> missingFilenames = checkForMissingLinks(exampleFilenames, exampleLinks);

    // Get a list of any tests that are missing.
    final List<File> missingTests = checkForMissingTests(exampleFilenames);

    // Remove any that we know are exceptions (examples that aren't expected to be
    // linked into any source files). These are typically template files used to
    // generate new examples.
    missingFilenames.removeWhere((String file) => _knownUnlinkedExamples.contains(file));

    if (missingFilenames.isEmpty &&
        missingTests.isEmpty &&
        legacyMalformedLinks.isEmpty &&
        standardMalformedLinks.isEmpty) {
      return true;
    }

    if (missingTests.isNotEmpty) {
      final buffer = StringBuffer('The following example test files are missing:\n');
      for (final name in missingTests) {
        buffer.writeln('  ${getRelativePath(name)}');
      }
      foundError(buffer.toString().trimRight().split('\n'));
    }

    if (missingFilenames.isNotEmpty) {
      final buffer = StringBuffer(
        'The following examples are not linked from any source file API doc comments:\n',
      );
      for (final name in missingFilenames) {
        buffer.writeln('  $name');
      }
      buffer.write('Either link them to a source file API doc comment, or remove them.');
      foundError(buffer.toString().split('\n'));
    }

    if (legacyMalformedLinks.isNotEmpty) {
      final buffer = StringBuffer(
        'The following malformed links were found in API doc comments:\n',
      );
      for (final link in legacyMalformedLinks) {
        buffer.writeln('  $link');
      }
      buffer.write(
        'Correct the formatting of these links so that they match the exact pattern:\n'
        r"  '\*\* See code in (?<path>.+) \*\*'",
      );
      foundError(buffer.toString().split('\n'));
    }

    if (standardMalformedLinks.isNotEmpty) {
      final buffer = StringBuffer(
        'The following malformed links were found in API doc comments:\n',
      );
      for (final link in standardMalformedLinks) {
        buffer.writeln('  $link');
      }
      buffer.write(
        'Correct the formatting of these links so that they match the exact pattern:\n'
        "  '{@example /<path>}' or '{@example /<path>#<region>}'",
      );
      foundError(buffer.toString().split('\n'));
    }
    return false;
  }

  String getRelativePath(File file, [Directory? root]) {
    root ??= flutterRoot;
    return path.relative(file.absolute.path, from: root.absolute.path);
  }

  List<File> getFiles(Directory directory, [Pattern? filenamePattern]) {
    final List<File> filenames = directory
        .listSync(recursive: true)
        .map((FileSystemEntity entity) {
          if (entity is File) {
            return entity;
          } else {
            return null;
          }
        })
        .where(
          (File? filename) =>
              filename != null &&
              (filenamePattern == null || filename.absolute.path.contains(filenamePattern)),
        )
        .map<File>((File? s) => s!)
        .toList();
    return filenames;
  }

  List<File> getExampleFilenames(Directory directory) {
    return getFiles(directory.childDirectory('lib'), RegExp(r'\d+\.dart$'));
  }

  (Set<String>, Set<LinkInfo>, Set<LinkInfo>) getExampleLinks(Directory searchDirectory) {
    final List<File> files = getFiles(searchDirectory, RegExp(r'\.dart$'));
    final searchStrings = <String>{};
    final legacyMalformedStrings = <LinkInfo>{};
    final standardMalformedStrings = <LinkInfo>{};
    final legacyValidExampleRe = RegExp(r'\*\* See code in (?<path>.+) \*\*');
    final standardValidExampleRe = RegExp(r'{@example /(?<path>[^#}]+)(?:#.+)?}');
    // Looks for some common broken versions of example links. This looks for
    // something that is at minimum "///*seecode<something>*" or
    // "///{@example<something>}" to indicate that it looks like an example
    // link. It should be narrowed if we start getting false positives.
    final legacyMalformedLinkRe = RegExp(
      r'^(?<malformed>\s*///\s*\*\*?\s*[sS][eE][eE]\s*[Cc][Oo][Dd][Ee].+\*\*?)',
    );
    final standardMalformedLinkRe = RegExp(r'^(?<malformed>\s*///\s*{@example.*)');
    for (final file in files) {
      final String contents = file.readAsStringSync();
      final List<String> lines = contents.split('\n');
      var count = 0;
      for (final line in lines) {
        count += 1;
        final RegExpMatch? legacyValidMatch = legacyValidExampleRe.firstMatch(line);
        final RegExpMatch? standardValidMatch = standardValidExampleRe.firstMatch(line);
        if (legacyValidMatch != null) {
          searchStrings.add(legacyValidMatch.namedGroup('path')!);
        } else if (standardValidMatch != null) {
          searchStrings.add(standardValidMatch.namedGroup('path')!);
        }
        final RegExpMatch? legacyMalformedMatch = legacyMalformedLinkRe.firstMatch(line);
        final RegExpMatch? standardMalformedMatch = standardMalformedLinkRe.firstMatch(line);
        // It's only malformed if it doesn't match the valid RegExp.
        if (legacyMalformedMatch != null && legacyValidMatch == null) {
          legacyMalformedStrings.add(
            LinkInfo(legacyMalformedMatch.namedGroup('malformed')!, file, count),
          );
        }
        if (standardMalformedMatch != null && standardValidMatch == null) {
          standardMalformedStrings.add(
            LinkInfo(standardMalformedMatch.namedGroup('malformed')!, file, count),
          );
        }
      }
    }
    return (searchStrings, legacyMalformedStrings, standardMalformedStrings);
  }

  List<String> checkForMissingLinks(List<File> exampleFilenames, Set<String> searchStrings) {
    final missingFilenames = <String>[];
    for (final example in exampleFilenames) {
      final String relativePath = getRelativePath(example, exampleBase);
      if (!searchStrings.contains(relativePath)) {
        missingFilenames.add(relativePath);
      }
    }
    return missingFilenames;
  }

  String getTestNameForExample(File example, Directory examples) {
    final String testPath = path.dirname(
      path.join(
        examples.absolute.path,
        'test',
        getRelativePath(example, examples.childDirectory('lib')),
      ),
    );
    return '${path.join(testPath, path.basenameWithoutExtension(example.path))}_test.dart';
  }

  List<File> checkForMissingTests(List<File> exampleFilenames) {
    final missingTests = <File>[];
    for (final example in exampleFilenames) {
      final File testFile = filesystem.file(getTestNameForExample(example, examples));
      if (!testFile.existsSync()) {
        missingTests.add(testFile);
      }
    }
    return missingTests;
  }
}
