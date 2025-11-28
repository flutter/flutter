// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../semantics.dart';
import 'colors.dart';
import 'constants.dart';
import 'context_menu.dart';
import 'theme.dart';

/// A button in a _ContextMenuSheet.
///
/// A typical use case is to pass a [Text] as the [child] here, but be sure to
/// use [TextOverflow.ellipsis] for the [Text.overflow] field if the text may be
/// long, as without it the text will wrap to the next line.
class CupertinoContextMenuAction extends StatefulWidget {
  /// Construct a CupertinoContextMenuAction.
  const CupertinoContextMenuAction({
    super.key,
    required this.child,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.onPressed,
    this.trailingIcon,
    this.focusNode,
    this.focusColor,
  });

  /// The widget that will be placed inside the action.
  final Widget child;

  /// Indicates whether this action should receive the style of an emphasized,
  /// default action.
  final bool isDefaultAction;

  /// Indicates whether this action should receive the style of a destructive
  /// action.
  final bool isDestructiveAction;

  /// Called when the action is pressed.
  final VoidCallback? onPressed;

  /// An optional icon to display to the right of the child.
  ///
  /// Will be colored in the same way as the [TextStyle] used for [child] (for
  /// example, if using [isDestructiveAction]).
  final IconData? trailingIcon;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The color of the background that highlights active focus.
  ///
  /// A transparency of [kCupertinoButtonTintedOpacityLight] (light mode) or
  /// [kCupertinoButtonTintedOpacityDark] (dark mode) is automatically applied to this color.
  ///
  /// When [focusColor] is null, defaults to [CupertinoColors.activeBlue].
  final Color? focusColor;

  @override
  State<CupertinoContextMenuAction> createState() => _CupertinoContextMenuActionState();
}

class _CupertinoContextMenuActionState extends State<CupertinoContextMenuAction> {
  static const Color _kBackgroundColorPressed = CupertinoDynamicColor.withBrightness(
    color: Color(0xFFDDDDDD),
    darkColor: Color(0xFF3F3F40),
  );
  static const double _kButtonHeight = 43;
  static const TextStyle _kActionSheetActionStyle = TextStyle(
    fontFamily: 'CupertinoSystemText',
    inherit: false,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: CupertinoColors.black,
    textBaseline: TextBaseline.alphabetic,
  );

  final GlobalKey _globalKey = GlobalKey();
  bool _isPressed = false;
  bool _isFocused = false;

  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _handleTap),
  };

  bool get enabled => widget.onPressed != null;

  void _handleTap([Intent? _]) {
    if (widget.onPressed case final VoidCallback onPressed?) {
      onPressed();
      context.findRenderObject()!.sendSemanticsEvent(const TapSemanticEvent());
    }
  }

  void _onShowFocusHighlight(bool showHighlight) {
    setState(() {
      _isFocused = showHighlight;
    });
  }

  void onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  void onTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  TextStyle get _textStyle {
    if (widget.isDefaultAction) {
      return _kActionSheetActionStyle.copyWith(
        color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
        fontWeight: FontWeight.w600,
      );
    }
    if (widget.isDestructiveAction) {
      return _kActionSheetActionStyle.copyWith(color: CupertinoColors.destructiveRed);
    }
    return _kActionSheetActionStyle.copyWith(
      color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
    );
  }

  Color get effectiveFocusBackgroundColor =>
      (widget.focusColor ?? CupertinoColors.activeBlue).withValues(
        alpha: CupertinoTheme.brightnessOf(context) == Brightness.light
            ? kCupertinoButtonTintedOpacityLight
            : kCupertinoButtonTintedOpacityDark,
      );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled && kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        key: _globalKey,
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _kButtonHeight),
          child: FocusableActionDetector(
            actions: _actionMap,
            focusNode: widget.focusNode,
            enabled: enabled,
            onShowFocusHighlight: _onShowFocusHighlight,
            child: Semantics(
              button: true,
              child: ColoredBox(
                color: switch ((pressed: _isPressed, focused: _isFocused)) {
                  (pressed: true, focused: _) => CupertinoDynamicColor.resolve(
                    _kBackgroundColorPressed,
                    context,
                  ),
                  (pressed: _, focused: true) => effectiveFocusBackgroundColor,
                  _ => CupertinoDynamicColor.resolve(
                    CupertinoContextMenu.kBackgroundColor,
                    context,
                  ),
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15.5, 8.0, 17.5, 8.0),
                  child: DefaultTextStyle(
                    style: _textStyle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(child: widget.child),
                        if (widget.trailingIcon != null)
                          Icon(widget.trailingIcon, color: _textStyle.color, size: 21.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
