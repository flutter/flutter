// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides an API to test/debug Flutter applications on remote Fuchsia devices
/// and emulators.
///
/// The application typically runs in a separate process from the actual
/// test, wherein the user can supply the process with various events to test
/// the behavior of said application.
library fuchsia_remote_debug_protocol;

export 'src/dart/dart_vm.dart';
export 'src/fuchsia_remote_connection.dart';
export 'src/runners/ssh_command_runner.dart';
