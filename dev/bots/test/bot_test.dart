// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'common.dart';

void main() {
  test('BOT variable is set on bots', () {
    expect(Platform.environment['BOT'], 'true');
  }, skip: true);
}
