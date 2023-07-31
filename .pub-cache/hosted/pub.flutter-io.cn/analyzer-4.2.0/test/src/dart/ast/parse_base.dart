// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';

class ParseBase with ResourceProviderMixin {
  /// Override this to change the analysis options for a given set of tests.
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl();

  ParseResult parseUnit(String path) {
    var file = getFile(path);
    var source = file.createSource();
    var content = file.readAsStringSync();

    final analysisOptions = this.analysisOptions;
    var featureSet = analysisOptions.contextFeatures;

    var errorListener = RecordingErrorListener();

    var reader = CharSequenceReader(content);
    var scanner = Scanner(source, reader, errorListener)
      ..configureFeatures(
        featureSetForOverriding: featureSet,
        featureSet: featureSet,
      );

    var token = scanner.tokenize();
    var lineInfo = LineInfo(scanner.lineStarts);
    featureSet = scanner.featureSet;

    var parser = Parser(
      source,
      errorListener,
      featureSet: featureSet,
      lineInfo: lineInfo,
    );
    parser.enableOptionalNewAndConst = true;

    var unit = parser.parseCompilationUnit(token);

    return ParseResult(
      path,
      content,
      unit.lineInfo,
      unit,
      errorListener.errors,
    );
  }
}

class ParseResult {
  final String path;
  final String content;
  final LineInfo lineInfo;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  ParseResult(this.path, this.content, this.lineInfo, this.unit, this.errors);
}
