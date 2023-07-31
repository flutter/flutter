// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';

/// Return the result of parsing the file at the given [path].
///
/// If a [resourceProvider] is given, it will be used to access the file system.
///
/// [featureSet] determines what set of features will be assumed by the parser.
/// This parameter is required because the analyzer does not yet have a
/// performant way of computing the correct feature set for a single file to be
/// parsed.  Callers that need the feature set to be strictly correct must
/// create an [AnalysisContextCollection], query it to get an [AnalysisContext],
/// query it to get an [AnalysisSession], and then call `getParsedUnit`.
///
/// Callers that don't need the feature set to be strictly correct can pass in
/// `FeatureSet.latestLanguageVersion()` to enable the default set of features;
/// this is much more performant than using an analysis session, because it
/// doesn't require the analyzer to process the SDK.
///
/// If [throwIfDiagnostics] is `true` (the default), then if any diagnostics are
/// produced because of syntactic errors in the file an `ArgumentError` will be
/// thrown. If the parameter is `false`, then the caller can check the result
/// to see whether there are any errors.
ParseStringResult parseFile(
    {required String path,
    ResourceProvider? resourceProvider,
    required FeatureSet featureSet,
    bool throwIfDiagnostics = true}) {
  resourceProvider ??= PhysicalResourceProvider.INSTANCE;
  var content = (resourceProvider.getResource(path) as File).readAsStringSync();
  return parseString(
      content: content,
      path: path,
      featureSet: featureSet,
      throwIfDiagnostics: throwIfDiagnostics);
}

/// Returns the result of parsing the given [content] as a compilation unit.
///
/// If a [featureSet] is provided, it will be the default set of features that
/// will be assumed by the parser.
///
/// If a [path] is provided, it will be used as the name of the file when
/// reporting errors.
///
/// If [throwIfDiagnostics] is `true` (the default), then if any diagnostics are
/// produced because of syntactic errors in the [content] an `ArgumentError`
/// will be thrown.  This behavior is not intended as a way for the client to
/// find out about errors--it is intended to avoid causing problems for naive
/// clients that might not be thinking about the possibility of parse errors
/// (and might therefore make assumptions about the returned AST that don't hold
/// in the presence of parse errors).  Clients interested in details about parse
/// errors should pass `false` and check `result.errors` to determine what parse
/// errors, if any, have occurred.
ParseStringResult parseString(
    {required String content,
    FeatureSet? featureSet,
    String? path,
    bool throwIfDiagnostics = true}) {
  featureSet ??= FeatureSet.latestLanguageVersion();
  var source = StringSource(content, path ?? '');
  var reader = CharSequenceReader(content);
  var errorCollector = RecordingErrorListener();
  var scanner = Scanner(source, reader, errorCollector)
    ..configureFeatures(
      featureSetForOverriding: featureSet,
      featureSet: featureSet,
    );
  var token = scanner.tokenize();
  var lineInfo = LineInfo(scanner.lineStarts);
  var parser = Parser(
    source,
    errorCollector,
    featureSet: scanner.featureSet,
    lineInfo: lineInfo,
  );
  var unit = parser.parseCompilationUnit(token);
  ParseStringResult result =
      ParseStringResultImpl(content, unit, errorCollector.errors);
  if (throwIfDiagnostics && result.errors.isNotEmpty) {
    var buffer = StringBuffer();
    for (var error in result.errors) {
      var location = lineInfo.getLocation(error.offset);
      buffer.writeln('  ${error.errorCode.name}: ${error.message} - '
          '${location.lineNumber}:${location.columnNumber}');
    }
    throw ArgumentError('Content produced diagnostics when parsed:\n$buffer');
  }
  return result;
}

/// Return the result of resolving the file at the given [path].
///
/// If a [resourceProvider] is given, it will be used to access the file system.
///
/// Note that if more than one file is going to be resolved then this function
/// is inefficient. Clients should instead use [AnalysisContextCollection] to
/// create one or more contexts and use those contexts to resolve the files.
Future<SomeResolvedUnitResult> resolveFile2(
    {required String path, ResourceProvider? resourceProvider}) async {
  AnalysisContext context =
      _createAnalysisContext(path: path, resourceProvider: resourceProvider);
  return await context.currentSession.getResolvedUnit(path);
}

/// Return a newly create analysis context in which the file at the given [path]
/// can be analyzed.
///
/// If a [resourceProvider] is given, it will be used to access the file system.
AnalysisContext _createAnalysisContext(
    {required String path, ResourceProvider? resourceProvider}) {
  AnalysisContextCollection collection = AnalysisContextCollection(
    includedPaths: <String>[path],
    resourceProvider: resourceProvider ?? PhysicalResourceProvider.INSTANCE,
  );
  List<AnalysisContext> contexts = collection.contexts;
  if (contexts.length != 1) {
    throw ArgumentError('path must be an absolute path to a single file');
  }
  return contexts[0];
}
