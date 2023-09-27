// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart' show immutable;

/// Data class that represents a range of versions in their String
/// representation.
///
/// Undefined [min] and [max] veresions represent an unknown minimum/maximum
/// version.
@immutable
class VersionRange{
  const VersionRange(
    this.min,
    this.max,
  );

  final String? min;
  final String? max;

  @override
  bool operator ==(Object other) =>
      other is VersionRange &&
      other.min == min &&
      other.max == max;

  @override
  int get hashCode => Object.hash(min, max);
}
