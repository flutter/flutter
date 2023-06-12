// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../method_channel/method_channel_firebase_auth.dart';

/// The interface that implementations of `firebase_auth` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `firebase_auth` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [FirebaseAuthPlatform] methods.
abstract class FirebaseAuthPlatform extends PlatformInterface {
  /// The [FirebaseApp] this instance was initialized with.
  @protected
  final FirebaseApp? appInstance;

  /// The current Auth instance's tenant ID.
  ///
  /// When you set the tenant ID of an Auth instance, all future sign-in/sign-up
  /// operations will pass this tenant ID and sign in or sign up users to the
  /// specified tenant project. When set to null, users are signed in to the
  /// parent project. By default, this is set to `null`.
  String? tenantId;

  /// Create an instance using [app]
  FirebaseAuthPlatform({this.appInstance}) : super(token: _token);

  /// Returns the [FirebaseApp] for the current instance.
  FirebaseApp get app {
    if (appInstance == null) {
      return Firebase.app();
    }

    return appInstance!;
  }

  static final Object _token = Object();

  /// Create an instance using [app] using the existing implementation
  factory FirebaseAuthPlatform.instanceFor(
      {required FirebaseApp app,
      required Map<dynamic, dynamic> pluginConstants,
      Persistence? persistence}) {
    return FirebaseAuthPlatform.instance
        .delegateFor(app: app, persistence: persistence)
        .setInitialValues(
            languageCode: pluginConstants['APP_LANGUAGE_CODE'],
            currentUser: pluginConstants['APP_CURRENT_USER'] == null
                ? null
                : Map<String, dynamic>.from(
                    pluginConstants['APP_CURRENT_USER']));
  }

  /// The current default [FirebaseAuthPlatform] instance.
  ///
  /// It will always default to [MethodChannelFirebaseAuth]
  /// if no other implementation was provided.
  static FirebaseAuthPlatform get instance {
    _instance ??= MethodChannelFirebaseAuth.instance;
    return _instance!;
  }

  static FirebaseAuthPlatform? _instance;

  /// Sets the [FirebaseAuthPlatform.instance]
  static set instance(FirebaseAuthPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Enables delegates to create new instances of themselves if a none default
  /// [FirebaseApp] instance is required by the user.
  ///
  /// Setting a [persistence] type is only available on web based platforms.
  @protected
  FirebaseAuthPlatform delegateFor(
      {required FirebaseApp app, Persistence? persistence}) {
    throw UnimplementedError('delegateFor() is not implemented');
  }

  /// Sets any initial values on the instance.
  ///
  /// Platforms with Method Channels can provide constant values to be available
  /// before the instance has initialized to prevent any unnecessary async
  /// calls.
  @protected
  FirebaseAuthPlatform setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    throw UnimplementedError('setInitialValues() is not implemented');
  }

  /// Returns the current [User] if they are currently signed-in, or `null` if
  /// not.
  ///
  /// You should not use this getter to determine the users current state,
  /// instead use [authStateChanges], [idTokenChanges] or [userChanges] to
  /// subscribe to updates.
  UserPlatform? get currentUser {
    throw UnimplementedError('get.currentUser is not implemented');
  }

  /// Sets the current user for the instance.
  set currentUser(UserPlatform? userPlatform) {
    throw UnimplementedError('set.currentUser is not implemented');
  }

  /// The current Auth instance's language code.
  ///
  /// See [setLanguageCode] to update the language code.
  String? get languageCode {
    throw UnimplementedError('languageCode is not implemented');
  }

  /// Sends a Stream event to a [authStateChanges] stream controller.
  void sendAuthChangesEvent(String appName, UserPlatform? userPlatform) {
    throw UnimplementedError('sendAuthChangesEvent() is not implemented');
  }

  /// Changes this instance to point to an Auth emulator running locally.
  ///
  /// Set the [host] and [port] of the local emulator, such as "localhost"
  /// with port 9099
  ///
  /// Note: Must be called immediately, prior to accessing auth methods.
  /// Do not use with production credentials as emulator traffic is not encrypted.
  Future<void> useAuthEmulator(String host, int port) {
    throw UnimplementedError('useAuthEmulator() is not implemented');
  }

  /// Applies a verification code sent to the user by email or other out-of-band
  /// mechanism.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the action code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the action code is invalid. This can happen if the code is
  ///    malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given action code has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the action code. This may
  ///    have happened if the user was deleted between when the action code was
  ///    issued and when this method was called.
  Future<void> applyActionCode(String code) {
    throw UnimplementedError('applyActionCode() is not implemented');
  }

  /// Checks a verification code sent to the user by email or other out-of-band
  /// mechanism.
  ///
  /// Returns [ActionCodeInfo] about the code.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the action code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the action code is invalid. This can happen if the code is
  ///    malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given action code has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the action code. This may
  ///    have happened if the user was deleted between when the action code was
  ///    issued and when this method was called.
  Future<ActionCodeInfo> checkActionCode(String code) {
    throw UnimplementedError('checkActionCode() is not implemented');
  }

  /// Completes the password reset process, given a confirmation code and new
  /// password.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the action code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the action code is invalid. This can happen if the code is
  ///    malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given action code has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the action code. This may
  ///    have happened if the user was deleted between when the action code was
  ///    issued and when this method was called.
  /// - **weak-password**:
  ///  - Thrown if the new password is not strong enough.
  Future<void> confirmPasswordReset(String code, String newPassword) {
    throw UnimplementedError('confirmPasswordReset() is not implemented');
  }

  /// Tries to create a new user account with the given email address and
  /// password.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **email-already-in-use**:
  ///  - Thrown if there already exists an account with the given email address.
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **operation-not-allowed**:
  ///  - Thrown if email/password accounts are not enabled. Enable
  ///    email/password accounts in the Firebase Console, under the Auth tab.
  /// - **weak-password**:
  ///  - Thrown if the password is not strong enough.
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
    String email,
    String password,
  ) {
    throw UnimplementedError(
      'createUserWithEmailAndPassword() is not implemented',
    );
  }

  /// Returns a list of sign-in methods that can be used to sign in a given
  /// user (identified by its main email address).
  ///
  /// This method is useful when you support multiple authentication mechanisms
  /// if you want to implement an email-first authentication flow.
  ///
  /// An empty `List` is returned if the user could not be found.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  Future<List<String>> fetchSignInMethodsForEmail(String email) {
    throw UnimplementedError('fetchSignInMethodsForEmail() is not implemented');
  }

  /// Returns a UserCredential from the redirect-based sign-in flow.
  ///
  /// If sign-in succeeded, returns the signed in user. If sign-in was
  /// unsuccessful, fails with an error. If no redirect operation was called,
  /// returns a [UserCredential] with a null User.
  ///
  /// This method is only support on web platforms.
  Future<UserCredentialPlatform> getRedirectResult() {
    throw UnimplementedError('getRedirectResult() is not implemented');
  }

  /// Checks if an incoming link is a sign-in with email link.
  bool isSignInWithEmailLink(String emailLink) {
    return (emailLink.contains('mode=signIn') ||
            emailLink.contains('mode%3DsignIn')) &&
        (emailLink.contains('oobCode=') || emailLink.contains('oobCode%3D'));
  }

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out).
  Stream<UserPlatform?> authStateChanges() {
    throw UnimplementedError('authStateChanges() is not implemented');
  }

  /// Notifies about changes to the user's sign-in state (such as sign-in or
  /// sign-out)
  /// and also token refresh events.
  Stream<UserPlatform?> idTokenChanges() {
    throw UnimplementedError('idTokenChanges() is not implemented');
  }

  /// Notifies about changes to any user updates.
  ///
  /// This is a superset of both [authStateChanges] and [idTokenChanges]. It
  /// provides events on all user changes, such as when credentials are linked,
  /// unlinked and when updates to the user profile are made. The purpose of
  /// this Stream is for listening to realtime updates to the user state
  /// (signed-in, signed-out, different user & token refresh) without
  /// manually having to call [reload] and then rehydrating changes to your
  /// application.
  Stream<UserPlatform?> userChanges() {
    throw UnimplementedError('userChanges() is not implemented');
  }

  /// Triggers the Firebase Authentication backend to send a password-reset
  /// email to the given email address, which must correspond to an existing
  /// user of your app.
  Future<void> sendPasswordResetEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) {
    throw UnimplementedError('sendPasswordResetEmail() is not implemented');
  }

  /// Sends a sign in with email link to provided email address.
  ///
  /// To complete the password reset, call [confirmPasswordReset] with the code
  /// supplied in the email sent to the user, along with the new password
  /// specified by the user.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the email address.
  Future<void> sendSignInLinkToEmail(
    String email,
    ActionCodeSettings actionCodeSettings,
  ) {
    throw UnimplementedError('sendSignInLinkToEmail() is not implemented');
  }

  /// When set to null, the default Firebase Console language setting is
  /// applied.
  ///
  /// The language code will propagate to email action templates (password
  /// reset, email verification and email change revocation), SMS templates for
  /// phone authentication, reCAPTCHA verifier and OAuth popup/redirect
  /// operations provided the specified providers support localization with the
  /// language code specified.
  ///
  /// On web platforms, if `null` is provided as the [languageCode] the Firebase
  /// project default language will be used. On native platforms, the device
  /// language will be used.
  Future<void> setLanguageCode(String? languageCode) {
    throw UnimplementedError('setLanguageCode() is not implemented');
  }

  /// Updates the current instance with the provided settings.
  ///
  /// [appVerificationDisabledForTesting] This setting applies to Android, iOS and
  ///   web platforms. When set to `true`, this property disables app
  ///   verification for the purpose of testing phone authentication. For this
  ///   property to take effect, it needs to be set before handling a reCAPTCHA
  ///   app verifier. When this is disabled, a mock reCAPTCHA is rendered
  ///   instead. This is useful for manual testing during development or for
  ///   automated integration tests.
  ///
  ///   In order to use this feature, you will need to
  ///   [whitelist your phone number](https://firebase.google.com/docs/auth/web/phone-auth?authuser=0#test-with-whitelisted-phone-numbers)
  ///   via the Firebase Console.
  ///
  ///   The default value is `false` (app verification is enabled).
  ///
  /// [forceRecaptchaFlow] This setting applies to Android only. When set to 'true',
  ///   it forces the application verification to use the web reCAPTCHA flow for Phone Authentication.
  ///   Once this has been called, every call to PhoneAuthProvider#verifyPhoneNumber() will skip the SafetyNet verification flow and use the reCAPTCHA flow instead.
  ///   Calling this method a second time will overwrite the previously passed parameter.
  ///
  /// [phoneNumber] & [smsCode] These settings apply to Android only. The phone number and SMS code here must have been configured in the Firebase Console (Authentication > Sign In Method > Phone).
  ///   Once this has been called, every call to PhoneAuthProvider#verifyPhoneNumber() with the same phone number as the one that is configured here will have onVerificationCompleted() triggered as the callback.
  ///   Calling this method a second time will overwrite the previously passed parameters. Only one number can be configured at a given time.
  ///   Calling this method with either parameter set to null removes this functionality until valid parameters are passed.
  ///   Verifying a phone number other than the one configured here will trigger normal behavior. If the phone number is configured as a test phone number in the console, the regular testing flow occurs. Otherwise, normal phone number verification will take place.
  ///   When this is set and PhoneAuthProvider#verifyPhoneNumber() is called with a matching phone number, PhoneAuthProvider.OnVerificationStateChangedCallbacks.onCodeAutoRetrievalTimeOut(String) will never be called.
  ///
  /// [userAccessGroup] This setting only applies to iOS and MacOS platforms.
  ///   When set, it allows you to share authentication state between
  ///   applications. Set the property to your team group ID or set to `null`
  ///   to remove sharing capabilities.
  ///
  ///   Key Sharing capabilities must be enabled for your app via XCode (Project
  ///   settings > Capabilities). To learn more, visit the
  ///   [Apple documentation](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps).
  Future<void> setSettings({
    bool? appVerificationDisabledForTesting,
    String? userAccessGroup,
    String? phoneNumber,
    String? smsCode,
    bool? forceRecaptchaFlow,
  }) {
    throw UnimplementedError('setSettings() is not implemented');
  }

  /// Changes the current type of persistence on the current Auth instance for
  /// the currently saved Auth session and applies this type of persistence for
  /// future sign-in requests, including sign-in with redirect requests. This
  /// will return a promise that will resolve once the state finishes copying
  /// from one type of storage to the other. Calling a sign-in method after
  /// changing persistence will wait for that persistence change to complete
  /// before applying it on the new Auth state.
  ///
  /// This makes it easy for a user signing in to specify whether their session
  /// should be remembered or not. It also makes it easier to never persist the
  /// Auth state for applications that are shared by other users or have
  /// sensitive data.
  ///
  /// This is only supported on web based platforms.
  Future<void> setPersistence(Persistence persistence) async {
    throw UnimplementedError('setPersistence() is not implemented');
  }

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **operation-not-allowed**:
  ///  - Thrown if anonymous accounts are not enabled. Enable anonymous accounts
  ///    in the Firebase Console, under the Auth tab.
  Future<UserCredentialPlatform> signInAnonymously() async {
    throw UnimplementedError('signInAnonymously() is not implemented');
  }

  /// Asynchronously signs in to Firebase with the given 3rd-party credentials
  /// (e.g. a Facebook login Access Token, a Google ID Token/Access Token pair,
  /// etc.) and returns additional identity provider data.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  ///
  /// If the user doesn't have an account already, one will be created
  /// automatically.
  ///
  /// **Important**: You must enable the relevant accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **account-exists-with-different-credential**:
  ///  - Thrown if there already exists an account with the email address
  ///    asserted by the credential. Resolve this by calling
  ///    [fetchSignInMethodsForEmail] and then asking the user to sign in using
  ///    one of the returned providers. Once the user is signed in, the original
  ///    credential can be linked to the user with [linkWithCredential].
  /// - **invalid-credential**:
  ///  - Thrown if the credential is malformed or has expired.
  /// - **operation-not-allowed**:
  ///  - Thrown if the type of account corresponding to the credential is not
  ///    enabled. Enable the account type in the Firebase Console, under the
  ///    Auth tab.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given credential has been
  ///    disabled.
  /// - **user-not-found**:
  ///  - Thrown if signing in with a credential from [EmailAuthProvider.credential]
  ///    and there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Thrown if signing in with a credential from [EmailAuthProvider.credential]
  ///    and the password is invalid for the given email, or if the account
  ///    corresponding to the email does not have a password set.
  /// - **invalid-verification-code**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification code of the credential is not valid.
  /// - **invalid-verification-id**:
  ///  - Thrown if the credential is a [PhoneAuthProvider.credential] and the
  ///    verification ID of the credential is not valid.id.
  Future<UserCredentialPlatform> signInWithCredential(
    AuthCredential credential,
  ) async {
    throw UnimplementedError('signInWithCredential() is not implemented');
  }

  /// Tries to sign in a user with a given Custom Token [token].
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// Use this method after you retrieve a Firebase Auth Custom Token from your
  /// server.
  ///
  /// If the user identified by the [uid] specified in the token doesn't
  /// have an account already, one will be created automatically.
  ///
  /// Read how to use Custom Token authentication and the cases where it is
  /// useful in [the guides](https://firebase.google.com/docs/auth/android/custom-auth).
  Future<UserCredentialPlatform> signInWithCustomToken(String token) async {
    throw UnimplementedError('signInWithCustomToken() is not implemented');
  }

  /// Attempts to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the given email.
  /// - **wrong-password**:
  ///  - Thrown if the password is invalid for the given email, or the account
  ///    corresponding to the email does not have a password set.
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    throw UnimplementedError('signInWithEmailAndPassword() is not implemented');
  }

  /// Signs in using an email address and email sign-in link.
  ///
  /// Fails with an error if the email address is invalid or OTP in email link
  /// expires.
  ///
  /// Confirm the link is a sign-in email link before calling this method,
  /// using [isSignInWithEmailLink].

  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if OTP in email link expires.
  /// - **invalid-email**:
  ///  - Thrown if the email address is not valid.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  Future<UserCredentialPlatform> signInWithEmailLink(
    String email,
    String emailLink,
  ) async {
    throw UnimplementedError('signInWithEmailLink() is not implemented');
  }

  /// Signs in with an AuthProvider using native authentication flow.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  Future<UserCredentialPlatform> signInWithProvider(
    AuthProvider provider,
  ) async {
    throw UnimplementedError('signInWithProvider() is not implemented');
  }

  /// Starts a sign-in flow for a phone number.
  ///
  /// You can optionally provide a [RecaptchaVerifier] instance to control the
  /// reCAPTCHA widget appearance and behavior.
  ///
  /// Once the reCAPTCHA verification has completed, called [ConfirmationResult.confirm]
  /// with the users SMS verification code to complete the authentication flow.
  ///
  /// This method is only available on web based platforms.
  Future<ConfirmationResultPlatform> signInWithPhoneNumber(
    String phoneNumber,
    RecaptchaVerifierFactoryPlatform applicationVerifier,
  ) async {
    throw UnimplementedError('signInWithPhoneNumber() is not implemented');
  }

  /// Authenticates a Firebase client using a popup-based OAuth authentication
  /// flow.
  ///
  /// If succeeds, returns the signed in user along with the provider's
  /// credential.
  ///
  /// This method is only available on web based platforms.
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider provider) {
    throw UnimplementedError('signInWithPopup() is not implemented');
  }

  /// Authenticates a Firebase client using a full-page redirect flow.
  ///
  /// To handle the results and errors for this operation, refer to
  /// [getRedirectResult].
  Future<void> signInWithRedirect(AuthProvider provider) {
    throw UnimplementedError('signInWithRedirect() is not implemented');
  }

  /// Signs out the current user.
  ///
  /// If successful, it also updates
  /// any [authStateChanges], [idTokenChanges] or [userChanges] stream
  /// listeners.
  Future<void> signOut() async {
    throw UnimplementedError('signOut() is not implemented');
  }

  /// Checks a password reset code sent to the user by email or other
  /// out-of-band mechanism.
  ///
  /// Returns the user's email address if valid.
  ///
  /// A [FirebaseAuthException] maybe thrown with the following error code:
  /// - **expired-action-code**:
  ///  - Thrown if the password reset code has expired.
  /// - **invalid-action-code**:
  ///  - Thrown if the password reset code is invalid. This can happen if the
  ///    code is malformed or has already been used.
  /// - **user-disabled**:
  ///  - Thrown if the user corresponding to the given email has been disabled.
  /// - **user-not-found**:
  ///  - Thrown if there is no user corresponding to the password reset code.
  ///    This may have happened if the user was deleted between when the code
  ///    was issued and when this method was called.
  Future<String> verifyPasswordResetCode(String code) {
    throw UnimplementedError('verifyPasswordResetCode() is not implemented');
  }

  /// Starts a phone number verification process for the given phone number.
  ///
  /// This method is used to verify that the user-provided phone number belongs
  /// to the user. Firebase sends a code via SMS message to the phone number,
  /// where you must then prompt the user to enter the code. The code can be
  /// combined with the verification ID to create a [PhoneAuthProvider.credential]
  /// which you can then use to sign the user in, or link with their account (
  /// see [signInWithCredential] or [linkWithCredential]).
  ///
  /// On some Android devices, auto-verification can be handled by the device
  /// and a [PhoneAuthCredential] will be automatically provided.
  ///
  /// No duplicated SMS will be sent out unless a [forceResendingToken] is
  /// provided.
  ///
  /// [phoneNumber] The phone number for the account the user is signing up
  ///   for or signing into. Make sure to pass in a phone number with country
  ///   code prefixed with plus sign ('+').
  ///
  /// [timeout] The maximum amount of time you are willing to wait for SMS
  ///   auto-retrieval to be completed by the library. Maximum allowed value
  ///   is 2 minutes.
  ///
  /// [forceResendingToken] The [forceResendingToken] obtained from [codeSent]
  ///   callback to force re-sending another verification SMS before the
  ///   auto-retrieval timeout.
  ///
  /// [verificationCompleted] Triggered when an SMS is auto-retrieved or the
  ///   phone number has been instantly verified. The callback will receive an
  ///   [PhoneAuthCredential] that can be passed to [signInWithCredential] or
  ///   [linkWithCredential].
  ///
  /// [verificationFailed]  Triggered when an error occurred during phone number
  ///   verification. A [FirebaseAuthException] is provided when this is
  ///   triggered.
  ///
  /// [codeSent] Triggered when an SMS has been sent to the users phone,
  ///   and will include a [verificationId] and [forceResendingToken].
  ///
  /// [codeAutoRetrievalTimeout] Triggered when SMS auto-retrieval times out and
  ///   provide a [verificationId].
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
    // ignore: invalid_use_of_visible_for_testing_member
    @visibleForTesting String? autoRetrievedSmsCodeForTesting,
  }) {
    throw UnimplementedError('verifyPhoneNumber() is not implemented');
  }
}
