// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'interface_level.dart';
import 'localizations.dart';
import 'scrollbar.dart';

// TODO(abarth): These constants probably belong somewhere more general.

// Used XD to flutter plugin(https://github.com/AdobeXD/xd-to-flutter-plugin/)
// to derive values of TextStyle(height and letterSpacing) from
// Adobe XD template for iOS 13, which can be found in
// Apple Design Resources(https://developer.apple.com/design/resources/).
// However the values are not exactly the same as native, so eyeballing is needed.
const TextStyle _kCupertinoDialogTitleStyle = TextStyle(
  fontFamily: '.SF UI Display',
  inherit: false,
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  height: 1.3,
  letterSpacing: -0.5,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogContentStyle = TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w400,
  height: 1.35,
  letterSpacing: -0.2,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogActionStyle = TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 16.8,
  fontWeight: FontWeight.w400,
  textBaseline: TextBaseline.alphabetic,
);

// iOS dialogs have a normal display width and another display width that is
// used when the device is in accessibility mode. Each of these widths are
// listed below.
const double _kCupertinoDialogWidth = 270.0;
const double _kAccessibilityCupertinoDialogWidth = 310.0;

const double _kBlurAmount = 20.0;
const double _kEdgePadding = 20.0;
const double _kMinButtonHeight = 45.0;
const double _kMinButtonFontSize = 10.0;
const double _kDialogCornerRadius = 14.0;
const double _kDividerThickness = 1.0;

// A translucent color that is painted on top of the blurred backdrop as the
// dialog's background color
// Extracted from https://developer.apple.com/design/resources/.
const Color _kDialogColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xCCF2F2F2),
  darkColor: Color(0xBF1E1E1E),
);

// Translucent light gray that is painted on top of the blurred backdrop as the
// background color of a pressed button.
// Eyeballed from iOS 13 beta simulator.
const Color _kDialogPressedColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFE1E1E1),
  darkColor: Color(0xFF2E2E2E),
);

// The alert dialog layout policy changes depending on whether the user is using
// a "regular" font size vs a "large" font size. This is a spectrum. There are
// many "regular" font sizes and many "large" font sizes. But depending on which
// policy is currently being used, a dialog is laid out differently.
//
// Empirically, the jump from one policy to the other occurs at the following text
// scale factors:
// Largest regular scale factor:  1.3529411764705883
// Smallest large scale factor:   1.6470588235294117
//
// The following constant represents a division in text scale factor beyond which
// we want to change how the dialog is laid out.
const double _kMaxRegularTextScaleFactor = 1.4;

// Accessibility mode on iOS is determined by the text scale factor that the
// user has selected.
bool _isInAccessibilityMode(BuildContext context) {
  final MediaQueryData? data = MediaQuery.maybeOf(context);
  return data != null && data.textScaleFactor > _kMaxRegularTextScaleFactor;
}

/// An iOS-style alert dialog.
///
/// An alert dialog informs the user about situations that require
/// acknowledgement. An alert dialog has an optional title, optional content,
/// and an optional list of actions. The title is displayed above the content
/// and the actions are displayed below the content.
///
/// This dialog styles its title and content (typically a message) to match the
/// standard iOS title and message dialog text style. These default styles can
/// be overridden by explicitly defining [TextStyle]s for [Text] widgets that
/// are part of the title or content.
///
/// To display action buttons that look like standard iOS dialog buttons,
/// provide [CupertinoDialogAction]s for the [actions] given to this dialog.
///
/// Typically passed as the child widget to [showDialog], which displays the
/// dialog.
///
/// See also:
///
///  * [CupertinoPopupSurface], which is a generic iOS-style popup surface that
///    holds arbitrary content to create custom popups.
///  * [CupertinoDialogAction], which is an iOS-style dialog button.
///  * [AlertDialog], a Material Design alert dialog.
///  * <https://developer.apple.com/ios/human-interface-guidelines/views/alerts/>
class CupertinoAlertDialog extends StatelessWidget {
  /// Creates an iOS-style alert dialog.
  ///
  /// The [actions] must not be null.
  const CupertinoAlertDialog({
    Key? key,
    this.title,
    this.content,
    this.actions = const <Widget>[],
    this.scrollController,
    this.actionScrollController,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
  }) : assert(actions != null),
       super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  ///
  /// Typically a [Text] widget.
  final Widget? content;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  ///
  /// Typically this is a list of [CupertinoDialogAction] widgets.
  final List<Widget> actions;

  /// A scroll controller that can be used to control the scrolling of the
  /// [content] in the dialog.
  ///
  /// Defaults to null, and is typically not needed, since most alert messages
  /// are short.
  ///
  /// See also:
  ///
  ///  * [actionScrollController], which can be used for controlling the actions
  ///    section when there are many actions.
  final ScrollController? scrollController;

  /// A scroll controller that can be used to control the scrolling of the
  /// actions in the dialog.
  ///
  /// Defaults to null, and is typically not needed.
  ///
  /// See also:
  ///
  ///  * [scrollController], which can be used for controlling the [content]
  ///    section when it is long.
  final ScrollController? actionScrollController;

  /// {@macro flutter.material.dialog.insetAnimationDuration}
  final Duration insetAnimationDuration;

  /// {@macro flutter.material.dialog.insetAnimationCurve}
  final Curve insetAnimationCurve;

  Widget _buildContent(BuildContext context) {
    final List<Widget> children = <Widget>[
      if (title != null || content != null)
        Flexible(
          flex: 3,
          child: _CupertinoAlertContentSection(
            title: title,
            content: content,
            scrollController: scrollController,
          ),
        ),
    ];

    return Container(
      color: CupertinoDynamicColor.resolve(_kDialogColor, context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildActions() {
    Widget actionSection = Container(
      height: 0.0,
    );
    if (actions.isNotEmpty) {
      actionSection = _CupertinoAlertActionSection(
        children: actions,
        scrollController: actionScrollController,
      );
    }

    return actionSection;
  }

  @override
  Widget build(BuildContext context) {
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    final bool isInAccessibilityMode = _isInAccessibilityMode(context);
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return CupertinoUserInterfaceLevel(
      data: CupertinoUserInterfaceLevelData.elevated,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          // iOS does not shrink dialog content below a 1.0 scale factor
          textScaleFactor: math.max(textScaleFactor, 1.0),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets +
                  const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
              duration: insetAnimationDuration,
              curve: insetAnimationCurve,
              child: MediaQuery.removeViewInsets(
                removeLeft: true,
                removeTop: true,
                removeRight: true,
                removeBottom: true,
                context: context,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: _kEdgePadding),
                    width: isInAccessibilityMode
                      ? _kAccessibilityCupertinoDialogWidth
                      : _kCupertinoDialogWidth,
                    child: CupertinoPopupSurface(
                      isSurfacePainted: false,
                      child: Semantics(
                        namesRoute: true,
                        scopesRoute: true,
                        explicitChildNodes: true,
                        label: localizations.alertDialogLabel,
                        child: _CupertinoDialogRenderWidget(
                          contentSection: _buildContent(context),
                          actionsSection: _buildActions(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Rounded rectangle surface that looks like an iOS popup surface, e.g., alert dialog
/// and action sheet.
///
/// A [CupertinoPopupSurface] can be configured to paint or not paint a white
/// color on top of its blurred area. Typical usage should paint white on top
/// of the blur. However, the white paint can be disabled for the purpose of
/// rendering divider gaps for a more complicated layout, e.g., [CupertinoAlertDialog].
/// Additionally, the white paint can be disabled to render a blurred rounded
/// rectangle without any color (similar to iOS's volume control popup).
///
/// See also:
///
///  * [CupertinoAlertDialog], which is a dialog with a title, content, and
///    actions.
///  * <https://developer.apple.com/ios/human-interface-guidelines/views/alerts/>
class CupertinoPopupSurface extends StatelessWidget {
  /// Creates an iOS-style rounded rectangle popup surface.
  const CupertinoPopupSurface({
    Key? key,
    this.isSurfacePainted = true,
    this.child,
  }) : super(key: key);

  /// Whether or not to paint a translucent white on top of this surface's
  /// blurred background. [isSurfacePainted] should be true for a typical popup
  /// that contains content without any dividers. A popup that requires dividers
  /// should set [isSurfacePainted] to false and then paint its own surface area.
  ///
  /// Some popups, like iOS's volume control popup, choose to render a blurred
  /// area without any white paint covering it. To achieve this effect,
  /// [isSurfacePainted] should be set to false.
  final bool isSurfacePainted;

  /// The widget below this widget in the tree.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kDialogCornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _kBlurAmount, sigmaY: _kBlurAmount),
        child: Container(
          color: isSurfacePainted ? CupertinoDynamicColor.resolve(_kDialogColor, context) : null,
          child: child,
        ),
      ),
    );
  }
}

// iOS style layout policy widget for sizing an alert dialog's content section and
// action button section.
//
// See [_RenderCupertinoDialog] for specific layout policy details.
class _CupertinoDialogRenderWidget extends RenderObjectWidget {
  const _CupertinoDialogRenderWidget({
    Key? key,
    required this.contentSection,
    required this.actionsSection,
  }) : super(key: key);

  final Widget contentSection;
  final Widget actionsSection;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCupertinoDialog(
      dividerThickness: _kDividerThickness / MediaQuery.of(context).devicePixelRatio,
      isInAccessibilityMode: _isInAccessibilityMode(context),
      dividerColor: CupertinoDynamicColor.resolve(CupertinoColors.separator, context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoDialog renderObject) {
    renderObject
      ..isInAccessibilityMode = _isInAccessibilityMode(context)
      ..dividerColor = CupertinoDynamicColor.resolve(CupertinoColors.separator, context);
  }

  @override
  RenderObjectElement createElement() {
    return _CupertinoDialogRenderElement(this);
  }
}

class _CupertinoDialogRenderElement extends RenderObjectElement {
  _CupertinoDialogRenderElement(_CupertinoDialogRenderWidget widget) : super(widget);

  Element? _contentElement;
  Element? _actionsElement;

  @override
  _CupertinoDialogRenderWidget get widget => super.widget as _CupertinoDialogRenderWidget;

  @override
  _RenderCupertinoDialog get renderObject => super.renderObject as _RenderCupertinoDialog;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_contentElement != null) {
      visitor(_contentElement!);
    }
    if (_actionsElement != null) {
      visitor(_actionsElement!);
    }
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _contentElement = updateChild(_contentElement, widget.contentSection, _AlertDialogSections.contentSection);
    _actionsElement = updateChild(_actionsElement, widget.actionsSection, _AlertDialogSections.actionsSection);
  }

  @override
  void insertRenderObjectChild(RenderObject child, _AlertDialogSections slot) {
    assert(slot != null);
    switch (slot) {
      case _AlertDialogSections.contentSection:
        renderObject.contentSection = child as RenderBox;
        break;
      case _AlertDialogSections.actionsSection:
        renderObject.actionsSection = child as RenderBox;
        break;
    }
  }

  @override
  void moveRenderObjectChild(RenderObject child, _AlertDialogSections oldSlot, _AlertDialogSections newSlot) {
    assert(false);
  }

  @override
  void update(RenderObjectWidget newWidget) {
    super.update(newWidget);
    _contentElement = updateChild(_contentElement, widget.contentSection, _AlertDialogSections.contentSection);
    _actionsElement = updateChild(_actionsElement, widget.actionsSection, _AlertDialogSections.actionsSection);
  }

  @override
  void forgetChild(Element child) {
    assert(child == _contentElement || child == _actionsElement);
    if (_contentElement == child) {
      _contentElement = null;
    } else {
      assert(_actionsElement == child);
      _actionsElement = null;
    }
    super.forgetChild(child);
  }

  @override
  void removeRenderObjectChild(RenderObject child, _AlertDialogSections slot) {
    assert(child == renderObject.contentSection || child == renderObject.actionsSection);
    if (renderObject.contentSection == child) {
      renderObject.contentSection = null;
    } else {
      assert(renderObject.actionsSection == child);
      renderObject.actionsSection = null;
    }
  }
}

// iOS style layout policy for sizing an alert dialog's content section and action
// button section.
//
// The policy is as follows:
//
// If all content and buttons fit on screen:
// The content section and action button section are sized intrinsically and centered
// vertically on screen.
//
// If all content and buttons do not fit on screen, and iOS is NOT in accessibility mode:
// A minimum height for the action button section is calculated. The action
// button section will not be rendered shorter than this minimum.  See
// [_RenderCupertinoDialogActions] for the minimum height calculation.
//
// With the minimum action button section calculated, the content section can
// take up as much space as is available, up to the point that it hits the
// minimum button height at the bottom.
//
// After the content section is laid out, the action button section is allowed
// to take up any remaining space that was not consumed by the content section.
//
// If all content and buttons do not fit on screen, and iOS IS in accessibility mode:
// The button section is given up to 50% of the available height. Then the content
// section is given whatever height remains.
class _RenderCupertinoDialog extends RenderBox {
  _RenderCupertinoDialog({
    RenderBox? contentSection,
    RenderBox? actionsSection,
    double dividerThickness = 0.0,
    bool isInAccessibilityMode = false,
    required Color dividerColor,
  }) : _contentSection = contentSection,
       _actionsSection = actionsSection,
       _dividerThickness = dividerThickness,
       _isInAccessibilityMode = isInAccessibilityMode,
       _dividerPaint = Paint()
        ..color = dividerColor
        ..style = PaintingStyle.fill;


  RenderBox? get contentSection => _contentSection;
  RenderBox? _contentSection;
  set contentSection(RenderBox? newContentSection) {
    if (newContentSection != _contentSection) {
      if (_contentSection != null) {
        dropChild(_contentSection!);
      }
      _contentSection = newContentSection;
      if (_contentSection != null) {
        adoptChild(_contentSection!);
      }
    }
  }

  RenderBox? get actionsSection => _actionsSection;
  RenderBox? _actionsSection;
  set actionsSection(RenderBox? newActionsSection) {
    if (newActionsSection != _actionsSection) {
      if (null != _actionsSection) {
        dropChild(_actionsSection!);
      }
      _actionsSection = newActionsSection;
      if (null != _actionsSection) {
        adoptChild(_actionsSection!);
      }
    }
  }

  bool get isInAccessibilityMode => _isInAccessibilityMode;
  bool _isInAccessibilityMode;
  set isInAccessibilityMode(bool newValue) {
    if (newValue != _isInAccessibilityMode) {
      _isInAccessibilityMode = newValue;
      markNeedsLayout();
    }
  }

  double get _dialogWidth => isInAccessibilityMode
      ? _kAccessibilityCupertinoDialogWidth
      : _kCupertinoDialogWidth;

  final double _dividerThickness;
  final Paint _dividerPaint;

  Color get dividerColor => _dividerPaint.color;
  set dividerColor(Color newValue) {
    if (dividerColor == newValue) {
      return;
    }

    _dividerPaint.color = newValue;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (null != contentSection) {
      contentSection!.attach(owner);
    }
    if (null != actionsSection) {
      actionsSection!.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    if (null != contentSection) {
      contentSection!.detach();
    }
    if (null != actionsSection) {
      actionsSection!.detach();
    }
  }

  @override
  void redepthChildren() {
    if (null != contentSection) {
      redepthChild(contentSection!);
    }
    if (null != actionsSection) {
      redepthChild(actionsSection!);
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BoxParentData) {
      child.parentData = BoxParentData();
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (contentSection != null) {
      visitor(contentSection!);
    }
    if (actionsSection != null) {
      visitor(actionsSection!);
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[
    if (contentSection != null) contentSection!.toDiagnosticsNode(name: 'content'),
    if (actionsSection != null) actionsSection!.toDiagnosticsNode(name: 'actions'),
  ];

  @override
  double computeMinIntrinsicWidth(double height) {
    return _dialogWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _dialogWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double contentHeight = contentSection!.getMinIntrinsicHeight(width);
    final double actionsHeight = actionsSection!.getMinIntrinsicHeight(width);
    final bool hasDivider = contentHeight > 0.0 && actionsHeight > 0.0;
    final double height = contentHeight + (hasDivider ? _dividerThickness : 0.0) + actionsHeight;

    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double contentHeight = contentSection!.getMaxIntrinsicHeight(width);
    final double actionsHeight = actionsSection!.getMaxIntrinsicHeight(width);
    final bool hasDivider = contentHeight > 0.0 && actionsHeight > 0.0;
    final double height = contentHeight + (hasDivider ? _dividerThickness : 0.0) + actionsHeight;

    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _performLayout(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.dryLayoutChild,
    ).size;
  }

  @override
  void performLayout() {
    final _DialogSizes dialogSizes = _performLayout(
      constraints: constraints,
      layoutChild: ChildLayoutHelper.layoutChild,
    );
    size = dialogSizes.size;

    // Set the position of the actions box to sit at the bottom of the dialog.
    // The content box defaults to the top left, which is where we want it.
    assert(actionsSection!.parentData is BoxParentData);
    final BoxParentData actionParentData = actionsSection!.parentData! as BoxParentData;
    actionParentData.offset = Offset(0.0, dialogSizes.actionSectionYOffset);
  }

  _DialogSizes _performLayout({required BoxConstraints constraints, required ChildLayouter layoutChild}) {
    return isInAccessibilityMode
        ? performAccessibilityLayout(
          constraints: constraints,
          layoutChild: layoutChild,
        ) : performRegularLayout(
          constraints: constraints,
          layoutChild: layoutChild,
        );
  }

  // When not in accessibility mode, an alert dialog might reduce the space
  // for buttons to just over 1 button's height to make room for the content
  // section.
  _DialogSizes performRegularLayout({required BoxConstraints constraints, required ChildLayouter layoutChild}) {
    final bool hasDivider = contentSection!.getMaxIntrinsicHeight(_dialogWidth) > 0.0
        && actionsSection!.getMaxIntrinsicHeight(_dialogWidth) > 0.0;
    final double dividerThickness = hasDivider ? _dividerThickness : 0.0;

    final double minActionsHeight = actionsSection!.getMinIntrinsicHeight(_dialogWidth);

    final Size contentSize = layoutChild(
      contentSection!,
      constraints.deflate(EdgeInsets.only(bottom: minActionsHeight + dividerThickness)),
    );

    final Size actionsSize = layoutChild(
      actionsSection!,
      constraints.deflate(EdgeInsets.only(top: contentSize.height + dividerThickness)),
    );

    final double dialogHeight = contentSize.height + dividerThickness + actionsSize.height;

    return _DialogSizes(
      size: constraints.constrain(Size(_dialogWidth, dialogHeight)),
      actionSectionYOffset: contentSize.height + dividerThickness,
    );
  }

  // When in accessibility mode, an alert dialog will allow buttons to take
  // up to 50% of the dialog height, even if the content exceeds available space.
  _DialogSizes performAccessibilityLayout({required BoxConstraints constraints, required ChildLayouter layoutChild}) {
    final bool hasDivider = contentSection!.getMaxIntrinsicHeight(_dialogWidth) > 0.0
        && actionsSection!.getMaxIntrinsicHeight(_dialogWidth) > 0.0;
    final double dividerThickness = hasDivider ? _dividerThickness : 0.0;

    final double maxContentHeight = contentSection!.getMaxIntrinsicHeight(_dialogWidth);
    final double maxActionsHeight = actionsSection!.getMaxIntrinsicHeight(_dialogWidth);

    final Size contentSize;
    final Size actionsSize;
    if (maxContentHeight + dividerThickness + maxActionsHeight > constraints.maxHeight) {
      // There isn't enough room for everything. Following iOS's accessibility dialog
      // layout policy, first we allow the actions to take up to 50% of the dialog
      // height. Second we fill the rest of the available space with the content
      // section.

      actionsSize = layoutChild(
        actionsSection!,
        constraints.deflate(EdgeInsets.only(top: constraints.maxHeight / 2.0)),
      );

      contentSize = layoutChild(
        contentSection!,
        constraints.deflate(EdgeInsets.only(bottom: actionsSize.height + dividerThickness)),
      );
    } else {
      // Everything fits. Give content and actions all the space they want.

      contentSize = layoutChild(
        contentSection!,
        constraints,
      );

      actionsSize = layoutChild(
        actionsSection!,
        constraints.deflate(EdgeInsets.only(top: contentSize.height)),
      );
    }

    // Calculate overall dialog height.
    final double dialogHeight = contentSize.height + dividerThickness + actionsSize.height;

    return _DialogSizes(
      size: constraints.constrain(Size(_dialogWidth, dialogHeight)),
      actionSectionYOffset: contentSize.height + dividerThickness,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final BoxParentData contentParentData = contentSection!.parentData! as BoxParentData;
    contentSection!.paint(context, offset + contentParentData.offset);

    final bool hasDivider = contentSection!.size.height > 0.0 && actionsSection!.size.height > 0.0;
    if (hasDivider) {
      _paintDividerBetweenContentAndActions(context.canvas, offset);
    }

    final BoxParentData actionsParentData = actionsSection!.parentData! as BoxParentData;
    actionsSection!.paint(context, offset + actionsParentData.offset);
  }

  void _paintDividerBetweenContentAndActions(Canvas canvas, Offset offset) {
    canvas.drawRect(
      Rect.fromLTWH(
        offset.dx,
        offset.dy + contentSection!.size.height,
        size.width,
        _dividerThickness,
      ),
      _dividerPaint,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    final BoxParentData contentSectionParentData = contentSection!.parentData! as BoxParentData;
    final BoxParentData actionsSectionParentData = actionsSection!.parentData! as BoxParentData;
    return result.addWithPaintOffset(
             offset: contentSectionParentData.offset,
             position: position,
             hitTest: (BoxHitTestResult result, Offset transformed) {
               assert(transformed == position - contentSectionParentData.offset);
               return contentSection!.hitTest(result, position: transformed);
             },
           )
        || result.addWithPaintOffset(
             offset: actionsSectionParentData.offset,
             position: position,
             hitTest: (BoxHitTestResult result, Offset transformed) {
               assert(transformed == position - actionsSectionParentData.offset);
               return actionsSection!.hitTest(result, position: transformed);
             },
           );
  }
}

class _DialogSizes {
  const _DialogSizes({required this.size, required this.actionSectionYOffset});

  final Size size;
  final double actionSectionYOffset;
}

// Visual components of an alert dialog that need to be explicitly sized and
// laid out at runtime.
enum _AlertDialogSections {
  contentSection,
  actionsSection,
}

// The "content section" of a CupertinoAlertDialog.
//
// If title is missing, then only content is added.  If content is
// missing, then only title is added. If both are missing, then it returns
// a SingleChildScrollView with a zero-sized Container.
class _CupertinoAlertContentSection extends StatelessWidget {
  const _CupertinoAlertContentSection({
    Key? key,
    this.title,
    this.content,
    this.scrollController,
  }) : super(key: key);

  // The (optional) title of the dialog is displayed in a large font at the top
  // of the dialog.
  //
  // Typically a Text widget.
  final Widget? title;

  // The (optional) content of the dialog is displayed in the center of the
  // dialog in a lighter font.
  //
  // Typically a Text widget.
  final Widget? content;

  // A scroll controller that can be used to control the scrolling of the
  // content in the dialog.
  //
  // Defaults to null, and is typically not needed, since most alert contents
  // are short.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (title == null && content == null) {
      return SingleChildScrollView(
        controller: scrollController,
        child: const SizedBox(width: 0.0, height: 0.0),
      );
    }

    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final List<Widget> titleContentGroup = <Widget>[
      if (title != null)
        Padding(
          padding: EdgeInsets.only(
            left: _kEdgePadding,
            right: _kEdgePadding,
            bottom: content == null ? _kEdgePadding : 1.0,
            top: _kEdgePadding * textScaleFactor,
          ),
          child: DefaultTextStyle(
            style: _kCupertinoDialogTitleStyle.copyWith(
              color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
            ),
            textAlign: TextAlign.center,
            child: title!,
          ),
        ),
      if (content != null)
        Padding(
          padding: EdgeInsets.only(
            left: _kEdgePadding,
            right: _kEdgePadding,
            bottom: _kEdgePadding * textScaleFactor,
            top: title == null ? _kEdgePadding : 1.0,
          ),
          child: DefaultTextStyle(
            style: _kCupertinoDialogContentStyle.copyWith(
              color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
            ),
            textAlign: TextAlign.center,
            child: content!,
          ),
        ),
    ];

    return CupertinoScrollbar(
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: titleContentGroup,
        ),
      ),
    );
  }
}

// The "actions section" of a [CupertinoAlertDialog].
//
// See [_RenderCupertinoDialogActions] for details about action button sizing
// and layout.
class _CupertinoAlertActionSection extends StatefulWidget {
  const _CupertinoAlertActionSection({
    Key? key,
    required this.children,
    this.scrollController,
  }) : assert(children != null),
       super(key: key);

  final List<Widget> children;

  // A scroll controller that can be used to control the scrolling of the
  // actions in the dialog.
  //
  // Defaults to null, and is typically not needed, since most alert dialogs
  // don't have many actions.
  final ScrollController? scrollController;

  @override
  _CupertinoAlertActionSectionState createState() => _CupertinoAlertActionSectionState();
}

class _CupertinoAlertActionSectionState extends State<_CupertinoAlertActionSection> {
  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final List<Widget> interactiveButtons = <Widget>[];
    for (int i = 0; i < widget.children.length; i += 1) {
      interactiveButtons.add(
        _PressableActionButton(
          child: widget.children[i],
        ),
      );
    }

    return CupertinoScrollbar(
      child: SingleChildScrollView(
        controller: widget.scrollController,
        child: _CupertinoDialogActionsRenderWidget(
          actionButtons: interactiveButtons,
          dividerThickness: _kDividerThickness / devicePixelRatio,
        ),
      ),
    );
  }
}

// Button that updates its render state when pressed.
//
// The pressed state is forwarded to an _ActionButtonParentDataWidget. The
// corresponding _ActionButtonParentData is then interpreted and rendered
// appropriately by _RenderCupertinoDialogActions.
class _PressableActionButton extends StatefulWidget {
  const _PressableActionButton({
    required this.child,
  });

  final Widget child;

  @override
  _PressableActionButtonState createState() => _PressableActionButtonState();
}

class _PressableActionButtonState extends State<_PressableActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return _ActionButtonParentDataWidget(
      isPressed: _isPressed,
      child: MergeSemantics(
        // TODO(mattcarroll): Button press dynamics need overhaul for iOS:
        // https://github.com/flutter/flutter/issues/19786
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails details) => setState(() {
            _isPressed = true;
          }),
          onTapUp: (TapUpDetails details) => setState(() {
            _isPressed = false;
          }),
          // TODO(mattcarroll): Cancel is currently triggered when user moves
          //  past slop instead of off button: https://github.com/flutter/flutter/issues/19783
          onTapCancel: () => setState(() => _isPressed = false),
          child: widget.child,
        ),
      ),
    );
  }
}

// ParentDataWidget that updates _ActionButtonParentData for an action button.
//
// Each action button requires knowledge of whether or not it is pressed so that
// the dialog can correctly render the button. The pressed state is held within
// _ActionButtonParentData. _ActionButtonParentDataWidget is responsible for
// updating the pressed state of an _ActionButtonParentData based on the
// incoming [isPressed] property.
class _ActionButtonParentDataWidget extends ParentDataWidget<_ActionButtonParentData> {
  const _ActionButtonParentDataWidget({
    Key? key,
    required this.isPressed,
    required Widget child,
  }) : super(key: key, child: child);

  final bool isPressed;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is _ActionButtonParentData);
    final _ActionButtonParentData parentData = renderObject.parentData! as _ActionButtonParentData;
    if (parentData.isPressed != isPressed) {
      parentData.isPressed = isPressed;

      // Force a repaint.
      final AbstractNode? targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsPaint();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => _CupertinoDialogActionsRenderWidget;
}

// ParentData applied to individual action buttons that report whether or not
// that button is currently pressed by the user.
class _ActionButtonParentData extends MultiChildLayoutParentData {
  _ActionButtonParentData({
    this.isPressed = false,
  });

  bool isPressed;
}

/// A button typically used in a [CupertinoAlertDialog].
///
/// See also:
///
///  * [CupertinoAlertDialog], a dialog that informs the user about situations
///    that require acknowledgement.
class CupertinoDialogAction extends StatelessWidget {
  /// Creates an action for an iOS-style dialog.
  const CupertinoDialogAction({
    Key? key,
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.textStyle,
    required this.child,
  }) : assert(child != null),
       assert(isDefaultAction != null),
       assert(isDestructiveAction != null),
       super(key: key);

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback? onPressed;

  /// Set to true if button is the default choice in the dialog.
  ///
  /// Default buttons have bold text. Similar to
  /// [UIAlertController.preferredAction](https://developer.apple.com/documentation/uikit/uialertcontroller/1620102-preferredaction),
  /// but more than one action can have this attribute set to true in the same
  /// [CupertinoAlertDialog].
  ///
  /// This parameters defaults to false and cannot be null.
  final bool isDefaultAction;

  /// Whether this action destroys an object.
  ///
  /// For example, an action that deletes an email is destructive.
  ///
  /// Defaults to false and cannot be null.
  final bool isDestructiveAction;

  /// [TextStyle] to apply to any text that appears in this button.
  ///
  /// Dialog actions have a built-in text resizing policy for long text. To
  /// ensure that this resizing policy always works as expected, [textStyle]
  /// must be used if a text size is desired other than that specified in
  /// [_kCupertinoDialogActionStyle].
  final TextStyle? textStyle;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by
  /// default. To enable a button, set its [onPressed] property to a non-null
  /// value.
  bool get enabled => onPressed != null;

  double _calculatePadding(BuildContext context) {
    return 8.0 * MediaQuery.textScaleFactorOf(context);
  }

  // Dialog action content shrinks to fit, up to a certain point, and if it still
  // cannot fit at the minimum size, the text content is ellipsized.
  //
  // This policy only applies when the device is not in accessibility mode.
  Widget _buildContentWithRegularSizingPolicy({
    required BuildContext context,
    required TextStyle textStyle,
    required Widget content,
  }) {
    final bool isInAccessibilityMode = _isInAccessibilityMode(context);
    final double dialogWidth = isInAccessibilityMode
        ? _kAccessibilityCupertinoDialogWidth
        : _kCupertinoDialogWidth;
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);
    // The fontSizeRatio is the ratio of the current text size (including any
    // iOS scale factor) vs the minimum text size that we allow in action
    // buttons. This ratio information is used to automatically scale down action
    // button text to fit the available space.
    final double fontSizeRatio = (textScaleFactor * textStyle.fontSize!) / _kMinButtonFontSize;
    final double padding = _calculatePadding(context);

    return IntrinsicHeight(
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: fontSizeRatio * (dialogWidth - (2 * padding)),
            ),
            child: Semantics(
              button: true,
              onTap: onPressed,
              child: DefaultTextStyle(
                style: textStyle,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dialog action content is permitted to be as large as it wants when in
  // accessibility mode. If text is used as the content, the text wraps instead
  // of ellipsizing.
  Widget _buildContentWithAccessibilitySizingPolicy({
    required TextStyle textStyle,
    required Widget content,
  }) {
    return DefaultTextStyle(
      style: textStyle,
      textAlign: TextAlign.center,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = _kCupertinoDialogActionStyle.copyWith(
      color: CupertinoDynamicColor.resolve(
        isDestructiveAction ?  CupertinoColors.systemRed : CupertinoColors.systemBlue,
        context,
      ),
    );
    style = style.merge(textStyle);

    if (isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if (!enabled) {
      style = style.copyWith(color: style.color!.withOpacity(0.5));
    }

    // Apply a sizing policy to the action button's content based on whether or
    // not the device is in accessibility mode.
    // TODO(mattcarroll): The following logic is not entirely correct. It is also
    // the case that if content text does not contain a space, it should also
    // wrap instead of ellipsizing. We are consciously not implementing that
    // now due to complexity.
    final Widget sizedContent = _isInAccessibilityMode(context)
      ? _buildContentWithAccessibilitySizingPolicy(
          textStyle: style,
          content: child,
        )
      : _buildContentWithRegularSizingPolicy(
          context: context,
          textStyle: style,
          content: child,
        );

    return GestureDetector(
      excludeFromSemantics: true,
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _kMinButtonHeight,
        ),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.all(_calculatePadding(context)),
          child: sizedContent,
        ),
      ),
    );
  }
}

// iOS style dialog action button layout.
//
// [_CupertinoDialogActionsRenderWidget] does not provide any scrolling
// behavior for its buttons. It only handles the sizing and layout of buttons.
// Scrolling behavior can be composed on top of this widget, if desired.
//
// See [_RenderCupertinoDialogActions] for specific layout policy details.
class _CupertinoDialogActionsRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogActionsRenderWidget({
    Key? key,
    required List<Widget> actionButtons,
    double dividerThickness = 0.0,
  }) : _dividerThickness = dividerThickness,
       super(key: key, children: actionButtons);

  final double _dividerThickness;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCupertinoDialogActions(
      dialogWidth: _isInAccessibilityMode(context)
        ? _kAccessibilityCupertinoDialogWidth
        : _kCupertinoDialogWidth,
      dividerThickness: _dividerThickness,
      dialogColor: CupertinoDynamicColor.resolve(_kDialogColor, context),
      dialogPressedColor: CupertinoDynamicColor.resolve(_kDialogPressedColor, context),
      dividerColor: CupertinoDynamicColor.resolve(CupertinoColors.separator, context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoDialogActions renderObject) {
    renderObject
      ..dialogWidth = _isInAccessibilityMode(context)
        ? _kAccessibilityCupertinoDialogWidth
        : _kCupertinoDialogWidth
      ..dividerThickness = _dividerThickness
      ..dialogColor = CupertinoDynamicColor.resolve(_kDialogColor, context)
      ..dialogPressedColor = CupertinoDynamicColor.resolve(_kDialogPressedColor, context)
      ..dividerColor = CupertinoDynamicColor.resolve(CupertinoColors.separator, context);
  }
}

// iOS style layout policy for sizing and positioning an alert dialog's action
// buttons.
//
// The policy is as follows:
//
// If a single action button is provided, or if 2 action buttons are provided
// that can fit side-by-side, then action buttons are sized and laid out in a
// single horizontal row. The row is exactly as wide as the dialog, and the row
// is as tall as the tallest action button. A horizontal divider is drawn above
// the button row. If 2 action buttons are provided, a vertical divider is
// drawn between them. The thickness of the divider is set by [dividerThickness].
//
// If 2 action buttons are provided but they cannot fit side-by-side, then the
// 2 buttons are stacked vertically. A horizontal divider is drawn above each
// button. The thickness of the divider is set by [dividerThickness]. The minimum
// height of this [RenderBox] in the case of 2 stacked buttons is as tall as
// the 2 buttons stacked. This is different than the 3+ button case where the
// minimum height is only 1.5 buttons tall. See the 3+ button explanation for
// more info.
//
// If 3+ action buttons are provided then they are all stacked vertically. A
// horizontal divider is drawn above each button. The thickness of the divider
// is set by [dividerThickness]. The minimum height of this [RenderBox] in the case
// of 3+ stacked buttons is as tall as the 1st button + 50% the height of the
// 2nd button. In other words, the minimum height is 1.5 buttons tall. This
// minimum height of 1.5 buttons is expected to work in tandem with a surrounding
// [ScrollView] to match the iOS dialog behavior.
//
// Each button is expected to have an _ActionButtonParentData which reports
// whether or not that button is currently pressed. If a button is pressed,
// then the dividers above and below that pressed button are not drawn - instead
// they are filled with the standard white dialog background color. The one
// exception is the very 1st divider which is always rendered. This policy comes
// from observation of native iOS dialogs.
class _RenderCupertinoDialogActions extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderCupertinoDialogActions({
    List<RenderBox>? children,
    required double dialogWidth,
    double dividerThickness = 0.0,
    required Color dialogColor,
    required Color dialogPressedColor,
    required Color dividerColor,
  }) : _dialogWidth = dialogWidth,
       _buttonBackgroundPaint = Paint()
        ..color = dialogColor
        ..style = PaintingStyle.fill,
        _pressedButtonBackgroundPaint = Paint()
          ..color = dialogPressedColor
          ..style = PaintingStyle.fill,
        _dividerPaint = Paint()
          ..color = dividerColor
          ..style = PaintingStyle.fill,
       _dividerThickness = dividerThickness {
    addAll(children);
  }

  double get dialogWidth => _dialogWidth;
  double _dialogWidth;
  set dialogWidth(double newWidth) {
    if (newWidth != _dialogWidth) {
      _dialogWidth = newWidth;
      markNeedsLayout();
    }
  }

  // The thickness of the divider between buttons.
  double get dividerThickness => _dividerThickness;
  double _dividerThickness;
  set dividerThickness(double newValue) {
    if (newValue != _dividerThickness) {
      _dividerThickness = newValue;
      markNeedsLayout();
    }
  }

  final Paint _buttonBackgroundPaint;
  set dialogColor(Color value) {
    if (value == _buttonBackgroundPaint.color)
      return;

    _buttonBackgroundPaint.color = value;
    markNeedsPaint();
  }

  final Paint _pressedButtonBackgroundPaint;
  set dialogPressedColor(Color value) {
    if (value == _pressedButtonBackgroundPaint.color)
      return;

    _pressedButtonBackgroundPaint.color = value;
    markNeedsPaint();
  }

  final Paint _dividerPaint;
  set dividerColor(Color value) {
    if (value == _dividerPaint.color)
      return;

    _dividerPaint.color = value;
    markNeedsPaint();
  }

  Iterable<RenderBox> get _pressedButtons sync* {
    RenderBox? currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData! as _ActionButtonParentData;
      if (parentData.isPressed) {
        yield currentChild;
      }
      currentChild = childAfter(currentChild);
    }
  }

  bool get _isButtonPressed {
    RenderBox? currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData! as _ActionButtonParentData;
      if (parentData.isPressed) {
        return true;
      }
      currentChild = childAfter(currentChild);
    }
    return false;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionButtonParentData)
      child.parentData = _ActionButtonParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return dialogWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return dialogWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double minHeight;
    if (childCount == 0) {
      minHeight = 0.0;
    } else if (childCount == 1) {
      // If only 1 button, display the button across the entire dialog.
      minHeight = _computeMinIntrinsicHeightSideBySide(width);
    } else {
      if (childCount == 2 && _isSingleButtonRow(width)) {
        // The first 2 buttons fit side-by-side. Display them horizontally.
        minHeight = _computeMinIntrinsicHeightSideBySide(width);
      } else {
        // 3+ buttons are always stacked. The minimum height when stacked is
        // 1.5 buttons tall.
        minHeight = _computeMinIntrinsicHeightStacked(width);
      }
    }
    return minHeight;
  }

  // The minimum height for a single row of buttons is the larger of the buttons'
  // min intrinsic heights.
  double _computeMinIntrinsicHeightSideBySide(double width) {
    assert(childCount >= 1 && childCount <= 2);

    final double minHeight;
    if (childCount == 1) {
      minHeight = firstChild!.getMinIntrinsicHeight(width);
    } else {
      final double perButtonWidth = (width - dividerThickness) / 2.0;
      minHeight = math.max(
        firstChild!.getMinIntrinsicHeight(perButtonWidth),
        lastChild!.getMinIntrinsicHeight(perButtonWidth),
      );
    }
    return minHeight;
  }

  // The minimum height for 2+ stacked buttons is the height of the 1st button
  // + 50% the height of the 2nd button + the divider between the two.
  double _computeMinIntrinsicHeightStacked(double width) {
    assert(childCount >= 2);

    return firstChild!.getMinIntrinsicHeight(width)
      + dividerThickness
      + (0.5 * childAfter(firstChild!)!.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double maxHeight;
    if (childCount == 0) {
      // No buttons. Zero height.
      maxHeight = 0.0;
    } else if (childCount == 1) {
      // One button. Our max intrinsic height is equal to the button's.
      maxHeight = firstChild!.getMaxIntrinsicHeight(width);
    } else if (childCount == 2) {
      // Two buttons...
      if (_isSingleButtonRow(width)) {
        // The 2 buttons fit side by side so our max intrinsic height is equal
        // to the taller of the 2 buttons.
        final double perButtonWidth = (width - dividerThickness) / 2.0;
        maxHeight = math.max(
          firstChild!.getMaxIntrinsicHeight(perButtonWidth),
          lastChild!.getMaxIntrinsicHeight(perButtonWidth),
        );
      } else {
        // The 2 buttons do not fit side by side. Measure total height as a
        // vertical stack.
        maxHeight = _computeMaxIntrinsicHeightStacked(width);
      }
    } else {
      // Three+ buttons. Stack the buttons vertically with dividers and measure
      // the overall height.
      maxHeight = _computeMaxIntrinsicHeightStacked(width);
    }
    return maxHeight;
  }

  // Max height of a stack of buttons is the sum of all button heights + a
  // divider for each button.
  double _computeMaxIntrinsicHeightStacked(double width) {
    assert(childCount >= 2);

    final double allDividersHeight = (childCount - 1) * dividerThickness;
    double heightAccumulation = allDividersHeight;
    RenderBox? button = firstChild;
    while (button != null) {
      heightAccumulation += button.getMaxIntrinsicHeight(width);
      button = childAfter(button);
    }
    return heightAccumulation;
  }

  bool _isSingleButtonRow(double width) {
    final bool isSingleButtonRow;
    if (childCount == 1) {
      isSingleButtonRow = true;
    } else if (childCount == 2) {
      // There are 2 buttons. If they can fit side-by-side then that's what
      // we want to do. Otherwise, stack them vertically.
      final double sideBySideWidth = firstChild!.getMaxIntrinsicWidth(double.infinity)
          + dividerThickness
          + lastChild!.getMaxIntrinsicWidth(double.infinity);
      isSingleButtonRow = sideBySideWidth <= width;
    } else {
      isSingleButtonRow = false;
    }
    return isSingleButtonRow;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeLayout(constraints: constraints, dry: true);
  }

  @override
  void performLayout() {
    size = _computeLayout(constraints: constraints, dry: false);
  }

  Size _computeLayout({required BoxConstraints constraints, bool dry = false}) {
    final ChildLayouter layoutChild = dry
        ? ChildLayoutHelper.dryLayoutChild
        : ChildLayoutHelper.layoutChild;

    if (_isSingleButtonRow(dialogWidth)) {
      if (childCount == 1) {
        // We have 1 button. Our size is the width of the dialog and the height
        // of the single button.
        final Size childSize = layoutChild(
          firstChild!,
          constraints,
        );

        return constraints.constrain(
          Size(dialogWidth, childSize.height),
        );
      } else {
        // Each button gets half the available width, minus a single divider.
        final BoxConstraints perButtonConstraints = BoxConstraints(
          minWidth: (constraints.minWidth - dividerThickness) / 2.0,
          maxWidth: (constraints.maxWidth - dividerThickness) / 2.0,
          minHeight: 0.0,
          maxHeight: double.infinity,
        );

        // Layout the 2 buttons.
        final Size firstChildSize = layoutChild(
          firstChild!,
          perButtonConstraints,
        );
        final Size lastChildSize = layoutChild(
          lastChild!,
          perButtonConstraints,
        );

        if (!dry) {
          // The 2nd button needs to be offset to the right.
          assert(lastChild!.parentData is MultiChildLayoutParentData);
          final MultiChildLayoutParentData secondButtonParentData = lastChild!.parentData! as MultiChildLayoutParentData;
          secondButtonParentData.offset = Offset(firstChildSize.width + dividerThickness, 0.0);
        }

        // Calculate our size based on the button sizes.
        return constraints.constrain(
          Size(
            dialogWidth,
            math.max(
              firstChildSize.height,
              lastChildSize.height,
            ),
          ),
        );
      }
    } else {
      // We need to stack buttons vertically, plus dividers above each button (except the 1st).
      final BoxConstraints perButtonConstraints = constraints.copyWith(
        minHeight: 0.0,
        maxHeight: double.infinity,
      );

      RenderBox? child = firstChild;
      int index = 0;
      double verticalOffset = 0.0;
      while (child != null) {
        final Size childSize = layoutChild(
          child,
          perButtonConstraints,
        );

        if (!dry) {
          assert(child.parentData is MultiChildLayoutParentData);
          final MultiChildLayoutParentData parentData = child.parentData! as MultiChildLayoutParentData;
          parentData.offset = Offset(0.0, verticalOffset);
        }
        verticalOffset += childSize.height;
        if (index < childCount - 1) {
          // Add a gap for the next divider.
          verticalOffset += dividerThickness;
        }

        index += 1;
        child = childAfter(child);
      }

      // Our height is the accumulated height of all buttons and dividers.
      return constraints.constrain(
        Size(dialogWidth, verticalOffset),
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;

    if (_isSingleButtonRow(size.width)) {
      _drawButtonBackgroundsAndDividersSingleRow(canvas, offset);
    } else {
      _drawButtonBackgroundsAndDividersStacked(canvas, offset);
    }

    _drawButtons(context, offset);
  }

  void _drawButtonBackgroundsAndDividersSingleRow(Canvas canvas, Offset offset) {
    // The vertical divider sits between the left button and right button (if
    // the dialog has 2 buttons).  The vertical divider is hidden if either the
    // left or right button is pressed.
    final Rect verticalDivider = childCount == 2 && !_isButtonPressed
      ? Rect.fromLTWH(
          offset.dx + firstChild!.size.width,
          offset.dy,
          dividerThickness,
          math.max(
            firstChild!.size.height,
            lastChild!.size.height,
          ),
        )
      : Rect.zero;

    final List<Rect> pressedButtonRects = _pressedButtons.map<Rect>((RenderBox pressedButton) {
      final MultiChildLayoutParentData buttonParentData = pressedButton.parentData! as MultiChildLayoutParentData;

      return Rect.fromLTWH(
        offset.dx + buttonParentData.offset.dx,
        offset.dy + buttonParentData.offset.dy,
        pressedButton.size.width,
        pressedButton.size.height,
      );
    }).toList();

    // Create the button backgrounds path and paint it.
    final Path backgroundFillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..addRect(verticalDivider);

    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      backgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      backgroundFillPath,
      _buttonBackgroundPaint,
    );

    // Create the pressed buttons background path and paint it.
    final Path pressedBackgroundFillPath = Path();
    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      pressedBackgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      pressedBackgroundFillPath,
      _pressedButtonBackgroundPaint,
    );

    // Create the dividers path and paint it.
    final Path dividersPath = Path()
      ..addRect(verticalDivider);

    canvas.drawPath(
      dividersPath,
      _dividerPaint,
    );
  }

  void _drawButtonBackgroundsAndDividersStacked(Canvas canvas, Offset offset) {
    final Offset dividerOffset = Offset(0.0, dividerThickness);

    final Path backgroundFillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));

    final Path pressedBackgroundFillPath = Path();

    final Path dividersPath = Path();

    Offset accumulatingOffset = offset;

    RenderBox? child = firstChild;
    RenderBox? prevChild;
    while (child != null) {
      assert(child.parentData is _ActionButtonParentData);
      final _ActionButtonParentData currentButtonParentData = child.parentData! as _ActionButtonParentData;
      final bool isButtonPressed = currentButtonParentData.isPressed;

      bool isPrevButtonPressed = false;
      if (prevChild != null) {
        assert(prevChild.parentData is _ActionButtonParentData);
        final _ActionButtonParentData previousButtonParentData = prevChild.parentData! as _ActionButtonParentData;
        isPrevButtonPressed = previousButtonParentData.isPressed;
      }

      final bool isDividerPresent = child != firstChild;
      final bool isDividerPainted = isDividerPresent && !(isButtonPressed || isPrevButtonPressed);
      final Rect dividerRect = Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy,
        size.width,
        dividerThickness,
      );

      final Rect buttonBackgroundRect = Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy + (isDividerPresent ? dividerThickness : 0.0),
        size.width,
        child.size.height,
      );

      // If this button is pressed, then we don't want a white background to be
      // painted, so we erase this button from the background path.
      if (isButtonPressed) {
        backgroundFillPath.addRect(buttonBackgroundRect);
        pressedBackgroundFillPath.addRect(buttonBackgroundRect);
      }

      // If this divider is needed, then we erase the divider area from the
      // background path, and on top of that we paint a translucent gray to
      // darken the divider area.
      if (isDividerPainted) {
        backgroundFillPath.addRect(dividerRect);
        dividersPath.addRect(dividerRect);
      }

      accumulatingOffset += (isDividerPresent ? dividerOffset : Offset.zero)
          + Offset(0.0, child.size.height);

      prevChild = child;
      child = childAfter(child);
    }

    canvas.drawPath(backgroundFillPath, _buttonBackgroundPaint);
    canvas.drawPath(pressedBackgroundFillPath, _pressedButtonBackgroundPaint);
    canvas.drawPath(dividersPath, _dividerPaint);
  }

  void _drawButtons(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    while (child != null) {
      final MultiChildLayoutParentData childParentData = child.parentData! as MultiChildLayoutParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, { required Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }
}
