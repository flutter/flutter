/// Support code for the tests in this directory.
library support;

import 'dart:collection';
import 'dart:io';
import 'dart:isolate';

import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart';
import 'package:html/src/treebuilder.dart';
import 'package:path/path.dart' as p;

typedef TreeBuilderFactory = TreeBuilder Function(bool namespaceHTMLElements);

Map<String, TreeBuilderFactory>? _treeTypes;
Map<String, TreeBuilderFactory>? get treeTypes {
  // TODO(jmesserly): add DOM here once it's implemented
  _treeTypes ??= {'simpletree': (useNs) => TreeBuilder(useNs)};
  return _treeTypes;
}

Future<String> get testDirectory async {
  final packageUriDir = p.dirname(p.fromUri(await Isolate.resolvePackageUri(
      Uri(scheme: 'package', path: 'html/html.dart'))));
  // Assume pub layout - root is parent directory to package URI (`lib/`).
  final rootPackageDir = p.dirname(packageUriDir);
  return p.join(rootPackageDir, 'test');
}

Stream<String> dataFiles(String subdirectory) async* {
  final dir = Directory(p.join(await testDirectory, 'data', subdirectory));
  await for (final file in dir.list()) {
    if (file is! File) continue;
    yield file.path;
  }
}

// TODO(jmesserly): make this class simpler. We could probably split on
// "\n#" instead of newline and remove a lot of code.
class TestData extends IterableBase<Map<String?, String>> {
  final String _text;
  final String newTestHeading;

  TestData(String filename, [this.newTestHeading = 'data'])
      // Note: can't use readAsLinesSync here because it splits on \r
      : _text = File(filename).readAsStringSync();

  // Note: in Python this was a generator, but since we can't do that in Dart,
  // it's easier to convert it into an upfront computation.
  @override
  Iterator<Map<String?, String>> get iterator => _getData().iterator;

  List<Map<String?, String>> _getData() {
    var data = <String, String>{};
    String? key;
    final List<Map<String?, String>> result = <Map<String, String>>[];
    final lines = _text.split('\n');
    // Remove trailing newline to match Python
    if (lines.last == '') {
      lines.removeLast();
    }
    for (var line in lines) {
      final heading = sectionHeading(line);
      if (heading != null) {
        if (data.isNotEmpty && heading == newTestHeading) {
          // Remove trailing newline
          data[key!] = data[key]!.substring(0, data[key]!.length - 1);
          result.add(normaliseOutput(data));
          data = <String, String>{};
        }
        key = heading;
        data[key] = '';
      } else if (key != null) {
        data[key] = '${data[key]}$line\n';
      }
    }

    if (data.isNotEmpty) {
      result.add(normaliseOutput(data));
    }
    return result;
  }

  /// If the current heading is a test section heading return the heading,
  /// otherwise return null.
  static String? sectionHeading(String line) {
    return line.startsWith('#') ? line.substring(1).trim() : null;
  }

  static Map<String, String> normaliseOutput(Map<String, String> data) {
    // Remove trailing newlines
    data.forEach((key, value) {
      if (value.endsWith('\n')) {
        data[key] = value.substring(0, value.length - 1);
      }
    });
    return data;
  }
}

/// Serialize the [document] into the html5 test data format.
String testSerializer(Node document) {
  return (TestSerializer()..visit(document)).toString();
}

/// Serializes the DOM into test format. See [testSerializer].
class TestSerializer extends TreeVisitor {
  final StringBuffer _str;
  int _indent = 0;
  String _spaces = '';

  TestSerializer() : _str = StringBuffer();

  @override
  String toString() => _str.toString();

  int get indent => _indent;

  set indent(int value) {
    if (_indent == value) return;
    _spaces = ' ' * value;
    _indent = value;
  }

  void _newline() {
    if (_str.length > 0) _str.write('\n');
    _str.write('|$_spaces');
  }

  @override
  void visitNodeFallback(Node node) {
    _newline();
    _str.write(node);
    visitChildren(node);
  }

  @override
  void visitChildren(Node node) {
    indent += 2;
    for (var child in node.nodes) {
      visit(child);
    }
    indent -= 2;
  }

  @override
  void visitDocument(node) => _visitDocumentOrFragment(node);

  void _visitDocumentOrFragment(Node node) {
    indent += 1;
    for (var child in node.nodes) {
      visit(child);
    }
    indent -= 1;
  }

  @override
  void visitDocumentFragment(DocumentFragment node) =>
      _visitDocumentOrFragment(node);

  @override
  void visitElement(Element node) {
    _newline();
    _str.write(node);
    if (node.attributes.isNotEmpty) {
      indent += 2;
      final keys = node.attributes.keys.toList();
      keys.sort((x, y) {
        if (x is String) return x.compareTo(y as String);
        if (x is AttributeName) return x.compareTo(y as AttributeName);
        throw StateError('Cannot sort');
      });
      for (var key in keys) {
        final v = node.attributes[key];
        if (key is AttributeName) {
          final attr = key;
          key = '${attr.prefix} ${attr.name}';
        }
        _newline();
        _str.write('$key="$v"');
      }
      indent -= 2;
    }
    visitChildren(node);
  }
}
