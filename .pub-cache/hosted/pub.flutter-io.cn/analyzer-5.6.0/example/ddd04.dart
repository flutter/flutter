// import 'dart:io' hide BytesBuilder;
// import 'dart:typed_data';
//
// import 'package:analyzer/file_system/physical_file_system.dart';
// import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
// import 'package:vm_service/vm_service.dart';
// import 'package:analyzer/src/dart/analysis/byte_store.dart';
// import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
// import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
//
// import 'heap/analysis.dart';
// import 'heap/format.dart';
// import 'heap/load.dart';
//
// /// --observe:5000 --disable-service-auth-codes --pause_isolates_on_unhandled_exceptions=false --pause_isolates_on_exit=false
// void main() async {
//   // var path = '/Users/scheglov/dart/rwf-materials';
//   // var path = '/Users/scheglov/dart/rwf-materials/01-setting-up-your-environment';
//   var path =
//       '/Users/scheglov/dart/rwf-materials/01-setting-up-your-environment/projects/starter/packages/component_library';
//
//   // var profiler = ProcessProfiler.getProfilerForPlatform()!;
//   while (true) {
//     var resourceProvider = PhysicalResourceProvider.INSTANCE;
//     var fileContentCache = FileContentCache(resourceProvider);
//     var unlinkedUnitStore = UnlinkedUnitStoreImpl();
//
//     var collection = AnalysisContextCollectionImpl(
//       byteStore: MemoryByteStore(),
//       resourceProvider: resourceProvider,
//       fileContentCache: fileContentCache,
//       unlinkedUnitStore: unlinkedUnitStore,
//       sdkPath: '/Users/scheglov/Applications/dart-sdk',
//       // performanceLog: PerformanceLog(stdout),
//       includedPaths: [
//         path,
//       ],
//       // packagesFile:
//       //     '/Users/scheglov/dart/rwf-materials/15-automating-test-executions-and-build-distributions/projects/final/.dart_tool/package_config.json',
//     );
//
//     print('[Analysis contexts: ${collection.contexts.length}]');
//
//     // double maxMemory = 0;
//     var timer = Stopwatch()..start();
//     for (var analysisContext in collection.contexts) {
//       // print(analysisContext.contextRoot.root.path);
//       var analyzedFiles = analysisContext.contextRoot.analyzedFiles().toList();
//       for (var filePath in analyzedFiles) {
//         if (filePath.endsWith('.dart')) {
//           // print('  $filePath');
//           var analysisSession = analysisContext.currentSession;
//           await analysisSession.getResolvedUnit(filePath);
//
//           // collectAllGarbage();
//
//           // var usageInfo = await profiler.getProcessUsage(pid);
//           // var memoryMB = usageInfo!.memoryMB;
//           // if (memoryMB > maxMemory) {
//           //   maxMemory = memoryMB;
//           //   print('  heap: $maxMemory MB');
//           //   // if (maxMemory > 2000) {
//           //   //   writeHeapSnapshotToFile(
//           //   //     '/Users/scheglov/dart/rwf-materials/2000.heap',
//           //   //   );
//           //   //   // await Future<void>.delayed(const Duration(seconds: 10));
//           //   //   exit(0);
//           //   // }
//           // }
//           // maxMemory = max(maxMemory, usageInfo!.memoryMB);
//         }
//       }
//     }
//     timer.stop();
//     print('[time: ${timer.elapsedMilliseconds} ms]');
//
//     {
//       var timer = Stopwatch()..start();
//       var chunks = await loadFromUri(Uri.parse('http://127.0.0.1:5000'));
//       // final length = chunks
//       //     .map((e) => e.lengthInBytes)
//       //     .fold<int>(0, (prev, e) => prev + e);
//       // print(
//       //   '  [${timer.elapsedMilliseconds} ms] '
//       //   'Downloaded heap snapshot, ${length / 1024 / 1024} MB.',
//       // );
//
//       if (0 == 1) {
//         final bytesBuilder = BytesBuilder();
//         for (final chunk in chunks) {
//           bytesBuilder.add(
//             chunk.buffer.asUint8List(
//               chunk.offsetInBytes,
//               chunk.lengthInBytes,
//             ),
//           );
//         }
//         final bytes = bytesBuilder.toBytes();
//         final path = '/Users/scheglov/tmp/01.heap_snapshot';
//         File(path).writeAsBytesSync(bytes);
//         final lengthStr = (bytes.length / 1024 / 1024).toStringAsFixed(2);
//         print('Stored $lengthStr MB into $path');
//       }
//
//       final graph = HeapSnapshotGraph.fromChunks(chunks);
//       print('  [${timer.elapsedMilliseconds} ms] Created HeapSnapshotGraph.');
//       print('  externalSize: ${graph.externalSize}');
//       print('  shallowSize: ${graph.shallowSize}');
//       print('  Objects: ${graph.objects.length}');
//
//       final analysis = Analysis(graph);
//       print('  [${timer.elapsedMilliseconds} ms] Created Analysis.');
//
//       {
//         print('All objects.');
//         final objects = analysis.reachableObjects;
//         final stats = analysis.generateObjectStats(objects);
//         print(formatHeapStats(stats, maxLines: 20));
//         print('');
//       }
//
//       {
//         print('FileState(s)');
//         var fileStateList = analysis.filter(
//           analysis.reachableObjects,
//               (object) {
//             return object.klass.name == 'FileState';
//           },
//         );
//         analysis.printObjectStats(fileStateList);
//         print('');
//         final allObjects = analysis.transitiveGraph(fileStateList);
//         analysis.printObjectStats(allObjects);
//         print('');
//       }
//
//       if (0 == 1) {
//         print('Instances of: _SimpleUri');
//         final uriList = analysis.filterByClassPatterns(
//           analysis.reachableObjects,
//           ['_SimpleUri'],
//         );
//         final stats = analysis.generateObjectStats(uriList);
//         print(formatHeapStats(stats, maxLines: 20));
//         print('');
//
//         final uriStringList = analysis.findReferences(uriList, [':_uri']);
//
//         // TODO(scheglov) Restore
//         final uniqueUriStrSet = Set<String>();
//         for (final objectId in uriStringList) {
//           var object = graph.objects[objectId];
//           var uriStr = object.data as String;
//           if (!uniqueUriStrSet.add(uriStr)) {
//             throw StateError('Duplicate URI: $uriStr');
//           }
//         }
//
//         final dstats = analysis.generateDataStats(uriStringList);
//         print(formatDataStats(dstats, maxLines: 20));
//       }
//
//       if (0 == 0) {
//         print('Instances of: LibraryElementImpl');
//         final uriList = analysis.filterByClassPatterns(
//           analysis.reachableObjects,
//           ['LibraryElementImpl'],
//         );
//         final stats = analysis.generateObjectStats(uriList);
//         print(formatHeapStats(stats, maxLines: 20));
//         print('');
//       }
//
//       if (0 == 0) {
//         print('Instances of: _GrowableList');
//         final objectList = analysis.filter(analysis.reachableObjects, (object) {
//           return object.klass.libraryUri == Uri.parse('dart:core') &&
//               object.klass.name == '_GrowableList';
//           // return analysis.variableLengthOf(object) == 0;
//         });
//
//         // final objectList = analysis.filterByClassPatterns(
//         //   analysis.reachableObjects,
//         //   ['_GrowableList'],
//         // );
//         final stats = analysis.generateObjectStats(objectList);
//         print(formatHeapStats(stats, maxLines: 20));
//         print('');
//
//         const maxEntries = 10;
//         final paths = analysis.retainingPathsOf(objectList, 10);
//         for (int i = 0; i < paths.length; ++i) {
//           if (maxEntries != -1 && i >= maxEntries) break;
//           final path = paths[i];
//           print('There are ${path.count} retaining paths of');
//           print(formatRetainingPath(analysis.graph, paths[i]));
//           print('');
//         }
//
//         {
//           print('Instances of empty: _GrowableList');
//           final emptyList = analysis.filter(objectList, (object) {
//             return analysis.variableLengthOf(object) == 0;
//           });
//           final stats = analysis.generateObjectStats(emptyList);
//           print(formatHeapStats(stats, maxLines: 20));
//           print('');
//
//           // final paths = analysis.retainingPathsOf(emptyList, 10);
//           // for (int i = 0; i < paths.length; ++i) {
//           //   if (maxEntries != -1 && i >= maxEntries) break;
//           //   final path = paths[i];
//           //   print('There are ${path.count} retaining paths of');
//           //   print(formatRetainingPath(analysis.graph, paths[i]));
//           //   print('');
//           // }
//         }
//         // final dstats = analysis.generateDataStats(uriStringList);
//         // print(formatDataStats(dstats, maxLines: 20));
//       }
//     }
//
//     break;
//
//     // writeHeapSnapshotToFile(
//     //   '/Users/scheglov/dart/rwf-materials/2001.heap',
//     // );
//   }
//
//   // var analysisContext = collection.contextFor(path);
//   // var unitResult = await analysisContext.currentSession.getResolvedUnit(path);
//   // unitResult as ResolvedUnitResult;
//
//   // await Future<void>.delayed(const Duration(days: 1));
// }
//
// extension on Analysis {
//   void printObjectStats(IntSet objectIds) {
//     final stats = generateObjectStats(objectIds);
//     print(formatHeapStats(stats, maxLines: 20));
//     print('');
//   }
//
//   void printRetainers(
//       IntSet objectIds, {
//         int maxEntries = 3,
//       }) {
//     final paths = retainingPathsOf(objectIds, 20);
//     for (int i = 0; i < paths.length; ++i) {
//       if (i >= maxEntries) break;
//       final path = paths[i];
//       print('There are ${path.count} retaining paths of');
//       print(formatRetainingPath(graph, paths[i]));
//       print('');
//     }
//   }
//
//   IntSet filterByClass(
//       IntSet objectIds, {
//         required Uri libraryUri,
//         required String name,
//       }) {
//     return filter(reachableObjects, (object) {
//       return object.klass.libraryUri == libraryUri && object.klass.name == name;
//     });
//   }
// }
