// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'errors.dart';
import 'package_config.dart';
import 'util.dart';

export 'package_config.dart';

const bool _disallowPackagesInsidePackageUriRoot = false;

// Implementations of the main data types exposed by the API of this package.

class SimplePackageConfig implements PackageConfig {
  @override
  final int version;
  final Map<String, Package> _packages;
  final PackageTree _packageTree;
  @override
  final Object? extraData;

  factory SimplePackageConfig(int version, Iterable<Package> packages,
      [Object? extraData, void Function(Object error)? onError]) {
    onError ??= throwError;
    var validVersion = _validateVersion(version, onError);
    var sortedPackages = [...packages]..sort(_compareRoot);
    var packageTree = _validatePackages(packages, sortedPackages, onError);
    return SimplePackageConfig._(validVersion, packageTree,
        {for (var p in packageTree.allPackages) p.name: p}, extraData);
  }

  SimplePackageConfig._(
      this.version, this._packageTree, this._packages, this.extraData);

  /// Creates empty configuration.
  ///
  /// The empty configuration can be used in cases where no configuration is
  /// found, but code expects a non-null configuration.
  ///
  /// The version number is [PackageConfig.maxVersion] to avoid
  /// minimum-version filters discarding the configuration.
  const SimplePackageConfig.empty()
      : version = PackageConfig.maxVersion,
        _packageTree = const EmptyPackageTree(),
        _packages = const <String, Package>{},
        extraData = null;

  static int _validateVersion(
      int version, void Function(Object error) onError) {
    if (version < 0 || version > PackageConfig.maxVersion) {
      onError(PackageConfigArgumentError(version, 'version',
          'Must be in the range 1 to ${PackageConfig.maxVersion}'));
      return 2; // The minimal version supporting a SimplePackageConfig.
    }
    return version;
  }

  static PackageTree _validatePackages(Iterable<Package> originalPackages,
      List<Package> packages, void Function(Object error) onError) {
    var packageNames = <String>{};
    var tree = TriePackageTree();
    for (var originalPackage in packages) {
      SimplePackage? newPackage;
      if (originalPackage is! SimplePackage) {
        // SimplePackage validates these properties.
        newPackage = SimplePackage.validate(
            originalPackage.name,
            originalPackage.root,
            originalPackage.packageUriRoot,
            originalPackage.languageVersion,
            originalPackage.extraData,
            originalPackage.relativeRoot, (error) {
          if (error is PackageConfigArgumentError) {
            onError(PackageConfigArgumentError(packages, 'packages',
                'Package ${newPackage!.name}: ${error.message}'));
          } else {
            onError(error);
          }
        });
        if (newPackage == null) continue;
      } else {
        newPackage = originalPackage;
      }
      var name = newPackage.name;
      if (packageNames.contains(name)) {
        onError(PackageConfigArgumentError(
            name, 'packages', "Duplicate package name '$name'"));
        continue;
      }
      packageNames.add(name);
      tree.add(newPackage, (error) {
        if (error is ConflictException) {
          // There is a conflict with an existing package.
          var existingPackage = error.existingPackage;
          switch (error.conflictType) {
            case ConflictType.sameRoots:
              onError(PackageConfigArgumentError(
                  originalPackages,
                  'packages',
                  'Packages ${newPackage!.name} and ${existingPackage.name} '
                      'have the same root directory: ${newPackage.root}.\n'));
              break;
            case ConflictType.interleaving:
              // The new package is inside the package URI root of the existing
              // package.
              onError(PackageConfigArgumentError(
                  originalPackages,
                  'packages',
                  'Package ${newPackage!.name} is inside the root of '
                      'package ${existingPackage.name}, and the package root '
                      'of ${existingPackage.name} is inside the root of '
                      '${newPackage.name}.\n'
                      '${existingPackage.name} package root: '
                      '${existingPackage.packageUriRoot}\n'
                      '${newPackage.name} root: ${newPackage.root}\n'));
              break;
            case ConflictType.insidePackageRoot:
              onError(PackageConfigArgumentError(
                  originalPackages,
                  'packages',
                  'Package ${newPackage!.name} is inside the package root of '
                      'package ${existingPackage.name}.\n'
                      '${existingPackage.name} package root: '
                      '${existingPackage.packageUriRoot}\n'
                      '${newPackage.name} root: ${newPackage.root}\n'));
              break;
          }
        } else {
          // Any other error.
          onError(error);
        }
      });
    }
    return tree;
  }

  @override
  Iterable<Package> get packages => _packages.values;

  @override
  Package? operator [](String packageName) => _packages[packageName];

  /// Provides the associated package for a specific [file] (or directory).
  ///
  /// Returns a [Package] which contains the [file]'s path.
  /// That is, the [Package.rootUri] directory is a parent directory
  /// of the [file]'s location.
  /// Returns `null` if the file does not belong to any package.
  @override
  Package? packageOf(Uri file) => _packageTree.packageOf(file);

  @override
  Uri? resolve(Uri packageUri) {
    var packageName = checkValidPackageUri(packageUri, 'packageUri');
    return _packages[packageName]?.packageUriRoot.resolveUri(
        Uri(path: packageUri.path.substring(packageName.length + 1)));
  }

  @override
  Uri? toPackageUri(Uri nonPackageUri) {
    if (nonPackageUri.isScheme('package')) {
      throw PackageConfigArgumentError(
          nonPackageUri, 'nonPackageUri', 'Must not be a package URI');
    }
    if (nonPackageUri.hasQuery || nonPackageUri.hasFragment) {
      throw PackageConfigArgumentError(nonPackageUri, 'nonPackageUri',
          'Must not have query or fragment part');
    }
    // Find package that file belongs to.
    var package = _packageTree.packageOf(nonPackageUri);
    if (package == null) return null;
    // Check if it is inside the package URI root.
    var path = nonPackageUri.toString();
    var root = package.packageUriRoot.toString();
    if (_beginsWith(package.root.toString().length, root, path)) {
      var rest = path.substring(root.length);
      return Uri(scheme: 'package', path: '${package.name}/$rest');
    }
    return null;
  }
}

/// Configuration data for a single package.
class SimplePackage implements Package {
  @override
  final String name;
  @override
  final Uri root;
  @override
  final Uri packageUriRoot;
  @override
  final LanguageVersion? languageVersion;
  @override
  final Object? extraData;
  @override
  final bool relativeRoot;

  SimplePackage._(this.name, this.root, this.packageUriRoot,
      this.languageVersion, this.extraData, this.relativeRoot);

  /// Creates a [SimplePackage] with the provided content.
  ///
  /// The provided arguments must be valid.
  ///
  /// If the arguments are invalid then the error is reported by
  /// calling [onError], then the erroneous entry is ignored.
  ///
  /// If [onError] is provided, the user is expected to be able to handle
  /// errors themselves. An invalid [languageVersion] string
  /// will be replaced with the string `"invalid"`. This allows
  /// users to detect the difference between an absent version and
  /// an invalid one.
  ///
  /// Returns `null` if the input is invalid and an approximately valid package
  /// cannot be salvaged from the input.
  static SimplePackage? validate(
      String name,
      Uri root,
      Uri? packageUriRoot,
      LanguageVersion? languageVersion,
      Object? extraData,
      bool relativeRoot,
      void Function(Object error) onError) {
    var fatalError = false;
    var invalidIndex = checkPackageName(name);
    if (invalidIndex >= 0) {
      onError(PackageConfigFormatException(
          'Not a valid package name', name, invalidIndex));
      fatalError = true;
    }
    if (root.isScheme('package')) {
      onError(PackageConfigArgumentError(
          '$root', 'root', 'Must not be a package URI'));
      fatalError = true;
    } else if (!isAbsoluteDirectoryUri(root)) {
      onError(PackageConfigArgumentError(
          '$root',
          'root',
          'In package $name: Not an absolute URI with no query or fragment '
              'with a path ending in /'));
      // Try to recover. If the URI has a scheme,
      // then ensure that the path ends with `/`.
      if (!root.hasScheme) {
        fatalError = true;
      } else if (!root.path.endsWith('/')) {
        root = root.replace(path: root.path + '/');
      }
    }
    if (packageUriRoot == null) {
      packageUriRoot = root;
    } else if (!fatalError) {
      packageUriRoot = root.resolveUri(packageUriRoot);
      if (!isAbsoluteDirectoryUri(packageUriRoot)) {
        onError(PackageConfigArgumentError(
            packageUriRoot,
            'packageUriRoot',
            'In package $name: Not an absolute URI with no query or fragment '
                'with a path ending in /'));
        packageUriRoot = root;
      } else if (!isUriPrefix(root, packageUriRoot)) {
        onError(PackageConfigArgumentError(packageUriRoot, 'packageUriRoot',
            'The package URI root is not below the package root'));
        packageUriRoot = root;
      }
    }
    if (fatalError) return null;
    return SimplePackage._(
        name, root, packageUriRoot, languageVersion, extraData, relativeRoot);
  }
}

/// Checks whether [version] is a valid Dart language version string.
///
/// The format is (as RegExp) `^(0|[1-9]\d+)\.(0|[1-9]\d+)$`.
///
/// Reports a format exception on [onError] if not, or if the numbers
/// are too large (at most 32-bit signed integers).
LanguageVersion parseLanguageVersion(
    String? source, void Function(Object error) onError) {
  var index = 0;
  // Reads a positive decimal numeral. Returns the value of the numeral,
  // or a negative number in case of an error.
  // Starts at [index] and increments the index to the position after
  // the numeral.
  // It is an error if the numeral value is greater than 0x7FFFFFFFF.
  // It is a recoverable error if the numeral starts with leading zeros.
  int readNumeral() {
    const maxValue = 0x7FFFFFFF;
    if (index == source!.length) {
      onError(PackageConfigFormatException('Missing number', source, index));
      return -1;
    }
    var start = index;

    var char = source.codeUnitAt(index);
    var digit = char ^ 0x30;
    if (digit > 9) {
      onError(PackageConfigFormatException('Missing number', source, index));
      return -1;
    }
    var firstDigit = digit;
    var value = 0;
    do {
      value = value * 10 + digit;
      if (value > maxValue) {
        onError(
            PackageConfigFormatException('Number too large', source, start));
        return -1;
      }
      index++;
      if (index == source.length) break;
      char = source.codeUnitAt(index);
      digit = char ^ 0x30;
    } while (digit <= 9);
    if (firstDigit == 0 && index > start + 1) {
      onError(PackageConfigFormatException(
          'Leading zero not allowed', source, start));
    }
    return value;
  }

  var major = readNumeral();
  if (major < 0) {
    return SimpleInvalidLanguageVersion(source);
  }
  if (index == source!.length || source.codeUnitAt(index) != $dot) {
    onError(PackageConfigFormatException("Missing '.'", source, index));
    return SimpleInvalidLanguageVersion(source);
  }
  index++;
  var minor = readNumeral();
  if (minor < 0) {
    return SimpleInvalidLanguageVersion(source);
  }
  if (index != source.length) {
    onError(PackageConfigFormatException(
        'Unexpected trailing character', source, index));
    return SimpleInvalidLanguageVersion(source);
  }
  return SimpleLanguageVersion(major, minor, source);
}

abstract class _SimpleLanguageVersionBase implements LanguageVersion {
  @override
  int compareTo(LanguageVersion other) {
    var result = major.compareTo(other.major);
    if (result != 0) return result;
    return minor.compareTo(other.minor);
  }
}

class SimpleLanguageVersion extends _SimpleLanguageVersionBase {
  @override
  final int major;
  @override
  final int minor;
  String? _source;
  SimpleLanguageVersion(this.major, this.minor, this._source);

  @override
  bool operator ==(Object other) =>
      other is LanguageVersion && major == other.major && minor == other.minor;

  @override
  int get hashCode => (major * 17 ^ minor * 37) & 0x3FFFFFFF;

  @override
  String toString() => _source ??= '$major.$minor';
}

class SimpleInvalidLanguageVersion extends _SimpleLanguageVersionBase
    implements InvalidLanguageVersion {
  final String? _source;
  SimpleInvalidLanguageVersion(this._source);
  @override
  int get major => -1;
  @override
  int get minor => -1;

  @override
  String toString() => _source!;
}

abstract class PackageTree {
  Iterable<Package> get allPackages;
  SimplePackage? packageOf(Uri file);
}

class _PackageTrieNode {
  SimplePackage? package;

  /// Indexed by path segment.
  Map<String, _PackageTrieNode> map = {};
}

/// Packages of a package configuration ordered by root path.
///
/// A package has a root path and a package root path, where the latter
/// contains the files exposed by `package:` URIs.
///
/// A package is said to be inside another package if the root path URI of
/// the latter is a prefix of the root path URI of the former.
///
/// No two packages of a package may have the same root path.
/// The package root path of a package must not be inside another package's
/// root path.
/// Entire other packages are allowed inside a package's root.
class TriePackageTree implements PackageTree {
  /// Indexed by URI scheme.
  final Map<String, _PackageTrieNode> _map = {};

  /// A list of all packages.
  final List<SimplePackage> _packages = [];

  @override
  Iterable<Package> get allPackages sync* {
    for (var package in _packages) {
      yield package;
    }
  }

  bool _checkConflict(_PackageTrieNode node, SimplePackage newPackage,
      void Function(Object error) onError) {
    var existingPackage = node.package;
    if (existingPackage != null) {
      // Trying to add package that is inside the existing package.
      // 1) If it's an exact match it's not allowed (i.e. the roots can't be
      //    the same).
      if (newPackage.root.path.length == existingPackage.root.path.length) {
        onError(ConflictException(
            newPackage, existingPackage, ConflictType.sameRoots));
        return true;
      }
      // 2) The existing package has a packageUriRoot thats inside the
      //    root of the new package.
      if (_beginsWith(0, newPackage.root.toString(),
          existingPackage.packageUriRoot.toString())) {
        onError(ConflictException(
            newPackage, existingPackage, ConflictType.interleaving));
        return true;
      }

      // For internal reasons we allow this (for now). One should still never do
      // it thouh.
      // 3) The new package is inside the packageUriRoot of existing package.
      if (_disallowPackagesInsidePackageUriRoot) {
        if (_beginsWith(0, existingPackage.packageUriRoot.toString(),
            newPackage.root.toString())) {
          onError(ConflictException(
              newPackage, existingPackage, ConflictType.insidePackageRoot));
          return true;
        }
      }
    }
    return false;
  }

  /// Tries to add `newPackage` to the tree.
  ///
  /// Reports a [ConflictException] if the added package conflicts with an
  /// existing package.
  /// It conflicts if its root or package root is the same as an existing
  /// package's root or package root, is between the two, or if it's inside the
  /// package root of an existing package.
  ///
  /// If a conflict is detected between [newPackage] and a previous package,
  /// then [onError] is called with a [ConflictException] object
  /// and the [newPackage] is not added to the tree.
  ///
  /// The packages are added in order of their root path.
  void add(SimplePackage newPackage, void Function(Object error) onError) {
    var root = newPackage.root;
    var node = _map[root.scheme] ??= _PackageTrieNode();
    if (_checkConflict(node, newPackage, onError)) return;
    var segments = root.pathSegments;
    // Notice that we're skipping the last segment as it's always the empty
    // string because roots are directories.
    for (var i = 0; i < segments.length - 1; i++) {
      var path = segments[i];
      node = node.map[path] ??= _PackageTrieNode();
      if (_checkConflict(node, newPackage, onError)) return;
    }
    node.package = newPackage;
    _packages.add(newPackage);
  }

  bool _isMatch(
      String path, _PackageTrieNode node, List<SimplePackage> potential) {
    var currentPackage = node.package;
    if (currentPackage != null) {
      var currentPackageRootLength = currentPackage.root.toString().length;
      if (path.length == currentPackageRootLength) return true;
      var currentPackageUriRoot = currentPackage.packageUriRoot.toString();
      // Is [file] inside the package root of [currentPackage]?
      if (currentPackageUriRoot.length == currentPackageRootLength ||
          _beginsWith(currentPackageRootLength, currentPackageUriRoot, path)) {
        return true;
      }
      potential.add(currentPackage);
    }
    return false;
  }

  @override
  SimplePackage? packageOf(Uri file) {
    var currentTrieNode = _map[file.scheme];
    if (currentTrieNode == null) return null;
    var path = file.toString();
    var potential = <SimplePackage>[];
    if (_isMatch(path, currentTrieNode, potential)) {
      return currentTrieNode.package;
    }
    var segments = file.pathSegments;

    for (var i = 0; i < segments.length - 1; i++) {
      var segment = segments[i];
      currentTrieNode = currentTrieNode!.map[segment];
      if (currentTrieNode == null) break;
      if (_isMatch(path, currentTrieNode, potential)) {
        return currentTrieNode.package;
      }
    }
    if (potential.isEmpty) return null;
    return potential.last;
  }
}

class EmptyPackageTree implements PackageTree {
  const EmptyPackageTree();

  @override
  Iterable<Package> get allPackages => const Iterable<Package>.empty();

  @override
  SimplePackage? packageOf(Uri file) => null;
}

/// Checks whether [longerPath] begins with [parentPath].
///
/// Skips checking the [start] first characters which are assumed to
/// already have been matched.
bool _beginsWith(int start, String parentPath, String longerPath) {
  if (longerPath.length < parentPath.length) return false;
  for (var i = start; i < parentPath.length; i++) {
    if (longerPath.codeUnitAt(i) != parentPath.codeUnitAt(i)) return false;
  }
  return true;
}

enum ConflictType { sameRoots, interleaving, insidePackageRoot }

/// Conflict between packages added to the same configuration.
///
/// The [package] conflicts with [existingPackage] if it has
/// the same root path ([isRootConflict]) or the package URI root path
/// of [existingPackage] is inside the root path of [package]
/// ([isPackageRootConflict]).
class ConflictException {
  /// The existing package that [package] conflicts with.
  final SimplePackage existingPackage;

  /// The package that could not be added without a conflict.
  final SimplePackage package;

  /// Whether the conflict is with the package URI root of [existingPackage].
  final ConflictType conflictType;

  /// Creates a root conflict between [package] and [existingPackage].
  ConflictException(this.package, this.existingPackage, this.conflictType);
}

/// Used for sorting packages by root path.
int _compareRoot(Package p1, Package p2) =>
    p1.root.toString().compareTo(p2.root.toString());
