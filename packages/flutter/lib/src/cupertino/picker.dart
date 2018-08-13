// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Color of the 'magnifier' lens border.
const Color _kHighlighterBorder = Color(0xFF7F7F7F);
const Color _kDefaultBackground = Color(0xFFD2D4DB);
/// Eyeballed value comparing with a native picker.
const double _kDefaultDiameterRatio = 1.1;
/// Opacity fraction value that hides the wheel above and below the 'magnifier'
/// lens with the same color as the background.
const double _kForegroundScreenOpacityFraction = 0.7;

/// An iOS-styled picker.
///
/// Displays its children widgets on a wheel for selection and
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
  /// Creates a picker from a concrete list of children.
  ///
  /// The [diameterRatio] and [itemExtent] arguments must not be null. The
  /// [itemExtent] must be greater than zero.
  ///
  /// The [backgroundColor] defaults to light gray. It can be set to null to
  /// disable the background painting entirely; this is mildly more efficient
  /// than using [Colors.transparent].
  ///
  /// The [looping] argument decides whether the child list loops and can be
  /// scrolled infinitely.  If set to true, scrolling past the end of the list
  /// will loop the list back to the beginning.  If set to false, the list will
  /// stop scrolling when you reach the end or the beginning.
  CupertinoPicker({
    Key key,
    this.diameterRatio = _kDefaultDiameterRatio,
    this.backgroundColor = _kDefaultBackground,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    @required this.itemExtent,
    @required this.onSelectedItemChanged,
    @required List<Widget> children,
    bool looping = false,
  }) : assert(children != null),
       assert(diameterRatio != null),
       assert(diameterRatio > 0.0, RenderListWheelViewport.diameterRatioZeroMessage),
       assert(magnification > 0),
       assert(itemExtent != null),
       assert(itemExtent > 0),
       childDelegate = looping
                       ? new ListWheelChildLoopingListDelegate(children: children)
                       : new ListWheelChildListDelegate(children: children),
       super(key: key);

  /// Creates a picker from an [IndexedWidgetBuilder] callback where the builder
  /// is dynamically invoked during layout.
  ///
  /// A child is lazily created when it starts becoming visible in the viewport.
  /// All of the children provided by the builder are cached and reused, so
  /// normally the builder is only called once for each index (except when
  /// rebuilding - the cache is cleared).
  ///
  /// The [itemBuilder] argument must not be null. The [childCount] argument
  /// reflects the number of children that will be provided by the [itemBuilder].
  /// {@macro flutter.widgets.wheelList.childCount}
  ///
  /// The [itemExtent] argument must be non-null and positive.
  ///
  /// The [backgroundColor] defaults to light gray. It can be set to null to
  /// disable the background painting entirely; this is mildly more efficient
  /// than using [Colors.transparent].
  CupertinoPicker.builder({
    Key key,
    this.diameterRatio = _kDefaultDiameterRatio,
    this.backgroundColor = _kDefaultBackground,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    @required this.itemExtent,
    @required this.onSelectedItemChanged,
    @required IndexedWidgetBuilder itemBuilder,
    int childCount,
  }) : assert(itemBuilder != null),
       assert(diameterRatio != null),
       assert(diameterRatio > 0.0, RenderListWheelViewport.diameterRatioZeroMessage),
       assert(magnification > 0),
       assert(itemExtent != null),
       assert(itemExtent > 0),
       childDelegate = new ListWheelChildBuilderDelegate(builder: itemBuilder, childCount: childCount),
       super(key: key);

  /// Relative ratio between this picker's height and the simulated cylinder's diameter.
  ///
  /// Smaller values creates more pronounced curvatures in the scrollable wheel.
  ///
  /// For more details, see [ListWheelScrollView.diameterRatio].
  ///
  /// Must not be null and defaults to `1.1` to visually mimic iOS.
  final double diameterRatio;

  /// Background color behind the children.
  ///
  /// Defaults to a gray color in the iOS color palette.
  ///
  /// This can be set to null to disable the background painting entirely; this
  /// is mildly more efficient than using [Colors.transparent].
  final Color backgroundColor;

  /// {@macro flutter.rendering.wheelList.offAxisFraction}
  final double offAxisFraction;

  /// {@macro flutter.rendering.wheelList.useMagnifier}
  final bool useMagnifier;

  /// {@macro flutter.rendering.wheelList.magnification}
  final double magnification;

  /// A [FixedExtentScrollController] to read and control the current item.
  ///
  /// If null, an implicit one will be created internally.
  final FixedExtentScrollController scrollController;

  /// The uniform height of all children.
  ///
  /// All children will be given the [BoxConstraints] to match this exact
  /// height. Must not be null and must be positive.
  final double itemExtent;

  /// An option callback when the currently centered item changes.
  ///
  /// Value changes when the item closest to the center changes.
  ///
  /// This can be called during scrolls and during ballistic flings. To get the
  /// value only when the scrolling settles, use a [NotificationListener],
  /// listen for [ScrollEndNotification] and read its [FixedExtentMetrics].
  final ValueChanged<int> onSelectedItemChanged;

  /// A delegate that lazily instantiates children.
  final ListWheelChildDelegate childDelegate;

  @override
  State<StatefulWidget> createState() => new _CupertinoPickerState();
}

class _CupertinoPickerState extends State<CupertinoPicker> {
  int _lastHapticIndex;

  void _handleSelectedItemChanged(int index) {
    // Only the haptic engine hardware on iOS devices would produce the
    // intended effects.
    if (defaultTargetPlatform == TargetPlatform.iOS
        && index != _lastHapticIndex) {
      _lastHapticIndex = index;
      HapticFeedback.selectionClick();
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
            gradient: LinearGradient(
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xF2FFFFFF),
                Color(0xDDFFFFFF),
                Color(0x00FFFFFF),
                Color(0x00FFFFFF),
                Color(0xDDFFFFFF),
                Color(0xF2FFFFFF),
                Color(0xFFFFFFFF),
              ],
              stops: <double>[
                0.0, 0.05, 0.09, 0.22, 0.78, 0.91, 0.95, 1.0,
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
    final Color foreground = widget.backgroundColor?.withAlpha(
      (widget.backgroundColor.alpha * _kForegroundScreenOpacityFraction).toInt()
    );

    return new IgnorePointer(
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new Container(
              color: foreground,
            ),
          ),
          new Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(width: 0.0, color: _kHighlighterBorder),
                bottom: BorderSide(width: 0.0, color: _kHighlighterBorder),
              )
            ),
            constraints: new BoxConstraints.expand(
                height: widget.itemExtent * widget.magnification,
            ),
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
    Widget result = new Stack(
      children: <Widget>[
        new Positioned.fill(
          child: new ListWheelScrollView.useDelegate(
            controller: widget.scrollController,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: widget.diameterRatio,
            offAxisFraction: widget.offAxisFraction,
            useMagnifier: widget.useMagnifier,
            magnification: widget.magnification,
            itemExtent: widget.itemExtent,
            onSelectedItemChanged: _handleSelectedItemChanged,
            childDelegate: widget.childDelegate,
          ),
        ),
        _buildGradientScreen(),
        _buildMagnifierScreen(),
      ],
    );
    if (widget.backgroundColor != null) {
      result = new DecoratedBox(
        decoration: new BoxDecoration(
          color: widget.backgroundColor,
        ),
        child: result,
      );
    }
    return result;
  }
}
