// Copyright 2022, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: one_member_abstracts

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/pigeon/messages.pigeon.dart',
    // We export in the lib folder to expose the class to other packages.
    dartTestOut: 'test/pigeon/test_api.dart',
    javaOut:
        '../firebase_auth/android/src/main/java/io/flutter/plugins/firebase/auth/GeneratedAndroidFirebaseAuth.java',
    javaOptions: JavaOptions(
      package: 'io.flutter.plugins.firebase.auth',
      className: 'GeneratedAndroidFirebaseAuth',
    ),
    objcHeaderOut: '../firebase_auth/ios/Classes/Public/messages.g.h',
    objcSourceOut: '../firebase_auth/ios/Classes/messages.g.m',
  ),
)
class PigeonMultiFactorSession {
  const PigeonMultiFactorSession({
    required this.id,
  });

  final String id;
}

class PigeonPhoneMultiFactorAssertion {
  const PigeonPhoneMultiFactorAssertion({
    required this.verificationId,
    required this.verificationCode,
  });

  final String verificationId;
  final String verificationCode;
}

class PigeonMultiFactorInfo {
  const PigeonMultiFactorInfo({
    this.displayName,
    required this.enrollmentTimestamp,
    this.factorId,
    required this.uid,
    required this.phoneNumber,
  });

  final String? displayName;
  final double enrollmentTimestamp;
  final String? factorId;
  final String uid;
  final String? phoneNumber;
}

@HostApi(dartHostTestHandler: 'TestMultiFactorUserHostApi')
abstract class MultiFactorUserHostApi {
  @async
  void enrollPhone(
    String appName,
    PigeonPhoneMultiFactorAssertion assertion,
    String? displayName,
  );

  @async
  PigeonMultiFactorSession getSession(String appName);

  @async
  void unenroll(
    String appName,
    String? factorUid,
  );

  @async
  List<PigeonMultiFactorInfo> getEnrolledFactors(String appName);
}

@HostApi(dartHostTestHandler: 'TestMultiFactoResolverHostApi')
abstract class MultiFactoResolverHostApi {
  @async
  Map<String, Object> resolveSignIn(
    String resolverId,
    PigeonPhoneMultiFactorAssertion assertion,
  );
}

/// Only used to generate the object interface that are use outside of the Pigeon interface
@HostApi()
abstract class GenerateInterfaces {
  void generateInterfaces(PigeonMultiFactorInfo info);
}
