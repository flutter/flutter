// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Color of the 'magnifier' lens border.
const Color _kHighlighterBorder = const Color(0xFF7F7F7F);
const Color _kDefaultBackground = const Color(0xFFD2D4DB);
/// Eyeballed value comparing with a native picker.
const double _kDefaultDiameterRatio = 1.1;
/// A 255 based opacity value that hides the wheel above and below the 'magnifier' lens.
const int _kForegroundScreenOpacity = 180;

/// An iOS-styled picker.
///
/// Displays the provided [children] widgets on a wheel for selection and
/// calls back when the currently selected item changes.
///
/// Can be used with [showModalBottomSheet] to display the picker modally at the
/// bottom of the screen.
///
/// See also:
///
///  * [ListWheelScrollView], the generic widget backing this picker without
///    the iOS design specific chrome.
///  * <https://developer.apple.com/ios/human-interface-guidelines/controls/pickers/>
class CupertinoPicker extends StatefulWidget {
  const CupertinoPicker({
    this.diameterRatio: _kDefaultDiameterRatio,
    this.backgroundColor: _kDefaultBackground,
    this.scrollController,
    @required this.itemExtent,
    @required this.onSelectedItemChanged,
    @required this.children,
  }) : assert(diameterRatio != null && diameterRatio > 0.0),
       assert(backgroundColor != null),
       assert(itemExtent != null && itemExtent > 0.0);

  /// Relative ratio between this picker's height and the simulated cylinder's diameter.
  ///
  /// Smaller values creates more pronounced curvatures in the scrollable wheel.
  ///
  /// For more details, see [ListWheelScrollView.diameterRatio].
  ///
  /// Must not be null and defaults to 1.1 to visually mimic iOS.
  final double diameterRatio;

  /// Background color behind the children.
  ///
  /// Must not be null.
  final Color backgroundColor;

  /// A [FixedExtentScrollController] to read and control the current item.
  ///
  /// If null, an implicit one will be created internall.
  final FixedExtentScrollController scrollController;

  /// The uniform height of all children.
  ///
  /// All children will be given the [BoxConstraints] to match this exact
  /// height. Must be positive.
  final double itemExtent;

  /// An option callback when the current centered item changes.
  ///
  /// Value changes when the item closest to the center changes. This can be
  /// called during scrolls and during ballistic flings. To get the value only
  /// when the scrolling settles, use a [NotificationListener], listen for
  /// [ScrollEndNotification] and read its [FixedExtentMetrics].
  final ValueChanged<int> onSelectedItemChanged;

  /// [Widget]s in the picker's scroll wheel.
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
      // TODO(xster): Insert haptic feedback with lighter knock.
      // https://github.com/flutter/flutter/issues/13710.
      _lastHapticIndex = index;
    }

    if (widget.onSelectedItemChanged != null) {
      widget.onSelectedItemChanged(index);
    }
  }

  /// Makes the fade to white edge gradients.
  Widget _buildGradientScreen() {
    return new Positioned.fill(
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
    );
  }

  /// Makes the magnifier lens look so that the colors are normal through
  /// the lens and partially grayed out around it.
  Widget _buildMagnifierScreen() {
    final Color foreground = widget.backgroundColor.withAlpha(180);

    return new IgnorePointer(
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
                top: const BorderSide(width: 0.0, color: _kHighlighterBorder),
                bottom: const BorderSide(width: 0.0, color: _kHighlighterBorder),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return new DecoratedBox(
      decoration: new BoxDecoration(
        color: widget.backgroundColor,
      ),
      child: new Stack(
        children: <Widget>[
          new Positioned.fill(
            child: new ListWheelScrollView(
              controller: widget.scrollController,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: widget.diameterRatio,
              itemExtent: widget.itemExtent,
              onSelectedItemChanged: _handleSelectedItemChanged,
              children: widget.children,
            ),
          ),
          _buildGradientScreen(),
          _buildMagnifierScreen(),
        ],
      ),
    );
  }
}
