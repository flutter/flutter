// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

final _whitespace = RegExp(r'\s+');

/// Convert adb device names into more human readable descriptions.
String cleanAdbDeviceName(String name) {
  // Some emulators use `___` in the name as separators.
  name = name.replaceAll('___', ', ');

  // Convert `Nexus_7` / `Nexus_5X` style names to `Nexus 7` ones.
  name = name.replaceAll('_', ' ');

  name = name.replaceAll(_whitespace, ' ').trim();

  return name;
}
