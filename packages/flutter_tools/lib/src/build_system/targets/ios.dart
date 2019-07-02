// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../build_system.dart';
import 'assets.dart';
import 'dart.dart';

/// Create an iOS debug application.
const Target iosApplication = Target(
  name: 'ios_application',
  buildAction: null,
  inputs: <Source>[],
  outputs: <Source>[],
  dependencies: <Target>[
    copyAssets,
    kernelSnapshot,
  ]
);

/// Create an iOS debug application.
const Target iosReleaseApplication = Target(
  name: 'ios_release_application',
  buildAction: null,
  inputs: <Source>[],
  outputs: <Source>[],
  dependencies: <Target>[
    copyAssets,
    aotAssembly,
  ]
);
