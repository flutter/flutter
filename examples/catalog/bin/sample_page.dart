// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

// See /builds/dev/flutter/packages/flutter_tools/bin/fuchsia_builder.dart for arg parsing

const sampleCatalogKeywords = r'^Title:|^Summary:|^Description:|^Classes:|^Sample:|^See also:';

Directory outputDirectory;
Directory sampleDirectory;
Directory testDirectory;
Directory driverDirectory;
String sampleTemplate;
String screenshotTemplate;
String screenshotDriverTemplate;

void logMessage(String s) {
  print(s);
}

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
  sampleTemplate = sampleTemplateFile.readAsStringSync();
  screenshotTemplate = screenshotTemplateFile.readAsStringSync();
  screenshotDriverTemplate = screenshotDriverTemplateFile.readAsStringSync();
}

// fileName(new File('/foo/bar/baz.dart')) => 'baz'
String fileName(File file) {
  // In /foo/bar/baz.dart, matches baz.dart, match[1] == 'baz'
  final RegExp nameRE = new RegExp(r'(\w+)\.dart$');
  final Match nameMatch = nameRE.firstMatch(file.path);
  if (nameMatch.groupCount != 1)
    throw new SampleError('bad file path ${file.path}');
  return nameMatch[1];
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

class SampleError extends Error {
  SampleError(this.message);

  final String message;

  @override
  String toString() => '$message ($sampleFile)';
}

class SamplePageGenerator {
  SamplePageGenerator(this.sourceFile);

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
    final Math endMatch = endRE.firstMatch(contents.substring(startIndex));
    if (endMatch == null)
      return false;

    final String comment = contents.substring(startIndex, startIndex + endMatch.start);
    sourceCode = contents.substring(0, startMatch.start) + contents.substring(startIndex + endMatch.end);
    if (sourceCode.length == 0)
      throw new SampleError('did not find any source code');

    final RegExp keywordsRE = new RegExp(sampleCatalogKeywords, multiLine: true);
    final List<Match> keywordMatches = keywordsRE.allMatches(comment).toList();
    // TBD: fix error generation
    if (keywordMatches.length == 0)
      throw new SampleError('did not find any keywords in the Sample Catalog comment');

    commentValues = new Map<String, String>();
    for (int i = 0; i < keywordMatches.length; i += 1) {
      final String keyword = comment.substring(keywordMatches[i].start, keywordMatches[i].end - 1);
      final String value = comment.substring(
        keywordMatches[i].end,
        i == keywordMatches.length - 1 ? null : keywordMatches[i + 1].start,
      );
      commentValues[keyword.toLowerCase()] = value.trim();
    }
    commentValues['source'] = sourceCode.trim();

    return true;
  }
}

void main(List<String> args) {
  initialize();

  List<SampleGenerator> samples = <SampleGenerator>[];
  sampleDirectory.listSync().forEach((FilSystemEntity entity) {
    if (entity is File && (entity as File).path.endsWith('.dart')) {
      SamplePageGenerator sample = new SamplePageGenerator(entity);
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
    outputFile('screenshot.dart', testDirectory),
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
        return "'${outputFile(sample.sourceName + '.png').path}'";
      }).toList().join(',\n'),
    },
  );
}
