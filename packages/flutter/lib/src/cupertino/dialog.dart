// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'scrollbar.dart';

// TODO(abarth): These constants probably belong somewhere more general.

const TextStyle _kCupertinoDialogTitleStyle = const TextStyle(
  fontFamily: '.SF UI Display',
  inherit: false,
  fontSize: 18.0,
  fontWeight: FontWeight.w500,
  color: CupertinoColors.black,
  height: 1.06,
  letterSpacing: 0.48,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogContentStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.4,
  fontWeight: FontWeight.w300,
  color: CupertinoColors.black,
  height: 1.036,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogActionStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 16.8,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.activeBlue,
  textBaseline: TextBaseline.alphabetic,
);

const double _kCupertinoDialogWidth = 270.0;

// _kCupertinoDialogBlurOverlayDecoration is applied to the blurred backdrop to
// lighten the blurred image. Brightening is done to counteract the dark modal
// barrier that appears behind the dialog. The overlay blend mode does the
// brightening. The white color doesn't paint any white, it's just the basis
// for the overlay blend mode.
const BoxDecoration _kCupertinoDialogBlurOverlayDecoration = const BoxDecoration(
  color: CupertinoColors.white,
  backgroundBlendMode: BlendMode.overlay,
);

const double _kEdgePadding = 20.0;
const double _kButtonHeight = 45.0;
const double _kDialogCornerRadius = 12.0;

// _kDialogColor is a translucent white that is painted on top of the blurred
// backdrop.
const Color _kDialogColor = const Color(0xC0FFFFFF);
const Color _kButtonDividerColor = const Color(0x20000000);

/// An iOS-style dialog.
///
/// This dialog widget does not have any opinion about the contents of the
/// dialog. Rather than using this widget directly, consider using
/// [CupertinoAlertDialog], which implement a specific kind of dialog.
///
/// Push with `Navigator.of(..., rootNavigator: true)` when using with
/// [CupertinoTabScaffold] to ensure that the dialog appears above the tabs.
///
/// See also:
///
///  * [CupertinoAlertDialog], which is a dialog with title, contents, and
///    actions.
///  * <https://developer.apple.com/ios/human-interface-guidelines/views/alerts/>
class CupertinoDialog extends StatelessWidget {
  /// Creates an iOS-style dialog.
  const CupertinoDialog({
    Key key,
    this.child,
  }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new ClipRRect(
        borderRadius: BorderRadius.circular(_kDialogCornerRadius),
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: new Container(
            width: _kCupertinoDialogWidth,
            decoration: _kCupertinoDialogBlurOverlayDecoration,
            child: child,
          ),
        ),
      ),
    );
  }
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
///  * [CupertinoDialog], which is a generic iOS-style dialog.
///  * [CupertinoDialogAction], which is an iOS-style dialog button.
///  * <https://developer.apple.com/ios/human-interface-guidelines/views/alerts/>
class CupertinoAlertDialog extends StatelessWidget {
  /// Creates an iOS-style alert dialog.
  ///
  /// The [actions] must not be null.
  const CupertinoAlertDialog({
    Key key,
    this.title,
    this.content,
    this.actions = const <Widget>[],
    this.scrollController,
    this.actionScrollController,
  })  : assert(actions != null),
        super(key: key);

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  ///
  /// Typically a [Text] widget.
  final Widget content;

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
  final ScrollController scrollController;

  /// A scroll controller that can be used to control the scrolling of the
  /// actions in the dialog.
  ///
  /// Defaults to null, and is typically not needed.
  ///
  /// See also:
  ///
  ///  * [scrollController], which can be used for controlling the [content]
  ///    section when it is long.
  final ScrollController actionScrollController;

  Widget _buildContent() {
    final List<Widget> children = <Widget>[];

    if (title != null || content != null) {
      final Widget titleSection = new _CupertinoAlertTitleSection(
        title: title,
        content: content,
        scrollController: scrollController,
      );
      children.add(new Flexible(flex: 3, child: titleSection));
      // Add padding between the sections.
      children.add(const Padding(padding: const EdgeInsets.only(top: 8.0)));
    }

    return new Container(
      color: _kDialogColor,
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildActions() {
    Widget actionSection = new Container();
    if (actions.isNotEmpty) {
      actionSection = new _CupertinoAlertActionSection(
        children: actions,
        scrollController: actionScrollController,
      );
    }

    return actionSection;
  }

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new Container(
        margin: const EdgeInsets.symmetric(vertical: _kEdgePadding),
        width: _kCupertinoDialogWidth,
        // The following clip is critical. The BackdropFilter needs to have
        // rounded corners, but SKIA cannot internally create a rounded rect
        // shape. Therefore, we have no choice but to clip, ourselves.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kDialogCornerRadius),
          child: new BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: new Container(
              decoration: _kCupertinoDialogBlurOverlayDecoration,
              child: new _CupertinoDialogRenderWidget(
                isStacked: actions.length > 2,
                children: <Widget>[
                  new BaseLayoutId<_CupertinoDialogRenderWidget, MultiChildLayoutParentData>(
                    id: _AlertDialogSections.contentSection,
                    child: _buildContent(),
                  ),
                  new BaseLayoutId<_CupertinoDialogRenderWidget, MultiChildLayoutParentData>(
                    id: _AlertDialogSections.actionsSection,
                    child: _buildActions(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// iOS style layout policy widget for sizing an alert dialog's content section and
// action button section.
//
// The sizing policy is partially determined by whether or not action buttons
// are stacked vertically, or positioned horizontally. [isStacked] is used to
// indicate whether or not the buttons should be stacked vertically.
//
// See [_RenderCupertinoDialog] for specific layout policy details.
class _CupertinoDialogRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogRenderWidget({
    Key key,
    @required List<Widget> children,
    bool isStacked = false,
  }) : _isStacked = isStacked,
       super(key: key, children: children);

  final bool _isStacked;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderCupertinoDialog(isStacked: _isStacked);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoDialog renderObject) {
    renderObject.isStacked = _isStacked;
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
// If all content and buttons do not fit on screen:
// A minimum height for the action button section is calculated. The action
// button section will not be rendered shorter than this minimum.  See
// [_RenderCupertinoDialogActions] for the minimum height calculation.
//
// With the minimum action button section calculated, the content section is
// laid out as tall as it wants to be, up to the point that it hits the
// minimum button height at the bottom.
//
// After the content section is laid out, the action button section is allowed
// to take up any remaining space that was not consumed by the content section.
class _RenderCupertinoDialog extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
    RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderCupertinoDialog({
    RenderBox contentSection,
    RenderBox actionsSection,
    bool isStacked = false,
  }) : _isStacked = isStacked {
    if (null != contentSection) {
      add(contentSection);
    }
    if (null != actionsSection) {
      add(actionsSection);
    }
  }

  bool _isStacked;

  bool get isStacked => _isStacked;

  set isStacked(bool newValue) {
    if (newValue == _isStacked) {
      return;
    }

    _isStacked = newValue;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData)
      child.parentData = new MultiChildLayoutParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _kCupertinoDialogWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _kCupertinoDialogWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _computeIntrinsicHeight(width);
  }

  double _computeIntrinsicHeight(double width) {
    // Obtain references to the specific children we need lay out.
    final _DialogChildren dialogChildren = _findDialogChildren();
    final RenderBox content = dialogChildren.content;
    final RenderBox actions = dialogChildren.actions;

    final double contentHeight = content.getMaxIntrinsicHeight(width);
    final double actionsHeight = actions.getMaxIntrinsicHeight(width);
    final double height = contentHeight + actionsHeight;

    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  void performLayout() {
    // Obtain references to the specific children we need lay out.
    final _DialogChildren dialogChildren = _findDialogChildren();
    final RenderBox content = dialogChildren.content;
    final RenderBox actions = dialogChildren.actions;

    final double minActionsHeight = actions.getMinIntrinsicHeight(constraints.maxWidth);

    final Size maxDialogSize = constraints.biggest;

    // Size alert dialog content.
    content.layout(
      constraints.deflate(new EdgeInsets.only(bottom: minActionsHeight)),
      parentUsesSize: true,
    );
    final Size contentSize = content.size;

    // Size alert dialog actions.
    actions.layout(
      constraints.deflate(new EdgeInsets.only(top: contentSize.height)),
      parentUsesSize: true,
    );
    final Size actionsSize = actions.size;

    // Calculate overall dialog height.
    final double dialogHeight = contentSize.height + actionsSize.height;

    // Set our size now that layout calculations are complete.
    size = new Size(maxDialogSize.width, dialogHeight);

    // Set the position of the actions box to sit at the bottom of the dialog.
    // The content box defaults to the top left, which is where we want it.
    assert(actions.parentData is MultiChildLayoutParentData);
    final MultiChildLayoutParentData actionParentData = actions.parentData;
    actionParentData.offset = new Offset(0.0, contentSize.height);
  }

  _DialogChildren _findDialogChildren() {
    RenderBox content;
    RenderBox actions;
    final List<RenderBox> children = getChildrenAsList();
    for (RenderBox child in children) {
      final MultiChildLayoutParentData parentData = child.parentData;
      if (parentData.id == _AlertDialogSections.contentSection) {
        content = child;
      } else if (parentData.id == _AlertDialogSections.actionsSection) {
        actions = child;
      }
    }
    assert(content != null);
    assert(actions != null);

    return new _DialogChildren(
      content: content,
      actions: actions,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }
}

// Visual components of an alert dialog that need to be explicitly sized and
// laid out at runtime.
enum _AlertDialogSections {
  contentSection,
  actionsSection,
}

// Data structure used to pass around references to multiple dialog pieces for
// layout calculations.
class _DialogChildren {
  final RenderBox content;
  final RenderBox actions;

  _DialogChildren({
    this.content,
    this.actions,
  });
}

// The "content section" of a CupertinoAlertDialog.
//
// If title is missing, then only content is added.  If content is
// missing, then only title is added. If both are missing, then it returns
// a SingleChildScrollView with a zero-sized Container.
class _CupertinoAlertTitleSection extends StatelessWidget {
  const _CupertinoAlertTitleSection({
    Key key,
    this.title,
    this.content,
    this.scrollController,
  }) : super(key: key);

  // The (optional) title of the dialog is displayed in a large font at the top
  // of the dialog.
  //
  // Typically a Text widget.
  final Widget title;

  // The (optional) content of the dialog is displayed in the center of the
  // dialog in a lighter font.
  //
  // Typically a Text widget.
  final Widget content;

  // A scroll controller that can be used to control the scrolling of the
  // content in the dialog.
  //
  // Defaults to null, and is typically not needed, since most alert contents
  // are short.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final List<Widget> titleContentGroup = <Widget>[];
    if (title != null) {
      titleContentGroup.add(new Padding(
        padding: new EdgeInsets.only(
          left: _kEdgePadding,
          right: _kEdgePadding,
          bottom: content == null ? _kEdgePadding : 1.0,
          top: _kEdgePadding,
        ),
        child: new DefaultTextStyle(
          style: _kCupertinoDialogTitleStyle,
          textAlign: TextAlign.center,
          child: title,
        ),
      ));
    }

    if (content != null) {
      titleContentGroup.add(
        new Padding(
          padding: new EdgeInsets.only(
            left: _kEdgePadding,
            right: _kEdgePadding,
            bottom: _kEdgePadding,
            top: title == null ? _kEdgePadding : 1.0,
          ),
          child: new DefaultTextStyle(
            style: _kCupertinoDialogContentStyle,
            textAlign: TextAlign.center,
            child: content,
          ),
        ),
      );
    }

    if (titleContentGroup.isEmpty) {
      return new SingleChildScrollView(
        controller: scrollController,
        child: new Container(width: 0.0, height: 0.0),
      );
    }

    // Add padding between the widgets if necessary.
    if (titleContentGroup.length > 1) {
      titleContentGroup.insert(1, const Padding(padding: const EdgeInsets.only(top: 8.0)));
    }

    return new CupertinoScrollbar(
      child: new SingleChildScrollView(
        controller: scrollController,
        child: new Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: titleContentGroup,
        ),
      ),
    );
  }
}

/// A button typically used in a [CupertinoAlertDialog].
///
/// See also:
///
///  * [CupertinoAlertDialog], a dialog that informs the user about situations
///    that require acknowledgement
class CupertinoDialogAction extends StatelessWidget {
  /// Creates an action for an iOS-style dialog.
  const CupertinoDialogAction({
    this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    @required this.child,
  }) : assert(child != null);

  /// The callback that is called when the button is tapped or otherwise
  /// activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// Set to true if button is the default choice in the dialog.
  ///
  /// Default buttons are bold.
  final bool isDefaultAction;

  /// Whether this action destroys an object.
  ///
  /// For example, an action that deletes an email is destructive.
  final bool isDestructiveAction;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  /// Whether the button is enabled or disabled. Buttons are disabled by
  /// default. To enable a button, set its [onPressed] property to a non-null
  /// value.
  bool get enabled => onPressed != null;

  @override
  Widget build(BuildContext context) {
    TextStyle style = _kCupertinoDialogActionStyle;

    if (isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if (isDestructiveAction) {
      style = style.copyWith(color: CupertinoColors.destructiveRed);
    }

    if (!enabled) {
      style = style.copyWith(color: style.color.withOpacity(0.5));
    }

    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);
    return new GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: new ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _kButtonHeight,
        ),
        child: new Container(
          alignment: Alignment.center,
          padding: new EdgeInsets.all(8.0 * textScaleFactor),
          child: new DefaultTextStyle(
            style: style,
            child: child,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// The "actions section" of a [CupertinoAlertDialog].
//
// If _layoutActionsVertically is true, they are laid out vertically
// in a column; else they are laid out horizontally in a row. If there isn't
// enough room to show all the children vertically, they are wrapped in a
// CupertinoScrollbar widget. If children is null or empty, it returns null.
class _CupertinoAlertActionSection extends StatelessWidget {
  const _CupertinoAlertActionSection({
    Key key,
    @required this.children,
    this.scrollController,
  })  : assert(children != null),
        super(key: key);

  final List<Widget> children;

  // A scroll controller that can be used to control the scrolling of the
  // actions in the dialog.
  //
  // Defaults to null, and is typically not needed, since most alert dialogs
  // don't have many actions.
  final ScrollController scrollController;

  bool get _layoutActionsVertically => children.length > 2;

  Widget _buildHorizontalDivider(double devicePixelRatio) {
    return new Container(
      height: 1.0 / devicePixelRatio,
      color: _kButtonDividerColor,
    );
  }

  Widget _buildVerticalDivider(double devicePixelRatio) {
    return new Container(
      width: 1.0 / devicePixelRatio,
      color: _kButtonDividerColor,
    );
  }

  Widget _buildHorizontalButtons(double devicePixelRatio) {
    assert(
      children.length <= 2,
      'Horizontal dialog buttons can only be constructed with 2 or fewer '
      'buttons. Actual button count: ${children.length}',
    );

    if (children.length == 1) {
      return Column(
        children: <Widget>[
          _buildHorizontalDivider(devicePixelRatio),
          Row(
            children: <Widget>[
              new Expanded(
                child: _buildDialogButton(children.single),
              ),
            ],
          ),
        ],
      );
    } else {
      // TODO(abarth): Hide the divider when one of the adjacent buttons is highlighted
      return Column(
        children: <Widget>[
          _buildHorizontalDivider(devicePixelRatio),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                new Expanded(
                  child: _buildDialogButton(children[0]),
                ),
                _buildVerticalDivider(devicePixelRatio),
                new Expanded(
                  child: _buildDialogButton(children[1]),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Iterable<Widget> _buildVerticalButtons(double devicePixelRatio) sync* {
    for (Widget child in children) {
      yield _buildHorizontalDivider(devicePixelRatio);
      yield _buildDialogButton(child);
    }
  }

  Widget _buildDialogButton(Widget buttonContent) {
    return Container(
      color: _kDialogColor,
      child: buttonContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (children.isEmpty) {
      return new SingleChildScrollView(
        controller: scrollController,
        child: new Container(width: 0.0, height: 0.0),
      );
    }

    // TODO(abarth): Listen for the buttons being highlighted.

    if (_layoutActionsVertically) {
      final List<Widget> buttons = _buildVerticalButtons(devicePixelRatio).toList();

      final Widget actionsSection = new CupertinoScrollbar(
        child: new SingleChildScrollView(
          controller: scrollController,
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buttons,
          ),
        ),
      );

      return new _CupertinoDialogActionsRenderWidget(
        isStacked: true,
        children: <Widget>[
          new BaseLayoutId<_CupertinoDialogActionsRenderWidget, MultiChildLayoutParentData>(
            id: _AlertDialogSections.actionsSection,
            child: actionsSection,
          ),
        ]..addAll(buttons),
      );
    } else {
      // For a horizontal layout, we don't need the scrollController in most
      // cases, but it still has to be always attached to a scroll view.
      final Widget actionsSections = new CupertinoScrollbar(
        child: new SingleChildScrollView(
          controller: scrollController,
          child: ConstrainedBox(
            constraints: new BoxConstraints.loose(
              const Size(
                _kCupertinoDialogWidth,
                double.infinity,
              ),
            ),
            child: _buildHorizontalButtons(devicePixelRatio),
          ),
        ),
      );

      return new _CupertinoDialogActionsRenderWidget(
        isStacked: false,
        children: <Widget>[
          new BaseLayoutId<_CupertinoDialogActionsRenderWidget, MultiChildLayoutParentData>(
            id: _AlertDialogSections.actionsSection,
            child: actionsSections,
          ),
          actionsSections,
        ],
      );
    }
  }
}

// iOS style layout policy widget for sizing action buttons.
//
// The sizing policy is partially determined by whether or not action buttons
// are stacked vertically, or positioned horizontally. [isStacked] is used to
// indicate whether or not the buttons should be stacked vertically.
//
// See [_RenderCupertinoDialogActions] for specific layout policy details.
//
// Usage instructions:
//
// When stacked vertically:
// The entire actions section (all buttons and dividers) should be a single
// grandchild of this widget, and it should be wrapped with a
// [BaseLayoutId<_CupertinoDialogActionsRenderWidget, MultiChildLayoutParentData>]
// whose ID is [_AlertDialogPieces.actionsSection].
//
// Also, the entire list of buttons and dividers should also be passed as
// direct children of this widget in the order they appear: divider, button,
// divider, button. The order is critical and the layout will break if that
// exact order is not respected.
//
// Vertical example:
//
// ```
// new _CupertinoDialogActionsRenderWidget(
//   isStacked: true,
//   children: <Widget>[
//     new BaseLayoutId<_CupertinoDialogActionsRenderWidget, MultiChildLayoutParentData>(
//       id: _AlertDialogPieces.actionsSection,
//       child: actionsSection,
//     ),
//   ]..addAll(buttons),
// );
// ```
//
// When displayed horizontally:
// The entire actions section (all buttons, dividers, etc) should be a single
// grandchild of this widget, and it should be wrapped with a
// [BaseLayoutId<_CupertinoDialogActionsRenderWidget, MultiChildLayoutParentData>]
// whose ID is [_AlertDialogPieces.actionsSection].
//
// Also, the single actions section widget that is a child of [BaseLayoutId] should
// also be passed to this widget as a direct child. The reason to pass it a 2nd
// time is to allow this widget to explicitly measure the actions section.
//
// Horizontal example:
//
// ```
// new _CupertinoDialogActionsRenderWidget(
//   isStacked: false,
//   children: <Widget>[
//     new BaseLayoutId<_CupertinoDialogActionsRenderWidget, MultiChildLayoutParentData>(
//       id: _AlertDialogPieces.actionsSection,
//       child: actionsSection,
//     actionsSection,
//   ],
// );
// ```
class _CupertinoDialogActionsRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogActionsRenderWidget({
    Key key,
    @required List<Widget> children,
    bool isStacked = false,
  }) : _isStacked = isStacked,
        super(key: key, children: children);

  final bool _isStacked;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderCupertinoDialogActions(
      isStacked: _isStacked,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoDialogActions renderObject) {
    renderObject.isStacked = _isStacked;
  }
  
}

// iOS style layout policy for sizing an alert dialog's action buttons.
//
// The policy is as follows:
//
// If buttons are stacked (see [isStacked]), a minimum intrinsic height is
// reported that equals the height of the first button + 50% the height of
// the second button. The policy, more generally, is 1.5x button height, but
// it's possible that buttons are of different heights, so this policy measures
// the first 2 buttons directly. This policy reflects how iOS stacks buttons
// in an alert dialog. By exposing 50% of the 2nd button, the dialog makes it
// clear that there are more buttons "below the fold".
//
// If buttons are not stacked, then they appear in a horizontal row. In that
// case the minimum and maximum intrinsic height is set to the height of the
// button(s) in the row.
//
// [_RenderCupertinoDialogActions] has specific usage requirements. See
// [_CupertinoDialogActionsRenderWidget] for information about the type and
// order of expected child widgets.
class _RenderCupertinoDialogActions extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderCupertinoDialogActions({
    List<RenderBox> children,
    bool isStacked = false,
  }) : _isStacked = isStacked {
    addAll(children);
  }

  bool _isStacked;

  bool get isStacked => _isStacked;

  set isStacked(bool newValue) {
    if (newValue == _isStacked) {
      return;
    }

    _isStacked = newValue;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData)
      child.parentData = new MultiChildLayoutParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _kCupertinoDialogWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _kCupertinoDialogWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    double height = 0.0;

    if (_isStacked) {
      // Actions min height is first item height + 50% second item height.
      final RenderBox divider = _findDivider();
      final double dividerHeight = divider.computeMinIntrinsicHeight(width);
      final List<RenderBox> firstTwoButtons = _findFirstNButtonRows(2);
      final double firstButtonHeight = firstTwoButtons[0].computeMinIntrinsicHeight(width);
      final double secondButtonHeight = firstTwoButtons[1].computeMinIntrinsicHeight(width);
      height = firstButtonHeight + (0.5 * secondButtonHeight) + (dividerHeight * 2);
    } else {
      // Actions min height is first item height (because we are only showing 1 row).
      final List<RenderBox> firstButton = _findFirstNButtonRows(1);
      height = firstButton.first.computeMinIntrinsicHeight(width);
    }

    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _findActionsChild().computeMaxIntrinsicHeight(width);
  }

  @override
  void performLayout() {
    // First, layout all children at size zero because if we fail to call
    // layout() on a child then we'll get an error.
    final List<RenderBox> children = getChildrenAsList();
    for (RenderBox child in children) {
      child.layout(
        new BoxConstraints.tight(const Size(0.0, 0.0)),
        parentUsesSize: false,
      );
    }

    // Layout the one child we actually care about, which is the dialog "actions".
    final RenderBox actions = _findActionsChild();
    actions.layout(
      constraints,
      parentUsesSize: true,
    );

    // Set our size to be as wide as we want, and as tall as the "actions" we
    // measured.
    size = new Size(constraints.biggest.width, actions.size.height);
  }

  RenderBox _findActionsChild() {
    RenderBox actions;
    final List<RenderBox> children = getChildrenAsList();
    for (RenderBox child in children) {
      final MultiChildLayoutParentData parentData = child.parentData;
      if (parentData.id == _AlertDialogSections.actionsSection) {
        actions = child;
      }
    }
    assert(actions != null);

    return actions;
  }

  RenderBox _findDivider() {
    RenderBox divider;
    final List<RenderBox> children = getChildrenAsList();
    for (RenderBox child in children) {
      // The first child that isn't "actions" should be a divider.
      final MultiChildLayoutParentData parentData = child.parentData;
      if (parentData.id != _AlertDialogSections.actionsSection) {
        divider = child;
      }
    }
    assert(divider != null);

    return divider;
  }

  List<RenderBox> _findFirstNButtonRows(int buttonCount) {
    final List<RenderBox> firstNButtons = <RenderBox>[];
    final List<RenderBox> children = getChildrenAsList();
    for (int i = 0; i < children.length; i += 1) {
      if (i % 2 == 0) {
        continue;
      }

      final RenderBox child = children[i];
      final MultiChildLayoutParentData parentData = child.parentData;
      if (parentData.id != _AlertDialogSections.actionsSection) {
        firstNButtons.add(child);

        if (firstNButtons.length == buttonCount) {
          break;
        }
      }
    }
    assert(firstNButtons.length == buttonCount);

    return firstNButtons;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // Only paint the actions widget. Do not paint other children because
    // they're only used for layout calculations.
    final RenderBox actions = _findActionsChild();
    final MultiChildLayoutParentData parentData = actions.parentData;
    context.paintChild(actions, parentData.offset + offset);
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    // Only hit test the actions widget. Do not hit test other children because
    // they're only used for layout calculations.
    final RenderBox actions = _findActionsChild();
    final MultiChildLayoutParentData parentData = actions.parentData;
    return actions.hitTest(result, position: position - parentData.offset);
  }
}