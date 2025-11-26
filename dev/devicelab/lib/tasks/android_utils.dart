// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

void addMetadataToManifest(String testDirectory, List<(String, String)> keyPairs) {
  final String manifestPath = path.join(
    testDirectory,
    'android',
    'app',
    'src',
    'main',
    'AndroidManifest.xml',
  );
  final File file = File(manifestPath);

  if (!file.existsSync()) {
    throw Exception('AndroidManifest.xml not found at $manifestPath');
  }

  final String xmlStr = file.readAsStringSync();
  final XmlDocument xmlDoc = XmlDocument.parse(xmlStr);
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
      final XmlElement metaData = XmlElement(XmlName('meta-data'), <XmlAttribute>[
        XmlAttribute(XmlName('android:name'), key),
        XmlAttribute(XmlName('android:value'), value),
      ]);
      applicationNode.children.add(metaData);
    }
  }

  file.writeAsStringSync(xmlDoc.toXmlString(pretty: true, indent: '    '));
}
