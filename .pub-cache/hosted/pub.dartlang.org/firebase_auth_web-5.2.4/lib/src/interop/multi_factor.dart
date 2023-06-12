// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs

import 'package:firebase_core_web/firebase_core_web_interop.dart'
    hide jsify, dartify;

import 'auth.dart' as auth;
import 'auth_interop.dart' as auth_interop;

/// Given an AppJSImp, return the Auth instance.
MultiFactorUser multiFactor(auth.User user) {
  return MultiFactorUser.getInstance(auth_interop.multiFactor(user.jsObject));
}

/// Given an AppJSImp, return the Auth instance.
MultiFactorResolver getMultiFactorResolver(
    auth.Auth auth, auth_interop.MultiFactorError error) {
  return MultiFactorResolver.fromJsObject(
      auth_interop.getMultiFactorResolver(auth.jsObject, error));
}

/// The Firebase MultiFactorUser service class.
///
/// See: https://firebase.google.com/docs/reference/js/auth.md#multifactor.
class MultiFactorUser
    extends JsObjectWrapper<auth_interop.MultiFactorUserJsImpl> {
  static final _expando = Expando<MultiFactorUser>();

  /// Creates a new Auth from a [jsObject].
  static MultiFactorUser getInstance(
      auth_interop.MultiFactorUserJsImpl jsObject) {
    return _expando[jsObject] ??= MultiFactorUser._fromJsObject(jsObject);
  }

  MultiFactorUser._fromJsObject(auth_interop.MultiFactorUserJsImpl jsObject)
      : super.fromJsObject(jsObject);

  /// Returns a list of the user's enrolled second factors.
  List<MultiFactorInfo> get enrolledFactors =>
      jsObject.enrolledFactors.map(MultiFactorInfo.fromJsObject).toList();

  /// Returns the session identifier for a second factor enrollment operation.
  ///
  /// This is used to identify the user trying to enroll a second factor.
  Future<MultiFactorSession> get session =>
      handleThenable(jsObject.getSession())
          .then(MultiFactorSession.fromJsObject);

  /// Enrolls a second factor as identified by the [MultiFactorAssertion] for the user.
  ///
  /// On resolution, the user tokens are updated to reflect the change in the JWT payload.
  /// Accepts an additional display name parameter used to identify the second factor to the end user.
  /// Recent re-authentication is required for this operation to succeed. On successful enrollment,
  /// existing Firebase sessions (refresh tokens) are revoked. When a new factor is enrolled,
  /// an email notification is sent to the user’s email.
  Future<void> enroll(MultiFactorAssertion assertion, String? displayName) {
    return handleThenable(jsObject.enroll(assertion.jsObject, displayName));
  }

  /// Unenrolls the specified second factor.
  ///
  /// To specify the factor to remove, pass a [MultiFactorInfo] object
  /// (retrieved from [MultiFactorUser.enrolledFactors]) or the factor's UID string.
  /// Sessions are not revoked when the account is unenrolled.
  /// An email notification is likely to be sent to the user notifying them of the change.
  /// Recent re-authentication is required for this operation to succeed.
  /// When an existing factor is unenrolled, an email notification is sent to the user’s email.
  Future<void> unenroll(String multiFactorInfoId) {
    return handleThenable(jsObject.unenroll(multiFactorInfoId));
  }
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorinfo
class MultiFactorInfo<T extends auth_interop.MultiFactorInfoJsImpl>
    extends JsObjectWrapper<T> {
  MultiFactorInfo.fromJsObject(T jsObject) : super.fromJsObject(jsObject);

  /// The user friendly name of the current second factor.
  String? get displayName => jsObject.displayName;

  /// The enrollment date of the second factor formatted as a UTC string.
  String get enrollmentTime => jsObject.enrollmentTime;

  /// The identifier of the second factor.
  String get factorId => jsObject.factorId;

  /// The multi-factor enrollment ID.
  String get uid => jsObject.uid;
}

class PhoneMultiFactorInfo
    extends MultiFactorInfo<auth_interop.PhoneMultiFactorInfoJsImpl> {
  PhoneMultiFactorInfo.fromJsObject(
      auth_interop.PhoneMultiFactorInfoJsImpl jsObject)
      : super.fromJsObject(jsObject);

  /// The user friendly name of the current second factor.
  String get phoneNumber => jsObject.phoneNumber;
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorsession.md#multifactorsession_interface
class MultiFactorSession
    extends JsObjectWrapper<auth_interop.MultiFactorSessionJsImpl> {
  MultiFactorSession.fromJsObject(auth.MultiFactorSessionJsImpl jsObject)
      : super.fromJsObject(jsObject);
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorsession.md#multifactorsession_interface
class MultiFactorAssertion<T extends auth_interop.MultiFactorAssertionJsImpl>
    extends JsObjectWrapper<T> {
  MultiFactorAssertion.fromJsObject(T jsObject) : super.fromJsObject(jsObject);

  String get factorId => jsObject.factorId;
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorsession.md#multifactorsession_interface
class PhoneMultiFactorAssertion
    extends MultiFactorAssertion<auth_interop.PhoneMultiFactorAssertionJsImpl> {
  PhoneMultiFactorAssertion.fromJsObject(
      auth.PhoneMultiFactorAssertionJsImpl jsObject)
      : super.fromJsObject(jsObject);
}

/// https://firebase.google.com/docs/reference/js/auth#getmultifactorresolver
class MultiFactorResolver
    extends JsObjectWrapper<auth_interop.MultiFactorResolverJsImpl> {
  MultiFactorResolver.fromJsObject(auth.MultiFactorResolverJsImpl jsObject)
      : super.fromJsObject(jsObject);

  List<MultiFactorInfo> get hints => jsObject.hints.map((e) {
        if (e is auth_interop.PhoneMultiFactorInfoJsImpl) {
          return PhoneMultiFactorInfo.fromJsObject(e);
        } else {
          return MultiFactorInfo.fromJsObject(e);
        }
      }).toList();
  MultiFactorSession get session =>
      MultiFactorSession.fromJsObject(jsObject.session);

  Future<auth.UserCredential> resolveSignIn(MultiFactorAssertion assertion) {
    return handleThenable(jsObject.resolveSignIn(assertion.jsObject))
        .then(auth.UserCredential.fromJsObject);
  }
}

/// https://firebase.google.com/docs/reference/js/auth.multifactorsession.md#multifactorsession_interface
class PhoneMultiFactorGenerator
    extends JsObjectWrapper<auth_interop.PhoneMultiFactorGeneratorJsImpl> {
  PhoneMultiFactorGenerator.fromJsObject(
      auth.PhoneMultiFactorGeneratorJsImpl jsObject)
      : super.fromJsObject(jsObject);

  static PhoneMultiFactorAssertion assertion(
      auth.PhoneAuthCredentialJsImpl credential) {
    return PhoneMultiFactorAssertion.fromJsObject(
        auth_interop.PhoneMultiFactorGeneratorJsImpl.assertion(credential)!);
  }
}
