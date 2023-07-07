// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_api/src/backend/runtime.dart'; // ignore: implementation_imports
import 'package:yaml/yaml.dart';

import './../platform.dart';

/// An interface for [PlatformPlugin]s that support per-platform customization.
///
/// If a [PlatformPlugin] implements this, the user will be able to override the
/// [Runtime]s it supports using the
/// [`override_platforms`][override_platforms] configuration field, and define
/// new runtimes based on them using the [`define_platforms`][define_platforms]
/// field. The custom settings will be passed to the plugin using
/// [customizePlatform].
///
/// [override_platforms]: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md#override_platforms
/// [define_platforms]: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md#define_platforms
///
/// Plugins that implement this **must** support children of recognized runtimes
/// (created by [Runtime.extend]) in their [load] methods.
abstract class CustomizablePlatform<T extends Object> extends PlatformPlugin {
  /// Parses user-provided [settings] for a custom platform into a
  /// plugin-defined format.
  ///
  /// The [settings] come from a user's configuration file. The parsed output
  /// will be passed to [customizePlatform].
  ///
  /// Subclasses should throw [SourceSpanFormatException]s if [settings]
  /// contains invalid configuration. Unrecognized fields should be ignored if
  /// possible.
  T parsePlatformSettings(YamlMap settings);

  /// Merges [settings1] with [settings2] and returns a new settings object that
  /// includes the configuration of both.
  ///
  /// When the settings conflict, [settings2] should take priority.
  ///
  /// This is used to merge global settings with local settings, or a custom
  /// platform's settings with its parent's.
  T mergePlatformSettings(T settings1, T settings2);

  /// Defines user-provided [settings] for [runtime].
  ///
  /// The [runtime] is a runtime this plugin was declared to accept when
  /// registered with [Loader.registerPlatformPlugin], or a runtime whose
  /// [Runtime.parent] is one of those runtimes. Subclasses should customize the
  /// behavior for these runtimes when [loadChannel] or [load] is called with
  /// the given [runtime], using the [settings] which are parsed by
  /// [parsePlatformSettings]. This is guaranteed to be called before either
  /// `load` method.
  void customizePlatform(Runtime runtime, T settings);
}
