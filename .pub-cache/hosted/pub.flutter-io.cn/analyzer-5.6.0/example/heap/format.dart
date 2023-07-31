// // Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// // for details. All rights reserved. Use of this source code is governed by a
// // BSD-style license that can be found in the LICENSE file.
//
// import 'dart:typed_data';
//
// import 'package:vm_service/vm_service.dart';
//
// import 'analysis.dart';
//
// String format(int a) => a.toString().padLeft(6, ' ');
// String formatBytes(int a) => (a ~/ 1024).toString().padLeft(6, ' ') + ' kb';
// String truncateString(String s) {
//   int index;
//
//   index = s.indexOf('\n');
//   if (index >= 0) s = s.substring(index);
//
//   index = s.indexOf('\r');
//   if (index >= 0) s = s.substring(index);
//
//   if (s.length > 30) s = s.substring(30);
//   return s;
// }
//
// String formatHeapStats(HeapStats stats, {int? maxLines, int? sizeCutoff}) {
//   assert(sizeCutoff == null || sizeCutoff >= 0);
//   assert(maxLines == null || maxLines >= 0);
//
//   final table = Table();
//   table.addRow(['size', 'count', 'class']);
//   table.addRow(['--------', '--------', '--------']);
//   int totalSize = 0;
//   int totalCount = 0;
//   for (int i = 0; i < stats.classes.length; ++i) {
//     final c = stats.classes[i];
//     final count = stats.counts[c.classId];
//     final size = stats.sizes[c.classId];
//
//     totalSize += size;
//     totalCount += count;
//
//     if (sizeCutoff == null || size >= sizeCutoff) {
//       if (maxLines == null || i < maxLines) {
//         table.addRow(
//             [formatBytes(size), format(count), '${c.name} ${c.libraryUri}']);
//       }
//     }
//   }
//   if (table.rows > 3) {
//     table.addRow(['--------', '--------']);
//     table.addRow([formatBytes(totalSize), format(totalCount)]);
//   }
//   return table.asString;
// }
//
// String formatDataStats(HeapDataStats stats, {int? maxLines, int? sizeCutoff}) {
//   assert(sizeCutoff == null || sizeCutoff >= 0);
//   assert(maxLines == null || maxLines >= 0);
//
//   final table = Table();
//   table.addRow(['size', 'unique-size', 'count', 'class', 'data']);
//   table.addRow(['--------', '--------', '--------', '--------', '--------']);
//
//   int totalSize = 0;
//   int totalUniqueSize = 0;
//   int totalCount = 0;
//
//   final List<HeapData> datas = stats.datas;
//   for (int i = 0; i < datas.length; ++i) {
//     final data = datas[i];
//
//     totalSize += data.size;
//     totalUniqueSize += data.totalSize;
//     totalCount += data.count;
//
//     if (sizeCutoff == null || data.totalSize >= sizeCutoff) {
//       if (maxLines == null || i < maxLines) {
//         table.addRow([
//           formatBytes(data.totalSize),
//           formatBytes(data.size),
//           format(data.count),
//           data.klass,
//           data.valueAsString,
//         ]);
//       }
//     }
//   }
//   if (table.rows > 3) {
//     table.addRow(['--------', '--------', '--------']);
//     table.addRow([
//       formatBytes(totalUniqueSize),
//       formatBytes(totalSize),
//       format(totalCount)
//     ]);
//   }
//   return table.asString;
// }
//
// String formatRetainingPath(HeapSnapshotGraph graph, DedupedUint32List rpath) {
//   final path = _stringifyRetainingPath(graph, rpath);
//   final bool wasTruncated = rpath.path.last != /*root*/ 1;
//   final sb = StringBuffer();
//   for (int i = 0; i < path.length; ++i) {
//     final indent = i >= 2 ? (i - 1) : 0;
//     sb.writeln(' ' * 4 * indent + (i == 0 ? '' : '⮑ ') + '${path[i]}');
//   }
//   if (wasTruncated) {
//     sb.writeln(' ' * 4 * (path.length - 1) + '⮑  …');
//   }
//   return sb.toString();
// }
//
// String formatDominatorPath(HeapSnapshotGraph graph, DedupedUint32List dpath) {
//   final path = _stringifyDominatorPath(graph, dpath);
//   final bool wasTruncated = dpath.path.last != /*root*/ 1;
//   final sb = StringBuffer();
//   for (int i = 0; i < path.length; ++i) {
//     final indent = i >= 2 ? (i - 1) : 0;
//     sb.writeln(' ' * 4 * indent + (i == 0 ? '' : '⮑  ') + '${path[i]}');
//   }
//   if (wasTruncated) {
//     sb.writeln(' ' * 4 * (path.length - 1) + '⮑  …');
//   }
//   return sb.toString();
// }
//
// List<String> _stringifyRetainingPath(
//     HeapSnapshotGraph graph, DedupedUint32List rpath) {
//   final path = rpath.path;
//   final spath = <String>[];
//   for (int i = 0; i < path.length; i += 2) {
//     final klass = graph.classes[path[i]];
//
//     String? fieldName;
//     String prefix = '';
//     if (i > 0) {
//       final int value = path[i - 1];
//       final hasUniqueOwner = (value & (1 << 0)) == 1;
//       final fieldIndex = value >> 1;
//       if (fieldIndex != DedupedUint32List.noFieldIndex) {
//         final field = klass.fields[fieldIndex];
//         assert(field.index == fieldIndex);
//         fieldName = field.name;
//       }
//       prefix = (hasUniqueOwner ? '・' : '﹢');
//     }
//
//     spath.add(prefix +
//         '${klass.name}' +
//         (fieldName != null ? '.$fieldName' : '') +
//         ' (${klass.libraryUri})');
//   }
//   return spath;
// }
//
// List<String> _stringifyDominatorPath(
//     HeapSnapshotGraph graph, DedupedUint32List rpath) {
//   final path = rpath.path;
//   final spath = <String>[];
//   for (int i = 0; i < path.length; i++) {
//     final klass = graph.classes[path[i]];
//     spath.add('${klass.name} (${klass.libraryUri})');
//   }
//   return spath;
// }
//
// class Table {
//   final List<List<String>> _rows = [];
//   int _maxColumn = -1;
//
//   int get rows => _rows.length;
//
//   void addRow(List<String> row) {
//     _maxColumn = row.length > _maxColumn ? row.length : _maxColumn;
//     _rows.add(row);
//   }
//
//   String get asString {
//     if (_rows.isEmpty) return '';
//
//     final colSizes = Uint32List(_maxColumn);
//     for (final row in _rows) {
//       for (int i = 0; i < row.length; ++i) {
//         final value = row[i];
//         final c = colSizes[i];
//         if (value.length > c) colSizes[i] = value.length;
//       }
//     }
//
//     final sb = StringBuffer();
//     for (final row in _rows) {
//       for (int i = 0; i < row.length; ++i) {
//         row[i] = row[i].padRight(colSizes[i], ' ');
//       }
//       sb.writeln(row.join('  '));
//     }
//     return sb.toString().trimRight();
//   }
// }
//
// String indent(String left, String text) {
//   return left + text.replaceAll('\n', '\n$left');
// }
