// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file contains code for collecting statistics about the use of fields in
/// a summary file.
import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/idl.dart';

main(List<String> args) {
  if (args.length != 1) {
    _printUsage();
    exitCode = 1;
    return;
  }

  String inputFilePath = args[0];

  // Read the input.
  PackageBundle bundle =
      PackageBundle.fromBuffer(File(inputFilePath).readAsBytesSync());

  // Compute and output stats.
  Stats stats = Stats();
  stats.record(bundle);
  stats.dump();
}

/// The name of the stats tool.
const String BINARY_NAME = "stats";

/// Print information about how to use the stats tool.
void _printUsage() {
  print('Usage: $BINARY_NAME input_file_path');
}

/// An instance of [Stats] keeps track of statistics about the use of fields in
/// summary objects.
class Stats {
  /// Map from type to field name to a count of how often the field is used.
  Map<Type, Map<String, int>> counts = <Type, Map<String, int>>{};

  /// Print out statistics gathered so far.
  void dump() {
    counts.forEach((Type type, Map<String, int> typeCounts) {
      print(type);
      List<String> keys = typeCounts.keys.toList();
      keys.sort((a, b) => typeCounts[b]!.compareTo(typeCounts[a]!));
      for (String key in keys) {
        print('  $key: ${typeCounts[key]}');
      }
      print('');
    });
  }

  /// Record statistics for [obj] and all objects it refers to.
  void record(SummaryClass obj) {
    Map<String, int> typeCounts =
        counts.putIfAbsent(obj.runtimeType, () => <String, int>{});
    obj.toMap().forEach((key, value) {
      if (value == null ||
          value == 0 ||
          value == false ||
          value == '' ||
          value is List && value.isEmpty ||
          // TODO(srawlins): Remove this and enumerate each enum which may
          // be encountered.
          // ignore: avoid_dynamic_calls
          reflect(value).type.isEnum && (value as dynamic).index == 0) {
        return;
      }
      typeCounts.update(key, (value) => value + 1, ifAbsent: () => 0);
      if (value is SummaryClass) {
        record(value);
      } else if (value is List) {
        value.forEach((element) {
          if (element is SummaryClass) {
            record(element);
          }
        });
      }
    });
  }
}
