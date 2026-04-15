// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

/// Adds [keyPairs] to the metadata of the Flutter Android app's manifest
/// specified at [testDirectory].
///
/// If any one key in [keyPairs] is already in the manifest, then its value
/// is overriden with the value specified in [keyPairs].
///
/// [testDirectory] is assumed to point to the root of the Flutter project.
void addMetadataToManifest(String projectDirectory, List<(String, String)> keyPairs) {
  final String manifestPath = path.join(
    projectDirectory,
    'android',
    'app',
    'src',
    'main',
    'AndroidManifest.xml',
  );
  final file = File(manifestPath);

  if (!file.existsSync()) {
    throw Exception('AndroidManifest.xml not found at $manifestPath');
  }

  final String xmlStr = file.readAsStringSync();
  final xmlDoc = XmlDocument.parse(xmlStr);
  final XmlElement applicationNode = xmlDoc.findAllElements('application').first;

  // Check if the meta-data node already exists.
  for (final (String key, String value) in keyPairs) {
    final Iterable<XmlElement> existingMetaData = applicationNode
        .findAllElements('meta-data')
        .where((XmlElement node) => node.getAttribute('android:name') == key);

    if (existingMetaData.isNotEmpty) {
      final XmlElement existingEntry = existingMetaData.first;
      existingEntry.setAttribute('android:value', value);
    } else {
      final metaData = XmlElement(XmlName('meta-data'), <XmlAttribute>[
        XmlAttribute(XmlName('android:name'), key),
        XmlAttribute(XmlName('android:value'), value),
      ]);
      applicationNode.children.add(metaData);
    }
  }

  file.writeAsStringSync(xmlDoc.toXmlString(pretty: true, indent: '    '));
}
