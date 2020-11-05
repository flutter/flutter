import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'text_button.dart';
import 'theme.dart';

enum _TextSelectionToolbarItemPosition {
  /// The first item among multiple in the menu.
  first,

  /// One of several items, not the first or last.
  middle,

  /// The last item among multiple in the menu.
  last,

  /// The only item in the menu.
  only,
}

/// A button styled like a Material native Android text selection menu button.
class TextSelectionToolbarTextButton extends StatelessWidget {
  /// Creates an instance of TextSelectionToolbarTextButton.
  const TextSelectionToolbarTextButton({
    Key? key,
    required this.child,
    required this.index,
    this.onPressed,
    required this.total,
  }) : assert(total > 0),
       assert(index >= 0 && index < total),
       super(key: key);

  /// The child of this button.
  ///
  /// Usually a [Text].
  final Widget child;

  /// Called when this button is pressed.
  final VoidCallback? onPressed;

  /// At what index this button is in the toolbar children.
  ///
  /// This is needed becase a button may appear differently depending on where
  /// it is in the list.
  ///
  /// See also:
  ///   [total], which is the total number of children in the toolbar.
  final int index;

  /// The total number of children in the toolbar, including this one.
  ///
  /// This is needed becase a button may appear differently depending on where
  /// it is in the list.
  ///
  /// See also:
  ///   [index], which is the index among total where this button appears.
  final int total;

  // These values were eyeballed to match the native text selection menu on a
  // Pixel 2 running Android 10.
  static const double _kMiddlePadding = 9.5;
  static const double _kEndPadding = 14.5;

  static double _getLeftPadding(_TextSelectionToolbarItemPosition position) {
    if (position == _TextSelectionToolbarItemPosition.first
        || position == _TextSelectionToolbarItemPosition.only) {
      return _kEndPadding;
    }
    return _kMiddlePadding;
  }

  static double _getRightPadding(_TextSelectionToolbarItemPosition position) {
    if (position == _TextSelectionToolbarItemPosition.last
        || position == _TextSelectionToolbarItemPosition.only) {
      return _kEndPadding;
    }
    return _kMiddlePadding;
  }

  _TextSelectionToolbarItemPosition get _position {
    if (index == 0) {
      return total == 1
          ? _TextSelectionToolbarItemPosition.only
          : _TextSelectionToolbarItemPosition.first;
    }
    if (index == total - 1) {
      return _TextSelectionToolbarItemPosition.last;
    }
    return _TextSelectionToolbarItemPosition.middle;
  }

  @override
  Widget build(BuildContext context) {
    // TODO(hansmuller): Should be colorScheme.onSurface
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.colorScheme.brightness == Brightness.dark;
    final Color primary = isDark ? Colors.white : Colors.black87;

    return TextButton(
      style: TextButton.styleFrom(
        primary: primary,
        shape: const RoundedRectangleBorder(),
        minimumSize: const Size(kMinInteractiveDimension, kMinInteractiveDimension),
        padding: EdgeInsets.only(
          left: _getLeftPadding(_position),
          right: _getRightPadding(_position),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
