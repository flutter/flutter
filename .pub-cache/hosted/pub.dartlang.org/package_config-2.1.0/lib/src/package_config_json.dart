// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Parsing and serialization of package configurations.

import 'dart:convert';
import 'dart:typed_data';

import 'errors.dart';
import 'package_config_impl.dart';
import 'packages_file.dart' as packages_file;
import 'util.dart';

const String _configVersionKey = 'configVersion';
const String _packagesKey = 'packages';
const List<String> _topNames = [_configVersionKey, _packagesKey];
const String _nameKey = 'name';
const String _rootUriKey = 'rootUri';
const String _packageUriKey = 'packageUri';
const String _languageVersionKey = 'languageVersion';
const List<String> _packageNames = [
  _nameKey,
  _rootUriKey,
  _packageUriKey,
  _languageVersionKey
];

const String _generatedKey = 'generated';
const String _generatorKey = 'generator';
const String _generatorVersionKey = 'generatorVersion';

final _jsonUtf8Decoder = json.fuse(utf8).decoder;

PackageConfig parsePackageConfigBytes(
    Uint8List bytes, Uri file, void Function(Object error) onError) {
  // TODO(lrn): Make this simpler. Maybe parse directly from bytes.
  Object? jsonObject;
  try {
    jsonObject = _jsonUtf8Decoder.convert(bytes);
  } on FormatException catch (e) {
    onError(PackageConfigFormatException.from(e));
    return const SimplePackageConfig.empty();
  }
  return parsePackageConfigJson(jsonObject, file, onError);
}

PackageConfig parsePackageConfigString(
    String source, Uri file, void Function(Object error) onError) {
  Object? jsonObject;
  try {
    jsonObject = jsonDecode(source);
  } on FormatException catch (e) {
    onError(PackageConfigFormatException.from(e));
    return const SimplePackageConfig.empty();
  }
  return parsePackageConfigJson(jsonObject, file, onError);
}

/// Creates a [PackageConfig] from a parsed JSON-like object structure.
///
/// The [json] argument must be a JSON object (`Map<String, Object?>`)
/// containing a `"configVersion"` entry with an integer value in the range
/// 1 to [PackageConfig.maxVersion],
/// and with a `"packages"` entry which is a JSON array (`List<Object?>`)
/// containing JSON objects which each has the following properties:
///
/// * `"name"`: The package name as a string.
/// * `"rootUri"`: The root of the package as a URI stored as a string.
/// * `"packageUri"`: Optionally the root of for `package:` URI resolution
///     for the package, as a relative URI below the root URI
///     stored as a string.
/// * `"languageVersion"`: Optionally a language version string which is a
///     an integer numeral, a decimal point (`.`) and another integer numeral,
///     where the integer numeral cannot have a sign, and can only have a
///     leading zero if the entire numeral is a single zero.
///
/// All other properties are stored in [extraData].
///
/// The [baseLocation] is used as base URI to resolve the "rootUri"
/// URI referencestring.
PackageConfig parsePackageConfigJson(
    Object? json, Uri baseLocation, void Function(Object error) onError) {
  if (!baseLocation.hasScheme || baseLocation.isScheme('package')) {
    throw PackageConfigArgumentError(baseLocation.toString(), 'baseLocation',
        'Must be an absolute non-package: URI');
  }

  if (!baseLocation.path.endsWith('/')) {
    baseLocation = baseLocation.resolveUri(Uri(path: '.'));
  }

  String typeName<T>() {
    if (0 is T) return 'int';
    if ('' is T) return 'string';
    if (const [] is T) return 'array';
    return 'object';
  }

  T? checkType<T>(Object? value, String name, [String? packageName]) {
    if (value is T) return value;
    // The only types we are called with are [int], [String], [List<Object?>]
    // and Map<String, Object?>. Recognize which to give a better error message.
    var message =
        "$name${packageName != null ? " of package $packageName" : ""}"
        ' is not a JSON ${typeName<T>()}';
    onError(PackageConfigFormatException(message, value));
    return null;
  }

  Package? parsePackage(Map<String, Object?> entry) {
    String? name;
    String? rootUri;
    String? packageUri;
    String? languageVersion;
    Map<String, Object?>? extraData;
    var hasName = false;
    var hasRoot = false;
    var hasVersion = false;
    entry.forEach((key, value) {
      switch (key) {
        case _nameKey:
          hasName = true;
          name = checkType<String>(value, _nameKey);
          break;
        case _rootUriKey:
          hasRoot = true;
          rootUri = checkType<String>(value, _rootUriKey, name);
          break;
        case _packageUriKey:
          packageUri = checkType<String>(value, _packageUriKey, name);
          break;
        case _languageVersionKey:
          hasVersion = true;
          languageVersion = checkType<String>(value, _languageVersionKey, name);
          break;
        default:
          (extraData ??= {})[key] = value;
          break;
      }
    });
    if (!hasName) {
      onError(PackageConfigFormatException('Missing name entry', entry));
    }
    if (!hasRoot) {
      onError(PackageConfigFormatException('Missing rootUri entry', entry));
    }
    if (name == null || rootUri == null) return null;
    var parsedRootUri = Uri.parse(rootUri!);
    var relativeRoot = !hasAbsolutePath(parsedRootUri);
    var root = baseLocation.resolveUri(parsedRootUri);
    if (!root.path.endsWith('/')) root = root.replace(path: root.path + '/');
    var packageRoot = root;
    if (packageUri != null) packageRoot = root.resolve(packageUri!);
    if (!packageRoot.path.endsWith('/')) {
      packageRoot = packageRoot.replace(path: packageRoot.path + '/');
    }

    LanguageVersion? version;
    if (languageVersion != null) {
      version = parseLanguageVersion(languageVersion, onError);
    } else if (hasVersion) {
      version = SimpleInvalidLanguageVersion('invalid');
    }

    return SimplePackage.validate(
        name!, root, packageRoot, version, extraData, relativeRoot, (error) {
      if (error is ArgumentError) {
        onError(
            PackageConfigFormatException(error.message, error.invalidValue));
      } else {
        onError(error);
      }
    });
  }

  var map = checkType<Map<String, Object?>>(json, 'value');
  if (map == null) return const SimplePackageConfig.empty();
  Map<String, Object?>? extraData;
  List<Package>? packageList;
  int? configVersion;
  map.forEach((key, value) {
    switch (key) {
      case _configVersionKey:
        configVersion = checkType<int>(value, _configVersionKey) ?? 2;
        break;
      case _packagesKey:
        var packageArray = checkType<List<Object?>>(value, _packagesKey) ?? [];
        var packages = <Package>[];
        for (var package in packageArray) {
          var packageMap =
              checkType<Map<String, Object?>>(package, 'package entry');
          if (packageMap != null) {
            var entry = parsePackage(packageMap);
            if (entry != null) {
              packages.add(entry);
            }
          }
        }
        packageList = packages;
        break;
      default:
        (extraData ??= {})[key] = value;
        break;
    }
  });
  if (configVersion == null) {
    onError(PackageConfigFormatException('Missing configVersion entry', json));
    configVersion = 2;
  }
  if (packageList == null) {
    onError(PackageConfigFormatException('Missing packages list', json));
    packageList = [];
  }
  return SimplePackageConfig(configVersion!, packageList!, extraData, (error) {
    if (error is ArgumentError) {
      onError(PackageConfigFormatException(error.message, error.invalidValue));
    } else {
      onError(error);
    }
  });
}

final _jsonUtf8Encoder = JsonUtf8Encoder('  ');

void writePackageConfigJsonUtf8(
    PackageConfig config, Uri? baseUri, Sink<List<int>> output) {
  // Can be optimized.
  var data = packageConfigToJson(config, baseUri);
  output.add(_jsonUtf8Encoder.convert(data) as Uint8List);
}

void writePackageConfigJsonString(
    PackageConfig config, Uri? baseUri, StringSink output) {
  // Can be optimized.
  var data = packageConfigToJson(config, baseUri);
  output.write(JsonEncoder.withIndent('  ').convert(data));
}

Map<String, Object?> packageConfigToJson(PackageConfig config, Uri? baseUri) =>
    <String, Object?>{
      ...?_extractExtraData(config.extraData, _topNames),
      _configVersionKey: PackageConfig.maxVersion,
      _packagesKey: [
        for (var package in config.packages)
          <String, Object?>{
            _nameKey: package.name,
            _rootUriKey: trailingSlash((package.relativeRoot
                    ? relativizeUri(package.root, baseUri)
                    : package.root)
                .toString()),
            if (package.root != package.packageUriRoot)
              _packageUriKey: trailingSlash(
                  relativizeUri(package.packageUriRoot, package.root)
                      .toString()),
            if (package.languageVersion != null &&
                package.languageVersion is! InvalidLanguageVersion)
              _languageVersionKey: package.languageVersion.toString(),
            ...?_extractExtraData(package.extraData, _packageNames),
          }
      ],
    };

void writeDotPackages(PackageConfig config, Uri baseUri, StringSink output) {
  var extraData = config.extraData;
  // Write .packages too.
  String? comment;
  if (extraData is Map<String, Object?>) {
    var generator = extraData[_generatorKey];
    if (generator is String) {
      var generated = extraData[_generatedKey];
      var generatorVersion = extraData[_generatorVersionKey];
      comment = 'Generated by $generator'
          "${generatorVersion is String ? " $generatorVersion" : ""}"
          "${generated is String ? " on $generated" : ""}.";
    }
  }
  packages_file.write(output, config, baseUri: baseUri, comment: comment);
}

/// If "extraData" is a JSON map, then return it, otherwise return null.
///
/// If the value contains any of the [reservedNames] for the current context,
/// entries with that name in the extra data are dropped.
Map<String, Object?>? _extractExtraData(
    Object? data, Iterable<String> reservedNames) {
  if (data is Map<String, Object?>) {
    if (data.isEmpty) return null;
    for (var name in reservedNames) {
      if (data.containsKey(name)) {
        var filteredData = {
          for (var key in data.keys)
            if (!reservedNames.contains(key)) key: data[key]
        };
        if (filteredData.isEmpty) return null;
        for (var value in filteredData.values) {
          if (!_validateJson(value)) return null;
        }
        return filteredData;
      }
    }
    return data;
  }
  return null;
}

/// Checks that the object is a valid JSON-like data structure.
bool _validateJson(Object? object) {
  if (object == null || true == object || false == object) return true;
  if (object is num || object is String) return true;
  if (object is List<Object?>) {
    return object.every(_validateJson);
  }
  if (object is Map<String, Object?>) {
    return object.values.every(_validateJson);
  }
  return false;
}
