// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:multicast_dns/src/resource_record.dart';

/// Cache for resource records that have been received.
///
/// There can be multiple entries for the same name and type.
///
/// The cache is updated with a list of records, because it needs to remove
/// all entries that correspond to the name and type of the name/type
/// combinations of records that should be updated.  For example, a host may
/// remove one of its IP addresses and report the remaining address as a
/// response - then we need to clear all previous entries for that host before
/// updating the cache.
class ResourceRecordCache {
  /// Creates a new ResourceRecordCache.
  ResourceRecordCache();

  final Map<int, SplayTreeMap<String, List<ResourceRecord>>> _cache =
      <int, SplayTreeMap<String, List<ResourceRecord>>>{};

  /// The number of entries in the cache.
  int get entryCount {
    int count = 0;
    for (final SplayTreeMap<String, List<ResourceRecord>> map
        in _cache.values) {
      for (final List<ResourceRecord> records in map.values) {
        count += records.length;
      }
    }
    return count;
  }

  /// Update the records in this cache.
  void updateRecords(List<ResourceRecord> records) {
    // TODO(karlklose): include flush bit in the record and only flush if
    // necessary.
    // Clear the cache for all name/type combinations to be updated.
    final Map<int, Set<String>> seenRecordTypes = <int, Set<String>>{};
    for (final ResourceRecord record in records) {
      // TODO(dnfield): Update this to use set literal syntax when we're able to bump the SDK constraint.
      seenRecordTypes[record.resourceRecordType] ??=
          Set<String>(); // ignore: prefer_collection_literals
      if (seenRecordTypes[record.resourceRecordType]!.add(record.name)) {
        _cache[record.resourceRecordType] ??=
            SplayTreeMap<String, List<ResourceRecord>>();

        _cache[record.resourceRecordType]![record.name] = <ResourceRecord>[
          record
        ];
      } else {
        _cache[record.resourceRecordType]![record.name]!.add(record);
      }
    }
  }

  /// Get a record from this cache.
  void lookup<T extends ResourceRecord>(
      String name, int type, List<T> results) {
    assert(ResourceRecordType.debugAssertValid(type));
    final int time = DateTime.now().millisecondsSinceEpoch;
    final SplayTreeMap<String, List<ResourceRecord>>? candidates = _cache[type];
    if (candidates == null) {
      return;
    }

    final List<ResourceRecord>? candidateRecords = candidates[name];
    if (candidateRecords == null) {
      return;
    }
    candidateRecords
        .removeWhere((ResourceRecord candidate) => candidate.validUntil < time);
    results.addAll(candidateRecords.cast<T>());
  }
}
