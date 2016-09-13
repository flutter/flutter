// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => new Ticker(onTick);
}
