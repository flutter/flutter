// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_utilities/package_root.dart' as package_root;
import 'package:test/test.dart';

main() async {
  SnippetTester tester = SnippetTester();
  await tester.verify();
  if (tester.output.isNotEmpty) {
    fail(tester.output.toString());
  }
}

class SnippetTester {
  final OverlayResourceProvider provider;
  final Folder docFolder;
  final String snippetDirPath;
  final String snippetPath;

  final StringBuffer output = StringBuffer();

  factory SnippetTester() {
    var provider = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
    var packageRoot = provider.pathContext.normalize(package_root.packageRoot);
    var analyzerPath = provider.pathContext.join(packageRoot, 'analyzer');
    var docPath = provider.pathContext.join(analyzerPath, 'doc');
    var docFolder = provider.getFolder(docPath);
    var snippetDirPath =
        provider.pathContext.join(analyzerPath, 'test', 'snippets');
    var snippetPath = provider.pathContext.join(snippetDirPath, 'snippet.dart');
    return SnippetTester._(provider, docFolder, snippetDirPath, snippetPath);
  }

  SnippetTester._(
      this.provider, this.docFolder, this.snippetDirPath, this.snippetPath);

  Future<void> verify() async {
    await verifyFolder(docFolder);
  }

  Future<void> verifyFile(File file) async {
    String content = file.readAsStringSync();
    List<String> lines = const LineSplitter().convert(content);
    List<String> codeLines = [];
    bool inCode = false;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line == '```dart') {
        if (inCode) {
          // TODO(brianwilkerson) Report this.
        }
        inCode = true;
      } else if (line == '```') {
        if (!inCode) {
          // TODO(brianwilkerson) Report this.
        }
        await verifySnippet(file, codeLines.join('\n'));
        codeLines.clear();
        inCode = false;
      } else if (inCode) {
        codeLines.add(line);
      }
    }
  }

  Future<void> verifyFolder(Folder folder) async {
    for (Resource child in folder.getChildren()) {
      if (child is File) {
        if (child.shortName.endsWith('.md')) {
          await verifyFile(child);
        }
      } else if (child is Folder) {
        await verifyFolder(child);
      }
    }
  }

  Future<void> verifySnippet(File file, String snippet) async {
    // TODO(brianwilkerson) When the files outside of 'src' contain only public
    //  API, write code to compute the list of imports so that new public API
    //  will automatically be allowed.
    String imports = '''
// @dart = 2.9
import 'dart:math' as math;

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';

''';
    provider.setOverlay(snippetPath,
        content: '''
$imports
$snippet
''',
        modificationStamp: 1);
    try {
      AnalysisContextCollection collection = AnalysisContextCollection(
          includedPaths: <String>[snippetDirPath], resourceProvider: provider);
      List<AnalysisContext> contexts = collection.contexts;
      if (contexts.length != 1) {
        fail('The snippets directory contains multiple analysis contexts.');
      }
      var results = await contexts[0].currentSession.getErrors(snippetPath);
      if (results is ErrorsResult) {
        Iterable<AnalysisError> errors = results.errors.where((error) {
          ErrorCode errorCode = error.errorCode;
          return errorCode != HintCode.UNUSED_IMPORT &&
              errorCode != HintCode.UNUSED_LOCAL_VARIABLE;
        });
        if (errors.isNotEmpty) {
          String filePath =
              provider.pathContext.relative(file.path, from: docFolder.path);
          if (output.isNotEmpty) {
            output.writeln();
          }
          output.writeln('Errors in snippet in "$filePath":');
          output.writeln();
          output.writeln(snippet);
          output.writeln();
          int importsLength = imports.length + 1; // account for the '\n'.
          for (var error in errors) {
            writeError(error, importsLength);
          }
        }
      }
    } catch (exception, stackTrace) {
      if (output.isNotEmpty) {
        output.writeln();
      }
      output.writeln('Exception while analyzing "$snippet"');
      output.writeln();
      output.writeln(exception);
      output.writeln(stackTrace);
    } finally {
      provider.removeOverlay(snippetPath);
    }
  }

  void writeError(AnalysisError error, int prefixLength) {
    output.write(error.errorCode);
    output.write(' (');
    output.write(error.offset - prefixLength);
    output.write(', ');
    output.write(error.length);
    output.write(') ');
    output.writeln(error.message);
  }
}
