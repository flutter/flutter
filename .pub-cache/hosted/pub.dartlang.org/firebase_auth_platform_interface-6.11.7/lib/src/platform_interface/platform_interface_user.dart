// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A user account.
abstract class UserPlatform extends PlatformInterface {
  // ignore: public_member_api_docs
  UserPlatform(this.auth, this.multiFactor, Map<String, dynamic> user)
      : _user = user,
        super(token: _token);

  static final Object _token = Object();

  /// Ensures that any delegate class has extended a [UserPlatform].
  static void verify(UserPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// The [FirebaseAuthPlatform] instance.
  final FirebaseAuthPlatform auth;

  final MultiFactorPlatform multiFactor;

  final Map<String, dynamic> _user;

  /// The users display name.
  ///
  /// Will be `null` if signing in anonymously or via password authentication.
  String? get displayName {
    return _user['displayName'];
  }

  /// The users email address.
  ///
  /// Will be `null` if signing in anonymously.
  String? get email {
    return _user['email'];
  }

  /// Returns whether the users email address has been verified.
  ///
  /// To send a verification email, see [sendEmailVerification].
  ///
  /// Once verified, call [reload] to ensure the latest user information is
  /// retrieved from Firebase.
  bool get emailVerified {
    return _user['emailVerified'];
  }

  /// Returns whether the user is a anonymous.
  bool get isAnonymous {
    return _user['isAnonymous'];
  }

  /// Returns additional metadata about the user, such as their creation time.
  UserMetadata get metadata {
    return UserMetadata(
        _user['metadata']['creationTime'], _user['metadata']['lastSignInTime']);
  }

  /// Returns the users phone number.
  ///
  /// This property will be `null` if the user has not signed in or been has
  /// their phone number linked.
  String? get phoneNumber {
    return _user['phoneNumber'];
  }

  /// Returns a photo URL for the user.
  ///
  /// This property will be populated if the user has signed in or been linked
  /// with a 3rd party OAuth provider (such as Google).
  String? get photoURL {
    return _user['photoURL'];
  }

  /// Returns a list of user information for each linked provider.
  List<UserInfo> get providerData {
    return List.from(_user['providerData'])
        .map((data) => UserInfo(Map<String, String?>.from(data)))
        .toList();
  }

  /// Returns a JWT refresh token for the user.
  ///
  /// This property will be an empty string for native platforms (android, iOS & macOS) as they do not
  /// support refresh tokens.
  String? get refreshToken {
    return _user['refreshToken'];
  }

  /// The current user's tenant ID.
  ///
  /// This is a read-only property, which indicates the tenant ID used to sign
  /// in the current user. This is `null` if the user is signed in from the
  /// parent project.
  String? get tenantId {
    return _user['tenantId'];
  }

  /// The user's unique ID.
  String get uid {
    return _user['uid'];
  }

  /// Deletes and signs out the user.
  ///
  /// **Important**: this is a security-sensitive operation that requires the
  /// user to have recently signed in. If this requirement isn't met, ask the
  /// user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **requires-recent-login**:
  ///  - Thrown if the user's last sign-in time does not meet the security
  ///    threshold. Use [User.reauthenticateWithCredential] to resolve. This
  ///    does not apply if the user is anonymous.
  Future<void> delete() async {
    throw UnimplementedError('delete() is not implemented');
  }

  /// Returns a JSON Web Token (JWT) used to identify the user to a Firebase
  /// service.
  ///
  /// Returns the current token if it has not expired. Otherwise, this will
  /// refresh the token and return a new one.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<String> getIdToken(bool forceRefresh) {
    throw UnimplementedError('getIdToken() is not implemented');
  }

  /// Returns a [IdTokenResult] containing the users JSON Web Token (JWT) and
  /// other metadata.
  ///
  /// Returns the current token if it has not expired. Otherwise, this will
  /// refresh the token and return a new one.
  ///
  /// If [forceRefresh] is `true`, the token returned will be refresh regardless
  /// of token expiration.
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) {
    throw UnimplementedError('getIdTokenResult() is not implemented');
  }

  /// Links the user account with the given credentials.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **provider-already-linked**:
  ///  - Thrown if the provider has already been linked to the user. This error
  ///    is thrown even if this is not the same provider's account that is
  ///    currently linked to the user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **credential-already-in-use**:
  ///  - Thrown if the account corresponding to the credential already exists
  ///    among your users, or is already linked to a Firebase User. For example,
  ///    this error could be thrown if you are upgrading an anonymous user to a
  ///    Google user by linking a Google credential to it and the Google
  ///    credential used is already associated with an existing Firebase Google
  ///    user. The fields `email`, `phoneNumber`, and `credential`
  ///    ([AuthCredential]) may be provided, depending on the type of
  ///    credential. You can recover from this error by signing in with
  ///    `credential` directly via [signInWithCredential].
  /// - **email-already-in-use**:
  ///  - Thrown if the email corresponding to the credential already exists
  ///    among your users. When thrown while linking a credential to an existing
  ///    user, an `email` and `credential` ([AuthCredential]) fields are also
  ///    provided. You have to link the credential to the existing user with
  ///    that email if you wish to continue signing in with that credential.
  ///    To do so, call [fetchSignInMethodsForEmail], sign in to `email` via one
  ///    of the providers returned and then [User.linkWithCredential] the
  ///    original credential to that newly signed in user.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.
  Future<UserCredentialPlatform> linkWithCredential(AuthCredential credential) {
    throw UnimplementedError('linkWithCredential() is not implemented');
  }

  /// Signs in with an AuthProvider using native authentication flow.
  /// On Web you should use [linkWithPopup] or [linkWithRedirect] instead.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **provider-already-linked**:
  ///  - Thrown if the provider has already been linked to the user. This error
  ///    is thrown even if this is not the same provider's account that is
  ///    currently linked to the user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **credential-already-in-use**:
  ///  - Thrown if the account corresponding to the credential already exists
  ///    among your users, or is already linked to a Firebase User. For example,
  ///    this error could be thrown if you are upgrading an anonymous user to a
  ///    Google user by linking a Google credential to it and the Google
  ///    credential used is already associated with an existing Firebase Google
  ///    user. The fields `email`, `phoneNumber`, and `credential`
  ///    ([AuthCredential]) may be provided, depending on the type of
  ///    credential. You can recover from this error by signing in with
  ///    `credential` directly via [signInWithCredential].
  /// - **email-already-in-use**:
  ///  - Thrown if the email corresponding to the credential already exists
  ///    among your users. When thrown while linking a credential to an existing
  ///    user, an `email` and `credential` ([AuthCredential]) fields are also
  ///    provided. You have to link the credential to the existing user with
  ///    that email if you wish to continue signing in with that credential.
  ///    To do so, call [fetchSignInMethodsForEmail], sign in to `email` via one
  ///    of the providers returned and then [User.linkWithCredential] the
  ///    original credential to that newly signed in user.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.
  Future<UserCredentialPlatform> linkWithProvider(AuthProvider provider) {
    throw UnimplementedError('linkWithProvider() is not implemented');
  }

  /// Renews the user’s authentication using the provided auth provider instance.
  /// On Web you should use [linkWithPopup] instead.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  Future<UserCredentialPlatform> reauthenticateWithProvider(
    AuthProvider provider,
  ) {
    throw UnimplementedError('reauthenticateWithProvider() is not implemented');
  }

  /// Renews the user’s authentication using the provided auth provider instance.
  /// On mobile you should use [reauthenticateWithProvider] instead.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  Future<UserCredentialPlatform> reauthenticateWithPopup(
    AuthProvider provider,
  ) {
    throw UnimplementedError('reauthenticateWithPopup() is not implemented');
  }

  /// Renews the user’s authentication using the provided auth provider instance.
  /// On mobile you should use [reauthenticateWithProvider] instead.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  Future<void> reauthenticateWithRedirect(
    AuthProvider provider,
  ) {
    throw UnimplementedError('reauthenticateWithRedirect() is not implemented');
  }

  /// Links the user account with the given provider.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **provider-already-linked**:
  ///  - Thrown if the provider has already been linked to the user. This error
  ///    is thrown even if this is not the same provider's account that is
  ///    currently linked to the user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **credential-already-in-use**:
  ///  - Thrown if the account corresponding to the credential already exists
  ///    among your users, or is already linked to a Firebase User. For example,
  ///    this error could be thrown if you are upgrading an anonymous user to a
  ///    Google user by linking a Google credential to it and the Google
  ///    credential used is already associated with an existing Firebase Google
  ///    user. The fields `email`, `phoneNumber`, and `credential`
  ///    ([AuthCredential]) may be provided, depending on the type of
  ///    credential. You can recover from this error by signing in with
  ///    `credential` directly via [signInWithCredential].
  /// - **email-already-in-use**:
  ///  - Thrown if the email corresponding to the credential already exists
  ///    among your users. When thrown while linking a credential to an existing
  ///    user, an `email` and `credential` ([AuthCredential]) fields are also
  ///    provided. You have to link the credential to the existing user with
  ///    that email if you wish to continue signing in with that credential.
  ///    To do so, call [fetchSignInMethodsForEmail], sign in to `email` via one
  ///    of the providers returned and then [User.linkWithCredential] the
  ///    original credential to that newly signed in user.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  Future<UserCredentialPlatform> linkWithPopup(AuthProvider provider) {
    throw UnimplementedError('linkWithPopup() is not implemented');
  }

  /// Links the user account with the given provider.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **provider-already-linked**:
  ///  - Thrown if the provider has already been linked to the user. This error
  ///    is thrown even if this is not the same provider's account that is
  ///    currently linked to the user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **credential-already-in-use**:
  ///  - Thrown if the account corresponding to the credential already exists
  ///    among your users, or is already linked to a Firebase User. For example,
  ///    this error could be thrown if you are upgrading an anonymous user to a
  ///    Google user by linking a Google credential to it and the Google
  ///    credential used is already associated with an existing Firebase Google
  ///    user. The fields `email`, `phoneNumber`, and `credential`
  ///    ([AuthCredential]) may be provided, depending on the type of
  ///    credential. You can recover from this error by signing in with
  ///    `credential` directly via [signInWithCredential].
  /// - **email-already-in-use**:
  ///  - Thrown if the email corresponding to the credential already exists
  ///    among your users. When thrown while linking a credential to an existing
  ///    user, an `email` and `credential` ([AuthCredential]) fields are also
  ///    provided. You have to link the credential to the existing user with
  ///    that email if you wish to continue signing in with that credential.
  ///    To do so, call [fetchSignInMethodsForEmail], sign in to `email` via one
  ///    of the providers returned and then [User.linkWithCredential] the
  ///    original credential to that newly signed in user.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the provider in the Firebase Console. Go
  ///    to the Firebase Console for your project, in the Auth section and the
  ///    Sign in Method tab and configure the provider.
  Future<void> linkWithRedirect(AuthProvider provider) {
    throw UnimplementedError('linkWithRedirect() is not implemented');
  }

  /// Links the user account with the given phone number.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **provider-already-linked**:
  ///  - Thrown if the provider has already been linked to the user. This error
  ///    is thrown even if this is not the same provider's account that is
  ///    currently linked to the user.
  /// - **captcha-check-failed**:
  ///  - Thrown if the reCAPTCHA response token was invalid, expired, or if this
  ///    method was called from a non-whitelisted domain.
  /// - **invalid-phone-number**:
  ///  - Thrown if the phone number has an invalid format.
  /// - **quota-exceeded**:
  ///  - Thrown if the SMS quota for the Firebase project has been exceeded.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given phone number has been disabled.
  /// - **credential-already-in-use**:
  ///  - Thrown if the account corresponding to the phone number already exists
  ///    among your users, or is already linked to a Firebase User.
  /// - **operation-not-allowed**:
  ///  - Thrown if you have not enabled the phone authentication provider in the
  ///  Firebase Console. Go to the Firebase Console for your project, in the Auth
  ///  section and the Sign in Method tab and configure the provider.
  Future<ConfirmationResultPlatform> linkWithPhoneNumber(
    String phoneNumber,
    RecaptchaVerifierFactoryPlatform applicationVerifier,
  ) {
    throw UnimplementedError('linkWithPhoneNumber() is not implemented');
  }

  /// Re-authenticates a user using a fresh credential.
  ///
  /// Use before operations such as [User.updatePassword] that require tokens
  /// from recent sign-in attempts.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **user-mismatch**:
  ///  - Thrown if the credential given does not correspond to the user.
  /// - **user-not-found**:
  ///  - Thrown if the credential given does not correspond to any existing
  ///    user.
  /// - **invalid-credential**:
  ///  - Thrown if the provider's credential is not valid. This can happen if it
  ///    has already expired when calling link, or if it used invalid token(s).
  ///    See the Firebase documentation for your provider, and make sure you
  ///    pass in the correct parameters to the credential method.
  /// - **invalid-email**:
  ///  - Thrown if the email used in a [EmailAuthProvider.credential] is
  ///    invalid.
  /// - **wrong-password**:
  ///  - Thrown if the password used in a [EmailAuthProvider.credential] is not
  ///    correct or when the user associated with the email does not have a
  ///    password.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.
  Future<UserCredentialPlatform> reauthenticateWithCredential(
      AuthCredential credential) {
    throw UnimplementedError(
        'reauthenticateWithCredential() is not implemented');
  }

  /// Refreshes the current user, if signed in.
  Future<void> reload() async {
    throw UnimplementedError('reload() is not implemented');
  }

  /// Sends a verification email to a user.
  ///
  /// The verification process is completed by calling [applyActionCode].
  Future<void> sendEmailVerification(
    ActionCodeSettings? actionCodeSettings,
  ) async {
    throw UnimplementedError('sendEmailVerification() is not implemented');
  }

  /// Unlinks a provider from a user account.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **no-such-provider**:
  ///  - Thrown if the user does not have this provider linked or when the
  ///    provider ID given does not exist.
  Future<UserPlatform> unlink(String providerId) async {
    throw UnimplementedError('unlink() is not implemented');
  }

  /// Updates the user's email address.
  ///
  /// An email will be sent to the original email address (if it was set) that
  /// allows to revoke the email address change, in order to protect them from
  /// account hijacking.
  ///
  /// **Important**: this is a security sensitive operation that requires the
  /// user to have recently signed in. If this requirement isn't met, ask the
  /// user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email used is invalid.
  /// - **email-already-in-use**:
  ///  - Thrown if the email is already used by another user.
  /// - **requires-recent-login**:
  ///  - Thrown if the user's last sign-in time does not meet the security
  ///    threshold. Use [User.reauthenticateWithCredential] to resolve. This
  ///    does not apply if the user is anonymous.
  Future<void> updateEmail(String newEmail) async {
    throw UnimplementedError('updateEmail() is not implemented');
  }

  /// Updates the user's password.
  ///
  /// **Important**: this is a security sensitive operation that requires the
  ///   user to have recently signed in. If this requirement isn't met, ask the
  ///   user to authenticate again and then call [User.reauthenticateWithCredential].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **weak-password**:
  ///  - Thrown if the password is not strong enough.
  /// - **requires-recent-login**:
  ///  - Thrown if the user's last sign-in time does not meet the security
  ///    threshold. Use [User.reauthenticateWithCredential] to resolve. This
  ///    does not apply if the user is anonymous.
  Future<void> updatePassword(String newPassword) async {
    throw UnimplementedError('updatePassword() is not implemented');
  }

  /// Updates the user's phone number.
  ///
  /// A credential can be created by verifying a phone number via
  /// [verifyPhoneNumber].
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-verification-code**:
  ///  - Thrown if the verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the verification ID of the credential is not valid.
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {
    throw UnimplementedError('updatePhoneNumber() is not implemented');
  }

  /// Updates a user's profile data.
  Future<void> updateProfile(Map<String, String?> profile) async {
    throw UnimplementedError('updateProfile() is not implemented');
  }

  /// Sends a verification email to a new email address. The user's email will
  /// be updated to the new one after being verified.
  ///
  /// If you have a custom email action handler, you can complete the
  /// verification process by calling [applyActionCode].
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    throw UnimplementedError('verifyBeforeUpdateEmail() is not implemented');
  }
}
