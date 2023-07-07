// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'class_heap_detail_stats.dart';
import 'heap_sample.dart';

abstract class DecodeEncode<T> {
  int get version;

  String encode(T sample);

  /// More than one Encoded entry, add a comma and the Encoded entry.
  String encodeAnother(T sample);

  T fromJson(Map<String, dynamic> json);
}

abstract class MemoryJson<T> implements DecodeEncode<T> {
  MemoryJson();

  /// Given a JSON string representing an array of HeapSample, decode to a
  /// List of HeapSample.
  MemoryJson.decode(
    String payloadName, {
    required String argJsonString,
    Map<String, dynamic>? argDecodedMap,
  }) {
    final Map<String, dynamic> decodedMap =
        argDecodedMap == null ? jsonDecode(argJsonString) : argDecodedMap;
    final Map<String, dynamic> samplesPayload = decodedMap['$payloadName'];

    final payloadVersion = samplesPayload['$jsonVersionField'];
    final payloadDevToolsScreen = samplesPayload['$jsonDevToolsScreenField'];

    if (payloadVersion != version) {
      // TODO(terry): Convert Payload TBD - only one version today.
      // TODO(terry): Notify user the file is being converted.
      // TODO(terry): Consider moving config_specific/logger/ into shared to
      //              use logger instead of print.
      print(
        'WARNING: Unable to convert JSON memory file payload version=$payloadVersion.',
      );
      // TODO(terry): After conversion update payloadVersion to version;
    }

    _memoryPayload = payloadDevToolsScreen == devToolsScreenValueMemory;
    _payloadVersion = payloadVersion;

    // Any problem return (data is empty).
    if (!isMatchedVersion || !isMemoryPayload) return;

    final List dynamicList = samplesPayload['$jsonDataField'];
    for (var index = 0; index < dynamicList.length; index++) {
      final sample = fromJson(dynamicList[index]);
      data.add(sample);
    }
  }

  late final int _payloadVersion;

  int get payloadVersion => _payloadVersion;

  /// Imported JSON data loaded and converted, if necessary, to the latest version.
  bool get isMatchedVersion => _payloadVersion == version;

  late final bool _memoryPayload;

  /// JSON payload field "dart<T>DevToolsScreen" has a value of "memory" e.g.,
  ///   "dartDevToolsScreen": "memory"
  bool get isMemoryPayload => _memoryPayload;

  /// If data is empty check isMatchedVersion and isMemoryPayload to ensure the
  /// JSON file loaded is a memory file.
  final data = <T>[];

  static const String jsonDevToolsScreenField = 'dartDevToolsScreen';
  // TODO(terry): Expose Timeline.
  // const String _devToolsScreenValueTimeline = 'timeline';
  static const String devToolsScreenValueMemory = 'memory';
  static const String jsonVersionField = 'version';
  static const String jsonDataField = 'data';

  /// Trailer portion:
  static String get trailer => '\n]\n}}';
}

class SamplesMemoryJson extends MemoryJson<HeapSample> {
  SamplesMemoryJson();

  /// Given a JSON string representing an array of HeapSample, decode to a
  /// List of HeapSample.
  SamplesMemoryJson.decode({
    required String argJsonString,
    Map<String, dynamic>? argDecodedMap,
  }) : super.decode(
          _jsonMemoryPayloadField,
          argJsonString: argJsonString,
          argDecodedMap: argDecodedMap,
        );

  /// Exported JSON payload of collected memory statistics.
  static const String _jsonMemoryPayloadField = 'samples';

  /// Structure of the memory JSON file:
  ///
  /// {
  ///   "samples": {
  ///     "version": 1,
  ///     "dartDevToolsScreen": "memory"
  ///     "data": [
  ///       Encoded Heap Sample see section below.
  ///     ]
  ///   }
  /// }

  /// Header portion (memoryJsonHeader) e.g.,
  /// =======================================
  /// {
  ///   "samples": {
  ///     "version": 1,
  ///     "dartDevToolsScreen": "memory"
  ///     "data": [
  ///
  /// Encoded Allocations entry (SamplesMemoryJson),
  /// ==============================================================================
  ///     {
  ///       "timestamp":1581540967479,
  ///       "rss":211419136,
  ///       "capacity":50956576,
  ///       "used":41384952,
  ///       "external":166176,
  ///       "gc":false,
  ///       "adb_memoryInfo":{
  ///         "Realtime":450147758,
  ///         "Java Heap":7416,
  ///         "Native Heap":41712,
  ///         "Code":12644,
  ///         "Stack":52,
  ///         "Graphics":0,
  ///         "Private Other":94420,
  ///         "System":6178,
  ///         "Total":162422
  ///       }
  ///     },
  ///
  /// Trailer portion (memoryJsonTrailer) e.g.,
  /// =========================================
  ///     ]
  ///   }
  /// }

  @override
  int get version => HeapSample.version;

  /// Encoded Heap Sample
  @override
  String encode(HeapSample sample) => jsonEncode(sample);

  /// More than one Encoded Heap Sample, add a comma and the Encoded Heap Sample.
  @override
  String encodeAnother(HeapSample sample) => ',\n${jsonEncode(sample)}';

  @override
  HeapSample fromJson(Map<String, dynamic> json) => HeapSample.fromJson(json);

  /// Given a list of HeapSample, encode as a Json string.
  static String encodeList(List<HeapSample> data) {
    final samplesJson = SamplesMemoryJson();
    final result = StringBuffer();

    // Iterate over all HeapSamples collected.
    data.map((f) {
      final encodedValue = result.isNotEmpty
          ? samplesJson.encodeAnother(f)
          : samplesJson.encode(f);
      result.write(encodedValue);
    }).toList();

    return '$header$result${MemoryJson.trailer}';
  }

  static String get header => '{"$_jsonMemoryPayloadField": {'
      '"${MemoryJson.jsonVersionField}": ${HeapSample.version}, '
      '"${MemoryJson.jsonDevToolsScreenField}": "${MemoryJson.devToolsScreenValueMemory}", '
      '"${MemoryJson.jsonDataField}": [\n';
}

/// Structure of the memory JSON file:
///
/// {
///   "allocations": {
///     "version": 1,
///     "dartDevToolsScreen": "memory"
///     "data": [
///       Encoded ClassHeapDetailStats see section below.
///     ]
///   }
/// }

/// Header portion (memoryJsonHeader) e.g.,
/// =======================================
/// {
///   "allocations": {
///     "version": 1,
///     "dartDevToolsScreen": "memory"
///     "data": [
///
/// Encoded Allocations entry (AllocationMemoryJson),
/// ==============================================================================
///     {
///       "class" : {
///          id: "classes/1"
///          name: "AClassName"
///        },
///       "instancesCurrent": 100,
///       "instancesDelta": 0,
///       "bytesCurrent": 55,
///       "bytesDelta": 5,
///       "isStacktraced": false,
///     },
///
/// Trailer portion (memoryJsonTrailer) e.g.,
/// =========================================
///     ]
///   }
/// }
class AllocationMemoryJson extends MemoryJson<ClassHeapDetailStats> {
  AllocationMemoryJson();

  /// Given a JSON string representing an array of HeapSample, decode to a
  /// List of HeapSample.
  AllocationMemoryJson.decode({
    required String argJsonString,
    Map<String, dynamic>? argDecodedMap,
  }) : super.decode(
          _jsonAllocationPayloadField,
          argJsonString: argJsonString,
          argDecodedMap: argDecodedMap,
        );

  /// Exported JSON payload of collected memory statistics.
  static const String _jsonAllocationPayloadField = 'allocations';

  /// Encoded ClassHeapDetailStats
  @override
  String encode(ClassHeapDetailStats sample) => jsonEncode(sample);

  /// More than one Encoded ClassHeapDetailStats, add a comma and the Encoded ClassHeapDetailStats entry.
  @override
  String encodeAnother(ClassHeapDetailStats sample) =>
      ',\n${jsonEncode(sample)}';

  @override
  ClassHeapDetailStats fromJson(Map<String, dynamic> json) =>
      ClassHeapDetailStats.fromJson(json);

  @override
  int get version => ClassHeapDetailStats.version;

  /// Given a list of HeapSample, encode as a Json string.
  static String encodeList(List<ClassHeapDetailStats> data) {
    final allocationJson = AllocationMemoryJson();

    final result = StringBuffer();

    // Iterate over all ClassHeapDetailStats collected.
    data.map((f) {
      final encodedValue = result.isNotEmpty
          ? allocationJson.encodeAnother(f)
          : allocationJson.encode(f);
      result.write(encodedValue);
    }).toList();

    return '$header$result${MemoryJson.trailer}';
  }

  /// Allocations Header portion:
  static String get header => '{"$_jsonAllocationPayloadField": {'
      '"${MemoryJson.jsonVersionField}": ${ClassHeapDetailStats.version}, '
      '"${MemoryJson.jsonDevToolsScreenField}": "${MemoryJson.devToolsScreenValueMemory}", '
      '"${MemoryJson.jsonDataField}": [\n';
}
