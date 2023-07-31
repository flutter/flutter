// import 'dart:io' as io;
// import 'dart:isolate';
//
// import 'package:vm_service/vm_service.dart';
//
// import 'heap/analysis.dart';
// import 'heap/format.dart';
//
// void main() async {
//   const tmpPath = '/Users/scheglov/tmp';
//   // const fileName = '20230203/cm_inf_11.heap_snapshot';
//   // const fileName = '20230203/cm_100_11.heap_snapshot';
//   const fileName = '20230203/b267486151_2_1.heap_snapshot';
//   final path = '$tmpPath/cider-heap/$fileName';
//
//   final bytes = io.File(path).readAsBytesSync();
//   final graph = HeapSnapshotGraph.fromChunks([bytes.buffer.asByteData()]);
//
//   print('Graph');
//   print('  capacity: ${formatBytes(graph.capacity)}');
//   print('  shallowSize: ${formatBytes(graph.shallowSize)}');
//   print('  externalSize: ${formatBytes(graph.externalSize)}');
//   print('');
//
//   final analysis = Analysis(graph);
//
//   {
//     print('All objects: with garbage');
//     final objects = graph.objects.map((e) => e.oid).toSet();
//     final stats = analysis.generateObjectStats(objects);
//     print(formatHeapStats(stats, maxLines: 20));
//     print('');
//   }
//
//   {
//     print('All objects: live');
//     final objects = analysis.reachableObjects;
//     final stats = analysis.generateObjectStats(objects);
//     print(formatHeapStats(stats, maxLines: 20));
//     print('');
//   }
//
//   if (1 == 1) {
//     print('_Uint8List(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == '_Uint8List';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     // final allObjects = analysis.transitiveGraph(libraryElements);
//     // analysis.printObjectStats(allObjects);
//     // print('');
//     // analysis.printRetainers(libraryElements, maxEntries: 3);
//     // print('');
//   }
//
//   if (1 == 0) {
//     print('_StringCanonicalizer(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == '_StringCanonicalizer';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     final allObjects = analysis.transitiveGraph(libraryElements);
//     analysis.printObjectStats(allObjects);
//     print('');
//     // analysis.printRetainers(libraryElements, maxEntries: 3);
//     // print('');
//   }
//
//   if (1 == 0) {
//     print('View(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == 'View';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     final allObjects = analysis.transitiveGraph(libraryElements);
//     analysis.printObjectStats(allObjects);
//     print('');
//     // analysis.printRetainers(libraryElements, maxEntries: 3);
//     // print('');
//   }
//
//   if (1 == 0) {
//     print('CiderResourceProvider(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == 'CiderResourceProvider';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     final allObjects = analysis.transitiveGraph(libraryElements);
//     analysis.printObjectStats(allObjects);
//     print('');
//     // analysis.printRetainers(libraryElements, maxEntries: 3);
//     // print('');
//   }
//
//   if (1 == 0) {
//     print('_OneByteString(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == '_OneByteString';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     // final allObjects = analysis.transitiveGraph(libraryElements);
//     // analysis.printObjectStats(allObjects);
//     // print('');
//     analysis.printRetainers(libraryElements, maxEntries: 5);
//     print('');
//   }
//
//   if (1 == 0) {
//     print('_SimpleUri(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == '_SimpleUri';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     // final allObjects = analysis.transitiveGraph(libraryElements);
//     // analysis.printObjectStats(allObjects);
//     // print('');
//     analysis.printRetainers(libraryElements, maxEntries: 3);
//     print('');
//   }
//
//   if (1 == 0) {
//     print('_List(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == '_List';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     // final allObjects = analysis.transitiveGraph(libraryElements);
//     // analysis.printObjectStats(allObjects);
//     // print('');
//     analysis.printRetainers(libraryElements, maxEntries: 10);
//     print('');
//   }
//
//   if (1 == 1) {
//     print('LibraryElementImpl(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == 'LibraryElementImpl';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     final allObjects = analysis.transitiveGraph(libraryElements);
//     analysis.printObjectStats(allObjects);
//     print('');
//     analysis.printRetainers(libraryElements, maxEntries: 3);
//     print('');
//   }
//
//   if (1 == 0) {
//     print('FinalizerEntry(s)');
//     var libraryElements = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == 'FinalizerEntry';
//       },
//     );
//     analysis.printObjectStats(libraryElements);
//     print('');
//     final allObjects = analysis.transitiveGraph(libraryElements);
//     analysis.printObjectStats(allObjects);
//     print('');
//     analysis.printRetainers(libraryElements, maxEntries: 3);
//     print('');
//   }
//
//   if (1 == 0) {
//     print('CiderIsolateByteStore(s)');
//     var fileStateList = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == 'CiderIsolateByteStore';
//       },
//     );
//     analysis.printObjectStats(fileStateList);
//     print('');
//     final allObjects = analysis.transitiveGraph(fileStateList);
//     analysis.printObjectStats(allObjects);
//     print('');
//   }
//
//   if (1 == 1) {
//     print('FileState(s)');
//     var fileStateList = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == 'FileState';
//       },
//     );
//     analysis.printObjectStats(fileStateList);
//     print('');
//     final allObjects = analysis.transitiveGraph(fileStateList);
//     analysis.printObjectStats(allObjects);
//     print('');
//     // analysis.printRetainers(fileStateList, maxEntries: 3);
//     // print('');
//     // if (1 == 1) {
//     //   print('FileState(s) :: UnlinkedUnit(s)');
//     //   var libraryElements = analysis.filter(
//     //     allObjects,
//     //     (object) {
//     //       return object.klass.name == 'UnlinkedUnit';
//     //     },
//     //   );
//     //   analysis.printObjectStats(libraryElements);
//     //   print('');
//     //   final allObjects2 = analysis.transitiveGraph(libraryElements);
//     //   analysis.printObjectStats(allObjects2);
//     //   print('');
//     //   // analysis.printRetainers(libraryElements, maxEntries: 5);
//     //   // print('');
//     // }
//     // if (1 == 0) {
//     //   print('FileState(s) :: _Set(s)');
//     //   var setObjects = analysis.filter(
//     //     allObjects,
//     //     (object) {
//     //       return object.klass.name == '_Set';
//     //     },
//     //   );
//     //   analysis.printObjectStats(setObjects);
//     //   print('');
//     //   final allObjects2 = analysis.transitiveGraph(
//     //     setObjects,
//     //     analysis.parseTraverseFilter(['^FileState']),
//     //   );
//     //   analysis.printObjectStats(allObjects2);
//     //   print('');
//     //   // analysis.printRetainers(libraryElements, maxEntries: 5);
//     //   // print('');
//     // }
//   }
//
//   if (1 == 1) {
//     final fileResolverList = analysis.filter(
//       analysis.reachableObjects,
//       (object) {
//         return object.klass.name == 'FileResolver';
//       },
//     );
//     analysis.printObjectStats(fileResolverList);
//
//     for (final fileResolver in fileResolverList) {
//       print('');
//       print('');
//       print('FileResolver $fileResolver');
//       print('');
//
//       var information = analysis.examine2(fileResolver, maxLevel: 8);
//       print(information);
//
//       print('All objects.');
//       final allObjects = analysis.transitiveGraph({fileResolver});
//       analysis.printObjectStats(allObjects);
//       print('');
//
//       if (1 == 0) {
//         print('FileResolver :: LibraryElementImpl(s)');
//         final libraryElements = analysis.filter(
//           allObjects,
//           (o) => o.klass.name == 'LibraryElementImpl',
//         );
//         analysis.printObjectStats(libraryElements);
//         print('');
//
//         analysis.printRetainers(libraryElements);
//       }
//
//       if (1 == 0) {
//         print('FileResolver :: _List(s)');
//         var listList = analysis.filter(
//           allObjects,
//           (object) {
//             return object.klass.name == '_List';
//           },
//         );
//         analysis.printObjectStats(listList);
//         print('');
//         // final allObjects = analysis.transitiveGraph(byteListList);
//         // analysis.printObjectStats(allObjects);
//         // print('');
//         analysis.printRetainers(listList, maxEntries: 3);
//         print('');
//       }
//
//       if (1 == 1) {
//         print('FileResolver :: _Uint8List(s)');
//         var listList = analysis.filter(
//           allObjects,
//           (object) {
//             return object.klass.name == '_Uint8List';
//           },
//         );
//         analysis.printObjectStats(listList);
//         print('');
//         // final allObjects = analysis.transitiveGraph(byteListList);
//         // analysis.printObjectStats(allObjects);
//         // print('');
//         analysis.printRetainers(listList, maxEntries: 3);
//         print('');
//       }
//     }
//   }
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
//     IntSet objectIds, {
//     int maxEntries = 3,
//   }) {
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
//     IntSet objectIds, {
//     required Uri libraryUri,
//     required String name,
//   }) {
//     return filter(reachableObjects, (object) {
//       return object.klass.libraryUri == libraryUri && object.klass.name == name;
//     });
//   }
// }
