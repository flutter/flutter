// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Generates Java and Kotlin constants from Dart sources of truth, using Pigeon.
//
// What gets generated is listed in [sources]: a Dart source of truth, and the
// Java and/or Kotlin file generated from it. Add an entry there to share a new
// set of constants.
//
// ## Usage
//
// ```
// dart dev/tools/gen_gradle_constants/bin/gen_gradle_constants.dart
// ```
//
// The path of every file written is printed, one per line; dev/bots/analyze.dart
// regenerates and then asks git whether any of them changed.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:pigeon/pigeon.dart';

/// The Dart sources of truth, and the files generated from each of them.
///
/// Paths are relative to the root of the repository, and use `/` as the
/// separator on every platform.
const List<ConstantsSource> sources = <ConstantsSource>[
  ConstantsSource(
    dartSource: 'packages/flutter_tools/lib/src/android/gradle_constants.dart',
    generates: <GeneratedFile>[
      GeneratedFile.kotlin(
        file: 'packages/flutter_tools/gradle/src/main/kotlin/GradleConstants.g.kt',
        package: 'com.flutter.gradle',
      ),
    ],
  ),
];

/// The copyright header prepended to every generated file.
const String copyrightHeader = 'dev/tools/gen_gradle_constants/copyright.txt';

/// A Dart file of constants, and the files generated from it.
class ConstantsSource {
  const ConstantsSource({required this.dartSource, required this.generates});

  /// The Dart file that declares the constants.
  final String dartSource;

  /// The files generated from [dartSource]; one per target language.
  final List<GeneratedFile> generates;
}

/// A file generated from a [ConstantsSource].
class GeneratedFile {
  // Nothing generates Java today, but a source of truth can name a Java file,
  // a Kotlin file, or both.
  // ignore: unreachable_from_main
  const GeneratedFile.java({required this.file, required this.package})
    : language = TargetLanguage.java;

  const GeneratedFile.kotlin({required this.file, required this.package})
    : language = TargetLanguage.kotlin;

  /// The file to generate.
  final String file;

  /// The Java or Kotlin package that [file] declares.
  final String package;

  /// The language [file] is written in.
  final TargetLanguage language;
}

/// A language Pigeon can generate constants for.
enum TargetLanguage {
  // Java constants live inside a class, so the declarations Pigeon emits start
  // at the class declaration, and the file has to be closed again.
  java(
    outputFlag: '--java_out',
    packageFlag: '--java_package',
    declarationsStart: 'public class ',
    constantPrefix: 'public static final ',
    closer: '}',
  ),
  kotlin(
    outputFlag: '--kotlin_out',
    packageFlag: '--kotlin_package',
    declarationsStart: 'package ',
    constantPrefix: 'const val ',
  );

  const TargetLanguage({
    required this.outputFlag,
    required this.packageFlag,
    required this.declarationsStart,
    required this.constantPrefix,
    this.closer,
  });

  /// The Pigeon flag naming the file to generate.
  final String outputFlag;

  /// The Pigeon flag naming the package the generated file belongs to.
  final String packageFlag;

  /// The prefix of the last line of the file header, after which Pigeon starts
  /// emitting declarations.
  final String declarationsStart;

  /// The prefix of a generated constant declaration.
  final String constantPrefix;

  /// The line closing the file, for languages that need one.
  final String? closer;
}

Future<void> main() async {
  // Generate into a scratch directory first, so that a run that fails partway
  // through cannot leave a half written file behind.
  final Directory scratch = Directory.systemTemp.createTempSync('gen_gradle_constants.');
  try {
    for (final ConstantsSource source in sources) {
      for (final GeneratedFile generated in source.generates) {
        final String contents = await _generate(source, generated, scratch);
        File(_resolve(generated.file)).writeAsStringSync(contents);
        stdout.writeln(generated.file);
      }
    }
  } finally {
    scratch.deleteSync(recursive: true);
  }
}

/// Runs Pigeon for a single [generated] file, and returns its pruned contents.
Future<String> _generate(ConstantsSource source, GeneratedFile generated, Directory scratch) async {
  final String scratchFile = path.join(scratch.path, _toPlatformPath(generated.file));
  Directory(path.dirname(scratchFile)).createSync(recursive: true);
  final int exitCode = await Pigeon.run(<String>[
    '--input',
    _resolve(source.dartSource),
    generated.language.outputFlag,
    scratchFile,
    generated.language.packageFlag,
    generated.package,
    '--copyright_header',
    _resolve(copyrightHeader),
    '--one_language',
  ]);
  if (exitCode != 0) {
    stderr.writeln('Pigeon failed to generate ${generated.file} from ${source.dartSource}.');
    exit(exitCode);
  }
  return _keepOnlyConstants(File(scratchFile).readAsLinesSync(), generated.language);
}

/// Rewrites Pigeon's output to keep only the file header and the constants.
///
/// Pigeon unconditionally emits the imports, message codec, and error class that
/// a generated platform channel API needs. None of that applies to a file that
/// only declares constants, and the Flutter Gradle Plugin in particular is a
/// plain JVM Gradle plugin, with neither the Android SDK nor the Flutter
/// embedding on its classpath, so those imports would not even resolve.
String _keepOnlyConstants(List<String> generated, TargetLanguage language) {
  final header = <String>[];
  final constants = <String>[];
  var inHeader = true;
  for (final line in generated) {
    final String declaration = line.trimLeft();
    // A file of constants needs no imports. Kotlin puts them after the package
    // declaration and Java before the class declaration, so drop them wherever
    // they turn up.
    if (declaration.startsWith('import ')) {
      continue;
    }
    if (inHeader) {
      // Dropping the imports must not leave the blank lines around them behind.
      if (declaration.isEmpty && (header.isEmpty || header.last.isEmpty)) {
        continue;
      }
      header.add(line);
      inHeader = !declaration.startsWith(language.declarationsStart);
    } else if (declaration.startsWith(language.constantPrefix)) {
      constants.add(line);
    } else if (declaration.isNotEmpty) {
      // Pigeon emits the constants first, so anything else ends them.
      break;
    }
  }

  final buffer = StringBuffer();
  header.forEach(buffer.writeln);
  buffer.writeln();
  constants.forEach(buffer.writeln);
  if (language.closer != null) {
    buffer.writeln(language.closer);
  }
  return buffer.toString();
}

/// The root of the repository, from the location of this script in
/// `<root>/dev/tools/gen_gradle_constants/bin`.
final String _repoRoot = path.normalize(
  path.join(path.dirname(path.fromUri(Platform.script)), '..', '..', '..', '..'),
);

/// Turns a repository relative, `/` separated path into an absolute one.
String _resolve(String repoRelativePath) => path.join(_repoRoot, _toPlatformPath(repoRelativePath));

String _toPlatformPath(String posixPath) => path.joinAll(path.posix.split(posixPath));
