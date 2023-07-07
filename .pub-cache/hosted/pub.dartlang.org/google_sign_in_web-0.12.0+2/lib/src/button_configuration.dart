// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_identity_services_web/id.dart' as id;
import 'package:js/js_util.dart' as js_util;

/// Converts user-facing `GisButtonConfiguration` into the JS-Interop `id.GsiButtonConfiguration`.
id.GsiButtonConfiguration? convertButtonConfiguration(
  GSIButtonConfiguration? config,
) {
  if (config == null) {
    return null;
  }
  return js_util.jsify(<String, Object?>{
    if (config.type != null) 'type': _idType[config.type],
    if (config.theme != null) 'theme': _idTheme[config.theme],
    if (config.size != null) 'size': _idSize[config.size],
    if (config.text != null) 'text': _idText[config.text],
    if (config.shape != null) 'shape': _idShape[config.shape],
    if (config.logoAlignment != null)
      'logo_alignment': _idLogoAlignment[config.logoAlignment],
    if (config.minimumWidth != null) 'width': config.minimumWidth,
    if (config.locale != null) 'locale': config.locale,
  }) as id.GsiButtonConfiguration;
}

/// A class to configure the Google Sign-In Button for web.
///
/// See:
/// * https://developers.google.com/identity/gsi/web/reference/js-reference#GsiButtonConfiguration
class GSIButtonConfiguration {
  /// Constructs a button configuration object.
  GSIButtonConfiguration({
    this.type,
    this.theme,
    this.size,
    this.text,
    this.shape,
    this.logoAlignment,
    this.minimumWidth,
    this.locale,
  }) : assert(minimumWidth == null || minimumWidth > 0);

  /// The button type: icon, or standard button.
  final GSIButtonType? type;

  /// The button theme.
  ///
  /// For example, filledBlue or filledBlack.
  final GSIButtonTheme? theme;

  /// The button size.
  ///
  /// For example, small or large.
  final GSIButtonSize? size;

  /// The button text.
  ///
  /// For example "Sign in with Google" or "Sign up with Google".
  final GSIButtonText? text;

  /// The button shape.
  ///
  /// For example, rectangular or circular.
  final GSIButtonShape? shape;

  /// The Google logo alignment: left or center.
  final GSIButtonLogoAlignment? logoAlignment;

  /// The minimum button width, in pixels.
  ///
  /// The maximum width is 400 pixels.
  final double? minimumWidth;

  /// The pre-set locale of the button text.
  ///
  /// If not set, the browser's default locale or the Google session user's
  /// preference is used.
  ///
  /// Different users might see different versions of localized buttons, possibly
  /// with different sizes.
  final String? locale;
}

/// The type of button to be rendered.
///
/// See:
/// * https://developers.google.com/identity/gsi/web/reference/js-reference#type
enum GSIButtonType {
  /// A button with text or personalized information.
  standard,

  /// An icon button without text.
  icon;
}

const Map<GSIButtonType, id.ButtonType> _idType =
    <GSIButtonType, id.ButtonType>{
  GSIButtonType.icon: id.ButtonType.icon,
  GSIButtonType.standard: id.ButtonType.standard,
};

/// The theme of the button to be rendered.
///
/// See:
/// * https://developers.google.com/identity/gsi/web/reference/js-reference#theme
enum GSIButtonTheme {
  /// A standard button theme.
  outline,

  /// A blue-filled button theme.
  filledBlue,

  /// A black-filled button theme.
  filledBlack;
}

const Map<GSIButtonTheme, id.ButtonTheme> _idTheme =
    <GSIButtonTheme, id.ButtonTheme>{
  GSIButtonTheme.outline: id.ButtonTheme.outline,
  GSIButtonTheme.filledBlue: id.ButtonTheme.filled_blue,
  GSIButtonTheme.filledBlack: id.ButtonTheme.filled_black,
};

/// The size of the button to be rendered.
///
/// See:
/// * https://developers.google.com/identity/gsi/web/reference/js-reference#size
enum GSIButtonSize {
  /// A large button (about 40px tall).
  large,

  /// A medium-sized button (about 32px tall).
  medium,

  /// A small button (about 20px tall).
  small;
}

const Map<GSIButtonSize, id.ButtonSize> _idSize =
    <GSIButtonSize, id.ButtonSize>{
  GSIButtonSize.large: id.ButtonSize.large,
  GSIButtonSize.medium: id.ButtonSize.medium,
  GSIButtonSize.small: id.ButtonSize.small,
};

/// The button text.
///
/// See:
/// * https://developers.google.com/identity/gsi/web/reference/js-reference#text
enum GSIButtonText {
  /// The button text is "Sign in with Google".
  signinWith,

  /// The button text is "Sign up with Google".
  signupWith,

  /// The button text is "Continue with Google".
  continueWith,

  /// The button text is "Sign in".
  signin;
}

const Map<GSIButtonText, id.ButtonText> _idText =
    <GSIButtonText, id.ButtonText>{
  GSIButtonText.signinWith: id.ButtonText.signin_with,
  GSIButtonText.signupWith: id.ButtonText.signup_with,
  GSIButtonText.continueWith: id.ButtonText.continue_with,
  GSIButtonText.signin: id.ButtonText.signin,
};

/// The button shape.
///
/// See:
/// * https://developers.google.com/identity/gsi/web/reference/js-reference#shape
enum GSIButtonShape {
  /// The rectangular-shaped button.
  rectangular,

  /// The circle-shaped button.
  pill;
  // Does this need circle and square?
}

const Map<GSIButtonShape, id.ButtonShape> _idShape =
    <GSIButtonShape, id.ButtonShape>{
  GSIButtonShape.rectangular: id.ButtonShape.rectangular,
  GSIButtonShape.pill: id.ButtonShape.pill,
};

/// The alignment of the Google logo. The default value is left. This attribute only applies to the standard button type.
///
/// See:
/// * https://developers.google.com/identity/gsi/web/reference/js-reference#logo_alignment
enum GSIButtonLogoAlignment {
  /// Left-aligns the Google logo.
  left,

  /// Center-aligns the Google logo.
  center;
}

const Map<GSIButtonLogoAlignment, id.ButtonLogoAlignment> _idLogoAlignment =
    <GSIButtonLogoAlignment, id.ButtonLogoAlignment>{
  GSIButtonLogoAlignment.left: id.ButtonLogoAlignment.left,
  GSIButtonLogoAlignment.center: id.ButtonLogoAlignment.center,
};
