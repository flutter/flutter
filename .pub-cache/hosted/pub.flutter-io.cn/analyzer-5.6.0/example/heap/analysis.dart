// // Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
//
// import 'dart:typed_data';
//
// import 'package:vm_service/vm_service.dart';
//
// import 'format.dart';
// import 'intset.dart';
// export 'intset.dart';
//
// const int _invalidIdx = 0;
// const int _rootObjectIdx = 1;
//
// class Analysis {
//   final HeapSnapshotGraph graph;
//
//   late final reachableObjects = transitiveGraph(roots);
//
//   late final Uint32List _retainers = _calculateRetainers();
//
//   late final _oneByteStringCid = _findClassId('_OneByteString');
//   late final _twoByteStringCid = _findClassId('_TwoByteString');
//   late final _nonGrowableListCid = _findClassId('_List');
//   late final _immutableListCid = _findClassId('_ImmutableList');
//   late final _weakPropertyCid = _findClassId('_WeakProperty');
//   late final _weakReferenceCid = _findClassId('_WeakReference');
//   late final _patchClassCid = _findClassId('PatchClass');
//   late final _finalizerEntryCid = _findClassId('FinalizerEntry');
//
//   late final _weakPropertyKeyIdx = _findFieldIndex(_weakPropertyCid, 'key_');
//   late final _weakPropertyValueIdx =
//       _findFieldIndex(_weakPropertyCid, 'value_');
//
//   late final _finalizerEntryDetachIdx =
//       _findFieldIndex(_finalizerEntryCid, 'detach_');
//   late final _finalizerEntryValueIdx =
//       _findFieldIndex(_finalizerEntryCid, 'value_');
//
//   late final _Arch _arch = (() {
//     // We want to figure out the architecture this heapsnapshot was made from
//     // without it being directly included in the snapshot.
//     // In order to distinguish 32-bit/64-bit/64-bit-compressed we need
//     //   - an object whose shallowSize will be different for all 3 architectures
//     //   - have an actual object in the heap snapshot
//     // -> PatchClass seems to satisfy this.
//     final size = graph.objects
//         .firstWhere(
//             (obj) => obj.classId == _patchClassCid && obj.shallowSize != 0)
//         .shallowSize;
//
//     switch (size) {
//       case 24:
//         return _Arch.arch32;
//       case 32:
//         return _Arch.arch64c;
//       case 48:
//         return _Arch.arch64;
//       default:
//         throw 'Unexpected size of patch class: $size.';
//     }
//   })();
//
//   late final int _headerSize = _arch != _Arch.arch32 ? 8 : 4;
//   late final int _wordSize = _arch == _Arch.arch64 ? 8 : 4;
//
//   Analysis(this.graph);
//
//   /// The roots from which alive data can be discovered.
//   final IntSet roots = IntSet()..add(_rootObjectIdx);
//
//   /// Calculates retaining paths for all objects in [objs].
//   ///
//   /// All retaining paths will have the object itself plus at most [depth]
//   /// retainers in it.
//   List<DedupedUint32List> retainingPathsOf(IntSet objs, int depth) {
//     final paths = <DedupedUint32List, int>{};
//     for (var oId in objs) {
//       final rpath = _retainingPathOf(oId, depth);
//       final old = paths[rpath];
//       paths[rpath] = (old == null) ? 1 : old + 1;
//     }
//     paths.forEach((path, count) {
//       path.count = count;
//     });
//     return paths.keys.toList()..sort((a, b) => paths[b]! - paths[a]!);
//   }
//
//   /// Returns information about a specific object.
//   ObjectInformation examine(int oId) {
//     String stringifyValue(int valueId) {
//       if (valueId == _invalidIdx) return 'int/double/simd';
//
//       final object = graph.objects[valueId];
//       final cid = object.classId;
//       if (cid == _oneByteStringCid || cid == _twoByteStringCid) {
//         return '"${truncateString(object.data as String)}"';
//       }
//
//       final valueClass = graph.classes[cid];
//       return '${valueClass.name}@${valueId} (${valueClass.libraryUri})';
//     }
//
//     final object = graph.objects[oId];
//     final cid = object.classId;
//     final klass = graph.classes[cid];
//     final fs = klass.fields.toList()..sort((a, b) => a.index - b.index);
//     final fieldValues = <String, String>{};
//     if (cid == _oneByteStringCid || cid == _twoByteStringCid) {
//       fieldValues['data'] = stringifyValue(oId);
//     } else {
//       int maxFieldIndex = -1;
//       for (final field in fs) {
//         final valueId = object.references[field.index];
//         fieldValues[field.name] = stringifyValue(valueId);
//         if (field.index > maxFieldIndex) {
//           maxFieldIndex = field.index;
//         }
//       }
//
//       if (cid == _immutableListCid || cid == _nonGrowableListCid) {
//         final refs = object.references;
//         int len = refs.length - (maxFieldIndex + 1);
//         if (len < 10) {
//           for (int i = 0; i < len; ++i) {
//             fieldValues['[$i]'] = stringifyValue(refs[1 + maxFieldIndex + i]);
//           }
//         } else {
//           for (int i = 0; i < 4; ++i) {
//             fieldValues['[$i]'] = stringifyValue(refs[1 + maxFieldIndex + i]);
//           }
//           fieldValues['[...]'] = '';
//           for (int i = len - 4; i < len; ++i) {
//             fieldValues['[$i]'] = stringifyValue(refs[1 + maxFieldIndex + i]);
//           }
//         }
//       }
//     }
//     return ObjectInformation(
//         klass.name, klass.libraryUri.toString(), fieldValues);
//   }
//
//   /// Returns information about a specific object.
//   ObjectInformation examine2(
//     int oId, {
//     int maxLevel = 0,
//     int level = 0,
//   }) {
//     Object stringifyValue(int valueId) {
//       if (valueId == _invalidIdx) {
//         return 'int/double/simd';
//       }
//
//       if (level < maxLevel) {
//         return examine2(valueId, maxLevel: maxLevel, level: level + 1);
//       }
//
//       final object = graph.objects[valueId];
//       final cid = object.classId;
//       if (cid == _oneByteStringCid || cid == _twoByteStringCid) {
//         return '"${truncateString(object.data as String)}"';
//       }
//
//       final valueClass = graph.classes[cid];
//       return '${valueClass.name}@${valueId} (${valueClass.libraryUri})';
//     }
//
//     final object = graph.objects[oId];
//     final cid = object.classId;
//     final klass = graph.classes[cid];
//     final fs = klass.fields.toList()..sort((a, b) => a.index - b.index);
//     final fieldValues = <String, Object>{};
//     if (cid == _oneByteStringCid || cid == _twoByteStringCid) {
//       fieldValues['data'] = stringifyValue(oId);
//     } else {
//       int maxFieldIndex = -1;
//       for (final field in fs) {
//         final valueId = object.references[field.index];
//         fieldValues[field.name] = stringifyValue(valueId);
//         if (field.index > maxFieldIndex) {
//           maxFieldIndex = field.index;
//         }
//       }
//
//       if (cid == _immutableListCid || cid == _nonGrowableListCid) {
//         final refs = object.references;
//         int len = refs.length - (maxFieldIndex + 1);
//         if (len < 10) {
//           for (int i = 0; i < len; ++i) {
//             fieldValues['[$i]'] = stringifyValue(refs[1 + maxFieldIndex + i]);
//           }
//         } else {
//           for (int i = 0; i < 4; ++i) {
//             fieldValues['[$i]'] = stringifyValue(refs[1 + maxFieldIndex + i]);
//           }
//           fieldValues['[...]'] = '';
//           for (int i = len - 4; i < len; ++i) {
//             fieldValues['[$i]'] = stringifyValue(refs[1 + maxFieldIndex + i]);
//           }
//         }
//       }
//     }
//     return ObjectInformation(
//         klass.name, klass.libraryUri.toString(), fieldValues);
//   }
//
//   /// Generates statistics about the given set of [objects].
//   ///
//   /// The classes are sored by sum of shallow-size of objects of a class if
//   /// [sortBySize] is true and by number of objects per-class otherwise.
//   HeapStats generateObjectStats(IntSet objects, {bool sortBySize = true}) {
//     final graphObjects = graph.objects;
//     final numCids = graph.classes.length;
//
//     final counts = Int32List(numCids);
//     final sizes = Int32List(numCids);
//     for (final objectId in objects) {
//       final obj = graphObjects[objectId];
//       final cid = obj.classId;
//       counts[cid]++;
//       sizes[cid] += obj.shallowSize;
//     }
//
//     final classes = graph.classes.where((c) => counts[c.classId] > 0).toList();
//     if (sortBySize) {
//       classes.sort((a, b) {
//         var diff = sizes[b.classId] - sizes[a.classId];
//         if (diff != 0) return diff;
//         diff = counts[b.classId] - counts[a.classId];
//         if (diff != 0) return diff;
//         return graph.classes[b.classId].name
//             .compareTo(graph.classes[a.classId].name);
//       });
//     } else {
//       classes.sort((a, b) {
//         var diff = counts[b.classId] - counts[a.classId];
//         if (diff != 0) return diff;
//         diff = sizes[b.classId] - sizes[a.classId];
//         if (diff != 0) return diff;
//         return graph.classes[b.classId].name
//             .compareTo(graph.classes[a.classId].name);
//       });
//     }
//
//     return HeapStats(classes, sizes, counts);
//   }
//
//   /// Generate statistics about the variable-length data of [objects].
//   ///
//   /// The returned [HeapData]s are sorted by cumulative size if
//   /// [sortBySize] is true and by number of objects otherwise.
//   HeapDataStats generateDataStats(IntSet objects, {bool sortBySize = true}) {
//     final graphObjects = graph.objects;
//     final klasses = graph.classes;
//     final counts = <HeapData, int>{};
//     for (final objectId in objects) {
//       final obj = graphObjects[objectId];
//       final klass = klasses[obj.classId].name;
//       // Should use length here instead!
//       final len = variableLengthOf(obj);
//       if (len == -1) continue;
//       final data = HeapData(klass, obj.data, obj.shallowSize, len);
//       counts[data] = (counts[data] ?? 0) + 1;
//     }
//     counts.forEach((HeapData data, int count) {
//       data.count = count;
//     });
//
//     final datas = counts.keys.toList();
//     if (sortBySize) {
//       datas.sort((a, b) => b.totalSize - a.totalSize);
//     } else {
//       datas.sort((a, b) => b.count - a.count);
//     }
//
//     return HeapDataStats(datas);
//   }
//
//   /// Calculates the set of objects transitively reachable by [roots].
//   IntSet transitiveGraph(IntSet roots, [TraverseFilter? tfilter = null]) {
//     final reachable = IntSet();
//     final worklist = <int>[];
//
//     final objects = graph.objects;
//
//     reachable.addAll(roots);
//     worklist.addAll(roots);
//
//     final weakProperties = IntSet();
//
//     while (worklist.isNotEmpty) {
//       while (worklist.isNotEmpty) {
//         final objectIdToExpand = worklist.removeLast();
//         final objectToExpand = objects[objectIdToExpand];
//         final cid = objectToExpand.classId;
//
//         // Weak references don't keep their value alive.
//         if (cid == _weakReferenceCid) continue;
//
//         // Weak properties keep their value alive if the key is alive.
//         if (cid == _weakPropertyCid) {
//           if (tfilter == null ||
//               tfilter._shouldTraverseEdge(
//                   _weakPropertyCid, _weakPropertyValueIdx)) {
//             weakProperties.add(objectIdToExpand);
//           }
//           continue;
//         }
//
//         // Normal object (or FinalizerEntry).
//         final references = objectToExpand.references;
//         final bool isFinalizerEntry = cid == _finalizerEntryCid;
//         for (int i = 0; i < references.length; ++i) {
//           // [FinalizerEntry] objects don't keep their "detach" and "value"
//           // fields alive.
//           if (isFinalizerEntry &&
//               (i == _finalizerEntryDetachIdx || i == _finalizerEntryValueIdx)) {
//             continue;
//           }
//
//           final successor = references[i];
//           if (!reachable.contains(successor)) {
//             if (tfilter == null ||
//                 (tfilter._shouldTraverseEdge(objectToExpand.classId, i) &&
//                     tfilter._shouldIncludeObject(objects[successor].classId))) {
//               reachable.add(successor);
//               worklist.add(successor);
//             }
//           }
//         }
//       }
//
//       // Enqueue values of weak properties if their key is alive.
//       weakProperties.removeWhere((int weakProperty) {
//         final wpReferences = objects[weakProperty].references;
//         final keyId = wpReferences[_weakPropertyKeyIdx];
//         final valueId = wpReferences[_weakPropertyValueIdx];
//         if (reachable.contains(keyId)) {
//           if (!reachable.contains(valueId)) {
//             if (tfilter == null ||
//                 tfilter._shouldIncludeObject(objects[valueId].classId)) {
//               reachable.add(valueId);
//               worklist.add(valueId);
//             }
//           }
//           return true;
//         }
//         return false;
//       });
//     }
//     return reachable;
//   }
//
//   /// Calculates the set of objects that transitively can reach [oids].
//   IntSet reverseTransitiveGraph(IntSet oids, [TraverseFilter? tfilter = null]) {
//     final reachable = IntSet();
//     final worklist = <int>[];
//
//     final objects = graph.objects;
//
//     reachable.addAll(oids);
//     worklist.addAll(oids);
//
//     while (worklist.isNotEmpty) {
//       final objectIdToExpand = worklist.removeLast();
//       final objectToExpand = objects[objectIdToExpand];
//       final referrers = objectToExpand.referrers;
//       for (int i = 0; i < referrers.length; ++i) {
//         final predecessorId = referrers[i];
//         // This is a dead object in heap that refers to a live object.
//         if (!reachableObjects.contains(predecessorId)) continue;
//         if (!reachable.contains(predecessorId)) {
//           final predecessor = objects[predecessorId];
//           final cid = predecessor.classId;
//
//           // A WeakReference does not keep its object alive.
//           if (cid == _weakReferenceCid) continue;
//
//           // A WeakProperty does not keep its key alive, but may keep it's value
//           // alive.
//           if (cid == _weakPropertyCid) {
//             final refs = predecessor.references;
//             bool hasRealRef = false;
//             for (int i = 0; i < refs.length; ++i) {
//               if (i == _weakPropertyKeyIdx) continue;
//               if (refs[i] == objectIdToExpand) hasRealRef = true;
//             }
//             if (!hasRealRef) continue;
//           }
//
//           // A FinalizerEntry] does not keep its {detach_,value_} fields alive.
//           if (cid == _finalizerEntryCid) {
//             final refs = predecessor.references;
//             bool hasRealRef = false;
//             for (int i = 0; i < refs.length; ++i) {
//               if (i == _finalizerEntryDetachIdx) continue;
//               if (i == _finalizerEntryValueIdx) continue;
//               if (refs[i] == objectIdToExpand) hasRealRef = true;
//             }
//             if (!hasRealRef) continue;
//           }
//
//           bool passedFilter = true;
//           if (tfilter != null) {
//             final index = predecessor.references.indexOf(objectIdToExpand);
//             passedFilter =
//                 (tfilter._shouldTraverseEdge(predecessor.classId, index) &&
//                     tfilter._shouldIncludeObject(predecessor.classId));
//           }
//           if (passedFilter) {
//             reachable.add(predecessorId);
//             worklist.add(predecessorId);
//           }
//         }
//       }
//     }
//     return reachable;
//   }
//
//   // Only keep those in [toFilter] that have references from [from].
//   IntSet filterObjectsReferencedBy(IntSet toFilter, IntSet from) {
//     final result = IntSet();
//     final objects = graph.objects;
//
//     for (final fromId in from) {
//       final from = objects[fromId];
//       for (final refId in from.references) {
//         if (toFilter.contains(refId)) {
//           result.add(refId);
//           break;
//         }
//       }
//     }
//
//     return result;
//   }
//
//   /// Returns set of cids that are matching the provided [patterns].
//   IntSet findClassIdsMatching(Iterable<String> patterns) {
//     final regexPatterns = patterns.map((p) => RegExp(p)).toList();
//
//     final classes = graph.classes;
//     final cids = IntSet();
//     for (final klass in classes) {
//       if (regexPatterns.any((pattern) =>
//           pattern.hasMatch(klass.name) ||
//           pattern.hasMatch(klass.libraryUri.toString()))) {
//         cids.add(klass.classId);
//       }
//     }
//     return cids;
//   }
//
//   /// Create filters that can be used in traversing object graphs.
//   TraverseFilter? parseTraverseFilter(List<String> patterns) {
//     if (patterns.isEmpty) return null;
//
//     final aset = IntSet();
//     final naset = IntSet();
//
//     int bits = 0;
//
//     final fmap = <int, IntSet>{};
//     final nfmap = <int, IntSet>{};
//     for (String pattern in patterns) {
//       final bool isNegated = pattern.startsWith('^');
//       if (isNegated) {
//         pattern = pattern.substring(1);
//       }
//
//       // Edge filter.
//       final int sep = pattern.indexOf(':');
//       if (sep != -1 && sep != (pattern.length - 1)) {
//         final klassPattern = pattern.substring(0, sep);
//
//         final fieldNamePattern = pattern.substring(sep + 1);
//         final cids = findClassIdsMatching([klassPattern]);
//
//         final fieldNameRegexp = RegExp(fieldNamePattern);
//         for (final cid in cids) {
//           final klass = graph.classes[cid];
//           for (final field in klass.fields) {
//             if (fieldNameRegexp.hasMatch(field.name)) {
//               (isNegated ? nfmap : fmap)
//                   .putIfAbsent(cid, IntSet.new)
//                   .add(field.index);
//             }
//           }
//         }
//
//         if (!isNegated) {
//           bits |= TraverseFilter._hasPositiveEdgePatternBit;
//         }
//
//         continue;
//       }
//
//       // Class filter.
//       final cids = findClassIdsMatching([pattern]);
//       (isNegated ? naset : aset).addAll(cids);
//
//       if (!isNegated) {
//         bits |= TraverseFilter._hasPositiveClassPatternBit;
//       }
//     }
//     return TraverseFilter._(patterns, bits, aset, naset, fmap, nfmap);
//   }
//
//   /// Returns set of objects from [objectIds] whose class id is in [cids].
//   IntSet filterByClassId(IntSet objectIds, IntSet cids) {
//     return filter(objectIds, (object) => cids.contains(object.classId));
//   }
//
//   /// Returns set of objects from [objectIds] whose class id is in [cids].
//   IntSet filterByClassPatterns(IntSet objectIds, List<String> patterns) {
//     final tfilter = parseTraverseFilter(patterns);
//     if (tfilter == null) return objectIds;
//     return filter(objectIds, tfilter._shouldFilterObject);
//   }
//
//   /// Returns set of objects from [objectIds] whose class id is in [cids].
//   IntSet filter(IntSet objectIds, bool Function(HeapSnapshotObject) filter) {
//     final result = IntSet();
//     final objects = graph.objects;
//     objectIds.forEach((int objId) {
//       if (filter(objects[objId])) {
//         result.add(objId);
//       }
//     });
//     return result;
//   }
//
//   /// Returns users of [objs].
//   IntSet findUsers(IntSet objs, List<String> patterns) {
//     final tfilter = parseTraverseFilter(patterns);
//
//     final objects = graph.objects;
//     final result = IntSet();
//     for (final objId in objs) {
//       final object = objects[objId];
//       final referrers = object.referrers;
//       for (int i = 0; i < referrers.length; ++i) {
//         final userId = referrers[i];
//         // This is a dead object in heap that refers to a live object.
//         if (!reachableObjects.contains(userId)) continue;
//         bool passedFilter = true;
//         if (tfilter != null) {
//           final user = objects[userId];
//           final idx = user.references.indexOf(objId);
//           passedFilter = tfilter._shouldTraverseEdge(user.classId, idx) &&
//               tfilter._shouldIncludeObject(user.classId);
//         }
//         if (passedFilter) {
//           result.add(userId);
//         }
//       }
//     }
//     return result;
//   }
//
//   /// Returns references of [objs].
//   IntSet findReferences(IntSet objs, List<String> patterns) {
//     final tfilter = parseTraverseFilter(patterns);
//
//     final objects = graph.objects;
//     final result = IntSet();
//     for (final objId in objs) {
//       final object = objects[objId];
//       final references = object.references;
//       for (int i = 0; i < references.length; ++i) {
//         final refId = references[i];
//         bool passedFilter = true;
//         if (tfilter != null) {
//           final other = objects[refId];
//           passedFilter = tfilter._shouldTraverseEdge(object.classId, i) &&
//               tfilter._shouldIncludeObject(other.classId);
//         }
//         if (passedFilter) {
//           var refObj = graph.objects[refId];
//           if (graph.classes[refObj.classId].name == 'FileState') {
//             // graph.classes[graph.objects[graph.objects[object.referrers.toList()[0]].referrers[0]].classId]
//             // print('aaaaaa');
//           }
//           result.add(refId);
//         }
//       }
//     }
//     return result;
//   }
//
//   /// Returns the size of the variable part of [object]
//   ///
//   /// For strings this is the length of the string (or approximation thereof).
//   /// For typed data this is the number of elements.
//   /// For fixed-length arrays this is the length of the array.
//   int variableLengthOf(HeapSnapshotObject object) {
//     final cid = object.classId;
//
//     final isList = cid == _nonGrowableListCid || cid == _immutableListCid;
//     if (isList) {
//       // Return the length of the non-growable array.
//       final numFields = graph.classes[cid].fields.length;
//       return object.references.length - numFields;
//     }
//
//     final isString = cid == _oneByteStringCid || cid == _twoByteStringCid;
//     if (isString) {
//       // Return the length of the string.
//       //
//       // - For lengths <128 the length of string is precise
//       // - For larger strings, the data is truncated, so we use the payload
//       //   size.
//       // - TODO: The *heapsnapshot format contains actual length but it gets
//       //   lost after reading. Can we preserve it somewhere on
//       //   `HeapSnapshotGraph`?
//       //
//       // The approximation is based on knowning the header size of a string:
//       // - String has: header, length (hash - on 32-bit platforms) + payload
//       final fixedSize =
//           _headerSize + _wordSize * (_arch == _Arch.arch32 ? 2 : 1);
//       final len =
//           object.shallowSize == 0 ? 0 : (object.shallowSize - fixedSize);
//       if (len < 128) return (object.data as String).length;
//       return len; // Over-approximates to 2 * wordsize.
//     }
//
//     final data = object.data;
//     if (data is HeapSnapshotObjectLengthData) {
//       // Most likely typed data object, return length in elements.
//       return data.length;
//     }
//
//     final fixedSize = _headerSize + _wordSize * object.references.length;
//     final dataSize = object.shallowSize - fixedSize;
//     if (dataSize > _wordSize) {
//       final klass = graph.classes[cid];
//       // User-visible, but VM-recognized objects with variable size.
//       if (!['_RegExp', '_SuspendState'].contains(klass.name)) {
//         // Non-user-visible, VM-recognized objects (empty library uri).
//         final uri = klass.libraryUri.toString().trim();
//         if (uri != '') {
//           throw 'Object has fixed size: $fixedSize and total '
//               'size: ${object.shallowSize} but is not known to '
//               'be variable-length (class: ${graph.classes[cid].name})';
//         }
//       }
//     }
//
//     return -1;
//   }
//
//   int _findClassId(String className) {
//     return graph.classes
//         .singleWhere((klass) =>
//             klass.name == className &&
//             (klass.libraryUri.scheme == 'dart' ||
//                 klass.libraryUri.toString() == ''))
//         .classId;
//   }
//
//   int _findFieldIndex(int cid, String fieldName) {
//     return graph.classes[cid].fields
//         .singleWhere((f) => f.name == fieldName)
//         .index;
//   }
//
//   DedupedUint32List _retainingPathOf(int oId, int depth) {
//     final objects = graph.objects;
//     final classes = graph.classes;
//
//     @pragma('vm:prefer-inline')
//     int getFieldIndex(int oId, int childId) {
//       final object = objects[oId];
//       final fields = classes[object.classId].fields;
//       final idx = object.references.indexOf(childId);
//       if (idx == -1) throw 'should not happen';
//
//       int fieldIndex = fields.any((f) => f.index == idx)
//           ? idx
//           : DedupedUint32List.noFieldIndex;
//       return fieldIndex;
//     }
//
//     @pragma('vm:prefer-inline')
//     int retainingPathLength(int id) {
//       int length = 1;
//       int id = oId;
//       while (id != _rootObjectIdx && length <= depth) {
//         id = _retainers[id];
//         length++;
//       }
//       return length;
//     }
//
//     @pragma('vm:prefer-inline')
//     bool hasMoreThanOneAlive(IntSet reachableObjects, Uint32List list) {
//       int count = 0;
//       for (int i = 0; i < list.length; ++i) {
//         if (reachableObjects.contains(list[i])) {
//           count++;
//           if (count >= 2) return true;
//         }
//       }
//       return false;
//     }
//
//     int lastId = oId;
//     var lastObject = objects[lastId];
//
//     final path = Uint32List(2 * retainingPathLength(oId) - 1);
//     path[0] = lastObject.classId;
//     for (int i = 1; i < path.length; i += 2) {
//       assert(lastId != _rootObjectIdx && ((i - 1) ~/ 2) < depth);
//       final users = lastObject.referrers;
//       final int userId = _retainers[lastId];
//
//       final user = objects[userId];
//       int fieldIndex = getFieldIndex(userId, lastId);
//       final lastWasUniqueRef = !hasMoreThanOneAlive(reachableObjects, users);
//
//       path[i] = (lastWasUniqueRef ? 1 : 0) << 0 | fieldIndex << 1;
//       path[i + 1] = user.classId;
//
//       lastId = userId;
//       lastObject = user;
//     }
//     return DedupedUint32List(path);
//   }
//
//   Uint32List _calculateRetainers() {
//     final retainers = Uint32List(graph.objects.length);
//
//     var worklist = IntSet()..add(_rootObjectIdx);
//     while (!worklist.isEmpty) {
//       final next = IntSet();
//
//       for (final objId in worklist) {
//         final object = graph.objects[objId];
//         final cid = object.classId;
//
//         // Weak references don't keep their value alive.
//         if (cid == _weakReferenceCid) continue;
//
//         // Weak properties keep their value alive if the key is alive.
//         if (cid == _weakPropertyCid) {
//           final valueId = object.references[_weakPropertyValueIdx];
//           if (reachableObjects.contains(valueId)) {
//             if (retainers[valueId] == 0) {
//               retainers[valueId] = objId;
//               next.add(valueId);
//             }
//           }
//           continue;
//         }
//
//         // Normal object (or FinalizerEntry).
//         final references = object.references;
//         final bool isFinalizerEntry = cid == _finalizerEntryCid;
//         for (int i = 0; i < references.length; ++i) {
//           // [FinalizerEntry] objects don't keep their "detach" and "value"
//           // fields alive.
//           if (isFinalizerEntry &&
//               (i == _finalizerEntryDetachIdx || i == _finalizerEntryValueIdx)) {
//             continue;
//           }
//
//           final refId = references[i];
//           if (retainers[refId] == 0) {
//             retainers[refId] = objId;
//             next.add(refId);
//           }
//         }
//       }
//       worklist = next;
//     }
//     return retainers;
//   }
// }
//
// class TraverseFilter {
//   static const int _hasPositiveClassPatternBit = (1 << 0);
//   static const int _hasPositiveEdgePatternBit = (1 << 1);
//
//   final List<String> _patterns;
//
//   final int _bits;
//
//   final IntSet? _allowed;
//   final IntSet? _disallowed;
//
//   final Map<int, IntSet>? _followMap;
//   final Map<int, IntSet>? _notFollowMap;
//
//   const TraverseFilter._(this._patterns, this._bits, this._allowed,
//       this._disallowed, this._followMap, this._notFollowMap);
//
//   bool get _hasPositiveClassPattern =>
//       (_bits & _hasPositiveClassPatternBit) != 0;
//   bool get _hasPositiveEdgePattern => (_bits & _hasPositiveEdgePatternBit) != 0;
//
//   String asString(HeapSnapshotGraph graph) {
//     final sb = StringBuffer();
//     sb.writeln(
//         'The traverse filter expression "${_patterns.join(' ')}" matches:\n');
//
//     final ca = _allowed ?? IntSet();
//     final cna = _disallowed ?? IntSet();
//
//     final klasses = graph.classes.toList()
//       ..sort((a, b) => a.name.compareTo(b.name));
//
//     for (final klass in klasses) {
//       final cid = klass.classId;
//
//       final posEdge = [];
//       final negEdge = [];
//
//       final f = _followMap?[cid] ?? IntSet();
//       final nf = _notFollowMap?[cid] ?? IntSet();
//       for (final field in klass.fields) {
//         final fieldIndex = field.index;
//         if (f.contains(fieldIndex)) {
//           posEdge.add(field.name);
//         }
//         if (nf.contains(fieldIndex)) {
//           negEdge.add(field.name);
//         }
//       }
//
//       bool printedClass = false;
//       final name = klass.name;
//       if (ca.contains(cid)) {
//         sb.writeln('[+] $name');
//         printedClass = true;
//       }
//       if (cna.contains(cid)) {
//         sb.writeln('[-] $name');
//         printedClass = true;
//       }
//       if (posEdge.isNotEmpty || negEdge.isNotEmpty) {
//         if (!printedClass) {
//           sb.writeln('[ ] $name');
//           printedClass = true;
//         }
//         for (final field in posEdge) {
//           sb.writeln('[+]   .$field');
//         }
//         for (final field in negEdge) {
//           sb.writeln('[-]   .$field');
//         }
//       }
//     }
//     return sb.toString().trim();
//   }
//
//   // Should include the edge when building transitive graphs.
//   bool _shouldTraverseEdge(int cid, int fieldIndex) {
//     final nf = _notFollowMap?[cid];
//     if (nf != null && nf.contains(fieldIndex)) return false;
//
//     final f = _followMap?[cid];
//     if (f != null && f.contains(fieldIndex)) return true;
//
//     // If there's an allow list we only allow allowed ones, otherwise we allow
//     // all.
//     return !_hasPositiveEdgePattern;
//   }
//
//   // Should include the object when building transitive graphs.
//   bool _shouldIncludeObject(int cid) {
//     if (_disallowed?.contains(cid) == true) return false;
//     if (_allowed?.contains(cid) == true) return true;
//
//     // If there's an allow list we only allow allowed ones, otherwise we allow
//     // all.
//     return !_hasPositiveClassPattern;
//   }
//
//   // Should include the object when filtering a set of objects.
//   bool _shouldFilterObject(HeapSnapshotObject object) {
//     final cid = object.classId;
//     final numReferences = object.references.length;
//     return __shouldFilterObject(cid, numReferences);
//   }
//
//   bool __shouldFilterObject(int cid, int numReferences) {
//     if (!_shouldIncludeObject(cid)) return false;
//
//     // Check if the object has an explicitly disallowed field.
//     final nf = _notFollowMap?[cid];
//     if (nf != null) {
//       for (int fieldIndex = 0; fieldIndex < numReferences; ++fieldIndex) {
//         if (nf.contains(fieldIndex)) return false;
//       }
//     }
//
//     // Check if the object has an explicitly allowed field.
//     final f = _followMap?[cid];
//     if (f != null) {
//       for (int fieldIndex = 0; fieldIndex < numReferences; ++fieldIndex) {
//         if (f.contains(fieldIndex)) return true;
//       }
//     }
//
//     // If there's an allow list we only allow allowed ones, otherwise we allow
//     // all.
//     return !_hasPositiveEdgePattern;
//   }
// }
//
// /// Stringified representation of a heap object.
// class ObjectInformation {
//   final String className;
//   final String libraryUri;
//   final Map<String, Object> fieldValues;
//
//   ObjectInformation(this.className, this.libraryUri, this.fieldValues);
// }
//
// /// Heap usage statistics calculated for a set of heap objects.
// class HeapStats {
//   final List<HeapSnapshotClass> classes;
//   final Int32List sizes;
//   final Int32List counts;
//
//   HeapStats(this.classes, this.sizes, this.counts);
//
//   int get totalSize => sizes.fold(0, (int a, int b) => a + b);
//   int get totalCount => counts.fold(0, (int a, int b) => a + b);
// }
//
// /// Heap object data statistics calculated for a set of heap objects.
// class HeapDataStats {
//   final List<HeapData> datas;
//
//   HeapDataStats(this.datas);
//
//   int get totalSizeUniqueDatas =>
//       datas.fold(0, (int sum, HeapData d) => sum + d.size);
//   int get totalSize =>
//       datas.fold(0, (int sum, HeapData d) => sum + d.totalSize);
//   int get totalCount => datas.fold(0, (int sum, HeapData d) => sum + d.count);
// }
//
// /// Representing the data of one heap object.
// ///
// /// Since the data can be truncated, it has an extra size that allows to
// /// distinguish datas with same truncated value with high probability.
// class HeapData {
//   final String klass;
//   final dynamic value;
//   final int size;
//   final int len;
//
//   late final int count;
//
//   HeapData(this.klass, this.value, this.size, this.len);
//
//   int? _hashCode;
//   int get hashCode {
//     if (_hashCode != null) return _hashCode!;
//
//     var valueToHash = value;
//     if (valueToHash is! String &&
//         valueToHash is! bool &&
//         valueToHash is! double) {
//       if (valueToHash is HeapSnapshotObjectLengthData) {
//         valueToHash = valueToHash.length;
//       } else if (valueToHash is HeapSnapshotObjectNoData) {
//         valueToHash = 0;
//       } else if (valueToHash is HeapSnapshotObjectNullData) {
//         valueToHash = 0;
//       } else {
//         throw '${valueToHash.runtimeType}';
//       }
//     }
//
//     return _hashCode = Object.hash(klass, valueToHash, size, len);
//   }
//
//   bool operator ==(other) {
//     if (identical(this, other)) return true;
//     if (other is! HeapData) return false;
//     if (size != other.size) return false;
//     if (len != other.len) return false;
//     if (klass != other.klass) return false;
//
//     final ovalue = other.value;
//     if (value is String || value is bool || value is double) {
//       return value == ovalue;
//     }
//     // We don't have the typed data content, so we don't know whether they are
//     // equal / dedupable.
//     return false;
//   }
//
//   String get valueAsString {
//     var d = value;
//     if (d is String) {
//       final newLine = d.indexOf('\n');
//       if (newLine >= 0) {
//         d = d.substring(0, newLine);
//       }
//       if (d.length > 80) {
//         d = d.substring(0, 80);
//       }
//       return d;
//     }
//     return 'len:$len';
//   }
//
//   int get totalSize => size * count;
// }
//
// /// Used to represent retaining paths.
// ///
// /// For retaining paths: `[cid0, fieldIdx1 << 1 | isUniqueOwner, cid1, ...]`
// class DedupedUint32List {
//   static const int noFieldIndex = (1 << 29);
//
//   final Uint32List path;
//   late final int count;
//
//   DedupedUint32List(this.path);
//
//   int? _hashCode;
//   int get hashCode => _hashCode ??= Object.hashAll(path);
//
//   bool operator ==(other) {
//     if (identical(this, other)) return true;
//     if (other is! DedupedUint32List) return false;
//     if (path.length != other.path.length) return false;
//     for (int i = 0; i < path.length; ++i) {
//       if (path[i] != other.path[i]) return false;
//     }
//     return true;
//   }
// }
//
// enum _Arch {
//   arch32,
//   arch64,
//   arch64c,
// }
