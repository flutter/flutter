// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Print a banner at the beginning of each frame.
///
/// Frames triggered by the engine and handler by the scheduler binding will
/// have a banner giving the frame number and the time stamp of the frame.
///
/// Frames triggered eagerly by the widget framework (e.g. when calling
/// [runApp]) will have a label saying "warm-up frame" instead of the time stamp
/// (the time stamp sent to frame callbacks in that case is the time of the last
/// frame, or 0:00 if it is the first frame).
///
/// To include a banner at the end of each frame as well, to distinguish
/// intra-frame output from inter-frame output, set [debugPrintEndFrameBanner]
/// to true as well.
///
/// See [SchedulerBinding.beginFrame].
bool debugPrintBeginFrameBanner = false;

/// Print a banner at the end of each frame.
///
/// Combined with [debugPrintBeginFrameBanner], this can be helpful for
/// determining if code is running during a frame or between frames.
bool debugPrintEndFrameBanner = false;
