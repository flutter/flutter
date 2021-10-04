// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';

File _getMultiDexKeepFile(Directory projectDir) {
  return projectDir.childDirectory('android')
    .childDirectory('app')
    .childFile('multidex-flutter-keepfile.txt');
}

/// Creates a multi dex keep file if it does not exist.
///
/// Otherwise, does nothing. This does not verify the contents
/// of the keep file are valid.
void ensureMultiDexKeepFileExists(final Directory projectDir) {
  final File keepFile = _getMultiDexKeepFile(projectDir);
  if (keepFile.existsSync()) {
    return;
  }
  keepFile.createSync(recursive: true);

  final StringBuffer buffer = StringBuffer();
  // TODO(garyq): Programmatically determine the classes to keep.
  //
  // We include both FlutterApplication and FlutterMultiDexApplication as the develoepr may choose
  // to manually install multidex support.
  buffer.write('''
io/flutter/app/FlutterApplication.class
io/flutter/app/FlutterMultiDexApplication.class
io/flutter/view/FlutterMain.class
io/flutter/util/PathUtils.class
''');
  keepFile.writeAsStringSync(buffer.toString(), flush: true);
}

/// Returns true if the multi dex keep file exists.
bool multiDexKeepFileExists(final Directory projectDir) {
  if (_getMultiDexKeepFile(projectDir).existsSync()) {
    return true;
  }
  return false;
}

File _getMultiDexUtilsFile(Directory projectDir) {
  return projectDir.childDirectory('android')
    .childDirectory('app')
    .childDirectory('src')
    .childDirectory('main')
    .childDirectory('java')
    .childDirectory('io')
    .childDirectory('flutter')
    .childDirectory('app')
    .childFile('FlutterMultiDexSupportUtils.java');
}

/// Creates the FlutterMultiDexSupportUtils.java file if it does not exist.
///
/// Otherwise, does nothing. This does not verify the contents
/// of the java file are valid.
void ensureMultiDexUtilsExists(final Directory projectDir) {
  final File utilsFile = _getMultiDexUtilsFile(projectDir);
  if (utilsFile.existsSync()) {
    return;
  }
  utilsFile.createSync(recursive: true);

  final StringBuffer buffer = StringBuffer();
  buffer.write('''
// Generated file. Please do not edit.

package io.flutter.app;

import android.content.Context;
import androidx.multidex.MultiDex;

/**
 * A utility class that adds MultiDex support for apps that support minSdk 20
 * and below.
 *
 * <p>If the minSdk version is 21 or above, multi dex is natively supported.
 */
public class FlutterMultiDexSupportUtils {
  public static void installMultiDexSupport(Context context) {
    MultiDex.install(context);
  }
}

''');
  utilsFile.writeAsStringSync(buffer.toString(), flush: true);
}

/// Returns true if the FlutterMultiDexSupportUtils.java file exists.
bool multiDexUtilsExists(final Directory projectDir) {
  if (_getMultiDexKeepFile(projectDir).existsSync()) {
    return true;
  }
  return false;
}
