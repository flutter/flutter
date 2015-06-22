// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

enum Relation { equalTo, lessThanOrEqualTo, greaterThanOrEqualTo, }

class Constraint {
  final Relation relation;
  final Expression expression;
  double priority = 1000.0;

  Constraint(this.expression, this.relation);
}
