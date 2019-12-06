// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import 'context.dart';

const ProcessManager _kLocalProcessManager = LocalProcessManager();

/// The active process manager.
ProcessManager get processManager => context.get<ProcessManager>() ?? _kLocalProcessManager;
