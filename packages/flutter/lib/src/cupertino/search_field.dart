// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

// This is a light gray color used for UISearchTextField's background.
const Color _kDefaultBackgroundColor = Color.fromRGBO(239, 239, 240, 1.0);

// This is approximately the corner radius used in UISearchTextField.
// Note that UISearchTextField uses continuous corners, as opposed to circular.
const BorderRadius _kDefaultBorderRadius =
    BorderRadius.all(Radius.circular(9.0));

// This is a dark gray color used for UISearchTextField's tint color.
const Color _kDefaultItemColor = Color.fromRGBO(132, 132, 136, 1.0);

// This is a dark gray color used for UISearchTextField's placeholder color.
const TextStyle _kDefaultPlaceholderStyle =
    TextStyle(color: Color.fromRGBO(142, 142, 147, 1.0));

// These are insets used to mimick UISearchTextField's search icon placement.
const EdgeInsets _kDefaultPrefixInsets = EdgeInsets.fromLTRB(6, 0, 0, 4);

// These are insets used to mimick UISearchTextField's X-Mark icon placement.
const EdgeInsets _kDefaultSuffixInsets = EdgeInsets.fromLTRB(0, 0, 5, 2);

// These are insets used to mimick UISearchTextField's text placement.
const EdgeInsets _kDefaultContentPadding = EdgeInsets.fromLTRB(3.8, 8, 5, 8);

// The suffix mode determines whether the X-Mark appears during editing.
const OverlayVisibilityMode _kDefaultSuffixMode = OverlayVisibilityMode.editing;

// This is a decoration that uses the default background color and border radius
const BoxDecoration _kDefaultBoxDecoration = BoxDecoration(
  color: _kDefaultBackgroundColor,
  borderRadius: _kDefaultBorderRadius,
);

// The default placeholder seen in UISearchTextField.
const String _kDefaultPlaceholder = 'Search';

// This returns the icon sizes, which scales with the accessibility font size.
double _scaledIconSize(BuildContext context) {
  return MediaQuery.textScaleFactorOf(context) * 20.0;
}

// Creates the search icon which is used as a prefix.
Widget _defaultPrefix(Color itemColor) {
  return Builder(
    builder: (BuildContext context) => Icon(
      CupertinoIcons.search,
      color: itemColor,
      size: _scaledIconSize(context),
    ),
  );
}

// Creates the X-Mark icon which is used as a suffix. It accepts a tap action.
Widget _defaultSuffix(Color itemColor, Function() onTap) {
  return Builder(
    builder: (BuildContext context) => GestureDetector(
      child: Icon(
        CupertinoIcons.xmark_circle_fill,
        color: itemColor,
        size: _scaledIconSize(context),
      ),
      onTap: onTap,
    ),
  );
}

/// A [CupertinoTextField] that mimicks the look and behavior of UIKit's
/// [UISearchTextField].
class CupertinoSearchTextField extends CupertinoTextField {
  ///
  /// Creates a [CupertinoTextField] that mimicks the look and behavior of UIKit's
  /// [UISearchTextField].
  ///
  /// Similar to [CupertinoTextField], to provide a prefilled text entry, pass
  /// in a [TextEditingController] with an initial value to the [controller]
  /// parameter. The [controller] property must not be null.
  ///
  /// The [onChanged] parameter takes a [Function(String)] which is invoked
  /// upon a change in the text field's value.
  ///
  /// The [onSubmitted] parameter takes a [Function(String)] which is invoked
  /// when the keyboard submits.
  ///
  /// To provide a hint placeholder text that appears when the text entry is
  /// empty, pass a [String] to the [placeholder] parameter. This defaults to
  /// 'Search'.
  ///
  /// To set the placeholder color and style, pass a [TextStyle] to the
  /// [placeholderStyle] parameter. This defaults to the default gray iOS color.
  ///
  /// To set the text field's background color and border radius, pass a
  /// [BoxDecoration] to the [decoration] parameter. This defaults to the
  /// default gray iOS background color and 9 px corner radius.
  ///
  /// To set the text field's text padding, pass an [EdgeInsets] to the
  /// [padding] parameter. This defaults to the default iOS padding.
  ///
  /// To set the icon colors for the search icon (prefix) and X-Mark (suffix),
  /// pass a [Color] to the [itemColor] parameter. This defaults to the dark
  /// gray iOS color.
  ///
  /// To set the padding insets for the search icon (prefix), pass an
  /// [EdgeInsets] to the [prefixInsets] parameter. This defaults to the default
  /// iOS insets.
  ///
  /// To set the padding insets for the X-Mark icon (suffix), pass an
  /// [EdgeInsets] to the [suffixInsets] parameter. This defaults to the default
  /// iOS insets.
  ///
  /// To dictate when the X-Mark (suffix) should be on, a.k.a. only on when
  /// editing, not editing, on always, or on never, pass a
  /// [OverlayVisibilityMode] to [suffixMode]. This defaults to only on when
  /// editing.
  ///
  /// To customize the X-Mark (suffix) action, pass a [Function()] to [onSuffixTap].
  /// This defaults to clearing the text.
  ///
  CupertinoSearchTextField({
    TextEditingController? controller,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    String placeholder = _kDefaultPlaceholder,
    TextStyle placeholderStyle = _kDefaultPlaceholderStyle,
    BoxDecoration? decoration = _kDefaultBoxDecoration,
    Color backgroundColor = _kDefaultBackgroundColor,
    BorderRadius borderRadius = _kDefaultBorderRadius,
    EdgeInsets padding = _kDefaultContentPadding,
    Color itemColor = _kDefaultItemColor,
    EdgeInsets prefixInsets = _kDefaultPrefixInsets,
    EdgeInsets suffixInsets = _kDefaultSuffixInsets,
    OverlayVisibilityMode suffixMode = _kDefaultSuffixMode,
    Function()? onSuffixTap,
  })  : assert(controller != null),
        super(
          controller: controller,
          // If backgroundColor or borderRadius have been passed as params,
          // make a new BoxDecoration. Otherwise, use default.
          decoration: (backgroundColor != null || borderRadius != null)
              ? BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius,
                )
              : (decoration ?? _kDefaultBoxDecoration),
          // This is the search icon widget.
          prefix: Padding(
            child: _defaultPrefix(itemColor),
            padding: prefixInsets,
          ),
          // This is the X-Mark widget. If onTap has been passed as a param,
          // use it as the X-Mark's tapping action. Otherwise, default to
          // clearing the text.
          suffix: Padding(
            child: _defaultSuffix(
                itemColor,
                onSuffixTap ??
                    () {
                      controller!.text = '';
                    }),
            padding: suffixInsets,
          ),
          suffixMode: suffixMode,
          placeholder: placeholder,
          placeholderStyle: placeholderStyle,
          padding: padding,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        );
}
