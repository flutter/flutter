// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// A data class for app links related project settings.
///
/// See https://developer.android.com/training/app-links.
@immutable
class AndroidAppLinkSettings {
  const AndroidAppLinkSettings({
    required this.applicationId,
    required this.domains,
  });

  /// The application id of the android sub-project.
  final String applicationId;

  /// The associated web domains of the android sub-project.
  final List<String> domains;
}
