// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// This changes the DocSetPlatformFamily key to be "dartlang" instead of the
/// name of the package (usually "flutter").
///
/// This is so that the IntelliJ plugin for Dash will be able to go directly to
/// the docs for a symbol from a keystroke. Without this, flutter isn't part
/// of the list of package names it searches. After this, it finds the flutter
/// docs because they're declared here to be part of the "dartlang" family of
/// docs.
///
/// Dashing doesn't have a way to configure this, so we modify the Info.plist
/// directly to make the change.
void main(List<String> args) {
  final File infoPlist = File('flutter.docset/Contents/Info.plist');
  String contents = infoPlist.readAsStringSync();

  // Since I didn't want to add the XML package as a dependency just for this,
  // I just used a regular expression to make this simple change.
  final RegExp findRe = RegExp(r'(\s*<key>DocSetPlatformFamily</key>\s*<string>)[^<]+(</string>)', multiLine: true);
  contents = contents.replaceAllMapped(findRe, (Match match) {
    return '${match.group(1)}dartlang${match.group(2)}';
  });
  infoPlist.writeAsStringSync(contents);
}
