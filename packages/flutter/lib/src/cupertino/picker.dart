// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

const Color _highlighterBorder = const Color(0xFF7F7F7F);

class CupertinoPicker extends StatefulWidget {
  const CupertinoPicker({
    this.diameterRatio,
    this.background,

    this.scrollController,
    @required this.itemExtent,
    @required this.onSelectedItemChanged,
    @required this.children,
  });

  final double diameterRatio;
  final Color background;
  final ListWheelScrollController scrollController;
  final double itemExtent;
  final ValueChanged<int> onSelectedItemChanged;

  final List<Widget> children;

  @override
  State<StatefulWidget> createState() => new CupertinoPickerState();
}

class CupertinoPickerState extends State<CupertinoPicker> {
  int _lastHapticIndex;

  @override
  void initState() {
    super.initState();
  }

  void _handleSelectedItemChanged(int index) {
    if (index != _lastHapticIndex) {
      // Insert haptic feedback with lighter knock.
      _lastHapticIndex = index;
    }

    if (widget.onSelectedItemChanged != null) {
      widget.onSelectedItemChanged(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color foreground = widget.background.withAlpha(100);
    return new DecoratedBox(
      decoration: new BoxDecoration(
        color: widget.background,
      ),
      child: new Stack(
        children: <Widget>[
          new Positioned.fill(
            child: new NotificationListener<ScrollNotification>(
              child: new ListWheelScrollView(
                controller: widget.scrollController,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: widget.diameterRatio,
                itemExtent: widget.itemExtent,
                onSelectedItemChanged: _handleSelectedItemChanged,
                children: widget.children,
              ),
            ),
          ),
          new Positioned.fill(
            child: new IgnorePointer(
              child: new Container(
                decoration: const BoxDecoration(
                  gradient: const LinearGradient(
                    colors: const <Color>[
                      const Color(0xFFFFFFFF),
                      const Color(0xF2FFFFFF),
                      const Color(0xDDFFFFFF),
                      const Color(0x00FFFFFF),
                      const Color(0x00FFFFFF),
                      const Color(0xDDFFFFFF),
                      const Color(0xF2FFFFFF),
                      const Color(0xFFFFFFFF),
                    ],
                    stops: const <double>[
                      0.0, 0.05, 0.09, 0.18, 0.82, 0.91, 0.95, 1.0,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          new IgnorePointer(
            child: new Column(
              children: <Widget>[
                new Expanded(
                  child: new Container(
                    color: foreground,
                  ),
                ),
                new Container(
                  decoration: new BoxDecoration(
                    border: new Border(
                      top: const BorderSide(width: 0.0, color: _highlighterBorder),
                      bottom: const BorderSide(width: 0.0, color: _highlighterBorder),
                    )
                  ),
                  constraints: new BoxConstraints.expand(height: widget.itemExtent),
                ),
                new Expanded(
                  child: new Container(
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
