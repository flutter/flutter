// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Marker interface for all platform specific plugin config impls.
abstract class PluginPlatform {
  const PluginPlatform();

  Map<String, dynamic> toMap();
}

/// Contains parameters to template an Android plugin.
///
/// The required fields include: [name] of the plugin, [package] of the plugin and
/// the [pluginClass] that will be the entry point to the plugin's native code.
class AndroidPlugin extends PluginPlatform {
  const AndroidPlugin({
    @required this.name,
    @required this.package,
    @required this.pluginClass,
  });

  factory AndroidPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return AndroidPlugin(
      name: name,
      package: yaml['package'],
      pluginClass: yaml['pluginClass'],
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['package'] is String && yaml['pluginClass'] is String;
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
/// will be the entry point to the plugin's native code.
class IOSPlugin extends PluginPlatform {
  const IOSPlugin({
    @required this.name,
    this.classPrefix,
    @required this.pluginClass,
  });

  factory IOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return IOSPlugin(
      name: name,
      classPrefix: '',
      pluginClass: yaml['pluginClass'],
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String;
  }

  static const String kConfigKey = 'ios';

  final String name;

  /// Note, this is here only for legacy reasons. Multi-platform format
  /// always sets it to empty String.
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
class MacOSPlugin extends PluginPlatform {
  const MacOSPlugin({
    @required this.name,
    @required this.pluginClass,
  });

  factory MacOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return MacOSPlugin(
      name: name,
      pluginClass: yaml['pluginClass'],
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String;
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

/// Contains the parameters to template a web plugin.
///
/// The required fields include: [name] of the plugin, the [pluginClass] that will
/// be the entry point to the plugin's implementation, and the [fileName]
/// containing the code.
class WebPlugin extends PluginPlatform {
  const WebPlugin({
    @required this.name,
    @required this.pluginClass,
    @required this.fileName,
  });

  factory WebPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return WebPlugin(
      name: name,
      pluginClass: yaml['pluginClass'],
      fileName: yaml['fileName'],
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['pluginClass'] is String && yaml['fileName'] is String;
  }

  static const String kConfigKey = 'web';

  /// The name of the plugin.
  final String name;

  /// The class containing the plugin implementation details.
  ///
  /// This class should have a static `registerWith` method defined.
  final String pluginClass;

  /// The name of the file containing the class implementation above.
  final String fileName;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': pluginClass,
      'file': fileName,
    };
  }
}
