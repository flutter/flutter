// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returns [name] if [number] is 1, or the plural of [name] otherwise.
///
/// By default, this just adds "s" to the end of [name] to get the plural. If
/// [plural] is passed, that's used instead.
String pluralize(String name, int number, {String? plural}) {
  if (number == 1) return name;
  if (plural != null) return plural;
  return '${name}s';
}

/// Returns a sentence fragment listing the elements of [iter].
///
/// This converts each element of [iter] to a string and separates them with
/// commas and/or [conjunction] where appropriate. The [conjunction] defaults to
/// "and".
String toSentence(Iterable iter, {String conjunction = 'and'}) {
  if (iter.length == 1) return iter.first.toString();

  var result = iter.take(iter.length - 1).join(', ');
  if (iter.length > 2) result += ',';
  return '$result $conjunction ${iter.last}';
}

/// Returns a human-friendly representation of [duration].
String niceDuration(Duration duration) {
  var minutes = duration.inMinutes;
  var seconds = duration.inSeconds % 60;
  var decaseconds = (duration.inMilliseconds % 1000) ~/ 100;

  var buffer = StringBuffer();
  if (minutes != 0) buffer.write('$minutes minutes');

  if (minutes == 0 || seconds != 0) {
    if (minutes != 0) buffer.write(', ');
    buffer.write(seconds);
    if (decaseconds != 0) buffer.write('.$decaseconds');
    buffer.write(' seconds');
  }

  return buffer.toString();
}
