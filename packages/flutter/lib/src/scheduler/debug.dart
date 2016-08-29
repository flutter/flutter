// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Print a banner at the beginning of each frame.
bool debugPrintBeginFrameBanner = false;

/// Print a banner at the end of each frame.
///
/// Combined with [debugPrintBeginFrameBanner], this can be helpful for
/// determining if code is running during a frame or between frames.
bool debugPrintEndFrameBanner = false;
