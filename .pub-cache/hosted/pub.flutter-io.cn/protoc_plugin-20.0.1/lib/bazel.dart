// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Bazel support for protoc_plugin.
library protoc_bazel;

import 'package:path/path.dart' as p;

import 'src/options.dart';
import 'src/output_config.dart';

/// Dart protoc plugin option for Bazel packages.
///
/// This option takes a semicolon-separated list of Bazel package metadata in
/// `package_name|input_root|output_root` form. `input_root` designates the
/// directory relative to which input protos are located -- typically the root
/// of the Bazel package, where the `BUILD` file is located. `output_root`
/// designates the directory relative to which generated `.pb.dart` outputs are
/// emitted -- typically the package's `lib/` directory under the genfiles
/// directory specified by `genfiles_dir` in the Bazel configuration. Generated
/// outputs are emitted at the same path relative to `output_root` as the input
/// proto is found relative to `input_root`.
///
/// For example, using `foo.bar|foo/bar|foo/bar/lib`:
///   * `foo/bar/baz.proto` will generate `foo/bar/lib/baz.pb.dart`
///   * `foo/bar/a/b/baz.proto` will generate `foo/bar/lib/a/b/baz.pb.dart`
const bazelOptionId = 'BazelPackages';

class BazelPackage {
  final String name;
  final String inputRoot;
  final String outputRoot;

  BazelPackage(this.name, String inputRoot, String outputRoot)
      : inputRoot = p.normalize(inputRoot),
        outputRoot = p.normalize(outputRoot);
}

/// Parser for the `BazelPackages` option.
class BazelOptionParser implements SingleOptionParser {
  /// Output map of package input_root to package.
  final Map<String, BazelPackage> output;

  BazelOptionParser(this.output);

  @override
  void parse(String name, String? value, OnError onError) {
    if (value == null) {
      onError('Invalid $bazelOptionId option. Expected a non-empty value.');
      return;
    }

    for (var entry in value.split(';')) {
      var fields = entry.split('|');
      if (fields.length != 3) {
        onError(
            'ERROR: expected package_name|input_root|output_root. Got: $entry');
        continue;
      }
      var pkg = BazelPackage(fields[0], fields[1], fields[2]);
      if (!output.containsKey(pkg.inputRoot)) {
        output[pkg.inputRoot] = pkg;
      } else {
        var prev = output[pkg.inputRoot]!;
        if (pkg.name != prev.name) {
          onError('ERROR: multiple packages with input_root ${pkg.inputRoot}: '
              '${prev.name} and ${pkg.name}');
          continue;
        }
        if (pkg.outputRoot != prev.outputRoot) {
          onError('ERROR: conflicting output_roots for package ${pkg.name}: '
              '${prev.outputRoot} and ${pkg.outputRoot}');
          continue;
        }
      }
    }
  }
}

/// A Dart `package:` URI with package name and path components.
class _PackageUri {
  final String packageName;
  final String path;
  Uri get uri => Uri.parse('package:$packageName/$path');

  _PackageUri(this.packageName, this.path);
}

/// [OutputConfiguration] that uses Bazel layout information to resolve output
/// locations and imports.
class BazelOutputConfiguration extends DefaultOutputConfiguration {
  final Map<String, BazelPackage> packages;

  BazelOutputConfiguration(this.packages);

  /// Search for the most specific Bazel package above [searchPath].
  BazelPackage? _findPackage(String searchPath) {
    var index = searchPath.lastIndexOf('/');
    while (index > 0) {
      searchPath = searchPath.substring(0, index);
      var pkg = packages[searchPath];
      if (pkg != null) return pkg;
      index = searchPath.lastIndexOf('/');
    }
    return null;
  }

  @override
  Uri outputPathFor(Uri inputPath, String extension) {
    var pkg = _findPackage(inputPath.path);
    if (pkg == null) {
      throw ArgumentError('Unable to locate package for input $inputPath.');
    }

    // Bazel package-relative paths.
    var relativeInput = inputPath.path.substring('${pkg.inputRoot}/'.length);
    var base = p.withoutExtension(relativeInput);
    var outputPath = p.join(pkg.outputRoot, '$base$extension');
    return Uri.file(outputPath);
  }

  @override
  Uri resolveImport(Uri target, Uri source, String extension) {
    var targetBase = p.withoutExtension(target.path);
    var targetUri = _packageUriFor('$targetBase$extension');
    var sourceUri = _packageUriFor(source.path);

    if (targetUri == null && sourceUri != null) {
      // We can't reach outside of the lib/ directory of a package without
      // using a package: import. Using a relative import for [target] could
      // break anyone who uses a package: import to load [source].
      throw 'ERROR: cannot generate import for $target from $source.';
    }

    if (targetUri != null && sourceUri?.packageName != targetUri.packageName) {
      return targetUri.uri;
    }

    return super.resolveImport(target, source, extension);
  }

  _PackageUri? _packageUriFor(String target) {
    var pkg = _findPackage(target);
    if (pkg == null) return null;
    var relPath = target.substring(pkg.inputRoot.length + 1);
    return _PackageUri(pkg.name, relPath);
  }
}
