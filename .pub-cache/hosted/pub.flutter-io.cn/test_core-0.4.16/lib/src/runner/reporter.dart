// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An interface for classes that watch the progress of an Engine and report it
/// to the user.
///
/// A reporter should subscribe to the Engine's events as soon as it's created.
abstract class Reporter {
  /// Pauses the reporter's output.
  ///
  /// Subclasses should buffer any events from the engine while they're paused.
  /// They should also ensure that this does nothing if the reporter is already
  /// paused.
  void pause();

  /// Resumes the reporter's output after being [paused].
  ///
  /// Subclasses should ensure that this does nothing if the reporter isn't
  /// paused.
  void resume();
}
