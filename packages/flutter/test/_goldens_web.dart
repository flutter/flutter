// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

// package:flutter_goldens is not used as part of the test process for web.
// TODO(Piinks): Retrace steps to how ^web does actually... use flutter_goldens
Future<void> testExecutable(FutureOr<void> Function() testMain) async => testMain();
