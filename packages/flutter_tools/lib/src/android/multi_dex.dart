// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';

File _getMultidexUtilsFile(Directory projectDir) {
  return projectDir.childDirectory('android')
    .childDirectory('app')
    .childDirectory('src')
    .childDirectory('main')
    .childDirectory('java')
    .childDirectory('io')
    .childDirectory('flutter')
    .childDirectory('app')
    .childFile('FlutterMultidexSupportUtils.java');
}

/// Creates the FlutterMultidexSupportUtils.java file if it does not exist.
///
/// Otherwise, does nothing. This does not verify the contents
/// of the java file are valid.
void ensureMultidexUtilsExists(final Directory projectDir) {
  final File utilsFile = _getMultidexUtilsFile(projectDir);
  if (utilsFile.existsSync()) {
    return;
  }
  utilsFile.createSync(recursive: true);

  final StringBuffer buffer = StringBuffer();
  buffer.write('''
// Generated file. Please do not edit.

package io.flutter.app;

import android.content.Context;
import androidx.multidex.Multidex;

/**
 * A utility class that adds Multidex support for apps that support minSdk 20
 * and below.
 *
 * <p>If the minSdk version is 21 or above, multidex is natively supported.
 */
public class FlutterMultidexSupportUtils {
  public static void installMultidexSupport(Context context) {
    Multidex.install(context);
  }
}

''');
  utilsFile.writeAsStringSync(buffer.toString(), flush: true);
}

/// Returns true if the FlutterMultidexSupportUtils.java file exists.
bool multidexUtilsExists(final Directory projectDir) {
  if (_getMultidexUtilsFile(projectDir).existsSync()) {
    return true;
  }
  return false;
}
