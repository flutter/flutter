// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns a human readable string for a duration.
///
/// Handles durations that span up to hours - this will not be a good fit for
/// durations that are longer than days.
///
/// Always attempts 2 'levels' of precision. Will show hours/minutes,
/// minutes/seconds, seconds/tenths of a second, or milliseconds depending on
/// the largest level that needs to be displayed.
///
// TODO: This is copied from `package:build_runner_core`, at some point we
// may want to move this to a shared dependency.
String humanReadable(Duration duration) {
  if (duration < const Duration(seconds: 1)) {
    return '${duration.inMilliseconds}ms';
  }
  if (duration < const Duration(minutes: 1)) {
    return '${(duration.inMilliseconds / 1000.0).toStringAsFixed(1)}s';
  }
  if (duration < const Duration(hours: 1)) {
    final minutes = duration.inMinutes;
    final remaining = duration - Duration(minutes: minutes);
    return '${minutes}m ${remaining.inSeconds}s';
  }
  final hours = duration.inHours;
  final remaining = duration - Duration(hours: hours);
  return '${hours}h ${remaining.inMinutes}m';
}
