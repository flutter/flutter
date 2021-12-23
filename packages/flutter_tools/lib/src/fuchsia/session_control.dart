// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/process.dart';

import 'fuchsia_device.dart';

// Usage: session_control <command> [<args>]
//
// Various operations to control sessions.
//
// Options:
// --help            display usage information
//
// Commands:
// launch            Launch a new session.
// restart           Restart the current session.
// add               Add an element to the current session.
//
// Usage: session_control launch <session_url>
//
// Launch a new session.
//
// Options:
// --help            display usage information
//
// Usage: session_control restart
//
// Restart the current session.
//
// Options:
// --help            display usage information
//
//
// Usage: session_control add <element_url>
//
// Add an element to the current session.
//
// Options:
// --help            display usage information

/// A simple wrapper around the 'session_control' tool running on the Fuchsia device.
class FuchsiaSessionControl {
  /// Instructs session_control on the device to add the app at [url] as an element.
  ///
  /// [url] should be formatted as a Fuchsia-style package URL, e.g.:
  ///     fuchsia-pkg://fuchsia.com/flutter_gallery#meta/flutter_gallery.cmx
  /// Returns true on success and false on failure.
  Future<bool> add(FuchsiaDevice device, String url) async {
    final RunResult result = await device.shell('session_control add $url');
    return result.exitCode == 0;
  }
}
