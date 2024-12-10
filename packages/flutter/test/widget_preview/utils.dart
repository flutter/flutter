// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/src/widget_preview/widget_preview.dart';

class WidgetPreviewTestScaffolding extends StatelessWidget {
  const WidgetPreviewTestScaffolding({super.key, required this.previews});

  final List<WidgetPreview> previews;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LayoutBuilder(
        builder: (_, BoxConstraints constraints) {
          return WidgetPreviewerWindowConstraints(
            constraints: constraints,
            child: SingleChildScrollView(
              child: Column(
                children: previews,
              ),
            ),
          );
        },
      ),
    );
  }
}
