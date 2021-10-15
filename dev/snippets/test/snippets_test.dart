// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show Directory, File, Process, ProcessResult, ProcessSignal, ProcessStartMode, SystemEncoding;
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:snippets/configuration.dart';
import 'package:snippets/main.dart' show getChannelName;
import 'package:snippets/snippets.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('Generator', () {
    late Configuration configuration;
    late SnippetGenerator generator;
    late Directory tmpDir;
    late File template;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('flutter_snippets_test.');
      configuration = Configuration(flutterRoot: Directory(path.join(
          tmpDir.absolute.path, 'flutter')));
      configuration.createOutputDirectory();
      configuration.templatesDirectory.createSync(recursive: true);
      configuration.skeletonsDirectory.createSync(recursive: true);
      template = File(path.join(configuration.templatesDirectory.path, 'template.tmpl'));
      template.writeAsStringSync('''
// Flutter code sample for {{element}}

{{description}}

import 'package:flutter/material.dart';
import '../foo.dart';

{{code-imports}}

{{code-my-preamble}}

main() {
  {{code}}
}
''');
      configuration.getHtmlSkeletonFile(SnippetType.sample).writeAsStringSync('''
<div>HTML Bits</div>
{{description}}
<pre>{{code}}</pre>
<pre>{{app}}</pre>
<div>More HTML Bits</div>
''');
      configuration.getHtmlSkeletonFile(SnippetType.snippet).writeAsStringSync('''
<div>HTML Bits</div>
{{description}}
<pre>{{code}}</pre>
<div>More HTML Bits</div>
''');
      configuration.getHtmlSkeletonFile(SnippetType.sample, showDartPad: true).writeAsStringSync('''
<div>HTML Bits (DartPad-style)</div>
<iframe class="snippet-dartpad" src="https://dartpad.dev/embed-flutter.html?split=60&run=true&sample_id={{id}}&sample_channel={{channel}}"></iframe>
<div>More HTML Bits</div>
''');
      generator = SnippetGenerator(configuration: configuration);
    });
    tearDown(() {
      tmpDir.deleteSync(recursive: true);
    });

    test('generates samples', () async {
      final File inputFile = File(path.join(tmpDir.absolute.path, 'snippet_in.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
A description of the snippet.

On several lines.

```dart imports
import 'dart:ui';
```

```my-dart_language my-preamble
const String name = 'snippet';
```

```dart
void main() {
  print('The actual $name.');
}
```
''');
      final File outputFile = File(path.join(tmpDir.absolute.path, 'snippet_out.txt'));

      final String html = generator.generate(
        inputFile,
        SnippetType.sample,
        template: 'template',
        metadata: <String, Object>{
          'id': 'id',
          'channel': 'stable',
          'element': 'MyElement',
        },
        output: outputFile,
      );
      expect(html, contains('<div>HTML Bits</div>'));
      expect(html, contains('<div>More HTML Bits</div>'));
      expect(html, contains(r'print(&#39;The actual $name.&#39;);'));
      expect(html, contains('A description of the snippet.\n'));
      expect(html, isNot(contains('sample_channel=stable')));
      expect(
          html,
          contains('&#47;&#47; A description of the snippet.\n'
              '&#47;&#47;\n'
              '&#47;&#47; On several lines.\n'));
      expect(html, contains('void main() {'));

      final String outputContents = outputFile.readAsStringSync();
      expect(outputContents, contains('// Flutter code sample for MyElement'));
      expect(outputContents, contains('A description of the snippet.'));
      expect(outputContents, contains('void main() {'));
      expect(outputContents, contains("const String name = 'snippet';"));
      final List<String> lines = outputContents.split('\n');
      final int dartUiLine = lines.indexOf("import 'dart:ui';");
      final int materialLine = lines.indexOf("import 'package:flutter/material.dart';");
      final int otherLine = lines.indexOf("import '../foo.dart';");
      expect(dartUiLine, lessThan(materialLine));
      expect(materialLine, lessThan(otherLine));
    });

    test('generates snippets', () async {
      final File inputFile = File(path.join(tmpDir.absolute.path, 'snippet_in.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
A description of the snippet.

On several lines.

```code
void main() {
  print('The actual $name.');
}
```
''');

      final String html = generator.generate(
        inputFile,
        SnippetType.snippet,
        metadata: <String, Object>{'id': 'id'},
      );
      expect(html, contains('<div>HTML Bits</div>'));
      expect(html, contains('<div>More HTML Bits</div>'));
      expect(html, contains(r'  print(&#39;The actual $name.&#39;);'));
      expect(html, contains('<div class="snippet-description">{@end-inject-html}A description of the snippet.\n\n'
          'On several lines.{@inject-html}</div>\n'));
      expect(html, contains('main() {'));
    });

    test('generates dartpad samples', () async {
      final File inputFile = File(path.join(tmpDir.absolute.path, 'snippet_in.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
A description of the snippet.

On several lines.

```code
void main() {
  print('The actual $name.');
}
```
''');

      final String html = generator.generate(
        inputFile,
        SnippetType.sample,
        showDartPad: true,
        template: 'template',
        metadata: <String, Object>{'id': 'id', 'channel': 'stable'},
      );
      expect(html, contains('<div>HTML Bits (DartPad-style)</div>'));
      expect(html, contains('<div>More HTML Bits</div>'));
      expect(html, contains('<iframe class="snippet-dartpad" src="https://dartpad.dev/embed-flutter.html?split=60&run=true&sample_id=id&sample_channel=stable"></iframe>'));
    });

    test('generates sample metadata', () async {
      final File inputFile = File(path.join(tmpDir.absolute.path, 'snippet_in.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
A description of the snippet.

On several lines.

```code
void main() {
  print('The actual $name.');
}
```
''');

      final File outputFile = File(path.join(tmpDir.absolute.path, 'snippet_out.dart'));
      final File expectedMetadataFile = File(path.join(tmpDir.absolute.path, 'snippet_out.json'));

      generator.generate(
        inputFile,
        SnippetType.sample,
        template: 'template',
        output: outputFile,
        metadata: <String, Object>{'sourcePath': 'some/path.dart', 'id': 'id', 'channel': 'stable'},
      );
      expect(expectedMetadataFile.existsSync(), isTrue);
      final Map<String, dynamic> json = jsonDecode(expectedMetadataFile.readAsStringSync()) as Map<String, dynamic>;
      expect(json['id'], equals('id'));
      expect(json['channel'], equals('stable'));
      expect(json['file'], equals('snippet_out.dart'));
      expect(json['description'], equals('A description of the snippet.\n\nOn several lines.'));
      // Ensure any passed metadata is included in the output JSON too.
      expect(json['sourcePath'], equals('some/path.dart'));
    });
  });

  group('getChannelName()', () {
    test('does not call git if LUCI_BRANCH env var provided', () {
      const String branch = 'stable';
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{'LUCI_BRANCH': branch},
      );
      final FakeProcessManager processManager = FakeProcessManager(<FakeCommand>[]);
      expect(
        getChannelName(
          platform: platform,
          processManager: processManager,
        ),
        branch,
      );
      expect(processManager.hasRemainingExpectations, false);
    });

    test('calls git if LUCI_BRANCH env var is not provided', () {
      const String branch = 'stable';
      final FakePlatform platform = FakePlatform(
        environment: <String, String>{},
      );
      final ProcessResult result = ProcessResult(0, 0, '## $branch...refs/heads/master', '');
      final FakeProcessManager processManager = FakeProcessManager(
        <FakeCommand>[FakeCommand('git status -b --porcelain', result)],
      );
      expect(
        getChannelName(
          platform: platform,
          processManager: processManager,
        ),
        branch,
      );
      expect(processManager.hasRemainingExpectations, false);
    });
  });
}

const SystemEncoding systemEncoding = SystemEncoding();

class FakeCommand {
  FakeCommand(this.command, [ProcessResult? result]) : _result = result;
  final String command;

  final ProcessResult? _result;
  ProcessResult get result => _result ?? ProcessResult(0, 0, '', '');
}

class FakeProcessManager implements ProcessManager {
  FakeProcessManager(this.remainingExpectations);

  final List<FakeCommand> remainingExpectations;

  @override
  bool canRun(dynamic command, {String? workingDirectory}) => true;

  @override
  Future<Process> start(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    throw Exception('not implemented');
  }

  @override
  Future<ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    throw Exception('not implemented');
  }

  @override
  ProcessResult runSync(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    if (remainingExpectations.isEmpty) {
      fail(
        'Called FakeProcessManager with $command when no further commands were expected!',
      );
    }
    final FakeCommand expectedCommand = remainingExpectations.removeAt(0);
    final String expectedName = expectedCommand.command;
    final String actualName = command.join(' ');
    if (expectedName != actualName) {
      fail(
        'FakeProcessManager expected the command $expectedName but received $actualName',
      );
    }
    return expectedCommand.result;
  }

  bool get hasRemainingExpectations => remainingExpectations.isNotEmpty;

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) {
    throw Exception('not implemented');
  }
}
