// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// HeapSpace of Dart VM collected heap data.
class HeapSpace {
  HeapSpace._fromJson(this.json)
      : avgCollectionPeriodMillis = json['avgCollectionPeriodMillis'],
        capacity = json['capacity'],
        collections = json['collections'],
        external = json['external'],
        name = json['name'],
        time = json['time'],
        used = json['used'];

  static HeapSpace? parse(Map<String, dynamic>? json) =>
      json == null ? null : HeapSpace._fromJson(json);

  final Map<String, dynamic> json;

  final double? avgCollectionPeriodMillis;

  final int? capacity;

  final int? collections;

  final int? external;

  final String? name;

  final double? time;

  final int? used;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['type'] = 'HeapSpace';
    json.addAll({
      'avgCollectionPeriodMillis': avgCollectionPeriodMillis,
      'capacity': capacity,
      'collections': collections,
      'external': external,
      'name': name,
      'time': time,
      'used': used,
    });
    return json;
  }

  @override
  String toString() => '[HeapSpace]';
}
