// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'flat_button.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'text_selection_theme.dart';
import 'theme.dart';

const double _kHandleSize = 22.0;

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarHeight = 44.0;
// Padding when positioning toolbar below selection.
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatefulWidget {
  const _TextSelectionToolbar({
    this.clipboardStatus,
    Key key,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.isAbove,
  }) : super(key: key);

  final ClipboardStatusNotifier clipboardStatus;
  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;

  // When true, the toolbar fits above its anchor and will be positioned there.
  final bool isAbove;

  @override
  _TextSelectionToolbarState createState() => _TextSelectionToolbarState();
}

// Intermediate data used for building menu items with the _getItems method.
class _ItemData {
  const _ItemData(
    this.onPressed,
    this.label,
  ) : assert(onPressed != null),
      assert(label != null);

  final VoidCallback onPressed;
  final String label;
}

class _TextSelectionToolbarState extends State<_TextSelectionToolbar> with TickerProviderStateMixin {
  ClipboardStatusNotifier _clipboardStatus;

  // Whether or not the overflow menu is open. When it is closed, the menu
  // items that don't overflow are shown. When it is open, only the overflowing
  // menu items are shown.
  bool _overflowOpen = false;

  // The key for _TextSelectionToolbarContainer.
  UniqueKey _containerKey = UniqueKey();

  Widget _getItem(_ItemData itemData, bool isFirst, bool isLast) {
    assert(isFirst != null);
    assert(isLast != null);
    return ButtonTheme.fromButtonThemeData(
      data: ButtonTheme.of(context).copyWith(
        height: kMinInteractiveDimension,
        minWidth: kMinInteractiveDimension,
      ),
      child: FlatButton(
        onPressed: itemData.onPressed,
        padding: EdgeInsets.only(
          // These values were eyeballed to match the native text selection menu
          // on a Pixel 2 running Android 10.
          left: 9.5 + (isFirst ? 5.0 : 0.0),
          right: 9.5 + (isLast ? 5.0 : 0.0),
        ),
        shape: Border.all(width: 0.0, color: Colors.transparent),
        child: Text(itemData.label),
      ),
    );
  }

  // Close the menu and reset layout calculations, as in when the menu has
  // changed and saved values are no longer relevant. This should be called in
  // setState or another context where a rebuild is happening.
  void _reset() {
    // Change _TextSelectionToolbarContainer's key when the menu changes in
    // order to cause it to rebuild. This lets it recalculate its
    // saved width for the new set of children, and it prevents AnimatedSize
    // from animating the size change.
    _containerKey = UniqueKey();
    // If the menu items change, make sure the overflow menu is closed. This
    // prevents an empty overflow menu.
    _overflowOpen = false;
  }

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
  void didUpdateWidget(_TextSelectionToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the children are changing, the current page should be reset.
    if (((widget.handleCut == null) != (oldWidget.handleCut == null))
      || ((widget.handleCopy == null) != (oldWidget.handleCopy == null))
      || ((widget.handlePaste == null) != (oldWidget.handlePaste == null))
      || ((widget.handleSelectAll == null) != (oldWidget.handleSelectAll == null))) {
      _reset();
    }
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

    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<_ItemData> itemDatas = <_ItemData>[
      if (widget.handleCut != null)
        _ItemData(widget.handleCut, localizations.cutButtonLabel),
      if (widget.handleCopy != null)
        _ItemData(widget.handleCopy, localizations.copyButtonLabel),
      if (widget.handlePaste != null
          && _clipboardStatus.value == ClipboardStatus.pasteable)
        _ItemData(widget.handlePaste, localizations.pasteButtonLabel),
      if (widget.handleSelectAll != null)
        _ItemData(widget.handleSelectAll, localizations.selectAllButtonLabel),
    ];

    // If there is no option available, build an empty widget.
    if (itemDatas.isEmpty) {
      return const SizedBox(width: 0.0, height: 0.0);
    }

    return _TextSelectionToolbarContainer(
      key: _containerKey,
      overflowOpen: _overflowOpen,
      child: AnimatedSize(
        vsync: this,
        // This duration was eyeballed on a Pixel 2 emulator running Android
        // API 28.
        duration: const Duration(milliseconds: 140),
        child: Material(
          // This value was eyeballed to match the native text selection menu on
          // a Pixel 2 running Android 10.
          borderRadius: const BorderRadius.all(Radius.circular(7.0)),
          clipBehavior: Clip.antiAlias,
          elevation: 1.0,
          type: MaterialType.card,
          child: _TextSelectionToolbarItems(
            isAbove: widget.isAbove,
            overflowOpen: _overflowOpen,
            children: <Widget>[
              // The navButton that shows and hides the overflow menu is the
              // first child.
              Material(
                type: MaterialType.card,
                child: IconButton(
                  // TODO(justinmc): This should be an AnimatedIcon, but
                  // AnimatedIcons doesn't yet support arrow_back to more_vert.
                  // https://github.com/flutter/flutter/issues/51209
                  icon: Icon(_overflowOpen ? Icons.arrow_back : Icons.more_vert),
                  onPressed: () {
                    setState(() {
                      _overflowOpen = !_overflowOpen;
                    });
                  },
                  tooltip: _overflowOpen
                      ? localizations.backButtonTooltip
                      : localizations.moreButtonTooltip,
                ),
              ),
              for (int i = 0; i < itemDatas.length; i++)
                _getItem(itemDatas[i], i == 0, i == itemDatas.length - 1)
            ],
          ),
        ),
      ),
    );
  }
}

// When the overflow menu is open, it tries to align its right edge to the right
// edge of the closed menu. This widget handles this effect by measuring and
// maintaining the width of the closed menu and aligning the child to the right.
class _TextSelectionToolbarContainer extends SingleChildRenderObjectWidget {
  const _TextSelectionToolbarContainer({
    Key key,
    @required Widget child,
    @required this.overflowOpen,
  }) : assert(child != null),
       assert(overflowOpen != null),
       super(key: key, child: child);

  final bool overflowOpen;

  @override
  _TextSelectionToolbarContainerRenderBox createRenderObject(BuildContext context) {
    return _TextSelectionToolbarContainerRenderBox(overflowOpen: overflowOpen);
  }

  @override
  void updateRenderObject(BuildContext context, _TextSelectionToolbarContainerRenderBox renderObject) {
    renderObject.overflowOpen = overflowOpen;
  }
}

class _TextSelectionToolbarContainerRenderBox extends RenderProxyBox {
  _TextSelectionToolbarContainerRenderBox({
    @required bool overflowOpen,
  }) : assert(overflowOpen != null),
       _overflowOpen = overflowOpen,
       super();

  // The width of the menu when it was closed. This is used to achieve the
  // behavior where the open menu aligns its right edge to the closed menu's
  // right edge.
  double _closedWidth;

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child.layout(constraints.loosen(), parentUsesSize: true);

    // Save the width when the menu is closed. If the menu changes, this width
    // is invalid, so it's important that this RenderBox be recreated in that
    // case. Currently, this is achieved by providing a new key to
    // _TextSelectionToolbarContainer.
    if (!overflowOpen && _closedWidth == null) {
      _closedWidth = child.size.width;
    }

    size = constraints.constrain(Size(
      // If the open menu is wider than the closed menu, just use its own width
      // and don't worry about aligning the right edges.
      // _closedWidth is used even when the menu is closed to allow it to
      // animate its size while keeping the same right alignment.
      _closedWidth == null || child.size.width > _closedWidth ? child.size.width : _closedWidth,
      child.size.height,
    ));

    final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;
    childParentData.offset = Offset(
      size.width - child.size.width,
      0.0,
    );
  }

  // Paint at the offset set in the parent data.
  @override
  void paint(PaintingContext context, Offset offset) {
    final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  // Include the parent data offset in the hit test.
  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    // The x, y parameters have the top left of the node's box as the origin.
    final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;
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
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;
    transform.translate(childParentData.offset.dx, childParentData.offset.dy);
    super.applyPaintTransform(child, transform);
  }
}

// Renders the menu items in the correct positions in the menu and its overflow
// submenu based on calculating which item would first overflow.
class _TextSelectionToolbarItems extends MultiChildRenderObjectWidget {
  _TextSelectionToolbarItems({
    Key key,
    @required this.isAbove,
    @required this.overflowOpen,
    @required List<Widget> children,
  }) : assert(children != null),
       assert(isAbove != null),
       assert(overflowOpen != null),
       super(key: key, children: children);

  final bool isAbove;
  final bool overflowOpen;

  @override
  _TextSelectionToolbarItemsRenderBox createRenderObject(BuildContext context) {
    return _TextSelectionToolbarItemsRenderBox(
      isAbove: isAbove,
      overflowOpen: overflowOpen,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _TextSelectionToolbarItemsRenderBox renderObject) {
    renderObject
      ..isAbove = isAbove
      ..overflowOpen = overflowOpen;
  }

  @override
  _TextSelectionToolbarItemsElement createElement() => _TextSelectionToolbarItemsElement(this);
}

class _TextSelectionToolbarItemsElement extends MultiChildRenderObjectElement {
  _TextSelectionToolbarItemsElement(
    MultiChildRenderObjectWidget widget,
  ) : super(widget);

  static bool _shouldPaint(Element child) {
    return (child.renderObject.parentData as ToolbarItemsParentData).shouldPaint;
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where(_shouldPaint).forEach(visitor);
  }
}

class _TextSelectionToolbarItemsRenderBox extends RenderBox with ContainerRenderObjectMixin<RenderBox, ToolbarItemsParentData> {
  _TextSelectionToolbarItemsRenderBox({
    @required bool isAbove,
    @required bool overflowOpen,
  }) : assert(overflowOpen != null),
       assert(isAbove != null),
       _isAbove = isAbove,
       _overflowOpen = overflowOpen,
       super();

  // The index of the last item that doesn't overflow.
  int _lastIndexThatFits = -1;

  bool _isAbove;
  bool get isAbove => _isAbove;
  set isAbove(bool value) {
    if (value == isAbove) {
      return;
    }
    _isAbove = value;
    markNeedsLayout();
  }

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  // Layout the necessary children, and figure out where the children first
  // overflow, if at all.
  void _layoutChildren() {
    // When overflow is not open, the toolbar is always a specific height.
    final BoxConstraints sizedConstraints = _overflowOpen
      ? constraints
      : BoxConstraints.loose(Size(
          constraints.maxWidth,
          _kToolbarHeight,
        ));

    int i = -1;
    double width = 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      // No need to layout children inside the overflow menu when it's closed.
      // The opposite is not true. It is necessary to layout the children that
      // don't overflow when the overflow menu is open in order to calculate
      // _lastIndexThatFits.
      if (_lastIndexThatFits != -1 && !overflowOpen) {
        return;
      }

      final RenderBox child = renderObjectChild as RenderBox;
      child.layout(sizedConstraints.loosen(), parentUsesSize: true);
      width += child.size.width;

      if (width > sizedConstraints.maxWidth && _lastIndexThatFits == -1) {
        _lastIndexThatFits = i - 1;
      }
    });

    // If the last child overflows, but only because of the width of the
    // overflow button, then just show it and hide the overflow button.
    final RenderBox navButton = firstChild;
    if (_lastIndexThatFits != -1
        && _lastIndexThatFits == childCount - 2
        && width - navButton.size.width <= sizedConstraints.maxWidth) {
      _lastIndexThatFits = -1;
    }
  }

  // Returns true when the child should be painted, false otherwise.
  bool _shouldPaintChild(RenderObject renderObjectChild, int index) {
    // Paint the navButton when there is overflow.
    if (renderObjectChild == firstChild) {
      return _lastIndexThatFits != -1;
    }

    // If there is no overflow, all children besides the navButton are painted.
    if (_lastIndexThatFits == -1) {
      return true;
    }

    // When there is overflow, paint if the child is in the part of the menu
    // that is currently open. Overflowing children are painted when the
    // overflow menu is open, and the children that fit are painted when the
    // overflow menu is closed.
    return (index > _lastIndexThatFits) == overflowOpen;
  }

  // Decide which children will be pained and set their shouldPaint, and set the
  // offset that painted children will be placed at.
  void _placeChildren() {
    int i = -1;
    Size nextSize = const Size(0.0, 0.0);
    double fitWidth = 0.0;
    final RenderBox navButton = firstChild;
    double overflowHeight = overflowOpen && !isAbove ? navButton.size.height : 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;

      // Handle placing the navigation button after iterating all children.
      if (renderObjectChild == navButton) {
        return;
      }

      // There is no need to place children that won't be painted.
      if (!_shouldPaintChild(renderObjectChild, i)) {
        childParentData.shouldPaint = false;
        return;
      }
      childParentData.shouldPaint = true;

      if (!overflowOpen) {
        childParentData.offset = Offset(fitWidth, 0.0);
        fitWidth += child.size.width;
        nextSize = Size(
          fitWidth,
          math.max(child.size.height, nextSize.height),
        );
      } else {
        childParentData.offset = Offset(0.0, overflowHeight);
        overflowHeight += child.size.height;
        nextSize = Size(
          math.max(child.size.width, nextSize.width),
          overflowHeight,
        );
      }
    });

    // Place the navigation button if needed.
    final ToolbarItemsParentData navButtonParentData = navButton.parentData as ToolbarItemsParentData;
    if (_shouldPaintChild(firstChild, 0)) {
      navButtonParentData.shouldPaint = true;
      if (overflowOpen) {
        navButtonParentData.offset = isAbove
          ? Offset(0.0, overflowHeight)
          : Offset.zero;
        nextSize = Size(
          nextSize.width,
          isAbove ? nextSize.height + navButton.size.height : nextSize.height,
        );
      } else {
        navButtonParentData.offset = Offset(fitWidth, 0.0);
        nextSize = Size(nextSize.width + navButton.size.width, nextSize.height);
      }
    } else {
      navButtonParentData.shouldPaint = false;
    }

    size = nextSize;
  }

  @override
  void performLayout() {
    _lastIndexThatFits = -1;
    if (firstChild == null) {
      performResize();
      return;
    }

    _layoutChildren();
    _placeChildren();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;
      if (!childParentData.shouldPaint) {
        return;
      }

      context.paintChild(child, childParentData.offset + offset);
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ToolbarItemsParentData) {
      child.parentData = ToolbarItemsParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    // The x, y parameters have the top left of the node's box as the origin.
    RenderBox child = lastChild;
    while (child != null) {
      final ToolbarItemsParentData childParentData = child.parentData as ToolbarItemsParentData;

      // Don't hit test children aren't shown.
      if (!childParentData.shouldPaint) {
        child = childParentData.previousSibling;
        continue;
      }

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit)
        return true;
      child = childParentData.previousSibling;
    }
    return false;
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
}

/// Centers the toolbar around the given anchor, ensuring that it remains on
/// screen.
class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayout(this.anchor, this.upperBounds, this.fitsAbove);

  /// Anchor position of the toolbar in global coordinates.
  final Offset anchor;

  /// The upper-most valid y value for the anchor.
  final double upperBounds;

  /// Whether the closed toolbar fits above the anchor position.
  ///
  /// If the closed toolbar doesn't fit, then the menu is rendered below the
  /// anchor position. It should never happen that the toolbar extends below the
  /// padded bottom of the screen.
  ///
  /// If the closed toolbar does fit but it doesn't fit when the overflow menu
  /// is open, then the toolbar is still rendered above the anchor position. It
  /// then grows downward, overlapping the selection.
  final bool fitsAbove;

  // Return the value that centers width as closely as possible to position
  // while fitting inside of min and max.
  static double _centerOn(double position, double width, double min, double max) {
    // If it overflows on the left, put it as far left as possible.
    if (position - width / 2.0 < min) {
      return min;
    }

    // If it overflows on the right, put it as far right as possible.
    if (position + width / 2.0 > max) {
      return max - width;
    }

    // Otherwise it fits while perfectly centered.
    return position - width / 2.0;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
      _centerOn(
        anchor.dx,
        childSize.width,
        _kToolbarScreenPadding,
        size.width - _kToolbarScreenPadding,
      ),
      fitsAbove
        ? math.max(upperBounds, anchor.dy - childSize.height)
        : anchor.dy,
    );
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return anchor != oldDelegate.anchor;
  }
}

/// Draws a single text selection handle which points up and to the left.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({ this.color });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double radius = size.width/2.0;
    final Rect circle = Rect.fromCircle(center: Offset(radius, radius), radius: radius);
    final Rect point = Rect.fromLTWH(0.0, 0.0, radius, radius);
    final Path path = Path()..addOval(circle)..addRect(point);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}

class _MaterialTextSelectionControls extends TextSelectionControls {
  /// Returns the size of the Material handle.
  @override
  Size getHandleSize(double textLineHeight) => const Size(_kHandleSize, _kHandleSize);

  /// Builder for material-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ClipboardStatusNotifier clipboardStatus,
  ) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));

    // The toolbar should appear below the TextField when there is not enough
    // space above the TextField to show it.
    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint = endpoints.length > 1
      ? endpoints[1]
      : endpoints[0];
    const double closedToolbarHeightNeeded = _kToolbarScreenPadding
      + _kToolbarHeight
      + _kToolbarContentDistance;
    final double paddingTop = MediaQuery.of(context).padding.top;
    final double availableHeight = globalEditableRegion.top
      + startTextSelectionPoint.point.dy
      - textLineHeight
      - paddingTop;
    final bool fitsAbove = closedToolbarHeightNeeded <= availableHeight;
    final Offset anchor = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      fitsAbove
        ? globalEditableRegion.top + startTextSelectionPoint.point.dy - textLineHeight - _kToolbarContentDistance
        : globalEditableRegion.top + endTextSelectionPoint.point.dy + _kToolbarContentDistanceBelow,
    );

    return Stack(
      children: <Widget>[
        CustomSingleChildLayout(
          delegate: _TextSelectionToolbarLayout(
            anchor,
            _kToolbarScreenPadding + paddingTop,
            fitsAbove,
          ),
          child: _TextSelectionToolbar(
            clipboardStatus: clipboardStatus,
            handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
            handleCopy: canCopy(delegate) ? () => handleCopy(delegate, clipboardStatus) : null,
            handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
            handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
            isAbove: fitsAbove,
          ),
        ),
      ],
    );
  }

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textHeight) {
    final ThemeData theme = Theme.of(context);
    final Color handleColor = theme.useTextSelectionTheme ?
      TextSelectionTheme.of(context).selectionHandleColor ?? theme.colorScheme.primary :
      theme.textSelectionHandleColor;
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          color: handleColor,
        ),
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return Transform.rotate(
          angle: math.pi / 2.0,
          child: handle,
        );
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points up
        return Transform.rotate(
          angle: math.pi / 4.0,
          child: handle,
        );
    }
    assert(type != null);
    return null;
  }

  /// Gets anchor for material-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, 0);
      case TextSelectionHandleType.right:
        return Offset.zero;
      default:
        return const Offset(_kHandleSize / 2, -4);
    }
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // Android allows SelectAll when selection is not collapsed, unless
    // everything has already been selected.
    final TextEditingValue value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
           value.text.isNotEmpty &&
           !(value.selection.start == 0 && value.selection.end == value.text.length);
  }
}

/// Text selection controls that follow the Material Design specification.
final TextSelectionControls materialTextSelectionControls = _MaterialTextSelectionControls();
