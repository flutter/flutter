// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'scrollbar.dart';

const TextStyle _kActionSheetActionStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 20.0,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.activeBlue,
  textBaseline: TextBaseline.alphabetic,
);

const TextStyle _kActionSheetContentStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 13.0,
  fontWeight: FontWeight.w400,
  color: _kContentTextColor,
  textBaseline: TextBaseline.alphabetic,
);

// _kCupertinoAlertBlurOverlayDecoration is applied to the blurred backdrop to
// lighten the blurred image. Brightening is done to counteract the dark modal
// barrier that appears behind the alert. The overlay blend mode does the
// brightening. The white color doesn't paint any white, it's just the basis
// for the overlay blend mode.
const BoxDecoration _kCupertinoAlertBlurOverlayDecoration = BoxDecoration(
  color: CupertinoColors.white,
  backgroundBlendMode: BlendMode.overlay,
);

// Translucent, very light gray that is painted on top of the blurred backdrop
// as the action sheet's background color.
const Color _kBackgroundColor = const Color(0xD1F8F8F8);

// Translucent, light gray that is painted on top of the blurred backdrop as
// the background color of a pressed button.
const Color _kPressedColor = const Color(0xA6E5E5EA);

// Translucent gray that is painted on top of the blurred backdrop in the gap
// areas between the content section and actions section, as well as between
// buttons.
const Color _kButtonDividerColor = const Color(0x403F3F3F);

const Color _kContentTextColor = const Color(0xFF8F8F8F);
const Color _kCancelButtonPressedColor = const Color(0xFFEAEAEA);

const double _kEdgeHorizontalPadding = 8.0;
const double _kEdgeVerticalPadding = 10.0;
const double _kContentHorizontalPadding = 40.0;
const double _kContentVerticalPadding = 14.0;

const double _kButtonHeight = 56.0;
const double _kCornerRadius = 14.0;
const double _kDividerThickness = 1.0;

/// An iOS-style action sheet.
///
/// An action sheet is a specific style of alert that present the user
/// with a set of two or more choices related to the current context.
/// An action sheet can have a title, an additional message, and a list
/// of actions. The title is displayed above the message and the actions
/// are displayed below this content.
///
/// This action sheet styles its title and message to match standard iOS action
/// sheet title and message text style.
///
/// To display action buttons that look like standard iOS action sheet buttons,
/// provide [ActionSheetAction]s for the [actions] given to this action shet.
///
/// To include a iOS-style cancel button separate from the other buttons,
/// provide an [ActionSheetAction] for the [cancelButton] given to this
/// action sheet.
///
/// An action sheet is typically passed as the child widget to
/// [showCupertinoModalPopup], which displays the action sheet by sliding it up
/// from the bottom of the screen.
///
/// See also:
///
///  * [ActionSheetAction], which is an iOS-style action sheet button.
///  * <https://developer.apple.com/design/human-interface-guidelines/ios/views/action-sheets/>
class CupertinoActionSheet extends StatelessWidget {
  /// Creates an iOS-style action sheet.
  ///
  /// An action sheet must have a non-null value for at least one of the
  /// following arguments: [actions], [title], [message], or [cancelButton].
  ///
  /// Generally, action sheets are used to give the user a choice between
  /// two or more choices for the current context.
  const CupertinoActionSheet({
    Key key,
    this.title,
    this.message,
    this.actions,
    this.messageScrollController,
    this.actionScrollController,
    this.cancelButton,
  })  : assert(actions != null || title != null || message != null || cancelButton != null),
        super(key: key);

  /// The optional title of the action sheet. When the [message] is non-null,
  /// the font of the [title] is bold.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// The optional descriptive message that provides more details about the
  /// reason for the alert.
  ///
  /// Typically a [Text] widget.
  final Widget message;

  /// The set of actions that are displayed for the user to select.
  ///
  /// Typically this is a list of [ActionSheetAction] widgets.
  final List<Widget> actions;

  /// A scroll controller that can be used to control the scrolling of the
  /// [message] in the action sheet.
  ///
  /// This attribute is typically not needed, as alert messages should be
  /// short.
  final ScrollController messageScrollController;

  /// A scroll controller that can be used to control the scrolling of the
  /// [actions] in the action sheet.
  ///
  /// This attribute is typically not needed.
  final ScrollController actionScrollController;

  /// The optional cancel button that is grouped separately from the other
  /// actions.
  ///
  /// Typically this is an [ActionSheetAction] widget.
  final Widget cancelButton;

  Widget _buildContent() {
    final List<Widget> content = <Widget>[];
    if (title != null || message != null) {
      final Widget titleSection = new _CupertinoAlertContentSection(
        title: title,
        message: message,
        scrollController: messageScrollController,
      );
      content.add(new Flexible(child: titleSection));
    }

    return new Container(
      key: const Key('cupertino_action_sheet_content_section'),
      color: _kBackgroundColor,
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      ),
    );
  }

  Widget _buildActions() {
    if (actions == null || actions.isEmpty) {
      return new Container(
        height: 0.0,
      );
    }
    return new Container(
      child: _CupertinoAlertActionSection(
        children: actions,
        scrollController: actionScrollController,
      ),
    );
  }

  Widget _buildCancelButton() {
    final double cancelPadding = (actions != null || message != null || title != null) ? _kEdgeHorizontalPadding : 0.0;
    return Padding(
      padding: new EdgeInsets.only(top: cancelPadding),
      child: new _CupertinoActionSheetCancelButton(
        child: cancelButton,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      new Flexible(child: ClipRRect(
        key: const Key('cupertino_action_sheet_modal'),
        borderRadius: BorderRadius.circular(12.0),
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: new Container(
            decoration: _kCupertinoAlertBlurOverlayDecoration,
            child: new _CupertinoAlertRenderWidget(
              children: <Widget>[
                new BaseLayoutId<_CupertinoAlertRenderWidget, MultiChildLayoutParentData>(
                  id: _AlertSections.actionsSection,
                  child: _buildActions(),
                ),
                new BaseLayoutId<_CupertinoAlertRenderWidget, MultiChildLayoutParentData>(
                  id: _AlertSections.contentSection,
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    ];

    if (cancelButton != null) {
      children.add(
        _buildCancelButton(),
      );
    }

    final Orientation orientation = MediaQuery.of(context).orientation;
    double actionSheetWidth;
    if (orientation == Orientation.portrait) {
      actionSheetWidth = MediaQuery.of(context).size.width - (_kEdgeHorizontalPadding * 2);
    } else {
      actionSheetWidth = MediaQuery.of(context).size.height - (_kEdgeHorizontalPadding * 2);
    }

    return new SafeArea(
      child: new Semantics(
        namesRoute: true,
        scopesRoute: true,
        explicitChildNodes: true,
        label: 'Alert',
        child: new Container(
          width: actionSheetWidth,
          margin: const EdgeInsets.symmetric(horizontal: _kEdgeHorizontalPadding, vertical: _kEdgeVerticalPadding),
          child: new Column(
            children: children,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          ),
        ),
      ),
    );
  }
}

/// A button typically used in an [CupertinoActionSheet].
///
/// See also:
///
///  * [CupertinoActionSheet], an alert that presents the user with a set of two or
///    more choices related to the current context.
class ActionSheetAction extends StatelessWidget {
  ///Creates an action for an iOS-style action sheet.
  const ActionSheetAction({
    @required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    @required this.child,
  })  : assert(child != null),
        assert(onPressed != null);

  /// The callback that is called when the button is tapped.
  ///
  /// This attribute must not be null.
  final VoidCallback onPressed;

  /// Whether this action is the default choice in the action sheet.
  ///
  /// Default buttons have bold text.
  final bool isDefaultAction;

  /// Whether this action might change or delete data.
  ///
  /// Destructive buttons have red text.
  final bool isDestructiveAction;

  /// The widget below this widget in the tree.
  ///
  /// Typically a [Text] widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    TextStyle style = _kActionSheetActionStyle;

    if (isDefaultAction) {
      style = style.copyWith(fontWeight: FontWeight.w600);
    }

    if (isDestructiveAction) {
      style = style.copyWith(color: CupertinoColors.destructiveRed);
    }

    return new GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: new ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _kButtonHeight,
        ),
        child: new Semantics(
          button: true,
          child: new Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
                horizontal: 10.0,
              ),
              child: new DefaultTextStyle(
                style: style,
                child: child,
                textAlign: TextAlign.center,
              )),
        ),
      ),
    );
  }
}

class _CupertinoActionSheetCancelButton extends StatefulWidget {
  const _CupertinoActionSheetCancelButton({
    Key key,
    this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _CupertinoActionSheetCancelButtonState createState() => _CupertinoActionSheetCancelButtonState();
}

class _CupertinoActionSheetCancelButtonState extends State<_CupertinoActionSheetCancelButton> {
  Color _backgroundColor;

  @override
  void initState() {
    _backgroundColor = CupertinoColors.white;
    super.initState();
  }

  void _onTapDown(TapDownDetails event) {
    setState(() {
      _backgroundColor = _kCancelButtonPressedColor;
    });
  }

  void _onTapUp(TapUpDetails event) {
    setState(() {
      _backgroundColor = CupertinoColors.white;
    });
  }

  void _onTapCancel() {
    setState(() {
      _backgroundColor = CupertinoColors.white;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: new Container(
        decoration: new BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(_kCornerRadius),
        ),
        child: widget.child,
      ),
    );
  }
}

class _CupertinoAlertRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoAlertRenderWidget({
    Key key,
    @required List<Widget> children,
  }) : super(key: key, children: children);


  @override
  RenderObject createRenderObject(BuildContext context) {
    return new _RenderCupertinoAlert();
  }

  @override
  void updateRenderObject(BuildContext context, _RenderCupertinoAlert renderObject) {
    // NO-OP
  }
}

// iOS style layout policy for sizing an alert's content section and action
// button section.
//
// The policy is as follows:
//
// If all content and buttons fit on screen:
// The content section and action button section are sized intrinsically.
//
// If all content and buttons do not fit on screen:
// A minimum height for the action button section is calculated. The action
// button section will not be rendered shorter than this minimum.  See
// [_RenderCupertinoAlertActions] for the minimum height calculation.
//
// With the minimum action button section calculated, the content section is
// laid out as tall as it wants to be, up to the point that it hits the
// minimum button height at the bottom.
//
// After the content section is laid out, the action button section is allowed
// to take up any remaining space that was not consumed by the content section.
class _RenderCupertinoAlert extends RenderBox with ContainerRenderObjectMixin<RenderBox,
    MultiChildLayoutParentData>, RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderCupertinoAlert({
    RenderBox contentSection,
    RenderBox actionsSection,
  }) {
    if (null != contentSection) {
      add(contentSection);
    }
    if (null != actionsSection) {
      add(actionsSection);
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = new MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return constraints.minWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return constraints.maxWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    // Obtain references to the specific children we need lay out.
    final _AlertChildren dialogChildren = _findDialogChildren();
    final RenderBox content = dialogChildren.content;
    final RenderBox actions = dialogChildren.actions;

    final double contentHeight = content.getMinIntrinsicHeight(width);
    final double actionsHeight = actions.getMinIntrinsicHeight(width);
    double height = contentHeight + actionsHeight;

    if (actionsHeight > 0 || contentHeight > 0) {
      height -= 2 * _kEdgeHorizontalPadding;
    }
    if (height.isFinite) {
      return height;
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    // Obtain references to the specific children we need lay out.
    final _AlertChildren dialogChildren = _findDialogChildren();
    final RenderBox content = dialogChildren.content;
    final RenderBox actions = dialogChildren.actions;

    final double contentHeight = content.getMaxIntrinsicHeight(width);
    final double actionsHeight = actions.getMaxIntrinsicHeight(width);
    double height = contentHeight + actionsHeight;

    if (actionsHeight > 0 || contentHeight > 0) {
      height -= 2 * _kEdgeHorizontalPadding;
    }
    if (height.isFinite) {
      return height;
    }
    return 0.0;
  }

  @override
  void performLayout() {
    // Obtain references to the specific children we need lay out.
    final _AlertChildren dialogChildren = _findDialogChildren();
    final RenderBox content = dialogChildren.content;
    final RenderBox actions = dialogChildren.actions;

    final double minActionsHeight = actions.getMinIntrinsicHeight(constraints.maxWidth);

    final Size maxActionSheetSize = constraints.biggest;

    // Size alert content.
    content.layout(
      constraints.deflate(new EdgeInsets.only(bottom: minActionsHeight)),
      parentUsesSize: true,
    );
    final Size contentSize = content.size;

    // Size alert actions.
    actions.layout(
      constraints.deflate(new EdgeInsets.only(top: contentSize.height)),
      parentUsesSize: true,
    );
    final Size actionsSize = actions.size;

    // Calculate overall alert height.
    final double actionSheetHeight = contentSize.height + actionsSize.height;

    // Set our size now that layout calculations are complete.
    size = new Size(maxActionSheetSize.width, actionSheetHeight);

    // Set the position of the actions box to sit at the bottom of the alert.
    // The content box defaults to the top left, which is where we want it.
    assert(actions.parentData is MultiChildLayoutParentData);
    final MultiChildLayoutParentData actionParentData = actions.parentData;
    actionParentData.offset = new Offset(0.0, contentSize.height);
  }

  _AlertChildren _findDialogChildren() {
    RenderBox content;
    RenderBox actions;
    final List<RenderBox> children = getChildrenAsList();
    for (RenderBox child in children) {
      final MultiChildLayoutParentData parentData = child.parentData;
      if (parentData.id == _AlertSections.contentSection) {
        content = child;
      } else if (parentData.id == _AlertSections.actionsSection) {
        actions = child;
      }
    }
    assert(content != null);
    assert(actions != null);

    return new _AlertChildren(
      content: content,
      actions: actions,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(HitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

// Visual components of an alert that need to be explicitly sized and
// laid out at runtime.
enum _AlertSections {
  contentSection,
  actionsSection,
}

// Data structure used to pass around references to multiple alert pieces for
// layout calculations.
class _AlertChildren {
  _AlertChildren({
    this.content,
    this.actions,
  });

  final RenderBox content;
  final RenderBox actions;
}

// The "content section" of an [ActionSheet].
//
// If title is missing, then only content is added.  If content is
// missing, then only title is added. If both are missing, then it returns
// a SingleChildScrollView with a zero-sized Container.
class _CupertinoAlertContentSection extends StatelessWidget {
  const _CupertinoAlertContentSection({
    Key key,
    this.title,
    this.message,
    this.scrollController,
  }) : super(key: key);

  // The optional title of the action sheet. When the message is non-null,
  // the font of the title is bold.
  //
  // Typically a Text widget.
  final Widget title;

  // The optional descriptive message that provides more details about the
  // reason for the alert.
  //
  // Typically a Text widget.
  final Widget message;

  // A scroll controller that can be used to control the scrolling of the
  // content in the action sheet.
  //
  // Defaults to null, and is typically not needed, since most alert contents
  // are short.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final List<Widget> titleContentGroup = <Widget>[];
    if (title != null) {
      titleContentGroup.add(new Padding(
        padding: const EdgeInsets.only(
          left: _kContentHorizontalPadding,
          right: _kContentHorizontalPadding,
          bottom: _kContentVerticalPadding,
          top: _kContentVerticalPadding,
        ),
        child: new DefaultTextStyle(
          style: message == null ? _kActionSheetContentStyle :
            _kActionSheetContentStyle.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          child: title,
        ),
      ));
    }

    if (message != null) {
      titleContentGroup.add(
        new Padding(
          padding: new EdgeInsets.only(
            left: _kContentHorizontalPadding,
            right: _kContentHorizontalPadding,
            bottom: title == null ? _kContentVerticalPadding : 22.0,
            top: title == null ? _kContentVerticalPadding : 0.0,
          ),
          child: new DefaultTextStyle(
            style: title == null ? _kActionSheetContentStyle.copyWith(fontWeight: FontWeight.w600) :
              _kActionSheetContentStyle,
            textAlign: TextAlign.center,
            child: message,
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

// The "actions section" of an [ActionSheet].
//
// See [_RenderCupertinoAlertActions] for details about action button sizing
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
  // actions in the action sheet.
  //
  // Defaults to null, and is typically not needed, since most alerts
  // don't have many actions.
  final ScrollController scrollController;

  @override
  _CupertinoAlertActionSectionState createState() {
    return new _CupertinoAlertActionSectionState();
  }
}

class _CupertinoAlertActionSectionState extends State<_CupertinoAlertActionSection> {
  static _CupertinoAlertActionSectionState of(BuildContext context) {
    return context.ancestorStateOfType(
      const TypeMatcher<_CupertinoAlertActionSectionState>(),
    );
  }

  final Set<int> _pressedButtons = new Set<int>();

  void onButtonDown(int index) {
    setState(() => _pressedButtons.add(index));
  }

  void onButtonUp(int index) {
    setState(() => _pressedButtons.remove(index));
  }

  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    final List<Widget> interactiveButtons = <Widget>[];
    for (int i = 0; i < widget.children.length; i += 1) {
      interactiveButtons.add(
        new GestureDetector(
          onTapDown: (TapDownDetails details) {
            onButtonDown(i);
          },
          onTapUp: (TapUpDetails details) {
            onButtonUp(i);
          },
          onTapCancel: () {
            onButtonUp(i);
          },
          child: widget.children[i],
        ),
      );
    }

    return new CupertinoScrollbar(
      child: new SingleChildScrollView(
        controller: widget.scrollController,
        child: new _CupertinoDialogActionsRenderWidget(
          actionButtons: interactiveButtons,
          pressedButtons: new Set<int>.from(_pressedButtons),
          dividerThickness: _kDividerThickness / devicePixelRatio,
        ),
      ),
    );
  }
}

// iOS style dialog action button layout.
//
// See [_RenderCupertinoDialogActions] for specific layout policy details.
class _CupertinoDialogActionsRenderWidget extends MultiChildRenderObjectWidget {
  _CupertinoDialogActionsRenderWidget({
    Key key,
    @required List<Widget> actionButtons,
    @required Set<int> pressedButtons,
    double dividerThickness = 0.0,
  }) : assert(pressedButtons != null),
        _pressedButtons = pressedButtons,
        _dividerThickness = dividerThickness,
      super(key: key, children: actionButtons);

  final Set<int> _pressedButtons;
  final double _dividerThickness;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return new RenderCupertinoDialogActions(
      pressedButtons: _pressedButtons,
      dividerThickness: _dividerThickness,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderCupertinoDialogActions renderObject) {
    renderObject.pressedButtons = _pressedButtons;
    renderObject.dividerThickness = _dividerThickness;
  }
}

// iOS-style layout policy for sizing and positioning an action sheet's buttons.
//
// The policy is as follows:
//
// Action sheet buttons are always stacked vertically. In the case where the
// content section and the action section combined can not fit on the screen
// without scrolling, the height of the action section is determined as
// follows.
//
// If the user has included a separate cancel button, the height of the action
// section can be up to the height of 3 action buttons (i.e., the user can
// include 1, 2, or 3 action buttons and they will appear without needing to
// be scrolled). If 4+ action buttons are provided, the height of the action
// section shrinks to 1.5 buttons tall, and is scrollable.
//
// If the user has not included a separate cancel button, the height of the
// action section is at most 1.5 buttons tall.
@visibleForTesting
class RenderCupertinoDialogActions extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  /// Creates an iOS dialog actions section layout policy.
  ///
  /// [pressedButtons] must not be null.
  RenderCupertinoDialogActions({
    List<RenderBox> children,
    @required Set<int> pressedButtons,
    double dividerThickness = 0.0,
  }) :  assert(pressedButtons != null),
        _dividerThickness = dividerThickness,
        _pressedButtons = pressedButtons {
    addAll(children);
  }

  Set<int> _pressedButtons;

  /// The buttons which are currently pressed by the user.
  Set<int> get pressedButtons => _pressedButtons;

  set pressedButtons(Set<int> newValue) {
    if (_pressedButtons.containsAll(newValue)
        && newValue.containsAll(_pressedButtons)) {
      return;
    }

    _pressedButtons = newValue;
    markNeedsPaint();
  }

  double _dividerThickness;

  /// The thickness of the divider between buttons.
  double get dividerThickness => _dividerThickness;

  set dividerThickness(double newValue) {
    if (newValue == _dividerThickness) {
      return;
    }

    _dividerThickness = newValue;
    markNeedsLayout();
  }

  bool _hasCancelButton;
  bool get hasCancelButton => _hasCancelButton;
  set hasCancelButton(bool newValue) {
    if (newValue == _hasCancelButton) {
      return;
    }

    _hasCancelButton = newValue;
    markNeedsLayout();
  }

  final Paint _buttonBkPaint = new Paint()
    ..color = _kBackgroundColor
    ..style = PaintingStyle.fill;

  final Paint _pressedButtonBkPaint = new Paint()
    ..color = _kPressedColor
    ..style = PaintingStyle.fill;

  final Paint _dividerPaint = new Paint()
    ..color = _kButtonDividerColor
    ..style = PaintingStyle.fill;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData)
      child.parentData = new MultiChildLayoutParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return constraints.minWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return constraints.maxWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (childCount == 0) {
      return 0.0;
    }
    return _computeMinIntrinsicHeightStacked(width);
  }

  // The minimum height for more than 2 buttons is the height of the 1st button
  // + 50% the height of the 2nd button + 2 dividers.
  double _computeMinIntrinsicHeightStacked(double width) {
    final List<RenderBox> children = getChildrenAsList();
    if (children.length == 1) {
      return firstChild.computeMinIntrinsicHeight(width) + dividerThickness;
    }
    return (2 * dividerThickness)
        + children[0].computeMinIntrinsicHeight(width)
        + (0.5 * children[1].computeMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (childCount == 0) {
      // No buttons. Zero height.
      return 0.0;
    }
    return _computeMaxIntrinsicHeightStacked(width);
  }

  // Max height of a stack of buttons is the sum of all button heights + a
  // divider for each button.
  double _computeMaxIntrinsicHeightStacked(double width) {
    final double allDividersHeight = childCount * dividerThickness;
    return getChildrenAsList().fold(allDividersHeight, (double heightAccum, RenderBox button) {
      return heightAccum + button.computeMaxIntrinsicHeight(width);
    });
  }

  @override
  void performLayout() {
    final double layoutWidth  = constraints.maxWidth;
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
    size = new Size(layoutWidth, verticalOffset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    _drawButtonBackgroundsAndDividersStacked(canvas, offset);
    _drawButtons(context, offset);
  }

  void _drawButtonBackgroundsAndDividersStacked(Canvas canvas, Offset offset) {
    final Offset dividerOffset = new Offset(0.0, dividerThickness);

    final Path bkFillPath = new Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.largest);

    final Path pressedBkFillPath = new Path();

    final Path dividersPath = new Path();

    Offset accumulatingOffset = offset;

    final List<RenderBox> children = getChildrenAsList();
    for (int i = 0; i < children.length; i += 1) {
      final bool isButtonPressed = pressedButtons.contains(i);
      final bool isPrevButtonPressed = pressedButtons.contains(i - 1);
      final bool dividerNeeded = i == 0 || !(isButtonPressed || isPrevButtonPressed);

      final Rect dividerRect = new Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy,
        size.width,
        dividerThickness,
      );

      final Rect buttonBkRect = new Rect.fromLTWH(
        accumulatingOffset.dx,
        accumulatingOffset.dy + dividerThickness,
        size.width,
        children[i].size.height,
      );

      // If this button is pressed, then we don't want a white background to be
      // painted, so we erase this button from the background path.
      if (isButtonPressed) {
        bkFillPath.addRect(buttonBkRect);
        pressedBkFillPath.addRect(buttonBkRect);
      }

      // If this divider is needed, then we erase the divider area from the
      // background path, and on top of that we paint a translucent gray to
      // darken the divider area.
      if (dividerNeeded) {
        bkFillPath.addRect(dividerRect);
        dividersPath.addRect(dividerRect);
      }

      accumulatingOffset += dividerOffset + new Offset(0.0, children[i].size.height);
    }

    // Draw all of the button backgrounds.
    canvas.drawPath(
      bkFillPath,
      _buttonBkPaint,
    );

    // Draw the pressed button backgrounds.
    canvas.drawPath(
      pressedBkFillPath,
      _pressedButtonBkPaint,
    );

    // Draw all of the dividers.
    canvas.drawPath(
      dividersPath,
      _dividerPaint,
    );
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