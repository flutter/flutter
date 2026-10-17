// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/utils.dart';

/// Constant for 'pluginClass' key in plugin maps.
const kPluginClass = 'pluginClass';

/// Constant for 'dartPluginClass' key in plugin maps.
const kDartPluginClass = 'dartPluginClass';

/// Constant for 'dartPluginFile' key in plugin maps.
const kDartFileName = 'dartFileName';

/// Constant for 'fileName' key in plugin maps.
const kFileName = 'fileName';

/// Constant for 'ffiPlugin' key in plugin maps.
const kFfiPlugin = 'ffiPlugin';

// Constant for 'defaultPackage' key in plugin maps.
const kDefaultPackage = 'default_package';

/// Matches a valid native plugin class or dot-separated package identifier.
///
/// Plugin `class`/`package` values are interpolated verbatim into the generated
/// GeneratedPluginRegistrant source files (Java/Kotlin, Swift, Objective-C,
/// C++). Restricting them to identifier characters prevents a (possibly
/// transitive) dependency from injecting arbitrary native code into the
/// consuming app's build via its pubspec plugin declaration.
final RegExp _pluginIdentifierPattern = RegExp(
  r'^[a-zA-Z_$][a-zA-Z0-9_$]*(\.[a-zA-Z_$][a-zA-Z0-9_$]*)*$',
);

/// Whether [value] is a valid native plugin class or dot-separated package
/// identifier. Callers first confirm the value is a String via the schema type
/// checks; absent fields are not validated here.
bool isValidPluginIdentifier(String value) => _pluginIdentifierPattern.hasMatch(value);

/// Matches a safe relative Dart source path (e.g. `src/foo_web.dart`) ending in
/// `.dart`. Plugin `fileName`/`dartFileName` values are interpolated into an
/// `import` in the generated registrant, so they must not contain quotes,
/// semicolons, whitespace or parent-directory segments.
final RegExp pluginDartFileNamePattern = RegExp(r'^\w[\w./-]*\.dart$');

/// Whether [value] is a safe relative Dart source path for a plugin. Callers
/// first confirm the value is a String via the schema type checks.
bool isValidPluginDartFileName(String value) =>
    pluginDartFileNamePattern.hasMatch(value) && !value.contains('..');

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

  /// The default implementation package defined in pubspec.yaml, if any.
  String? get defaultPackage;

  /// The Dart plugin main class defined in pubspec.yaml, if any.
  String? get dartPluginClass;

  /// Path to file in which dartPluginClass is defined, if any.
  String? get dartFileName;
}

typedef _CommonPlatformFields = ({
  String? pluginClass,
  String? dartPluginClass,
  String? dartFileName,
  bool ffiPlugin,
  String? defaultPackage,
});

sealed class ParseResult<T> {
  factory ParseResult.pass(T value) => ParseResultPass<T>(value: value);
  factory ParseResult.fail(List<String> errors) => ParseResultFail<T>(errors: errors);
}

final class ParseResultPass<T>({required final T value}) implements ParseResult<T>;

final class ParseResultFail<T>({required final List<String> errors}) implements ParseResult<T> {
  this {
    if (errors.isEmpty) {
      throw StateError('The error list must not be empty');
    }
  }
}

/// Helper for extracting and validating fields from a platform plugin [YamlMap].
final class _PluginPlatformYaml {
  _PluginPlatformYaml(this._yaml, {required this.configKey});

  final YamlMap _yaml;
  final String configKey;
  final errors = <String>[];

  void invalid(String reason) {
    errors.add('Invalid "$configKey" plugin specification: $reason');
  }

  String? string(String key, {bool allowNull = true}) {
    final Object? value = _yaml[key];
    if (value is String) {
      return value;
    }
    if (value == null && (allowNull || !_yaml.containsKey(key))) {
      return null;
    }
    invalid('the "$key" field must be a string.');
    return null;
  }

  String? identifier(String key, {bool allowNull = true}) {
    final String? value = string(key, allowNull: allowNull);
    if (value != null && !isValidPluginIdentifier(value)) {
      invalid(
        'the "$key" field must be a valid identifier, optionally with dot-separated segments.',
      );
      return null;
    }
    return value;
  }

  bool flag(String key) {
    final Object? value = _yaml[key];
    if (value is! bool?) {
      invalid('the "$key" field must be a boolean.');
      return false;
    }
    return value ?? false;
  }

  /// Parses the common platform fields from [_yaml].
  _CommonPlatformFields parseCommonFields(String name, {required String displayName}) {
    final String? defaultPackage = string(kDefaultPackage, allowNull: false);
    final String? pluginClass = identifier(kPluginClass);
    final String? dartPluginClass = identifier(kDartPluginClass, allowNull: false);
    final String? dartFileName = string(kDartFileName);
    final bool ffiPlugin = flag(kFfiPlugin);

    if (dartFileName != null) {
      if (_yaml[kDartPluginClass] == null) {
        errors.add(
          '"dartFileName" cannot be specified without "dartPluginClass" in $displayName platform of plugin "$name"',
        );
      }
      if (!isValidPluginDartFileName(dartFileName)) {
        errors.add(
          'The plugin `$name` has an invalid `dartFileName` for platform `$configKey` '
          'in pubspec.yaml.',
        );
      }
    }

    return (
      pluginClass: pluginClass,
      dartPluginClass: dartPluginClass,
      dartFileName: dartFileName,
      ffiPlugin: ffiPlugin,
      defaultPackage: defaultPackage,
    );
  }
}

abstract class DarwinPlugin {
  /// Indicates the iOS and macOS native code is shareable the subdirectory "darwin",
  bool get sharedDarwinSource;
}

/// Contains parameters to template an Android plugin.
///
/// The [name] of the plugin is required. Additionally, either:
/// - [defaultPackage], or
/// - an implementation consisting of:
///   - the [package] and [pluginClass] that will be the entry point to the
///     plugin's native code, and/or
///   - the [dartPluginClass] with optional [dartFileName] that will be
///     the entry point for the plugin's Dart code
/// is required.
class AndroidPlugin extends PluginPlatform implements NativeOrDartPlugin {
  AndroidPlugin({
    required this.name,
    required this.pluginPath,
    this.package,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    this.defaultPackage,
    required this._fileSystem,
  }) : ffiPlugin = ffiPlugin ?? false;

  /// Parses the Android plugin configuration from the given [yaml].
  static ParseResult<AndroidPlugin> parseFromYaml(
    String name,
    YamlMap yaml, {
    required String pluginPath,
    required FileSystem fileSystem,
  }) {
    final parser = _PluginPlatformYaml(yaml, configKey: kConfigKey);
    final _CommonPlatformFields fields = parser.parseCommonFields(name, displayName: 'Android');
    final String? package = parser.identifier('package');

    final bool hasPluginDeclaration =
        (package != null && fields.pluginClass != null) ||
        fields.dartPluginClass != null ||
        fields.ffiPlugin ||
        fields.defaultPackage != null;
    if (!hasPluginDeclaration) {
      parser.invalid(
        'at least one of "package" and "$kPluginClass", "$kDartPluginClass", "$kFfiPlugin: true", or "$kDefaultPackage" must be specified.',
      );
    }

    if (parser.errors.isNotEmpty) {
      return .fail(parser.errors);
    }

    return .pass(
      AndroidPlugin(
        name: name,
        package: package,
        pluginClass: fields.pluginClass,
        dartPluginClass: fields.dartPluginClass,
        dartFileName: fields.dartFileName,
        ffiPlugin: fields.ffiPlugin,
        defaultPackage: fields.defaultPackage,
        pluginPath: pluginPath,
        fileSystem: fileSystem,
      ),
    );
  }

  final FileSystem _fileSystem;

  @override
  bool hasMethodChannel() => pluginClass != null;

  @override
  bool hasFfi() => ffiPlugin;

  @override
  bool hasDart() => dartPluginClass != null;

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

  /// The default implementation package defined in pubspec.yaml, if any.
  @override
  final String? defaultPackage;

  /// The absolute path to the plugin in the pub cache.
  final String pluginPath;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'package': ?package,
      'class': ?pluginClass,
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      kDefaultPackage: ?defaultPackage,
      // Mustache doesn't support complex types.
      'supportsEmbeddingV1': _supportedEmbeddings.contains('1'),
      'supportsEmbeddingV2': _supportedEmbeddings.contains('2'),
    };
  }

  /// Returns the version of the Android embedding.
  late final Set<String> _supportedEmbeddings = _getSupportedEmbeddings();

  Set<String> _getSupportedEmbeddings() {
    final supportedEmbeddings = <String>{};
    final String baseMainPath = _fileSystem.path.join(pluginPath, 'android', 'src', 'main');

    final String? package = this.package;
    // Don't attempt to validate the native code if there isn't supposed to
    // be any.
    if (package == null) {
      return supportedEmbeddings;
    }

    final mainClassCandidates = <String>[
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
    var mainClassFound = false;
    for (final mainClassCandidate in mainClassCandidates) {
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
/// - [defaultPackage], or
/// - an implementation consisting of:
///   - the [classPrefix] (with optional [pluginClass]) that will be the entry
///     point to the plugin's native code, and/or
///   - the [dartPluginClass] with optional [dartFileName] that will be
///     the entry point for the plugin's Dart code
/// is required.
class IOSPlugin extends PluginPlatform implements NativeOrDartPlugin, DarwinPlugin {
  const IOSPlugin({
    required this.name,
    required this.classPrefix,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    this.defaultPackage,
    bool? sharedDarwinSource,
  }) : ffiPlugin = ffiPlugin ?? false,
       sharedDarwinSource = sharedDarwinSource ?? false;

  /// Parses the iOS plugin configuration from the given [yaml].
  static ParseResult<IOSPlugin> parseFromYaml(String name, YamlMap yaml) {
    final parser = _PluginPlatformYaml(yaml, configKey: kConfigKey);
    final _CommonPlatformFields fields = parser.parseCommonFields(name, displayName: 'iOS');
    final bool sharedDarwinSource = parser.flag(kSharedDarwinSource);

    final bool hasPluginDeclaration =
        fields.pluginClass != null ||
        fields.dartPluginClass != null ||
        fields.ffiPlugin ||
        sharedDarwinSource ||
        fields.defaultPackage != null;
    if (!hasPluginDeclaration) {
      parser.invalid(
        'at least one of "$kPluginClass", "$kDartPluginClass", "$kFfiPlugin: true", "$kSharedDarwinSource: true", or "$kDefaultPackage" must be specified.',
      );
    }

    if (parser.errors.isNotEmpty) {
      return .fail(parser.errors);
    }

    return .pass(
      IOSPlugin(
        name: name,
        classPrefix: '',
        pluginClass: fields.pluginClass,
        dartPluginClass: fields.dartPluginClass,
        dartFileName: fields.dartFileName,
        ffiPlugin: fields.ffiPlugin,
        defaultPackage: fields.defaultPackage,
        sharedDarwinSource: sharedDarwinSource,
      ),
    );
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
  @override
  final String? defaultPackage;

  /// Indicates the iOS native code is shareable with macOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "ios".
  @override
  final bool sharedDarwinSource;

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
      'class': ?pluginClass,
      if (pluginClass != null) 'classVar': camelCase(snakeCase('$classPrefix$pluginClass')),
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      if (sharedDarwinSource) kSharedDarwinSource: true,
      kDefaultPackage: ?defaultPackage,
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
class MacOSPlugin extends PluginPlatform implements NativeOrDartPlugin, DarwinPlugin {
  const MacOSPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    this.defaultPackage,
    bool? sharedDarwinSource,
  }) : ffiPlugin = ffiPlugin ?? false,
       sharedDarwinSource = sharedDarwinSource ?? false;

  /// Parses the macOS plugin configuration from the given [yaml].
  static ParseResult<MacOSPlugin> parseFromYaml(String name, YamlMap yaml) {
    final parser = _PluginPlatformYaml(yaml, configKey: kConfigKey);
    final _CommonPlatformFields fields = parser.parseCommonFields(name, displayName: 'macOS');
    final bool sharedDarwinSource = parser.flag(kSharedDarwinSource);

    final bool hasPluginDeclaration =
        fields.pluginClass != null ||
        fields.dartPluginClass != null ||
        fields.ffiPlugin ||
        sharedDarwinSource ||
        fields.defaultPackage != null;
    if (!hasPluginDeclaration) {
      parser.invalid(
        'at least one of "$kPluginClass", "$kDartPluginClass", "$kFfiPlugin: true", "$kSharedDarwinSource: true", or "$kDefaultPackage" must be specified.',
      );
    }

    if (parser.errors.isNotEmpty) {
      return .fail(parser.errors);
    }

    return .pass(
      MacOSPlugin(
        name: name,
        pluginClass: fields.pluginClass,
        dartPluginClass: fields.dartPluginClass,
        dartFileName: fields.dartFileName,
        ffiPlugin: fields.ffiPlugin,
        defaultPackage: fields.defaultPackage,
        sharedDarwinSource: sharedDarwinSource,
      ),
    );
  }

  static const kConfigKey = 'macos';

  final String name;
  final String? pluginClass;
  @override
  final String? dartPluginClass;
  @override
  final String? dartFileName;
  final bool ffiPlugin;
  @override
  final String? defaultPackage;

  /// Indicates the macOS native code is shareable with iOS in
  /// the subdirectory "darwin", otherwise in the subdirectory "macos".
  @override
  final bool sharedDarwinSource;

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
      'class': ?pluginClass,
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      if (sharedDarwinSource) kSharedDarwinSource: true,
      kDefaultPackage: ?defaultPackage,
    };
  }
}

/// Contains the parameters to template a Windows plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
/// [dartFileName] is not required and will be used only if [dartPluginClass]
/// provided.
class WindowsPlugin extends PluginPlatform implements NativeOrDartPlugin, VariantPlatformPlugin {
  const WindowsPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    this.defaultPackage,
    this.variants = const <PluginPlatformVariant>{},
  }) : ffiPlugin = ffiPlugin ?? false,
       assert(
         pluginClass != null ||
             dartPluginClass != null ||
             defaultPackage != null ||
             (ffiPlugin ?? false),
       );

  /// Parses the Windows plugin configuration from the given [yaml].
  static ParseResult<WindowsPlugin> parseFromYaml(String name, YamlMap yaml) {
    final parser = _PluginPlatformYaml(yaml, configKey: kConfigKey);
    final _CommonPlatformFields fields = parser.parseCommonFields(name, displayName: 'Windows');

    final variants = <PluginPlatformVariant>{};
    final Object? variantList = yaml[kSupportedVariants];
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
      parser.invalid('the "$kSupportedVariants" field must be a list of strings.');
    }

    final bool hasPluginDeclaration =
        fields.pluginClass != null ||
        fields.dartPluginClass != null ||
        fields.ffiPlugin ||
        fields.defaultPackage != null;
    if (!hasPluginDeclaration) {
      parser.invalid(
        'at least one of "$kPluginClass", "$kDartPluginClass", "$kFfiPlugin: true", or "$kDefaultPackage" must be specified.',
      );
    }

    if (parser.errors.isNotEmpty) {
      return .fail(parser.errors);
    }

    return .pass(
      WindowsPlugin(
        name: name,
        pluginClass: fields.pluginClass,
        dartPluginClass: fields.dartPluginClass,
        dartFileName: fields.dartFileName,
        ffiPlugin: fields.ffiPlugin,
        defaultPackage: fields.defaultPackage,
        variants: variants,
      ),
    );
  }

  static const kConfigKey = 'windows';

  final String name;
  final String? pluginClass;
  @override
  final String? dartPluginClass;
  @override
  final String? dartFileName;
  final bool ffiPlugin;
  @override
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
      'class': ?pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      kDefaultPackage: ?defaultPackage,
    };
  }
}

/// Contains the parameters to template a Linux plugin.
///
/// The [name] of the plugin is required. Either [dartPluginClass] or [pluginClass] are required.
/// [pluginClass] will be the entry point to the plugin's native code.
/// [dartFileName] is not required and will be used only if [dartPluginClass]
/// provided.
class LinuxPlugin extends PluginPlatform implements NativeOrDartPlugin {
  const LinuxPlugin({
    required this.name,
    this.pluginClass,
    this.dartPluginClass,
    this.dartFileName,
    bool? ffiPlugin,
    this.defaultPackage,
  }) : ffiPlugin = ffiPlugin ?? false,
       assert(
         pluginClass != null ||
             dartPluginClass != null ||
             (ffiPlugin ?? false) ||
             defaultPackage != null,
       );

  /// Parses the Linux plugin configuration from the given [yaml].
  static ParseResult<LinuxPlugin> parseFromYaml(String name, YamlMap yaml) {
    final parser = _PluginPlatformYaml(yaml, configKey: kConfigKey);
    final _CommonPlatformFields fields = parser.parseCommonFields(name, displayName: 'Linux');

    final bool hasPluginDeclaration =
        fields.pluginClass != null ||
        fields.dartPluginClass != null ||
        fields.ffiPlugin ||
        fields.defaultPackage != null;
    if (!hasPluginDeclaration) {
      parser.invalid(
        'at least one of "$kPluginClass", "$kDartPluginClass", "$kFfiPlugin: true", or "$kDefaultPackage" must be specified.',
      );
    }

    if (parser.errors.isNotEmpty) {
      return .fail(parser.errors);
    }

    return .pass(
      LinuxPlugin(
        name: name,
        pluginClass: fields.pluginClass,
        dartPluginClass: fields.dartPluginClass,
        dartFileName: fields.dartFileName,
        ffiPlugin: fields.ffiPlugin,
        defaultPackage: fields.defaultPackage,
      ),
    );
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
      'class': ?pluginClass,
      if (pluginClass != null) 'filename': _filenameForCppClass(pluginClass!),
      kDartPluginClass: ?dartPluginClass,
      kDartFileName: ?dartFileName,
      if (ffiPlugin) kFfiPlugin: true,
      kDefaultPackage: ?defaultPackage,
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
    final errors = <String>[];
    final Object? rawPluginClass = yaml[kPluginClass];
    String? pluginClass;
    if (rawPluginClass is! String) {
      errors.add('The plugin `$name` is missing the required field `pluginClass` in pubspec.yaml');
    } else if (!isValidPluginIdentifier(rawPluginClass)) {
      errors.add('The plugin `$name` has an invalid `pluginClass` in its web plugin declaration.');
    } else {
      pluginClass = rawPluginClass;
    }

    final Object? rawFileName = yaml[kFileName];
    String? fileName;
    if (rawFileName is! String) {
      errors.add('The plugin `$name` is missing the required field `fileName` in pubspec.yaml');
    } else if (!isValidPluginDartFileName(rawFileName)) {
      errors.add('The plugin `$name` has an invalid `fileName` in its web plugin declaration.');
    } else {
      fileName = rawFileName;
    }

    if (errors.isNotEmpty) {
      return .fail(errors);
    }
    return .pass(WebPlugin(name: name, pluginClass: pluginClass!, fileName: fileName!));
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

  @override
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
