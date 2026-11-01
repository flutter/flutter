// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

void main() {
  // Change made in https://github.com/flutter/flutter/pull/177102
  Table(border: TableBorder.all());
  Table(border: const TableBorder.symmetric(inside: BorderSide()));
  const TableBorder tableBorder = TableBorder();
  TableBorder.lerp(tableBorder, tableBorder, 0.5);
}

// Change made in https://github.com/flutter/flutter/pull/177102
class CustomTableBorder extends TableBorder {
  const CustomTableBorder() : super(top: const BorderSide());
}
