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
      int? significantDigits,
      this.maximumSignificantDigits,
      this.minimumSignificantDigits}) {
    if (significantDigits != null) {
      if (maximumSignificantDigits != null ||
          minimumSignificantDigits != null) {
        throw ArgumentError('Cannot specify both significantDigits and '
            'maximumSignificantDigits/minimumSignificantDigits');
      }
      maximumSignificantDigits = significantDigits;
      minimumSignificantDigits = significantDigits;
    }
  }

  num number;
  String expected;
  int? maximumIntegerDigits;
  int? minimumIntegerDigits;
  int? maximumFractionDigits;
  int? minimumFractionDigits;
  int? minimumExponentDigits;
  int? maximumSignificantDigits;
  int? minimumSignificantDigits;

  @override
  String toString() => 'CompactRoundingTestCase for $number, '
      'maxIntDig: $maximumIntegerDigits, '
      'minIntDig: $minimumIntegerDigits, '
      'maxFracDig: $maximumFractionDigits, '
      'minFracDig: $minimumFractionDigits, '
      'minExpDig: $minimumExponentDigits, '
      'maxSigDig: $maximumSignificantDigits, '
      'minSigDig: $minimumSignificantDigits.';
}

List<CompactRoundingTestCase> cldr35CompactNumTests = <CompactRoundingTestCase>[
  //
  CompactRoundingTestCase(1750000, '1.8M'),
  CompactRoundingTestCase(1750000, '1.8M', maximumIntegerDigits: 1),
  CompactRoundingTestCase(1750000, '1.8M', minimumIntegerDigits: 1),
  CompactRoundingTestCase(1750000, '1.8M', maximumIntegerDigits: 4),
  CompactRoundingTestCase(1750000, '0001.8M', minimumIntegerDigits: 4),
  CompactRoundingTestCase(1750000, '2M', maximumFractionDigits: 0),
  CompactRoundingTestCase(1750000, '1.75M', minimumFractionDigits: 0),
  CompactRoundingTestCase(1750000, '1.75M', maximumFractionDigits: 4),
  CompactRoundingTestCase(1750000, '1.7500M', minimumFractionDigits: 4),
  CompactRoundingTestCase(1750000, '1.8M', minimumExponentDigits: 3),
  CompactRoundingTestCase(1750000, '2M', significantDigits: 1),
  CompactRoundingTestCase(1750000, '1.8M', significantDigits: 2),
  CompactRoundingTestCase(1750000, '1.75M', significantDigits: 3),
  CompactRoundingTestCase(1750000, '1.750M', significantDigits: 4),

  CompactRoundingTestCase(175000, '175K'),
  CompactRoundingTestCase(175000, '175K', maximumIntegerDigits: 1),
  CompactRoundingTestCase(175000, '175K', minimumIntegerDigits: 1),
  CompactRoundingTestCase(175000, '175K', maximumIntegerDigits: 4),
  CompactRoundingTestCase(175000, '0175K', minimumIntegerDigits: 4),
  CompactRoundingTestCase(175000, '175K', maximumFractionDigits: 0),
  CompactRoundingTestCase(175000, '175K', minimumFractionDigits: 0),
  CompactRoundingTestCase(175000, '175K', maximumFractionDigits: 4),
  CompactRoundingTestCase(175000, '175.0000K', minimumFractionDigits: 4),
  CompactRoundingTestCase(175000, '175K', minimumExponentDigits: 3),
  CompactRoundingTestCase(175000, '200K', significantDigits: 1),
  CompactRoundingTestCase(175000, '180K', significantDigits: 2),
  CompactRoundingTestCase(175000, '175K', significantDigits: 3),
  CompactRoundingTestCase(175000, '175.0K', significantDigits: 4),

  CompactRoundingTestCase(1750, '01.750K',
      minimumIntegerDigits: 2, minimumFractionDigits: 3),
  CompactRoundingTestCase(1750, '01.8K',
      minimumIntegerDigits: 2, maximumFractionDigits: 1),

  CompactRoundingTestCase(175, '175'),
  CompactRoundingTestCase(175, '175', maximumIntegerDigits: 1),
  CompactRoundingTestCase(175, '175', minimumIntegerDigits: 1),
  CompactRoundingTestCase(175, '175', maximumIntegerDigits: 4),
  CompactRoundingTestCase(175, '0175', minimumIntegerDigits: 4),
  CompactRoundingTestCase(175, '175', maximumFractionDigits: 0),
  CompactRoundingTestCase(175, '175', minimumFractionDigits: 0),
  CompactRoundingTestCase(175, '175', maximumFractionDigits: 4),
  CompactRoundingTestCase(175, '175.0000', minimumFractionDigits: 4),
  CompactRoundingTestCase(175, '175', minimumExponentDigits: 3),
  CompactRoundingTestCase(175, '200', significantDigits: 1),
  CompactRoundingTestCase(175, '180', significantDigits: 2),
  CompactRoundingTestCase(175, '175', significantDigits: 3),
  CompactRoundingTestCase(175, '175.0', significantDigits: 4),

  CompactRoundingTestCase(1.756, '1.8'),
  CompactRoundingTestCase(1.756, '1.8', maximumIntegerDigits: 1),
  CompactRoundingTestCase(1.756, '1.8', minimumIntegerDigits: 1),
  CompactRoundingTestCase(1.756, '1.8', maximumIntegerDigits: 4),
  CompactRoundingTestCase(1.756, '0001.8', minimumIntegerDigits: 4),
  CompactRoundingTestCase(1.756, '2', maximumFractionDigits: 0),
  CompactRoundingTestCase(1.756, '1.756', minimumFractionDigits: 0),
  CompactRoundingTestCase(1.756, '1.756', maximumFractionDigits: 4),
  CompactRoundingTestCase(1.756, '1.7560', minimumFractionDigits: 4),
  CompactRoundingTestCase(1.756, '1.8', minimumExponentDigits: 3),
  CompactRoundingTestCase(1.756, '2', significantDigits: 1),
  CompactRoundingTestCase(1.756, '1.8', significantDigits: 2),
  CompactRoundingTestCase(1.756, '1.76', significantDigits: 3),
  CompactRoundingTestCase(1.756, '1.756', significantDigits: 4),

  CompactRoundingTestCase(1.75, '1.8'),
  CompactRoundingTestCase(1.75, '1.8', maximumIntegerDigits: 1),
  CompactRoundingTestCase(1.75, '1.8', minimumIntegerDigits: 1),
  CompactRoundingTestCase(1.75, '1.8', maximumIntegerDigits: 4),
  CompactRoundingTestCase(1.75, '0001.8', minimumIntegerDigits: 4),
  CompactRoundingTestCase(1.75, '2', maximumFractionDigits: 0),
  CompactRoundingTestCase(1.75, '1.75', minimumFractionDigits: 0),
  CompactRoundingTestCase(1.75, '1.75', maximumFractionDigits: 4),
  CompactRoundingTestCase(1.75, '1.7500', minimumFractionDigits: 4),
  CompactRoundingTestCase(1.75, '1.8', minimumExponentDigits: 3),
  CompactRoundingTestCase(1.75, '2', significantDigits: 1),
  CompactRoundingTestCase(1.75, '1.8', significantDigits: 2),
  CompactRoundingTestCase(1.75, '1.75', significantDigits: 3),
  CompactRoundingTestCase(1.75, '1.750', significantDigits: 4),

  CompactRoundingTestCase(1, '1'),
  CompactRoundingTestCase(1, '1', maximumIntegerDigits: 1),
  CompactRoundingTestCase(1, '1', minimumIntegerDigits: 1),
  CompactRoundingTestCase(1, '1', maximumIntegerDigits: 4),
  CompactRoundingTestCase(1, '0001', minimumIntegerDigits: 4),
  CompactRoundingTestCase(1, '1', maximumFractionDigits: 0),
  CompactRoundingTestCase(1, '1', minimumFractionDigits: 0),
  CompactRoundingTestCase(1, '1', maximumFractionDigits: 4),
  CompactRoundingTestCase(1, '1.0000', minimumFractionDigits: 4),
  CompactRoundingTestCase(1, '1', minimumExponentDigits: 3),
  CompactRoundingTestCase(1, '1', significantDigits: 1),
  CompactRoundingTestCase(1, '1.0', significantDigits: 2),
  CompactRoundingTestCase(1, '1.00', significantDigits: 3),
  CompactRoundingTestCase(1, '1.000', significantDigits: 4),

  CompactRoundingTestCase(0.9999, '1'),
  CompactRoundingTestCase(0.9999, '1', significantDigits: 1),
  CompactRoundingTestCase(0.9999, '1.0', significantDigits: 2),
  CompactRoundingTestCase(0.9999, '1.00', significantDigits: 3),
  CompactRoundingTestCase(0.9999, '0.9999', significantDigits: 4),

  CompactRoundingTestCase(0.9876, '0.99'),
  CompactRoundingTestCase(0.9876, '1', significantDigits: 1),
  CompactRoundingTestCase(0.9876, '0.99', significantDigits: 2),
  CompactRoundingTestCase(0.9876, '0.988', significantDigits: 3),
  CompactRoundingTestCase(0.9876, '0.9876', significantDigits: 4),

  CompactRoundingTestCase(999, '1K', significantDigits: 1),
  CompactRoundingTestCase(999, '1.0K', significantDigits: 2),
  CompactRoundingTestCase(999, '999', significantDigits: 3),
  CompactRoundingTestCase(999, '999.0', significantDigits: 4),

  CompactRoundingTestCase(999.9, '1K', significantDigits: 1),
  CompactRoundingTestCase(999.9, '1.0K', significantDigits: 2),
  CompactRoundingTestCase(999.9, '1.00K', significantDigits: 3),
  CompactRoundingTestCase(999.9, '999.9', significantDigits: 4),

  CompactRoundingTestCase(999.99, '1K', significantDigits: 1),
  CompactRoundingTestCase(999.99, '1.0K', significantDigits: 2),
  CompactRoundingTestCase(999.99, '1.00K', significantDigits: 3),
  CompactRoundingTestCase(999.99, '1.000K', significantDigits: 4),

  CompactRoundingTestCase(999000, '1M', significantDigits: 1),
  CompactRoundingTestCase(999000, '1.0M', significantDigits: 2),
  CompactRoundingTestCase(999000, '999K', significantDigits: 3),
  CompactRoundingTestCase(999000, '999.0K', significantDigits: 4),

  CompactRoundingTestCase(999, '1K', maximumSignificantDigits: 1),
  CompactRoundingTestCase(999, '1K', maximumSignificantDigits: 2),
  CompactRoundingTestCase(999, '999', maximumSignificantDigits: 3),
  CompactRoundingTestCase(999, '999', maximumSignificantDigits: 4),

  CompactRoundingTestCase(999.9, '1K', maximumSignificantDigits: 1),
  CompactRoundingTestCase(999.9, '1K', maximumSignificantDigits: 2),
  CompactRoundingTestCase(999.9, '1K', maximumSignificantDigits: 3),
  CompactRoundingTestCase(999.9, '999.9', maximumSignificantDigits: 4),

  CompactRoundingTestCase(999.99, '1K', maximumSignificantDigits: 1),
  CompactRoundingTestCase(999.99, '1K', maximumSignificantDigits: 2),
  CompactRoundingTestCase(999.99, '1K', maximumSignificantDigits: 3),
  CompactRoundingTestCase(999.99, '1K', maximumSignificantDigits: 4),

  CompactRoundingTestCase(999000, '1M', maximumSignificantDigits: 1),
  CompactRoundingTestCase(999000, '1M', maximumSignificantDigits: 2),
  CompactRoundingTestCase(999000, '999K', maximumSignificantDigits: 3),
  CompactRoundingTestCase(999000, '999K', maximumSignificantDigits: 4),

  CompactRoundingTestCase(999, '999', maximumFractionDigits: 0),
  CompactRoundingTestCase(999, '999', maximumFractionDigits: 1),
  CompactRoundingTestCase(999, '999', maximumFractionDigits: 2),

  CompactRoundingTestCase(999.9, '1K', maximumFractionDigits: 0),
  CompactRoundingTestCase(999.9, '999.9', maximumFractionDigits: 1),
  CompactRoundingTestCase(999.9, '999.9', maximumFractionDigits: 2),

  CompactRoundingTestCase(999.99, '1K', maximumFractionDigits: 0),
  CompactRoundingTestCase(999.99, '1K', maximumFractionDigits: 1),
  CompactRoundingTestCase(999.99, '999.99', maximumFractionDigits: 2),

  CompactRoundingTestCase(999900, '1M', maximumFractionDigits: 0),
  CompactRoundingTestCase(999900, '999.9K', maximumFractionDigits: 1),
  CompactRoundingTestCase(999900, '999.9K', maximumFractionDigits: 2),
];
