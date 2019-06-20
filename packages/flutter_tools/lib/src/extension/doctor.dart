// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'extension.dart';

/// How does the environment match the validation requirements.
enum ValidationType {
  /// Requirements are not met or are otherwise missing.
  missing,

  /// Some requirements are met.
  partial,
  // TODO(jonahwilliams): deprecate this enum.
  notAvailable,

  /// All requirements are met.
  installed,
}

/// The kind of validation message to be shown in the doctor UI.
enum ValidationMessageType {
  /// Something is wrong with this validator.
  error,

  /// Nothing is broken, but something might not be right.
  hint,

  /// Nothing is broken, purely informative.
  information,
}

/// Collected tool functionality related to diagnosing problems with a project
/// or development environment.
abstract class DoctorDomain extends Domain {

  /// Diagnose problems with the users environment.
  Future<Map<String, Object>> diagnose(Map<String, Object> arguments);
}
