// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'debug.dart';
import 'flat_button.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
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
    Key key,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.isAbove,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;

  // When true, the toolbar fits above its anchor and will be positioned there.
  final bool isAbove;

  @override
  _TextSelectionToolbarState createState() => _TextSelectionToolbarState();
}

class _TextSelectionToolbarState extends State<_TextSelectionToolbar> with TickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();

  // Whether or not the overflow menu is open.
  bool _overflowOpen = false;
  // The greatest width ever measured for this widget.
  double _maxWidth;

  @override
  Widget build(BuildContext context) {
    // Keep track of the largest child width.
    if (_key.currentContext != null) {
      final RenderBox renderBoxChild = _key.currentContext.findRenderObject() as RenderBox;
      if (_maxWidth == null || renderBoxChild.size.width > _maxWidth) {
        _maxWidth = renderBoxChild.size.width;
      }
    }

    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final List<Widget> items = <Widget>[];
    if (widget.handleCut != null) {
      items.add(FlatButton(
        child: Text(localizations.cutButtonLabel),
        onPressed: () {
          setState(() {
            _overflowOpen = false;
          });
          widget.handleCut();
        },
      ));
    }
    if (widget.handleCopy != null) {
      items.add(FlatButton(
        child: Text(localizations.copyButtonLabel),
        onPressed: () {
          setState(() {
            _overflowOpen = false;
          });
          widget.handleCopy();
        },
      ));
    }
    if (widget.handlePaste != null) {
      items.add(FlatButton(
        child: Text(localizations.pasteButtonLabel),
        onPressed: () {
          setState(() {
            _overflowOpen = false;
          });
          widget.handlePaste();
        },
      ));
    }
    if (widget.handleSelectAll != null) {
      items.add(FlatButton(
        child: Text(localizations.selectAllButtonLabel),
        onPressed: () {
          setState(() {
            _overflowOpen = false;
          });
          widget.handleSelectAll();
        },
      ));
    }

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return Container(width: 0.0, height: 0.0);
    }

    final Container child = Container(
      key: _key,
      height: _overflowOpen ? null : _kToolbarHeight,
      child: Material(
        elevation: 1.0,
        child: AnimatedSize(
          vsync: this,
          // This duration was eyeballed on a Pixel 2 emulator running Android
          // API 28.
          duration: const Duration(milliseconds: 140),
          child: _TextSelectionToolbarItems(
            isAbove: widget.isAbove,
            overflowOpen: _overflowOpen,
            children: <Widget>[
              // The navButton that shows and hides the overflow menu is the first
              // child.
              Material(
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
                  tooltip: _overflowOpen ? 'Back' : 'More',
                ),
              ),
              ...items,
            ],
          ),
        ),
      ),
    );

    // When the menu shrinks as the overflow is opened, then it occupies the
    // same size as it did with overflow closed and aligns itself to the right
    // of its original size.
    return _maxWidth == null ? child : SizedBox(
      width: _maxWidth,
      child: Align(
        alignment: Alignment.topRight,
        heightFactor: 1.0,
        widthFactor: 1.0,
        child: child,
      ),
    );

  }
}

// Renders the menu items in the correct positions in the menu and its overflow
// submenu based on calculating which item would first overflow.
class _TextSelectionToolbarItems extends MultiChildRenderObjectWidget {
  _TextSelectionToolbarItems({
    Key key,
    @required List<Widget> children,
    @required this.isAbove,
    @required this.overflowOpen,
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
  MultiChildRenderObjectElement createElement() => MultiChildRenderObjectElement(this);
}

class _TextSelectionToolbarItemsRenderBox extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexParentData>, RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData> {
  _TextSelectionToolbarItemsRenderBox({
    @required bool isAbove,
    @required bool overflowOpen,
  }) : assert(overflowOpen != null),
       assert(isAbove != null),
       _isAbove = isAbove,
       _overflowOpen = overflowOpen,
       super();

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

  // Lay out all children, regardless of whether or not they will be painted or
  // placed with an offset. Find which child overflows, if any.
  void _layoutChildren() {
    int i = -1;
    double width = 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;
      final RenderBox child = renderObjectChild as RenderBox;
      child.layout(constraints.loosen(), parentUsesSize: true);
      width += child.size.width;

      if (width > constraints.maxWidth && _lastIndexThatFits == -1) {
        _lastIndexThatFits = i - 1;
      }
    });

    // If the last child overflows, but only because of the width of the
    // overflow button, then just show it and hide the overflow button.
    final RenderBox navButton = firstChild;
    if (_lastIndexThatFits != -1 && _lastIndexThatFits == childCount - 2
      && width - navButton.size.width <= constraints.maxWidth) {
      _lastIndexThatFits = -1;
    }
  }

  // Set the offset of all of the children that will be painted.
  void _placeChildren() {
    int i = -1;
    Size nextSize = const Size(0.0, 0.0);
    double fitWidth = 0.0;
    final RenderBox navButton = firstChild;
    double overflowHeight = overflowOpen && !isAbove ? navButton.size.height : 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      // The navigation button is placed after iterating all children.
      if (renderObjectChild == firstChild) {
        return;
      }

      final RenderBox child = renderObjectChild as RenderBox;
      final FlexParentData childParentData = child.parentData as FlexParentData;

      // If the current child is not displayed, place it offscreen to avoid it
      // interfering with hit detection.
      if (_lastIndexThatFits != -1) {
        if ((!overflowOpen && i > _lastIndexThatFits)
          || (overflowOpen && i <= _lastIndexThatFits)) {
          childParentData.offset = Offset(-child.size.width, -child.size.height);
          return;
        }
      }

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

    // Place the navigation button if there is overflow.
    if (_lastIndexThatFits >= 0) {
      final FlexParentData navButtonParentData = navButton.parentData as FlexParentData;
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
    int i = -1;
    bool fits = true;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      // Don't paint the navButton if there is no overflow.
      if (_lastIndexThatFits == -1 && renderObjectChild == firstChild) {
        return;
      }

      // Don't paint children that don't fit when overflow is closed, and don't
      // paint children that do fit when overflow is open.
      if (renderObjectChild != firstChild && fits == overflowOpen) {
        if (fits && i == _lastIndexThatFits) {
          fits = false;
        }
        return;
      }

      // Otherwise paint the child.
      final RenderBox child = renderObjectChild as RenderBox;
      final FlexParentData childParentData = child.parentData as FlexParentData;
      context.paintChild(child, childParentData.offset + offset);
      if (fits && i == _lastIndexThatFits) {
        fits = false;
      }
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! FlexParentData) {
      child.parentData = FlexParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
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
            handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
            handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
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
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          color: Theme.of(context).textSelectionHandleColor,
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
