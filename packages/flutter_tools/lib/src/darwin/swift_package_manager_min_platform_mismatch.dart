// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/version.dart';

class SwiftPackageManagerMinPlatformMismatch {
  SwiftPackageManagerMinPlatformMismatch({
    required this.packageProduct,
    required this.requiredMinVersion,
    required this.targetSupportedVersion,
    required this.platformName,
  });

  // Example:
  // "The package product 'cloud-firestore' requires minimum platform version 13.0 for the iOS platform, but this target supports 12.0"
  static final RegExp _pattern = RegExp(
    r"The package product '([^']+)' requires minimum platform version ([0-9]+(?:\.[0-9]+)*) "
    r'for the (iOS|macOS) platform, but this target supports ([0-9]+(?:\.[0-9]+)*)',
    caseSensitive: false,
  );

  static SwiftPackageManagerMinPlatformMismatch? tryParse(String message) {
    final RegExpMatch? match = _pattern.firstMatch(message);
    if (match == null) {
      return null;
    }

    final String packageProduct = match.group(1)!;
    final Version? requiredMinVersion = Version.parse(match.group(2));
    final String platformName = match.group(3)!.toLowerCase();
    final Version? targetSupportedVersion = Version.parse(match.group(4));
    if (requiredMinVersion == null || targetSupportedVersion == null) {
      return null;
    }

    return SwiftPackageManagerMinPlatformMismatch(
      packageProduct: packageProduct,
      requiredMinVersion: requiredMinVersion,
      targetSupportedVersion: targetSupportedVersion,
      platformName: platformName,
    );
  }

  final String packageProduct;
  final Version requiredMinVersion;
  final Version targetSupportedVersion;
  final String platformName;
}

String swiftPackageManagerMinPlatformMismatchInstructions({
  required Version requiredMinVersion,
  required Version supportedVersion,
}) {
  return '''
To fix this error, increase your app's minimum platform version from $supportedVersion to at least $requiredMinVersion or remove this dependency.
To increase your app's minimum platform version:
1. Open your app (ios/Runner.xcworkspace or macos/Runner.xcworkspace) in Xcode.
2. In the Project Navigator, select the Runner project > Runner target > General tab.
3. Increase your app's target Minimum Deployments setting.
4. If you updated your iOS app's Minimum Deployments, regenerate the iOS project's configuration files:
    flutter build ios --config-only
5. If you updated your macOS app's Minimum Deployments, regenerate the macOS project's configuration files:
    flutter build macos --config-only
''';
}
