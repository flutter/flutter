// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [Image.errorBuilder].

void main() => runApp(const ErrorBuilderExampleApp());

class ErrorBuilderExampleApp extends StatelessWidget {
  const ErrorBuilderExampleApp({super.key});

  @override
  Widget build(final BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: ErrorBuilderExample(),
        ),
      ),
    );
  }
}

class ErrorBuilderExample extends StatelessWidget {
  const ErrorBuilderExample({super.key});

  @override
  Widget build(final BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Image.network(
        'https://example.does.not.exist/image.jpg',
        errorBuilder: (final BuildContext context, final Object exception, final StackTrace? stackTrace) {
          // Appropriate logging or analytics, e.g.
          // myAnalytics.recordError(
          //   'An error occurred loading "https://example.does.not.exist/image.jpg"',
          //   exception,
          //   stackTrace,
          // );
          return const Text('😢');
        },
      ),
    );
  }
}
