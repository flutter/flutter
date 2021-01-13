import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';

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

// TODO(justinmc): Deduplicate this with desktop_text_selection.dart.
const Color _kToolbarBackgroundColor = Color(0xFF2D2E31);

class CupertinoDesktopButton extends StatefulWidget {
  const CupertinoDesktopButton({
    Key? key,
    required this.padding,
    required this.onPressed,
    required this.text,
  }) : super(key: key);

  final VoidCallback onPressed;

  final EdgeInsetsGeometry padding;

  final String text;

  @override
  _CupertinoDesktopButtonState createState() => _CupertinoDesktopButtonState();
}

class _CupertinoDesktopButtonState extends State<CupertinoDesktopButton> {
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
          borderRadius: null,
          color: _isHovered ? _kToolbarButtonBackgroundColorActive : _kToolbarBackgroundColor,
          minSize: 0.0,
          onPressed: widget.onPressed,
          padding: widget.padding,
          pressedOpacity: 0.7,
          child: Text(
            // TODO(justinmc): Remove this 'Desktop' text, just using it to
            // distinguish iOS and Desktop TSM right now.
            // Eventually, make this look like real desktop while reusing
            // duplicate stuff with iOS and Material.
            widget.text,
            overflow: TextOverflow.ellipsis,
            style: _kToolbarButtonFontStyle,
          ),
        ),
      ),
    );
  }
}

