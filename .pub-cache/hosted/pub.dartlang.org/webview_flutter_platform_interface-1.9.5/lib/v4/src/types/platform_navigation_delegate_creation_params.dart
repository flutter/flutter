// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Object specifying creation parameters for creating a [PlatformNavigationDelegate].
///
/// Platform specific implementations can add additional fields by extending
/// this class.
///
/// {@tool sample}
/// This example demonstrates how to extend the [PlatformNavigationDelegateCreationParams] to
/// provide additional platform specific parameters.
///
/// When extending [PlatformNavigationDelegateCreationParams] additional
/// parameters should always accept `null` or have a default value to prevent
/// breaking changes.
///
/// ```dart
/// class AndroidNavigationDelegateCreationParams extends PlatformNavigationDelegateCreationParams {
///   AndroidNavigationDelegateCreationParams._(
///     // This parameter prevents breaking changes later.
///     // ignore: avoid_unused_constructor_parameters
///     PlatformNavigationDelegateCreationParams params, {
///     this.filter,
///   }) : super();
///
///   factory AndroidNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
///       PlatformNavigationDelegateCreationParams params, {
///       String? filter,
///   }) {
///     return AndroidNavigationDelegateCreationParams._(params, filter: filter);
///   }
///
///   final String? filter;
/// }
/// ```
/// {@end-tool}
@immutable
class PlatformNavigationDelegateCreationParams {
  /// Used by the platform implementation to create a new [PlatformNavigationkDelegate].
  const PlatformNavigationDelegateCreationParams();
}
