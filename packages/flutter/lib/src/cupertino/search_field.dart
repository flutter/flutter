// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icons.dart';
import 'text_field.dart';

/// A [CupertinoTextField] that mimics the look and behavior of UIKit's
/// `UISearchTextField`.
///
/// This control defaults to showing the basic parts of a `UISearchTextField`,
/// like the 'Search' placeholder, prefix-ed Search icon, and suffix-ed
/// X-Mark icon.
///
/// To control the text that is displayed in the text field, use the
/// [controller]. For example, to set the initial value of the text field, use
/// a [controller] that already contains some text such as:
///
/// {@tool snippet}
///
/// ```dart
/// class MyPrefilledSearch extends StatefulWidget {
///   @override
///   _MyPrefilledSearchState createState() => _MyPrefilledSearchState();
/// }
///
/// class _MyPrefilledSearchState extends State<MyPrefilledSearch> {
///   TextEditingController _textController;
///
///   @override
///   void initState() {
///     super.initState();
///     _textController = TextEditingController(text: 'initial text');
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return CupertinoSearchTextField(controller: _textController);
///   }
/// }
/// ```
/// {@end-tool}
///
/// It is recommended to pass a [ValueChanged<String>] to both [onChanged] and
/// [onSubmitted] parameters in order to be notified once the value of the
/// field changes or is submitted by the keyboard:
///
/// /// {@tool snippet}
///
/// ```dart
///
///   @override
///   Widget build(BuildContext context) {
///     return CupertinoSearchTextField(
///       onChanged: (value) {
///         print("The text has changed to: " + value);
///       },
///       onSubmitted: (value) {
///         print("Submitted text: " + value);
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
class CupertinoSearchTextField extends StatefulWidget {
  /// Creates a [CupertinoTextField] that mimicks the look and behavior of UIKit's
  /// `UISearchTextField`.
  ///
  /// Similar to [CupertinoTextField], to provide a prefilled text entry, pass
  /// in a [TextEditingController] with an initial value to the [controller]
  /// parameter.
  ///
  /// The [onChanged] parameter takes a [ValueChanged<String>] which is invoked
  /// upon a change in the text field's value.
  ///
  /// The [onSubmitted] parameter takes a [ValueChanged<String>] which is invoked
  /// when the keyboard submits.
  ///
  /// To provide a hint placeholder text that appears when the text entry is
  /// empty, pass a [String] to the [placeholder] parameter. This defaults to
  /// 'Search'.
  // TODO(DanielEdrisian): Localize the 'Search' placeholder.
  ///
  /// The [style] and [placeholderStyle] properties allow changing the style of
  /// the text and placeholder of the textfield. [placeholderStyle] defaults
  /// to the gray [CupertinoColors.secondaryLabel] iOS color.
  ///
  /// To set the text field's background color and border radius, pass a
  /// [BoxDecoration] to the [decoration] parameter. This defaults to the
  /// default translucent tertiarySystemFill iOS color and 9 px corner radius.
  // TODO(DanielEdrisian): Must make border radius continuous, see
  // https://github.com/flutter/flutter/issues/13914.
  ///
  /// The [itemColor] and [itemSize] properties allow changing the icon color
  /// and icon size of the search icon (prefix) and X-Mark (suffix).
  /// They default to [CupertinoColors.secondaryLabel] and [20.0].
  ///
  /// The [padding], [prefixInsets], and [suffixInsets] let you set the padding
  /// insets for text, the search icon (prefix), and the X-Mark icon (suffix).
  /// They default to values that replicate the `UISearchTextField` look. These
  /// default fields were determined using the comparison tool in
  /// https://github.com/flutter/platform_tests/.
  ///
  /// To customize the suffix icon, pass an [Icon] to [suffixIcon]. This
  /// defaults to the X-Mark.
  ///
  /// To dictate when the X-Mark (suffix) should be visible, a.k.a. only on when
  /// editing, not editing, on always, or on never, pass a
  /// [OverlayVisibilityMode] to [suffixMode]. This defaults to only on when
  /// editing.
  ///
  /// To customize the X-Mark (suffix) action, pass a [VoidCallback] to
  /// [onSuffixTap]. This defaults to clearing the text.
  const CupertinoSearchTextField({
    Key? key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.placeholder = 'Search',
    this.placeholderStyle,
    this.decoration,
    this.backgroundColor = CupertinoColors.tertiarySystemFill,
    this.borderRadius = const BorderRadius.all(Radius.circular(9.0)),
    this.padding = const EdgeInsets.fromLTRB(3.8, 8, 5, 8),
    this.itemColor = CupertinoColors.secondaryLabel,
    this.itemSize = 20.0,
    this.prefixInsets = const EdgeInsets.fromLTRB(6, 0, 0, 4),
    this.suffixInsets = const EdgeInsets.fromLTRB(0, 0, 5, 2),
    this.suffixIcon = const Icon(CupertinoIcons.xmark_circle_fill),
    this.suffixMode = OverlayVisibilityMode.editing,
    this.onSuffixTap,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CupertinoSearchTextFieldState();

  /// Similar to [CupertinoTextField], to provide a prefilled text entry, pass
  /// in a [TextEditingController] with an initial value to the [controller]
  /// parameter.
  final TextEditingController? controller;

  /// The [onChanged] parameter takes a [ValueChanged<String>] which is invoked
  /// upon a change in the text field's value.
  final ValueChanged<String>? onChanged;

  /// The [onSubmitted] parameter takes a [ValueChanged<String>] which is invoked
  /// when the keyboard submits.
  final ValueChanged<String>? onSubmitted;

  /// The [style] property allows changing the style of the text. Defaults
  /// to the gray [CupertinoColors.secondaryLabel] iOS color.
  final TextStyle? style;

  /// The [placeholder] parameter lets you provide a hint placeholder text that
  /// appears when the text entry is empty. This defaults to 'Search'.
  // TODO(DanielEdrisian): Localize the 'Search' placeholder.
  final String? placeholder;

  /// The [placeholderStyle] property allows changing the style of the
  /// placeholder of the textfield. Defaults to the gray
  /// [CupertinoColors.secondaryLabel] iOS color.
  final TextStyle? placeholderStyle;

  /// The [decoration] property lets you set the decoration for the text field.
  /// This property is automatically set using the [backgroundColor] and
  /// [borderRadius] properties, which both have default values. Therefore,
  /// [decoration] has a default value upon building the widget. It is designed
  /// to mimic the look of a `UISearchTextField`.
  final BoxDecoration? decoration;

  /// The [backgroundColor] property lets you set the [decoration] property's
  /// background color. Defaults to the translucent
  /// [CupertinoColors.tertiarySystemFill] iOS color.
  final Color? backgroundColor;

  /// The [borderRadius] property lets you set the [decoration] property's
  /// border radius. Defaults to 9 px circular corner radius.
  // TODO(DanielEdrisian): Must make border radius continuous, see
  // https://github.com/flutter/flutter/issues/13914.
  final BorderRadius borderRadius;

  /// The [padding] property lets you set the padding insets for the text and
  /// placeholder. Defaults to padding that replicates the `UISearchTextField`
  /// look. The inset values were determined using the comparison tool in
  /// https://github.com/flutter/platform_tests/.
  final EdgeInsets padding;
  final Color? itemColor;
  final double itemSize;

  /// The [prefixInsets] property lets you set the padding insets for the
  /// suffix. Defaults to padding that replicates the `UISearchTextField` suffix
  /// look. The inset values were determined using the comparison tool in
  /// https://github.com/flutter/platform_tests/.
  final EdgeInsets prefixInsets;

  /// The [suffixInsets] property lets you set the padding insets for the
  /// prefix. Defaults to padding that replicates the `UISearchTextField` prefix
  /// look. The inset values were determined using the comparison tool in
  /// https://github.com/flutter/platform_tests/.
  final EdgeInsets suffixInsets;

  /// The [suffixIcon] property sets the suffix widget's icon. Defaults to
  /// the X-Mark [CupertinoIcons.xmark_circle_fill]. The suffix is customizable
  /// so that users can override it with other options, like a bookmark icon.
  final Icon suffixIcon;

  /// The [suffixMode] property dictates when the X-Mark (suffix) should be
  /// visible, a.k.a. only on when editing, not editing, on always, or on never.
  /// This defaults to only on when editing.
  final OverlayVisibilityMode suffixMode;

  /// The [onSuffixTap] property lets you customize the X-Mark (suffix) action.
  /// This defaults to clearing the text. The suffix action is customizable
  /// so that users can override it with other functionality, that isn't
  /// necessarily clearing text.
  final VoidCallback? onSuffixTap;
}

class _CupertinoSearchTextFieldState extends State<CupertinoSearchTextField> {
  @override
  Widget build(BuildContext context) {
    // The icon size will be scaled by a factor of the accessibility text scale,
    // to follow the behavior of `UISearchTextField`.
    final double scaledIconSize =
        MediaQuery.textScaleFactorOf(context) * widget.itemSize;

    // If decoration was not provided, create a decoration with the provided
    // background color and border radius (which both have default values).
    final BoxDecoration decoration = widget.decoration ??
        BoxDecoration(
          color: CupertinoDynamicColor.resolve(widget.backgroundColor, context),
          borderRadius: widget.borderRadius,
        );

    final TextStyle placeholderStyle = widget.placeholderStyle ??
        TextStyle(
          color: CupertinoDynamicColor.resolve(
              CupertinoColors.secondaryLabel, context),
        );

    final Color? itemColor =
        CupertinoDynamicColor.resolve(widget.itemColor, context);

    final IconThemeData iconThemeData =
        IconThemeData(color: itemColor, size: scaledIconSize);

    final Widget prefix = Padding(
      child: IconTheme(
          child: const Icon(CupertinoIcons.search), data: iconThemeData),
      padding: widget.prefixInsets,
    );

    // TODO(DanielEdrisian): Replace [GestureDetector] with a [CupertinoButton].
    // The reason why I went with [GestureDetector] was because
    // [CupertinoButton] was messing with the content size of the entire
    // search field. Must find a way to get it working with a button, so that
    // touch-down has that fading effect.
    final Widget suffix = Padding(
      child: GestureDetector(
        child: IconTheme(child: widget.suffixIcon, data: iconThemeData),
        onTap: widget.onSuffixTap ??
            () {
              widget.controller!.text = '';
              if (widget.onChanged != null) {
                widget.onChanged!('');
              }
            },
      ),
      padding: widget.suffixInsets,
    );

    return CupertinoTextField(
      controller: widget.controller,
      decoration: decoration,
      style: widget.style,
      prefix: prefix,
      suffix: suffix,
      suffixMode: widget.suffixMode,
      placeholder: widget.placeholder,
      placeholderStyle: placeholderStyle,
      padding: widget.padding,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
