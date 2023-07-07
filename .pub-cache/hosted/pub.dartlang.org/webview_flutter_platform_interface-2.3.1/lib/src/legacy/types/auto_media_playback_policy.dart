// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Specifies possible restrictions on automatic media playback.
///
/// This is typically used in [WebView.initialMediaPlaybackPolicy].
// The method channel implementation is marshalling this enum to the value's index, so the order
// is important.
enum AutoMediaPlaybackPolicy {
  /// Starting any kind of media playback requires a user action.
  ///
  /// For example: JavaScript code cannot start playing media unless the code was executed
  /// as a result of a user action (like a touch event).
  require_user_action_for_all_media_types,

  /// Starting any kind of media playback is always allowed.
  ///
  /// For example: JavaScript code that's triggered when the page is loaded can start playing
  /// video or audio.
  always_allow,
}
