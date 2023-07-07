// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'errors.dart';
import 'package_config_impl.dart';
import 'package_config_json.dart';

/// A package configuration.
///
/// Associates configuration data to packages and files in packages.
///
/// More members may be added to this class in the future,
/// so classes outside of this package must not implement [PackageConfig]
/// or any subclass of it.
abstract class PackageConfig {
  /// The largest configuration version currently recognized.
  static const int maxVersion = 2;

  /// An empty package configuration.
  ///
  /// A package configuration with no available packages.
  /// Is used as a default value where a package configuration
  /// is expected, but none have been specified or found.
  static const PackageConfig empty = SimplePackageConfig.empty();

  /// Creats a package configuration with the provided available [packages].
  ///
  /// The packages must be valid packages (valid package name, valid
  /// absolute directory URIs, valid language version, if any),
  /// and there must not be two packages with the same name.
  ///
  /// The package's root ([Package.rootUri]) and package-root
  /// ([Package.packageUriRoot]) paths must satisfy a number of constraints
  /// We say that one path (which we know ends with a `/` charater)
  /// is inside another path, if the latter path is a prefix of the former path,
  /// including the two paths being the same.
  ///
  /// * No package's root must be the same as another package's root.
  /// * The package-root of a package must be inside the package's root.
  /// * If one package's package-root is inside another package's root,
  ///   then the latter package's package root must not be inside the former
  ///   package's root. (No getting between a package and its package root!)
  ///   This also disallows a package's root being the same as another
  ///   package's package root.
  ///
  /// If supplied, the [extraData] will be available as the
  /// [PackageConfig.extraData] of the created configuration.
  ///
  /// The version of the resulting configuration is always [maxVersion].
  factory PackageConfig(Iterable<Package> packages, {Object? extraData}) =>
      SimplePackageConfig(maxVersion, packages, extraData);

  /// Parses a package configuration file.
  ///
  /// The [bytes] must be an UTF-8 encoded JSON object
  /// containing a valid package configuration.
  ///
  /// The [baseUri] is used as the base for resolving relative
  /// URI references in the configuration file. If the configuration
  /// has been read from a file, the [baseUri] can be the URI of that
  /// file, or of the directory it occurs in.
  ///
  /// If [onError] is provided, errors found during parsing or building
  /// the configuration are reported by calling [onError] instead of
  /// throwing, and parser makes a *best effort* attempt to continue
  /// despite the error. The input must still be valid JSON.
  /// The result may be [PackageConfig.empty] if there is no way to
  /// extract useful information from the bytes.
  static PackageConfig parseBytes(Uint8List bytes, Uri baseUri,
          {void Function(Object error)? onError}) =>
      parsePackageConfigBytes(bytes, baseUri, onError ?? throwError);

  /// Parses a package configuration file.
  ///
  /// The [configuration] must be a JSON object
  /// containing a valid package configuration.
  ///
  /// The [baseUri] is used as the base for resolving relative
  /// URI references in the configuration file. If the configuration
  /// has been read from a file, the [baseUri] can be the URI of that
  /// file, or of the directory it occurs in.
  ///
  /// If [onError] is provided, errors found during parsing or building
  /// the configuration are reported by calling [onError] instead of
  /// throwing, and parser makes a *best effort* attempt to continue
  /// despite the error. The input must still be valid JSON.
  /// The result may be [PackageConfig.empty] if there is no way to
  /// extract useful information from the bytes.
  static PackageConfig parseString(String configuration, Uri baseUri,
          {void Function(Object error)? onError}) =>
      parsePackageConfigString(configuration, baseUri, onError ?? throwError);

  /// Parses the JSON data of a package configuration file.
  ///
  /// The [configuration] must be a JSON-like Dart data structure,
  /// like the one provided by parsing JSON text using `dart:convert`,
  /// containing a valid package configuration.
  ///
  /// The [baseUri] is used as the base for resolving relative
  /// URI references in the configuration file. If the configuration
  /// has been read from a file, the [baseUri] can be the URI of that
  /// file, or of the directory it occurs in.
  ///
  /// If [onError] is provided, errors found during parsing or building
  /// the configuration are reported by calling [onError] instead of
  /// throwing, and parser makes a *best effort* attempt to continue
  /// despite the error. The input must still be valid JSON.
  /// The result may be [PackageConfig.empty] if there is no way to
  /// extract useful information from the bytes.
  static PackageConfig parseJson(Object? jsonData, Uri baseUri,
          {void Function(Object error)? onError}) =>
      parsePackageConfigJson(jsonData, baseUri, onError ?? throwError);

  /// Writes a configuration file for this configuration on [output].
  ///
  /// If [baseUri] is provided, URI references in the generated file
  /// will be made relative to [baseUri] where possible.
  static void writeBytes(PackageConfig configuration, Sink<Uint8List> output,
      [Uri? baseUri]) {
    writePackageConfigJsonUtf8(configuration, baseUri, output);
  }

  /// Writes a configuration JSON text for this configuration on [output].
  ///
  /// If [baseUri] is provided, URI references in the generated file
  /// will be made relative to [baseUri] where possible.
  static void writeString(PackageConfig configuration, StringSink output,
      [Uri? baseUri]) {
    writePackageConfigJsonString(configuration, baseUri, output);
  }

  /// Converts a configuration to a JSON-like data structure.
  ///
  /// If [baseUri] is provided, URI references in the generated data
  /// will be made relative to [baseUri] where possible.
  static Map<String, Object?> toJson(PackageConfig configuration,
          [Uri? baseUri]) =>
      packageConfigToJson(configuration, baseUri);

  /// The configuration version number.
  ///
  /// Currently this is 1 or 2, where
  /// * Version one is the `.packages` file format and
  /// * Version two is the first `package_config.json` format.
  ///
  /// Instances of this class supports both, and the version
  /// is only useful for detecting which kind of file the configuration
  /// was read from.
  int get version;

  /// All the available packages of this configuration.
  ///
  /// No two of these packages have the same name,
  /// and no two [Package.root] directories overlap.
  Iterable<Package> get packages;

  /// Look up a package by name.
  ///
  /// Returns the [Package] fron [packages] with [packageName] as
  /// [Package.name]. Returns `null` if the package is not available in the
  /// current configuration.
  Package? operator [](String packageName);

  /// Provides the associated package for a specific [file] (or directory).
  ///
  /// Returns a [Package] which contains the [file]'s path, if any.
  /// That is, the [Package.rootUri] directory is a parent directory
  /// of the [file]'s location.
  ///
  /// Returns `null` if the file does not belong to any package.
  Package? packageOf(Uri file);

  /// Resolves a `package:` URI to a non-package URI
  ///
  /// The [packageUri] must be a valid package URI. That means:
  /// * A URI with `package` as scheme,
  /// * with no authority part (`package://...`),
  /// * with a path starting with a valid package name followed by a slash, and
  /// * with no query or fragment part.
  ///
  /// Throws an [ArgumentError] (which also implements [PackageConfigError])
  /// if the package URI is not valid.
  ///
  /// Returns `null` if the package name of [packageUri] is not available
  /// in this package configuration.
  /// Returns the remaining path of the package URI resolved relative to the
  /// [Package.packageUriRoot] of the corresponding package.
  Uri? resolve(Uri packageUri);

  /// The package URI which resolves to [nonPackageUri].
  ///
  /// The [nonPackageUri] must not have any query or fragment part,
  /// and it must not have `package` as scheme.
  /// Throws an [ArgumentError] (which also implements [PackageConfigError])
  /// if the non-package URI is not valid.
  ///
  /// Returns a package URI which [resolve] will convert to [nonPackageUri],
  /// if any such URI exists. Returns `null` if no such package URI exists.
  Uri? toPackageUri(Uri nonPackageUri);

  /// Extra data associated with the package configuration.
  ///
  /// The data may be in any format, depending on who introduced it.
  /// The standard `package_config.json` file storage will only store
  /// JSON-like list/map data structures.
  Object? get extraData;
}

/// Configuration data for a single package.
abstract class Package {
  /// Creates a package with the provided properties.
  ///
  /// The [name] must be a valid package name.
  /// The [root] must be an absolute directory URI, meaning an absolute URI
  /// with no query or fragment path and a path starting and ending with `/`.
  /// The [packageUriRoot], if provided, must be either an absolute
  /// directory URI or a relative URI reference which is then resolved
  /// relative to [root]. It must then also be a subdirectory of [root],
  /// or the same directory, and must end with `/`.
  /// If [languageVersion] is supplied, it must be a valid Dart language
  /// version, which means two decimal integer literals separated by a `.`,
  /// where the integer literals have no leading zeros unless they are
  /// a single zero digit.
  ///
  /// The [relativeRoot] controls whether the [root] is written as
  /// relative to the `package_config.json` file when the package
  /// configuration is written to a file. It defaults to being relative.
  ///
  /// If [extraData] is supplied, it will be available as the
  /// [Package.extraData] of the created package.
  factory Package(String name, Uri root,
          {Uri? packageUriRoot,
          LanguageVersion? languageVersion,
          Object? extraData,
          bool relativeRoot = true}) =>
      SimplePackage.validate(name, root, packageUriRoot, languageVersion,
          extraData, relativeRoot, throwError)!;

  /// The package-name of the package.
  String get name;

  /// The location of the root of the package.
  ///
  /// Is always an absolute URI with no query or fragment parts,
  /// and with a path ending in `/`.
  ///
  /// All files in the [rootUri] directory are considered
  /// part of the package for purposes where that that matters.
  Uri get root;

  /// The root of the files available through `package:` URIs.
  ///
  /// A `package:` URI with [name] as the package name is
  /// resolved relative to this location.
  ///
  /// Is always an absolute URI with no query or fragment part
  /// with a path ending in `/`,
  /// and with a location which is a subdirectory
  /// of the [root], or the same as the [root].
  Uri get packageUriRoot;

  /// The default language version associated with this package.
  ///
  /// Each package may have a default language version associated,
  /// which is the language version used to parse and compile
  /// Dart files in the package.
  /// A package version is defined by two non-negative numbers,
  /// the *major* and *minor* version numbers.
  ///
  /// A package may have no language version associated with it
  /// in the package configuration, in which case tools should
  /// use a default behavior for the package.
  LanguageVersion? get languageVersion;

  /// Extra data associated with the specific package.
  ///
  /// The data may be in any format, depending on who introduced it.
  /// The standard `package_config.json` file storage will only store
  /// JSON-like list/map data structures.
  Object? get extraData;

  /// Whether the [root] URI should be written as relative.
  ///
  /// When the configuration is written to a `package_config.json`
  /// file, the [root] URI can be either relative to the file
  /// location or absolute, controller by this value.
  bool get relativeRoot;
}

/// A language version.
///
/// A language version is represented by two non-negative integers,
/// the [major] and [minor] version numbers.
///
/// If errors during parsing are handled using an `onError` handler,
/// then an *invalid* language version may be represented by an
/// [InvalidLanguageVersion] object.
abstract class LanguageVersion implements Comparable<LanguageVersion> {
  /// The maximal value allowed by [major] and [minor] values;
  static const int maxValue = 0x7FFFFFFF;
  factory LanguageVersion(int major, int minor) {
    RangeError.checkValueInInterval(major, 0, maxValue, 'major');
    RangeError.checkValueInInterval(minor, 0, maxValue, 'major');
    return SimpleLanguageVersion(major, minor, null);
  }

  /// Parses a language version string.
  ///
  /// A valid language version string has the form
  ///
  /// > *decimalNumber* `.` *decimalNumber*
  ///
  /// where a *decimalNumber* is a non-empty sequence of decimal digits
  /// with no unnecessary leading zeros (the decimal number only starts
  /// with a zero digit if that digit is the entire number).
  /// No spaces are allowed in the string.
  ///
  /// If the [source] is valid then it is parsed into a valid
  /// [LanguageVersion] object.
  /// If not, then the [onError] is called with a [FormatException].
  /// If [onError] is not supplied, it defaults to throwing the exception.
  /// If the call does not throw, then an [InvalidLanguageVersion] is returned
  /// containing the original [source].
  static LanguageVersion parse(String source,
          {void Function(Object error)? onError}) =>
      parseLanguageVersion(source, onError ?? throwError);

  /// The major language version.
  ///
  /// A non-negative integer less than 2<sup>31</sup>.
  ///
  /// The value is negative for objects representing *invalid* language
  /// versions ([InvalidLanguageVersion]).
  int get major;

  /// The minor language version.
  ///
  /// A non-negative integer less than 2<sup>31</sup>.
  ///
  /// The value is negative for objects representing *invalid* language
  /// versions ([InvalidLanguageVersion]).
  int get minor;

  /// Compares language versions.
  ///
  /// Two language versions are considered equal if they have the
  /// same major and minor version numbers.
  ///
  /// A language version is greater then another if the former's major version
  /// is greater than the latter's major version, or if they have
  /// the same major version and the former's minor version is greater than
  /// the latter's.
  @override
  int compareTo(LanguageVersion other);

  /// Valid language versions with the same [major] and [minor] values are
  /// equal.
  ///
  /// Invalid language versions ([InvalidLanguageVersion]) are not equal to
  /// any other object.
  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  /// A string representation of the language version.
  ///
  /// A valid language version is represented as
  /// `"${version.major}.${version.minor}"`.
  @override
  String toString();
}

/// An *invalid* language version.
///
/// Stored in a [Package] when the orginal language version string
/// was invalid and a `onError` handler was passed to the parser
/// which did not throw on an error.
abstract class InvalidLanguageVersion implements LanguageVersion {
  /// The value -1 for an invalid language version.
  @override
  int get major;

  /// The value -1 for an invalid language version.
  @override
  int get minor;

  /// An invalid language version is only equal to itself.
  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  /// The original invalid version string.
  @override
  String toString();
}
