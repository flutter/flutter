// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'adb_memory_info.dart';
import 'event_sample.dart';

/// DevTools Plotted and JSON persisted memory information.
class HeapSample {
  HeapSample(
    this.timestamp,
    this.rss,
    this.capacity,
    this.used,
    this.external,
    this.isGC,
    AdbMemoryInfo? adbMemoryInfo,
    EventSample? memoryEventInfo,
    RasterCache? rasterCache,
  )   : adbMemoryInfo = adbMemoryInfo ?? AdbMemoryInfo.empty(),
        memoryEventInfo = memoryEventInfo ?? EventSample.empty(),
        rasterCache = rasterCache ?? RasterCache.empty();

  factory HeapSample.fromJson(Map<String, dynamic> json) {
    final adbMemoryInfo = json['adb_memoryInfo'];
    final memoryEventInfo = json['memory_eventInfo'];
    final rasterCache = json['raster_cache'];
    return HeapSample(
      json['timestamp'] as int,
      json['rss'] as int,
      json['capacity'] as int,
      json['used'] as int,
      json['external'] as int,
      json['gc'] as bool,
      adbMemoryInfo != null
          ? AdbMemoryInfo.fromJson(adbMemoryInfo)
          : AdbMemoryInfo.empty(),
      memoryEventInfo != null
          ? EventSample.fromJson(memoryEventInfo)
          : EventSample.empty(),
      rasterCache != null
          ? RasterCache.fromJson(rasterCache)
          : RasterCache.empty(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp,
        'rss': rss,
        'capacity': capacity,
        'used': used,
        'external': external,
        'gc': isGC,
        'adb_memoryInfo': adbMemoryInfo.toJson(),
        'memory_eventInfo': memoryEventInfo.toJson(),
        'raster_cache': rasterCache.toJson(),
      };

  /// Version of HeapSample JSON payload.
  static const version = 1;

  final int timestamp;

  final int rss;

  final int capacity;

  final int used;

  final int external;

  final bool isGC;

  EventSample memoryEventInfo;

  AdbMemoryInfo adbMemoryInfo;

  RasterCache rasterCache;

  @override
  String toString() => '[HeapSample timestamp: $timestamp, '
      '${const JsonEncoder.withIndent('  ').convert(toJson())}]';
}
