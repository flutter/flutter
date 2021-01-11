// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Default Google Play Store implementation states that reflect the current
/// installation status of a deferred component module.
///
/// Returned by [DeferredComponent.getDeferredComponentInstallState].
///
/// These states may differ in custom deferred component implementations.
///
/// Due to the asynchronous nature of platform channels, these states are
/// informational and should not be depended on to determine if a dynamic
/// feature is ready to use or not. Readiness should be determined by
/// completion of the future returned by
/// [DeferredComponent.installDeferredComponent] or `loadLibrary()`.
///
/// These states are an extension of the states in Android's
/// https://developer.android.com/reference/com/google/android/play/core/splitinstall/model/SplitInstallSessionStatus
///
/// Typical state flow begins as `unknown`, and transitions into `requested`
/// when the installation is begun. When the request is processed, the
/// state changes to `downloading` and finally `installed`. Modules previously
/// installed but not loaded in this session will be in the
/// `installedPendingLoad` state, which indicates that the installation request
/// call (either `loadLibrary()` or [DeferredComponent.installDeferredComponent]) should
/// be repeated to trigger the loading process.
enum DeferredComponentInstallState {
  /// The deferred component installation has been requested, but has not begun
  /// download or installation yet.
  requested,
  /// The deferred component installation is awaiting further action.
  pending,
  /// User input is requried for continued installation.
  requireUserConfirmation,
  /// The deferred component is being downloaded.
  downloading,
  /// The deferred component has finished downloading but has not yet been
  /// installed.
  downloaded,
  /// The downloaded deferred component is being installed.
  installing,
  /// The deferred component has previously been installed and all files/assets
  /// are available, but has not been loaded into the VM in the current
  /// app's session. Either `loadLibrary()` or [DeferredComponent.installDeferredComponent]
  /// should be called to trigger the loading process to ensure the deferred component's
  /// components can be safely used in the app.
  installedPendingLoad,
  /// The deferred component has been succesfully downloaded and installed. Assets and
  /// code from the deferred component are ready to use.
  installed,
  /// An installation request has been asked to be canceled.
  cancelling,
  /// An installation request has been canceled.
  canceled,
  /// An installation request has failed.
  failed,
  /// The deferred component has not been requested nor installed or is unavailable.
  unknown,
}

/// Manages the installation and loading of deferred component modules.
///
/// Deferred components allow Flutter applications to download precompiled AOT
/// dart code and assets at runtime, reducing the install size of apps and
/// avoiding installing unnessecary code/assets on end user devices. Common
/// use cases include deferring installation of advanced or infrequently
/// used features and limiting locale specific features to users of matching
/// locales.
class DeferredComponent {
  // This class is not meant to be instantiated or extended; this constructor
  // prevents instantiation and extension.
  DeferredComponent._();

  // TODO(garyq): We should eventually expand this to install modules by loadingUnitId
  // as well as moduleName, but currently, loadingUnitId is opaque to the dart code
  // so this is not possible. The API has been left flexible to allow adding
  // loadingUnitId as a parameter.

  /// Requests that an assets-only deferred component identified by the [moduleName]
  /// be downloaded and installed.
  ///
  /// This method returns a Future<void> that will complete when the feature is
  /// installed and any assets are ready to be used. When an error occurs, the
  /// future will complete with an error.
  ///
  /// This method should be used for asset-only deferred components or loading just
  /// the assets from a component with both dart code and assets. Deferred components
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
  ///
  /// See also:
  ///
  ///  * [uninstallDeferredComponent], a method to request the uninstall of a component.
  ///  * [loadLibrary](https://api.dart.dev/dart-mirrors/LibraryDependencyMirror/loadLibrary.html),
  ///    the dart method to trigger the installation of the corresponding deferred component that
  ///    contains the dart library.
  ///  * [getDeferredComponentInstallState], a getter that provides the current state
  ///    of a deferred component installation.
  static Future<void> installDeferredComponent({required String moduleName}) async {
    await SystemChannels.deferredComponent.invokeMethod<void>(
      'installDeferredComponent',
      <String, dynamic>{ 'loadingUnitId': -1, 'moduleName': moduleName },
    );
  }
  /// Gets the current installation state of the deferred component identified by the
  /// [moduleName].
  ///
  /// This method returns a string that represents the state. Depending on
  /// the implementation, this string may vary, but the default Google Play
  /// Store implementation retuns a state in the [DeferredComponentInstallState] enum.
  ///
  /// Installations of deferred component modules may be triggered by either calling
  /// [installDeferredComponent] for assets-only modules or `loadLibrary()` on a deferred
  /// imported library. Modules not yet requested or do not exist will complete with
  /// [DeferredComponentInstallState.unknown]. Modules previously installed but not
  /// loaded in this session will return [DeferredComponentInstallState.installedPendingLoad],
  /// which indicates that the installation request call should be repeated to
  /// complete the loading process.
  ///
  /// Due to the async nature of platform channels and network i/o, newly requested
  /// installs may return [DeferredComponentInstallState.unknown] until the installation
  /// request has been processed. Thus, this state information should be used as purely
  /// informational and not as an accurate reflection of the readiness of the deferred
  /// component. Code and assets may only be used after the Future returned by `loadLibrary()`
  /// or [installDeferredComponent] completes succesfully, regardless of what the
  /// installation state is in.
  ///
  /// See also:
  ///
  ///  * [loadLibrary](https://api.dart.dev/dart-mirrors/LibraryDependencyMirror/loadLibrary.html),
  ///    the dart method to trigger the installation of the corresponding deferred component that
  ///    contains the dart library.
  ///  * [installDeferredComponent], a method to install asset-only components.
  static Future<String?> getDeferredComponentInstallState({required String moduleName}) {
    return SystemChannels.deferredComponent.invokeMethod<String>(
      'getDeferredComponentInstallState',
      <String, dynamic>{ 'loadingUnitId': -1, 'moduleName': moduleName },
    );
  }

  /// Requests that a deferred component identified by the [moduleName] be
  /// uninstalled.
  ///
  /// Since uninstallation typically requires significant disk i/o, this method only
  /// signals the intent to uninstall. Completion of the returned future indicates
  /// that the request to uninstall has been registered. Actual uninstallation (eg,
  /// removal of assets and files) may occur at a later time. However, once uninstallation
  /// is requested, the deferred component should not be used anymore until
  /// [installDeferredComponent] or `loadLibrary()` is called again.
  ///
  /// It is safe to request an uninstall when dart code from the component is in use,
  /// but assets from the component should not be used once the component uninstall is
  /// requested. The dart code will remain usable in the app's current session but
  /// is not guaranteed to work in future sessions.
  ///
  /// See also:
  ///
  ///  * [installDeferredComponent], a method to install asset-only components.
  ///  * [loadLibrary](https://api.dart.dev/dart-mirrors/LibraryDependencyMirror/loadLibrary.html),
  ///    the dart method to trigger the installation of the corresponding deferred component that
  ///    contains the dart library.
  static Future<void> uninstallDeferredComponent({required String moduleName}) async {
    await SystemChannels.deferredComponent.invokeMethod<void>(
      'uninstallDeferredComponent',
      <String, dynamic>{ 'loadingUnitId': -1, 'moduleName': moduleName },
    );
  }
}
