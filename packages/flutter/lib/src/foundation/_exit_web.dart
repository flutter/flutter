// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The dart:html implementation of an exit call.
///
/// This throws an [UnsupportedError] when called, as web applications do not
/// have sufficient permissions to exit their own browser.
void exit() {
  throw UnsupportedError('Cannot call exit() on the web.');
}
