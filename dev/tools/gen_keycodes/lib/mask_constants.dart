// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class MaskConstant {
  const MaskConstant._({required this.name, required this.value, required this.description});

  factory MaskConstant.fromJsonMapEntry(String name, Map<String, dynamic> map) {
    dynamic getNonNull(String key) {
      final dynamic value = map[key];
      assert(value != null);
      return value;
    }

    return MaskConstant._(
      name: name,
      value: getNonNull('value') as String,
      description: <String>[for (dynamic element in getNonNull('description') as List<dynamic>)
        element as String],
    );
  }

  final String name;
  final String value;
  final List<String> description;
}

List<MaskConstant> parseMaskConstants(dynamic content) {
  return <MaskConstant>[
    for (final String key in content.keys)
      MaskConstant.fromJsonMapEntry(key, content[key] as Map<String, dynamic>),
  ];
}
