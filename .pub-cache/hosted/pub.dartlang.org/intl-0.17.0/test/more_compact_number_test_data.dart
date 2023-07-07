// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CompactRoundingTestCase {
  CompactRoundingTestCase(this.number, this.expected,
      {this.maximumIntegerDigits,
      this.minimumIntegerDigits,
      this.maximumFractionDigits,
      this.minimumFractionDigits,
      this.minimumExponentDigits,
      this.significantDigits});

  num number;
  String expected;
  int? maximumIntegerDigits;
  int? minimumIntegerDigits;
  int? maximumFractionDigits;
  int? minimumFractionDigits;
  int? minimumExponentDigits;
  int? significantDigits;

  String toString() => "CompactRoundingTestCase for $number, "
      "maxIntDig: $maximumIntegerDigits, "
      "minIntDig: $minimumIntegerDigits, "
      "maxFracDig: $maximumFractionDigits, "
      "minFracDig: $minimumFractionDigits, "
      "minExpDig: $minimumExponentDigits, "
      "sigDig: $significantDigits.";
}

var oldIntlCompactNumTests = <CompactRoundingTestCase>[
  // Most parameters are ignored, giving same result as the default:
  CompactRoundingTestCase(1750000, "1.75M"),
  CompactRoundingTestCase(1750000, "1.75M", maximumIntegerDigits: 1),
  CompactRoundingTestCase(1750000, "1.75M", minimumIntegerDigits: 1),
  CompactRoundingTestCase(1750000, "1.75M", maximumIntegerDigits: 4),
  CompactRoundingTestCase(1750000, "0001.75M", minimumIntegerDigits: 4),
  CompactRoundingTestCase(1750000, "1.75M", maximumFractionDigits: 0),
  CompactRoundingTestCase(1750000, "1.75M", minimumFractionDigits: 0),
  CompactRoundingTestCase(1750000, "1.75M", maximumFractionDigits: 4),
  CompactRoundingTestCase(1750000, "1.75M", minimumFractionDigits: 4),

  CompactRoundingTestCase(175000, "175K"),
  CompactRoundingTestCase(175000, "175K", maximumIntegerDigits: 1),
  CompactRoundingTestCase(175000, "175K", minimumIntegerDigits: 1),
  CompactRoundingTestCase(175000, "175K", maximumIntegerDigits: 4),
  CompactRoundingTestCase(175000, "0175K", minimumIntegerDigits: 4),
  CompactRoundingTestCase(175000, "175K", maximumFractionDigits: 0),
  CompactRoundingTestCase(175000, "175K", minimumFractionDigits: 0),
  CompactRoundingTestCase(175000, "175K", maximumFractionDigits: 4),
  CompactRoundingTestCase(175000, "175K", minimumFractionDigits: 4),

  CompactRoundingTestCase(1.756, "1.76"),
  CompactRoundingTestCase(1.756, "1.76", maximumIntegerDigits: 1),
  CompactRoundingTestCase(1.756, "1.76", minimumIntegerDigits: 1),
  CompactRoundingTestCase(1.756, "1.76", maximumIntegerDigits: 4),
  CompactRoundingTestCase(1.756, "0001.76", minimumIntegerDigits: 4),
  CompactRoundingTestCase(1.756, "1.76", maximumFractionDigits: 0),
  CompactRoundingTestCase(1.756, "1.76", minimumFractionDigits: 0),
  CompactRoundingTestCase(1.756, "1.76", maximumFractionDigits: 4),
  CompactRoundingTestCase(1.756, "1.76", minimumFractionDigits: 4),

  CompactRoundingTestCase(1.75, "1.75"),
  CompactRoundingTestCase(1.75, "1.75", maximumIntegerDigits: 1),
  CompactRoundingTestCase(1.75, "1.75", minimumIntegerDigits: 1),
  CompactRoundingTestCase(1.75, "1.75", maximumIntegerDigits: 4),
  CompactRoundingTestCase(1.75, "0001.75", minimumIntegerDigits: 4),
  CompactRoundingTestCase(1.75, "1.75", maximumFractionDigits: 0),
  CompactRoundingTestCase(1.75, "1.75", minimumFractionDigits: 0),
  CompactRoundingTestCase(1.75, "1.75", maximumFractionDigits: 4),
  CompactRoundingTestCase(1.75, "1.75", minimumFractionDigits: 4),
  CompactRoundingTestCase(1.75, "1.75", minimumExponentDigits: 3),
  CompactRoundingTestCase(1.75, "2", significantDigits: 1),
  CompactRoundingTestCase(1.75, "1.8", significantDigits: 2),
  CompactRoundingTestCase(1.75, "1.75", significantDigits: 3),
  CompactRoundingTestCase(1.75, "1.75", significantDigits: 4),
];

var cldr35CompactNumTests = <CompactRoundingTestCase>[
  //
  CompactRoundingTestCase(1750000, "1.8M"),
  CompactRoundingTestCase(1750000, "1.8M", maximumIntegerDigits: 1),
  CompactRoundingTestCase(1750000, "1.8M", minimumIntegerDigits: 1),
  CompactRoundingTestCase(1750000, "1.8M", maximumIntegerDigits: 4),
  CompactRoundingTestCase(1750000, "0001.8M", minimumIntegerDigits: 4),
  CompactRoundingTestCase(1750000, "2M", maximumFractionDigits: 0),
  CompactRoundingTestCase(1750000, "1.75M", minimumFractionDigits: 0),
  CompactRoundingTestCase(1750000, "1.75M", maximumFractionDigits: 4),
  CompactRoundingTestCase(1750000, "1.7500M", minimumFractionDigits: 4),
  CompactRoundingTestCase(1750000, "1.8M", minimumExponentDigits: 3),
  CompactRoundingTestCase(1750000, "2M", significantDigits: 1),
  CompactRoundingTestCase(1750000, "1.8M", significantDigits: 2),
  CompactRoundingTestCase(1750000, "1.75M", significantDigits: 3),
  CompactRoundingTestCase(1750000, "1.750M", significantDigits: 4),

  CompactRoundingTestCase(175000, "175K"),
  CompactRoundingTestCase(175000, "175K", maximumIntegerDigits: 1),
  CompactRoundingTestCase(175000, "175K", minimumIntegerDigits: 1),
  CompactRoundingTestCase(175000, "175K", maximumIntegerDigits: 4),
  CompactRoundingTestCase(175000, "0175K", minimumIntegerDigits: 4),
  CompactRoundingTestCase(175000, "175K", maximumFractionDigits: 0),
  CompactRoundingTestCase(175000, "175K", minimumFractionDigits: 0),
  CompactRoundingTestCase(175000, "175K", maximumFractionDigits: 4),
  CompactRoundingTestCase(175000, "175.0000K", minimumFractionDigits: 4),
  CompactRoundingTestCase(175000, "175K", minimumExponentDigits: 3),
  CompactRoundingTestCase(175000, "200K", significantDigits: 1),
  CompactRoundingTestCase(175000, "180K", significantDigits: 2),
  CompactRoundingTestCase(175000, "175K", significantDigits: 3),
  CompactRoundingTestCase(175000, "175.0K", significantDigits: 4),

  CompactRoundingTestCase(1750, "01.750K",
      minimumIntegerDigits: 2, minimumFractionDigits: 3),
  CompactRoundingTestCase(1750, "01.8K",
      minimumIntegerDigits: 2, maximumFractionDigits: 1),

  CompactRoundingTestCase(1.756, "1.8"),
  CompactRoundingTestCase(1.756, "1.8", maximumIntegerDigits: 1),
  CompactRoundingTestCase(1.756, "1.8", minimumIntegerDigits: 1),
  CompactRoundingTestCase(1.756, "1.8", maximumIntegerDigits: 4),
  CompactRoundingTestCase(1.756, "0001.8", minimumIntegerDigits: 4),
  CompactRoundingTestCase(1.756, "2", maximumFractionDigits: 0),
  CompactRoundingTestCase(1.756, "1.756", minimumFractionDigits: 0),
  CompactRoundingTestCase(1.756, "1.756", maximumFractionDigits: 4),
  CompactRoundingTestCase(1.756, "1.7560", minimumFractionDigits: 4),
  CompactRoundingTestCase(1.756, "1.8", minimumExponentDigits: 3),
  CompactRoundingTestCase(1.756, "2", significantDigits: 1),
  CompactRoundingTestCase(1.756, "1.8", significantDigits: 2),
  CompactRoundingTestCase(1.756, "1.76", significantDigits: 3),
  CompactRoundingTestCase(1.756, "1.756", significantDigits: 4),

  CompactRoundingTestCase(1.75, "1.8"),
  CompactRoundingTestCase(1.75, "1.8", maximumIntegerDigits: 1),
  CompactRoundingTestCase(1.75, "1.8", minimumIntegerDigits: 1),
  CompactRoundingTestCase(1.75, "1.8", maximumIntegerDigits: 4),
  CompactRoundingTestCase(1.75, "0001.8", minimumIntegerDigits: 4),
  CompactRoundingTestCase(1.75, "2", maximumFractionDigits: 0),
  CompactRoundingTestCase(1.75, "1.75", minimumFractionDigits: 0),
  CompactRoundingTestCase(1.75, "1.75", maximumFractionDigits: 4),
  CompactRoundingTestCase(1.75, "1.7500", minimumFractionDigits: 4),
  CompactRoundingTestCase(1.75, "1.8", minimumExponentDigits: 3),
  CompactRoundingTestCase(1.75, "2", significantDigits: 1),
  CompactRoundingTestCase(1.75, "1.8", significantDigits: 2),
  CompactRoundingTestCase(1.75, "1.75", significantDigits: 3),
  CompactRoundingTestCase(1.75, "1.750", significantDigits: 4),
];
