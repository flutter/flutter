// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:characters/src/grapheme_clusters/constants.dart";

export "unicode_grapheme_tests.dart";

String testDescription(List<String> expected) {
  return "÷ " +
      expected
          .map((s) => s.runes
              .map((x) => x.toRadixString(16).padLeft(4, "0"))
              .join(" × "))
          .join(" ÷ ") +
      " ÷";
}

var categoryName = List<String>.filled(16, "")
  ..[categoryOther] = "Other"
  ..[categoryCR] = "CR"
  ..[categoryLF] = "LF"
  ..[categoryControl] = "Control"
  ..[categoryExtend] = "Extend"
  ..[categoryZWJ] = "ZWJ"
  ..[categoryRegionalIndicator] = "RI"
  ..[categoryPrepend] = "Prepend"
  ..[categorySpacingMark] = "SpacingMark"
  ..[categoryL] = "L"
  ..[categoryV] = "V"
  ..[categoryT] = "T"
  ..[categoryLV] = "LV"
  ..[categoryLVT] = "LVT"
  ..[categoryPictographic] = "Pictographic"
  ..[categoryEoT] = "EoT";
