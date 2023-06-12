// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper for building `.dart_tool/package_config.json` files.
///
/// See accepted/future-releases/language-versioning/package-config-file-v2.md
/// in https://github.com/dart-lang/language/
class PackageConfigFileBuilder {
  final List<_PackageDescription> _packages = [];

  /// The [rootPath] will be given to `toUriStr` of [toContent] to produce
  /// the corresponding `file://` URI, normally a POSIX path.
  ///
  /// The [packageUri] is optional, a URI reference, resolved against the
  /// file URI of the [rootPath]. The result must be inside the [rootPath].
  void add({
    required String name,
    required String rootPath,
    String packageUri = 'lib/',
    String? languageVersion,
  }) {
    if (_packages.any((e) => e.name == name)) {
      throw StateError('Already added: $name');
    }
    _packages.add(
      _PackageDescription(
        name: name,
        rootPath: rootPath,
        packageUri: packageUri,
        languageVersion: languageVersion,
      ),
    );
  }

  PackageConfigFileBuilder copy() {
    var copy = PackageConfigFileBuilder();
    copy._packages.addAll(_packages);
    return copy;
  }

  String toContent({
    required String Function(String) toUriStr,
  }) {
    var buffer = StringBuffer();

    buffer.writeln('{');

    var prefix = ' ' * 2;
    buffer.writeln('$prefix"configVersion": 2,');
    buffer.writeln('$prefix"packages": [');

    for (var i = 0; i < _packages.length; i++) {
      var package = _packages[i];

      var prefix = ' ' * 4;
      buffer.writeln('$prefix{');

      prefix = ' ' * 6;
      buffer.writeln('$prefix"name": "${package.name}",');

      var rootUri = toUriStr(package.rootPath);
      buffer.write('$prefix"rootUri": "$rootUri"');

      buffer.writeln(',');
      buffer.write('$prefix"packageUri": "${package.packageUri}"');

      if (package.languageVersion != null) {
        buffer.writeln(',');
        buffer.write('$prefix"languageVersion": "${package.languageVersion}"');
      }

      buffer.writeln();

      prefix = ' ' * 4;
      buffer.write(prefix);
      buffer.writeln(i < _packages.length - 1 ? '},' : '}');
    }

    buffer.writeln('  ]');
    buffer.writeln('}');

    return buffer.toString();
  }
}

class _PackageDescription {
  final String name;
  final String rootPath;
  final String packageUri;
  final String? languageVersion;

  _PackageDescription({
    required this.name,
    required this.rootPath,
    required this.packageUri,
    required this.languageVersion,
  });
}
