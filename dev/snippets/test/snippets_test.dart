// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' hide Platform;
import 'package:path/path.dart' as path;

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'package:snippets/configuration.dart';
import 'package:snippets/snippets.dart';

void main() {
  group('Generator', () {
    Configuration configuration;
    SnippetGenerator generator;
    Directory tmpDir;
    File template;

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
}
