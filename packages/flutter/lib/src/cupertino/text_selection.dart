// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'button.dart';
import 'colors.dart';
import 'localizations.dart';
import 'theme.dart';

// Read off from the output on iOS 12. This color does not vary with the
// application's theme color.
const double _kSelectionHandleOverlap = 1.5;
// Extracted from https://developer.apple.com/design/resources/.
const double _kSelectionHandleRadius = 6;

// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;
// Minimal padding from tip of the selection toolbar arrow to horizontal edges of the
// screen. Eyeballed value.
const double _kArrowScreenPadding = 26.0;

// Vertical distance between the tip of the arrow and the line of text the arrow
// is pointing to. The value used here is eyeballed.
const double _kToolbarContentDistance = 8.0;
// Values derived from https://developer.apple.com/design/resources/.
// 92% Opacity ~= 0xEB

// Values extracted from https://developer.apple.com/design/resources/.
// The height of the toolbar, including the arrow.
const double _kToolbarHeight = 43.0;
const Size _kToolbarArrowSize = Size(14.0, 7.0);
const Radius _kToolbarBorderRadius = Radius.circular(8);
// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const Color _kToolbarBackgroundColor = Color(0xEB202020);
const Color _kToolbarDividerColor = Color(0xFF808080);

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.white,
);

const TextStyle _kToolbarButtonDisabledFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.inactiveGray,
);

// Eyeballed value.
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 10.0, horizontal: 18.0);

// Generates the child that's passed into CupertinoTextSelectionToolbar.
class _CupertinoTextSelectionToolbarWrapper extends StatefulWidget {
  const _CupertinoTextSelectionToolbarWrapper({
    Key key,
    this.arrowTipX,
    this.barTopY,
    this.clipboardStatus,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.isArrowPointingDown,
  }) : super(key: key);

  final double arrowTipX;
  final double barTopY;
  final ClipboardStatusNotifier clipboardStatus;
  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;
  final bool isArrowPointingDown;

  @override
  _CupertinoTextSelectionToolbarWrapperState createState() => _CupertinoTextSelectionToolbarWrapperState();
}

class _CupertinoTextSelectionToolbarWrapperState extends State<_CupertinoTextSelectionToolbarWrapper> {
  ClipboardStatusNotifier _clipboardStatus;

  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    _clipboardStatus = widget.clipboardStatus ?? ClipboardStatusNotifier();
    _clipboardStatus.addListener(_onChangedClipboardStatus);
    _clipboardStatus.update();
  }

  @override
  void didUpdateWidget(_CupertinoTextSelectionToolbarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clipboardStatus == null && widget.clipboardStatus != null) {
      _clipboardStatus.removeListener(_onChangedClipboardStatus);
      _clipboardStatus.dispose();
      _clipboardStatus = widget.clipboardStatus;
    } else if (oldWidget.clipboardStatus != null) {
      if (widget.clipboardStatus == null) {
        _clipboardStatus = ClipboardStatusNotifier();
        _clipboardStatus.addListener(_onChangedClipboardStatus);
        oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
      } else if (widget.clipboardStatus != oldWidget.clipboardStatus) {
        _clipboardStatus = widget.clipboardStatus;
        _clipboardStatus.addListener(_onChangedClipboardStatus);
        oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
      }
    }
    if (widget.handlePaste != null) {
      _clipboardStatus.update();
    }
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, this can be disposed after its creator has
    // already disposed _clipboardStatus.
    if (!_clipboardStatus.disposed) {
      _clipboardStatus.removeListener(_onChangedClipboardStatus);
      if (widget.clipboardStatus == null) {
        _clipboardStatus.dispose();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't render the menu until the state of the clipboard is known.
    if (widget.handlePaste != null
        && _clipboardStatus.value == ClipboardStatus.unknown) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    final List<Widget> items = <Widget>[];
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    final EdgeInsets arrowPadding = widget.isArrowPointingDown
      ? EdgeInsets.only(bottom: _kToolbarArrowSize.height)
      : EdgeInsets.only(top: _kToolbarArrowSize.height);
    final Widget onePhysicalPixelVerticalDivider =
        SizedBox(width: 1.0 / MediaQuery.of(context).devicePixelRatio);

    void addToolbarButton(
      String text,
      VoidCallback onPressed,
    ) {
      if (items.isNotEmpty) {
        items.add(onePhysicalPixelVerticalDivider);
      }

      items.add(CupertinoButton(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: _kToolbarButtonFontStyle,
        ),
        borderRadius: null,
        color: _kToolbarBackgroundColor,
        minSize: _kToolbarHeight,
        onPressed: onPressed,
        padding: _kToolbarButtonPadding.add(arrowPadding),
        pressedOpacity: 0.7,
      ));
    }

    if (widget.handleCut != null) {
      addToolbarButton(localizations.cutButtonLabel, widget.handleCut);
    }
    if (widget.handleCopy != null) {
      addToolbarButton(localizations.copyButtonLabel, widget.handleCopy);
    }
    if (widget.handlePaste != null
        && _clipboardStatus.value == ClipboardStatus.pasteable) {
      addToolbarButton(localizations.pasteButtonLabel, widget.handlePaste);
    }
    if (widget.handleSelectAll != null) {
      addToolbarButton(localizations.selectAllButtonLabel, widget.handleSelectAll);
    }

    return CupertinoTextSelectionToolbar._(
      barTopY: widget.barTopY,
      arrowTipX: widget.arrowTipX,
      isArrowPointingDown: widget.isArrowPointingDown,
      child: items.isEmpty ? null : _CupertinoTextSelectionToolbarContent(
        isArrowPointingDown: widget.isArrowPointingDown,
        children: items,
      ),
    );
  }
}

/// An iOS-style toolbar that appears in response to text selection.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting text.
///
/// See also:
///
///  * [TextSelectionControls.buildToolbar], where [CupertinoTextSelectionToolbar]
///    will be used to build an iOS-style toolbar.
@visibleForTesting
class CupertinoTextSelectionToolbar extends SingleChildRenderObjectWidget {
  const CupertinoTextSelectionToolbar._({
    Key key,
    double barTopY,
    double arrowTipX,
    bool isArrowPointingDown,
    Widget child,
  }) : _barTopY = barTopY,
       _arrowTipX = arrowTipX,
       _isArrowPointingDown = isArrowPointingDown,
       super(key: key, child: child);

  // The y-coordinate of toolbar's top edge, in global coordinate system.
  final double _barTopY;

  // The y-coordinate of the tip of the arrow, in global coordinate system.
  final double _arrowTipX;

  // Whether the arrow should point down and be attached to the bottom
  // of the toolbar, or point up and be attached to the top of the toolbar.
  final bool _isArrowPointingDown;

  @override
  _ToolbarRenderBox createRenderObject(BuildContext context) => _ToolbarRenderBox(_barTopY, _arrowTipX, _isArrowPointingDown, null);

  @override
  void updateRenderObject(BuildContext context, _ToolbarRenderBox renderObject) {
    renderObject
      ..barTopY = _barTopY
      ..arrowTipX = _arrowTipX
      ..isArrowPointingDown = _isArrowPointingDown;
  }
}

class _ToolbarParentData extends BoxParentData {
  // The x offset from the tip of the arrow to the center of the toolbar.
  // Positive if the tip of the arrow has a larger x-coordinate than the
  // center of the toolbar.
  double arrowXOffsetFromCenter;
  @override
  String toString() => 'offset=$offset, arrowXOffsetFromCenter=$arrowXOffsetFromCenter';
}

class _ToolbarRenderBox extends RenderShiftedBox {
  _ToolbarRenderBox(
    this._barTopY,
    this._arrowTipX,
    this._isArrowPointingDown,
    RenderBox child,
  ) : super(child);


  @override
  bool get isRepaintBoundary => true;

  double _barTopY;
  set barTopY(double value) {
    if (_barTopY == value) {
      return;
    }
    _barTopY = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  double _arrowTipX;
  set arrowTipX(double value) {
    if (_arrowTipX == value) {
      return;
    }
    _arrowTipX = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  bool _isArrowPointingDown;
  set isArrowPointingDown(bool value) {
    if (_isArrowPointingDown == value) {
      return;
    }
    _isArrowPointingDown = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  final BoxConstraints heightConstraint = const BoxConstraints.tightFor(height: _kToolbarHeight);

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;
    size = constraints.biggest;

    if (child == null) {
      return;
    }
    final BoxConstraints enforcedConstraint = constraints
      .deflate(const EdgeInsets.symmetric(horizontal: _kToolbarScreenPadding))
      .loosen();

    child.layout(heightConstraint.enforce(enforcedConstraint), parentUsesSize: true,);
    final _ToolbarParentData childParentData = child.parentData as _ToolbarParentData;

    // The local x-coordinate of the center of the toolbar.
    final double lowerBound = child.size.width/2 + _kToolbarScreenPadding;
    final double upperBound = size.width - child.size.width/2 - _kToolbarScreenPadding;
    final double adjustedCenterX = _arrowTipX.clamp(lowerBound, upperBound) as double;

    childParentData.offset = Offset(adjustedCenterX - child.size.width / 2, _barTopY);
    childParentData.arrowXOffsetFromCenter = _arrowTipX - adjustedCenterX;
  }

  // The path is described in the toolbar's coordinate system.
  Path _clipPath() {
    final _ToolbarParentData childParentData = child.parentData as _ToolbarParentData;
    final Path rrect = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset(0, _isArrowPointingDown ? 0 : _kToolbarArrowSize.height,)
          & Size(child.size.width, child.size.height - _kToolbarArrowSize.height),
          _kToolbarBorderRadius,
        ),
      );

    final double arrowTipX = child.size.width / 2 + childParentData.arrowXOffsetFromCenter;

    final double arrowBottomY = _isArrowPointingDown
      ? child.size.height - _kToolbarArrowSize.height
      : _kToolbarArrowSize.height;

    final double arrowTipY = _isArrowPointingDown ? child.size.height : 0;

    final Path arrow = Path()
      ..moveTo(arrowTipX, arrowTipY)
      ..lineTo(arrowTipX - _kToolbarArrowSize.width / 2, arrowBottomY)
      ..lineTo(arrowTipX + _kToolbarArrowSize.width / 2, arrowBottomY)
      ..close();

    return Path.combine(PathOperation.union, rrect, arrow);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final _ToolbarParentData childParentData = child.parentData as _ToolbarParentData;
    context.pushClipPath(
      needsCompositing,
      offset + childParentData.offset,
      Offset.zero & child.size,
      _clipPath(),
      (PaintingContext innerContext, Offset innerOffset) => innerContext.paintChild(child, innerOffset),
    );
  }

  Paint _debugPaint;

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child == null) {
        return true;
      }

      _debugPaint ??= Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0.0, 0.0),
        const Offset(10.0, 10.0),
        <Color>[const Color(0x00000000), const Color(0xFFFF00FF), const Color(0xFFFF00FF), const Color(0x00000000)],
        <double>[0.25, 0.25, 0.75, 0.75],
        TileMode.repeated,
      )
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

      final _ToolbarParentData childParentData = child.parentData as _ToolbarParentData;
      context.canvas.drawPath(_clipPath().shift(offset + childParentData.offset), _debugPaint);
      return true;
    }());
  }
}

/// Draws a single text selection handle with a bar and a ball.
class _TextSelectionHandlePainter extends CustomPainter {
  const _TextSelectionHandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double halfStrokeWidth = 1.0;
    final Paint paint = Paint()..color = color;
    final Rect circle = Rect.fromCircle(
      center: const Offset(_kSelectionHandleRadius, _kSelectionHandleRadius),
      radius: _kSelectionHandleRadius,
    );
    final Rect line = Rect.fromPoints(
      const Offset(
        _kSelectionHandleRadius - halfStrokeWidth,
        2 * _kSelectionHandleRadius - _kSelectionHandleOverlap,
      ),
      Offset(_kSelectionHandleRadius + halfStrokeWidth, size.height),
    );
    final Path path = Path()
      ..addOval(circle)
    // Draw line so it slightly overlaps the circle.
      ..addRect(line);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) => color != oldPainter.color;
}

class _CupertinoTextSelectionControls extends TextSelectionControls {
  /// Returns the size of the Cupertino handle.
  @override
  Size getHandleSize(double textLineHeight) {
    return Size(
      _kSelectionHandleRadius * 2,
      textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap,
    );
  }

  /// Builder for iOS-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset position,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
  ) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // The toolbar should appear below the TextField when there is not enough
    // space above the TextField to show it, assuming there's always enough space
    // at the bottom in this case.
    final double toolbarHeightNeeded = mediaQuery.padding.top
      + _kToolbarScreenPadding
      + _kToolbarHeight
      + _kToolbarContentDistance;
    final double availableHeight = globalEditableRegion.top + endpoints.first.point.dy - textLineHeight;
    final bool isArrowPointingDown = toolbarHeightNeeded <= availableHeight;

    final double arrowTipX = (position.dx + globalEditableRegion.left).clamp(
      _kArrowScreenPadding + mediaQuery.padding.left,
      mediaQuery.size.width - mediaQuery.padding.right - _kArrowScreenPadding,
    ) as double;

    // The y-coordinate has to be calculated instead of directly quoting position.dy,
    // since the caller (TextSelectionOverlay._buildToolbar) does not know whether
    // the toolbar is going to be facing up or down.
    final double localBarTopY = isArrowPointingDown
      ? endpoints.first.point.dy - textLineHeight - _kToolbarContentDistance - _kToolbarHeight
      : endpoints.last.point.dy + _kToolbarContentDistance;

    return _CupertinoTextSelectionToolbarWrapper(
      arrowTipX: arrowTipX,
      barTopY: localBarTopY + globalEditableRegion.top,
      clipboardStatus: clipboardStatus,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate, clipboardStatus) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      isArrowPointingDown: isArrowPointingDown,
    );
  }

  /// Builder for iOS text selection edges.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight) {
    // We want a size that's a vertical line the height of the text plus a 18.0
    // padding in every direction that will constitute the selection drag area.
    final Size desiredSize = getHandleSize(textLineHeight);

    final Widget handle = SizedBox.fromSize(
      size: desiredSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(CupertinoTheme.of(context).primaryColor),
      ),
    );

    // [buildHandle]'s widget is positioned at the selection cursor's bottom
    // baseline. We transform the handle such that the SizedBox is superimposed
    // on top of the text selection endpoints.
    switch (type) {
      case TextSelectionHandleType.left:
        return handle;
      case TextSelectionHandleType.right:
        // Right handle is a vertical mirror of the left.
        return Transform(
          transform: Matrix4.identity()
            ..translate(desiredSize.width / 2, desiredSize.height / 2)
            ..rotateZ(math.pi)
            ..translate(-desiredSize.width / 2, -desiredSize.height / 2),
          child: handle,
        );
      // iOS doesn't draw anything for collapsed selections.
      case TextSelectionHandleType.collapsed:
        return const SizedBox();
    }
    assert(type != null);
    return null;
  }

  /// Gets anchor for cupertino-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    final Size handleSize = getHandleSize(textLineHeight);
    switch (type) {
      // The circle is at the top for the left handle, and the anchor point is
      // all the way at the bottom of the line.
      case TextSelectionHandleType.left:
        return Offset(
          handleSize.width / 2,
          handleSize.height,
        );
      // The right handle is vertically flipped, and the anchor point is near
      // the top of the circle to give slight overlap.
      case TextSelectionHandleType.right:
        return Offset(
          handleSize.width / 2,
          handleSize.height - 2 * _kSelectionHandleRadius + _kSelectionHandleOverlap,
        );
      // A collapsed handle anchors itself so that it's centered.
      default:
        return Offset(
          handleSize.width / 2,
          textLineHeight + (handleSize.height - textLineHeight) / 2,
        );
    }
  }
}

// Renders the content of the selection menu and maintains the page state.
class _CupertinoTextSelectionToolbarContent extends StatefulWidget {
  const _CupertinoTextSelectionToolbarContent({
    Key key,
    @required this.children,
    @required this.isArrowPointingDown,
  }) : assert(children != null),
       // This ignore is used because .isNotEmpty isn't compatible with const.
       assert(children.length > 0), // ignore: prefer_is_empty
       super(key: key);

  final List<Widget> children;
  final bool isArrowPointingDown;

  @override
  _CupertinoTextSelectionToolbarContentState createState() => _CupertinoTextSelectionToolbarContentState();
}

class _CupertinoTextSelectionToolbarContentState extends State<_CupertinoTextSelectionToolbarContent> with TickerProviderStateMixin {
  // Controls the fading of the buttons within the menu during page transitions.
  AnimationController _controller;
  int _page = 0;
  int _nextPage;

  void _handleNextPage() {
    _controller.reverse();
    _controller.addStatusListener(_statusListener);
    _nextPage = _page + 1;
  }

  void _handlePreviousPage() {
    _controller.reverse();
    _controller.addStatusListener(_statusListener);
    _nextPage = _page - 1;
  }

  void _statusListener(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) {
      return;
    }

    setState(() {
      _page = _nextPage;
      _nextPage = null;
    });
    _controller.forward();
    _controller.removeStatusListener(_statusListener);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 1.0,
      vsync: this,
      // This was eyeballed on a physical iOS device running iOS 13.
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void didUpdateWidget(_CupertinoTextSelectionToolbarContent oldWidget) {
    // If the children are changing, the current page should be reset.
    if (widget.children != oldWidget.children) {
      _page = 0;
      _nextPage = null;
      _controller.forward();
      _controller.removeStatusListener(_statusListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets arrowPadding = widget.isArrowPointingDown
      ? EdgeInsets.only(bottom: _kToolbarArrowSize.height)
      : EdgeInsets.only(top: _kToolbarArrowSize.height);

    return DecoratedBox(
      decoration: const BoxDecoration(color: _kToolbarDividerColor),
      child: FadeTransition(
        opacity: _controller,
        child: _CupertinoTextSelectionToolbarItems(
          page: _page,
          backButton: CupertinoButton(
            borderRadius: null,
            color: _kToolbarBackgroundColor,
            minSize: _kToolbarHeight,
            onPressed: _handlePreviousPage,
            padding: arrowPadding,
            pressedOpacity: 0.7,
            child: const Text('◀', style: _kToolbarButtonFontStyle),
          ),
          dividerWidth: 1.0 / MediaQuery.of(context).devicePixelRatio,
          nextButton: CupertinoButton(
            borderRadius: null,
            color: _kToolbarBackgroundColor,
            minSize: _kToolbarHeight,
            onPressed: _handleNextPage,
            padding: arrowPadding,
            pressedOpacity: 0.7,
            child: const Text('▶', style: _kToolbarButtonFontStyle),
          ),
          nextButtonDisabled: CupertinoButton(
            borderRadius: null,
            color: _kToolbarBackgroundColor,
            disabledColor: _kToolbarBackgroundColor,
            minSize: _kToolbarHeight,
            onPressed: null,
            padding: arrowPadding,
            pressedOpacity: 1.0,
            child: const Text('▶', style: _kToolbarButtonDisabledFontStyle),
          ),
          children: widget.children,
        ),
      ),
    );
  }
}

// The custom RenderObjectWidget that, together with
// _CupertinoTextSelectionToolbarItemsRenderBox and
// _CupertinoTextSelectionToolbarItemsElement, paginates the menu items.
class _CupertinoTextSelectionToolbarItems extends RenderObjectWidget {
  _CupertinoTextSelectionToolbarItems({
    Key key,
    @required this.page,
    @required this.children,
    @required this.backButton,
    @required this.dividerWidth,
    @required this.nextButton,
    @required this.nextButtonDisabled,
  }) : assert(children != null),
       assert(children.isNotEmpty),
       assert(backButton != null),
       assert(dividerWidth != null),
       assert(nextButton != null),
       assert(nextButtonDisabled != null),
       assert(page != null),
       super(key: key);

  final Widget backButton;
  final List<Widget> children;
  final double dividerWidth;
  final Widget nextButton;
  final Widget nextButtonDisabled;
  final int page;

  @override
  _CupertinoTextSelectionToolbarItemsRenderBox createRenderObject(BuildContext context) {
    return _CupertinoTextSelectionToolbarItemsRenderBox(
      dividerWidth: dividerWidth,
      page: page,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _CupertinoTextSelectionToolbarItemsRenderBox renderObject) {
    renderObject
      ..page = page
      ..dividerWidth = dividerWidth;
  }

  @override
  _CupertinoTextSelectionToolbarItemsElement createElement() => _CupertinoTextSelectionToolbarItemsElement(this);
}

// The custom RenderObjectElement that helps paginate the menu items.
class _CupertinoTextSelectionToolbarItemsElement extends RenderObjectElement {
  _CupertinoTextSelectionToolbarItemsElement(
    _CupertinoTextSelectionToolbarItems widget,
  ) : super(widget);

  List<Element> _children;
  final Map<_CupertinoTextSelectionToolbarItemsSlot, Element> slotToChild = <_CupertinoTextSelectionToolbarItemsSlot, Element>{};

  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  _CupertinoTextSelectionToolbarItems get widget => super.widget as _CupertinoTextSelectionToolbarItems;

  @override
  _CupertinoTextSelectionToolbarItemsRenderBox get renderObject => super.renderObject as _CupertinoTextSelectionToolbarItemsRenderBox;

  void _updateRenderObject(RenderBox child, _CupertinoTextSelectionToolbarItemsSlot slot) {
    switch (slot) {
      case _CupertinoTextSelectionToolbarItemsSlot.backButton:
        renderObject.backButton = child;
        break;
      case _CupertinoTextSelectionToolbarItemsSlot.nextButton:
        renderObject.nextButton = child;
        break;
      case _CupertinoTextSelectionToolbarItemsSlot.nextButtonDisabled:
        renderObject.nextButtonDisabled = child;
        break;
    }
  }

  @override
  void insertRenderObjectChild(RenderObject child, dynamic slot) {
    if (slot is _CupertinoTextSelectionToolbarItemsSlot) {
      assert(child is RenderBox);
      _updateRenderObject(child as RenderBox, slot);
      assert(renderObject.slottedChildren.containsKey(slot));
      return;
    }
    if (slot is IndexedSlot) {
      assert(renderObject.debugValidateChild(child));
      renderObject.insert(child as RenderBox, after: slot?.value?.renderObject as RenderBox);
      return;
    }
    assert(false, 'slot must be _CupertinoTextSelectionToolbarItemsSlot or IndexedSlot');
  }

  // This is not reachable for children that don't have an IndexedSlot.
  @override
  void moveRenderObjectChild(RenderObject child, IndexedSlot<Element> oldSlot, IndexedSlot<Element> newSlot) {
    assert(child.parent == renderObject);
    renderObject.move(child as RenderBox, after: newSlot?.value?.renderObject as RenderBox);
  }

  static bool _shouldPaint(Element child) {
    return (child.renderObject.parentData as ToolbarItemsParentData).shouldPaint;
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    // Check if the child is in a slot.
    if (slot is _CupertinoTextSelectionToolbarItemsSlot) {
      assert(child is RenderBox);
      assert(renderObject.slottedChildren.containsKey(slot));
      _updateRenderObject(null, slot);
      assert(!renderObject.slottedChildren.containsKey(slot));
      return;
    }

    // Otherwise look for it in the list of children.
    assert(slot is IndexedSlot);
    assert(child.parent == renderObject);
    renderObject.remove(child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
    for (final Element child in _children) {
      if (!_forgottenChildren.contains(child))
        visitor(child);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.containsValue(child) || _children.contains(child));
    assert(!_forgottenChildren.contains(child));
    // Handle forgetting a child in children or in a slot.
    if (slotToChild.containsKey(child.slot)) {
      final _CupertinoTextSelectionToolbarItemsSlot slot = child.slot as _CupertinoTextSelectionToolbarItemsSlot;
      slotToChild.remove(slot);
    } else {
      _forgottenChildren.add(child);
    }
    super.forgetChild(child);
  }

  // Mount or update slotted child.
  void _mountChild(Widget widget, _CupertinoTextSelectionToolbarItemsSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    // Mount slotted children.
    _mountChild(widget.backButton, _CupertinoTextSelectionToolbarItemsSlot.backButton);
    _mountChild(widget.nextButton, _CupertinoTextSelectionToolbarItemsSlot.nextButton);
    _mountChild(widget.nextButtonDisabled, _CupertinoTextSelectionToolbarItemsSlot.nextButtonDisabled);

    // Mount list children.
    _children = List<Element>(widget.children.length);
    Element previousChild;
    for (int i = 0; i < _children.length; i += 1) {
      final Element newChild = inflateWidget(widget.children[i], IndexedSlot<Element>(i, previousChild));
      _children[i] = newChild;
      previousChild = newChild;
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    // Visit slot children.
    for (final Element child in slotToChild.values) {
      if (_shouldPaint(child) && !_forgottenChildren.contains(child)) {
        visitor(child);
      }
    }
    // Visit list children.
    _children
        .where((Element child) => !_forgottenChildren.contains(child) && _shouldPaint(child))
        .forEach(visitor);
  }

  @override
  void update(_CupertinoTextSelectionToolbarItems newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);

    // Update slotted children.
    _mountChild(widget.backButton, _CupertinoTextSelectionToolbarItemsSlot.backButton);
    _mountChild(widget.nextButton, _CupertinoTextSelectionToolbarItemsSlot.nextButton);
    _mountChild(widget.nextButtonDisabled, _CupertinoTextSelectionToolbarItemsSlot.nextButtonDisabled);

    // Update list children.
    _children = updateChildren(_children, widget.children, forgottenChildren: _forgottenChildren);
    _forgottenChildren.clear();
  }
}

// The custom RenderBox that helps paginate the menu items.
class _CupertinoTextSelectionToolbarItemsRenderBox extends RenderBox with ContainerRenderObjectMixin<RenderBox, ToolbarItemsParentData>, RenderBoxContainerDefaultsMixin<RenderBox, ToolbarItemsParentData> {
  _CupertinoTextSelectionToolbarItemsRenderBox({
    @required double dividerWidth,
    @required int page,
  }) : assert(dividerWidth != null),
       assert(page != null),
       _dividerWidth = dividerWidth,
       _page = page,
       super();

  final Map<_CupertinoTextSelectionToolbarItemsSlot, RenderBox> slottedChildren = <_CupertinoTextSelectionToolbarItemsSlot, RenderBox>{};

  RenderBox _updateChild(RenderBox oldChild, RenderBox newChild, _CupertinoTextSelectionToolbarItemsSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      slottedChildren.remove(slot);
    }
    if (newChild != null) {
      slottedChildren[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  bool _isSlottedChild(RenderBox child) {
    return child == _backButton || child == _nextButton || child == _nextButtonDisabled;
  }

  int _page;
  int get page => _page;
  set page(int value) {
    if (value == _page) {
      return;
    }
    _page = value;
    markNeedsLayout();
  }

  double _dividerWidth;
  double get dividerWidth => _dividerWidth;
  set dividerWidth(double value) {
    if (value == _dividerWidth) {
      return;
    }
    _dividerWidth = value;
    markNeedsLayout();
  }

  RenderBox _backButton;
  RenderBox get backButton => _backButton;
  set backButton(RenderBox value) {
    _backButton = _updateChild(_backButton, value, _CupertinoTextSelectionToolbarItemsSlot.backButton);
  }

  RenderBox _nextButton;
  RenderBox get nextButton => _nextButton;
  set nextButton(RenderBox value) {
    _nextButton = _updateChild(_nextButton, value, _CupertinoTextSelectionToolbarItemsSlot.nextButton);
  }

  RenderBox _nextButtonDisabled;
  RenderBox get nextButtonDisabled => _nextButtonDisabled;
  set nextButtonDisabled(RenderBox value) {
    _nextButtonDisabled = _updateChild(_nextButtonDisabled, value, _CupertinoTextSelectionToolbarItemsSlot.nextButtonDisabled);
  }

  @override
  void performLayout() {
    if (firstChild == null) {
      performResize();
      return;
    }

    // Layout slotted children.
    _backButton.layout(constraints.loosen(), parentUsesSize: true);
    _nextButton.layout(constraints.loosen(), parentUsesSize: true);
    _nextButtonDisabled.layout(constraints.loosen(), parentUsesSize: true);

    final double subsequentPageButtonsWidth =
        _backButton.size.width + _nextButton.size.width;
    double currentButtonPosition = 0.0;
    double toolbarWidth; // The width of the whole widget.
    double firstPageWidth;
    int currentPage = 0;
    int i = -1;
    visitChildren((RenderObject renderObjectChild) {
      i++;
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData =
          child.parentData as ToolbarItemsParentData;
      childParentData.shouldPaint = false;

      // Skip slotted children and children on pages after the visible page.
      if (_isSlottedChild(child) || currentPage > _page) {
        return;
      }

      double paginationButtonsWidth = 0.0;
      if (currentPage == 0) {
        // If this is the last child, it's ok to fit without a forward button.
        paginationButtonsWidth =
            i == childCount - 1 ? 0.0 : _nextButton.size.width;
      } else {
        paginationButtonsWidth = subsequentPageButtonsWidth;
      }

      // The width of the menu is set by the first page.
      child.layout(
        BoxConstraints.loose(Size(
          (currentPage == 0 ? constraints.maxWidth : firstPageWidth) - paginationButtonsWidth,
          constraints.maxHeight,
        )),
        parentUsesSize: true,
      );

      // If this child causes the current page to overflow, move to the next
      // page and relayout the child.
      final double currentWidth =
          currentButtonPosition + paginationButtonsWidth + child.size.width;
      if (currentWidth > constraints.maxWidth) {
        currentPage++;
        currentButtonPosition = _backButton.size.width + dividerWidth;
        paginationButtonsWidth = _backButton.size.width + _nextButton.size.width;
        child.layout(
          BoxConstraints.loose(Size(
            firstPageWidth - paginationButtonsWidth,
            constraints.maxHeight,
          )),
          parentUsesSize: true,
        );
      }
      childParentData.offset = Offset(currentButtonPosition, 0.0);
      currentButtonPosition += child.size.width + dividerWidth;
      childParentData.shouldPaint = currentPage == page;

      if (currentPage == 0) {
        firstPageWidth = currentButtonPosition + _nextButton.size.width;
      }
      if (currentPage == page) {
        toolbarWidth = currentButtonPosition;
      }
    });

    // It shouldn't be possible to navigate beyond the last page.
    assert(page <= currentPage);

    // Position page nav buttons.
    if (currentPage > 0) {
      final ToolbarItemsParentData nextButtonParentData =
          _nextButton.parentData as ToolbarItemsParentData;
      final ToolbarItemsParentData nextButtonDisabledParentData =
          _nextButtonDisabled.parentData as ToolbarItemsParentData;
      final ToolbarItemsParentData backButtonParentData =
          _backButton.parentData as ToolbarItemsParentData;
      // The forward button always shows if there is more than one page, even on
      // the last page (it's just disabled).
      if (page == currentPage) {
        nextButtonDisabledParentData.offset = Offset(toolbarWidth, 0.0);
        nextButtonDisabledParentData.shouldPaint = true;
        toolbarWidth += nextButtonDisabled.size.width;
      } else {
        nextButtonParentData.offset = Offset(toolbarWidth, 0.0);
        nextButtonParentData.shouldPaint = true;
        toolbarWidth += nextButton.size.width;
      }
      if (page > 0) {
        backButtonParentData.offset = Offset.zero;
        backButtonParentData.shouldPaint = true;
        // No need to add the width of the back button to toolbarWidth here. It's
        // already been taken care of when laying out the children to
        // accommodate the back button.
      }
    } else {
      // No divider for the next button when there's only one page.
      toolbarWidth -= dividerWidth;
    }

    size = constraints.constrain(Size(toolbarWidth, _kToolbarHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;

      if (childParentData.shouldPaint) {
        final Offset childOffset = childParentData.offset + offset;
        context.paintChild(child, childOffset);
      }
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  // Returns true iff the single child is hit by the given position.
  static bool hitTestChild(RenderBox child, BoxHitTestResult result, { Offset position }) {
    if (child == null) {
      return false;
    }
    final ToolbarItemsParentData childParentData =
        child.parentData as ToolbarItemsParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    // Hit test list children.
    // The x, y parameters have the top left of the node's box as the origin.
    RenderBox child = lastChild;
    while (child != null) {
      final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;

      // Don't hit test children that aren't shown.
      if (!childParentData.shouldPaint) {
        child = childParentData.previousSibling;
        continue;
      }

      if (hitTestChild(child, result, position: position)) {
        return true;
      }
      child = childParentData.previousSibling;
    }

    // Hit test slot children.
    if (hitTestChild(backButton, result, position: position)) {
      return true;
    }
    if (hitTestChild(nextButton, result, position: position)) {
      return true;
    }
    if (hitTestChild(nextButtonDisabled, result, position: position)) {
      return true;
    }

    return false;
  }

  @override
  void attach(PipelineOwner owner) {
    // Attach list children.
    super.attach(owner);

    // Attach slot children.
    for (final RenderBox child in slottedChildren.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    // Detach list children.
    super.detach();

    // Detach slot children.
    for (final RenderBox child in slottedChildren.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      redepthChild(child);
    });
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    // Visit the slotted children.
    if (_backButton != null) {
      visitor(_backButton);
    }
    if (_nextButton != null) {
      visitor(_nextButton);
    }
    if (_nextButtonDisabled != null) {
      visitor(_nextButtonDisabled);
    }
    // Visit the list children.
    super.visitChildren(visitor);
  }

  // Visit only the children that should be painted.
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;
      if (childParentData.shouldPaint) {
        visitor(renderObjectChild);
      }
    });
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    visitChildren((RenderObject renderObjectChild) {
      if (renderObjectChild == null) {
        return;
      }
      final RenderBox child = renderObjectChild as RenderBox;
      if (child == backButton) {
        value.add(child.toDiagnosticsNode(name: 'back button'));
      } else if (child == nextButton) {
        value.add(child.toDiagnosticsNode(name: 'next button'));
      } else if (child == nextButtonDisabled) {
        value.add(child.toDiagnosticsNode(name: 'next button disabled'));

      // List children.
      } else {
        value.add(child.toDiagnosticsNode(name: 'menu item'));
      }
    });
    return value;
  }
}

// The slots that can be occupied by widgets in
// _CupertinoTextSelectionToolbarItems, excluding the list of children.
enum _CupertinoTextSelectionToolbarItemsSlot {
  backButton,
  nextButton,
  nextButtonDisabled,
}

/// Text selection controls that follows iOS design conventions.
final TextSelectionControls cupertinoTextSelectionControls = _CupertinoTextSelectionControls();
