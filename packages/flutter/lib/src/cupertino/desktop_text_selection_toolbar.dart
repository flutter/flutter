import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'text_selection_toolbar.dart';

// Minimal padding from all edges of the selection toolbar to all edges of the
// screen.
const double _kToolbarScreenPadding = 8.0;

// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const Color _kToolbarDividerColor = Color(0xFF808080);

// These values were measured from a screenshot of TextEdit on MacOS 10.15.7 on
// a Macbook Pro.
const double _kToolbarWidth = 222.0;
const Color _kToolbarBorderColor = Color(0xFF505152);
const Radius _kToolbarBorderRadius = Radius.circular(4.0);
const Color _kToolbarBackgroundColor = Color(0xFF2D2E31);

/*
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
*/


/// An iOS-style text selection toolbar.
///
/// Typically displays buttons for text manipulation, e.g. copying and pasting
/// text.
///
/// Tries to position itself above [anchorAbove], but if it doesn't fit, then
/// it positions itself below [anchorBelow].
///
/// If any children don't fit in the menu, an overflow menu will automatically
/// be created.
///
/// See also:
///
///  * [TextSelectionControls.buildToolbar], where this is used by default to
///    build an iOS-style toolbar.
///  * [TextSelectionToolbar], which is similar, but builds an Android-style
///    toolbar.
class CupertinoDesktopTextSelectionToolbar extends StatelessWidget {
  /// Creates an instance of CupertinoTextSelectionToolbar.
  const CupertinoDesktopTextSelectionToolbar({
    Key? key,
    required this.anchorAbove,
    required this.anchorBelow,
    required this.children,
    this.toolbarBuilder = _defaultToolbarBuilder,
  }) : assert(children.length > 0),
       super(key: key);

  /// {@macro flutter.material.TextSelectionToolbar.anchorAbove}
  final Offset anchorAbove;

  /// {@macro flutter.material.TextSelectionToolbar.anchorBelow}
  final Offset anchorBelow;

  /// {@macro flutter.material.TextSelectionToolbar.children}
  ///
  /// See also:
  ///   * [CupertinoTextSelectionToolbarButton], which builds a default
  ///     Cupertino-style text selection toolbar text button.
  final List<Widget> children;

  /// {@macro flutter.material.TextSelectionToolbar.toolbarBuilder}
  ///
  /// The given anchor and isAbove can be used to position an arrow, as in the
  /// default Cupertino toolbar.
  final CupertinoToolbarBuilder toolbarBuilder;

  // Builds a toolbar just like the default iOS toolbar, with the right color
  // background and a rounded cutout with an arrow.
  static Widget _defaultToolbarBuilder(BuildContext context, Offset anchor, bool isAbove, Widget child) {
    // TODO(justinmc): I just removed Shape here, is this ok otherwise?
    return DecoratedBox(
      decoration: const BoxDecoration(color: _kToolbarDividerColor),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final double paddingAbove = mediaQuery.padding.top + _kToolbarScreenPadding;

    const Offset contentPaddingAdjustment = Offset.zero;// Offset(0.0, _kToolbarContentDistance);
    final Offset localAdjustment = Offset(_kToolbarScreenPadding, paddingAbove);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kToolbarScreenPadding,
        paddingAbove,
        _kToolbarScreenPadding,
        _kToolbarScreenPadding,
      ),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: anchorAbove - localAdjustment - contentPaddingAdjustment,
          anchorBelow: anchorBelow - localAdjustment + contentPaddingAdjustment,
        ),
        child: _CupertinoDesktopTextSelectionToolbarContent(
          children: children,
        ),
      ),
    );
  }
}

// TODO(justinmc): Anything I can take from the refactored mobile Content?
// Renders the content of the selection menu and maintains the page state.
class _CupertinoDesktopTextSelectionToolbarContent extends StatefulWidget {
  const _CupertinoDesktopTextSelectionToolbarContent({
    Key? key,
    required this.children,
  }) : assert(children != null),
       // This ignore is used because .isNotEmpty isn't compatible with const.
       assert(children.length > 0), // ignore: prefer_is_empty
       super(key: key);

  final List<Widget> children;

  @override
  _CupertinoDesktopTextSelectionToolbarContentState createState() => _CupertinoDesktopTextSelectionToolbarContentState();
}

class _CupertinoDesktopTextSelectionToolbarContentState extends State<_CupertinoDesktopTextSelectionToolbarContent> with TickerProviderStateMixin {
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
  void didUpdateWidget(_CupertinoDesktopTextSelectionToolbarContent oldWidget) {
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
    return Container(
      width: _kToolbarWidth,
      decoration: BoxDecoration(
        color: _kToolbarBackgroundColor,
        border: Border.all(
          color: _kToolbarBorderColor,
        ),
        borderRadius: const BorderRadius.all(_kToolbarBorderRadius)
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 0.0,
          // This value was measured from a screenshot of TextEdit on MacOS
          // 10.15.7 on a Macbook Pro.
          vertical: 3.0,
        ),
        child: FadeTransition(
          opacity: _controller,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.children,
          ),
        ),
      ),
    );
  }
}
