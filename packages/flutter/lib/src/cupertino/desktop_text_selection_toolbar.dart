import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;

/// An iOS-style toolbar that appears in response to text selection.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting text.
///
/// See also:
///
///  * [TextSelectionControls.buildToolbar], where [CupertinoDesktopTextSelectionToolbar]
///    will be used to build an iOS-style toolbar.
@visibleForTesting
class CupertinoDesktopTextSelectionToolbar extends SingleChildRenderObjectWidget {
  const CupertinoDesktopTextSelectionToolbar({
    Key? key,
    required Offset anchor,
    Widget? child,
  }) : _anchor = anchor,
       super(key: key, child: child);

  final Offset _anchor;

  @override
  _ToolbarRenderBox createRenderObject(BuildContext context) => _ToolbarRenderBox(_anchor, null);

  @override
  void updateRenderObject(BuildContext context, _ToolbarRenderBox renderObject) {
    renderObject.anchor = _anchor;
  }
}

// TODO(justinmc): In regular Coop, this was moved to public TextSelectionToolbarLayout.
class _ToolbarRenderBox extends RenderShiftedBox {
  _ToolbarRenderBox(
    this._anchor,
    RenderBox? child,
  ) : super(child);


  @override
  bool get isRepaintBoundary => true;

  Offset _anchor;
  set anchor(Offset value) {
    if (_anchor == value) {
      return;
    }
    _anchor = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void performLayout() {
    if (child == null) {
      return;
    }
    size = constraints.biggest;
    child!.layout(constraints, parentUsesSize: true);

    final BoxParentData childParentData = child!.parentData! as BoxParentData;

    // The local x-coordinate of the center of the toolbar.
    final double upperBound = size.width - child!.size.width/2 - _kToolbarScreenPadding;
    final double adjustedCenterX = _anchor.dx.clamp(_kToolbarScreenPadding, upperBound);

    // TODO(justinmc): When reaching the bottom of the screen, should move up.
    childParentData.offset = Offset(adjustedCenterX, _anchor.dy);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    context.paintChild(child!, childParentData.offset);
  }
}
