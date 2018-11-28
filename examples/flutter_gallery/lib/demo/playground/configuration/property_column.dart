// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const double _kLabelFontSize = 16.0;
const Color _kLabelColor = Colors.blue;

class PropertyColumn extends StatelessWidget {
  const PropertyColumn({
    @required this.label,
    @required this.widget,
    this.labelFontSize = _kLabelFontSize,
    this.labelColor = _kLabelColor,
  });
  final String label;
  final double labelFontSize;
  final Color labelColor;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 15.0, bottom: 20.0),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: labelFontSize,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: widget,
        ),
      ],
    );
  }
}
