// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/utils/phone_auth_callbacks.dart';

void main() {
  test('$PhoneAuthCallbacks', () {
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {};

    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {};

    final PhoneCodeSent codeSent = (
      String verificationId, [
      int? forceResendingToken,
    ]) async {};

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {};

    final callbacks = PhoneAuthCallbacks(verificationCompleted,
        verificationFailed, codeSent, codeAutoRetrievalTimeout);

    expect(callbacks, isA<PhoneAuthCallbacks>());
    expect(callbacks.verificationCompleted, isA<PhoneVerificationCompleted>());
    expect(callbacks.verificationFailed, isA<PhoneVerificationFailed>());
    expect(callbacks.codeSent, isA<PhoneCodeSent>());
    expect(callbacks.codeAutoRetrievalTimeout,
        isA<PhoneCodeAutoRetrievalTimeout>());
  });
}
