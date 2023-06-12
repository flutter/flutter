// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'id.dart';

class AssetNotFoundException implements Exception {
  final AssetId assetId;

  AssetNotFoundException(this.assetId);

  @override
  String toString() => 'AssetNotFoundException: $assetId';
}

class PackageNotFoundException implements Exception {
  final String name;

  PackageNotFoundException(this.name);

  @override
  String toString() => 'PackageNotFoundException: $name';
}

class InvalidOutputException implements Exception {
  final AssetId assetId;
  final String message;

  InvalidOutputException(this.assetId, this.message);

  @override
  String toString() => 'InvalidOutputException: $assetId\n$message';
}

class InvalidInputException implements Exception {
  /// The invalid asset that couldn't be read.
  final AssetId assetId;

  /// The list of readable globs in the package dependency.
  ///
  /// This includes public files like `lib/` by default, but a package can
  /// choose to allow additional assets via a `build.yaml` file.
  final List<String> allowedGlobs;

  InvalidInputException(this.assetId, {this.allowedGlobs = const ['lib/**']});

  @override
  String toString() {
    final allowedBuffer = StringBuffer();

    for (var i = 0; i < allowedGlobs.length; i++) {
      if (i > 0) {
        if (i == allowedGlobs.length - 1) {
          allowedBuffer.write(' or ');
        } else {
          allowedBuffer.write(', ');
        }
      }

      allowedBuffer.write(allowedGlobs[i]);
    }

    return 'InvalidInputException: $assetId\n'
        'For this package, only assets matching $allowedBuffer can be used as '
        'inputs. \n'
        'A package can mark a file as public by including it in its '
        '`additional_public_assets` in a build.yaml file.';
  }
}

class BuildStepCompletedException implements Exception {
  @override
  String toString() => 'BuildStepCompletedException: '
      'Attempt to use a BuildStep after is has completed';
}

class UnresolvableAssetException implements Exception {
  final String description;

  const UnresolvableAssetException(this.description);

  @override
  String toString() => 'Unresolvable Asset from $description.';
}
