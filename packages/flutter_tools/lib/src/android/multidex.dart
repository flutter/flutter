// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:xml/xml.dart';

import '../base/file_system.dart';

// These utility methods are used to generate the code for multidex support as
// well as verifying the project is properly set up.

File _getMultiDexApplicationFile(Directory projectDir) {
  return projectDir.childDirectory('android')
    .childDirectory('app')
    .childDirectory('src')
    .childDirectory('main')
    .childDirectory('java')
    .childDirectory('io')
    .childDirectory('flutter')
    .childDirectory('app')
    .childFile('FlutterMultiDexApplication.java');
}

/// Creates the FlutterMultiDexApplication.java if it does not exist.
void ensureMultiDexApplicationExists(final Directory projectDir) {
  final File applicationFile = _getMultiDexApplicationFile(projectDir);
  if (applicationFile.existsSync()) {
    // This checks for instances of legacy versions of this file. Legacy versions maintained
    // compatibility with v1 embedding by extending FlutterApplication. If we detect this,
    // we replace the file with the modern v2 embedding version.
    if (applicationFile.readAsStringSync().contains('android.app.Application;')) {
      return;
    }
  }
  applicationFile.createSync(recursive: true);

  final StringBuffer buffer = StringBuffer();
  buffer.write('''
// Generated file.
//
// If you wish to remove Flutter's multidex support, delete this entire file.
//
// Modifications to this file should be done in a copy under a different name
// as this file may be regenerated.

package io.flutter.app;

import android.app.Application;
import android.content.Context;
import androidx.annotation.CallSuper;
import androidx.multidex.MultiDex;

/**
 * Extension of {@link android.app.Application}, adding multidex support.
 */
public class FlutterMultiDexApplication extends Application {
  @Override
  @CallSuper
  protected void attachBaseContext(Context base) {
    super.attachBaseContext(base);
    MultiDex.install(this);
  }
}
''');
  applicationFile.writeAsStringSync(buffer.toString(), flush: true);
}

/// Returns true if FlutterMultiDexApplication.java exists.
///
/// This function does not verify the contents of the file.
bool multiDexApplicationExists(final Directory projectDir) {
  if (_getMultiDexApplicationFile(projectDir).existsSync()) {
    return true;
  }
  return false;
}

File _getManifestFile(Directory projectDir) {
  return projectDir.childDirectory('android')
    .childDirectory('app')
    .childDirectory('src')
    .childDirectory('main')
    .childFile('AndroidManifest.xml');
}

/// Returns true if the `app` module AndroidManifest.xml includes the
/// <application android:name="${applicationName}"> attribute.
bool androidManifestHasNameVariable(final Directory projectDir) {
  final File manifestFile = _getManifestFile(projectDir);
  if (!manifestFile.existsSync()) {
    return false;
  }
  XmlDocument document;
  try {
    document = XmlDocument.parse(manifestFile.readAsStringSync());
  } on XmlParserException {
    return false;
  } on FileSystemException {
    return false;
  }
  // Check for the ${androidName} application attribute.
  for (final XmlElement application in document.findAllElements('application')) {
    final String? applicationName = application.getAttribute('android:name');
    if (applicationName == r'${applicationName}') {
      return true;
    }
  }
  return false;
}
