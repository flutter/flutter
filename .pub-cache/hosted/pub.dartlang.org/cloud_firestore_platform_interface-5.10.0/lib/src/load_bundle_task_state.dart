// ignore_for_file: require_trailing_commas
// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Represents the state of an on-going [LoadBundleTask].
///
/// The state can be accessed directly via a [LoadBundleTaskSnapshot].
enum LoadBundleTaskState {
  /// Indicates the task is currently in-progress.
  running,

  /// Indicates the task has successfully completed.
  success,

  /// Indicates the task failed with an error.
  error,
}
