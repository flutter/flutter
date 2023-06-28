// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'debug.dart';
import 'localizations.dart';

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const CupertinoDynamicColor _kToolbarBackgroundColor = CupertinoDynamicColor.withBrightness(
  // This value was extracted from a screenshot of iOS 16.0.3, as light mode
  // didn't appear in the Apple design resources assets linked above.
  color: Color(0xEBF7F7F7),
  darkColor: Color(0xEB202020),
);

const CupertinoDynamicColor _kToolbarTextColor = CupertinoDynamicColor.withBrightness(
  color: CupertinoColors.black,
  darkColor: CupertinoColors.white,
);

// Eyeballed value.
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0);

/// A button in the style of the iOS text selection toolbar buttons.
class CupertinoTextSelectionToolbarButton extends StatelessWidget {
  /// Create an instance of [CupertinoTextSelectionToolbarButton].
  ///
  /// [child] cannot be null.
  const CupertinoTextSelectionToolbarButton({
    super.key,
    this.onPressed,
    required Widget this.child,
  }) : text = null,
       buttonItem = null;

  /// Create an instance of [CupertinoTextSelectionToolbarButton] whose child is
  /// a [Text] widget styled like the default iOS text selection toolbar button.
  const CupertinoTextSelectionToolbarButton.text({
    super.key,
    this.onPressed,
    required this.text,
  }) : buttonItem = null,
       child = null;

  /// Create an instance of [CupertinoTextSelectionToolbarButton] from the given
  /// [ContextMenuButtonItem].
  ///
  /// [buttonItem] cannot be null.
  CupertinoTextSelectionToolbarButton.buttonItem({
    super.key,
    required ContextMenuButtonItem this.buttonItem,
  }) : child = null,
       text = null,
       onPressed = buttonItem.onPressed;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.child}
  /// The child of this button.
  ///
  /// Usually a [Text] or an [Icon].
  /// {@endtemplate}
  final Widget? child;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.onPressed}
  /// Called when this button is pressed.
  /// {@endtemplate}
  final VoidCallback? onPressed;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.onPressed}
  /// The buttonItem used to generate the button when using
  /// [CupertinoTextSelectionToolbarButton.buttonItem].
  /// {@endtemplate}
  final ContextMenuButtonItem? buttonItem;

  /// {@template flutter.cupertino.CupertinoTextSelectionToolbarButton.text}
  /// The text used in the button's label when using
  /// [CupertinoTextSelectionToolbarButton.text].
  /// {@endtemplate}
  final String? text;

  /// Returns the default button label String for the button of the given
  /// [ContextMenuButtonItem]'s [ContextMenuButtonType].
  static String getButtonLabel(BuildContext context, ContextMenuButtonItem buttonItem) {
    if (buttonItem.label != null) {
      return buttonItem.label!;
    }

    assert(debugCheckHasCupertinoLocalizations(context));
    final CupertinoLocalizations localizations = CupertinoLocalizations.of(context);
    switch (buttonItem.type) {
      case ContextMenuButtonType.cut:
        return localizations.cutButtonLabel;
      case ContextMenuButtonType.copy:
        return localizations.copyButtonLabel;
      case ContextMenuButtonType.paste:
        return localizations.pasteButtonLabel;
      case ContextMenuButtonType.selectAll:
        return localizations.selectAllButtonLabel;
      case ContextMenuButtonType.liveTextInput:
      case ContextMenuButtonType.delete:
      case ContextMenuButtonType.custom:
        return '';
    }
  }

  Widget? _getButtonWidget(BuildContext context) {
    if (buttonItem == null) {
      return null;
    }
    final Widget result;
    switch (buttonItem!.type) {
      case ContextMenuButtonType.cut:
      case ContextMenuButtonType.copy:
      case ContextMenuButtonType.paste:
      case ContextMenuButtonType.selectAll:
      case ContextMenuButtonType.delete:
      case ContextMenuButtonType.custom:
        return null;
      case ContextMenuButtonType.liveTextInput:
        result = SizedBox(
          width: 13,
          height: 13,
          child: CustomPaint(
            painter: _LiveTextIconPainter(color: _kToolbarTextColor.resolveFrom(context)),
          ),
        );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (this.child != null) {
      child = this.child!;
    } else {
      // If this button has a specific widget, only show widget instead of a text label.
      final Widget? widget = _getButtonWidget(context);
      if (widget == null) {
        child = Text(
          text ?? getButtonLabel(context, buttonItem!),
          overflow: TextOverflow.ellipsis,
          style: _kToolbarButtonFontStyle.copyWith(
            color: onPressed != null
                ? _kToolbarTextColor.resolveFrom(context)
                : CupertinoColors.inactiveGray,
          ),
        );
      } else {
        child = widget;
      }
    }

    return CupertinoButton(
      borderRadius: null,
      color: _kToolbarBackgroundColor,
      disabledColor: _kToolbarBackgroundColor,
      onPressed: onPressed,
      padding: _kToolbarButtonPadding,
      pressedOpacity: onPressed == null ? 1.0 : 0.7,
      child: child,
    );
  }
}

class _LiveTextIconPainter extends CustomPainter {
  _LiveTextIconPainter({required this.color});

  final Color color;

  final Paint _painter = Paint()
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    _painter.color = color;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    final Offset origin = Offset(-size.width / 2.0, -size.height / 2.0);
    // Path for the one corner.
    final Path path = Path()
      ..moveTo(origin.dx, origin.dy + 3.5)
      ..lineTo(origin.dx, origin.dy + 1)
      ..arcToPoint(Offset(origin.dx + 1, origin.dy), radius: const Radius.circular(1))
      ..lineTo(origin.dx + 3.5, origin.dy);

    // Rotate to draw corner four times.
    final Matrix4 rotationMatrix = Matrix4.identity()..rotateZ(pi / 2);
    for (int i = 0; i < 4; i += 1) {
      canvas.drawPath(path, _painter);
      canvas.transform(rotationMatrix.storage);
    }

    // Draw three lines.
    canvas.drawLine(const Offset(-3, -3), const Offset(3, -3), _painter);
    canvas.drawLine(const Offset(-3, 0), const Offset(3, 0), _painter);
    canvas.drawLine(const Offset(-3, 3), const Offset(1, 3), _painter);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiveTextIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
