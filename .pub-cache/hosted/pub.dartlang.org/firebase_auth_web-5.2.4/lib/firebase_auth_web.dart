// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_web/src/firebase_auth_web_multi_factor.dart';
import 'package:firebase_auth_web/src/interop/utils/utils.dart';
import 'package:firebase_auth_web/src/utils/web_utils.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart'
    as core_interop;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/firebase_auth_web_confirmation_result.dart';
import 'src/firebase_auth_web_recaptcha_verifier_factory.dart';
import 'src/firebase_auth_web_user.dart';
import 'src/firebase_auth_web_user_credential.dart';
import 'src/interop/auth.dart' as auth_interop;
import 'src/interop/multi_factor.dart' as multi_factor;

/// The web delegate implementation for [FirebaseAuth].
class FirebaseAuthWeb extends FirebaseAuthPlatform {
  /// Stub initializer to allow the [registerWith] to create an instance without
  /// registering the web delegates or listeners.
  FirebaseAuthWeb._()
      : _webAuth = null,
        super(appInstance: null);

  Completer<void> _initialized = Completer();

  // To set "persistence" on web, it is now required on the v9.0.0 or above Firebase JS SDK to pass the value on calling `initializeAuth()`.
  // https://firebase.google.com/docs/reference/js/auth.md#initializeauth
  Persistence? _persistence;

  /// The entry point for the [FirebaseAuthWeb] class.
  FirebaseAuthWeb({required FirebaseApp app, Persistence? persistence})
      : super(appInstance: app) {
    _persistence = persistence;
    // Create a app instance broadcast stream for both delegate listener events
    _userChangesListeners[app.name] =
        StreamController<UserPlatform?>.broadcast();
    _authStateChangesListeners[app.name] =
        StreamController<UserPlatform?>.broadcast();
    _idTokenChangesListeners[app.name] =
        StreamController<UserPlatform?>.broadcast();

    // TODO(rrousselGit): close StreamSubscription
    delegate.onAuthStateChanged.map((auth_interop.User? webUser) {
      if (!_initialized.isCompleted) {
        _initialized.complete();
      }

      if (webUser == null) {
        return null;
      } else {
        return UserWeb(
          this,
          MultiFactorWeb(this, multi_factor.multiFactor(webUser)),
          webUser,
          _webAuth,
        );
      }
    }).listen((UserWeb? webUser) {
      _authStateChangesListeners[app.name]!.add(webUser);
    });

    // TODO(rrousselGit): close StreamSubscription
    // Also triggers `userChanged` events
    delegate.onIdTokenChanged.map((auth_interop.User? webUser) {
      if (webUser == null) {
        return null;
      } else {
        return UserWeb(
          this,
          MultiFactorWeb(this, multi_factor.multiFactor(webUser)),
          webUser,
          _webAuth,
        );
      }
    }).listen((UserWeb? webUser) {
      _idTokenChangesListeners[app.name]!.add(webUser);
      _userChangesListeners[app.name]!.add(webUser);
    });
  }

  /// Called by PluginRegistry to register this plugin for Flutter Web
  static void registerWith(Registrar registrar) {
    FirebaseCoreWeb.registerService('auth', () async {
      await FirebaseAuthWeb.instance.delegate.onWaitInitState();
    });
    FirebaseAuthPlatform.instance = FirebaseAuthWeb.instance;
    PhoneMultiFactorGeneratorPlatform.instance = PhoneMultiFactorGeneratorWeb();
    RecaptchaVerifierFactoryPlatform.instance =
        RecaptchaVerifierFactoryWeb.instance;
  }

  static Map<String, StreamController<UserPlatform?>>
      _authStateChangesListeners = <String, StreamController<UserPlatform?>>{};

  static Map<String, StreamController<UserPlatform?>> _idTokenChangesListeners =
      <String, StreamController<UserPlatform?>>{};

  static Map<String, StreamController<UserPlatform?>> _userChangesListeners =
      <String, StreamController<UserPlatform?>>{};

  /// Initializes a stub instance to allow the class to be registered.
  static FirebaseAuthWeb get instance {
    return FirebaseAuthWeb._();
  }

  /// instance of Auth from the web plugin
  auth_interop.Auth? _webAuth;

  auth_interop.Auth get delegate {
    _webAuth ??= auth_interop.getAuthInstance(core_interop.app(app.name),
        persistence: _persistence);

    return _webAuth!;
  }

  @override
  FirebaseAuthPlatform delegateFor(
      {required FirebaseApp app, Persistence? persistence}) {
    return FirebaseAuthWeb(app: app, persistence: persistence);
  }

  @override
  FirebaseAuthWeb setInitialValues({
    Map<String, dynamic>? currentUser,
    String? languageCode,
  }) {
    // Values are already set on web
    return this;
  }

  @override
  UserPlatform? get currentUser {
    auth_interop.User? webCurrentUser = delegate.currentUser;

    if (webCurrentUser == null) {
      return null;
    }

    return UserWeb(
      this,
      MultiFactorWeb(this, multi_factor.multiFactor(delegate.currentUser!)),
      delegate.currentUser!,
      _webAuth,
    );
  }

  @override
  String? get tenantId {
    return delegate.tenantId;
  }

  @override
  set tenantId(String? tenantId) {
    delegate.tenantId = tenantId;
  }

  @override
  void sendAuthChangesEvent(String appName, UserPlatform? userPlatform) {
    assert(_userChangesListeners[appName] != null);

    _userChangesListeners[appName]!.add(userPlatform);
  }

  @override
  Future<void> applyActionCode(String code) async {
    try {
      await delegate.applyActionCode(code);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<ActionCodeInfo> checkActionCode(String code) async {
    try {
      return convertWebActionCodeInfo(await delegate.checkActionCode(code))!;
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await delegate.confirmPasswordReset(code, newPassword);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return UserCredentialWeb(
        this,
        await delegate.createUserWithEmailAndPassword(email, password),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      return await delegate.fetchSignInMethodsForEmail(email);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> getRedirectResult() async {
    try {
      return UserCredentialWeb(
        this,
        await delegate.getRedirectResult(),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Stream<UserPlatform?> authStateChanges() async* {
    await _initialized.future;
    yield currentUser;
    yield* _authStateChangesListeners[app.name]!.stream;
  }

  @override
  Stream<UserPlatform?> idTokenChanges() async* {
    await _initialized.future;
    yield currentUser;
    yield* _idTokenChangesListeners[app.name]!.stream;
  }

  @override
  Stream<UserPlatform?> userChanges() async* {
    await _initialized.future;
    yield currentUser;
    yield* _userChangesListeners[app.name]!.stream;
  }

  @override
  Future<void> sendPasswordResetEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    try {
      await delegate.sendPasswordResetEmail(
          email, convertPlatformActionCodeSettings(actionCodeSettings));
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> sendSignInLinkToEmail(
    String email, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    try {
      await delegate.sendSignInLinkToEmail(
          email, convertPlatformActionCodeSettings(actionCodeSettings));
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  String get languageCode {
    return delegate.languageCode;
  }

  @override
  Future<void> setLanguageCode(String? languageCode) async {
    delegate.languageCode = languageCode;
  }

  @override
  Future<void> setSettings({
    bool? appVerificationDisabledForTesting,
    String? userAccessGroup,
    String? phoneNumber,
    String? smsCode,
    bool? forceRecaptchaFlow,
  }) async {
    delegate.settings.appVerificationDisabledForTesting =
        appVerificationDisabledForTesting;
  }

  @override
  Future<void> setPersistence(Persistence persistence) async {
    try {
      return delegate.setPersistence(persistence);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<UserCredentialPlatform> signInAnonymously() async {
    try {
      return UserCredentialWeb(
        this,
        await delegate.signInAnonymously(),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithCredential(
    AuthCredential credential,
  ) async {
    try {
      return UserCredentialWeb(
        this,
        await delegate
            .signInWithCredential(convertPlatformCredential(credential)!),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithCustomToken(String token) async {
    try {
      return UserCredentialWeb(
        this,
        await delegate.signInWithCustomToken(token),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return UserCredentialWeb(
        this,
        await delegate.signInWithEmailAndPassword(email, password),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailLink(
      String email, String emailLink) async {
    try {
      return UserCredentialWeb(
        this,
        await delegate.signInWithEmailLink(email, emailLink),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<ConfirmationResultPlatform> signInWithPhoneNumber(
    String phoneNumber,
    RecaptchaVerifierFactoryPlatform applicationVerifier,
  ) async {
    try {
      // Do not inline - type is not inferred & error is thrown.
      auth_interop.RecaptchaVerifier verifier = applicationVerifier.delegate;

      return ConfirmationResultWeb(
        this,
        await delegate.signInWithPhoneNumber(phoneNumber, verifier),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<UserCredentialPlatform> signInWithPopup(AuthProvider provider) async {
    try {
      return UserCredentialWeb(
        this,
        await delegate.signInWithPopup(convertPlatformAuthProvider(provider)),
        _webAuth,
      );
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<void> signInWithRedirect(AuthProvider provider) async {
    try {
      return delegate.signInWithRedirect(convertPlatformAuthProvider(provider));
    } catch (e) {
      throw getFirebaseAuthException(e, _webAuth);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await delegate.signOut();
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> useAuthEmulator(String host, int port) async {
    try {
      // The generic platform interface is with host and port split to
      // centralize logic between android/ios native, but web takes the
      // origin as a single string
      delegate.useAuthEmulator('http://$host:$port');
    } catch (e) {
      final String code = (e as auth_interop.AuthError).code;
      // this catches Firebase Error from web that occurs after hot reloading & hot restarting
      if (code != 'auth/emulator-config-failed') {
        throw getFirebaseAuthException(e);
      }
    }
  }

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    try {
      return await delegate.verifyPasswordResetCode(code);
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    try {
      Map<String, dynamic>? data;
      if (multiFactorSession != null) {
        final _webMultiFactorSession =
            multiFactorSession as MultiFactorSessionWeb;
        if (multiFactorInfo != null) {
          data = {
            'multiFactorUid': multiFactorInfo.uid,
            'session': _webMultiFactorSession.webSession.jsObject,
          };
        } else {
          data = {
            'phoneNumber': phoneNumber,
            'session': _webMultiFactorSession.webSession.jsObject,
          };
        }
      }

      final phoneOptions = (data ?? phoneNumber)!;

      final provider = auth_interop.PhoneAuthProvider(_webAuth);
      final verifier = RecaptchaVerifierFactoryWeb(
        auth: this,
      ).delegate;

      /// We add the passthrough method for LegacyJsObject
      final verificationId = await provider.verifyPhoneNumber(
          jsify(phoneOptions, (object) => object), verifier);

      codeSent(verificationId, null);
    } catch (e) {
      verificationFailed(getFirebaseAuthException(e));
    }
  }
}
