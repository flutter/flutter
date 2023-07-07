// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// The type of operation that generated the action code from calling
/// [checkActionCode].
enum ActionCodeInfoOperation {
  /// Unknown operation.
  unknown,

  /// Password reset code generated via [sendPasswordResetEmail].
  passwordReset,

  /// Email verification code generated via [User.sendEmailVerification].
  verifyEmail,

  /// Email change revocation code generated via [User.updateEmail].
  recoverEmail,

  /// Email sign in code generated via [sendSignInLinkToEmail].
  emailSignIn,

  /// Verify and change email code generated via [User.verifyBeforeUpdateEmail].
  verifyAndChangeEmail,

  /// Action code for reverting second factor addition.
  revertSecondFactorAddition,
}

/// A response from calling [checkActionCode].
class ActionCodeInfo {
  // ignore: public_member_api_docs
  @protected
  ActionCodeInfo({
    required int operation,
    required Map<String, dynamic> data,
  })  : _operation = operation,
        _data = data;

  int _operation;

  Map<String, dynamic> _data;

  /// The type of operation that generated the action code.
  ActionCodeInfoOperation get operation {
    switch (_operation) {
      case 0:
        return ActionCodeInfoOperation.unknown;
      case 1:
        return ActionCodeInfoOperation.passwordReset;
      case 2:
        return ActionCodeInfoOperation.verifyEmail;
      case 3:
        return ActionCodeInfoOperation.recoverEmail;
      case 4:
        return ActionCodeInfoOperation.emailSignIn;
      case 5:
        return ActionCodeInfoOperation.verifyAndChangeEmail;
      case 6:
        return ActionCodeInfoOperation.revertSecondFactorAddition;
      default:
        throw UnsupportedError('Unknown ActionCodeInfoOperation: $_operation.');
    }
  }

  /// The data associated with the action code.
  ///
  /// Depending on the [ActionCodeInfoOperation], `email` and `previousEmail`
  /// may be available.
  Map<String, dynamic> get data {
    return <String, dynamic>{
      'email': _data['email'],
      'previousEmail': _data['previousEmail'],
    };
  }
}
