// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Attempts to retrieve an enum value from [haystack] if [needle] is not null.
T? maybeEnum<T extends Enum>(String? needle, List<T> haystack) {
  if (needle == null) {
    return null;
  }
  return haystack.byName(needle);
}

/// The type of several functions from the library, that don't receive
/// parameters nor return anything.
typedef VoidFn = void Function();

/*
// Enum: UX Mode
// https://developers.google.com/identity/gsi/web/reference/js-reference#ux_mode
// Used both by `oauth2.initCodeClient` and `id.initialize`.
*/

/// Use this enum to set the UX flow used by the Sign In With Google button.
/// The default value is [popup].
///
/// This attribute has no impact on the OneTap UX.
enum UxMode {
  /// Performs sign-in UX flow in a pop-up window.
  popup('popup'),

  /// Performs sign-in UX flow by a full page redirection.
  redirect('redirect');

  ///
  const UxMode(String uxMode) : _uxMode = uxMode;
  final String _uxMode;

  @override
  String toString() => _uxMode;
}

/// Changes the text of the title and messages in the One Tap prompt.
enum OneTapContext {
  /// "Sign in with Google"
  signin('signin'),

  /// "Sign up with Google"
  signup('signup'),

  /// "Use with Google"
  use('use');

  ///
  const OneTapContext(String context) : _context = context;
  final String _context;

  @override
  String toString() => _context;
}

/// The detailed reason why the OneTap UI isn't displayed.
enum MomentNotDisplayedReason {
  /// Browser not supported.
  ///
  /// See https://developers.google.com/identity/gsi/web/guides/supported-browsers
  browser_not_supported('browser_not_supported'),

  /// Invalid Client.
  ///
  /// See https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid
  invalid_client('invalid_client'),

  /// Missing client_id.
  ///
  /// See https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid
  missing_client_id('missing_client_id'),

  /// The user has opted out, or they aren't signed in to a Google account.
  ///
  /// https://developers.google.com/identity/gsi/web/guides/features
  opt_out_or_no_session('opt_out_or_no_session'),

  /// Google One Tap can only be displayed in HTTPS domains.
  ///
  /// See https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid
  secure_http_required('secure_http_required'),

  /// The user has previously closed the OneTap card.
  ///
  /// See https://developers.google.com/identity/gsi/web/guides/features#exponential_cooldown
  suppressed_by_user('suppressed_by_user'),

  /// The current `origin` is not associated with the Client ID.
  ///
  /// See https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid
  unregistered_origin('unregistered_origin'),

  /// Unknown reason
  unknown_reason('unknown_reason');

  ///
  const MomentNotDisplayedReason(String reason) : _reason = reason;
  final String _reason;

  @override
  String toString() => _reason;
}

/// The detailed reason for the skipped moment.
enum MomentSkippedReason {
  /// auto_cancel
  auto_cancel('auto_cancel'),

  /// user_cancel
  user_cancel('user_cancel'),

  /// tap_outside
  tap_outside('tap_outside'),

  /// issuing_failed
  issuing_failed('issuing_failed');

  ///
  const MomentSkippedReason(String reason) : _reason = reason;
  final String _reason;

  @override
  String toString() => _reason;
}

/// The detailed reason for the dismissal.
enum MomentDismissedReason {
  /// credential_returned
  credential_returned('credential_returned'),

  /// cancel_called
  cancel_called('cancel_called'),

  /// flow_restarted
  flow_restarted('flow_restarted');

  ///
  const MomentDismissedReason(String reason) : _reason = reason;
  final String _reason;

  @override
  String toString() => _reason;
}

/// The moment type.
enum MomentType {
  /// Display moment
  display('display'),

  /// Skipped moment
  skipped('skipped'),

  /// Dismissed moment
  dismissed('dismissed');

  ///
  const MomentType(String type) : _type = type;
  final String _type;

  @override
  String toString() => _type;
}

/// Represents how a credential was selected.
enum CredentialSelectBy {
  /// Automatic sign-in of a user with an existing session who had previously
  /// granted consent to share credentials.
  auto('auto'),

  /// A user with an existing session who had previously granted consent
  /// pressed the One Tap 'Continue as' button to share credentials.
  user('user'),

  /// A user with an existing session pressed the One Tap 'Continue as' button
  /// to grant consent and share credentials. Applies only to Chrome v75 and
  /// higher.
  user_1tap('user_1tap'),

  /// A user without an existing session pressed the One Tap 'Continue as'
  /// button to select an account and then pressed the Confirm button in a
  /// pop-up window to grant consent and share credentials. Applies to
  /// non-Chromium based browsers.
  user_2tap('user_2tap'),

  /// A user with an existing session who previously granted consent pressed
  /// the Sign In With Google button and selected a Google Account from
  /// 'Choose an Account' to share credentials.
  btn('btn'),

  /// A user with an existing session pressed the Sign In With Google button
  /// and pressed the Confirm button to grant consent and share credentials.
  btn_confirm('btn_confirm'),

  /// A user without an existing session who previously granted consent
  /// pressed the Sign In With Google button to select a Google Account and
  /// share credentials.
  btn_add_session('btn_add_session'),

  /// A user without an existing session first pressed the Sign In With Google
  /// button to select a Google Account and then pressed the Confirm button to
  /// consent and share credentials.
  btn_confirm_add_session('btn_confirm_add_session');

  ///
  const CredentialSelectBy(String selectBy) : _selectBy = selectBy;
  final String _selectBy;

  @override
  String toString() => _selectBy;
}

/// The type of button to be rendered.
///
/// https://developers.google.com/identity/gsi/web/reference/js-reference#type
enum ButtonType {
  /// A button with text or personalized information.
  standard('standard'),

  /// An icon button without text.
  icon('icon');

  ///
  const ButtonType(String type) : _type = type;
  final String _type;

  @override
  String toString() => _type;
}

/// The theme of the button to be rendered.
///
/// https://developers.google.com/identity/gsi/web/reference/js-reference#theme
enum ButtonTheme {
  /// A standard button theme.
  outline('outline'),

  /// A blue-filled button theme.
  filled_blue('filled_blue'),

  /// A black-filled button theme.
  filled_black('filled_black');

  ///
  const ButtonTheme(String theme) : _theme = theme;
  final String _theme;

  @override
  String toString() => _theme;
}

/// The theme of the button to be rendered.
///
/// https://developers.google.com/identity/gsi/web/reference/js-reference#size
enum ButtonSize {
  /// A large button (about 40px tall).
  large('large'),

  /// A medium-sized button (about 32px tall).
  medium('medium'),

  /// A small button (about 20px tall).
  small('small');

  ///
  const ButtonSize(String size) : _size = size;
  final String _size;

  @override
  String toString() => _size;
}

/// The button text.
///
/// https://developers.google.com/identity/gsi/web/reference/js-reference#text
enum ButtonText {
  /// The button text is "Sign in with Google".
  signin_with('signin_with'),

  /// The button text is "Sign up with Google".
  signup_with('signup_with'),

  /// The button text is "Continue with Google".
  continue_with('continue_with'),

  /// The button text is "Sign in".
  signin('signin');

  ///
  const ButtonText(String text) : _text = text;
  final String _text;

  @override
  String toString() => _text;
}

/// The button shape.
///
/// https://developers.google.com/identity/gsi/web/reference/js-reference#shape
enum ButtonShape {
  /// The rectangular-shaped button.
  ///
  /// If used for the [ButtonType.icon], then it's the same as [square].
  rectangular('rectangular'),

  /// The pill-shaped button.
  ///
  /// If used for the [ButtonType.icon], then it's the same as [circle].
  pill('pill'),

  /// The circle-shaped button.
  ///
  /// If used for the [ButtonType.standard], then it's the same as [pill].
  circle('circle'),

  /// The square-shaped button.
  ///
  /// If used for the [ButtonType.standard], then it's the same as [rectangular].
  square('square');

  ///
  const ButtonShape(String shape) : _shape = shape;
  final String _shape;

  @override
  String toString() => _shape;
}

/// The type of button to be rendered.
///
/// https://developers.google.com/identity/gsi/web/reference/js-reference#type
enum ButtonLogoAlignment {
  /// Left-aligns the Google logo.
  left('left'),

  /// Center-aligns the Google logo.
  center('center');

  ///
  const ButtonLogoAlignment(String alignment) : _alignment = alignment;
  final String _alignment;

  @override
  String toString() => _alignment;
}

/// The `type` of the error object passed into the `error_callback` function.
enum GoogleIdentityServicesErrorType {
  /// Missing required parameter.
  missing_required_parameter('missing_required_parameter'),

  /// The popup was closed before the flow was completed.
  popup_closed('popup_closed'),

  /// Popup failed to open.
  popup_failed_to_open('popup_failed_to_open'),

  /// Unknown error.
  unknown('unknown');

  ///
  const GoogleIdentityServicesErrorType(String type) : _type = type;
  final String _type;

  @override
  String toString() => _type;
}
