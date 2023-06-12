// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_multi_factor.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// {@template .platformInterfaceMultiFactor}
/// The platform defining the interface of multi-factor related
/// properties and operations pertaining to a [User].
/// {@endtemplate}
abstract class MultiFactorPlatform extends PlatformInterface {
  /// {@macro .platformInterfaceMultiFactor}
  MultiFactorPlatform(
    this.auth,
  ) : super(token: _token);

  /// The [FirebaseAuthPlatform] instance.
  final FirebaseAuthPlatform auth;

  static final Object _token = Object();

  /// Enrolls a second factor as identified by the [MultiFactorAssertion] parameter for the current user.
  ///
  /// [displayName] can be used to provide a display name for the second factor.
  Future<void> enroll(
    MultiFactorAssertionPlatform assertion, {
    String? displayName,
  }) {
    throw UnimplementedError('enroll() is not implemented');
  }

  /// Returns a session identifier for a second factor enrollment operation.
  Future<MultiFactorSession> getSession() {
    throw UnimplementedError('getSession() is not implemented');
  }

  /// Unenrolls a second factor from this user.
  ///
  /// [factorUid] is the unique identifier of the second factor to unenroll.
  /// [multiFactorInfo] is the [MultiFactorInfo] of the second factor to unenroll.
  /// Only one of [factorUid] or [multiFactorInfo] should be provided.
  Future<void> unenroll({String? factorUid, MultiFactorInfo? multiFactorInfo}) {
    throw UnimplementedError('unenroll() is not implemented');
  }

  /// Returns a list of the [MultiFactorInfo] already associated with this user.
  Future<List<MultiFactorInfo>> getEnrolledFactors() {
    throw UnimplementedError('getEnrolledFactors() is not implemented');
  }
}

/// Identifies the current session to enroll a second factor or to complete sign in when previously enrolled.
///
/// It contains additional context on the existing user, notably the confirmation that the user passed the first factor challenge.
class MultiFactorSession {
  MultiFactorSession(this.id);

  final String id;
}

/// {@template .multiFactorAssertion}
/// Represents an assertion that the Firebase Authentication server
/// can use to authenticate a user as part of a multi-factor flow.
/// {@endtemplate}
class MultiFactorAssertionPlatform extends PlatformInterface {
  /// {@macro .multiFactorAssertion}
  MultiFactorAssertionPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Ensures that any delegate class has extended a [MultiFactorResolverPlatform].
  static void verify(MultiFactorAssertionPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }
}

/// {@template .platformInterfaceMultiFactorResolverPlatform}
/// Utility class that contains methods to resolve second factor
/// requirements on users that have opted into two-factor authentication.
/// {@endtemplate}
class MultiFactorResolverPlatform extends PlatformInterface {
  /// {@macro .platformInterfaceMultiFactorResolverPlatform}
  MultiFactorResolverPlatform(
    this.hints,
    this.session,
  ) : super(token: _token);

  static final Object _token = Object();

  /// Ensures that any delegate class has extended a [MultiFactorResolverPlatform].
  static void verify(MultiFactorResolverPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// List of [MultiFactorInfo] which represents the available
  /// second factors that can be used to complete the sign-in for the current session.
  final List<MultiFactorInfo> hints;

  /// A MultiFactorSession, an opaque session identifier for the current sign-in flow.
  final MultiFactorSession session;

  /// Completes sign in with a second factor using an MultiFactorAssertion which
  /// confirms that the user has successfully completed the second factor challenge.
  Future<UserCredentialPlatform> resolveSignIn(
    MultiFactorAssertionPlatform assertion,
  ) {
    throw UnimplementedError('resolveSignIn() is not implemented');
  }
}

/// Represents a single second factor means for the user.
///
/// See direct subclasses for type-specific information.
class MultiFactorInfo {
  const MultiFactorInfo({
    required this.factorId,
    required this.enrollmentTimestamp,
    required this.displayName,
    required this.uid,
  });

  /// User-given display name for this second factor.
  final String? displayName;

  /// The enrollment timestamp for this second factor in seconds since epoch (UTC midnight on January 1, 1970).
  final double enrollmentTimestamp;

  /// The factor id of this second factor.
  final String factorId;

  /// The unique identifier for this second factor.
  final String uid;

  @override
  String toString() {
    return 'MultiFactorInfo{enrollmentTimestamp: $enrollmentTimestamp, displayName: $displayName, uid: $uid}';
  }
}

/// Represents the information for a phone second factor.
class PhoneMultiFactorInfo extends MultiFactorInfo {
  const PhoneMultiFactorInfo({
    required String? displayName,
    required double enrollmentTimestamp,
    required String factorId,
    required String uid,
    required this.phoneNumber,
  }) : super(
          displayName: displayName,
          enrollmentTimestamp: enrollmentTimestamp,
          factorId: factorId,
          uid: uid,
        );

  /// The phone number associated with this second factor verification method.
  final String phoneNumber;
}

/// Helper class used to generate PhoneMultiFactorAssertions.
class PhoneMultiFactorGeneratorPlatform extends PlatformInterface {
  static PhoneMultiFactorGeneratorPlatform? _instance;

  static final Object _token = Object();

  PhoneMultiFactorGeneratorPlatform() : super(token: _token);

  /// The current default [PhoneMultiFactorGeneratorPlatform] instance.
  ///
  /// It will always default to [MethodChannelPhoneMultiFactorGenerator]
  /// if no other implementation was provided.
  static PhoneMultiFactorGeneratorPlatform get instance {
    _instance ??= MethodChannelPhoneMultiFactorGenerator();
    return _instance!;
  }

  /// Sets the [PhoneMultiFactorGeneratorPlatform.instance]
  static set instance(PhoneMultiFactorGeneratorPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Transforms a PhoneAuthCredential into a [MultiFactorAssertion]
  /// which can be used to confirm ownership of a phone second factor.
  MultiFactorAssertionPlatform getAssertion(
    PhoneAuthCredential credential,
  ) {
    throw UnimplementedError('getAssertion() is not implemented');
  }
}
