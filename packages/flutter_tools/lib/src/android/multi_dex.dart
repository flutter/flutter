// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:xml/xml.dart';

import '../artifacts.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/deferred_component.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../flutter_manifest.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import 'android_builder.dart';
import 'android_studio.dart';
import 'gradle_errors.dart';
import 'gradle_utils.dart';

File _getMultiDexKeepFile(Directory projectDir) {
  return projectDir.childDirectory('android')
    .childDirectory('app')
    .childFile('multidex-flutter-keepfile.txt');
}

// This creates a 
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

bool multiDexKeepFileExists(final Directory projectDir) {
  if (_getMultiDexKeepFile(projectDir).existsSync()) {
    return true;
  }
  return false;
}

// This creates a 
void ensureMultiDexUtilsExists(final Directory projectDir) {
  final File utilsFile = projectDir.childDirectory('android')
    .childDirectory('app')
    .childDirectory('src')
    .childDirectory('main')
    .childDirectory('java')
    .childDirectory('io')
    .childDirectory('flutter')
    .childDirectory('app')
    .childFile('FlutterMultiDexSupportUtils.java');
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
