// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Run this example with: flutter run -t lib/basic.dart -d emulator

// This file is used to extract code samples for the README.md file.
// Run update-excerpts if you modify this file.

// #docregion basic-example
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final Uri _url = Uri.parse('https://flutter.dev');

void main() => runApp(
      const MaterialApp(
        home: Material(
          child: Center(
            child: ElevatedButton(
              onPressed: _launchUrl,
              child: Text('Show Flutter homepage'),
            ),
          ),
        ),
      ),
    );

Future<void> _launchUrl() async {
  if (!await launchUrl(_url)) {
    throw 'Could not launch $_url';
  }
}
// #enddocregion basic-example
