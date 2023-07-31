import 'dart:typed_data';

import 'predicate.dart';
import 'range.dart';

class LookupCharPredicate implements CharacterPredicate {
  LookupCharPredicate(List<RangeCharPredicate> ranges)
      : start = ranges.first.start,
        stop = ranges.last.stop,
        bits = Uint32List(
            (ranges.last.stop - ranges.first.start + 1 + offset) >> shift) {
    for (final range in ranges) {
      for (var index = range.start - start;
          index <= range.stop - start;
          index++) {
        bits[index >> shift] |= mask[index & offset];
      }
    }
  }

  final int start;
  final int stop;
  final Uint32List bits;

  @override
  bool test(int value) =>
      start <= value && value <= stop && _testBit(value - start);

  bool _testBit(int value) =>
      (bits[value >> shift] & mask[value & offset]) != 0;

  @override
  bool isEqualTo(CharacterPredicate other) =>
      other is LookupCharPredicate &&
      other.start == start &&
      other.stop == stop &&
      other.bits == bits;

  static const int shift = 5;
  static const int offset = 31;
  static const List<int> mask = [
    1,
    2,
    4,
    8,
    16,
    32,
    64,
    128,
    256,
    512,
    1024,
    2048,
    4096,
    8192,
    16384,
    32768,
    65536,
    131072,
    262144,
    524288,
    1048576,
    2097152,
    4194304,
    8388608,
    16777216,
    33554432,
    67108864,
    134217728,
    268435456,
    536870912,
    1073741824,
    2147483648,
  ];
}
