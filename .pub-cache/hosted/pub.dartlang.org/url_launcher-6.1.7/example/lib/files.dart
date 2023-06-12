// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Run this example with: flutter run -t lib/files.dart -d linux

// This file is used to extract code samples for the README.md file.
// Run update-excerpts if you modify this file.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ElevatedButton(
              onPressed: _openFile,
              child: Text('Open File'),
            ),
          ),
        ),
      ),
    );

Future<void> _openFile() async {
  // Prepare a file within tmp
  final String tempFilePath = p.joinAll(<String>[
    ...p.split(Directory.systemTemp.path),
    'flutter_url_launcher_example.txt'
  ]);
  final File testFile = File(tempFilePath);
  await testFile.writeAsString('Hello, world!');
// #docregion file
  final String filePath = testFile.absolute.path;
  final Uri uri = Uri.file(filePath);

  if (!File(uri.toFilePath()).existsSync()) {
    throw '$uri does not exist!';
  }
  if (!await launchUrl(uri)) {
    throw 'Could not launch $uri';
  }
// #enddocregion file
}
