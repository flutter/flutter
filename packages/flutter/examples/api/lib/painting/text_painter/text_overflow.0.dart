// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Flutter code sample for [TextOverflow].

void main() => runApp(const ExampleApp());

const Color _background = Color(0xFFFFFFFF);
const Color _foreground = Color(0xFF202124);
const Color _accent = Color(0xFF1A73E8);
const Color _outline = Color(0xFFBDC1C6);

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: _background,
      textStyle: const TextStyle(fontSize: 14.0, color: _foreground),
      builder: (BuildContext context, Widget? child) =>
          const TextOverflowExample(),
    );
  }
}

class TextOverflowExample extends StatefulWidget {
  const TextOverflowExample({super.key});

  @override
  State<TextOverflowExample> createState() => _TextOverflowExampleState();
}

class _TextOverflowExampleState extends State<TextOverflowExample> {
  static const String _path =
      '/Users/someone/Documents/reports/2019/november/summary.txt';
  static const double _minWidth = 60.0;
  static const double _maxWidth = 320.0;

  TextOverflow _overflow = TextOverflow.ellipsisStart;
  double _width = 240.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Changing the overflow mode or the width updates this Text in
            // place; the paragraph recomputes where the ellipsis goes as part
            // of its next layout.
            SizedBox(
              width: _width,
              child: DecoratedBox(
                decoration: BoxDecoration(border: Border.all(color: _outline)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _path,
                    overflow: _overflow,
                    semanticsLabel: _path,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: <Widget>[
                for (final TextOverflow overflow in <TextOverflow>[
                  TextOverflow.ellipsisStart,
                  TextOverflow.ellipsisMiddle,
                  TextOverflow.ellipsis,
                ])
                  _OverflowButton(
                    overflow: overflow,
                    selected: overflow == _overflow,
                    onTap: () => setState(() => _overflow = overflow),
                  ),
              ],
            ),
            const SizedBox(height: 24.0),
            // Drag horizontally to change how much room the text has to fit in.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (DragUpdateDetails details) {
                setState(() {
                  _width = clampDouble(
                    _width + details.delta.dx,
                    _minWidth,
                    _maxWidth,
                  );
                });
              },
              child: SizedBox(
                width: _maxWidth,
                child: Column(
                  children: <Widget>[
                    Align(
                      // Map the width onto the -1 to 1 range Alignment uses.
                      alignment: Alignment(
                        (_width - _minWidth) / (_maxWidth - _minWidth) * 2.0 -
                            1.0,
                        0.0,
                      ),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox.square(dimension: 20.0),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text('Drag to resize the box (${_width.round()} px)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowButton extends StatelessWidget {
  const _OverflowButton({
    required this.overflow,
    required this.selected,
    required this.onTap,
  });

  final TextOverflow overflow;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? _accent : _background,
          border: Border.all(color: selected ? _accent : _outline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            overflow.name,
            style: TextStyle(color: selected ? _background : _foreground),
          ),
        ),
      ),
    );
  }
}
