import 'dart:ui' as ui;

import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: SelectionArea(
          child: DefaultSelectionStyle.merge(
            selectionHeightStyle: ui.BoxHeightStyle.max,
            child: const Center(
              child: Text(
                'Select this text. The line height is larger than the glyph height.',
                style: TextStyle(fontSize: 20, height: 3),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
