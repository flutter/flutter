// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'shell.dart';

/// Ensures that the [MojoShell] singleton is created synchronously
/// during binding initialization. This allows other binding classes
/// to register services in the same call stack as the services are
/// offered to the embedder, thus avoiding any potential race
/// conditions. For example, without this, the embedder might have
/// requested a service before the Dart VM has started running; if the
/// [MojoShell] is then created in an earlier call stack than the
/// server for that service is provided, then the request will be
/// rejected as not matching any registered servers.
abstract class ServicesBinding extends BindingBase {
  @override
  void initInstances() {
    super.initInstances();
    new MojoShell();
  }
}
