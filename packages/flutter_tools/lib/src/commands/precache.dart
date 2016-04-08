// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';

import '../cache.dart';

class PrecacheCommand extends Command {
  @override
  final String name = 'precache';

  @override
  final String description = 'Populates the Flutter tool\'s cache of binary artifacts.';

  @override
  Future<int> run() async {
    await Cache.instance.updateAll();
    return 0;
  }
}
