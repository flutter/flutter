// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';

void main() {

  // Change made in https://github.com/flutter/flutter/pull/20649
  const CupertinoDialog(child: Text('Test Fix'));

  // Change made in
  const CupertinoTextThemeData themeData = CupertinoTextThemeData(brightness: Brightness.dark);
  themeData.copyWith(brightness: Brightness.light);

}