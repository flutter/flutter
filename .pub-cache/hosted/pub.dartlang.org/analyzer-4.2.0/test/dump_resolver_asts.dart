//// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
//// for details. All rights reserved. Use of this source code is governed by a
//// BSD-style license that can be found in the LICENSE file.
//
//import 'package:analyzer/dart/analysis/results.dart';
//import 'package:analyzer/file_system/file_system.dart';
//import 'package:analyzer/file_system/physical_file_system.dart';
//import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
//
//import 'src/summary/resolved_ast_printer.dart';
//import 'utils/package_root.dart' as package_root;
//
//main(List<String> arguments) async {
//  var provider = PhysicalResourceProvider.INSTANCE;
//  var pathContext = provider.pathContext;
//
//  var packageRoot = pathContext.normalize(package_root.packageRoot);
//  var analyzerPath = pathContext.join(packageRoot, 'analyzer');
//
//  var libPath = pathContext.join(analyzerPath, 'lib');
//  var dartFiles = _listFiles(provider.getFolder(libPath))
//      .map((file) => file.path)
//      .where((path) => path.endsWith('.dart'))
//      .toList();
//
//  var collection = new AnalysisContextCollectionImpl(
//    includedPaths: <String>[analyzerPath],
//    resourceProvider: provider,
//  );
//
//  for (var path in dartFiles) {
//    print(path);
//    var session = collection.contextFor(path).currentSession;
//    var result = await session.getResolvedUnit(path);
//    _toResolvedUnitText(result);
//  }
//}
//
//Iterable<File> _listFiles(Folder folder) sync* {
//  for (var child in folder.getChildren()) {
//    if (child is File) {
//      yield child;
//    } else if (child is Folder) {
//      yield* _listFiles(child);
//    }
//  }
//}
//
//String _toResolvedUnitText(ResolvedUnitResult result) {
//  var buffer = StringBuffer();
//  result.unit.accept(
//    ResolvedAstPrinter(
//      selfUriStr: '${result.uri}',
//      sink: buffer,
//      indent: '',
//      codeLinesProvider: _CodeLinesProvider(result),
//    ),
//  );
//  return buffer.toString();
//}
//
//class _CodeLinesProvider implements CodeLinesProvider {
//  final ResolvedUnitResult result;
//  int lastLine = -1;
//
//  _CodeLinesProvider(this.result);
//
//  @override
//  String nextLine(int offset) {
//    var location = result.lineInfo.getLocation(offset);
//    var lineNumber = location.lineNumber;
//    if (lineNumber <= lastLine) {
//      return null;
//    }
//
//    lastLine = lineNumber;
//    var a = result.lineInfo.lineStarts[lineNumber - 1];
//    var b = result.lineInfo.lineStarts[lineNumber];
//    return result.content.substring(a, b);
//  }
//}
