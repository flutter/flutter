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
  /// Creates a control used for selecting values.
  ///
  /// The [diameterRatio] and [itemExtent] arguments must not be null. The
  /// [itemExtent] must be greater than zero.
  ///
  /// The [backgroundColor] defaults to light gray. It can be set to null to
  /// disable the background painting entirely; this is mildly more efficient
  /// than using [Colors.transparent].
  const CupertinoPicker({
    Key key,
    this.diameterRatio = _kDefaultDiameterRatio,
    this.backgroundColor = _kDefaultBackground,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    @required this.itemExtent,
    @required this.onSelectedItemChanged,
    @required this.children,
  }) : assert(diameterRatio != null),
       assert(diameterRatio > 0.0, RenderListWheelViewport.diameterRatioZeroMessage),
       assert(magnification > 0),
       assert(itemExtent != null),
       assert(itemExtent > 0),
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

  /// [CupertinoPickerItem]s in the picker's scroll wheel.
  final List<CupertinoPickerItem> children;

  @override
  State<StatefulWidget> createState() => new _CupertinoPickerState();
}

class _CupertinoPickerState extends State<CupertinoPicker> {
  int _lastHapticIndex;
  ScrollController _controller;

  @override
  void initState() {
    _controller = widget.scrollController ?? new FixedExtentScrollController();
    super.initState();
  }

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
          child: new _CupertinoPickerSemantics(
            controller: _controller,
            items: widget.children,
            child: new ListWheelScrollView(
              controller: _controller,
              physics: const FixedExtentScrollPhysics(),
              diameterRatio: widget.diameterRatio,
              offAxisFraction: widget.offAxisFraction,
              useMagnifier: widget.useMagnifier,
              magnification: widget.magnification,
              itemExtent: widget.itemExtent,
              onSelectedItemChanged: _handleSelectedItemChanged,
              children: widget.children.map<Widget>((CupertinoPickerItem item) {
                Widget result = new Container(
                  width: item.width,
                  height: item.height,
                  alignment: item.alignment,
                  padding: item.padding,
                  child: new Text(item.value),
                );
                if (item.center)
                  result = new Center(child: result);
                return result;
              }).toList(),
            ),
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

class _CupertinoPickerSemantics extends SingleChildRenderObjectWidget {
  const _CupertinoPickerSemantics({
    @required this.controller,
    @required this.items,
    @required Widget child}) : super(child: child);

  // The currently selected index.
  final FixedExtentScrollController controller;

  // The total number of children, or null if unbounded.
  final List<CupertinoPickerItem> items;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderCupertinoPickerSemantics(
      controller,
      Directionality.of(context),
      items,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderCupertinoPickerSemantics renderObject) {
    renderObject
      ..textDirection = Directionality.of(context)
      ..items = items
      ..controller = controller;
  }
}

class _RenderCupertinoPickerSemantics extends RenderProxyBox {
  _RenderCupertinoPickerSemantics(
    this._controller,
    this._textDirection,
    this._items,
  );

  FixedExtentScrollController get controller => _controller;
  FixedExtentScrollController _controller;
  set controller(FixedExtentScrollController value) {
    if (value != _controller)
      return;
    _controller.removeListener(_handleScrollEvent);
    _controller = value;
    if (_controller.initialItem != null)
      _selectedItem = _controller.initialItem;
    _controller.addListener(_handleScrollEvent);
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value)
      return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  List<CupertinoPickerItem> get items => _items;
  List<CupertinoPickerItem> _items;
  set items(List<CupertinoPickerItem> value) {
    if (value == items)
      return;
    _items = value;
    markNeedsSemanticsUpdate();
  }

  int _selectedItem = 0;

  void _handleScrollEvent() {
    if (controller.selectedItem == _selectedItem)
      return;
    _selectedItem = controller.selectedItem;
    markNeedsSemanticsUpdate();
  }

  void _handleDecrease() {
    if (_controller.selectedItem == 0)
      return;
    _controller.jumpToItem(
      _controller.selectedItem - 1,
    );
  }

  void _handleIncrease() {
    if (_items != null && _controller.selectedItem - 1 == _items.length)
      return;
    _controller.jumpToItem(
      _controller.selectedItem + 1,
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (_items != null && _selectedItem < _items.length - 1) {
      config.onIncrease = _handleIncrease;
      config.increasedValue = _items[_selectedItem + 1].value;
    }
    if (_selectedItem > 0) {
      config.onDecrease = _handleDecrease;
      config.decreasedValue = _items[_selectedItem - 1].value;
    }
    config.value = _items[_selectedItem].value;
    config.textDirection = textDirection;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {}
}

/// The [CupertinoPickerItem] is a value that can be picked from a [CupertinoPicker].
class CupertinoPickerItem {
  /// Create a new [CupertinoPickerItem] from a non-null, non-empty [value].
  const CupertinoPickerItem({
    @required this.value,
    this.center = false,
    this.height,
    this.alignment,
    this.width,
    this.padding,
  }) : assert(value != null),
       assert(value != '');

  /// Whether to center the picker item within its container.
  ///
  /// Defaults to false.
  final bool center;

  /// Padding
  final EdgeInsets padding;

  /// Alignment
  final Alignment alignment;

  /// Width
  final double width;

  /// Height
  final double height;

  /// The value that can be picked.
  final String value;
}