// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart'
    show getGradlewFileName;
import 'package:flutter_tools/src/base/io.dart';
import 'package:xml/xml.dart';

import '../src/common.dart';
import 'test_utils.dart';

final XmlElement pureHttpIntentFilter = XmlElement(
  XmlName('intent-filter'),
  <XmlAttribute>[XmlAttribute(XmlName('autoVerify', 'android'), 'true')],
  <XmlElement>[
    XmlElement(
      XmlName('action'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.action.VIEW')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.DEFAULT')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.BROWSABLE')],
    ),
    XmlElement(
      XmlName('data'),
      <XmlAttribute>[
        XmlAttribute(XmlName('scheme', 'android'), 'http'),
        XmlAttribute(XmlName('host', 'android'), 'pure-http.com'),
      ],
    ),
  ],
);

final XmlElement nonHttpIntentFilter = XmlElement(
  XmlName('intent-filter'),
  <XmlAttribute>[XmlAttribute(XmlName('autoVerify', 'android'), 'true')],
  <XmlElement>[
    XmlElement(
      XmlName('action'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.action.VIEW')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.DEFAULT')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.BROWSABLE')],
    ),
    XmlElement(
      XmlName('data'),
      <XmlAttribute>[
        XmlAttribute(XmlName('scheme', 'android'), 'custom'),
        XmlAttribute(XmlName('host', 'android'), 'custom.com'),
      ],
    ),
  ],
);

final XmlElement hybridIntentFilter = XmlElement(
  XmlName('intent-filter'),
  <XmlAttribute>[XmlAttribute(XmlName('autoVerify', 'android'), 'true')],
  <XmlElement>[
    XmlElement(
      XmlName('action'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.action.VIEW')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.DEFAULT')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.BROWSABLE')],
    ),
    XmlElement(
      XmlName('data'),
      <XmlAttribute>[
        XmlAttribute(XmlName('scheme', 'android'), 'custom'),
        XmlAttribute(XmlName('host', 'android'), 'hybrid.com'),
      ],
    ),
    XmlElement(
      XmlName('data'),
      <XmlAttribute>[
        XmlAttribute(XmlName('scheme', 'android'), 'http'),
      ],
    ),
  ],
);

final XmlElement nonAutoVerifyIntentFilter = XmlElement(
  XmlName('intent-filter'),
  <XmlAttribute>[],
  <XmlElement>[
    XmlElement(
      XmlName('action'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.action.VIEW')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.DEFAULT')],
    ),
    XmlElement(
      XmlName('category'),
      <XmlAttribute>[XmlAttribute(XmlName('name', 'android'), 'android.intent.category.BROWSABLE')],
    ),
    XmlElement(
      XmlName('data'),
      <XmlAttribute>[
        XmlAttribute(XmlName('scheme', 'android'), 'http'),
        XmlAttribute(XmlName('host', 'android'), 'non-auto-verify.com'),
      ],
    ),
  ],
);

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext(
      'gradle task exists named print<mode>AppLinkDomains that prints app link domains', () async {
    // Create a new flutter project.
    final String flutterBin =
    fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      tempDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    // Adds intent filters for app links
    final String androidManifestPath =  fileSystem.path.join(tempDir.path, 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
    final io.File androidManifestFile = io.File(androidManifestPath);
    final XmlDocument androidManifest = XmlDocument.parse(androidManifestFile.readAsStringSync());
    final XmlElement activity = androidManifest.findAllElements('activity').first;
    activity.children.add(pureHttpIntentFilter);
    activity.children.add(nonHttpIntentFilter);
    activity.children.add(hybridIntentFilter);
    activity.children.add(nonAutoVerifyIntentFilter);
    androidManifestFile.writeAsStringSync(androidManifest.toString(), flush: true);

    // Ensure that gradle files exists from templates.
    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--config-only',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);

    final Directory androidApp = tempDir.childDirectory('android');
    result = await processManager.run(<String>[
      '.${platform.pathSeparator}${getGradlewFileName(platform)}',
      ...getLocalEngineArguments(),
      '-q', // quiet output.
      'printDebugAppLinkDomains',
    ], workingDirectory: androidApp.path);

    expect(result.exitCode, 0);

    const List<String> expectedLines = <String>[
      // Should only pick up the pure and hybrid intent filters
      'Domain: pure-http.com',
      'Domain: hybrid.com',
    ];
    final List<String> actualLines = LineSplitter.split(result.stdout.toString()).toList();
    expect(const ListEquality<String>().equals(actualLines, expectedLines), isTrue);
  });
}
