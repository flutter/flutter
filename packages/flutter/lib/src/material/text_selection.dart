// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'text_button.dart';
import 'text_selection_theme.dart';
import 'theme.dart';

const double _kHandleSize = 22.0;

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarHeight = 44.0;
// Padding between the toolbar and the anchor.
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;

typedef Widget _ToolbarBuilder(BuildContext context, Widget child);

class MaterialTextSelectionControls extends TextSelectionControls {
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
    return _TextSelectionToolbar(
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate, clipboardStatus) : null,
      handlePaste: canPaste(delegate) ? () => handlePaste(delegate) : null,
      handleSelectAll: canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
    );
  }

  // TODO(justinmc): Handles should be customizable too.
  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textHeight) {
    final ThemeData theme = Theme.of(context)!;
    final Color handleColor = TextSelectionTheme.of(context).selectionHandleColor ?? theme.colorScheme.primary;
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

// The highest level toolbar widget, built directly by buildToolbar.
class _TextSelectionToolbar extends StatefulWidget {
  const _TextSelectionToolbar({
    Key? key,
    required this.clipboardStatus,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCut,
    required this.handleCopy,
    required this.handlePaste,
    required this.handleSelectAll,
    required this.selectionMidpoint,
    required this.textLineHeight,
  }) : super(key: key);

  final ClipboardStatusNotifier clipboardStatus;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCut;
  final VoidCallback? handleCopy;
  final VoidCallback? handlePaste;
  final VoidCallback? handleSelectAll;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  _TextSelectionToolbarState createState() => _TextSelectionToolbarState();
}

// TODO(justinmc): When this PR is merged, how will users add a custom button
// to the TSM? Currently, it's fairly involved due to my refusal to make a
// widget that is specific to buildToolbar. Decide whether to provide a nice
// widget that may be deprecated soon, or to keep it difficult and break
// TextSelectionControls later.
class _TextSelectionToolbarState extends State<_TextSelectionToolbar> with TickerProviderStateMixin {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus.addListener(_onChangedClipboardStatus);
    widget.clipboardStatus.update();
  }

  @override
  void didUpdateWidget(_TextSelectionToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
    widget.clipboardStatus.update();
  }

  @override
  void dispose() {
    super.dispose();
    // When used in an Overlay, it can happen that this is disposed after its
    // creator has already disposed _clipboardStatus.
    if (!widget.clipboardStatus.disposed) {
      widget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If there are no buttons to be shown, don't render anything.
    if (widget.handleCut == null && widget.handleCopy == null
        && widget.handlePaste == null && widget.handleSelectAll == null) {
      return const SizedBox.shrink();
    }
    // If the paste button is desired, don't render anything until the state of
    // the clipboard is known, since it's used to determine if paste is shown.
    if (widget.handlePaste != null
        && widget.clipboardStatus.value == ClipboardStatus.unknown) {
      return const SizedBox.shrink();
    }

    // Calculate the positioning of the menu. It is placed above the selection
    // if there is enough room, or otherwise below.
    final TextSelectionPoint startTextSelectionPoint = widget.endpoints[0];
    final TextSelectionPoint endTextSelectionPoint = widget.endpoints.length > 1
      ? widget.endpoints[1]
      : widget.endpoints[0];
    final Offset anchorAbove = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top + startTextSelectionPoint.point.dy - widget.textLineHeight - _kToolbarContentDistance
    );
    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top + endTextSelectionPoint.point.dy + _kToolbarContentDistanceBelow,
    );

    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    return TextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: <Widget>[
        if (widget.handleCut != null)
          TextSelectionMenuTextButton(
            isFirst: true,
            isLast: false,
            onPressed: widget.handleCut,
            child: Text(localizations.cutButtonLabel),
          ),
        if (widget.handleCopy != null)
          TextSelectionMenuTextButton(
            isFirst: false,
            isLast: false,
            onPressed: widget.handleCopy,
            child: Text(localizations.copyButtonLabel),
          ),
        if (widget.handlePaste != null
            && widget.clipboardStatus.value == ClipboardStatus.pasteable)
          TextSelectionMenuTextButton(
            isFirst: false,
            isLast: false,
            onPressed: widget.handlePaste,
            child: Text(localizations.pasteButtonLabel),
          ),
        if (widget.handleSelectAll != null)
          TextSelectionMenuTextButton(
            isFirst: false,
            isLast: true,
            //isLast: false,
            onPressed: widget.handleSelectAll,
            child: Text(localizations.selectAllButtonLabel),
          ),
      ],
    );
  }
}

/// A fully-functional Material-style text selection toolbar.
///
/// Positions itself above or below the given anchor so that it fits on the
/// screen.
///
class TextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of TextSelectionToolbar.
  const TextSelectionToolbar({
    Key? key,
    required this.anchorAbove,
    required this.anchorBelow,
    this.toolbarBuilder = _defaultToolbarBuilder,
    required this.children,
  }) : super(key: key);

  /// The focal point that the toolbar attempts to position itself above.
  ///
  /// If there is not enough room above before reaching the top of the screen,
  /// then the toolbar will position itself below [anchorBelow].
  final Offset anchorAbove;

  /// The focal point that the toolbar attempts to position itself below, if it
  /// doesn't fit above [anchorAbove].
  final Offset anchorBelow;

  /// The children that will be displayed in the text selection toolbar.
  ///
  /// Typically these are buttons.
  ///
  /// See also:
  ///   * [TextSelectionToolbarTextButton], which builds a default Material-
  ///     style text selection toolbar text button.
  final List<Widget> children;

  // TODO(justinmc): Elaborate docs.
  /// Builds the toolbar that will be populated with [children] and fit inside
  /// of the layout that adjusts to overflow.
  final _ToolbarBuilder toolbarBuilder;

  static Widget _defaultToolbarBuilder(BuildContext context, Widget child) {
    return _MaterialTextSelectionToolbarShapeNew(
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double paddingTop = MediaQuery.of(context).padding.top
        + _kToolbarScreenPadding;
    final double availableHeight = anchorAbove.dy
      - paddingTop;
    final bool fitsAbove = _kToolbarHeight <= availableHeight;

    return Stack(
      children: <Widget>[
        CustomSingleChildLayout(
          delegate: _TextSelectionToolbarLayoutDelegate(
            fitsAbove ? anchorAbove : anchorBelow,
            paddingTop,
            fitsAbove,
          ),
          child: _TextSelectionToolbarOverflowableNew(
            isAbove: fitsAbove,
            toolbarBuilder: toolbarBuilder,
            children: children,
          ),
        ),
      ],
    );
  }
}

// Centers the toolbar around the given anchor, ensuring that it remains on
// screen.
class _TextSelectionToolbarLayoutDelegate extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayoutDelegate(
    this.anchor,
    this.upperBounds,
    this.fitsAbove,
  );

  /// Anchor position of the toolbar in global coordinates.
  final Offset anchor;

  /// The upper-most valid y value for the anchor.
  final double upperBounds;

  /// Whether the closed toolbar fits above the anchor position.
  ///
  /// If the closed toolbar doesn't fit, then the menu is rendered below the
  /// anchor position. It should never happen that the toolbar extends below the
  /// padded bottom of the screen.
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
  bool shouldRelayout(_TextSelectionToolbarLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor;
  }
}

// A toolbar containing the given children. If they overflow the width
// available, then the overflowing children will be displayed in an overflow
// menu.
class _TextSelectionToolbarOverflowableNew extends StatefulWidget {
  const _TextSelectionToolbarOverflowableNew({
    Key? key,
    required this.isAbove,
    required this.toolbarBuilder,
    required this.children,
  }) : assert(children.length > 0),
       super(key: key);

  final List<Widget> children;

  // When true, the toolbar fits above its anchor and will be positioned there.
  final bool isAbove;

  // Builds the toolbar that will be populated with the children and fit inside
  // of the layout that adjusts to overflow.
  final _ToolbarBuilder toolbarBuilder;

  @override
  _TextSelectionToolbarOverflowableNewState createState() => _TextSelectionToolbarOverflowableNewState();
}

class _TextSelectionToolbarOverflowableNewState extends State<_TextSelectionToolbarOverflowableNew> with TickerProviderStateMixin {
  // Whether or not the overflow menu is open. When it is closed, the menu
  // items that don't overflow are shown. When it is open, only the overflowing
  // menu items are shown.
  bool _overflowOpen = false;

  // The key for _TextSelectionToolbarRightEdgeAlign.
  UniqueKey _containerKey = UniqueKey();

  // Close the menu and reset layout calculations, as in when the menu has
  // changed and saved values are no longer relevant. This should be called in
  // setState or another context where a rebuild is happening.
  void _reset() {
    // Change _TextSelectionToolbarRightEdgeAlign's key when the menu changes in
    // order to cause it to rebuild. This lets it recalculate its
    // saved width for the new set of children, and it prevents AnimatedSize
    // from animating the size change.
    _containerKey = UniqueKey();
    // If the menu items change, make sure the overflow menu is closed. This
    // prevents an empty overflow menu.
    _overflowOpen = false;
  }

  @override
  void didUpdateWidget(_TextSelectionToolbarOverflowableNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the children are changing, the current page should be reset.
    if (widget.children != oldWidget.children) {
      // TODO(justinmc): Do I need to check individual children equality, or
      // just the List?
      _reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);

    return _TextSelectionToolbarRightEdgeAlign(
      key: _containerKey,
      overflowOpen: _overflowOpen,
      child: AnimatedSize(
        vsync: this,
        // This duration was eyeballed on a Pixel 2 emulator running Android
        // API 28.
        duration: const Duration(milliseconds: 140),
        child: widget.toolbarBuilder(context, _TextSelectionToolbarItemsLayout(
          isAbove: widget.isAbove,
          overflowOpen: _overflowOpen,
          children: <Widget>[
            // The navButton that shows and hides the overflow menu is the
            // first child.
            _TextSelectionMenuOverflowButton(
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
            ...widget.children,
          ],
        )),
      ),
    );
  }
}

// When the overflow menu is open, it tries to align its right edge to the right
// edge of the closed menu. This widget handles this effect by measuring and
// maintaining the width of the closed menu and aligning the child to the right.
class _TextSelectionToolbarRightEdgeAlign extends SingleChildRenderObjectWidget {
  const _TextSelectionToolbarRightEdgeAlign({
    Key? key,
    required Widget child,
    required this.overflowOpen,
  }) : assert(child != null),
       assert(overflowOpen != null),
       super(key: key, child: child);

  final bool overflowOpen;

  @override
  _TextSelectionToolbarRightEdgeAlignRenderBox createRenderObject(BuildContext context) {
    return _TextSelectionToolbarRightEdgeAlignRenderBox(overflowOpen: overflowOpen);
  }

  @override
  void updateRenderObject(BuildContext context, _TextSelectionToolbarRightEdgeAlignRenderBox renderObject) {
    renderObject.overflowOpen = overflowOpen;
  }
}

class _TextSelectionToolbarRightEdgeAlignRenderBox extends RenderProxyBox {
  _TextSelectionToolbarRightEdgeAlignRenderBox({
    required bool overflowOpen,
  }) : assert(overflowOpen != null),
       _overflowOpen = overflowOpen,
       super();

  // The width of the menu when it was closed. This is used to achieve the
  // behavior where the open menu aligns its right edge to the closed menu's
  // right edge.
  double? _closedWidth;

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
    child!.layout(constraints.loosen(), parentUsesSize: true);

    // Save the width when the menu is closed. If the menu changes, this width
    // is invalid, so it's important that this RenderBox be recreated in that
    // case. Currently, this is achieved by providing a new key to
    // _TextSelectionToolbarRightEdgeAlign.
    if (!overflowOpen && _closedWidth == null) {
      _closedWidth = child!.size.width;
    }

    size = constraints.constrain(Size(
      // If the open menu is wider than the closed menu, just use its own width
      // and don't worry about aligning the right edges.
      // _closedWidth is used even when the menu is closed to allow it to
      // animate its size while keeping the same right alignment.
      _closedWidth == null || child!.size.width > _closedWidth! ? child!.size.width : _closedWidth!,
      child!.size.height,
    ));

    // Set the offset in the parent data such that the child will be aligned to
    // the right.
    final ToolbarItemsParentData childParentData = child!.parentData! as ToolbarItemsParentData;
    childParentData.offset = Offset(
      size.width - child!.size.width,
      0.0,
    );
  }

  // Paint at the offset set in the parent data.
  @override
  void paint(PaintingContext context, Offset offset) {
    final ToolbarItemsParentData childParentData = child!.parentData! as ToolbarItemsParentData;
    context.paintChild(child!, childParentData.offset + offset);
  }

  // Include the parent data offset in the hit test.
  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    // The x, y parameters have the top left of the node's box as the origin.
    final ToolbarItemsParentData childParentData = child!.parentData! as ToolbarItemsParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child!.hitTest(result, position: transformed);
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
    final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;
    transform.translate(childParentData.offset.dx, childParentData.offset.dy);
    super.applyPaintTransform(child, transform);
  }
}

// Renders the menu items in the correct positions in the menu and its overflow
// submenu based on calculating which item would first overflow.
class _TextSelectionToolbarItemsLayout extends MultiChildRenderObjectWidget {
  _TextSelectionToolbarItemsLayout({
    Key? key,
    required this.isAbove,
    required this.overflowOpen,
    required List<Widget> children,
  }) : assert(children != null),
       assert(isAbove != null),
       assert(overflowOpen != null),
       super(key: key, children: children);

  final bool isAbove;
  final bool overflowOpen;

  @override
  _TextSelectionToolbarItemsLayoutRenderBox createRenderObject(BuildContext context) {
    return _TextSelectionToolbarItemsLayoutRenderBox(
      isAbove: isAbove,
      overflowOpen: overflowOpen,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _TextSelectionToolbarItemsLayoutRenderBox renderObject) {
    renderObject
      ..isAbove = isAbove
      ..overflowOpen = overflowOpen;
  }

  @override
  _TextSelectionToolbarItemsLayoutElement createElement() => _TextSelectionToolbarItemsLayoutElement(this);
}

class _TextSelectionToolbarItemsLayoutElement extends MultiChildRenderObjectElement {
  _TextSelectionToolbarItemsLayoutElement(
    MultiChildRenderObjectWidget widget,
  ) : super(widget);

  static bool _shouldPaint(Element child) {
    return (child.renderObject!.parentData! as ToolbarItemsParentData).shouldPaint;
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where(_shouldPaint).forEach(visitor);
  }
}

class _TextSelectionToolbarItemsLayoutRenderBox extends RenderBox with ContainerRenderObjectMixin<RenderBox, ToolbarItemsParentData> {
  _TextSelectionToolbarItemsLayoutRenderBox({
    required bool isAbove,
    required bool overflowOpen,
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
    final RenderBox navButton = firstChild!;
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
    final RenderBox navButton = firstChild!;
    double overflowHeight = overflowOpen && !isAbove ? navButton.size.height : 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;

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
    final ToolbarItemsParentData navButtonParentData = navButton.parentData! as ToolbarItemsParentData;
    if (_shouldPaintChild(firstChild!, 0)) {
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
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;
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
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    // The x, y parameters have the top left of the node's box as the origin.
    RenderBox? child = lastChild;
    while (child != null) {
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;

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
          return child!.hitTest(result, position: transformed);
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
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;
      if (childParentData.shouldPaint) {
        visitor(renderObjectChild);
      }
    });
  }
}

// The Material-styled toolbar outline. Fill it with any widgets you want. No
// overflow ability.
class _MaterialTextSelectionToolbarShapeNew extends StatelessWidget {
  const _MaterialTextSelectionToolbarShapeNew({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      // This value was eyeballed to match the native text selection menu on
      // a Pixel 2 running Android 10.
      borderRadius: const BorderRadius.all(Radius.circular(7.0)),
      clipBehavior: Clip.antiAlias,
      elevation: 1.0,
      type: MaterialType.card,
      child: child,
    );
  }
}

// TODO(justinmc): Instead of isFirst/isLast, use an enum?
// TODO(justinmc): Document.
/// A button styled like a Material native Android text selection menu button.
class TextSelectionMenuTextButton extends StatelessWidget {
  const TextSelectionMenuTextButton({
    Key? key,
    required this.child,
    required this.isFirst,
    required this.isLast,
    this.onPressed,
  }) : super(key: key);

  final Widget child;

  // isFirst and isLast modify the padding in agreement with the first and last
  // items in Material's native Android text selection menu.
  final bool isFirst;
  final bool isLast;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // TODO(hansmuller): Should be colorScheme.onSurface
    final ThemeData theme = Theme.of(context)!;
    final bool isDark = theme.colorScheme.brightness == Brightness.dark;
    final Color primary = isDark ? Colors.white : Colors.black87;

    return TextButton(
      style: TextButton.styleFrom(
        primary: primary,
        shape: const RoundedRectangleBorder(),
        minimumSize: const Size(kMinInteractiveDimension, kMinInteractiveDimension),
        padding: EdgeInsets.only(
          // These values were eyeballed to match the native text selection menu
          // on a Pixel 2 running Android 10.
          left: 9.5 + (isFirst ? 5.0 : 0.0),
          right: 9.5 + (isLast ? 5.0 : 0.0),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

// A button styled like a Material native Android text selection overflow menu
// forward and back controls.
class _TextSelectionMenuOverflowButton extends StatelessWidget {
  const _TextSelectionMenuOverflowButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  }) : super(key: key);

  final Icon icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.card,
      child: IconButton(
        // TODO(justinmc): This should be an AnimatedIcon, but
        // AnimatedIcons doesn't yet support arrow_back to more_vert.
        // https://github.com/flutter/flutter/issues/51209
        icon: icon,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

/// Draws a single text selection handle which points up and to the left.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({ required this.color });

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

/// Text selection controls that follow the Material Design specification.
final TextSelectionControls materialTextSelectionControls = MaterialTextSelectionControls();

// Justin's widget hierarchy directory:
// _TextSelectionToolbar
//   Directly handles buildToolbar at the highest level.
//   Shouldn't be made public, but users may learn from it as an example of how
//   to use the other public classes.
// TODO(justinmc): Rename so it's not so similar to TextSelectionToolbar.
//
// TextSelectionToolbar
//   Takes in simple parameters and builds a fully functional toolbar.
//   The main public class.
// TODO(justinmc): Is it ok that it needs fitsAbove? Why again?
//
// _TextSelectionToolbarLayoutDelegate
//   Centers the toolbar at the given anchor and ensures it remains on screen.
//   Candidate for a second round of making things public.
//
// _TextSelectionToolbarOverflowableNew
//   Renders the given children in the given toolbarBuilder, creates the
//   overflow navigation button, and maintains overflowOpen (whether the
//   overflow menu is open, not whether or not it overflows).
// TODO(justinmc): Rename.
//
// _TextSelectionToolbarRightEdgeAlign
//   Layout only, lines up right edge when overflow is open.
//
// _TextSelectionToolbarItemsLayout
//   Layout only.
//   Does all of the hard overflow work. Detects overflow. Lays out the buttons
//   in regular or overflow menu.
//
// _MaterialTextSelectionToolbarShapeNew
//   Just does the shape and elevation of the toolbar.
//   Phase 2 public thing.
// TODO(justinmc): Rename.
//
// TextSelectionMenuTextButton
//   A Material-style text selection menu button.
//   Public!
//
// Critical user journeys:
//   Add another button that looks like the others.
//   Remove an existing button.
//   Change the appearance of everything.
