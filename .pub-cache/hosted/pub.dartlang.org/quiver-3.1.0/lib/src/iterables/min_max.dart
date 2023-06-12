// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Returns the maximum value in [i], according to the order specified by the
/// [compare] function, or `null` if [i] is empty.
///
/// The compare function must act as a [Comparator]. If [compare] is omitted,
/// [Comparable.compare] is used. If [i] contains null elements, an exception
/// will be thrown.
T? max<T>(Iterable<T> i, [Comparator<T>? compare]) {
  if (i.isEmpty) return null;
  final Comparator<T> _compare = compare ?? _compareAny;
  return i.reduce((a, b) => _compare(a, b) > 0 ? a : b);
}

/// Returns the minimum value in [i], according to the order specified by the
/// [compare] function, or `null` if [i] is empty.
///
/// The compare function must act as a [Comparator]. If [compare] is omitted,
/// [Comparable.compare] is used. If [i] contains null elements, an exception
/// will be thrown.
T? min<T>(Iterable<T> i, [Comparator<T>? compare]) {
  if (i.isEmpty) return null;
  final Comparator<T> _compare = compare ?? _compareAny;
  return i.reduce((a, b) => _compare(a, b) < 0 ? a : b);
}

/// Returns the minimum and maximum values in [i], according to the order
/// specified by the [compare] function, in an [Extent] instance. Always
/// returns an [Extent], but [Extent.min] and [Extent.max] may be `null` if [i]
/// is empty.
///
/// The compare function must act as a [Comparator]. If [compare] is omitted,
/// [Comparable.compare] is used. If [i] contains null elements, an exception
/// will be thrown.
///
/// If [i] is empty, an [Extent] is returned with [:null:] values for [:min:]
/// and [:max:], since there are no valid values for them.
Extent<T> extent<T>(Iterable<T> i, [Comparator<T>? compare]) {
  if (i.isEmpty) return Extent(null, null);
  final Comparator<T> _compare = compare ?? _compareAny;
  var iterator = i.iterator;
  var hasNext = iterator.moveNext();
  if (!hasNext) return Extent(null, null);
  var max = iterator.current;
  var min = iterator.current;
  while (iterator.moveNext()) {
    if (_compare(max, iterator.current) < 0) max = iterator.current;
    if (_compare(min, iterator.current) > 0) min = iterator.current;
  }
  return Extent(min, max);
}

class Extent<T> {
  Extent(this.min, this.max);

  final T? min;
  final T? max;
}

int _compareAny<T>(T a, T b) {
  return Comparable.compare(a as Comparable, b as Comparable);
}
