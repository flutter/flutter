// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Flutter code sample for OverlayPortal

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text('OverlayPortal Example')),
        body: const Center(child: ClickableTooltipWidget()),
      )
    );
  }
}

class ClickableTooltipWidget extends StatefulWidget {
  const ClickableTooltipWidget({super.key});

  @override
  State<StatefulWidget> createState() => ClickableTooltipWidgetState();
}

class ClickableTooltipWidgetState extends State<ClickableTooltipWidget> {
  bool shouldShowTooltip = false;

  void _onTap() {
    setState(() { shouldShowTooltip = !shouldShowTooltip; });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(fontSize: 50),
      child: GestureDetector(
        onTap: _onTap,
        child: OverlayPortal(
          overlayInfo: OverlayInfo.of(context),
          overlayChild: !shouldShowTooltip
            ? null
            : const Positioned(
              right: 50,
              bottom: 50,
              child: ColoredBox(
                color: Colors.amberAccent,
                child: Text('tooltip'),
              )
            ),
          child: const Text('Press to show/hide tooltip'),
        ),
      ),
    );
  }
}
