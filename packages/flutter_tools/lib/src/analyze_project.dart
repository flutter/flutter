// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'base/logger.dart';

class AnalyzeProject {
  AnalyzeProject({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

  Future<bool> diagnose() async {
    _logger.printStatus('test log');
    return true;
  }
}
