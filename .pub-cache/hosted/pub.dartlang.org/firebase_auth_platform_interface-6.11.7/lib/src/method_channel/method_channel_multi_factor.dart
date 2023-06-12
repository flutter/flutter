// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user_credential.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/utils/exception.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/utils/pigeon_helper.dart';
import 'package:firebase_auth_platform_interface/src/pigeon/messages.pigeon.dart';

class MethodChannelMultiFactor extends MultiFactorPlatform {
  /// Constructs a new [MethodChannelMultiFactor] instance.
  MethodChannelMultiFactor(FirebaseAuthPlatform auth) : super(auth);

  final _api = MultiFactorUserHostApi();

  @override
  Future<MultiFactorSession> getSession() async {
    try {
      final pigeonObject = await _api.getSession(auth.app.name);
      return MultiFactorSession(pigeonObject.id);
    } catch (e, stack) {
      convertPlatformException(e, stack, fromPigeon: true);
    }
  }

  @override
  Future<void> enroll(
    MultiFactorAssertionPlatform assertion, {
    String? displayName,
  }) async {
    final _assertion = assertion as MultiFactorAssertion;

    if (_assertion.credential is PhoneAuthCredential) {
      final credential = _assertion.credential as PhoneAuthCredential;
      final verificationId = credential.verificationId;
      final verificationCode = credential.smsCode;

      if (verificationCode == null) {
        throw ArgumentError('verificationCode must not be null');
      }
      if (verificationId == null) {
        throw ArgumentError('verificationId must not be null');
      }

      try {
        await _api.enrollPhone(
          auth.app.name,
          PigeonPhoneMultiFactorAssertion(
            verificationId: verificationId,
            verificationCode: verificationCode,
          ),
          displayName,
        );
      } catch (e, stack) {
        convertPlatformException(e, stack, fromPigeon: true);
      }
    } else {
      throw UnimplementedError(
        'Credential type ${_assertion.credential} is not supported yet',
      );
    }
  }

  @override
  Future<void> unenroll({
    String? factorUid,
    MultiFactorInfo? multiFactorInfo,
  }) {
    final uidToUnenroll = factorUid ?? multiFactorInfo?.uid;
    if (uidToUnenroll == null) {
      throw ArgumentError(
        'Either factorUid or multiFactorInfo must not be null',
      );
    }

    try {
      return _api.unenroll(
        auth.app.name,
        uidToUnenroll,
      );
    } catch (e, stack) {
      convertPlatformException(e, stack, fromPigeon: true);
    }
  }

  @override
  Future<List<MultiFactorInfo>> getEnrolledFactors() async {
    try {
      final data = await _api.getEnrolledFactors(auth.app.name);
      return multiFactorInfoPigeonToObject(data);
    } catch (e, stack) {
      convertPlatformException(e, stack, fromPigeon: true);
    }
  }
}

class MethodChannelMultiFactorResolver extends MultiFactorResolverPlatform {
  MethodChannelMultiFactorResolver(
    List<MultiFactorInfo> hints,
    MultiFactorSession session,
    String resolverId,
    MethodChannelFirebaseAuth auth,
  )   : _resolverId = resolverId,
        _auth = auth,
        super(hints, session);

  final String _resolverId;

  final MethodChannelFirebaseAuth _auth;
  final _api = MultiFactoResolverHostApi();

  @override
  Future<UserCredentialPlatform> resolveSignIn(
    MultiFactorAssertionPlatform assertion,
  ) async {
    final _assertion = assertion as MultiFactorAssertion;

    if (_assertion.credential is PhoneAuthCredential) {
      final credential = _assertion.credential as PhoneAuthCredential;
      final verificationId = credential.verificationId;
      final verificationCode = credential.smsCode;

      if (verificationCode == null) {
        throw ArgumentError('verificationCode must not be null');
      }
      if (verificationId == null) {
        throw ArgumentError('verificationId must not be null');
      }

      try {
        final data = await _api.resolveSignIn(
          _resolverId,
          PigeonPhoneMultiFactorAssertion(
            verificationId: verificationId,
            verificationCode: verificationCode,
          ),
        );

        MethodChannelUserCredential userCredential =
            MethodChannelUserCredential(_auth, data.cast<String, dynamic>());

        return userCredential;
      } catch (e, stack) {
        convertPlatformException(e, stack, fromPigeon: true);
      }
    } else {
      throw UnimplementedError(
        'Credential type ${_assertion.credential} is not supported yet',
      );
    }
  }
}

/// Represents an assertion that the Firebase Authentication server
/// can use to authenticate a user as part of a multi-factor flow.
class MultiFactorAssertion extends MultiFactorAssertionPlatform {
  MultiFactorAssertion(this.credential) : super();

  /// Associated credential to the assertion
  final AuthCredential credential;
}

/// Helper class used to generate PhoneMultiFactorAssertions.
class MethodChannelPhoneMultiFactorGenerator
    extends PhoneMultiFactorGeneratorPlatform {
  /// Transforms a PhoneAuthCredential into a [MultiFactorAssertion]
  /// which can be used to confirm ownership of a phone second factor.
  @override
  MultiFactorAssertionPlatform getAssertion(
    PhoneAuthCredential credential,
  ) {
    return MultiFactorAssertion(credential);
  }
}
