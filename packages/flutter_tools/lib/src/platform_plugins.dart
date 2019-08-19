// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Marker interface for all platform specific plugin config impls.
abstract class PlatformPlugin {
  const PlatformPlugin();

  Map<String, dynamic> toMap();
}

/// Contains parameters to template an Android plugin.
///
/// The required fields include: [name] of the plugin, [package] of the plugin and
/// the [pluginClass] that will be the entry point to the plugin's native code.
class AndroidPlugin extends PlatformPlugin {
  const AndroidPlugin({
    @required this.name,
    @required this.package,
    @required this.pluginClass,
  });

  factory AndroidPlugin.fromYaml(String name, YamlMap yaml) {
    assert(yaml != null);
    return AndroidPlugin(
      name: name,
      package: yaml['package'],
      pluginClass: yaml['pluginClass'],
    );
  }

  static const String kConfigKey = 'android';

  final String name;
  final String package;
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'package': package,
      'class': pluginClass,
    };
  }
}

/// Contains the parameters to template an iOS plugin.
///
/// The required fields include: [name] of the plugin, the [pluginClass] that
/// will be the entry point to the plugin's native code. [classPrefix] is required
/// if the plugin is using Objective-C, it is not required for Swift based iOS plugins.
class IOSPlugin extends PlatformPlugin {
  const IOSPlugin({
    @required this.name,
    this.classPrefix,
    @required this.pluginClass,
  });

  factory IOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(yaml != null);
    return IOSPlugin(
      name: name,
      classPrefix: yaml['classPrefix'],
      pluginClass: yaml['pluginClass'],
    );
  }

  static const String kConfigKey = 'ios';

  final String name;
  final String classPrefix;
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'prefix': classPrefix,
      'class': pluginClass,
    };
  }
}

/// Contains the parameters to template a macOS plugin.
///
/// The required fields include: [name] of the plugin, and [pluginClass] that will
/// be the entry point to the plugin's native code.
class MacOSPlugin extends PlatformPlugin {
  const MacOSPlugin({
    @required this.name,
    @required this.pluginClass,
  });

  factory MacOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(yaml != null);
    return MacOSPlugin(
      name: name,
      pluginClass: yaml['pluginClass'],
    );
  }

  static const String kConfigKey = 'macos';

  final String name;
  final String pluginClass;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
    };
  }
}
