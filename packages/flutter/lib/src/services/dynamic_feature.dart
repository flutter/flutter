// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Default Google Play Store implementation states that reflect the current
/// installation status of a dynamic feature module.
///
/// Returned by [DynamicFeature.getDynamicFeatureInstallState].
///
/// These states may differ in custom dynamic feature implementations.
///
/// Due to the asynchronous nature of platform channels, these states are
/// informational and should not be depended on to determine if a dynamic
/// feature is ready to use or not. Readiness should be determined by
/// completion of the future returned by [installDynamicFeature] or
/// `loadLibrary()`.
///
/// These states are an extension of the states in Android's
/// https://developer.android.com/reference/com/google/android/play/core/splitinstall/model/SplitInstallSessionStatus
///
/// Typical state flow begins as `unknown`, and transitions into `requested`
/// when the installation is begun. When the request is processed, the
/// state changes to `downloading` and finally `installed`. Modules previously
/// installed but not loaded in this session will be in the
/// `installedPendingLoad` state, which indicates that the installation request
/// call (either `loadLibrary()` or [installDynamicFeature]) should be repeated
/// to trigger the loading process.
enum DynamicFeatureInstallState {
  requested,
  pending,
  requireUserConfirmation,
  downloading,
  downloaded,
  installing,
  installedPendingLoad,
  installed,
  cancelling,
  canceled,
  failed,
  unknown,
}

/// Manages the installation and loading of dynamic feature modules.
///
/// Dynamic features allow Flutter applications to download precompiled AOT
/// dart code and assets at runtime, reducing the install size of apps and
/// avoiding installing unnessecary code/assets on end user devices. Common
/// use cases include deferring installation of advanced or infrequently
/// used features and limiting locale specific features to users of matching
/// locales.
class DynamicFeature {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  // ignore: unused_element
  DynamicFeature._();

  // TODO(garyq): We should eventually expand this to install modules by loadingUnitId
  // as well as moduleName, but currently, loadingUnitId is opaque to the dart code
  // so this is not possible. The API has been left flexible to allow adding
  // loadingUnitId as a parameter.

  /// Requests that an assets-only dynamic feature identified by the [moduleName]
  /// be downloaded and installed.
  ///
  /// This method returns a Future<void> that will complete when the feature is
  /// installed and any assets are ready to used. When an error occurs, the
  /// future will complete an error.
  ///
  /// This method should be used for asset-only dynamic features. Dynamic features
  /// containing dart code should call `loadLibrary()` on a deferred imported
  /// library's prefix to ensure that the dart code is properly loaded as
  /// `loadLibrary()` will provide the loading unit id needed for the dart
  /// library loading process. For example:
  ///
  /// ```dart
  /// import 'split_module.dart' deferred as SplitModule;
  /// ...
  /// SplitModule.loadLibrary();
  /// ```
  ///
  /// This method will not load associated dart libraries contained in the dynamic
  /// feature module, though it will download the files necessary and subsequent
  /// calls to `loadLibrary()` to load will complete faster.
  static Future<void> installDynamicFeature({@required String? moduleName}) async {
    await SystemChannels.dynamicFeature.invokeMethod<void>(
      'installDynamicFeature',
      { 'loadingUnitId': -1, 'moduleName': moduleName },
    );
  }
  /// Gets the current installation state of the dynamic feature identified by the
  /// [moduleName].
  ///
  /// This method returns a string that represents the state. Depending on
  /// the implementation, this string may vary, but the default Google Play
  /// Store implementation retuns a state in the [DynamicFeatureInstallState] enum.
  ///
  /// Installations of dynamic feature modules may be triggered by either calling
  /// [installDynamicFeature] for assets-only modules or `loadLibrary()` on a deferred
  /// imported library. Modules not yet requested or do not exist will complete with
  /// [DynamicFeatureInstallState.unknown]. Modules previously installed but not
  /// loaded in this session will return [DynamicFeatureInstallState.installedPendingLoad],
  /// which indicates that the installtion request call should be repeated to
  /// complete the loading process.
  ///
  /// Due to the async nature of platform channels and network i/o, newly requested
  /// installs may return null until the installation request has been processed. Thus,
  /// this state information should be used as purely informational and not as an
  /// accurate reflection of the readiness of the dynamic feature. Code and assets
  /// may only be used after the Future completes succesfully, regardless of what
  /// the installation state is in.
  static Future<String?> getDynamicFeatureInstallState({@required String? moduleName}) async {
    await SystemChannels.dynamicFeature.invokeMethod<void>(
      'getDynamicFeatureInstallState',
      { 'loadingUnitId': -1, 'moduleName': moduleName },
    );
  }

  /// Requests that a dynamic feature identified by the [moduleName] be
  /// uninstalled.
  ///
  /// Since uninstallation typically requires significant disk i/o, this method only
  /// signals the intent to uninstall. Actual uninstallation (eg, removal of
  /// assets and files) may occur at a later time. However, once uninstallation
  /// is requested, the dynamic feature should not be used anymore until
  /// [installDynamicFeature] or `loadLibrary()` is called again.
  static Future<void> uninstallDynamicFeature({@required String? moduleName}) async {
    await SystemChannels.dynamicFeature.invokeMethod<void>(
      'uninstallDynamicFeature',
      { 'loadingUnitId': -1, 'moduleName': moduleName },
    );
  }
}
