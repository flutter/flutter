import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';

// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const Color _kToolbarButtonBackgroundColor = Color(0xFF2D2E31);

// These values were measured from a screenshot of TextEdit on MacOS 10.15.7 on
// a Macbook Pro.
const Color _kToolbarButtonBackgroundColorActive = Color(0xFF0662CD);
const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
  color: CupertinoColors.white,
);

// This value was measured from a screenshot of TextEdit on MacOS 10.15.7 on a
// Macbook Pro.
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(
  vertical: 1.0,
  horizontal: 20.0,
);

/// A button in the style of the Mac context menu buttons.
class CupertinoDesktopTextSelectionToolbarButton extends StatefulWidget {
  /// Creates an instance of CupertinoDesktopTextSelectionToolbarButton.
  const CupertinoDesktopTextSelectionToolbarButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  /// Create an instance of [CupertinoDesktopTextSelectionToolbarButton] whose child is
  /// a [Text] widget styled like the default Mac context menu button.
  CupertinoDesktopTextSelectionToolbarButton.text({
    Key? key,
    required this.onPressed,
    required String text,
  }) : child = Text(
         text,
         overflow: TextOverflow.ellipsis,
         style: _kToolbarButtonFontStyle,
       ),
       super(key: key);

  /// {@macro flutter.cupertino.CupertinoTextSelectionToolbarButton.onPressed}
  final VoidCallback onPressed;

  /// {@macro flutter.cupertino.CupertinoTextSelectionToolbarButton.child}
  final Widget child;

  @override
  _CupertinoDesktopTextSelectionToolbarButtonState createState() => _CupertinoDesktopTextSelectionToolbarButtonState();
}

class _CupertinoDesktopTextSelectionToolbarButtonState extends State<CupertinoDesktopTextSelectionToolbarButton> {
  bool _isHovered = false;

  void _onEnter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        child: CupertinoButton(
          // TODO(justinmc): alignment: Alignment.centerLeft,
          borderRadius: null,
          color: _isHovered ? _kToolbarButtonBackgroundColorActive : _kToolbarButtonBackgroundColor,
          minSize: 0.0,
          onPressed: widget.onPressed,
          padding: _kToolbarButtonPadding,
          pressedOpacity: 0.7,
          child: widget.child,
        ),
      ),
    );
  }
}
