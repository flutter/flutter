// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_auth;

/// Defines multi-factor related properties and operations pertaining to a [User].
/// This class acts as the main entry point for enrolling or un-enrolling
/// second factors for a user, and provides access to their currently enrolled factors.
class MultiFactor {
  MultiFactorPlatform _delegate;

  MultiFactor._(this._delegate);

  /// Returns a session identifier for a second factor enrollment operation.
  Future<MultiFactorSession> getSession() {
    return _delegate.getSession();
  }

  /// Enrolls a second factor as identified by the [MultiFactorAssertion] parameter for the current user.
  ///
  /// [displayName] can be used to provide a display name for the second factor.
  Future<void> enroll(
    MultiFactorAssertion assertion, {
    String? displayName,
  }) async {
    return _delegate.enroll(assertion._delegate, displayName: displayName);
  }

  /// Unenrolls a second factor from this user.
  ///
  /// [factorUid] is the unique identifier of the second factor to unenroll.
  /// [multiFactorInfo] is the [MultiFactorInfo] of the second factor to unenroll.
  /// Only one of [factorUid] or [multiFactorInfo] should be provided.
  Future<void> unenroll({String? factorUid, MultiFactorInfo? multiFactorInfo}) {
    return _delegate.unenroll(
      factorUid: factorUid,
      multiFactorInfo: multiFactorInfo,
    );
  }

  /// Returns a list of the [MultiFactorInfo] already associated with this user.
  Future<List<MultiFactorInfo>> getEnrolledFactors() {
    return _delegate.getEnrolledFactors();
  }
}

/// Provider for generating a PhoneMultiFactorAssertion.
class PhoneMultiFactorGenerator {
  /// Transforms a PhoneAuthCredential into a [MultiFactorAssertion]
  /// which can be used to confirm ownership of a phone second factor.
  static MultiFactorAssertion getAssertion(
    PhoneAuthCredential credential,
  ) {
    final assertion =
        PhoneMultiFactorGeneratorPlatform.instance.getAssertion(credential);
    return MultiFactorAssertion._(assertion);
  }
}

/// Represents an assertion that the Firebase Authentication server
/// can use to authenticate a user as part of a multi-factor flow.
class MultiFactorAssertion {
  final MultiFactorAssertionPlatform _delegate;

  MultiFactorAssertion._(this._delegate) {
    MultiFactorAssertionPlatform.verify(_delegate);
  }
}

/// Utility class that contains methods to resolve second factor
/// requirements on users that have opted into two-factor authentication.
class MultiFactorResolver {
  final FirebaseAuth _auth;
  final MultiFactorResolverPlatform _delegate;

  MultiFactorResolver._(this._auth, this._delegate) {
    MultiFactorResolverPlatform.verify(_delegate);
  }

  /// List of [MultiFactorInfo] which represents the available
  /// second factors that can be used to complete the sign-in for the current session.
  List<MultiFactorInfo> get hints => _delegate.hints;

  /// A MultiFactorSession, an opaque session identifier for the current sign-in flow.
  MultiFactorSession get session => _delegate.session;

  /// Completes sign in with a second factor using an MultiFactorAssertion which
  /// confirms that the user has successfully completed the second factor challenge.
  Future<UserCredential> resolveSignIn(
    MultiFactorAssertion assertion,
  ) async {
    final credential = await _delegate.resolveSignIn(assertion._delegate);
    return UserCredential._(_auth, credential);
  }
}

/// MultiFactor exception related to Firebase Authentication. Check the error code
/// and message for more details.
class FirebaseAuthMultiFactorException extends FirebaseAuthException {
  final FirebaseAuth _auth;
  final FirebaseAuthMultiFactorExceptionPlatform _delegate;

  FirebaseAuthMultiFactorException._(this._auth, this._delegate)
      : super(
          code: _delegate.code,
          message: _delegate.message,
          email: _delegate.email,
          credential: _delegate.credential,
          phoneNumber: _delegate.phoneNumber,
          tenantId: _delegate.tenantId,
        );

  MultiFactorResolver get resolver =>
      MultiFactorResolver._(_auth, _delegate.resolver);
}
