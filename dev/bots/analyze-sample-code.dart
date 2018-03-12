// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

// To run this: bin/cache/dart-sdk/bin/dart dev/bots/analyze-sample-code.dart

final String _flutterRoot = path.dirname(path.dirname(path.dirname(path.fromUri(Platform.script))));
final String _flutter = path.join(_flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');

class Line {
  const Line(this.filename, this.line, this.indent);
  final String filename;
  final int line;
  final int indent;
  Line get next => this + 1;
  Line operator +(int count) {
    if (count == 0)
      return this;
    return new Line(filename, line + count, indent);
  }
  @override
  String toString([int column]) {
    if (column != null)
      return '$filename:$line:${column + indent}';
    return '$filename:$line';
  }
}

class Section {
  const Section(this.start, this.preamble, this.code, this.postamble);
  final Line start;
  final String preamble;
  final List<String> code;
  final String postamble;
  Iterable<String> get strings sync* {
    if (preamble != null) {
      assert(!preamble.contains('\n'));
      yield preamble;
    }
    assert(!code.any((String line) => line.contains('\n')));
    yield* code;
    if (postamble != null) {
      assert(!postamble.contains('\n'));
      yield postamble;
    }
  }
  List<Line> get lines {
    final List<Line> result = new List<Line>.generate(code.length, (int index) => start + index);
    if (preamble != null)
      result.insert(0, null);
    if (postamble != null)
      result.add(null);
    return result;
  }
}

const String kDartDocPrefix = '///';
const String kDartDocPrefixWithSpace = '$kDartDocPrefix ';

Future<Null> main() async {
  final Directory temp = Directory.systemTemp.createTempSync('analyze_sample_code_');
  int exitCode = 1;
  bool keepMain = false;
  final List<String> buffer = <String>[];
  try {
    final File mainDart = new File(path.join(temp.path, 'main.dart'));
    final File pubSpec = new File(path.join(temp.path, 'pubspec.yaml'));
    final Directory flutterPackage = new Directory(path.join(_flutterRoot, 'packages', 'flutter', 'lib'));
    final List<Section> sections = <Section>[];
    int sampleCodeSections = 0;
    for (FileSystemEntity file in flutterPackage.listSync(recursive: true, followLinks: false)) {
      if (file is File && path.extension(file.path) == '.dart') {
        final List<String> lines = file.readAsLinesSync();
        bool inPreamble = false;
        bool inSampleSection = false;
        bool inDart = false;
        bool foundDart = false;
        int lineNumber = 0;
        final List<String> block = <String>[];
        Line startLine;
        for (String line in lines) {
          lineNumber += 1;
          final String trimmedLine = line.trim();
          if (inPreamble) {
            if (line.isEmpty) {
              inPreamble = false;
              processBlock(startLine, block, sections);
            } else if (!line.startsWith('// ')) {
              throw '${file.path}:$lineNumber: Unexpected content in sample code preamble.';
            } else {
              block.add(line.substring(3));
            }
          } else if (inSampleSection) {
            if (!trimmedLine.startsWith(kDartDocPrefix) || trimmedLine.startsWith('/// ## ')) {
              if (inDart)
                throw '${file.path}:$lineNumber: Dart section inexplicably unterminated.';
              if (!foundDart)
                throw '${file.path}:$lineNumber: No dart block found in sample code section';
              inSampleSection = false;
            } else {
              if (inDart) {
                if (trimmedLine == '/// ```') {
                  inDart = false;
                  processBlock(startLine, block, sections);
                } else if (trimmedLine == kDartDocPrefix) {
                  block.add('');
                } else {
                  final int index = line.indexOf(kDartDocPrefixWithSpace);
                  if (index < 0)
                    throw '${file.path}:$lineNumber: Dart section inexplicably did not contain "$kDartDocPrefixWithSpace" prefix.';
                  block.add(line.substring(index + 4));
                }
              } else if (trimmedLine == '/// ```dart') {
                assert(block.isEmpty);
                startLine = new Line(file.path, lineNumber + 1, line.indexOf(kDartDocPrefixWithSpace) + kDartDocPrefixWithSpace.length);
                inDart = true;
                foundDart = true;
              }
            }
          } else if (line == '// Examples can assume:') {
            assert(block.isEmpty);
            startLine = new Line(file.path, lineNumber + 1, 3);
            inPreamble = true;
          } else if (trimmedLine == '/// ## Sample code' || trimmedLine == '/// ### Sample code') {
            inSampleSection = true;
            foundDart = false;
            sampleCodeSections += 1;
          }
        }
      }
    }
    buffer.add('// generated code');
    buffer.add('import \'dart:async\';');
    buffer.add('import \'dart:convert\';');
    buffer.add('import \'dart:math\' as math;');
    buffer.add('import \'dart:typed_data\';');
    buffer.add('import \'dart:ui\' as ui;');
    buffer.add('import \'package:flutter_test/flutter_test.dart\' hide TypeMatcher;');
    for (FileSystemEntity file in flutterPackage.listSync(recursive: false, followLinks: false)) {
      if (file is File && path.extension(file.path) == '.dart') {
        buffer.add('');
        buffer.add('// ${file.path}');
        buffer.add('import \'package:flutter/${path.basename(file.path)}\';');
      }
    }
    buffer.add('');
    final List<Line> lines = new List<Line>.filled(buffer.length, null, growable: true);
    for (Section section in sections) {
      buffer.addAll(section.strings);
      lines.addAll(section.lines);
    }
    assert(buffer.length == lines.length);
    mainDart.writeAsStringSync(buffer.join('\n'));
    pubSpec.writeAsStringSync('''
name: analyze_sample_code
dependencies:
  flutter:
    sdk: flutter
  flutter_test:
    sdk: flutter
''');
    print('Found $sampleCodeSections sample code sections.');
    final Process process = await Process.start(
      _flutter,
      <String>['analyze', '--no-preamble', mainDart.path],
      workingDirectory: temp.path,
    );
    stderr.addStream(process.stderr);
    final List<String> errors = await process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).toList();
    if (errors.first == 'Building flutter tool...')
      errors.removeAt(0);
    if (errors.first.startsWith('Running "flutter packages get" in '))
      errors.removeAt(0);
    if (errors.first.startsWith('Analyzing '))
      errors.removeAt(0);
    if (errors.last.endsWith(' issues found.') || errors.last.endsWith(' issue found.'))
      errors.removeLast();
    int errorCount = 0;
    for (String error in errors) {
      final String kBullet = Platform.isWindows ? ' - ' : ' • ';
      const String kColon = ':';
      final RegExp atRegExp = new RegExp(r' at .*main.dart:');
      final int start = error.indexOf(kBullet);
      final int end = error.indexOf(atRegExp);
      if (start >= 0 && end >= 0) {
        final String message = error.substring(start + kBullet.length, end);
        final String atMatch = atRegExp.firstMatch(error)[0];
        final int colon2 = error.indexOf(kColon, end + atMatch.length);
        if (colon2 < 0) {
          keepMain = true;
          throw 'failed to parse error message: $error';
        }
        final String line = error.substring(end + atMatch.length, colon2);
        final int bullet2 = error.indexOf(kBullet, colon2);
        if (bullet2 < 0) {
          keepMain = true;
          throw 'failed to parse error message: $error';
        }
        final String column = error.substring(colon2 + kColon.length, bullet2);
        final int lineNumber = int.parse(line, radix: 10, onError: (String source) => throw 'failed to parse error message: $error');
        final int columnNumber = int.parse(column, radix: 10, onError: (String source) => throw 'failed to parse error message: $error');
        if (lineNumber < 1 || lineNumber > lines.length) {
          keepMain = true;
          throw 'failed to parse error message (read line number as $lineNumber; total number of lines is ${lines.length}): $error';
        }
        final Line actualLine = lines[lineNumber - 1];
        final String errorCode = error.substring(bullet2 + kBullet.length);
        if (errorCode == 'unused_element') {
          // We don't really care if sample code isn't used!
        } else if (actualLine == null) {
          if (errorCode == 'missing_identifier' && lineNumber > 1 && buffer[lineNumber - 2].endsWith(',')) {
            final Line actualLine = lines[lineNumber - 2];
            print('${actualLine.toString(buffer[lineNumber - 2].length - 1)}: unexpected comma at end of sample code');
            errorCount += 1;
          } else {
            print('${mainDart.path}:${lineNumber - 1}:$columnNumber: $message');
            keepMain = true;
            errorCount += 1;
          }
        } else {
          print('${actualLine.toString(columnNumber)}: $message ($errorCode)');
          errorCount += 1;
        }
      } else {
        print('?? $error');
        keepMain = true;
        errorCount += 1;
      }
    }
    exitCode = await process.exitCode;
    if (exitCode == 1 && errorCount == 0)
      exitCode = 0;
    if (exitCode == 0)
      print('No errors!');
  } finally {
    if (keepMain) {
      print('Kept ${temp.path} because it had errors (see above).');
      print('-------8<-------');
      int number = 1;
      for (String line in buffer) {
        print('${number.toString().padLeft(6, " ")}: $line');
        number += 1;
      }
      print('-------8<-------');
    } else {
      temp.deleteSync(recursive: true);
    }
  }
  exit(exitCode);
}

int _expressionId = 0;

void processBlock(Line line, List<String> block, List<Section> sections) {
  if (block.isEmpty)
    throw '$line: Empty ```dart block in sample code.';
  if (block.first.startsWith('new ') || block.first.startsWith('const ')) {
    _expressionId += 1;
    sections.add(new Section(line, 'dynamic expression$_expressionId = ', block.toList(), ';'));
  } else if (block.first.startsWith('await ')) {
    _expressionId += 1;
    sections.add(new Section(line, 'Future<Null> expression$_expressionId() async { ', block.toList(), ' }'));
  } else if (block.first.startsWith('class ')) {
    sections.add(new Section(line, null, block.toList(), null));
  } else {
    final List<String> buffer = <String>[];
    int subblocks = 0;
    Line subline;
    for (int index = 0; index < block.length; index += 1) {
      if (block[index] == '' || block[index] == '// ...') {
        if (subline == null)
          throw '${line + index}: Unexpected blank line or "// ..." line near start of subblock in sample code.';
        subblocks += 1;
        processBlock(subline, buffer, sections);
        assert(buffer.isEmpty);
        subline = null;
      } else if (block[index].startsWith('// ')) {
        if (buffer.length > 1) // don't include leading comments
          buffer.add('/${block[index]}'); // so that it doesn't start with "// " and get caught in this again
      } else {
        subline ??= line + index;
        buffer.add(block[index]);
      }
    }
    if (subblocks > 0) {
      if (subline != null)
        processBlock(subline, buffer, sections);
    } else {
      sections.add(new Section(line, null, block.toList(), null));
    }
  }
  block.clear();
}
