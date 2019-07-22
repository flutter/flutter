// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Tool extensions for interfacing with a flutter application.
library app;

import 'package:meta/meta.dart';

import 'extension.dart';

/// The configuration for a built application.
class ApplicationBundle implements Serializable {
  /// Create a new [ApplicationBundle].
  ///
  /// [executable] must not be null.
  const ApplicationBundle({
    @required this.executable,
    this.context = const <String, Object>{},
  }) : assert(executable != null);

  /// Create a new [ApplicationBundle] from a json object.
  factory ApplicationBundle.fromJson(Map<String, Object> json) {
    final String executable = json['executable'];
    final Map<String, Object> context = json['context'];
    return ApplicationBundle(
      executable: executable,
      context: context,
    );
  }

  /// The identifier for the executable.
  final String executable;

  /// Additional contextual information about this executable.
  final Map<String, Object> context;

  @override
  Object toJson() {
    return <String, Object>{
      'executable': executable,
      'context': context,
    };
  }
}

/// A running flutter application.
class ApplicationInstance implements Serializable {
  /// Create a new [ApplicationInstance].
  ///
  /// if [vmserviceUri] is not provided, the application is configured as non
  /// debuggable by the tool.
  const ApplicationInstance({
    this.vmserviceUri,
    this.context = const <String, Object>{},
  });

  /// Create a new [ApplicationInstance] from a json object.
  factory ApplicationInstance.fromJson(Map<String, Object> json) {
    final Uri vmserviceUri = Uri.tryParse(json['vmserviceUri']);
    final Map<String, Object> context = json['context'] ?? const <String, Object>{};
    return ApplicationInstance(vmserviceUri: vmserviceUri, context: context);
  }

  /// The vmservice uri of the running application.
  ///
  /// This value may be null if the application is running in release mode,
  /// or otherwise does not have an availible vmservice.
  final Uri vmserviceUri;

  /// Additional platform-specific context.
  ///
  /// For example, a process id for a desktop application.
  final Map<String, Object> context;

  @override
  Object toJson() {
    return <String, Object>{
      'vmserviceUri': vmserviceUri,
      'context': context,
    };
  }
}

/// Functionality related to running applications.
abstract class AppDomain extends Domain {
  /// The tool has requested that an application is started on [deviceId].
  ///
  /// The binary for the application is provided in the [applicationBundle].
  Future<ApplicationInstance> startApp(ApplicationBundle applicationBundle, String deviceId);

  /// The tool has requested that an application is stopped.
  ///
  /// The binary for the application is provided in the [applicationBundle].
  Future<void> stopApp(ApplicationBundle applicationBundle);
}
