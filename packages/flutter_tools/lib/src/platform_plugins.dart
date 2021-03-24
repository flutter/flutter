// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/file_system.dart';

/// Constant for 'pluginClass' key in plugin maps.
const String kPluginClass = 'pluginClass';

/// Constant for 'pluginClass' key in plugin maps.
const String kDartPluginClass = 'dartPluginClass';

/// Marker interface for all platform specific plugin config implementations.
abstract class PluginPlatform {
  const PluginPlatform();

  Map<String, dynamic> toMap();
}

abstract class NativeOrDartPlugin {
  /// Determines whether the plugin has a native implementation or if it's a
  /// Dart-only plugin.
  bool isNative();
}

/// Contains parameters to template an Android plugin.
///
/// The required fields include: [name] of the plugin, [package] of the plugin and
/// the [pluginClass] that will be the entry point to the plugin's native code.
class AndroidPlugin extends PluginPlatform {
  AndroidPlugin({
    required this.name,
    required this.package,
    required this.pluginClass,
    required this.pluginPath,
    required FileSystem fileSystem,
  }) : _fileSystem = fileSystem;

  factory AndroidPlugin.fromYaml(String name, YamlMap yaml, String pluginPath, FileSystem fileSystem) {
    assert(validate(yaml));
    return AndroidPlugin(
      name: name,
      package: yaml['package'] as String,
      pluginClass: yaml['pluginClass'] as String,
      pluginPath: pluginPath,
      fileSystem: fileSystem,
    );
  }

  final FileSystem _fileSystem;

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml['package'] is String && yaml['pluginClass'] is String;
  }

  static const String kConfigKey = 'android';

  /// The plugin name defined in pubspec.yaml.
  final String name;

  /// The plugin package name defined in pubspec.yaml.
  final String package;

  /// The plugin main class defined in pubspec.yaml.
  final String pluginClass;

  /// The absolute path to the plugin in the pub cache.
  final String pluginPath;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'package': package,
      'class': pluginClass,
      // Mustache doesn't support complex types.
      'supportsEmbeddingV1': _supportedEmbedings.contains('1'),
      'supportsEmbeddingV2': _supportedEmbedings.contains('2'),
    };
  }

  Set<String>? _cachedEmbeddingVersion;

  /// Returns the version of the Android embedding.
  Set<String> get _supportedEmbedings => _cachedEmbeddingVersion ??= _getSupportedEmbeddings();

  Set<String> _getSupportedEmbeddings() {
    assert(pluginPath != null);
    final Set<String> supportedEmbeddings = <String>{};
    final String baseMainPath = _fileSystem.path.join(
      pluginPath,
      'android',
      'src',
      'main',
    );

    final List<String> mainClassCandidates = <String>[
      _fileSystem.path.join(
        baseMainPath,
        'java',
        package.replaceAll('.', _fileSystem.path.separator),
        '$pluginClass.java',
      ),
      _fileSystem.path.join(
        baseMainPath,
        'kotlin',
        package.replaceAll('.', _fileSystem.path.separator),
        '$pluginClass.kt',
      )
    ];

    File? mainPluginClass;
    bool mainClassFound = false;
    for (final String mainClassCandidate in mainClassCandidates) {
      mainPluginClass = _fileSystem.file(mainClassCandidate);
      if (mainPluginClass.existsSync()) {
        mainClassFound = true;
        break;
      }
    }
    if (mainPluginClass == null || !mainClassFound) {
      assert(mainClassCandidates.length <= 2);
      throwToolExit(
        "The plugin `$name` doesn't have a main class defined in ${mainClassCandidates.join(' or ')}. "
        "This is likely to due to an incorrect `androidPackage: $package` or `mainClass` entry in the plugin's pubspec.yaml.\n"
        'If you are the author of this plugin, fix the `androidPackage` entry or move the main class to any of locations used above. '
        'Otherwise, please contact the author of this plugin and consider using a different plugin in the meanwhile. '
      );
    }

    final String mainClassContent = mainPluginClass.readAsStringSync();
    if (mainClassContent
        .contains('io.flutter.embedding.engine.plugins.FlutterPlugin')) {
      supportedEmbeddings.add('2');
    } else {
      supportedEmbeddings.add('1');
    }
    if (mainClassContent.contains('PluginRegistry')
        && mainClassContent.contains('registerWith')) {
      supportedEmbeddings.add('1');
    }
    return supportedEmbeddings;
  }
}

/// Contains the parameters to template an iOS plugin.
///
/// The required fields include: [name] of the plugin, the [pluginClass] that
/// will be the entry point to the plugin's native code.
class IOSPlugin extends PluginPlatform {
  const IOSPlugin({
    required this.name,
    required this.classPrefix,
    required this.pluginClass,
  });

  factory IOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml)); // TODO(jonahwilliams): https://github.com/flutter/flutter/issues/67241
    return IOSPlugin(
      name: name,
      classPrefix: '',
      pluginClass: yaml['pluginClass'] as String,
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
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
class MacOSPlugin extends PluginPlatform implements NativeOrDartPlugin {
  const MacOSPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
  });

  factory MacOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    // Treat 'none' as not present. See https://github.com/flutter/flutter/issues/57497.
    String? pluginClass = yaml[kPluginClass] as String;
    if (pluginClass == 'none') {
      pluginClass = null;
    }
    return MacOSPlugin(
      name: name,
      pluginClass: pluginClass,
      dartPluginClass: yaml[kDartPluginClass] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml[kPluginClass] is String || yaml[kDartPluginClass] is String;
  }

  static const String kConfigKey = 'macos';

  final String name;
  final String? pluginClass;
  final String? dartPluginClass;

  @override
  bool isNative() => pluginClass != null;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (pluginClass != null) 'class': pluginClass,
      if (dartPluginClass != null) 'dartPluginClass': dartPluginClass,
    };
  }
}

/// Contains the parameters to template a Windows plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
class WindowsPlugin extends PluginPlatform implements NativeOrDartPlugin{
  const WindowsPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
  }) : assert(pluginClass != null || dartPluginClass != null);

  factory WindowsPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    // Treat 'none' as not present. See https://github.com/flutter/flutter/issues/57497.
    String? pluginClass = yaml[kPluginClass] as String;
    if (pluginClass == 'none') {
      pluginClass = null;
    }
    return WindowsPlugin(
      name: name,
      pluginClass: pluginClass,
      dartPluginClass: yaml[kDartPluginClass] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml[kDartPluginClass] is String || yaml[kPluginClass] is String;
  }

  static const String kConfigKey = 'windows';

  final String name;
  final String? pluginClass;
  final String? dartPluginClass;

  @override
  bool isNative() => pluginClass != null;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (pluginClass != null) 'class': pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      if (dartPluginClass != null) 'dartPluginClass': dartPluginClass,
    };
  }
}

/// Contains the parameters to template a Linux plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
class LinuxPlugin extends PluginPlatform implements NativeOrDartPlugin {
  const LinuxPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
  }) : assert(pluginClass != null || dartPluginClass != null);

  factory LinuxPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    // Treat 'none' as not present. See https://github.com/flutter/flutter/issues/57497.
    String? pluginClass = yaml[kPluginClass] as String;
    if (pluginClass == 'none') {
      pluginClass = null;
    }
    return LinuxPlugin(
      name: name,
      pluginClass: pluginClass,
      dartPluginClass: yaml[kDartPluginClass] as String,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml[kPluginClass] is String || yaml[kDartPluginClass] is String;
  }

  static const String kConfigKey = 'linux';

  final String name;
  final String? pluginClass;
  final String? dartPluginClass;

  @override
  bool isNative() => pluginClass != null;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (pluginClass != null) 'class': pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      if (dartPluginClass != null) 'dartPluginClass': dartPluginClass,
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
    required this.name,
    required this.pluginClass,
    required this.fileName,
  });

  factory WebPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    return WebPlugin(
      name: name,
      pluginClass: yaml['pluginClass'] as String,
      fileName: yaml['fileName'] as String,
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

final RegExp _internalCapitalLetterRegex = RegExp(r'(?=(?!^)[A-Z])');
String _filenameForCppClass(String className) {
  return className.splitMapJoin(
    _internalCapitalLetterRegex,
    onMatch: (_) => '_',
    onNonMatch: (String n) => n.toLowerCase());
}
