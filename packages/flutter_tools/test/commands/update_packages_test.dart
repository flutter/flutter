// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/update_packages.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('UpdatePackagesCommand', () {
    // Marking it as experimental breaks bots tests and packaging scripts on stable branches.
    testUsingContext('is not marked as experimental', () async {
      final UpdatePackagesCommand command = UpdatePackagesCommand();
      expect(command.isExperimental, isFalse);
    });
  });
}
