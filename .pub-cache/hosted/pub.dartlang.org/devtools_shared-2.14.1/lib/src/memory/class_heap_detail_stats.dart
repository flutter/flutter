// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

/// Entries for each class statistics
class ClassHeapDetailStats {
  ClassHeapDetailStats(
    this.classRef, {
    required int bytes,
    int deltaBytes = 0,
    required int instances,
    int deltaInstances = 0,
    bool traceAllocations = false,
  })  : bytesCurrent = bytes,
        bytesDelta = deltaBytes,
        instancesCurrent = instances,
        instancesDelta = deltaInstances,
        isStacktraced = traceAllocations;

  factory ClassHeapDetailStats.fromJson(Map<String, dynamic> json) {
    final classId = json['class']['id'];
    final className = json['class']['name'];

    return ClassHeapDetailStats(
      ClassRef(id: classId, name: className, library: null),
      bytes: json['bytesCurrent'] as int,
      deltaBytes: json['bytesDelta'] as int,
      instances: json['instancesCurrent'] as int,
      deltaInstances: json['instancesDelta'] as int,
      traceAllocations: json['isStackedTraced'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'class': {'id': classRef.id, 'name': classRef.name},
        'bytesCurrent': bytesCurrent,
        'bytesDelta': bytesDelta,
        'instancesCurrent': instancesCurrent,
        'instancesDelta': instancesDelta,
        'isStackedTraced': isStacktraced,
      };

  /// Version of ClassHeapDetailsStats payload.
  static const version = 1;

  final ClassRef classRef;

  final int instancesCurrent;

  int instancesDelta;

  final int bytesCurrent;

  int bytesDelta;

  bool isStacktraced;

  @override
  String toString() => '[ClassHeapDetailStats class: ${classRef.name}, '
      'count: $instancesCurrent, bytes: $bytesCurrent]';
}
