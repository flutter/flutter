// // @dart = 2.9
// import 'dart:async';
//
// import 'package:analyzer/dart/analysis/analysis_context.dart';
// import 'package:analyzer/dart/analysis/results.dart';
// import 'package:analyzer/file_system/file_system.dart';
// import 'package:analyzer/file_system/physical_file_system.dart';
// import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
// import 'package:analyzer/src/dart/analysis/byte_store.dart';
// import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
// import 'package:analyzer/src/dart/analysis/file_state.dart';
// import 'package:analyzer/src/dart/analysis/library_analyzer.dart';
// import 'package:analyzer/src/dart/analysis/library_context.dart';
// import 'package:analyzer/src/dart/analysis/session.dart';
// import 'package:analyzer/src/summary2/link.dart';
// import 'package:meta/meta.dart';
//
// main() async {
//   // var flutterPath = '/Users/scheglov/Source/flutter';
//   // var packagesPath = '$flutterPath/packages';
// //  var examplesPath = '$flutterPath/examples';
//   var byteStore = _RemovableByteStore();
//   var bestErrorsTime = Duration(days: 1);
//   while (true) {
//     {
//       contexts = _createContexts(
//         byteStore: byteStore,
//         includedPaths: [
//                '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analysis_server',
//           //      '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer',
//           //         '/Users/scheglov/Source/flutter/dev',
//           // '/Users/scheglov/Source/flutter/examples',
//           // '/Users/scheglov/Source/flutter/examples/hello_world',
//           // '/Users/scheglov/Source/flutter/packages/flutter/lib/src/cupertino',
//           // '/Users/scheglov/Source/flutter/packages/flutter/lib/src/cupertino/button.dart',
//           // '/Users/scheglov/Source/flutter/packages/flutter/lib',
//           // '/Users/scheglov/Source/flutter/packages',
//           // '$packagesPath/flutter',
//           //        '$packagesPath/flutter_test',
//           //        '$packagesPath/flutter_tools',
//           //        '$examplesPath/flutter_gallery',
//           //        '$examplesPath/stocks',
//           //        '$examplesPath/hello_world',
//         ],
//       );
//       contexts.sort((a, b) {
//         var ap = a.contextRoot.root.path;
//         var bp = b.contextRoot.root.path;
//         return ap.compareTo(bp);
//       });
//
//       print('');
//       for (var context in contexts) {
//         print(context.contextRoot.root);
//         print('    files: ${context.contextRoot.analyzedFiles().length}');
//       }
//
//       {
//         var timer = Stopwatch()..start();
//         for (var context in contexts) {
//           AnalysisSessionImpl sessionImpl = context.currentSession;
//           for (var file in context.contextRoot
//               .analyzedFiles()
//               .where((file) => file.endsWith('.dart'))) {
//             await sessionImpl.getErrors2(file) as ErrorsResult;
//           }
//         }
//
//         var timerElapsed = timer.elapsed;
//         if (timerElapsed < bestErrorsTime) {
//           bestErrorsTime = timerElapsed;
//         }
//
//         print(
//           'Computed errors in ${timer.elapsedMilliseconds} ms. '
//           '(best: ${bestErrorsTime.inMilliseconds} ms)',
//         );
//         print(
//             '  timerFileStateRefresh: ${timerFileStateRefresh.elapsedMilliseconds} ms.');
//         print('  timerLoad2: ${timerLoad2.elapsedMilliseconds} ms.');
//         print(
//             '    timerInputLibraries: ${timerInputLibraries.elapsedMilliseconds} ms.');
//         print('    timerLinking: ${timerLinking.elapsedMilliseconds} ms.');
//         //      print('      timerLinkingOutlines: ${timerLinkingOutlines.elapsedMilliseconds} ms.');
//         //      print('        timerLinkingOutlines1: ${timerLinkingOutlines1.elapsedMilliseconds} ms.');
//         //      print('        timerLinkingOutlines2: ${timerLinkingOutlines2.elapsedMilliseconds} ms.');
//         //      print('        timerLinkingOutlines3: ${timerLinkingOutlines3.elapsedMilliseconds} ms.');
//         //      print('        timerLinkingOutlines4: ${timerLinkingOutlines4.elapsedMilliseconds} ms.');
//         //      print('        timerLinkingOutlines5: ${timerLinkingOutlines5.elapsedMilliseconds} ms.');
//         print(
//             '      timerLinkingLinkingBundle: ${timerLinkingLinkingBundle.elapsedMilliseconds} ms.');
//         print(
//             '    timerBundleToBytes: ${timerBundleToBytes.elapsedMilliseconds} ms.');
//         print('    counterLinkedLibraries: $counterLinkedLibraries');
//         print('    counterLoadedLibraries: $counterLoadedLibraries');
//         print('    counterUnlinkedLinkedBytes: $counterUnlinkedLinkedBytes');
//         // print('      counterUnlinkedBytes: $counterUnlinkedBytes');
//         //      print('    timerBundleFromBytes: ${timerBundleFromBytes.elapsedMilliseconds} ms.');
//         // print(
//         //     '  timerReadLibraryElement: ${timerReadLibraryElement.elapsedMilliseconds} ms.');
//         // print(
//         //     '    timerReadLibraryElementApplyInformative: ${timerReadLibraryElementApplyInformative.elapsedMilliseconds} ms.');
//         print(
//             '  timerLibraryAnalyzer: ${timerLibraryAnalyzer.elapsedMilliseconds} ms.');
//         print(
//             '    timerLibraryAnalyzerFreshUnit: ${timerLibraryAnalyzerFreshUnit.elapsedMilliseconds} ms.');
//         print(
//             '    timerLibraryAnalyzerSplicer: ${timerLibraryAnalyzerSplicer.elapsedMilliseconds} ms.');
//         print(
//             '    timerLibraryAnalyzerResolve: ${timerLibraryAnalyzerResolve.elapsedMilliseconds} ms.');
//         print(
//             '    timerLibraryAnalyzerConst: ${timerLibraryAnalyzerConst.elapsedMilliseconds} ms.');
//         print(
//             '    timerLibraryAnalyzerVerify: ${timerLibraryAnalyzerVerify.elapsedMilliseconds} ms.');
//         //      print('  counterFileStateRefresh: $counterFileStateRefresh');
//         timerFileStateRefresh.reset();
//         timerLoad2.reset();
//         timerInputLibraries.reset();
//         timerLinking.reset();
//         //      timerLinkingOutlines.reset();
//         //      timerLinkingOutlines1.reset();
//         //      timerLinkingOutlines2.reset();
//         //      timerLinkingOutlines3.reset();
//         //      timerLinkingOutlines4.reset();
//         //      timerLinkingOutlines5.reset();
//         timerLinkingLinkingBundle.reset();
//         timerBundleToBytes.reset();
//         //      timerBundleFromBytes.reset();
//         timerLibraryAnalyzer.reset();
//         timerLibraryAnalyzerFreshUnit.reset();
//         timerLibraryAnalyzerSplicer.reset();
//         timerLibraryAnalyzerResolve.reset();
//         timerLibraryAnalyzerConst.reset();
//         timerLibraryAnalyzerVerify.reset();
//         // timerReadLibraryElement.reset();
//         // timerReadLibraryElementApplyInformative.reset();
//         //      counterFileStateRefresh = 0;
//         counterLinkedLibraries = 0;
//         counterLoadedLibraries = 0;
//         counterUnlinkedLinkedBytes = 0;
//         // counterUnlinkedBytes = 0;
//         //      libraryRefCache.clear();
//
//         //      print('  analyzeTimer: ${analyzeTimer.elapsedMilliseconds} ms.');
//         //      print('    parseTimer: ${parseTimer.elapsedMilliseconds} ms.');
//         //      print('    resolveUriDirectivesTimer: ${resolveUriDirectivesTimer.elapsedMilliseconds} ms.');
//         //      print('    resolveDirectivesTimer: ${resolveDirectivesTimer.elapsedMilliseconds} ms.');
//         //      print('    resolveFilesTimer: ${resolveFilesTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesDeclarationsTimer: ${resolveFilesDeclarationsTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesLibraryScopeTimer: ${resolveFilesLibraryScopeTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesAstRewriteTimer: ${resolveFilesAstRewriteTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesTypeParameterBoundsResolverTimer: ${resolveFilesTypeParameterBoundsResolverTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesTypeResolverTimer: ${resolveFilesTypeResolverTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesVariableResolverTimer: ${resolveFilesVariableResolverTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesPartialResolverTimer: ${resolveFilesPartialResolverTimer.elapsedMilliseconds} ms.');
//         //      print('      resolveFilesResolverTimer: ${resolveFilesResolverTimer.elapsedMilliseconds} ms.');
//         //      print('    computeConstantsTimer: ${computeConstantsTimer.elapsedMilliseconds} ms.');
//         //      print('    computeVerifyErrorsTimer: ${computeVerifyErrorsTimer.elapsedMilliseconds} ms.');
//         //      print('      computeConstantErrorsTimer: ${computeConstantErrorsTimer.elapsedMilliseconds} ms.');
//         //      print('    computeHintsTimer: ${computeHintsTimer.elapsedMilliseconds} ms.');
//         //      analyzeTimer.reset();
//         //      parseTimer.reset();
//         //      resolveUriDirectivesTimer.reset();
//         //      resolveDirectivesTimer.reset();
//         //      resolveFilesTimer.reset();
//         //      resolveFilesDeclarationsTimer.reset();
//         //      resolveFilesLibraryScopeTimer.reset();
//         //      resolveFilesAstRewriteTimer.reset();
//         //      resolveFilesTypeParameterBoundsResolverTimer.reset();
//         //      resolveFilesTypeResolverTimer.reset();
//         //      resolveFilesVariableResolverTimer.reset();
//         //      resolveFilesPartialResolverTimer.reset();
//         //      resolveFilesResolverTimer.reset();
//         //      computeConstantsTimer.reset();
//         //      computeVerifyErrorsTimer.reset();
//         //      computeConstantErrorsTimer.reset();
//         //      computeHintsTimer.reset();
//       }
//     }
//
// //    {
// //      var timer = new Stopwatch()..start();
// //      for (var context in contexts) {
// //        AnalysisSessionImpl sessionImpl = context.currentSession;
// //        await sessionImpl.getDriver().discoverAvailableFiles();
// //      }
// //      print('Discovered files in ${timer.elapsedMilliseconds} ms.');
// //    }
//
//     // byteStore.removeKeysEndingWith('');
//     byteStore.removeKeysEndingWith('.resolved');
//     await Future.delayed(Duration(milliseconds: 5000000), () => 0);
//     print(contexts);
//   }
// }
//
// List<AnalysisContext> contexts;
//
// List<AnalysisContext> _createContexts({
//   @required ByteStore byteStore,
//   @required List<String> includedPaths,
// }) {
//   ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
//
//   var contextCollection = AnalysisContextCollectionImpl(
//     byteStore: byteStore,
//     resourceProvider: resourceProvider,
//     includedPaths: includedPaths,
//     excludedPaths: [
//       '/Users/scheglov/Source/flutter/packages/flutter_tools/test/data',
//       '/Users/scheglov/Source/flutter/packages/flutter_test/test/test_config',
//       '/Users/scheglov/Source/flutter/packages/flutter/lib/src/material/animated_icons/data',
//     ],
//     fileContentCache: FileContentCache(resourceProvider),
//   );
//   return contextCollection.contexts;
//
// //   final List<AnalysisContext> contexts = [];
// //   var contextLocator = ContextLocator(
// //     resourceProvider: resourceProvider,
// //   );
// //   var roots =
// //       contextLocator.locateRoots(includedPaths: includedPaths, excludedPaths: [
// //     '/Users/scheglov/Source/flutter/packages/flutter_tools/test/data',
// //     '/Users/scheglov/Source/flutter/packages/flutter_test/test/test_config',
// //     '/Users/scheglov/Source/flutter/packages/flutter/lib/src/material/animated_icons/data',
// //   ]);
// //   for (var root in roots) {
// //     var contextBuilder = ContextBuilderImpl(
// //       resourceProvider: resourceProvider,
// //     );
// //     var context = contextBuilder.createContext(
// //       byteStore: byteStore,
// //       contextRoot: root,
// // //      performanceLog: PerformanceLog(stdout),
// //       sdkPath: getSdkPath(),
// //       fileContentCache: FileContentCache(
// //         resourceProvider,
// //         Duration(minutes: 5),
// //       ),
// //     );
// //     contexts.add(context);
// //   }
// //   return contexts;
// }
//
// class _RemovableByteStore implements ByteStore {
//   final MemoryByteStore store = MemoryByteStore();
//   final Set<String> keys = <String>{};
//
//   @override
//   List<int> get(String key) {
//     return store.get(key);
//   }
//
//   @override
//   void put(String key, List<int> bytes) {
//     keys.add(key);
//     store.put(key, bytes);
//   }
//
//   void removeKeysEndingWith(String end) {
//     for (var key in keys.toList()) {
//       if (key.endsWith(end)) {
//         // var value = store.get(key);
//         // print('[removeKeysEndingWith][key: $key][length: ${value.length}]');
//         keys.remove(key);
//         store.put(key, null);
//       }
//     }
//   }
// }
