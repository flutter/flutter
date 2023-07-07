// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Authentication. API reference:
// https://developers.google.com/identity/gsi/web/reference/js-reference

// ignore_for_file: non_constant_identifier_names
// * non_constant_identifier_names required to be able to use the same parameter
//   names as the underlying library.

@JS()
library google_accounts_id;

import 'package:js/js.dart';

import 'shared.dart';

/// Binding to the `google.accounts.id` JS global.
///
/// See: https://developers.google.com/identity/gsi/web/reference/js-reference
@JS('google.accounts.id')
external GoogleAccountsId get id;

/// The Dart definition of the `google.accounts.id` global.
@JS()
@staticInterop
abstract class GoogleAccountsId {}

/// The `google.accounts.id` methods
extension GoogleAccountsIdExtension on GoogleAccountsId {
  /// An undocumented method.
  ///
  /// Try it with 'debug'.
  external void setLogLevel(String level);

  /// Initializes the Sign In With Google client based on [IdConfiguration].
  ///
  /// The `initialize` method creates a Sign In With Google client instance that
  /// can be implicitly used by all modules in the same web page.
  ///
  /// * You only need to call the `initialize` method once even if you use
  ///   multiple modules (like One Tap, Personalized button, revocation, etc.) in
  ///   the same web page.
  /// * If you do call the google.accounts.id.initialize method multiple times,
  ///   only the configurations in the last call will be remembered and used.
  ///
  /// You actually reset the configurations whenever you call the `initialize`
  /// method, and all subsequent methods in the same web page will use the new
  /// configurations immediately.
  ///
  /// WARNING: The `initialize` method should be called only once, even if you
  /// use both One Tap and button in the same web page.
  ///
  /// Method: google.accounts.id.initialize
  /// https://developers.google.com/identity/gsi/web/reference/js-reference#google.accounts.id.initialize
  external void initialize(IdConfiguration idConfiguration);

  /// The `prompt` method displays the One Tap prompt or the browser native
  /// credential manager after the [initialize] method is invoked.
  ///
  /// Normally, the `prompt` method is called on page load. Due to the session
  /// status and user settings on the Google side, the One Tap prompt UI might
  /// not be displayed. To get notified on the UI status for different moments,
  /// pass a [PromptMomentListenerFn] to receive UI status notifications.
  ///
  /// Notifications are fired on the following moments:
  ///
  /// * Display moment: This occurs after the `prompt` method is called. The
  ///   notification contains a boolean value to indicate whether the UI is
  ///   displayed or not.
  /// * Skipped moment: This occurs when the One Tap prompt is closed by an auto
  ///   cancel, a manual cancel, or when Google fails to issue a credential, such
  ///   as when the selected session has signed out of Google.
  ///   In these cases, we recommend that you continue on to the next identity
  ///   providers, if there are any.
  /// * Dismissed moment: This occurs when Google successfully retrieves a
  ///   credential or a user wants to stop the credential retrieval flow. For
  ///   example, when the user begins to input their username and password in
  ///   your login dialog, you can call the [cancel] method to close the One Tap
  ///   prompt and trigger a dismissed moment.
  ///
  ///   WARNING: When on a dismissed moment, do not try any of the next identity
  ///   providers.
  ///
  /// Method: google.accounts.id.prompt
  /// https://developers.google.com/identity/gsi/web/reference/js-reference#google.accounts.id.prompt
  external void prompt([PromptMomentListenerFn momentListener]);

  /// Renders a Sign In With Google button in your web page.
  ///
  /// Method: google.accounts.id.renderButton
  /// https://developers.google.com/identity/gsi/web/reference/js-reference#google.accounts.id.renderButton
  external void renderButton(
    Object parent, [
    GsiButtonConfiguration options,
  ]);

  /// Record when the user signs out of your website in cookies.
  ///
  /// This prevents a UX dead loop.
  ///
  /// Method: google.accounts.id.disableAutoselect
  /// https://developers.google.com/identity/gsi/web/reference/js-reference#google.accounts.id.disableAutoSelect
  external void disableAutoSelect();

  /// A wrapper for the `store` method of the browser's native credential manager API.
  ///
  /// It can only be used to store a Password [Credential].
  ///
  /// See: https://developer.mozilla.org/en-US/docs/Web/API/CredentialsContainer/store
  ///
  /// Method: google.accounts.id.storeCredential
  /// https://developers.google.com/identity/gsi/web/reference/js-reference#google.accounts.id.storeCredential
  external void storeCredential(Credential credential, [VoidFn fallback]);

  /// Cancels the One Tap flow.
  ///
  /// You can cancel the One Tap flow if you remove the prompt from the relying
  /// party DOM. The cancel operation is ignored if a credential is already
  /// selected.
  ///
  /// Method: google.accounts.id.cancel
  /// https://developers.google.com/identity/gsi/web/reference/js-reference#google.accounts.id.cancel
  external void cancel();

  /// Revokes the OAuth grant used to share the ID token for the specified user.
  ///
  /// [hint] is the email address or unique ID of the user's Google Account. The
  /// ID is the `sub` property of the [CredentialResponse.credential] payload.
  ///
  /// The optional [callback] is a function that gets called to report on the
  /// success of the revocation call.
  ///
  /// The [callback] parameter must be manually wrapped in [allowInterop]
  /// before being passed to the [revoke] function.
  ///
  /// Method: google.accounts.id.revoke
  /// https://developers.google.com/identity/gsi/web/reference/js-reference#google.accounts.id.revoke
  external void revoke(String hint, [RevocationResponseHandlerFn callback]);
}

/// The configuration object for the [initialize] method.
///
/// Data type: IdConfiguration
/// https://developers.google.com/identity/gsi/web/reference/js-reference#IdConfiguration
@JS()
@anonymous
@staticInterop
abstract class IdConfiguration {
  /// Constructs a IdConfiguration object in JavaScript.
  ///
  /// The following properties need to be manually wrapped in [allowInterop]
  /// before being passed to this constructor: [callback], [native_callback],
  /// and [intermediate_iframe_close_callback].
  external factory IdConfiguration({
    /// Your application's client ID, which is found and created in the Google
    /// Developers Console.
    required String client_id,

    /// Determines if an ID token is automatically returned without any user
    /// interaction when there's only one Google session that has approved your
    /// app before. The default value is `false`.
    bool? auto_select,

    /// The function that handles the ID token returned from the One Tap prompt
    /// or the pop-up window. This attribute is required if Google One Tap or
    /// the Sign In With Google button `popup` UX mode is used.
    CallbackFn? callback,

    /// This attribute is the URI of your login endpoint. May be omitted if the
    /// current page is your login page, in which case the credential is posted
    /// to this page by default.
    ///
    /// The ID token credential response is posted to your login endpoint when
    /// a user clicks on the Sign In With Google button and `redirect` UX mode
    /// is used.
    ///
    /// Your login endpoint must handle POST requests containing a credential
    /// key with an ID token value in the body.
    Uri? login_uri,

    /// The function that handles the password credential returned from the
    /// browser's native credential manager.
    NativeCallbackFn? native_callback,

    /// Whether or not to cancel the One Tap request if a user clicks outside
    /// the prompt. The default value is `true`.
    bool? cancel_on_tap_outside,

    /// The DOM ID of the container element. If it's not set, the One Tap prompt
    /// is displayed in the top-right corner of the window.
    String? prompt_parent_id,

    /// A random string used by the ID token to prevent replay attacks.
    ///
    /// Nonce length is limited to the maximum JWT size supported by your
    /// environment, and individual browser and server HTTP size constraints.
    String? nonce,

    /// Changes the text of the title and messages in the One Tap prompt.
    OneTapContext? context,

    /// If you need to display One Tap in the parent domain and its subdomains,
    /// pass the parent domain to this field so that a single shared-state
    /// cookie is used.
    ///
    /// See: https://developers.google.com/identity/gsi/web/guides/subdomains
    String? state_cookie_domain,

    /// Set the UX flow used by the Sign In With Google button. The default
    /// value is `popup`. **This attribute has no impact on the OneTap UX.**
    UxMode? ux_mode,

    /// The origins that are allowed to embed the intermediate iframe. One Tap
    /// will run in the intermediate iframe mode if this field presents.
    ///
    /// Wildcard prefixes are also supported. Wildcard domains must begin with
    /// a secure `https://` scheme, otherwise they'll be considered invalid.
    List<String>? allowed_parent_origin,

    /// Overrides the default intermediate iframe behavior when users manually
    /// close One Tap by tapping on the 'X' button in the One Tap UI. The
    /// default behavior is to remove the intermediate iframe from the DOM
    /// immediately.
    ///
    /// The `intermediate_iframe_close_callback` field takes effect only in
    /// intermediate iframe mode. And it has impact only to the intermediate
    /// iframe, instead of the One Tap iframe. The One Tap UI is removed before
    /// the callback is invoked.
    Function? intermediate_iframe_close_callback,

    /// determines if the upgraded One Tap UX should be enabled on browsers
    /// that support Intelligent Tracking Prevention (ITP). The default value
    /// is false.
    ///
    /// See: https://developers.google.com/identity/gsi/web/guides/features#upgraded_ux_on_itp_browsers
    bool? itp_support,
  });
}

/// The type of the function that can be passed to [prompt] to listen for [PromptMomentNotification]s.
typedef PromptMomentListenerFn = void Function(PromptMomentNotification moment);

/// A moment (status) notification from the [prompt] method.
///
/// Data type: PromptMomentNotification
/// https://developers.google.com/identity/gsi/web/reference/js-reference#PromptMomentNotification
@JS()
@staticInterop
abstract class PromptMomentNotification {}

/// The methods of the [PromptMomentNotification] data type:
extension PromptMomentNotificationExtension on PromptMomentNotification {
  /// Is this notification for a display moment?
  external bool isDisplayMoment();

  /// Is this notification for a display moment, and the UI is displayed?
  external bool isDisplayed();

  /// Is this notification for a display moment, and the UI isn't displayed?
  external bool isNotDisplayed();

  /// Is this notification for a skipped moment?
  external bool isSkippedMoment();

  /// Is this notification for a dismissed moment?
  external bool isDismissedMoment();
  @JS('getMomentType')
  external String _getMomentType();
  @JS('getNotDisplayedReason')
  external String? _getNotDisplayedReason();
  @JS('getSkippedReason')
  external String? _getSkippedReason();
  @JS('getDismissedReason')
  external String? _getDismissedReason();

  /// The moment type.
  MomentType getMomentType() => MomentType.values.byName(_getMomentType());

  /// The detailed reason why the UI isn't displayed.
  MomentNotDisplayedReason? getNotDisplayedReason() =>
      maybeEnum(_getNotDisplayedReason(), MomentNotDisplayedReason.values);

  /// The detailed reason for the skipped moment.
  MomentSkippedReason? getSkippedReason() =>
      maybeEnum(_getSkippedReason(), MomentSkippedReason.values);

  /// The detailed reason for the dismissal.
  MomentDismissedReason? getDismissedReason() =>
      maybeEnum(_getDismissedReason(), MomentDismissedReason.values);
}

/// The object passed as the parameter of your [CallbackFn].
///
/// Data type: CredentialResponse
/// https://developers.google.com/identity/gsi/web/reference/js-reference#CredentialResponse
@JS()
@staticInterop
abstract class CredentialResponse {}

/// The fields that are contained in the credential response object.
extension CredentialResponseExtension on CredentialResponse {
  /// The ClientID for this Credential.
  external String? get client_id;

  /// Error while signing in.
  external String? get error;

  /// Details of the error while signing in.
  external String? get error_detail;

  /// This field is the ID token as a base64-encoded JSON Web Token (JWT)
  /// string.
  ///
  /// See more: https://developers.google.com/identity/gsi/web/reference/js-reference#credential
  external String? get credential;
  @JS('select_by')
  external String? get _select_by;

  /// This field sets how the credential was selected.
  ///
  /// The type of button used along with the session and consent state are used
  /// to set the value.
  ///
  /// See more: https://developers.google.com/identity/gsi/web/reference/js-reference#select_by
  CredentialSelectBy? get select_by =>
      maybeEnum(_select_by, CredentialSelectBy.values);
}

/// The type of the `callback` used to create an [IdConfiguration].
///
/// Describes a JavaScript function that handles ID tokens from
/// [CredentialResponse]s.
///
/// Google One Tap and the Sign In With Google button popup UX mode use this
/// attribute.
typedef CallbackFn = void Function(CredentialResponse credentialResponse);

/// The configuration object for the [renderButton] method.
///
/// Data type: GsiButtonConfiguration
/// https://developers.google.com/identity/gsi/web/reference/js-reference#GsiButtonConfiguration
@JS()
@anonymous
@staticInterop
abstract class GsiButtonConfiguration {
  /// Constructs an options object for the [renderButton] method.
  ///
  /// The following properties need to be manually wrapped in [allowInterop]
  /// before being passed to this constructor:
  external factory GsiButtonConfiguration({
    /// The button type.
    ButtonType type,

    /// The button theme.
    ButtonTheme theme,

    /// The button size.
    ButtonSize size,

    /// The button text.
    ButtonText text,

    /// The button shape.
    ButtonShape shape,

    /// The Google logo alignment in the button.
    ButtonLogoAlignment logo_alignment,

    /// The minimum button width, in pixels.
    ///
    /// The maximum width is 400 pixels.
    double width,

    /// The pre-set locale of the button text.
    ///
    /// If not set, the browser's default locale or the Google session user's
    /// preference is used.
    String locale,

    /// A function to be called when the button is clicked.
    GsiButtonClickListenerFn click_listener,
  });
}

/// The object passed as an optional parameter to `click_listener` function.
@JS()
@staticInterop
abstract class GsiButtonData {}

/// The fields that are contained in the button data.
extension GsiButtonDataExtension on GsiButtonData {
  /// Nonce
  external String? get nonce;

  /// State
  external String? get state;
}

/// The type of the [GsiButtonConfiguration] `click_listener` function.
typedef GsiButtonClickListenerFn = void Function(GsiButtonData? gsiButtonData);

/// The object passed to the [NativeCallbackFn]. Represents a PasswordCredential
/// that was returned by the Browser.
///
/// `Credential` objects can also be programmatically created to be stored
/// in the browser through the [storeCredential] method.
///
/// See also: https://developer.mozilla.org/en-US/docs/Web/API/PasswordCredential/PasswordCredential
///
/// Data type: Credential
/// https://developers.google.com/identity/gsi/web/reference/js-reference#type-Credential
@JS()
@anonymous
@staticInterop
abstract class Credential {
  ///
  external factory Credential({
    required String id,
    required String password,
  });
}

/// The fields that are contained in the [Credential] object.
extension CredentialExtension on Credential {
  /// Identifies the user.
  external String get id;

  /// The password.
  external String get password;
}

/// The type of the `native_callback` used to create an [IdConfiguration].
///
/// Describes a JavaScript function that handles password [Credential]s coming
/// from the native Credential manager of the user's browser.
typedef NativeCallbackFn = void Function(Credential credential);

/*
// Library load callback: onGoogleLibraryLoad
// https://developers.google.com/identity/gsi/web/reference/js-reference#onGoogleLibraryLoad
// See: `load_callback.dart` and `loader.dart`
*/

/// The type of the `callback` function passed to [revoke], to be notified of
/// the success of the revocation operation.
typedef RevocationResponseHandlerFn = void Function(
  RevocationResponse revocationResponse,
);

/// The parameter passed to the `callback` of the [revoke] function.
///
/// Data type: RevocationResponse
/// https://developers.google.com/identity/gsi/web/reference/js-reference#RevocationResponse
@JS()
@staticInterop
abstract class RevocationResponse {}

/// The fields that are contained in the [RevocationResponse] object.
extension RevocationResponseExtension on RevocationResponse {
  /// This field is a boolean value set to true if the revoke method call
  /// succeeded or false on failure.
  external bool get successful;

  /// This field is a string value and contains a detailed error message if the
  /// revoke method call failed, it is undefined on success.
  external String? get error;
}
