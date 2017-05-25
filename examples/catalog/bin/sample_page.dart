// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This application generates markdown pages and screenshots for each
// sample app. For more information see ../README.md.

import 'dart:io';

class SampleError extends Error {
  SampleError(this.message);
  final String message;
  @override
  String toString() => message;
}

// Sample apps are .dart files in the lib directory which contain a block
// comment that begins with a '/* Sample Catalog' line, and ends with a line
// that just  contains '*/'. The following keywords may appear at the
// beginning of lines within the comment. A keyword's value is all of
// the following text up to the next keyword or the end of the comment,
// sans leading and trailing whitespace.
const String sampleCatalogKeywords = r'^Title:|^Summary:|^Description:|^Classes:|^Sample:|^See also:';

Directory outputDirectory;
Directory sampleDirectory;
Directory testDirectory;
Directory driverDirectory;
String sampleTemplate;
String screenshotTemplate;
String screenshotDriverTemplate;

void logMessage(String s) { print(s); }
void logError(String s) { print(s); }

File inputFile(String dir, String name) {
  return new File(dir + Platform.pathSeparator + name);
}

File outputFile(String name, [Directory directory]) {
  return new File((directory ?? outputDirectory).path + Platform.pathSeparator + name);
}

void initialize() {
  final File sampleTemplateFile = inputFile('bin', 'sample_page.md.template');
  final File screenshotTemplateFile = inputFile('bin', 'screenshot.dart.template');
  final File screenshotDriverTemplateFile = inputFile('bin', 'screenshot_test.dart.template');

  outputDirectory = new Directory('.generated');
  sampleDirectory = new Directory('lib');
  testDirectory = new Directory('test');
  driverDirectory = new Directory('test_driver');
  outputDirectory.createSync();
  sampleTemplate = sampleTemplateFile.readAsStringSync();
  screenshotTemplate = screenshotTemplateFile.readAsStringSync();
  screenshotDriverTemplate = screenshotDriverTemplateFile.readAsStringSync();
}

// Return a copy of template with each occurrence of @(foo) replaced
// by values[foo].
String expandTemplate(String template, Map<String, String> values) {
  // Matches @(foo), match[1] == 'foo'
  final RegExp tokenRE = new RegExp(r'@\(([\w ]+)\)', multiLine: true);
  return template.replaceAllMapped(tokenRE, (Match match) {
    if (match.groupCount != 1)
      throw new SampleError('bad template keyword $match[0]');
    final String keyword = match[1];
    return (values[keyword] ?? "");
  });
}

void writeExpandedTemplate(File output, String template, Map<String, String> values) {
  output.writeAsStringSync(expandTemplate(template, values));
  logMessage('wrote $output');
}

class SampleGenerator {
  SampleGenerator(this.sourceFile);

  final File sourceFile;
  String sourceCode;
  Map<String, String> commentValues;

  // If sourceFile is lib/foo.dart then sourceName is foo. The sourceName
  // is used to create derived filenames like foo.md or foo.png.
  String get sourceName {
    // In /foo/bar/baz.dart, matches baz.dart, match[1] == 'baz'
    final RegExp nameRE = new RegExp(r'(\w+)\.dart$');
    final Match nameMatch = nameRE.firstMatch(sourceFile.path);
    if (nameMatch.groupCount != 1)
      throw new SampleError('bad source file name ${sourceFile.path}');
    return nameMatch[1];
  }

  // The name of the widget class that defines this sample app, like 'FooSample'.
  String get sampleClass => commentValues["sample"];

  // The relative import path for this sample, like '../lib/foo.dart'.
  String get importPath => '..' + Platform.pathSeparator + sourceFile.path;

  // Return true if we're able to find the "Sample Catalog" comment in the
  // sourceFile, and we're able to load its keyword/value pairs into
  // the commentValues Map. The rest of the file's contents are saved
  // in sourceCode.
  bool initialize() {
    final String contents = sourceFile.readAsStringSync();

    final RegExp startRE = new RegExp(r'^/\*\s+^Sample\s+Catalog', multiLine: true);
    final RegExp endRE = new RegExp(r'^\*/', multiLine: true);
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
      throw new SampleError('did not find any source code in $sourceFile');

    final RegExp keywordsRE = new RegExp(sampleCatalogKeywords, multiLine: true);
    final List<Match> keywordMatches = keywordsRE.allMatches(comment).toList();
    if (keywordMatches.isEmpty)
      throw new SampleError('did not find any keywords in the Sample Catalog comment in $sourceFile');

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

    return true;
  }
}

void generate() {
  initialize();

  final List<SampleGenerator> samples = <SampleGenerator>[];
  sampleDirectory.listSync().forEach((FileSystemEntity entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final SampleGenerator sample = new SampleGenerator(entity);
      if (sample.initialize()) { // skip files that lack the Sample Catalog comment
        writeExpandedTemplate(
          outputFile(sample.sourceName + '.md'),
          sampleTemplate,
          sample.commentValues,
        );
        samples.add(sample);
      }
    }
  });

  writeExpandedTemplate(
    outputFile('screenshot.dart', driverDirectory),
    screenshotTemplate,
    <String, String>{
      'imports': samples.map((SampleGenerator page) {
        return "import '${page.importPath}' show ${page.sampleClass};\n";
      }).toList().join(),
      'widgets': samples.map((SampleGenerator sample) {
        return 'new ${sample.sampleClass}(),\n';
      }).toList().join(),
    },
  );

  writeExpandedTemplate(
    outputFile('screenshot_test.dart', driverDirectory),
    screenshotDriverTemplate,
    <String, String>{
      'paths': samples.map((SampleGenerator sample) {
        return "'${outputFile('\${prefix}' + sample.sourceName + '.png').path}'";
      }).toList().join(',\n'),
    },
  );

  // To generate the screenshots: flutter drive test_driver/screenshot.dart
}

void main(List<String> args) {
  try {
    generate();
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
