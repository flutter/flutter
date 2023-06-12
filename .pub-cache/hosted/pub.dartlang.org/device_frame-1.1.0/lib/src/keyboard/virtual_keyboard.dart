import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';

/// Display a simulated on screen keyboard at the bottom of a [child] widget.
///
/// When [isEnabled] is updated, a [transitionDuration] starts to display
/// or hide the virtual keyboard.
///
/// No interraction is available, its only purpose is to display
/// the visual and update media query's `viewInsets` for [child].
class VirtualKeyboard extends StatelessWidget {
  /// Display a simulated on screen keyboard on top of the given [child] widget.
  ///
  /// When [isEnabled] is updated, a [transitionDuration] starts to display
  /// or hide the virtual keyboard.
  ///
  /// No interraction is available, its only purpose is to display
  /// the visual and update media query's `viewInsets` for [child].
  const VirtualKeyboard({
    Key? key,
    required this.child,
    this.isEnabled = false,
    this.transitionDuration = const Duration(milliseconds: 400),
  }) : super(key: key);

  /// Adds the keyboard insets to the given [mediaQuery].
  static MediaQueryData mediaQuery(MediaQueryData mediaQuery) {
    final insets = EdgeInsets.only(
      bottom: _VirtualKeyboard.minHeight + mediaQuery.padding.bottom,
    );
    return mediaQuery.copyWith(
      viewInsets: insets,
      viewPadding: mediaQuery.viewPadding,
      padding: mediaQuery.padding.copyWith(
        bottom: 0,
      ),
    );
  }

  /// Indicates whether the keyboard is displayed or not.
  final bool isEnabled;

  /// The widget on top of which the keyboard is displayed.
  final Widget child;

  /// The transition duration when the keyboard is displayed or hidden.
  final Duration transitionDuration;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: MediaQuery(
            data: !isEnabled
                ? mediaQuery
                : VirtualKeyboard.mediaQuery(mediaQuery),
            child: child,
          ),
        ),
        Positioned(
          bottom: -1,
          left: -1,
          right: -1,
          child: AnimatedCrossFade(
            firstChild: const SizedBox(),
            secondChild: const _VirtualKeyboard(
              height: _VirtualKeyboard.minHeight,
            ),
            crossFadeState: isEnabled
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: transitionDuration,
          ),
        ),
      ],
    );
  }
}

class _VirtualKeyboard extends StatelessWidget {
  const _VirtualKeyboard({
    double? height,
    this.spacing = 12,
  }) : height = height ?? minHeight;

  static const double minHeight = 214;
  final double height;
  final double spacing;

  Widget _row(List<Widget> children) {
    return Padding(
      padding: EdgeInsets.only(
        top: spacing,
        left: spacing,
      ),
      child: Row(
        children: children,
      ),
    );
  }

  List<Widget> _letters(
    List<String> letters,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return letters
        .map<Widget>(
          (x) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: spacing,
              ),
              child: VirtualKeyboardButton(
                backgroundColor: backgroundColor,
                child: Text(
                  x,
                  style: TextStyle(
                    fontSize: 14,
                    color: foregroundColor,
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = DeviceFrameTheme.of(context).keyboardStyle;
    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: height + mediaQuery.padding.bottom,
      padding: EdgeInsets.only(
        left: mediaQuery.padding.left + 1,
        right: mediaQuery.padding.right + 1,
      ),
      color: theme.backgroundColor,
      child: Column(
        children: <Widget>[
          _row(
            _letters(
              ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
              theme.button1BackgroundColor,
              theme.button1ForegroundColor,
            ),
          ),
          _row(
            _letters(
              ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
              theme.button1BackgroundColor,
              theme.button1ForegroundColor,
            ),
          ),
          _row([
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: VirtualKeyboardButton(
                child: Icon(
                  Icons.keyboard_capslock,
                  color: theme.button2ForegroundColor,
                  size: 16,
                ),
                backgroundColor: theme.button2BackgroundColor,
              ),
            ),
            ..._letters(
              ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
              theme.button1BackgroundColor,
              theme.button1ForegroundColor,
            ),
            Padding(
              padding: EdgeInsets.only(
                right: spacing,
              ),
              child: VirtualKeyboardButton(
                child: Icon(
                  Icons.backspace,
                  color: theme.button2ForegroundColor,
                  size: 16,
                ),
                backgroundColor: theme.button2BackgroundColor,
              ),
            ),
          ]),
          _row(
            [
              Padding(
                padding: EdgeInsets.only(
                  right: spacing,
                ),
                child: VirtualKeyboardButton(
                  child: Text(
                    '123',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.button2ForegroundColor,
                    ),
                  ),
                  backgroundColor: theme.button2BackgroundColor,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: spacing,
                ),
                child: VirtualKeyboardButton(
                  child: Icon(
                    Icons.insert_emoticon,
                    color: theme.button2ForegroundColor,
                    size: 16,
                  ),
                  backgroundColor: theme.button2BackgroundColor,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: spacing,
                  ),
                  child: VirtualKeyboardButton(
                    child: Text(
                      'space',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.button2ForegroundColor,
                      ),
                    ),
                    backgroundColor: theme.button2BackgroundColor,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  right: spacing,
                ),
                child: VirtualKeyboardButton(
                  child: Text(
                    'return',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.button2ForegroundColor,
                    ),
                  ),
                  backgroundColor: theme.button2BackgroundColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
