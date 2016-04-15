// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Base class for mixins that provide singleton services (also known as
/// "bindings").
///
/// To use this class in a mixin, inherit from it and implement
/// [initInstances()]. The mixin is guaranteed to only be constructed once in
/// the lifetime of the app (more precisely, it will assert if constructed twice
/// in checked mode).
///
/// The top-most layer used to write the application will have a
/// concrete class that inherits from BindingBase and uses all the
/// various BindingBase mixins (such as [Services]). For example, the
/// Widgets library in flutter introduces a binding called
/// [WidgetFlutterBinding]. The relevant library defines how to create
/// the binding. It could be implied (for example,
/// [WidgetFlutterBinding] is automatically started from [runApp]), or
/// the application might be required to explicitly call the
/// constructor.
abstract class BindingBase {
  BindingBase() {
    assert(!_debugInitialized);
    initInstances();
    assert(_debugInitialized);
  }

  static bool _debugInitialized = false;

  /// The initialization method. Subclasses override this method to hook into
  /// the platform and otherwise configure their services. Subclasses must call
  /// "super.initInstances()".
  ///
  /// By convention, if the service is to be provided as a singleton, it should
  /// be exposed as `MixinClassName.instance`, a static getter that returns
  /// `MixinClassName._instance`, a static field that is set by
  /// `initInstances()`.
  void initInstances() {
    assert(() { _debugInitialized = true; return true; });
  }

  @override
  String toString() => '<$runtimeType>';
}
