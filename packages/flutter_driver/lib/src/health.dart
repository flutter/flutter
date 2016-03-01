// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'enum_util.dart';
import 'message.dart';

/// Requests an application health check.
class GetHealth implements Command {
  final String kind = 'get_health';

  static fromJson(Map<String, dynamic> json) => new GetHealth();

  Map<String, dynamic> toJson() => const {};
}

/// Application health status.
enum HealthStatus {
  /// Application is known to be in a good shape and should be able to respond.
  ok,

  /// Application is not known to be in a good shape and may be unresponsive.
  bad,
}

final EnumIndex<HealthStatus> _healthStatusIndex =
    new EnumIndex<HealthStatus>(HealthStatus.values);

/// Application health status.
class Health extends Result {
  Health(this.status) {
    assert(status != null);
  }

  static Health fromJson(Map<String, dynamic> json) {
    return new Health(_healthStatusIndex.lookupBySimpleName(json['status']));
  }

  /// Health status
  final HealthStatus status;

  Map<String, dynamic> toJson() => {
    'status': _healthStatusIndex.toSimpleName(status)
  };
}
