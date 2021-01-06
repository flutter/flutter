// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import 'text_selection_toolbar_button.dart';

// Values extracted from https://developer.apple.com/design/resources/.
// The height of the toolbar, including the arrow.
const double _kToolbarHeight = 43.0;
// Vertical distance between the tip of the arrow and the line of text the arrow
// is pointing to. The value used here is eyeballed.
const double _kToolbarContentDistance = 8.0;
// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;
const Size _kToolbarArrowSize = Size(14.0, 7.0);

// Values extracted from https://developer.apple.com/design/resources/.
const Radius _kToolbarBorderRadius = Radius.circular(8);

// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const Color _kToolbarDividerColor = Color(0xFF808080);

/// An iOS-style text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// See also:
///
///  * [TextSelectionControls.buildToolbar], where this is used by default to
///    build an iOS-style toolbar.
class CupertinoTextSelectionToolbar extends StatelessWidget {
  /// Creates an instancwe of CupertinoTextSelectionToolbar.
  const CupertinoTextSelectionToolbar({
    Key? key,
    required Offset anchorAbove,
    required Offset anchorBelow,
    required List<Widget> children,
  }) : assert(children.length > 0),
       _anchorAbove = anchorAbove,
       _anchorBelow = anchorBelow,
       _children = children,
       super(key: key);

  final Offset _anchorAbove;
  final Offset _anchorBelow;

  final List<Widget> _children;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double toolbarHeightNeeded = mediaQuery.padding.top
      + _kToolbarScreenPadding
      + _kToolbarHeight
      + _kToolbarContentDistance;
    final bool isAbove = _anchorAbove.dy >= toolbarHeightNeeded;

    return _CupertinoTextSelectionToolbarThing(
      anchor: isAbove ? _anchorAbove : _anchorBelow,
      isAbove: isAbove,
      child: _CupertinoTextSelectionToolbarContent(
        isAbove: isAbove,
        children: _children,
      ),
    );
  }
}

// TODO(justinmc): Document and better name.
// Positions the toolbar at the given position with the arrow pointing in the
// given direction.
class _CupertinoTextSelectionToolbarThing extends SingleChildRenderObjectWidget {
  /// Create an instance of CupertinoTextSelectionToolbar.
  const _CupertinoTextSelectionToolbarThing({
    Key? key,
    required Offset anchor,
    required bool isAbove,
    Widget? child,
  }) : _anchor = anchor,
       _isAbove = isAbove,
       super(key: key, child: child);

  final Offset _anchor;

  // Whether the arrow should point down and be attached to the bottom
  // of the toolbar, or point up and be attached to the top of the toolbar.
  final bool _isAbove;

  @override
  _ToolbarRenderBox createRenderObject(BuildContext context) => _ToolbarRenderBox(
    _anchor,
    _isAbove,
    null,
  );

  @override
  void updateRenderObject(BuildContext context, _ToolbarRenderBox renderObject) {
    renderObject
      ..anchor = _anchor
      ..isAbove = _isAbove;
  }
}

// Positions and clips the toolbar.
//
// The toolbar is positioned at the correct anchor facing up or down.
//
// It is clipped down to a rounded rectangle with a protruding arrow.
class _ToolbarRenderBox extends RenderShiftedBox {
  _ToolbarRenderBox(
    this._anchor,
    this._isAbove,
    RenderBox? child,
  ) : super(child);


  @override
  bool get isRepaintBoundary => true;

  Offset _anchor;
  set anchor(Offset value) {
    if (value == _anchor) {
      return;
    }
    _anchor = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  bool _isAbove;
  set isAbove(bool value) {
    if (_isAbove == value) {
      return;
    }
    _isAbove = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  // The child is tall enough to have the arrow clipped out of it on both sides
  // top and bottom. Since _kToolbarHeight includes the height of one arrow, the
  // total height that the child is given is that plus one more arrow height.
  // The extra height on the opposite side of the arrow will be clipped out. By
  // using this appraoch, the buttons don't need any special padding that
  // depends on isAbove.
  final BoxConstraints _heightConstraint = BoxConstraints.tightFor(
    height: _kToolbarHeight + _kToolbarArrowSize.height,
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
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

    child!.layout(_heightConstraint.enforce(enforcedConstraint), parentUsesSize: true);
    final BoxParentData childParentData = child!.parentData! as BoxParentData;

    // The local x-coordinate of the center of the toolbar. The toolbar would
    // like to horizontally center itself on the anchor if possible.
    final double leftBound = child!.size.width/2 + _kToolbarScreenPadding;
    final double rightBound = constraints.maxWidth - child!.size.width/2 - _kToolbarScreenPadding;
    final double adjustedCenterX = _anchor.dx.clamp(leftBound, rightBound);

    childParentData.offset = Offset(
      adjustedCenterX - child!.size.width/2,
      _isAbove
          ? _anchor.dy - child!.size.height - _kToolbarContentDistance
          : _anchor.dy + _kToolbarContentDistance,
    );
  }

  // The path is described in the toolbar's coordinate system.
  Path _clipPath() {
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    final Path rrect = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset(0.0, _kToolbarArrowSize.height)
            & Size(
                child!.size.width,
                child!.size.height - _kToolbarArrowSize.height * 2,
              ),
          _kToolbarBorderRadius,
        ),
      );

    final double centerX = childParentData.offset.dx + child!.size.width / 2;
    final double arrowXOffsetFromCenter = _anchor.dx - centerX;
    final double arrowTipX = child!.size.width / 2 + arrowXOffsetFromCenter;

    final double arrowBaseY = _isAbove
      ? child!.size.height - _kToolbarArrowSize.height
      : _kToolbarArrowSize.height;

    final double arrowTipY = _isAbove ? child!.size.height : 0;

    final Path arrow = Path()
      ..moveTo(arrowTipX, arrowTipY)
      ..lineTo(arrowTipX - _kToolbarArrowSize.width / 2, arrowBaseY)
      ..lineTo(arrowTipX + _kToolbarArrowSize.width / 2, arrowBaseY)
      ..close();

    return Path.combine(PathOperation.union, rrect, arrow);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    _clipPathLayer = context.pushClipPath(
      needsCompositing,
      offset + childParentData.offset,
      Offset.zero & child!.size,
      _clipPath(),
      (PaintingContext innerContext, Offset innerOffset) => innerContext.paintChild(child!, innerOffset),
      oldLayer: _clipPathLayer
    );
  }

  ClipPathLayer? _clipPathLayer;
  Paint? _debugPaint;

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
          const <Color>[Color(0x00000000), Color(0xFFFF00FF), Color(0xFFFF00FF), Color(0x00000000)],
          const <double>[0.25, 0.25, 0.75, 0.75],
          TileMode.repeated,
        )
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final BoxParentData childParentData = child!.parentData! as BoxParentData;
      context.canvas.drawPath(_clipPath().shift(offset + childParentData.offset), _debugPaint!);
      return true;
    }());
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    // Positions outside of the clipped area of the child are not counted as
    // hits.
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    final Rect hitBox = Rect.fromLTWH(
      childParentData.offset.dx,
      childParentData.offset.dy + _kToolbarArrowSize.height,
      child!.size.width,
      child!.size.height - _kToolbarArrowSize.height * 2,
    );
    if (!hitBox.contains(position)) {
      return false;
    }

    return super.hitTestChildren(result, position: position);
  }
}

// Renders the content of the selection menu and maintains the page state.
class _CupertinoTextSelectionToolbarContent extends StatefulWidget {
  const _CupertinoTextSelectionToolbarContent({
    Key? key,
    required this.children,
    required this.isAbove,
  }) : assert(children != null),
       // This ignore is used because .isNotEmpty isn't compatible with const.
       assert(children.length > 0), // ignore: prefer_is_empty
       super(key: key);

  final List<Widget> children;
  final bool isAbove;

  @override
  _CupertinoTextSelectionToolbarContentState createState() => _CupertinoTextSelectionToolbarContentState();
}

class _CupertinoTextSelectionToolbarContentState extends State<_CupertinoTextSelectionToolbarContent> with TickerProviderStateMixin {
  // Controls the fading of the buttons within the menu during page transitions.
  late AnimationController _controller;
  int _page = 0;
  int? _nextPage;

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
      _page = _nextPage!;
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
    return DecoratedBox(
      decoration: const BoxDecoration(color: _kToolbarDividerColor),
      child: FadeTransition(
        opacity: _controller,
        child: _CupertinoTextSelectionToolbarItems(
          page: _page,
          backButton: CupertinoTextSelectionToolbarButton(
            onPressed: _handlePreviousPage,
            child: CupertinoTextSelectionToolbarButton.getText('◀'),
          ),
          dividerWidth: 1.0 / MediaQuery.of(context).devicePixelRatio,
          nextButton: CupertinoTextSelectionToolbarButton(
            onPressed: _handleNextPage,
            child: CupertinoTextSelectionToolbarButton.getText('▶'),
          ),
          nextButtonDisabled: CupertinoTextSelectionToolbarButton(
            child: CupertinoTextSelectionToolbarButton.getText('◀', false),
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
    Key? key,
    required this.page,
    required this.children,
    required this.backButton,
    required this.dividerWidth,
    required this.nextButton,
    required this.nextButtonDisabled,
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

  late List<Element> _children;
  final Map<_CupertinoTextSelectionToolbarItemsSlot, Element> slotToChild = <_CupertinoTextSelectionToolbarItemsSlot, Element>{};

  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  _CupertinoTextSelectionToolbarItems get widget => super.widget as _CupertinoTextSelectionToolbarItems;

  @override
  _CupertinoTextSelectionToolbarItemsRenderBox get renderObject => super.renderObject as _CupertinoTextSelectionToolbarItemsRenderBox;

  void _updateRenderObject(RenderBox? child, _CupertinoTextSelectionToolbarItemsSlot slot) {
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
      renderObject.insert(child as RenderBox, after: slot.value?.renderObject as RenderBox?);
      return;
    }
    assert(false, 'slot must be _CupertinoTextSelectionToolbarItemsSlot or IndexedSlot');
  }

  // This is not reachable for children that don't have an IndexedSlot.
  @override
  void moveRenderObjectChild(RenderObject child, IndexedSlot<Element> oldSlot, IndexedSlot<Element> newSlot) {
    assert(child.parent == renderObject);
    renderObject.move(child as RenderBox, after: newSlot.value.renderObject as RenderBox?);
  }

  static bool _shouldPaint(Element child) {
    return (child.renderObject!.parentData! as ToolbarItemsParentData).shouldPaint;
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
    final Element? oldChild = slotToChild[slot];
    final Element? newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
    }
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    // Mount slotted children.
    _mountChild(widget.backButton, _CupertinoTextSelectionToolbarItemsSlot.backButton);
    _mountChild(widget.nextButton, _CupertinoTextSelectionToolbarItemsSlot.nextButton);
    _mountChild(widget.nextButtonDisabled, _CupertinoTextSelectionToolbarItemsSlot.nextButtonDisabled);

    // Mount list children.
    _children = List<Element>.filled(widget.children.length, _NullElement.instance);
    Element? previousChild;
    for (int i = 0; i < _children.length; i += 1) {
      final Element newChild = inflateWidget(widget.children[i], IndexedSlot<Element?>(i, previousChild));
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
    required double dividerWidth,
    required int page,
  }) : assert(dividerWidth != null),
       assert(page != null),
       _dividerWidth = dividerWidth,
       _page = page,
       super();

  final Map<_CupertinoTextSelectionToolbarItemsSlot, RenderBox> slottedChildren = <_CupertinoTextSelectionToolbarItemsSlot, RenderBox>{};

  RenderBox? _updateChild(RenderBox? oldChild, RenderBox? newChild, _CupertinoTextSelectionToolbarItemsSlot slot) {
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

  RenderBox? _backButton;
  RenderBox? get backButton => _backButton;
  set backButton(RenderBox? value) {
    _backButton = _updateChild(_backButton, value, _CupertinoTextSelectionToolbarItemsSlot.backButton);
  }

  RenderBox? _nextButton;
  RenderBox? get nextButton => _nextButton;
  set nextButton(RenderBox? value) {
    _nextButton = _updateChild(_nextButton, value, _CupertinoTextSelectionToolbarItemsSlot.nextButton);
  }

  RenderBox? _nextButtonDisabled;
  RenderBox? get nextButtonDisabled => _nextButtonDisabled;
  set nextButtonDisabled(RenderBox? value) {
    _nextButtonDisabled = _updateChild(_nextButtonDisabled, value, _CupertinoTextSelectionToolbarItemsSlot.nextButtonDisabled);
  }

  @override
  void performLayout() {
    if (firstChild == null) {
      size = constraints.smallest;
      return;
    }

    // Layout slotted children.
    _backButton!.layout(constraints.loosen(), parentUsesSize: true);
    _nextButton!.layout(constraints.loosen(), parentUsesSize: true);
    _nextButtonDisabled!.layout(constraints.loosen(), parentUsesSize: true);

    final double subsequentPageButtonsWidth =
        _backButton!.size.width + _nextButton!.size.width;
    double currentButtonPosition = 0.0;
    late double toolbarWidth; // The width of the whole widget.
    late double firstPageWidth;
    int currentPage = 0;
    int i = -1;
    visitChildren((RenderObject renderObjectChild) {
      i++;
      final RenderBox child = renderObjectChild as RenderBox;
      final ToolbarItemsParentData childParentData =
          child.parentData! as ToolbarItemsParentData;
      childParentData.shouldPaint = false;

      // Skip slotted children and children on pages after the visible page.
      if (_isSlottedChild(child) || currentPage > _page) {
        return;
      }

      double paginationButtonsWidth = 0.0;
      if (currentPage == 0) {
        // If this is the last child, it's ok to fit without a forward button.
        paginationButtonsWidth =
            i == childCount - 1 ? 0.0 : _nextButton!.size.width;
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
        currentButtonPosition = _backButton!.size.width + dividerWidth;
        paginationButtonsWidth = _backButton!.size.width + _nextButton!.size.width;
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
        firstPageWidth = currentButtonPosition + _nextButton!.size.width;
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
          _nextButton!.parentData! as ToolbarItemsParentData;
      final ToolbarItemsParentData nextButtonDisabledParentData =
          _nextButtonDisabled!.parentData! as ToolbarItemsParentData;
      final ToolbarItemsParentData backButtonParentData =
          _backButton!.parentData! as ToolbarItemsParentData;
      // The forward button always shows if there is more than one page, even on
      // the last page (it's just disabled).
      if (page == currentPage) {
        nextButtonDisabledParentData.offset = Offset(toolbarWidth, 0.0);
        nextButtonDisabledParentData.shouldPaint = true;
        toolbarWidth += nextButtonDisabled!.size.width;
      } else {
        nextButtonParentData.offset = Offset(toolbarWidth, 0.0);
        nextButtonParentData.shouldPaint = true;
        toolbarWidth += nextButton!.size.width;
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
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;

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
  static bool hitTestChild(RenderBox? child, BoxHitTestResult result, { required Offset position }) {
    if (child == null) {
      return false;
    }
    final ToolbarItemsParentData childParentData =
        child.parentData! as ToolbarItemsParentData;
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
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    // Hit test list children.
    // The x, y parameters have the top left of the node's box as the origin.
    RenderBox? child = lastChild;
    while (child != null) {
      final ToolbarItemsParentData childParentData = child.parentData! as ToolbarItemsParentData;

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
      visitor(_backButton!);
    }
    if (_nextButton != null) {
      visitor(_nextButton!);
    }
    if (_nextButtonDisabled != null) {
      visitor(_nextButtonDisabled!);
    }
    // Visit the list children.
    super.visitChildren(visitor);
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

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    visitChildren((RenderObject renderObjectChild) {
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

class _NullElement extends Element {
  _NullElement() : super(_NullWidget());

  static _NullElement instance = _NullElement();

  @override
  bool get debugDoingBuild => throw UnimplementedError();

  @override
  void performRebuild() { }
}

class _NullWidget extends Widget {
  @override
  Element createElement() => throw UnimplementedError();
}
