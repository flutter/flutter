// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../doctor.dart';
import '../features.dart';

/// The custom-devices-specific implementation of a [Workflow].
///
/// This workflow requires the flutter-desktop-embedding as a sibling
/// repository to the flutter repo.
class CustomDeviceWorkflow implements Workflow {
  const CustomDeviceWorkflow({
    required FeatureFlags featureFlags
  }) : _featureFlags = featureFlags;

  final FeatureFlags _featureFlags;

  @override
  bool get appliesToHostPlatform => _featureFlags.areCustomDevicesEnabled;

  @override
  bool get canLaunchDevices => _featureFlags.areCustomDevicesEnabled;

  @override
  bool get canListDevices => _featureFlags.areCustomDevicesEnabled;

  @override
  bool get canListEmulators => false;
}
