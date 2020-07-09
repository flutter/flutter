// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

/// Color of the 'magnifier' lens border.
const Color _kHighlighterBorder = CupertinoDynamicColor.withBrightness(
  color: Color(0x33000000),
  darkColor: Color(0x33FFFFFF),
);
// Eyeballed values comparing with a native picker to produce the right
// curvatures and densities.
const double _kDefaultDiameterRatio = 1.07;
const double _kDefaultPerspective = 0.003;
const double _kSqueeze = 1.45;

// Opacity fraction value that dims the wheel above and below the "magnifier"
// lens.
const double _kOverAndUnderCenterOpacity = 0.447;

/// An iOS-styled picker.
///
/// Displays its children widgets on a wheel for selection and
/// calls back when the currently selected item changes.
///
/// By default, the first child in `children` will be the initially selected child.
/// The index of a different child can be specified in [scrollController], to make
/// that child the initially selected child.
///
/// Can be used with [showCupertinoModalPopup] to display the picker modally at the
/// bottom of the screen. When calling [showCupertinoModalPopup], be sure to set
/// `semanticsDismissible` to true to enable dismissing the modal via semantics.
///
/// Sizes itself to its parent. All children are sized to the same size based
/// on [itemExtent].
///
/// By default, descendent texts are shown with [CupertinoTextThemeData.pickerTextStyle].
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
  /// The [backgroundColor] defaults to null, which disables background painting entirely.
  /// (i.e. the picker is going to have a completely transparent background), to match
  /// the native UIPicker and UIDatePicker. Also, if it has transparency, no gradient
  /// effect will be rendered.
  ///
  /// The [scrollController] argument can be used to specify a custom
  /// [FixedExtentScrollController] for programmatically reading or changing
  /// the current picker index or for selecting an initial index value.
  ///
  /// The [looping] argument decides whether the child list loops and can be
  /// scrolled infinitely.  If set to true, scrolling past the end of the list
  /// will loop the list back to the beginning.  If set to false, the list will
  /// stop scrolling when you reach the end or the beginning.
  CupertinoPicker({
    Key key,
    this.diameterRatio = _kDefaultDiameterRatio,
    this.backgroundColor,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    this.squeeze = _kSqueeze,
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
       assert(squeeze != null),
       assert(squeeze > 0),
       childDelegate = looping
                       ? ListWheelChildLoopingListDelegate(children: children)
                       : ListWheelChildListDelegate(children: children),
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
  /// The [backgroundColor] defaults to null, which disables background painting entirely.
  /// (i.e. the picker is going to have a completely transparent background), to match
  /// the native UIPicker and UIDatePicker.
  CupertinoPicker.builder({
    Key key,
    this.diameterRatio = _kDefaultDiameterRatio,
    this.backgroundColor,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    this.squeeze = _kSqueeze,
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
       assert(squeeze != null),
       assert(squeeze > 0),
       childDelegate = ListWheelChildBuilderDelegate(builder: itemBuilder, childCount: childCount),
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
  /// Defaults to null, which disables background painting entirely.
  /// (i.e. the picker is going to have a completely transparent background), to match
  /// the native UIPicker and UIDatePicker.
  ///
  /// Any alpha value less 255 (fully opaque) will cause the removal of the
  /// wheel list edge fade gradient from rendering of the widget.
  final Color backgroundColor;

  /// {@macro flutter.rendering.wheelList.offAxisFraction}
  final double offAxisFraction;

  /// {@macro flutter.rendering.wheelList.useMagnifier}
  final bool useMagnifier;

  /// {@macro flutter.rendering.wheelList.magnification}
  final double magnification;

  /// A [FixedExtentScrollController] to read and control the current item, and
  /// to set the initial item.
  ///
  /// If null, an implicit one will be created internally.
  final FixedExtentScrollController scrollController;

  /// The uniform height of all children.
  ///
  /// All children will be given the [BoxConstraints] to match this exact
  /// height. Must not be null and must be positive.
  final double itemExtent;

  /// {@macro flutter.rendering.wheelList.squeeze}
  ///
  /// Defaults to `1.45` to visually mimic iOS.
  final double squeeze;

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
  State<StatefulWidget> createState() => _CupertinoPickerState();
}

class _CupertinoPickerState extends State<CupertinoPicker> {
  int _lastHapticIndex;
  FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _controller = FixedExtentScrollController();
    }
  }

  @override
  void didUpdateWidget(CupertinoPicker oldWidget) {
    if (widget.scrollController != null && oldWidget.scrollController == null) {
      _controller = null;
    } else if (widget.scrollController == null && oldWidget.scrollController != null) {
      assert(_controller == null);
      _controller = FixedExtentScrollController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _handleSelectedItemChanged(int index) {
    // Only the haptic engine hardware on iOS devices would produce the
    // intended effects.
    bool hasSuitableHapticHardware;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        hasSuitableHapticHardware = true;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        hasSuitableHapticHardware = false;
        break;
    }
    assert(hasSuitableHapticHardware != null);
    if (hasSuitableHapticHardware && index != _lastHapticIndex) {
      _lastHapticIndex = index;
      HapticFeedback.selectionClick();
    }

    if (widget.onSelectedItemChanged != null) {
      widget.onSelectedItemChanged(index);
    }
  }

  /// Draws the magnifier borders.
  Widget _buildMagnifierScreen() {
    final Color resolvedBorderColor = CupertinoDynamicColor.resolve(_kHighlighterBorder, context);

    return IgnorePointer(
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 0.0, color: resolvedBorderColor),
              bottom: BorderSide(width: 0.0, color: resolvedBorderColor),
            ),
          ),
          constraints: BoxConstraints.expand(
            height: widget.itemExtent * widget.magnification,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color resolvedBackgroundColor = CupertinoDynamicColor.resolve(widget.backgroundColor, context);

    final Widget result = DefaultTextStyle(
      style: CupertinoTheme.of(context).textTheme.pickerTextStyle,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _CupertinoPickerSemantics(
              scrollController: widget.scrollController ?? _controller,
              child: ListWheelScrollView.useDelegate(
                controller: widget.scrollController ?? _controller,
                physics: const FixedExtentScrollPhysics(),
                diameterRatio: widget.diameterRatio,
                perspective: _kDefaultPerspective,
                offAxisFraction: widget.offAxisFraction,
                useMagnifier: widget.useMagnifier,
                magnification: widget.magnification,
                overAndUnderCenterOpacity: _kOverAndUnderCenterOpacity,
                itemExtent: widget.itemExtent,
                squeeze: widget.squeeze,
                onSelectedItemChanged: _handleSelectedItemChanged,
                childDelegate: widget.childDelegate,
              ),
            ),
          ),
          _buildMagnifierScreen(),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(color: resolvedBackgroundColor),
      child: result,
    );
  }
}

// Turns the scroll semantics of the ListView into a single adjustable semantics
// node. This is done by removing all of the child semantics of the scroll
// wheel and using the scroll indexes to look up the current, previous, and
// next semantic label. This label is then turned into the value of a new
// adjustable semantic node, with adjustment callbacks wired to move the
// scroll controller.
class _CupertinoPickerSemantics extends SingleChildRenderObjectWidget {
  const _CupertinoPickerSemantics({
    Key key,
    Widget child,
    @required this.scrollController,
  }) : super(key: key, child: child);

  final FixedExtentScrollController scrollController;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderCupertinoPickerSemantics(scrollController, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, covariant _RenderCupertinoPickerSemantics renderObject) {
    renderObject
      ..textDirection = Directionality.of(context)
      ..controller = scrollController;
  }
}

class _RenderCupertinoPickerSemantics extends RenderProxyBox {
  _RenderCupertinoPickerSemantics(FixedExtentScrollController controller, this._textDirection) {
    this.controller = controller;
  }

  FixedExtentScrollController get controller => _controller;
  FixedExtentScrollController _controller;
  set controller(FixedExtentScrollController value) {
    if (value == _controller)
      return;
    if (_controller != null)
      _controller.removeListener(_handleScrollUpdate);
    else
      _currentIndex = value.initialItem ?? 0;
    value.addListener(_handleScrollUpdate);
    _controller = value;
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (textDirection == value)
      return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  int _currentIndex = 0;

  void _handleIncrease() {
    controller.jumpToItem(_currentIndex + 1);
  }

  void _handleDecrease() {
    if (_currentIndex == 0)
      return;
    controller.jumpToItem(_currentIndex - 1);
  }

  void _handleScrollUpdate() {
    if (controller.selectedItem == _currentIndex)
      return;
    _currentIndex = controller.selectedItem;
    markNeedsSemanticsUpdate();
  }
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.textDirection = textDirection;
  }

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config, Iterable<SemanticsNode> children) {
    if (children.isEmpty)
      return super.assembleSemanticsNode(node, config, children);
    final SemanticsNode scrollable = children.first;
    final Map<int, SemanticsNode> indexedChildren = <int, SemanticsNode>{};
    scrollable.visitChildren((SemanticsNode child) {
      assert(child.indexInParent != null);
      indexedChildren[child.indexInParent] = child;
      return true;
    });
    if (indexedChildren[_currentIndex] == null) {
      return node.updateWith(config: config);
    }
    config.value = indexedChildren[_currentIndex].label;
    final SemanticsNode previousChild = indexedChildren[_currentIndex - 1];
    final SemanticsNode nextChild = indexedChildren[_currentIndex + 1];
    if (nextChild != null) {
      config.increasedValue = nextChild.label;
      config.onIncrease = _handleIncrease;
    }
    if (previousChild != null) {
      config.decreasedValue = previousChild.label;
      config.onDecrease = _handleDecrease;
    }
    node.updateWith(config: config);
  }
}
