// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The flavor this app was built with. Equivalent to the value of the
/// `--flavor` option at build time.
const String flavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');
