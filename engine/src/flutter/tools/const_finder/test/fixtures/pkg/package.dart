// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:const_finder_fixtures/target.dart';

void createTargetInPackage() {
  const Target target = Target('package', -1, null);
  target.hit();
}

void createNonConstTargetInPackage() {
  // ignore: prefer_const_constructors
  final Target target = Target('package_non', -2, null);
  target.hit();
}
