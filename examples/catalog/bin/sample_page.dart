// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This application generates markdown pages and screenshots for each
// sample app. For more information see ../README.md.

import 'dart:io';

import 'package:path/path.dart';

class SampleError extends Error {
  SampleError(this.message);
  final String message;
  @override
  String toString() => 'SampleError($message)';
}

// Sample apps are .dart files in the lib directory which contain a block
// comment that begins with a '/* Sample Catalog' line, and ends with a line
// that just contains '*/'. The following keywords may appear at the
// beginning of lines within the comment. A keyword's value is all of
// the following text up to the next keyword or the end of the comment,
// sans leading and trailing whitespace.
const String sampleCatalogKeywords = r'^Title:|^Summary:|^Description:|^Classes:|^Sample:|^See also:';

Directory outputDirectory;
Directory sampleDirectory;
Directory testDirectory;
Directory driverDirectory;

void logMessage(String s) { print(s); }
void logError(String s) { print(s); }

File inputFile(String dir, String name) {
  return File(dir + Platform.pathSeparator + name);
}

File outputFile(String name, [Directory directory]) {
  return File((directory ?? outputDirectory).path + Platform.pathSeparator + name);
}

void initialize() {
  outputDirectory = Directory('.generated');
  sampleDirectory = Directory('lib');
  testDirectory = Directory('test');
  driverDirectory = Directory('test_driver');
  outputDirectory.createSync();
}

// Return a copy of template with each occurrence of @(foo) replaced
// by values[foo].
String expandTemplate(String template, Map<String, String> values) {
  // Matches @(foo), match[1] == 'foo'
  final RegExp tokenRE = RegExp(r'@\(([\w ]+)\)', multiLine: true);
  return template.replaceAllMapped(tokenRE, (Match match) {
    if (match.groupCount != 1)
      throw SampleError('bad template keyword $match[0]');
    final String keyword = match[1];
    return values[keyword] ?? '';
  });
}

void writeExpandedTemplate(File output, String template, Map<String, String> values) {
  output.writeAsStringSync(expandTemplate(template, values));
  logMessage('wrote $output');
}

class SampleInfo {
  SampleInfo(this.sourceFile, this.commit);

  final File sourceFile;
  final String commit;
  String sourceCode;
  Map<String, String> commentValues;

  // If sourceFile is lib/foo.dart then sourceName is foo. The sourceName
  // is used to create derived filenames like foo.md or foo.png.
  String get sourceName => basenameWithoutExtension(sourceFile.path);

  // The website's link to this page will be /catalog/samples/@(link)/.
  String get link => sourceName.replaceAll('_', '-');

  // The name of the widget class that defines this sample app, like 'FooSample'.
  String get sampleClass => commentValues['sample'];

  // The value of the 'Classes:' comment as a list of class names.
  Iterable<String> get highlightedClasses {
    final String classNames = commentValues['classes'];
    if (classNames == null)
      return const <String>[];
    return classNames.split(',').map<String>((String s) => s.trim()).where((String s) => s.isNotEmpty);
  }

  // The relative import path for this sample, like '../lib/foo.dart'.
  String get importPath => '..' + Platform.pathSeparator + sourceFile.path;

  // Return true if we're able to find the "Sample Catalog" comment in the
  // sourceFile, and we're able to load its keyword/value pairs into
  // the commentValues Map. The rest of the file's contents are saved
  // in sourceCode.
  bool initialize() {
    final String contents = sourceFile.readAsStringSync();

    final RegExp startRE = RegExp(r'^/\*\s+^Sample\s+Catalog', multiLine: true);
    final RegExp endRE = RegExp(r'^\*/', multiLine: true);
    final Match startMatch = startRE.firstMatch(contents);
    if (startMatch == null)
      return false;

    final int startIndex = startMatch.end;
    final Match endMatch = endRE.firstMatch(contents.substring(startIndex));
    if (endMatch == null)
      return false;

    final String comment = contents.substring(startIndex, startIndex + endMatch.start);
    sourceCode = contents.substring(0, startMatch.start) + contents.substring(startIndex + endMatch.end);
    if (sourceCode.trim().isEmpty)
      throw SampleError('did not find any source code in $sourceFile');

    final RegExp keywordsRE = RegExp(sampleCatalogKeywords, multiLine: true);
    final List<Match> keywordMatches = keywordsRE.allMatches(comment).toList();
    if (keywordMatches.isEmpty)
      throw SampleError('did not find any keywords in the Sample Catalog comment in $sourceFile');

    commentValues = <String, String>{};
    for (int i = 0; i < keywordMatches.length; i += 1) {
      final String keyword = comment.substring(keywordMatches[i].start, keywordMatches[i].end - 1);
      final String value = comment.substring(
        keywordMatches[i].end,
        i == keywordMatches.length - 1 ? null : keywordMatches[i + 1].start,
      );
      commentValues[keyword.toLowerCase()] = value.trim();
    }
    commentValues['name'] = sourceName;
    commentValues['path'] = 'examples/catalog/${sourceFile.path}';
    commentValues['source'] = sourceCode.trim();
    commentValues['link'] = link;
    commentValues['android screenshot'] = 'https://storage.googleapis.com/flutter-catalog/$commit/${sourceName}_small.png';

    return true;
  }
}

void generate(String commit) {
  initialize();

  final List<SampleInfo> samples = <SampleInfo>[];
  for (FileSystemEntity entity in sampleDirectory.listSync()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final SampleInfo sample = SampleInfo(entity, commit);
      if (sample.initialize()) // skip files that lack the Sample Catalog comment
        samples.add(sample);
    }
  }

  // Causes the generated imports to appear in alphabetical order.
  // Avoid complaints from flutter lint.
  samples.sort((SampleInfo a, SampleInfo b) {
    return a.sourceName.compareTo(b.sourceName);
  });

  final String entryTemplate = inputFile('bin', 'entry.md.template').readAsStringSync();

  // Write the sample catalog's home page: index.md
  final Iterable<String> entries = samples.map<String>((SampleInfo sample) {
    return expandTemplate(entryTemplate, sample.commentValues);
  });
  writeExpandedTemplate(
    outputFile('index.md'),
    inputFile('bin', 'index.md.template').readAsStringSync(),
    <String, String>{
      'entries': entries.join('\n'),
    },
  );

  // Write the sample app files, like animated_list.md
  for (SampleInfo sample in samples) {
    writeExpandedTemplate(
      outputFile(sample.sourceName + '.md'),
      inputFile('bin', 'sample_page.md.template').readAsStringSync(),
      sample.commentValues,
    );
  }

  // For each unique class listened in a sample app's "Classes:" list, generate
  // a file that's structurally the same as index.md but only contains samples
  // that feature one class. For example AnimatedList_index.md would only
  // include samples that had AnimatedList in their "Classes:" list.
  final Map<String, List<SampleInfo>> classToSamples = <String, List<SampleInfo>>{};
  for (SampleInfo sample in samples) {
    for (String className in sample.highlightedClasses) {
      classToSamples[className] ??= <SampleInfo>[];
      classToSamples[className].add(sample);
    }
  }
  for (String className in classToSamples.keys) {
    final Iterable<String> entries = classToSamples[className].map<String>((SampleInfo sample) {
      return expandTemplate(entryTemplate, sample.commentValues);
    });
    writeExpandedTemplate(
      outputFile('${className}_index.md'),
      inputFile('bin', 'class_index.md.template').readAsStringSync(),
      <String, String>{
        'class': '$className',
        'entries': entries.join('\n'),
        'link': '${className}_index',
      },
    );
  }

  // Write screenshot.dart, a "test" app that displays each sample
  // app in turn when the app is tapped.
  writeExpandedTemplate(
    outputFile('screenshot.dart', driverDirectory),
    inputFile('bin', 'screenshot.dart.template').readAsStringSync(),
    <String, String>{
      'imports': samples.map<String>((SampleInfo page) {
        return "import '${page.importPath}' show ${page.sampleClass};\n";
      }).toList().join(),
      'widgets': samples.map<String>((SampleInfo sample) {
        return 'new ${sample.sampleClass}(),\n';
      }).toList().join(),
    },
  );

  // Write screenshot_test.dart, a test driver for screenshot.dart
  // that collects screenshots of each app and saves them.
  writeExpandedTemplate(
    outputFile('screenshot_test.dart', driverDirectory),
    inputFile('bin', 'screenshot_test.dart.template').readAsStringSync(),
    <String, String>{
      'paths': samples.map<String>((SampleInfo sample) {
        return "'${outputFile(sample.sourceName + '.png').path}'";
      }).toList().join(',\n'),
    },
  );

  // For now, the website's index.json file must be updated by hand.
  logMessage('The following entries must appear in _data/catalog/widgets.json');
  for (String className in classToSamples.keys)
    logMessage('"sample": "${className}_index"');
}

void main(List<String> args) {
  if (args.length != 1) {
    logError(
      'Usage (cd examples/catalog/; dart bin/sample_page.dart commit)\n'
      'The flutter commit hash locates screenshots on storage.googleapis.com/flutter-catalog/'
    );
    exit(255);
  }
  try {
    generate(args[0]);
  } catch (error) {
    logError(
      'Error: sample_page.dart failed: $error\n'
      'This sample_page.dart app expects to be run from the examples/catalog directory. '
      'More information can be found in examples/catalog/README.md.'
    );
    exit(255);
  }
  exit(0);
}
