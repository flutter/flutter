// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';

import 'context.dart';

export 'package:platform/platform.dart';

const Platform _kLocalPlatform = LocalPlatform();

Platform get platform => context.get<Platform>() ?? _kLocalPlatform;
