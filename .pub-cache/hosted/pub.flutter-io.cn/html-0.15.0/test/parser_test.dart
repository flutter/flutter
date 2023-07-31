@TestOn('vm')
library parser_test;

import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

import 'support.dart';

// Run the parse error checks
// TODO(jmesserly): presumably we want this on by default?
final checkParseErrors = false;

String namespaceHtml(String expected) {
  // TODO(jmesserly): this is a workaround for http://dartbug.com/2979
  // We can't do regex replace directly =\
  // final namespaceExpected = new RegExp(@"^(\s*)<(\S+)>", multiLine: true);
  // return expected.replaceAll(namespaceExpected, @"$1<html $2>");
  final namespaceExpected = RegExp(r'^(\|\s*)<(\S+)>');
  final lines = expected.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final match = namespaceExpected.firstMatch(lines[i]);
    if (match != null) {
      lines[i] = '${match[1]}<html ${match[2]}>';
    }
  }
  return lines.join('\n');
}

void runParserTest(
    String groupName,
    String? innerHTML,
    String? input,
    String? expected,
    List? errors,
    TreeBuilderFactory treeCtor,
    bool namespaceHTMLElements) {
  // XXX - move this out into the setup function
  // concatenate all consecutive character tokens into a single token
  final builder = treeCtor(namespaceHTMLElements);
  final parser = HtmlParser(input, tree: builder);

  Node document;
  if (innerHTML != null) {
    document = parser.parseFragment(innerHTML);
  } else {
    document = parser.parse();
  }

  final output = testSerializer(document);

  if (namespaceHTMLElements) {
    expected = namespaceHtml(expected!);
  }

  expect(output, equals(expected),
      reason:
          '\n\nInput:\n$input\n\nExpected:\n$expected\n\nReceived:\n$output');

  if (checkParseErrors) {
    expect(parser.errors.length, equals(errors!.length),
        reason: '\n\nInput:\n$input\n\nExpected errors (${errors.length}):\n'
            "${errors.join('\n')}\n\n"
            'Actual errors (${parser.errors.length}):\n'
            "${parser.errors.map((e) => '$e').join('\n')}");
  }
}

void main() async {
  await for (var path in dataFiles('tree-construction')) {
    if (!path.endsWith('.dat')) continue;

    final tests = TestData(path, 'data');
    final testName = pathos.basenameWithoutExtension(path);

    group(testName, () {
      for (var testData in tests) {
        final input = testData['data'];
        final errorString = testData['errors'];
        final errors = errorString?.split('\n');
        final innerHTML = testData['document-fragment'];
        final expected = testData['document'];

        for (var treeCtor in treeTypes!.values) {
          for (var namespaceHTMLElements in const [false, true]) {
            test(_nameFor(input!), () {
              runParserTest(testName, innerHTML, input, expected, errors,
                  treeCtor, namespaceHTMLElements);
            });
          }
        }
      }
    });
  }
}

/// Extract the name for the test based on the test input data.
dynamic _nameFor(String input) {
  // Using jsonDecode to unescape other unicode characters
  final escapeQuote = input
      .replaceAll(RegExp('\\\\.'), '_')
      .replaceAll(RegExp('\u0000'), '_')
      .replaceAll('"', '\\"')
      .replaceAll(RegExp('[\n\r\t]'), '_');
  return jsonDecode('"$escapeQuote"');
}
