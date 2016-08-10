// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart_ui;

/// Mojo handles provided to the application at startup.
///
/// The application can take ownership of these handles by calling the static
/// "take" functions on this object. Once taken, the application is responsible
/// for managing the handles.
class MojoServices {
  MojoServices._();

  static int takeRootBundle() native "MojoServices_takeRootBundle";
  static int takeIncomingServices() native "MojoServices_takeIncomingServices";
  static int takeOutgoingServices() native "MojoServices_takeOutgoingServices";
  static int takeShell() native "MojoServices_takeShell";
  static int takeView() native "MojoServices_takeView";
  static int takeViewServices() native "MojoServices_takeViewServices";
}

// TODO(abarth): Remove these once clients have migrated to [MojoServices].
int takeRootBundleHandle() => MojoServices.takeRootBundle();
int takeServicesProvidedByEmbedder() => MojoServices.takeIncomingServices();
int takeServicesProvidedToEmbedder() => MojoServices.takeOutgoingServices();
int takeShellProxyHandle() => MojoServices.takeShell();
int takeViewHandle() => MojoServices.takeView();
