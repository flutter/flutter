// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Authorization. API reference:
// https://developers.google.com/identity/oauth2/web/reference/js-reference

// ignore_for_file: non_constant_identifier_names
// * non_constant_identifier_names required to be able to use the same parameter
//   names as the underlying library.

@JS()
library google_accounts_oauth2;

import 'package:js/js.dart';

import 'dom.dart';
import 'shared.dart';

/// Binding to the `google.accounts.oauth2` JS global.
///
/// See: https://developers.google.com/identity/oauth2/web/reference/js-reference
@JS('google.accounts.oauth2')
external GoogleAccountsOauth2 get oauth2;

/// The Dart definition of the `google.accounts.oauth2` global.
@JS()
@staticInterop
abstract class GoogleAccountsOauth2 {}

/// The `google.accounts.oauth2` methods
extension GoogleAccountsOauth2Extension on GoogleAccountsOauth2 {
  /// Initializes and returns a code client, with the passed-in [config].
  ///
  /// Method: google.accounts.oauth2.initCodeClient
  /// https://developers.google.com/identity/oauth2/web/reference/js-reference#google.accounts.oauth2.initCodeClient
  external CodeClient initCodeClient(CodeClientConfig config);

  /// Initializes and returns a token client, with the passed-in [config].
  ///
  /// Method: google.accounts.oauth2.initTokenClient
  /// https://developers.google.com/identity/oauth2/web/reference/js-reference#google.accounts.oauth2.initTokenClient
  external TokenClient initTokenClient(TokenClientConfig config);

  // Method: google.accounts.oauth2.hasGrantedAllScopes
  // https://developers.google.com/identity/oauth2/web/reference/js-reference#google.accounts.oauth2.hasGrantedAllScopes
  @JS('hasGrantedAllScopes')
  external bool _hasGrantedScope(TokenResponse token, String scope);

  /// Checks if hte user has granted **all** the specified [scopes].
  ///
  /// [scopes] is a space-separated list of scope names.
  ///
  /// Method: google.accounts.oauth2.hasGrantedAllScopes
  /// https://developers.google.com/identity/oauth2/web/reference/js-reference#google.accounts.oauth2.hasGrantedAllScopes
  bool hasGrantedAllScopes(TokenResponse tokenResponse, List<String> scopes) {
    return scopes
        .every((String scope) => _hasGrantedScope(tokenResponse, scope));
  }

  /// Checks if hte user has granted **all** the specified [scopes].
  ///
  /// [scopes] is a space-separated list of scope names.
  ///
  /// Method: google.accounts.oauth2.hasGrantedAllScopes
  /// https://developers.google.com/identity/oauth2/web/reference/js-reference#google.accounts.oauth2.hasGrantedAllScopes
  bool hasGrantedAnyScopes(TokenResponse tokenResponse, List<String> scopes) {
    return scopes.any((String scope) => _hasGrantedScope(tokenResponse, scope));
  }

  /// Revokes all of the scopes that the user granted to the app.
  ///
  /// A valid [accessToken] is required to revoke permissions.
  ///
  /// The [done] callback is called once the revoke action is done. It must be
  /// manually wrapped in [allowInterop] before being passed to this method.
  ///
  /// Method: google.accounts.oauth2.revoke
  /// https://developers.google.com/identity/oauth2/web/reference/js-reference#google.accounts.oauth2.revoke
  external void revoke(
    String accessToken, [
    RevokeTokenDoneFn done,
  ]);
}

/// The configuration object for the [initCodeClient] method.
///
/// Data type: CodeClientConfig
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#CodeClientConfig
@JS()
@anonymous
@staticInterop
abstract class CodeClientConfig {
  /// Constructs a CodeClientConfig object in JavaScript.
  ///
  /// The [callback] property must be wrapped in [allowInterop] before it's
  /// passed to this constructor.
  external factory CodeClientConfig({
    required String client_id,
    required String scope,
    String? redirect_uri,
    bool? auto_select,
    CodeClientCallbackFn? callback,
    ErrorCallbackFn? error_callback,
    String? state,
    bool? enable_serial_consent,
    String? hint,
    String? hosted_domain,
    UxMode? ux_mode,
    bool? select_account,
  });
}

/// A client that can start the OAuth 2.0 Code UX flow.
///
/// See: https://developers.google.com/identity/oauth2/web/guides/use-code-model
///
/// Data type: CodeClient
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#CodeClient
@JS()
@staticInterop
abstract class CodeClient {}

/// The methods available on the [CodeClient].
extension CodeClientExtension on CodeClient {
  /// Starts the OAuth 2.0 Code UX flow.
  external void requestCode();
}

/// The object passed as the parameter of your [CodeClientCallbackFn].
///
/// Data type: CodeResponse
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#CodeResponse
@JS()
@staticInterop
abstract class CodeResponse {}

/// The fields that are contained in the code response object.
extension CodeResponseExtension on CodeResponse {
  /// The authorization code of a successful token response.
  external String get code;

  /// A space-delimited list of scopes that are approved by the user.
  external String get scope;

  /// The string value that your application uses to maintain state between your
  /// authorization request and the response.
  external String get state;

  /// A single ASCII error code.
  external String? get error;

  /// Human-readable ASCII text providing additional information, used to assist
  /// the client developer in understanding the error that occurred.
  external String? get error_description;

  /// A URI identifying a human-readable web page with information about the
  /// error, used to provide the client developer with additional information
  /// about the error.
  external String? get error_uri;
}

/// The type of the `callback` function passed to [CodeClientConfig].
typedef CodeClientCallbackFn = void Function(CodeResponse response);

/// The configuration object for the [initTokenClient] method.
///
/// Data type: TokenClientConfig
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#TokenClientConfig
@JS()
@anonymous
@staticInterop
abstract class TokenClientConfig {
  /// Constructs a TokenClientConfig object in JavaScript.
  ///
  /// The [callback] property must be wrapped in [allowInterop] before it's
  /// passed to this constructor.
  external factory TokenClientConfig({
    required String client_id,
    required TokenClientCallbackFn? callback,
    required String scope,
    ErrorCallbackFn? error_callback,
    String? prompt,
    bool? enable_serial_consent,
    String? hint,
    String? hosted_domain,
    String? state,
  });
}

/// A client that can start the OAuth 2.0 Token UX flow.
///
/// See: https://developers.google.com/identity/oauth2/web/guides/use-token-model
///
/// Data type: TokenClient
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#TokenClient
@JS()
@staticInterop
abstract class TokenClient {}

/// The methods available on the [TokenClient].
extension TokenClientExtension on TokenClient {
  /// Starts the OAuth 2.0 Code UX flow.
  external void requestAccessToken([
    OverridableTokenClientConfig overrideConfig,
  ]);
}

/// The overridable configuration object for the [TokenClientExtension.requestAccessToken] method.
///
/// Data type: OverridableTokenClientConfig
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#OverridableTokenClientConfig
@JS()
@anonymous
@staticInterop
abstract class OverridableTokenClientConfig {
  /// Constructs an OverridableTokenClientConfig object in JavaScript.
  ///
  /// The [callback] property must be wrapped in [allowInterop] before it's
  /// passed to this constructor.
  external factory OverridableTokenClientConfig({
    /// A space-delimited, case-sensitive list of prompts to present the user.
    ///
    /// See `prompt` in [TokenClientConfig].
    String? prompt,

    /// For clients created before 2019, when set to `false`, disables "more
    /// granular Google Account permissions".
    ///
    /// This setting has no effect in newer clients.
    ///
    /// See: https://developers.googleblog.com/2018/10/more-granular-google-account.html
    bool? enable_serial_consent,

    /// When your app knows which user it is trying to authenticate, it can
    /// provide this parameter as a hint to the authentication server. Passing
    /// this hint suppresses the account chooser and either pre-fills the email
    /// box on the sign-in form, or selects the proper session (if the user is
    /// using multiple sign-in), which can help you avoid problems that occur if
    /// your app logs in the wrong user account.
    ///
    /// The value can be either an email address or the `sub` string, which is
    /// equivalent to the user's Google ID.
    ///
    /// About Multiple Sign-in: https://support.google.com/accounts/answer/1721977
    String? hint,

    /// A space-delimited list of scopes that identify the resources that your
    /// application could access on the user's behalf. These values inform the
    /// consent screen that Google displays to the user.
    // b/251971390
    String? scope,

    /// **Not recommended.** Specifies any string value that your application
    /// uses to maintain state between your authorization request and the
    /// authorization server's response.
    String? state,

    /// Preserves previously requested scopes in this new request.
    ///
    /// (Undocumented)
    bool? include_granted_scopes,
  });
}

/// The object passed as the parameter of your [TokenClientCallbackFn].
///
/// Data type: TokenResponse
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#TokenResponse
@JS()
@staticInterop
abstract class TokenResponse {}

/// The fields that are contained in the code response object.
extension TokenResponseExtension on TokenResponse {
  /// The access token of a successful token response.
  external String get access_token;

  /// The lifetime in seconds of the access token.
  external int get expires_in;

  /// The hosted domain the signed-in user belongs to.
  external String get hd;

  /// The prompt value that was used from the possible list of values specified
  /// by [TokenClientConfig] or [OverridableTokenClientConfig].
  external String get prompt;

  /// The type of the token issued.
  external String get token_type;

  /// A space-delimited list of scopes that are approved by the user.
  external String get scope;

  /// The string value that your application uses to maintain state between your
  /// authorization request and the response.
  external String get state;

  /// A single ASCII error code.
  external String? get error;

  /// Human-readable ASCII text providing additional information, used to assist
  /// the client developer in understanding the error that occurred.
  external String? get error_description;

  /// A URI identifying a human-readable web page with information about the
  /// error, used to provide the client developer with additional information
  /// about the error.
  external String? get error_uri;
}

/// The type of the `callback` function passed to [TokenClientConfig].
typedef TokenClientCallbackFn = void Function(TokenResponse response);

/// The type of the `error_callback` in both oauth2 initXClient calls.
///
/// (Currently undocumented)
///
/// `error` should be of type [GoogleIdentityServicesError]?, but it cannot be
/// because of this DDC bug: https://github.com/dart-lang/sdk/issues/50899
typedef ErrorCallbackFn = void Function(Object? error);

/// An error returned by `initTokenClient` or `initDataClient`.
///
/// Cannot be used: https://github.com/dart-lang/sdk/issues/50899
@JS()
@staticInterop
abstract class GoogleIdentityServicesError extends DomError {}

/// Methods of the GoogleIdentityServicesError object.
///
/// Cannot be used: https://github.com/dart-lang/sdk/issues/50899
extension GoogleIdentityServicesErrorExtension on GoogleIdentityServicesError {
  @JS('type')
  external String get _type;
  // String get _type => js_util.getProperty<String>(this, 'type');

  /// The type of error
  GoogleIdentityServicesErrorType get type =>
      GoogleIdentityServicesErrorType.values.byName(_type);
}

/// The signature of the `done` function for [revoke].
typedef RevokeTokenDoneFn = void Function(TokenRevocationResponse response);

/// The parameter passed to the `callback` of the [revoke] function.
///
/// Data type: RevocationResponse
/// https://developers.google.com/identity/oauth2/web/reference/js-reference#TokenResponse
@JS()
@staticInterop
abstract class TokenRevocationResponse {}

/// The fields that are contained in the [TokenRevocationResponse] object.
extension TokenRevocationResponseExtension on TokenRevocationResponse {
  /// This field is a boolean value set to true if the revoke method call
  /// succeeded or false on failure.
  external bool get successful;

  /// This field is a string value and contains a detailed error message if the
  /// revoke method call failed, it is undefined on success.
  external String? get error;

  /// The description of the error.
  external String? get error_description;
}
