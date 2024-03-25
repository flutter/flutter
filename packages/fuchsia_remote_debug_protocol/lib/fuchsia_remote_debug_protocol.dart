// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Provides an API to test/debug Flutter applications on remote Fuchsia devices
/// and emulators.
///
/// The application typically runs in a separate process from the actual
/// test, wherein the user can supply the process with various events to test
/// the behavior of said application.
///
/// The API will provide methods to connect to one or more instances of the
/// Dart VM and operate on Isolates and Flutter Views, including affordances to
/// subscribe to creation and destruction of Dart VM instances, Isolates, and
/// Flutter Views. Not all of these features are yet implemented, as this
/// library is a work in progress.
library;

export 'src/common/network.dart';
export 'src/dart/dart_vm.dart';
export 'src/fuchsia_remote_connection.dart';
export 'src/runners/ssh_command_runner.dart';
