//import 'dart:async';
//
//import 'package:analyzer/dart/analysis/analysis_context.dart';
//import 'package:analyzer/dart/analysis/context_locator.dart';
//import 'package:analyzer/file_system/file_system.dart';
//import 'package:analyzer/file_system/physical_file_system.dart';
//import 'package:analyzer/src/dart/analysis/byte_store.dart';
//import 'package:analyzer/src/dart/analysis/context_builder.dart';
//import 'package:analyzer/src/dart/analysis/driver.dart';
//import 'package:analyzer/src/dart/analysis/file_state.dart';
//import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
//import 'package:analyzer/src/dart/analysis/library_context.dart';
//import 'package:analyzer/src/dart/analysis/performance_logger.dart';
//import 'package:analyzer/src/dart/analysis/session.dart';
//import 'package:analyzer/src/dart/error/todo_codes.dart';
//import 'package:analyzer/src/summary2/ast_binary_reader.dart';
//import 'package:analyzer/src/summary2/ast_binary_writer.dart';
//import 'package:analyzer/src/summary2/link.dart';
//import 'package:meta/meta.dart';
//
//main() async {
//  var flutterPath = '/Users/scheglov/Source/flutter';
//  var packagesPath = '$flutterPath/packages';
//  var examplesPath = '$flutterPath/examples';
//  while (true) {
//    var byteStore = new MemoryByteStore();
//    var createContexts = _createContexts(
//      byteStore: byteStore,
//      includedPaths: [
////      '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer_plugin',
////      '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer',
//        '$packagesPath/flutter',
////        '$packagesPath/flutter_test',
////        '$packagesPath/flutter_tools',
////        '$examplesPath/flutter_gallery',
////        '$examplesPath/stocks',
////        '$examplesPath/hello_world',
//      ],
//    );
//    var contexts = createContexts.contexts;
//    contexts.sort((a, b) {
//      var ap = a.contextRoot.root.path;
//      var bp = b.contextRoot.root.path;
//      return ap.compareTo(bp);
//    });
//
//    print('');
//    for (var context in contexts) {
//      print(context.contextRoot.root);
//      print('    files: ${context.contextRoot.analyzedFiles().length}');
//    }
//
//    {
//      var timer = new Stopwatch()..start();
//      for (var context in contexts) {
//        AnalysisSessionImpl sessionImpl = context.currentSession;
//        for (var file in context.contextRoot
//            .analyzedFiles()
//            .where((file) => file.endsWith('.dart'))) {
//          var errorsResult = await sessionImpl.getErrors(file);
//          var errors = errorsResult.errors
//              .where((e) => e.errorCode != TodoCode.TODO)
//              .toList();
//          if (errors.isNotEmpty) {
//            print(errors.join('\n'));
//          }
//        }
//      }
//      print('Computed errors in ${timer.elapsedMilliseconds} ms.');
//      print(
//          '  timerFileStateRefresh: ${timerFileStateRefresh.elapsedMilliseconds} ms.');
//      print('  timerLoad2: ${timerLoad2.elapsedMilliseconds} ms.');
//      print(
//          '    timerInputLibraries: ${timerInputLibraries.elapsedMilliseconds} ms.');
//      print('    timerLinking: ${timerLinking.elapsedMilliseconds} ms.');
////      print('      timerLinkingOutlines: ${timerLinkingOutlines.elapsedMilliseconds} ms.');
////      print('        timerLinkingOutlines1: ${timerLinkingOutlines1.elapsedMilliseconds} ms.');
////      print('        timerLinkingOutlines2: ${timerLinkingOutlines2.elapsedMilliseconds} ms.');
////      print('        timerLinkingOutlines3: ${timerLinkingOutlines3.elapsedMilliseconds} ms.');
////      print('        timerLinkingOutlines4: ${timerLinkingOutlines4.elapsedMilliseconds} ms.');
////      print('        timerLinkingOutlines5: ${timerLinkingOutlines5.elapsedMilliseconds} ms.');
//      print(
//          '      timerLinkingLinkingBundle: ${timerLinkingLinkingBundle.elapsedMilliseconds} ms.');
//      print(
//          '      timerLinkingRemoveBundle: ${timerLinkingRemoveBundle.elapsedMilliseconds} ms.');
//      print(
//          '    timerBundleToBytes: ${timerBundleToBytes.elapsedMilliseconds} ms.');
//      print('    counterLinkedLibraries: $counterLinkedLibraries');
//      print('    counterLoadedLibraries: $counterLoadedLibraries');
//      print('    counterUnlinkedLinkedBytes: $counterUnlinkedLinkedBytes');
////      print('    timerBundleFromBytes: ${timerBundleFromBytes.elapsedMilliseconds} ms.');
//      print(
//          '  timerLibraryAnalyzer: ${timerLibraryAnalyzer.elapsedMilliseconds} ms.');
//      print(
//          '    timerLibraryAnalyzerFreshUnit: ${timerLibraryAnalyzerFreshUnit.elapsedMilliseconds} ms.');
//      print(
//          '    timerLibraryAnalyzerSplicer: ${timerLibraryAnalyzerSplicer.elapsedMilliseconds} ms.');
//      print(
//          '    timerLibraryAnalyzerResolve: ${timerLibraryAnalyzerResolve.elapsedMilliseconds} ms.');
//      print(
//          '    timerLibraryAnalyzerConst: ${timerLibraryAnalyzerConst.elapsedMilliseconds} ms.');
//      print(
//          '    timerLibraryAnalyzerVerify: ${timerLibraryAnalyzerVerify.elapsedMilliseconds} ms.');
////      print('  counterFileStateRefresh: $counterFileStateRefresh');
//      print(
//          '  timerAstBinaryReader: ${timerAstBinaryReader.elapsedMilliseconds} ms.');
//      print(
//          '    timerAstBinaryReaderDirective: ${timerAstBinaryReaderDirective.elapsedMilliseconds} ms.');
//      print(
//          '    timerAstBinaryReaderClass: ${timerAstBinaryReaderClass.elapsedMilliseconds} ms.');
//      print(
//          '    timerAstBinaryReaderFunctionDeclaration: ${timerAstBinaryReaderFunctionDeclaration.elapsedMilliseconds} ms.');
//      print(
//          '    timerAstBinaryReaderMixin: ${timerAstBinaryReaderMixin.elapsedMilliseconds} ms.');
//      print(
//          '    timerAstBinaryReaderTopLevelVar: ${timerAstBinaryReaderTopLevelVar.elapsedMilliseconds} ms.');
//      print(
//          '    timerAstBinaryReaderFunctionBody: ${timerAstBinaryReaderFunctionBody.elapsedMilliseconds} ms.');
//      print(
//          '  timerAstBinaryWriter: ${timerAstBinaryWriter.elapsedMilliseconds} ms.');
//      print(
//          '      timerAstBinaryWriterDirective: ${timerAstBinaryWriterDirective.elapsedMilliseconds} ms.');
//      print(
//          '      timerAstBinaryWriterClass: ${timerAstBinaryWriterClass.elapsedMilliseconds} ms.');
//      print(
//          '      timerAstBinaryWriterMixin: ${timerAstBinaryWriterMixin.elapsedMilliseconds} ms.');
//      print(
//          '      timerAstBinaryWriterFunctionBody: ${timerAstBinaryWriterFunctionBody.elapsedMilliseconds} ms.');
//      print(
//          '      timerAstBinaryWriterTypedef: ${timerAstBinaryWriterTypedef.elapsedMilliseconds} ms.');
//      print(
//          '      timerAstBinaryWriterTopVar: ${timerAstBinaryWriterTopVar.elapsedMilliseconds} ms.');
//      timerFileStateRefresh.reset();
//      timerLoad2.reset();
//      timerInputLibraries.reset();
//      timerLinking.reset();
////      timerLinkingOutlines.reset();
////      timerLinkingOutlines1.reset();
////      timerLinkingOutlines2.reset();
////      timerLinkingOutlines3.reset();
////      timerLinkingOutlines4.reset();
////      timerLinkingOutlines5.reset();
//      timerLinkingLinkingBundle.reset();
//      timerLinkingRemoveBundle.reset();
//      timerBundleToBytes.reset();
////      timerBundleFromBytes.reset();
//      timerLibraryAnalyzer.reset();
//      timerLibraryAnalyzerFreshUnit.reset();
//      timerLibraryAnalyzerSplicer.reset();
//      timerLibraryAnalyzerResolve.reset();
//      timerLibraryAnalyzerConst.reset();
//      timerLibraryAnalyzerVerify.reset();
//      timerAstBinaryReader.reset();
//      timerAstBinaryReaderDirective.reset();
//      timerAstBinaryReaderClass.reset();
//      timerAstBinaryReaderFunctionDeclaration.reset();
//      timerAstBinaryReaderMixin.reset();
//      timerAstBinaryReaderTopLevelVar.reset();
//      timerAstBinaryReaderFunctionBody.reset();
//      timerAstBinaryWriter.reset();
//      timerAstBinaryWriterDirective.reset();
//      timerAstBinaryWriterClass.reset();
//      timerAstBinaryWriterMixin.reset();
//      timerAstBinaryWriterFunctionBody.reset();
//      timerAstBinaryWriterTypedef.reset();
//      timerAstBinaryWriterTopVar.reset();
////      counterFileStateRefresh = 0;
//      counterLinkedLibraries = 0;
//      counterLoadedLibraries = 0;
//      counterUnlinkedLinkedBytes = 0;
////      libraryRefCache.clear();
//
////      createContexts.scheduler.stop();
//      await _pumpEventQueue(4096);
//    }
//
////    await new Future.delayed(new Duration(seconds: 0));
//  }
//}
//
//_CreatedContexts _createContexts({
//  @required ByteStore byteStore,
//  @required List<String> includedPaths,
//}) {
//  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
//  final List<AnalysisContext> contexts = [];
//  var contextLocator = new ContextLocator(
//    resourceProvider: resourceProvider,
//  );
//  var roots =
//      contextLocator.locateRoots(includedPaths: includedPaths, excludedPaths: [
//    '/Users/scheglov/Source/flutter/packages/flutter_tools/test/data',
//    '/Users/scheglov/Source/flutter/packages/flutter_test/test/test_config',
//    '/Users/scheglov/Source/flutter/packages/flutter/lib/src/material/animated_icons/data',
//  ]);
//
//  var performanceLog = new PerformanceLog(new StringBuffer());
//  var scheduler = new AnalysisDriverScheduler(performanceLog);
//
//  for (var root in roots) {
//    var contextBuilder = new ContextBuilderImpl(
//      resourceProvider: resourceProvider,
//    );
//    var context = contextBuilder.createContext(
//      byteStore: byteStore,
//      contextRoot: root,
//      scheduler: scheduler,
////      performanceLog: PerformanceLog(stdout),
//    );
//    contexts.add(context);
//  }
//  scheduler.start();
//  return _CreatedContexts(scheduler, contexts);
//}
//
///**
// * Returns a [Future] that completes after performing [times] pumpings of
// * the event queue.
// */
//Future _pumpEventQueue(int times) {
//  if (times == 0) {
//    return new Future.value();
//  }
//  return new Future.delayed(Duration.zero, () => _pumpEventQueue(times - 1));
//}
//
//class _CreatedContexts {
//  final AnalysisDriverScheduler scheduler;
//  final List<AnalysisContext> contexts;
//
//  _CreatedContexts(this.scheduler, this.contexts);
//}
