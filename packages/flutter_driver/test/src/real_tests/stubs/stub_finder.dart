// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

class StubFinder extends SerializableFinder {
  StubFinder(this.keyString);

  final String keyString;

  @override
  String get finderType => 'Stub';

  @override
  Map<String, String> serialize() {
    return super.serialize()..addAll(<String, String>{'keyString': keyString});
  }
}
