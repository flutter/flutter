// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TextRenderingApp());
}

/// A test application that renders text with various font weights and colors
/// to validate text rendering in integration tests.
class TextRenderingApp extends StatelessWidget {
  /// Creates a [TextRenderingApp].
  const TextRenderingApp({super.key});

  static const String _testText =
      'the quick brown fox jumped over the lazy dog!.?';

  Widget _buildTextSection({
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Expanded(
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            for (final FontWeight weight in <FontWeight>[
              FontWeight.w100,
              FontWeight.normal,
              FontWeight.bold,
            ])
              Text(
                _testText,
                style: GoogleFonts.roboto(
                  color: textColor,
                  fontSize: 20.0,
                  fontWeight: weight,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          key: const Key('text_rendering_canvas'),
          color: Colors.grey[850],
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildTextSection(
                textColor: Colors.white,
                backgroundColor: Colors.black,
              ),
              const SizedBox(height: 16.0),
              _buildTextSection(
                textColor: Colors.black,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 16.0),
              _buildTextSection(
                textColor: Colors.green,
                backgroundColor: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
