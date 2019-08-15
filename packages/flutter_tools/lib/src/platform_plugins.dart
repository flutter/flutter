// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Marker interface for all platform specific plugin config impls.
abstract class PlatformPlugin {
  const PlatformPlugin();

  Map<String, dynamic> toMap();
}

/// Contains all the required parameters to template an Android plugin.
class AndroidPlugin extends PlatformPlugin {
  const AndroidPlugin({
    this.name,
    this.package,
    this.pluginClass,
  });

  factory AndroidPlugin.fromYaml(String name, dynamic yaml) {
    assert(yaml != null);
    return AndroidPlugin(
      name: name,
      package: yaml['package'],
      pluginClass: yaml['pluginClass'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'package': package,
      'class': pluginClass,
    };
  }

  static const String kConfigKey = 'android';

  final String name;
  final String package;
  final String pluginClass;
}

/// Contains all the required parameters to template an iOS plugin.
class IOSPlugin extends PlatformPlugin {
  const IOSPlugin({
    this.name,
    this.classPrefix,
    this.pluginClass,
  });

  factory IOSPlugin.fromYaml(String name, dynamic yaml) {
    assert(yaml != null);
    return IOSPlugin(
      name: name,
      classPrefix: yaml['classPrefix'],
      pluginClass: yaml['pluginClass'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'prefix': classPrefix,
      'class': pluginClass,
    };
  }

  static const String kConfigKey = 'ios';

  final String name;
  final String classPrefix;
  final String pluginClass;
}

/// Contains all the required parameters to template an macOS plugin.
class MacOSPlugin extends PlatformPlugin {
  const MacOSPlugin({
    this.name,
    this.classPrefix,
    this.pluginClass,
  });

  factory MacOSPlugin.fromYaml(String name, dynamic yaml) {
    assert(yaml != null);
    return MacOSPlugin(
      name: name,
      classPrefix: yaml['classPrefix'],
      pluginClass: yaml['pluginClass'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'prefix': classPrefix,
      'class': pluginClass,
    };
  }

  static const String kConfigKey = 'macos';

  final String name;
  final String classPrefix;
  final String pluginClass;
}
