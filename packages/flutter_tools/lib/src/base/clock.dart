// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:quiver/time.dart';

import 'context.dart';

/// Currently active clock implementation.
///
/// By default uses system clock. Override this in tests using [Clock.fixed].
Clock get clock => context == null ? const Clock() : context[Clock];
