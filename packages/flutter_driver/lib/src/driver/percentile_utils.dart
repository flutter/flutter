// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Returns the [p]-th percentile element from the [doubles].
/// `List<doubles>` will be sorted.
double findPercentile(List<double> doubles, double p) {
  assert(doubles.isNotEmpty);
  doubles.sort();
  return doubles[((doubles.length - 1) * (p / 100)).round()];
}
