// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';

import 'context.dart';

export 'package:platform/platform.dart';

const Platform _kLocalPlatform = const LocalPlatform();

Platform get platform => context == null ? _kLocalPlatform : context[Platform];
