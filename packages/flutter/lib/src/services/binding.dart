// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Base class for mixins that provide singleton services (also known as
/// "bindings").
///
/// To use this class in a mixin, inherit from it and implement
/// [initInstances()]. The mixin is guaranteed to only be constructed once in
/// the lifetime of the app (more precisely, it will assert if constructed twice
/// in checked mode).
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
}
