// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'scrollbar.dart';

// TODO(abarth): These constants probably belong somewhere more general.

const TextStyle _kCupertinoDialogTitleStyle = TextStyle(
  fontFamily: '.SF UI Display',
  inherit: false,
  fontSize: 18.0,
  fontWeight: FontWeight.w500,
  color: CupertinoColors.black,
  height: 1.06,
  letterSpacing: 0.48,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogContentStyle = TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.4,
  fontWeight: FontWeight.w300,
  color: CupertinoColors.black,
  height: 1.036,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kCupertinoDialogActionStyle = TextStyle(
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
const BoxDecoration _kCupertinoDialogBlurOverlayDecoration = BoxDecoration(
  color: CupertinoColors.white,
  backgroundBlendMode: BlendMode.overlay,
);

const double _kBlurAmount = 20.0;
const double _kEdgePadding = 20.0;
const double _kMinButtonHeight = 45.0;
const double _kDialogCornerRadius = 12.0;
const double _kDividerThickness = 1.0;

// Translucent white that is painted on top of the blurred backdrop as the
// dialog's background color.
const Color _kDialogColor = Color(0xC0FFFFFF);

// Translucent white that is painted on top of the blurred backdrop as the
// background color of a pressed button.
const Color _kDialogPressedColor = Color(0x90FFFFFF);

// Translucent white that is painted on top of the blurred backdrop in the
// gap areas between the content section and actions section, as well as between
// buttons.
const Color _kButtonDividerColor = Color(0x40FFFFFF);

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
          filter: new ImageFilter.blur(sigmaX: _kBlurAmount, sigmaY: _kBlurAmount),
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
      final Widget titleSection = new _CupertinoAlertContentSection(
        title: title,
        content: content,
        scrollController: scrollController,
      );
      children.add(new Flexible(flex: 3, child: titleSection));
      if (actions.isNotEmpty) {
        // If both sections have content, place padding between them.
        children.add(const Padding(padding: EdgeInsets.only(top: 8.0)));
      }
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
    Widget actionSection = new Container(
      height: 0.0,
    );
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
        // rounded corners, but Skia cannot internally create a blurred rounded
        // rect. Therefore, we have no choice but to clip, ourselves.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kDialogCornerRadius),
          child: new BackdropFilter(
            filter: new ImageFilter.blur(sigmaX: _kBlurAmount, sigmaY: _kBlurAmount),
            child: new Container(
              decoration: _kCupertinoDialogBlurOverlayDecoration,
              child: new _CupertinoDialogRenderWidget(
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
// See [_RenderCupertinoDialog] for specific layout policy details.
class _CupertinoDialogRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogRenderWidget({
    Key key,
    @required List<Widget> children,
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderCupertinoDialog();
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
// With the minimum action button section calculated, the content section can
// take up as much space as is available, up to the point that it hits the
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
  }) {
    if (contentSection != null) {
      add(contentSection);
    }
    if (actionsSection != null) {
      add(actionsSection);
    }
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
    // Obtain references to the specific children we need lay out.
    final _DialogChildren dialogChildren = _findDialogChildren();
    final RenderBox content = dialogChildren.content;
    final RenderBox actions = dialogChildren.actions;

    final double contentHeight = content.getMinIntrinsicHeight(width);
    final double actionsHeight = actions.getMinIntrinsicHeight(width);
    final double height = contentHeight + actionsHeight;

    if (height.isFinite)
      return height;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
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
    size = new Size(_kCupertinoDialogWidth, dialogHeight);

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
  _DialogChildren({
    this.content,
    this.actions,
  });

  final RenderBox content;
  final RenderBox actions;
}

// The "content section" of a CupertinoAlertDialog.
//
// If title is missing, then only content is added.  If content is
// missing, then only title is added. If both are missing, then it returns
// a SingleChildScrollView with a zero-sized Container.
class _CupertinoAlertContentSection extends StatelessWidget {
  const _CupertinoAlertContentSection({
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
      titleContentGroup.insert(1, const Padding(padding: EdgeInsets.only(top: 8.0)));
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

// The "actions section" of a [CupertinoAlertDialog].
//
// See [_RenderCupertinoDialogActions] for details about action button sizing
// and layout.
class _CupertinoAlertActionSection extends StatefulWidget {
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

  @override
  _CupertinoAlertActionSectionState createState() => new _CupertinoAlertActionSectionState();
}

class _CupertinoAlertActionSectionState extends State<_CupertinoAlertActionSection> {
  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final List<Widget> interactiveButtons = <Widget>[];
    for (int i = 0; i < widget.children.length; i += 1) {
      interactiveButtons.add(
        new _PressableActionButton(
          child: widget.children[i],
        ),
      );
    }

    return new CupertinoScrollbar(
      child: new SingleChildScrollView(
        controller: widget.scrollController,
        child: new _CupertinoDialogActionsRenderWidget(
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
    @required this.child,
  });

  final Widget child;

  @override
  _PressableActionButtonState createState() => new _PressableActionButtonState();
}

class _PressableActionButtonState extends State<_PressableActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return new _ActionButtonParentDataWidget(
      isPressed: _isPressed,
      // TODO:(mattcarroll): Button press dynamics need overhaul for iOS: https://github.com/flutter/flutter/issues/19786
      child: new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails details) => setState(() => _isPressed = true),
        onTapUp: (TapUpDetails details) => setState(() => _isPressed = false),
        // TODO(mattcarroll): Cancel is currently triggered when user moves past slop instead of off button: https://github.com/flutter/flutter/issues/19783
        onTapCancel: () => setState(() => _isPressed = false),
        child: widget.child,
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
class _ActionButtonParentDataWidget extends ParentDataWidget<_CupertinoDialogActionsRenderWidget> {
  const _ActionButtonParentDataWidget({
    Key key,
    this.isPressed,
    @required Widget child,
  }) : super(key: key, child: child);

  final bool isPressed;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is _ActionButtonParentData);
    final _ActionButtonParentData parentData = renderObject.parentData;
    if (parentData.isPressed != isPressed) {
      parentData.isPressed = isPressed;

      // Force a repaint.
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject)
        targetParent.markNeedsPaint();
    }
  }
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
          minHeight: _kMinButtonHeight,
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

// iOS style dialog action button layout.
//
// [_CupertinoDialogActionsRenderWidget] does not provide any scrolling
// behavior for its buttons. It only handles the sizing and layout of buttons.
// Scrolling behavior can be composed on top of this widget, if desired.
//
// See [_RenderCupertinoDialogActions] for specific layout policy details.
class _CupertinoDialogActionsRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogActionsRenderWidget({
    Key key,
    @required List<Widget> actionButtons,
    double dividerThickness = 0.0,
  }) : _dividerThickness = dividerThickness,
       super(key: key, children: actionButtons);

  final double _dividerThickness;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderCupertinoDialogActions(
      dividerThickness: _dividerThickness,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoDialogActions renderObject) {
    renderObject.dividerThickness = _dividerThickness;
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
    List<RenderBox> children,
    double dividerThickness = 0.0,
  }) : _dividerThickness = dividerThickness {
    addAll(children);
  }

  // The thickness of the divider between buttons.
  double get dividerThickness => _dividerThickness;
  double _dividerThickness;
  set dividerThickness(double newValue) {
    if (newValue == _dividerThickness) {
      return;
    }

    _dividerThickness = newValue;
    markNeedsLayout();
  }

  final Paint _buttonBackgroundPaint = new Paint()
    ..color = _kDialogColor
    ..style = PaintingStyle.fill;

  final Paint _pressedButtonBackgroundPaint = new Paint()
    ..color = _kDialogPressedColor
    ..style = PaintingStyle.fill;

  final Paint _dividerPaint = new Paint()
    ..color = _kButtonDividerColor
    ..style = PaintingStyle.fill;

  Iterable<RenderBox> get _pressedButtons sync* {
    RenderBox currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData;
      if (parentData.isPressed) {
        yield currentChild;
      }
      currentChild = childAfter(currentChild);
    }
  }

  bool get _isButtonPressed {
    RenderBox currentChild = firstChild;
    while (currentChild != null) {
      assert(currentChild.parentData is _ActionButtonParentData);
      final _ActionButtonParentData parentData = currentChild.parentData;
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
      child.parentData = new _ActionButtonParentData();
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
    double minHeight;
    if (childCount == 0) {
      minHeight = 0.0;
    } else if (childCount == 1) {
      // If only 1 child
      minHeight = _computeMinIntrinsicHeightSideBySide(width);
    } else {
      if (childCount == 2) {
        if (_isSingleButtonRow(width)) {
          // The first 2 buttons fit side-by-side. Display them horizontally.
          minHeight = _computeMinIntrinsicHeightSideBySide(width);
        } else {
          // The first 2 buttons do not fit side-by-side. Display them stacked.
          // The minimum height for 2 buttons when stacked is the minimum height
          // of both buttons + dividers (no scrolling for 2 buttons).
          minHeight = _computeMinIntrinsicHeightForTwoStackedButtons(width);
        }
      } else {
        // 3+ buttons are always stacked. The minimum height when stacked is
        // 1.5 buttons tall.
        minHeight = _computeMinIntrinsicHeightStacked(width);
      }
    }
    return minHeight;
  }

  // The minimum height for a single row of buttons is the larger of the buttons'
  // min intrinsic heights + the width of a divider
  double _computeMinIntrinsicHeightSideBySide(double width) {
    assert(childCount >= 1 && childCount <= 2);

    double minHeight;
    if (childCount == 1) {
      minHeight = firstChild.getMinIntrinsicHeight(width) + dividerThickness;
    } else {
      final double perButtonWidth = (width - dividerThickness) / 2.0;
      minHeight = math.max(
        firstChild.getMinIntrinsicHeight(perButtonWidth) + dividerThickness,
        lastChild.getMinIntrinsicHeight(perButtonWidth) + dividerThickness,
      );
    }
    return minHeight;
  }

  // The minimum height for 2 stacked buttons is the height of both
  // buttons + 2 dividers.
  double _computeMinIntrinsicHeightForTwoStackedButtons(double width) {
    assert(childCount == 2);

    return (2 * dividerThickness)
        + firstChild.getMinIntrinsicHeight(width)
        + lastChild.getMinIntrinsicHeight(width);
  }

  // The minimum height for 3+ stacked buttons is the height of the 1st button
  // + 50% the height of the 2nd button + 2 dividers.
  double _computeMinIntrinsicHeightStacked(double width) {
    assert(childCount >= 3);

    return (2 * dividerThickness)
      + firstChild.getMinIntrinsicHeight(width)
      + (0.5 * childAfter(firstChild).getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    double maxHeight;
    if (childCount == 0) {
      // No buttons. Zero height.
      maxHeight = 0.0;
    } else if (childCount == 1) {
      // One button. Our max intrinsic height is equal to the button's.
      maxHeight = firstChild.getMaxIntrinsicHeight(width) + dividerThickness;
    } else if (childCount == 2) {
      // Two buttons...
      if (_isSingleButtonRow(width)) {
        // The 2 buttons fit side by side so our max intrinsic height is equal
        // to the taller of the 2 buttons.
        final double perButtonWidth = (width - dividerThickness) / 2.0;
        maxHeight = math.max(
          firstChild.getMaxIntrinsicHeight(perButtonWidth) + dividerThickness,
          lastChild.getMaxIntrinsicHeight(perButtonWidth) + dividerThickness,
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

    final double allDividersHeight = childCount * dividerThickness;
    return getChildrenAsList().fold(allDividersHeight, (double heightAccumulation, RenderBox button) {
      return heightAccumulation + button.getMaxIntrinsicHeight(width);
    });
  }

  bool _isSingleButtonRow(double width) {
    bool isSingleButtonRow;
    if (childCount == 1) {
      isSingleButtonRow = true;
    } else if (childCount == 2) {
      // There are 2 buttons. If they can fit side-by-side then that's what
      // we want to do. Otherwise, stack them vertically.
      final double sideBySideWidth = firstChild.getMaxIntrinsicWidth(double.infinity)
          + dividerThickness
          + lastChild.getMaxIntrinsicWidth(double.infinity);
      isSingleButtonRow = sideBySideWidth <= width;
    } else {
      isSingleButtonRow = false;
    }
    return isSingleButtonRow;
  }

  @override
  void performLayout() {
    if (_isSingleButtonRow(_kCupertinoDialogWidth)) {
      if (childCount == 1) {
        // We have 1 button. Our size is the width of the dialog and the height
        // of the single button.
        firstChild.layout(
          constraints,
          parentUsesSize: true,
        );

        size = new Size(_kCupertinoDialogWidth, firstChild.size.height + dividerThickness);
      } else {
        // Each button gets half the available width, minus a single divider.
        final BoxConstraints perButtonConstraints = constraints.copyWith(
          minWidth: (constraints.minWidth - dividerThickness) / 2.0,
          maxWidth: (constraints.maxWidth - dividerThickness) / 2.0,
        );

        // Layout the 2 buttons.
        for (RenderBox button in getChildrenAsList()) {
          button.layout(
            perButtonConstraints,
            parentUsesSize: true,
          );
        }

        // The 2nd button needs to be offset to the right.
        assert(lastChild.parentData is MultiChildLayoutParentData);
        final MultiChildLayoutParentData secondButtonParentData = lastChild.parentData;
        secondButtonParentData.offset = new Offset(firstChild.size.width + dividerThickness, 0.0);

        // Calculate our size based on the button sizes.
        size = new Size(
          _kCupertinoDialogWidth,
          math.max(
            firstChild.size.height,
            lastChild.size.height,
          ) + dividerThickness,
        );
      }
    } else {
      // We need to stack buttons vertically, plus dividers above each button.
      final BoxConstraints perButtonConstraints = constraints.copyWith(
        minHeight: 0.0,
        maxHeight: (constraints.maxHeight - (dividerThickness * childCount)) / childCount,
      );

      final List<RenderBox> children = getChildrenAsList();
      double verticalOffset = dividerThickness;
      for (int i = 0; i < children.length; ++i) {
        final RenderBox child = children[i];

        child.layout(
          perButtonConstraints,
          parentUsesSize: true,
        );

        assert(child.parentData is MultiChildLayoutParentData);
        final MultiChildLayoutParentData parentData = child.parentData;
        parentData.offset = new Offset(0.0, verticalOffset);

        verticalOffset += child.size.height;
        if (i < children.length - 1) {
          // Add a gap for the next divider.
          verticalOffset += dividerThickness;
        }
      }

      // Our height is the accumulated height of all buttons and dividers.
      size = new Size(_kCupertinoDialogWidth, verticalOffset);
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
    // The horizontal divider crosses the dialog from left to right, and appears
    // above all buttons.
    final Rect horizontalDivider = new Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      dividerThickness,
    );

    // The vertical divider sits between the left button and right button (if
    // the dialog has 2 buttons), and it starts just beneath the horizontal
    // divider and goes to the bottom of the single row of buttons. The
    // vertical divider is hidden if either the left or right button is pressed.
    final Rect verticalDivider = childCount == 2 && !_isButtonPressed
      ? new Rect.fromLTWH(
          offset.dx + firstChild.size.width,
          offset.dy + horizontalDivider.height,
          dividerThickness,
          math.max(
            firstChild.size.height,
            lastChild.size.height,
          ),
        )
      : Rect.zero;

    final List<Rect> pressedButtonRects = _pressedButtons.map((RenderBox pressedButton) {
      final MultiChildLayoutParentData buttonParentData = pressedButton.parentData;

      return new Rect.fromLTWH(
        offset.dx + buttonParentData.offset.dx,
        offset.dy + buttonParentData.offset.dy + dividerThickness,
        pressedButton.size.width,
        pressedButton.size.height,
      );
    }).toList();

    // Create the button backgrounds path and paint it.
    final Path backgroundFillPath = new Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.largest)
      ..addRect(horizontalDivider)
      ..addRect(verticalDivider);

    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      backgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      backgroundFillPath,
      _buttonBackgroundPaint,
    );

    // Create the pressed buttons background path and paint it.
    final Path pressedBackgroundFillPath = new Path();
    for (int i = 0; i < pressedButtonRects.length; i += 1) {
      pressedBackgroundFillPath.addRect(pressedButtonRects[i]);
    }

    canvas.drawPath(
      pressedBackgroundFillPath,
      _pressedButtonBackgroundPaint,
    );

    // Create the dividers path and paint it.
    final Path dividersPath = new Path()
      ..addRect(horizontalDivider)
      ..addRect(verticalDivider);

    canvas.drawPath(
      dividersPath,
      _dividerPaint,
    );
  }

  void _drawButtonBackgroundsAndDividersStacked(Canvas canvas, Offset offset) {
    final Offset dividerOffset = new Offset(0.0, dividerThickness);

    final Path backgroundFillPath = new Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.largest);

    final Path pressedBackgroundFillPath = new Path();

    final Path dividersPath = new Path();

    Offset accumulatingOffset = offset;

    final List<RenderBox> children = getChildrenAsList();
    for (int i = 0; i < children.length; i += 1) {
      assert(children[i].parentData is _ActionButtonParentData);
      final _ActionButtonParentData currentButtonParentData = children[i].parentData;
      final bool isButtonPressed = currentButtonParentData.isPressed;

      bool isPrevButtonPressed = false;
      if (i > 0) {
        assert(children[i - 1].parentData is _ActionButtonParentData);
        final _ActionButtonParentData previousButtonParentData = children[i - 1]
            .parentData;
        isPrevButtonPressed = previousButtonParentData.isPressed;
      }

      final bool dividerNeeded = i == 0 || !(isButtonPressed || isPrevButtonPressed);

      final Rect dividerRect = new Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy,
        size.width,
        dividerThickness,
      );

      final Rect buttonBackgroundRect = new Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy + dividerThickness,
        size.width,
        children[i].size.height,
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
      if (dividerNeeded) {
        backgroundFillPath.addRect(dividerRect);
        dividersPath.addRect(dividerRect);
      }

      accumulatingOffset += dividerOffset + new Offset(0.0, children[i].size.height);
    }

    canvas.drawPath(backgroundFillPath, _buttonBackgroundPaint);
    canvas.drawPath(pressedBackgroundFillPath, _pressedButtonBackgroundPaint);
    canvas.drawPath(dividersPath, _dividerPaint);
  }

  void _drawButtons(PaintingContext context, Offset offset) {
    for (RenderBox child in getChildrenAsList()) {
      final MultiChildLayoutParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(HitTestResult result, { Offset position }) {
    return defaultHitTestChildren(result, position: position);
  }
}