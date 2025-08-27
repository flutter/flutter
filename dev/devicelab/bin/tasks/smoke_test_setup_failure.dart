// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Creates a situation when the test framework was not properly initialized.
///
/// By not calling `task()` the VM service extension is not registered and
/// therefore will not accept requests to run tasks. When the runner attempts to
/// connect and run the test it will receive a "method not found" error from the
/// VM service, will likely retry forever.
///
/// The test in ../../test/run_test.dart runs this task until it detects
/// the retry message and then aborts the task.
Future<void> main() async {}
