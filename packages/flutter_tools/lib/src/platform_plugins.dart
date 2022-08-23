// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/file_system.dart';

/// Constant for 'pluginClass' key in plugin maps.
const String kPluginClass = 'pluginClass';

/// Constant for 'dartPluginClass' key in plugin maps.
const String kDartPluginClass = 'dartPluginClass';

/// Constant for 'ffiPlugin' key in plugin maps.
const String kFfiPlugin = 'ffiPlugin';

// Constant for 'defaultPackage' key in plugin maps.
const String kDefaultPackage = 'default_package';

/// Constant for 'supportedVariants' key in plugin maps.
const String kSupportedVariants = 'supportedVariants';

/// Platform variants that a Windows plugin can support.
enum PluginPlatformVariant {
  /// Win32 variant of Windows.
  win32,
}

/// Marker interface for all platform specific plugin config implementations.
abstract class PluginPlatform {
  const PluginPlatform();

  Map<String, dynamic> toMap();
}

/// A plugin that has platform variants.
abstract class VariantPlatformPlugin {
  /// The platform variants supported by the plugin.
  Set<PluginPlatformVariant> get supportedVariants;
}

abstract class NativeOrDartPlugin {
  /// Determines whether the plugin has a Dart implementation.
  bool hasDart();

  /// Determines whether the plugin has a FFI implementation.
  bool hasFfi();

  /// Determines whether the plugin has a method channel implementation.
  bool hasMethodChannel();
}

/// Contains parameters to template an Android plugin.
///
/// The [name] of the plugin is required. Additionally, either:
/// - [defaultPackage], or
/// - an implementation consisting of:
///   - the [package] and [pluginClass] that will be the entry point to the
///     plugin's native code, and/or
///   - the [dartPluginClass] that will be the entry point for the plugin's
///     Dart code
/// is required.
class AndroidPlugin extends PluginPlatform implements NativeOrDartPlugin {
  AndroidPlugin({
    required this.name,
    required this.pluginPath,
    this.package,
    this.pluginClass,
    this.dartPluginClass,
    bool? ffiPlugin,
    this.defaultPackage,
    required FileSystem fileSystem,
  })  : _fileSystem = fileSystem,
        ffiPlugin = ffiPlugin ?? false;

  factory AndroidPlugin.fromYaml(String name, YamlMap yaml, String pluginPath, FileSystem fileSystem) {
    assert(validate(yaml));
    return AndroidPlugin(
      name: name,
      package: yaml['package'] as String?,
      pluginClass: yaml[kPluginClass] as String?,
      dartPluginClass: yaml[kDartPluginClass] as String?,
      ffiPlugin: yaml[kFfiPlugin] as bool?,
      defaultPackage: yaml[kDefaultPackage] as String?,
      pluginPath: pluginPath,
      fileSystem: fileSystem,
    );
  }

  final FileSystem _fileSystem;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  @override
  bool hasDart() => dartPluginClass != null;

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return (yaml['package'] is String && yaml[kPluginClass] is String) ||
        yaml[kDartPluginClass] is String ||
        yaml[kFfiPlugin] == true ||
        yaml[kDefaultPackage] is String;
  }

  static const String kConfigKey = 'android';

  /// The plugin name defined in pubspec.yaml.
  final String name;

  /// The plugin package name defined in pubspec.yaml.
  final String? package;

  /// The native plugin main class defined in pubspec.yaml, if any.
  final String? pluginClass;

  /// The Dart plugin main class defined in pubspec.yaml, if any.
  final String? dartPluginClass;

  /// Is FFI plugin defined in pubspec.yaml.
  final bool ffiPlugin;

  /// The default implementation package defined in pubspec.yaml, if any.
  final String? defaultPackage;

  /// The absolute path to the plugin in the pub cache.
  final String pluginPath;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (package != null) 'package': package,
      if (pluginClass != null) 'class': pluginClass,
      if (dartPluginClass != null) kDartPluginClass : dartPluginClass,
      if (ffiPlugin) kFfiPlugin: true,
      if (defaultPackage != null) kDefaultPackage : defaultPackage,
      // Mustache doesn't support complex types.
      'supportsEmbeddingV1': _supportedEmbeddings.contains('1'),
      'supportsEmbeddingV2': _supportedEmbeddings.contains('2'),
    };
  }

  /// Returns the version of the Android embedding.
  late final Set<String> _supportedEmbeddings = _getSupportedEmbeddings();

  Set<String> _getSupportedEmbeddings() {
    assert(pluginPath != null);
    final Set<String> supportedEmbeddings = <String>{};
    final String baseMainPath = _fileSystem.path.join(
      pluginPath,
      'android',
      'src',
      'main',
    );

    final String? package = this.package;
    // Don't attempt to validate the native code if there isn't supposed to
    // be any.
    if (package == null) {
      return supportedEmbeddings;
    }

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
      ),
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
/// The [name] of the plugin is required. Additionally, either:
/// - [defaultPackage], or
/// - an implementation consisting of:
///   - the [pluginClass] (with optional [classPrefix]) that will be the entry
///     point to the plugin's native code, and/or
///   - the [dartPluginClass] that will be the entry point for the plugin's
///     Dart code
/// is required.
class IOSPlugin extends PluginPlatform implements NativeOrDartPlugin {
  const IOSPlugin({
    required this.name,
    required this.classPrefix,
    this.pluginClass,
    this.dartPluginClass,
    bool? ffiPlugin,
    this.defaultPackage,
  }) : ffiPlugin = ffiPlugin ?? false;

  factory IOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml)); // TODO(zanderso): https://github.com/flutter/flutter/issues/67241
    return IOSPlugin(
      name: name,
      classPrefix: '',
      pluginClass: yaml[kPluginClass] as String?,
      dartPluginClass: yaml[kDartPluginClass] as String?,
      ffiPlugin: yaml[kFfiPlugin] as bool?,
      defaultPackage: yaml[kDefaultPackage] as String?,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml[kPluginClass] is String ||
        yaml[kDartPluginClass] is String ||
        yaml[kFfiPlugin] == true ||
        yaml[kDefaultPackage] is String;
  }

  static const String kConfigKey = 'ios';

  final String name;

  /// Note, this is here only for legacy reasons. Multi-platform format
  /// always sets it to empty String.
  final String classPrefix;
  final String? pluginClass;
  final String? dartPluginClass;
  final bool ffiPlugin;
  final String? defaultPackage;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  @override
  bool hasDart() => dartPluginClass != null;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'prefix': classPrefix,
      if (pluginClass != null) 'class': pluginClass,
      if (dartPluginClass != null) kDartPluginClass : dartPluginClass,
      if (ffiPlugin) kFfiPlugin: true,
      if (defaultPackage != null) kDefaultPackage : defaultPackage,
    };
  }
}

/// Contains the parameters to template a macOS plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or
/// [pluginClass] or [ffiPlugin] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
class MacOSPlugin extends PluginPlatform implements NativeOrDartPlugin {
  const MacOSPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    bool? ffiPlugin,
    this.defaultPackage,
  }) : ffiPlugin = ffiPlugin ?? false;

  factory MacOSPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    // Treat 'none' as not present. See https://github.com/flutter/flutter/issues/57497.
    String? pluginClass = yaml[kPluginClass] as String?;
    if (pluginClass == 'none') {
      pluginClass = null;
    }
    return MacOSPlugin(
      name: name,
      pluginClass: pluginClass,
      dartPluginClass: yaml[kDartPluginClass] as String?,
      ffiPlugin: yaml[kFfiPlugin] as bool?,
      defaultPackage: yaml[kDefaultPackage] as String?,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml[kPluginClass] is String ||
        yaml[kDartPluginClass] is String ||
        yaml[kFfiPlugin] == true ||
        yaml[kDefaultPackage] is String;
  }

  static const String kConfigKey = 'macos';

  final String name;
  final String? pluginClass;
  final String? dartPluginClass;
  final bool ffiPlugin;
  final String? defaultPackage;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  @override
  bool hasDart() => dartPluginClass != null;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (pluginClass != null) 'class': pluginClass,
      if (dartPluginClass != null) kDartPluginClass: dartPluginClass,
      if (ffiPlugin) kFfiPlugin: true,
      if (defaultPackage != null) kDefaultPackage: defaultPackage,
    };
  }
}

/// Contains the parameters to template a Windows plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
class WindowsPlugin extends PluginPlatform
    implements NativeOrDartPlugin, VariantPlatformPlugin {
  const WindowsPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    bool? ffiPlugin,
    this.defaultPackage,
    this.variants = const <PluginPlatformVariant>{},
  })  : ffiPlugin = ffiPlugin ?? false,
        assert(pluginClass != null || dartPluginClass != null || defaultPackage != null);

  factory WindowsPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    // Treat 'none' as not present. See https://github.com/flutter/flutter/issues/57497.
    String? pluginClass = yaml[kPluginClass] as String?;
    if (pluginClass == 'none') {
      pluginClass = null;
    }
    final Set<PluginPlatformVariant> variants = <PluginPlatformVariant>{};
    final YamlList? variantList = yaml[kSupportedVariants] as YamlList?;
    if (variantList == null) {
      // If no variant list is provided assume Win32 for backward compatibility.
      variants.add(PluginPlatformVariant.win32);
    } else {
      const Map<String, PluginPlatformVariant> variantByName = <String, PluginPlatformVariant>{
        'win32': PluginPlatformVariant.win32,
      };
      for (final String variantName in variantList.cast<String>()) {
        final PluginPlatformVariant? variant = variantByName[variantName];
        if (variant != null) {
          variants.add(variant);
        }
        // Ignore unrecognized variants to make adding new variants in the
        // future non-breaking.
      }
    }
    return WindowsPlugin(
      name: name,
      pluginClass: pluginClass,
      dartPluginClass: yaml[kDartPluginClass] as String?,
      ffiPlugin: yaml[kFfiPlugin] as bool?,
      defaultPackage: yaml[kDefaultPackage] as String?,
      variants: variants,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }

    return yaml[kPluginClass] is String ||
        yaml[kDartPluginClass] is String ||
        yaml[kFfiPlugin] == true ||
        yaml[kDefaultPackage] is String;
  }

  static const String kConfigKey = 'windows';

  final String name;
  final String? pluginClass;
  final String? dartPluginClass;
  final bool ffiPlugin;
  final String? defaultPackage;
  final Set<PluginPlatformVariant> variants;

  @override
  Set<PluginPlatformVariant> get supportedVariants => variants;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  @override
  bool hasDart() => dartPluginClass != null;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (pluginClass != null) 'class': pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      if (dartPluginClass != null) kDartPluginClass: dartPluginClass,
      if (ffiPlugin) kFfiPlugin: true,
      if (defaultPackage != null) kDefaultPackage: defaultPackage,
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
    bool? ffiPlugin,
    this.defaultPackage,
  })  : ffiPlugin = ffiPlugin ?? false,
        assert(pluginClass != null || dartPluginClass != null || (ffiPlugin ?? false) || defaultPackage != null);

  factory LinuxPlugin.fromYaml(String name, YamlMap yaml) {
    assert(validate(yaml));
    // Treat 'none' as not present. See https://github.com/flutter/flutter/issues/57497.
    String? pluginClass = yaml[kPluginClass] as String?;
    if (pluginClass == 'none') {
      pluginClass = null;
    }
    return LinuxPlugin(
      name: name,
      pluginClass: pluginClass,
      dartPluginClass: yaml[kDartPluginClass] as String?,
      ffiPlugin: yaml[kFfiPlugin] as bool?,
      defaultPackage: yaml[kDefaultPackage] as String?,
    );
  }

  static bool validate(YamlMap yaml) {
    if (yaml == null) {
      return false;
    }
    return yaml[kPluginClass] is String ||
        yaml[kDartPluginClass] is String ||
        yaml[kFfiPlugin] == true ||
        yaml[kDefaultPackage] is String;
  }

  static const String kConfigKey = 'linux';

  final String name;
  final String? pluginClass;
  final String? dartPluginClass;
  final bool ffiPlugin;
  final String? defaultPackage;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  @override
  bool hasDart() => dartPluginClass != null;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      if (pluginClass != null) 'class': pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      if (dartPluginClass != null) kDartPluginClass: dartPluginClass,
      if (ffiPlugin) kFfiPlugin: true,
      if (defaultPackage != null) kDefaultPackage: defaultPackage,
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
