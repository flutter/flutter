// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/utils.dart';
import 'plugin_yaml_parser.dart';

/// Constant for 'pluginClass' key in plugin maps.
const kPluginClass = 'pluginClass';

/// Constant for 'fileName' key in plugin maps.
const kFileName = 'fileName';

/// Constant for 'ffiPlugin' key in plugin maps.
const kFfiPlugin = 'ffiPlugin';

/// Constant for 'sharedDarwinSource' key in plugin maps.
/// Can be set for iOS and macOS plugins.
const kSharedDarwinSource = 'sharedDarwinSource';

/// Constant for 'supportedVariants' key in plugin maps.
const kSupportedVariants = 'supportedVariants';

/// Platform variants that a Windows plugin can support.
enum PluginPlatformVariant {
  /// Win32 variant of Windows.
  win32,
}

/// Marker interface for all platform specific plugin config implementations.
abstract class PluginPlatform {
  const PluginPlatform();
}

/// A plugin that has platform variants.
abstract class VariantPlatformPlugin {
  /// The platform variants supported by the plugin.
  Set<PluginPlatformVariant> get supportedVariants;
}

abstract class NativePlugin {
  /// Determines whether the plugin has a FFI implementation.
  bool hasFfi();

  /// Determines whether the plugin has a method channel implementation.
  bool hasMethodChannel();
}

abstract class DartPlugin {
  /// The Dart plugin main class defined in pubspec.yaml, if any.
  String? get dartPluginClass;

  /// Path to file in which dartPluginClass is defined, if any.
  String? get dartFileName;
}

abstract class DarwinPlugin {
  /// Indicates the iOS and macOS native code is shareable the subdirectory "darwin",
  bool get sharedDarwinSource;
}

/// Contains parameters to template an Android plugin.
///
/// The [name] of the plugin is required. Additionally, either:
/// - the [package] and [pluginClass] that will be the entry point to the
///   plugin's native code, and/or
/// - the [dartPluginClass] with optional [dartFileName] that will be the entry
///   point for the plugin's Dart code
/// is required.
class AndroidPlugin extends PluginPlatform implements NativePlugin, DartPlugin {
  const AndroidPlugin({
    required this.name,
    required this.pluginPath,
    this.package,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
  }) : ffiPlugin = ffiPlugin ?? false;

  /// Parses the Android plugin configuration from the given [yaml].
  ///
  /// Returns `null` as the parsed value if [yaml] does not declare a valid
  /// Android plugin (none of `package` with `pluginClass`, `dartPluginClass`,
  /// or `ffiPlugin: true`).
  static ParseResult<AndroidPlugin?> parseFromYaml(
    String name,
    YamlMap yaml, {
    required String pluginPath,
  }) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.identifier('package'),
      parser.parseDartPluginFields(displayName: 'Android'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      String? package,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      if ((package != null && pluginClass != null) || ffiPlugin || dartPluginFields != null) {
        return AndroidPlugin(
          name: name,
          package: package,
          pluginClass: pluginClass,
          dartPluginClass: dartPluginFields?.dartPluginClass,
          dartFileName: dartPluginFields?.dartFileName,
          ffiPlugin: ffiPlugin,
          pluginPath: pluginPath,
        );
      }
      return null;
    });
  }

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  static const kConfigKey = 'android';

  /// The plugin name defined in pubspec.yaml.
  final String name;

  /// The plugin package name defined in pubspec.yaml.
  final String? package;

  /// The native plugin main class defined in pubspec.yaml, if any.
  final String? pluginClass;

  /// The Dart plugin main class defined in pubspec.yaml, if any.
  @override
  final String? dartPluginClass;

  /// Path to file in which dartPluginClass defined, if any.
  @override
  final String? dartFileName;

  /// Is FFI plugin defined in pubspec.yaml.
  final bool ffiPlugin;

  /// The absolute path to the plugin in the pub cache.
  final String pluginPath;

  Map<String, dynamic> toMap(FileSystem fileSystem) {
    final Set<String> supportedEmbeddings = _getSupportedEmbeddings(fileSystem);
    return <String, dynamic>{
      'name': name,
      'package': ?package,
      'class': ?pluginClass,
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      // Mustache doesn't support complex types.
      'supportsEmbeddingV1': supportedEmbeddings.contains('1'),
      'supportsEmbeddingV2': supportedEmbeddings.contains('2'),
    };
  }

  /// Returns the version of the Android embedding.
  Set<String> _getSupportedEmbeddings(FileSystem fileSystem) {
    final supportedEmbeddings = <String>{};
    final String baseMainPath = fileSystem.path.join(pluginPath, 'android', 'src', 'main');

    final String? package = this.package;
    // Don't attempt to validate the native code if there isn't supposed to
    // be any.
    if (package == null) {
      return supportedEmbeddings;
    }

    final mainClassCandidates = <String>[
      fileSystem.path.join(
        baseMainPath,
        'java',
        package.replaceAll('.', fileSystem.path.separator),
        '$pluginClass.java',
      ),
      fileSystem.path.join(
        baseMainPath,
        'kotlin',
        package.replaceAll('.', fileSystem.path.separator),
        '$pluginClass.kt',
      ),
    ];

    File? mainPluginClass;
    var mainClassFound = false;
    for (final mainClassCandidate in mainClassCandidates) {
      mainPluginClass = fileSystem.file(mainClassCandidate);
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
        'Otherwise, please contact the author of this plugin and consider using a different plugin in the meanwhile. ',
      );
    }

    final String mainClassContent = mainPluginClass.readAsStringSync();
    if (mainClassContent.contains('io.flutter.embedding.engine.plugins.FlutterPlugin')) {
      supportedEmbeddings.add('2');
    } else {
      supportedEmbeddings.add('1');
    }
    if (mainClassContent.contains('PluginRegistry') && mainClassContent.contains('registerWith')) {
      supportedEmbeddings.add('1');
    }
    return supportedEmbeddings;
  }
}

/// Contains the parameters to template an iOS plugin.
///
/// The [name] of the plugin is required. Additionally, either:
/// - the [classPrefix] (with optional [pluginClass]) that will be the entry
///   point to the plugin's native code, and/or
/// - the [dartPluginClass] with optional [dartFileName] that will be the entry
///   point for the plugin's Dart code
/// is required.
class IOSPlugin extends PluginPlatform implements NativePlugin, DartPlugin, DarwinPlugin {
  const IOSPlugin({
    required this.name,
    required this.classPrefix,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    bool? sharedDarwinSource,
  }) : ffiPlugin = ffiPlugin ?? false,
       sharedDarwinSource = sharedDarwinSource ?? false;

  /// Parses the iOS plugin configuration from the given [yaml].
  ///
  /// Returns `null` as the parsed value if [yaml] does not declare a valid
  /// iOS plugin (none of `pluginClass`, `dartPluginClass`, `ffiPlugin: true`,
  /// or `sharedDarwinSource: true`).
  static ParseResult<IOSPlugin?> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.flag(kSharedDarwinSource),
      parser.parseDartPluginFields(displayName: 'iOS'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      bool sharedDarwinSource,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      if (pluginClass != null || ffiPlugin || sharedDarwinSource || dartPluginFields != null) {
        return IOSPlugin(
          name: name,
          classPrefix: '',
          pluginClass: pluginClass,
          dartPluginClass: dartPluginFields?.dartPluginClass,
          dartFileName: dartPluginFields?.dartFileName,
          ffiPlugin: ffiPlugin,
          sharedDarwinSource: sharedDarwinSource,
        );
      }
      return null;
    });
  }

  static const kConfigKey = 'ios';

  final String name;

  /// Note, this is here only for legacy reasons. Multi-platform format
  /// always sets it to empty String.
  final String classPrefix;
  final String? pluginClass;
  @override
  final String? dartPluginClass;
  @override
  final String? dartFileName;
  final bool ffiPlugin;

  /// Indicates the iOS native code is shareable with macOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "ios".
  @override
  final bool sharedDarwinSource;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'prefix': classPrefix,
      'class': ?pluginClass,
      if (pluginClass != null) 'classVar': camelCase(snakeCase('$classPrefix$pluginClass')),
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      if (sharedDarwinSource) kSharedDarwinSource: true,
    };
  }
}

/// Contains the parameters to template a macOS plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or
/// [pluginClass] or [ffiPlugin] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
/// [dartFileName] is not required and will be used only if [dartPluginClass]
/// provided.
class MacOSPlugin extends PluginPlatform implements NativePlugin, DartPlugin, DarwinPlugin {
  const MacOSPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    bool? sharedDarwinSource,
  }) : ffiPlugin = ffiPlugin ?? false,
       sharedDarwinSource = sharedDarwinSource ?? false;

  /// Parses the macOS plugin configuration from the given [yaml].
  ///
  /// Returns `null` as the parsed value if [yaml] does not declare a valid
  /// macOS plugin (none of `pluginClass`, `dartPluginClass`,
  /// `ffiPlugin: true`, or `sharedDarwinSource: true`).
  static ParseResult<MacOSPlugin?> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.flag(kSharedDarwinSource),
      parser.parseDartPluginFields(displayName: 'macOS'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      bool sharedDarwinSource,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      if (pluginClass != null || ffiPlugin || sharedDarwinSource || dartPluginFields != null) {
        return MacOSPlugin(
          name: name,
          pluginClass: pluginClass,
          dartPluginClass: dartPluginFields?.dartPluginClass,
          dartFileName: dartPluginFields?.dartFileName,
          ffiPlugin: ffiPlugin,
          sharedDarwinSource: sharedDarwinSource,
        );
      }
      return null;
    });
  }

  static const kConfigKey = 'macos';

  final String name;
  final String? pluginClass;
  @override
  final String? dartPluginClass;
  @override
  final String? dartFileName;
  final bool ffiPlugin;

  /// Indicates the macOS native code is shareable with iOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "macos".
  @override
  final bool sharedDarwinSource;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': ?pluginClass,
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      if (sharedDarwinSource) kSharedDarwinSource: true,
    };
  }
}

/// Contains the parameters to template a Windows plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
/// [dartFileName] is not required and will be used only if [dartPluginClass]
/// provided.
class WindowsPlugin extends PluginPlatform
    implements NativePlugin, DartPlugin, VariantPlatformPlugin {
  const WindowsPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    this.variants = const <PluginPlatformVariant>{},
  }) : ffiPlugin = ffiPlugin ?? false,
       assert(pluginClass != null || dartPluginClass != null || (ffiPlugin ?? false));

  /// Parses the Windows plugin configuration from the given [yaml].
  ///
  /// Returns `null` as the parsed value if [yaml] does not declare a valid
  /// Windows plugin (none of `pluginClass`, `dartPluginClass`, or
  /// `ffiPlugin: true`).
  static ParseResult<WindowsPlugin?> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    final variants = <PluginPlatformVariant>{};
    final Object? variantList = yaml[kSupportedVariants];
    ParseResult<Set<PluginPlatformVariant>> variantsResult = .pass(variants);
    if (variantList == null) {
      // If no variant list is provided assume Win32 for backward compatibility.
      variants.add(PluginPlatformVariant.win32);
    } else if (variantList is YamlList && variantList.every((Object? e) => e is String)) {
      const variantByName = <String, PluginPlatformVariant>{'win32': PluginPlatformVariant.win32};
      for (final String variantName in variantList.cast<String>()) {
        final PluginPlatformVariant? variant = variantByName[variantName];
        if (variant != null) {
          variants.add(variant);
        }
        // Ignore unrecognized variants to make adding new variants in the
        // future non-breaking.
      }
    } else {
      variantsResult = parser.invalid('the "$kSupportedVariants" field must be a list of strings.');
    }

    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      variantsResult,
      parser.parseDartPluginFields(displayName: 'Windows'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      Set<PluginPlatformVariant> variants,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      if (pluginClass != null || ffiPlugin || dartPluginFields != null) {
        return WindowsPlugin(
          name: name,
          pluginClass: pluginClass,
          dartPluginClass: dartPluginFields?.dartPluginClass,
          dartFileName: dartPluginFields?.dartFileName,
          ffiPlugin: ffiPlugin,
          variants: variants,
        );
      }
      return null;
    });
  }

  static const kConfigKey = 'windows';

  final String name;
  final String? pluginClass;
  @override
  final String? dartPluginClass;
  @override
  final String? dartFileName;
  final bool ffiPlugin;
  final Set<PluginPlatformVariant> variants;

  @override
  Set<PluginPlatformVariant> get supportedVariants => variants;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': ?pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
    };
  }
}

/// Contains the parameters to template a Linux plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
/// [dartFileName] is not required and will be used only if [dartPluginClass]
/// provided.
class LinuxPlugin extends PluginPlatform implements NativePlugin, DartPlugin {
  const LinuxPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
  }) : ffiPlugin = ffiPlugin ?? false,
       assert(pluginClass != null || dartPluginClass != null || (ffiPlugin ?? false));

  /// Parses the Linux plugin configuration from the given [yaml].
  ///
  /// Returns `null` as the parsed value if [yaml] does not declare a valid
  /// Linux plugin (none of `pluginClass`, `dartPluginClass`, or
  /// `ffiPlugin: true`).
  static ParseResult<LinuxPlugin?> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (
      parser.identifier(kPluginClass),
      parser.flag(kFfiPlugin),
      parser.parseDartPluginFields(displayName: 'Linux'),
    ).map((
      String? pluginClass,
      bool ffiPlugin,
      ({String dartPluginClass, String dartFileName})? dartPluginFields,
    ) {
      if (pluginClass != null || ffiPlugin || dartPluginFields != null) {
        return LinuxPlugin(
          name: name,
          pluginClass: pluginClass,
          dartPluginClass: dartPluginFields?.dartPluginClass,
          dartFileName: dartPluginFields?.dartFileName,
          ffiPlugin: ffiPlugin,
        );
      }
      return null;
    });
  }

  static const kConfigKey = 'linux';

  final String name;
  final String? pluginClass;
  @override
  final String? dartPluginClass;
  @override
  final String? dartFileName;
  final bool ffiPlugin;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'class': ?pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
    };
  }
}

/// Contains the parameters to template a web plugin.
///
/// The required fields include: [name] of the plugin, the [pluginClass] that will
/// be the entry point to the plugin's implementation, and the [fileName]
/// containing the code.
class WebPlugin extends PluginPlatform {
  const WebPlugin({required this.name, required this.pluginClass, required this.fileName});

  /// Parses the Web plugin configuration from the given [yaml].
  static ParseResult<WebPlugin> parseFromYaml(String name, YamlMap yaml) {
    final parser = PluginYamlParser(yaml, pluginName: name, configKey: kConfigKey);
    return (parser.requiredIdentifier(kPluginClass), parser.requiredDartFileName(kFileName)).map(
      (String pluginClass, String fileName) =>
          WebPlugin(name: name, pluginClass: pluginClass, fileName: fileName),
    );
  }

  static const kConfigKey = 'web';

  /// The name of the plugin.
  final String name;

  /// The class containing the plugin implementation details.
  ///
  /// This class should have a static `registerWith` method defined.
  final String pluginClass;

  /// The name of the file containing the class implementation above.
  final String fileName;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'name': name, 'class': pluginClass, 'file': fileName};
  }
}

final _internalCapitalLetterRegex = RegExp(r'(?=(?!^)[A-Z])');
String _filenameForCppClass(String className) {
  return className.splitMapJoin(
    _internalCapitalLetterRegex,
    onMatch: (_) => '_',
    onNonMatch: (String n) => n.toLowerCase(),
  );
}
