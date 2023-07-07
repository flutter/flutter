// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This provides facilities for Internationalization that are only available
/// when running standalone. You should import only one of this or
/// intl_browser.dart. Right now the only thing provided here is finding
/// the operating system locale.

library intl_standalone;

import 'dart:io';
import 'intl.dart';

// TODO(alanknight): The need to do this by forcing the user to specially
// import a particular library is a horrible hack, only done because there
// seems to be no graceful way to do this at all. Either mirror access on
// dart2js or the ability to do spawnUri in the browser would be promising
// as ways to get rid of this requirement.
/// Find the system locale, accessed via the appropriate system APIs, and
/// set it as the default for internationalization operations in
/// the [Intl.systemLocale] variable.
Future<String> findSystemLocale() {
  try {
    Intl.systemLocale = Intl.canonicalizedLocale(Platform.localeName);
  } catch (e) {
    return Future.value();
  }
  return Future.value(Intl.systemLocale);
}
