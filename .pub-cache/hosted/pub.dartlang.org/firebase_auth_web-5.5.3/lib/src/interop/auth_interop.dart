// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: avoid_unused_constructor_parameters, non_constant_identifier_names, comment_references
// ignore_for_file: public_member_api_docs

@JS('firebase_auth')
library firebase_interop.auth;

import 'package:firebase_auth_web/src/interop/auth.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart';
import 'package:js/js.dart';

@JS()
external AuthJsImpl getAuth([AppJsImpl? app]);

@JS()
external AuthJsImpl initializeAuth(AppJsImpl app, dynamic debugErrorMap);

@JS('debugErrorMap')
external Map get debugErrorMap;

@JS()
external PromiseJsImpl<void> applyActionCode(AuthJsImpl auth, String oobCode);

@JS()
external Persistence inMemoryPersistence;
@JS()
external Persistence browserSessionPersistence;
@JS()
external Persistence browserLocalPersistence;
@JS()
external Persistence indexedDBLocalPersistence;

@JS()
external PromiseJsImpl<ActionCodeInfo> checkActionCode(
    AuthJsImpl auth, String oobCode);

@JS()
external PromiseJsImpl<void> confirmPasswordReset(
  AuthJsImpl auth,
  String oobCode,
  String newPassword,
);

@JS()
external void connectAuthEmulator(
  AuthJsImpl auth,
  String origin,
);

@JS()
external PromiseJsImpl<void> setPersistence(
    AuthJsImpl auth, Persistence persistence);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> createUserWithEmailAndPassword(
  AuthJsImpl auth,
  String email,
  String password,
);

@JS()
external AdditionalUserInfoJsImpl getAdditionalUserInfo(
    UserCredentialJsImpl userCredential);

@JS()
external PromiseJsImpl<void> deleteUser(
  UserJsImpl user,
);

@JS()
external PromiseJsImpl<List> fetchSignInMethodsForEmail(
    AuthJsImpl auth, String email);

@JS()
external bool isSignInWithEmailLink(String emailLink);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> getRedirectResult(AuthJsImpl auth);

@JS()
external PromiseJsImpl<void> sendSignInLinkToEmail(
  AuthJsImpl auth,
  String email, [
  ActionCodeSettings? actionCodeSettings,
]);

@JS()
external PromiseJsImpl<void> sendPasswordResetEmail(
  AuthJsImpl auth,
  String email, [
  ActionCodeSettings? actionCodeSettings,
]);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> signInWithCredential(
  AuthJsImpl auth,
  OAuthCredential credential,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> signInAnonymously(AuthJsImpl auth);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> signInWithCustomToken(
  AuthJsImpl auth,
  String token,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> signInWithEmailAndPassword(
  AuthJsImpl auth,
  String email,
  String password,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> signInWithEmailLink(
  AuthJsImpl auth,
  String email,
  String emailLink,
);

@JS()
external PromiseJsImpl<ConfirmationResultJsImpl> signInWithPhoneNumber(
  AuthJsImpl auth,
  String phoneNumber,
  ApplicationVerifierJsImpl applicationVerifier,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> signInWithPopup(
  AuthJsImpl auth,
  AuthProviderJsImpl provider,
);

@JS()
external PromiseJsImpl<void> signInWithRedirect(
  AuthJsImpl auth,
  AuthProviderJsImpl provider,
);

@JS()
external PromiseJsImpl<String> verifyPasswordResetCode(
  AuthJsImpl auth,
  String code,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> linkWithCredential(
  UserJsImpl user,
  OAuthCredential? credential,
);

@JS()
external PromiseJsImpl<ConfirmationResultJsImpl> linkWithPhoneNumber(
  UserJsImpl user,
  String phoneNumber,
  ApplicationVerifierJsImpl applicationVerifier,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> linkWithPopup(
  UserJsImpl user,
  AuthProviderJsImpl provider,
);

@JS()
external PromiseJsImpl<void> linkWithRedirect(
  UserJsImpl user,
  AuthProviderJsImpl provider,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> reauthenticateWithCredential(
  UserJsImpl user,
  OAuthCredential credential,
);

@JS()
external PromiseJsImpl<ConfirmationResultJsImpl> reauthenticateWithPhoneNumber(
  UserJsImpl user,
  String phoneNumber,
  ApplicationVerifierJsImpl applicationVerifier,
);

@JS()
external PromiseJsImpl<UserCredentialJsImpl> reauthenticateWithPopup(
  UserJsImpl user,
  AuthProviderJsImpl provider,
);

@JS()
external PromiseJsImpl<void> reauthenticateWithRedirect(
  UserJsImpl user,
  AuthProviderJsImpl provider,
);

@JS()
external PromiseJsImpl<void> sendEmailVerification([
  UserJsImpl user,
  ActionCodeSettings? actionCodeSettings,
]);

@JS()
external PromiseJsImpl<void> verifyBeforeUpdateEmail(
  UserJsImpl user,
  String newEmail, [
  ActionCodeSettings? actionCodeSettings,
]);

@JS()
external PromiseJsImpl<UserJsImpl> unlink(UserJsImpl user, String providerId);

@JS()
external PromiseJsImpl<void> updateEmail(UserJsImpl user, String newEmail);

@JS()
external PromiseJsImpl<void> updatePassword(
  UserJsImpl user,
  String newPassword,
);

@JS()
external PromiseJsImpl<void> updatePhoneNumber(
  UserJsImpl user,
  OAuthCredential? phoneCredential,
);

@JS()
external PromiseJsImpl<void> updateProfile(
  UserJsImpl user,
  UserProfile profile,
);

/// https://firebase.google.com/docs/reference/js/auth.md#multifactor
@JS()
external MultiFactorUserJsImpl multiFactor(
  UserJsImpl user,
);

/// https://firebase.google.com/docs/reference/js/auth.md#multifactor
@JS()
external MultiFactorResolverJsImpl getMultiFactorResolver(
  AuthJsImpl auth,
  MultiFactorError error,
);

@JS('Auth')
abstract class AuthJsImpl {
  external AppJsImpl get app;
  external UserJsImpl get currentUser;
  external String get languageCode;
  external set languageCode(String? s);
  external AuthSettings get settings;
  external String? get tenantId;
  external set tenantId(String? s);
  external Func0 onAuthStateChanged(
    dynamic nextOrObserver, [
    Func1? opt_error,
    Func0? opt_completed,
  ]);
  external Func0 onIdTokenChanged(
    dynamic nextOrObserver, [
    Func1? opt_error,
    Func0? opt_completed,
  ]);
  external PromiseJsImpl<void> signOut();
  external void useDeviceLanguage();
}

@anonymous
@JS()
abstract class IdTokenResultImpl {
  external String get authTime;
  external Object get claims;
  external String get expirationTime;
  external String get issuedAtTime;
  external String get signInProvider;
  external String get token;
}

@anonymous
@JS()
abstract class UserInfoJsImpl {
  external String get displayName;
  external String get email;
  external String get phoneNumber;
  external String get photoURL;
  external String get providerId;
  external String get uid;
}

/// https://firebase.google.com/docs/reference/js/firebase.User
@anonymous
@JS()
abstract class UserJsImpl extends UserInfoJsImpl {
  external bool get emailVerified;
  external bool get isAnonymous;
  external List<UserInfoJsImpl> get providerData;
  external String get refreshToken;
  external String get tenantId;
  external UserMetadata get metadata;
  external PromiseJsImpl<void> delete();
  external PromiseJsImpl<String> getIdToken([bool? opt_forceRefresh]);
  external PromiseJsImpl<IdTokenResultImpl> getIdTokenResult(
      [bool? opt_forceRefresh]);
  external PromiseJsImpl<void> reload();
  external Object toJSON();
}

/// An enumeration of the possible persistence mechanism types.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.Auth#.Persistence>
@JS('Persistence')
class Persistence {
  external String get type;
}

/// Interface that represents the credentials returned by an auth provider.
/// Implementations specify the details about each auth provider's credential
/// requirements.
///
/// See <https://firebase.google.com/docs/reference/js/firebase.auth.AuthCredential>.
@JS('AuthCredential')
abstract class AuthCredential {
  /// The authentication provider ID for the credential. For example,
  /// 'facebook.com', or 'google.com'.
  external String get providerId;

  /// The authentication sign in method for the credential. For example,
  /// 'password', or 'emailLink'. This corresponds to the sign-in method
  /// identifier as returned in firebase.auth.Auth.fetchSignInMethodsForEmail.
  external String get signInMethod;
}

/// Interface that represents the OAuth credentials returned by an OAuth
/// provider. Implementations specify the details about each auth provider's
/// credential requirements.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.OAuthCredential>.
@JS()
@anonymous
abstract class OAuthCredential extends AuthCredential {
  /// The OAuth access token associated with the credential if it belongs to
  /// an OAuth provider, such as facebook.com, twitter.com, etc.
  external String get accessToken;

  /// The OAuth ID token associated with the credential if it belongs to an
  /// OIDC provider, such as google.com.
  external String get idToken;

  /// The OAuth access token secret associated with the credential if it
  /// belongs to an OAuth 1.0 provider, such as twitter.com.
  external String get secret;
}

/// Defines the options for initializing an firebase.auth.OAuthCredential.
/// For ID tokens with nonce claim, the raw nonce has to also be provided.

@JS()
@anonymous
class OAuthCredentialOptions {
  /// The OAuth access token used to initialize the OAuthCredential.
  external String get accessToken;
  external set accessToken(String a);

  /// The OAuth ID token used to initialize the OAuthCredential.
  external String get idToken;
  external set idToken(String i);

  /// The raw nonce associated with the ID token. It is required when an ID token with a nonce field is provided.
  /// The SHA-256 hash of the raw nonce must match the nonce field in the ID token.
  external String get rawNonce;
  external set rawNonce(String r);
  external factory OAuthCredentialOptions({
    String? accessToken,
    String? idToken,
    String? rawNonce,
  });
}

@JS('AuthProvider')
@anonymous
abstract class AuthProviderJsImpl {
  external String get providerId;
}

@JS('EmailAuthProvider')
class EmailAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory EmailAuthProviderJsImpl();
  external static String get PROVIDER_ID;
  external static AuthCredential credential(String email, String password);
  external static AuthCredential credentialWithLink(
    String email,
    String emailLink,
  );
}

@JS('FacebookAuthProvider')
class FacebookAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory FacebookAuthProviderJsImpl();
  external static String get PROVIDER_ID;
  external FacebookAuthProviderJsImpl addScope(String scope);
  external FacebookAuthProviderJsImpl setCustomParameters(
    dynamic customOAuthParameters,
  );
  external static OAuthCredential credential(String token);
}

@JS('GithubAuthProvider')
class GithubAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory GithubAuthProviderJsImpl();
  external static String get PROVIDER_ID;
  external GithubAuthProviderJsImpl addScope(String scope);
  external GithubAuthProviderJsImpl setCustomParameters(
    dynamic customOAuthParameters,
  );
  external static OAuthCredential credential(String token);
}

@JS('GoogleAuthProvider')
class GoogleAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory GoogleAuthProviderJsImpl();
  external static String get PROVIDER_ID;
  external GoogleAuthProviderJsImpl addScope(String scope);
  external GoogleAuthProviderJsImpl setCustomParameters(
    dynamic customOAuthParameters,
  );
  external static OAuthCredential credential(
      [String? idToken, String? accessToken]);
}

@JS('OAuthProvider')
class OAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory OAuthProviderJsImpl(String providerId);
  external OAuthProviderJsImpl addScope(String scope);
  external OAuthProviderJsImpl setCustomParameters(
    dynamic customOAuthParameters,
  );
  external OAuthCredential credential(OAuthCredentialOptions credentialOptions);
  external static OAuthCredential? credentialFromResult(
    UserCredentialJsImpl userCredential,
  );
}

@JS('TwitterAuthProvider')
class TwitterAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory TwitterAuthProviderJsImpl();
  external static String get PROVIDER_ID;
  external TwitterAuthProviderJsImpl setCustomParameters(
    dynamic customOAuthParameters,
  );
  external static OAuthCredential credential(String token, String secret);
}

@JS('PhoneAuthProvider')
class PhoneAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory PhoneAuthProviderJsImpl([AuthJsImpl? auth]);
  external static String get PROVIDER_ID;
  external PromiseJsImpl<String> verifyPhoneNumber(
    dynamic /* PhoneInfoOptions | string */ phoneOptions,
    ApplicationVerifierJsImpl applicationVerifier,
  );
  external static PhoneAuthCredentialJsImpl credential(
    String verificationId,
    String verificationCode,
  );
}

@JS('SAMLAuthProvider')
class SAMLAuthProviderJsImpl extends AuthProviderJsImpl {
  external factory SAMLAuthProviderJsImpl(String providerId);
  external static OAuthCredential? credentialFromResult(
    UserCredentialJsImpl userCredential,
  );
}

@JS('ApplicationVerifier')
abstract class ApplicationVerifierJsImpl {
  external String get type;
  external PromiseJsImpl<String> verify();
}

@JS('RecaptchaVerifier')
class RecaptchaVerifierJsImpl extends ApplicationVerifierJsImpl {
  external factory RecaptchaVerifierJsImpl(
    containerOrId,
    Object parameters,
    AuthJsImpl authExtern,
  );
  external void clear();
  external PromiseJsImpl<num> render();
}

@JS('ConfirmationResult')
abstract class ConfirmationResultJsImpl {
  external String get verificationId;
  external PromiseJsImpl<UserCredentialJsImpl> confirm(String verificationCode);
}

/// A response from [Auth.checkActionCode].
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.ActionCodeInfo>.
@JS()
abstract class ActionCodeInfo {
  external ActionCodeData get data;
}

/// Interface representing a user's metadata.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.UserMetadata>.
@JS()
abstract class UserMetadata {
  /// The date the user was created, formatted as a UTC string.
  /// For example, 'Fri, 22 Sep 2017 01:49:58 GMT'.
  external String? get creationTime;

  /// The date the user last signed in, formatted as a UTC string.
  /// For example, 'Fri, 22 Sep 2017 01:49:58 GMT'.
  external String? get lastSignInTime;
}

/// A structure for [User]'s user profile.
@JS()
@anonymous
class UserProfile {
  external String get displayName;
  external set displayName(String s);
  external String get photoURL;
  external set photoURL(String s);

  external factory UserProfile({String? displayName, String? photoURL});
}

/// An authentication error.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth.Error>.
@JS('Error')
abstract class AuthError {
  external String get code;
  external set code(String s);
  external String get message;
  external set message(String s);
  external String get email;
  external set email(String s);
  external AuthCredential get credential;
  external set credential(AuthCredential c);
  external String get tenantId;
  external set tenantId(String s);
  external String get phoneNumber;
  external set phoneNumber(String s);
}

@JS()
@anonymous
class ActionCodeData {
  external String get email;
  external String get previousEmail;
}

/// This is the interface that defines the required continue/state URL with
/// optional Android and iOS bundle identifiers.
///
/// The fields are:
///
/// [url] Sets the link continue/state URL, which has different meanings
/// in different contexts:
/// * When the link is handled in the web action widgets, this is the deep link
/// in the continueUrl query parameter.
/// * When the link is handled in the app directly, this is the continueUrl
/// query parameter in the deep link of the Dynamic Link.
///
/// [iOS] Sets the [IosSettings] object.
///
/// [android] Sets the [AndroidSettings] object.
///
/// [handleCodeInApp] The default is [:false:]. When set to [:true:],
/// the action code link will be be sent as a Universal Link or Android App Link
/// and will be opened by the app if installed. In the [:false:] case,
/// the code will be sent to the web widget first and then on continue will
/// redirect to the app if installed.
///
/// See: <https://firebase.google.com/docs/reference/js/firebase.auth#.ActionCodeSettings>
@JS()
@anonymous
class ActionCodeSettings {
  external String get url;
  external set url(String s);
  external IosSettings get iOS;
  external set iOS(IosSettings i);
  external AndroidSettings get android;
  external set android(AndroidSettings a);
  external bool get handleCodeInApp;
  external set handleCodeInApp(bool b);
  external String get dynamicLinkDomain;
  external set dynamicLinkDomain(String d);
  external factory ActionCodeSettings({
    String? url,
    IosSettings? iOS,
    AndroidSettings? android,
    bool? handleCodeInApp,
    String? dynamicLinkDomain,
  });
}

/// The iOS settings.
///
/// Sets the iOS [bundleId].
/// This will try to open the link in an iOS app if it is installed.
@JS()
@anonymous
class IosSettings {
  external String get bundleId;
  external set bundleId(String s);
  external factory IosSettings({String? bundleId});
}

/// The Android settings.
///
/// Sets the Android [packageName]. This will try to open the link
/// in an android app if it is installed.
///
/// If [installApp] is passed, it specifies whether to install the Android app
/// if the device supports it and the app is not already installed.
/// If this field is provided without a [packageName], an error is thrown
/// explaining that the [packageName] must be provided in conjunction with
/// this field.
///
/// If [minimumVersion] is specified, and an older version of the app
/// is installed, the user is taken to the Play Store to upgrade the app.
@JS()
@anonymous
class AndroidSettings {
  external String get packageName;
  external set packageName(String s);
  external String get minimumVersion;
  external set minimumVersion(String s);
  external bool get installApp;
  external set installApp(bool b);
  external factory AndroidSettings({
    String? packageName,
    String? minimumVersion,
    bool? installApp,
  });
}

/// https://firebase.google.com/docs/reference/js/auth.usercredential
@JS()
@anonymous
class UserCredentialJsImpl {
  external UserJsImpl get user;
  external String get operationType;
  external AdditionalUserInfoJsImpl get additionalUserInfo;
}

/// https://firebase.google.com/docs/reference/js/firebase.auth#.AdditionalUserInfo
@JS()
@anonymous
class AdditionalUserInfoJsImpl {
  external String get providerId;
  external Object get profile;
  external String get username;
  external bool get isNewUser;
}

/// https://firebase.google.com/docs/reference/js/firebase.auth#.AdditionalUserInfo
@JS()
@anonymous
class AuthSettings {
  external bool get appVerificationDisabledForTesting;
  external set appVerificationDisabledForTesting(bool? b);
  // external factory AuthSettings({bool appVerificationDisabledForTesting});
}

external dynamic get browserPopupRedirectResolver;

/// https://firebase.google.com/docs/reference/js/auth.multifactoruser.md#multifactoruser_interface
@JS()
@anonymous
class MultiFactorUserJsImpl {
  external List<MultiFactorInfoJsImpl> get enrolledFactors;
  external PromiseJsImpl<void> enroll(
      MultiFactorAssertionJsImpl assertion, String? displayName);
  external PromiseJsImpl<MultiFactorSessionJsImpl> getSession();
  external PromiseJsImpl<void> unenroll(
      dynamic /* MultiFactorInfo | string */ option);
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorinfo
@JS()
@anonymous
class MultiFactorInfoJsImpl {
  external String? get displayName;
  external String get enrollmentTime;
  external String get factorId;
  external String get uid;
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorassertion
@JS()
@anonymous
class MultiFactorAssertionJsImpl {
  external String get factorId;
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorerror
@JS('Error')
@anonymous
class MultiFactorError extends AuthError {
  external dynamic get customData;
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorresolver
@JS()
@anonymous
class MultiFactorResolverJsImpl {
  external List<MultiFactorInfoJsImpl> get hints;
  external MultiFactorSessionJsImpl get session;
  external PromiseJsImpl<UserCredentialJsImpl> resolveSignIn(
      MultiFactorAssertionJsImpl assertion);
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorresolver
@JS()
@anonymous
class MultiFactorSessionJsImpl {}

/// https://firebase.google.com/docs/reference/js/auth.phonemultifactorinfo
@JS()
@anonymous
class PhoneMultiFactorInfoJsImpl extends MultiFactorInfoJsImpl {
  external String get phoneNumber;
}

/// https://firebase.google.com/docs/reference/js/auth.phonemultifactorenrollinfooptions
@JS()
@anonymous
class PhoneMultiFactorEnrollInfoOptionsJsImpl {
  external String get phoneNumber;
  external MultiFactorSessionJsImpl? get session;
}

/// https://firebase.google.com/docs/reference/js/auth.phonemultifactorgenerator
@JS('PhoneMultiFactorGenerator')
class PhoneMultiFactorGeneratorJsImpl {
  external static String get FACTOR_ID;
  external static PhoneMultiFactorAssertionJsImpl? assertion(
      PhoneAuthCredentialJsImpl credential);
}

/// https://firebase.google.com/docs/reference/js/auth.phonemultifactorassertion
@JS()
@anonymous
class PhoneMultiFactorAssertionJsImpl extends MultiFactorAssertionJsImpl {}

/// https://firebase.google.com/docs/reference/js/auth.phoneauthcredential
@JS()
@anonymous
class PhoneAuthCredentialJsImpl extends AuthCredential {
  external static PhoneAuthCredentialJsImpl fromJSON(
      dynamic /*object | string*/ json);
  external Object toJSON();
}
