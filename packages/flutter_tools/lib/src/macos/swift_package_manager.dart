// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/template.dart';
import '../base/version.dart';
import '../build_info.dart';
import '../darwin/darwin.dart';
import '../plugins.dart';
import '../xcode_project.dart';






/// Swift Package Manager is a dependency management solution for iOS and macOS
/// applications.
///
/// See also:
///   * https://www.swift.org/documentation/package-manager/ - documentation on
///     Swift Package Manager.
///   * https://developer.apple.com/documentation/packagedescription/package -
///     documentation on Swift Package Manager manifest file, Package.swift.
class SwiftPackageManager {
  const SwiftPackageManager({
    required Artifacts artifacts,
    required FileSystem fileSystem,
    required TemplateRenderer templateRenderer,
  }) : _artifacts = artifacts,
       _fileSystem = fileSystem,
       _templateRenderer = templateRenderer;

  final Artifacts _artifacts;
  final FileSystem _fileSystem;
  final TemplateRenderer _templateRenderer;

  /// Creates a Swift Package called 'FlutterGeneratedPluginSwiftPackage' that
  /// has dependencies on Flutter plugins that are compatible with Swift
  /// Package Manager.
  Future<void> generatePluginsSwiftPackage(
    List<Plugin> plugins,
    FlutterDarwinPlatform platform,
    XcodeBasedProject project, {
    BuildMode? buildMode,
    bool flutterAsADependency = true,
    Version? deploymentTarget,
  }) async {
    final Directory symlinkDirectory = project.relativeSwiftPackagesDirectory;
    ErrorHandlingFileSystem.deleteIfExists(symlinkDirectory, recursive: true);
    symlinkDirectory.createSync(recursive: true);

    final (
      List<SwiftPackagePackageDependency> packageDependencies,
      List<SwiftPackageTargetDependency> targetDependencies,
    ) = _dependenciesForPlugins(
      plugins: plugins,
      platform: platform,
      symlinkDirectory: symlinkDirectory,
      pathRelativeTo: project.flutterPluginSwiftPackageDirectory.path,
    );

    // If there aren't any Swift Package plugins and the project hasn't been
    // migrated yet, don't generate a Swift package or migrate the app since
    // it's not needed. If the project has already been migrated, regenerate
    // the Package.swift even if there are no dependencies in case there
    // were dependencies previously.
    if (packageDependencies.isEmpty && !project.flutterPluginSwiftPackageInProjectSettings) {
      return;
    }

    // Add Flutter framework Swift package dependency
    if (flutterAsADependency) {
      final (
        SwiftPackagePackageDependency flutterFrameworkPackageDependency,
        SwiftPackageTargetDependency flutterFrameworkTargetDependency,
      ) = _dependencyForFlutterFramework(
        pathRelativeTo: project.flutterPluginSwiftPackageDirectory.path,
        platform: platform,
        project: project,
      );
      packageDependencies.add(flutterFrameworkPackageDependency);
      targetDependencies.add(flutterFrameworkTargetDependency);
    }

    // FlutterGeneratedPluginSwiftPackage must be statically linked to ensure
    // any dynamic dependencies are linked to Runner and prevent undefined symbols.
    final generatedProduct = SwiftPackageProduct(
      name: kFlutterGeneratedPluginSwiftPackageName,
      targets: <String>[kFlutterGeneratedPluginSwiftPackageName],
      libraryType: SwiftPackageLibraryType.static,
    );

    final generatedTarget = SwiftPackageTarget.defaultTarget(
      name: kFlutterGeneratedPluginSwiftPackageName,
      dependencies: targetDependencies,
    );

    final SwiftPackageSupportedPlatform defaultPlatform = platform.supportedPackagePlatform;
    final SwiftPackageSupportedPlatform supportedPlatform;
    if (deploymentTarget != null && deploymentTarget > defaultPlatform.version) {
      supportedPlatform = SwiftPackageSupportedPlatform(
        platform: platform.swiftPackagePlatform,
        version: deploymentTarget,
      );
    } else {
      supportedPlatform = defaultPlatform;
    }

    final pluginsPackage = SwiftPackage(
      manifest: project.flutterPluginSwiftPackageManifest,
      name: kFlutterGeneratedPluginSwiftPackageName,
      platforms: <SwiftPackageSupportedPlatform>[supportedPlatform],
      products: <SwiftPackageProduct>[generatedProduct],
      dependencies: packageDependencies,
      targets: <SwiftPackageTarget>[generatedTarget],
      templateRenderer: _templateRenderer,
    );
    pluginsPackage.createSwiftPackage();
  }

  (List<SwiftPackagePackageDependency>, List<SwiftPackageTargetDependency>)
  _dependenciesForPlugins({
    required List<Plugin> plugins,
    required FlutterDarwinPlatform platform,
    required Directory symlinkDirectory,
    required String pathRelativeTo,
  }) {
    final packageDependencies = <SwiftPackagePackageDependency>[];
    final targetDependencies = <SwiftPackageTargetDependency>[];

    for (final plugin in plugins) {
      final String? pluginSwiftPackageManifestPath = plugin.pluginSwiftPackageManifestPath(
        _fileSystem,
        platform.name,
      );
      String? packagePath = plugin.pluginSwiftPackagePath(_fileSystem, platform.name);
      if (plugin.platforms[platform.name] == null ||
          pluginSwiftPackageManifestPath == null ||
          packagePath == null ||
          !_fileSystem.file(pluginSwiftPackageManifestPath).existsSync()) {
        continue;
      }

      final Link pluginSymlink = symlinkDirectory.childLink(plugin.name);
      ErrorHandlingFileSystem.deleteIfExists(pluginSymlink);
      pluginSymlink.createSync(packagePath);
      packagePath = pluginSymlink.path;
      packagePath = _fileSystem.path.relative(packagePath, from: pathRelativeTo);

      packageDependencies.add(SwiftPackagePackageDependency(name: plugin.name, path: packagePath));

      // The target dependency product name is hyphen separated because it's
      // the dependency's library name, which Swift Package Manager will
      // automatically use as the CFBundleIdentifier if linked dynamically. The
      // CFBundleIdentifier cannot contain underscores.
      targetDependencies.add(
        SwiftPackageTargetDependency.product(
          name: plugin.name.replaceAll('_', '-'),
          packageName: plugin.name,
        ),
      );
    }
    return (packageDependencies, targetDependencies);
  }

  /// Returns Flutter framework dependencies for the `FlutterGeneratedPluginSwiftPackage`.
  (SwiftPackagePackageDependency, SwiftPackageTargetDependency) _dependencyForFlutterFramework({
    required String pathRelativeTo,
    required FlutterDarwinPlatform platform,
    required XcodeBasedProject project,
  }) {
    createFlutterFrameworkSwiftPackage(platform: platform, project: project);
    return (
      SwiftPackagePackageDependency(
        name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
        path: _fileSystem.path.relative(
          project.flutterFrameworkSwiftPackageDirectory.path,
          from: pathRelativeTo,
        ),
      ),
      SwiftPackageTargetDependency.product(
        name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
        packageName: kFlutterGeneratedFrameworkSwiftPackageTargetName,
      ),
    );
  }

  /// Creates a Swift package called [kFlutterGeneratedFrameworkSwiftPackageTargetName] that vends the
  /// Flutter/FlutterMacOS framework as a binary target. The Flutter framework is symlinked within
  /// the package since binary targets must be relative.
  void createFlutterFrameworkSwiftPackage({
    required XcodeBasedProject project,
    required FlutterDarwinPlatform platform,
    BuildMode? buildMode,
  }) {
    final String frameworkName = platform.binaryName;

    _symlinkFlutterFramework(platform: platform, project: project, frameworkName: frameworkName, buildMode: buildMode);
    final flutterFrameworkPackage = SwiftPackage(
      manifest: project.flutterFrameworkSwiftPackageDirectory.childFile('Package.swift'),
      name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
      platforms: <SwiftPackageSupportedPlatform>[],
      products: <SwiftPackageProduct>[
        SwiftPackageProduct(
          name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
          targets: <String>[kFlutterGeneratedFrameworkSwiftPackageTargetName],
        ),
      ],
      dependencies: <SwiftPackagePackageDependency>[],
      targets: <SwiftPackageTarget>[
        SwiftPackageTarget.defaultTarget(
          name: kFlutterGeneratedFrameworkSwiftPackageTargetName,
          dependencies: [SwiftPackageTargetDependency.target(name: frameworkName)],
        ),
        SwiftPackageTarget.binaryTarget(
          name: frameworkName,
          relativePath: '$frameworkName.xcframework',
        ),
      ],
      templateRenderer: _templateRenderer,
    );
    flutterFrameworkPackage.createSwiftPackage();
  }

  /// Creates a subdirectory in [XcodeBasedProject.flutterFrameworkSwiftPackageDirectory] for each
  /// mode in [buildModes] and symlinks the corresponding Flutter/FlutterMacOS xcframework from
  /// the engine artifact cache. Also creates a symlink directly in
  /// [XcodeBasedProject.flutterFrameworkSwiftPackageDirectory] that links to first build mode
  /// subdirectory's xcframework.
  ///
  /// When Xcode builds the project, it'll use the xcframework symlink directly in
  /// [XcodeBasedProject.flutterFrameworkSwiftPackageDirectory]. The symlink is updated during the
  /// build pre-action.
  ///
  /// Example:
  /// ```txt
  /// FlutterFramework/Debug/Flutter.xcframework -> [path to engine cache]/ios/Flutter.xcframework
  /// FlutterFramework/Profile/Flutter.xcframework -> [path to engine cache]/ios-profile/Flutter.xcframework
  /// FlutterFramework/Release/Flutter.xcframework -> [path to engine cache]/ios-release/Flutter.xcframework
  /// FlutterFramework/Flutter.xcframework -> ./Debug/Flutter.xcframework
  /// ```
  void _symlinkFlutterFramework({
    required XcodeBasedProject project,
    required FlutterDarwinPlatform platform,
    required String frameworkName,
    BuildMode? buildMode,
    List<BuildMode>? buildModes,
  }) {
    final List<BuildMode> modesToSymlink = buildMode != null
        ? <BuildMode>[buildMode]
        : buildModes ?? const <BuildMode>[
            BuildMode.debug,
            BuildMode.profile,
            BuildMode.release,
          ];
    for (final mode in modesToSymlink) {
      final String frameworkArtifactPath = _artifacts.getArtifactPath(
        platform.xcframeworkArtifact,
        platform: platform.targetPlatform,
        mode: mode,
      );
      final Directory buildModeDirectory = project.flutterFrameworkSwiftPackageDirectory
          .childDirectory(mode.uppercaseName);
      final Link frameworkLink = _fileSystem.link(
        buildModeDirectory.childDirectory('$frameworkName.xcframework').path,
      );
      frameworkLink.createSync(frameworkArtifactPath, recursive: true);
    }
    updateFlutterFrameworkSymlink(
      buildMode: modesToSymlink.first,
      fileSystem: _fileSystem,
      platform: platform,
      project: project,
      createIfNotFound: true,
    );
  }

  /// Update the symlink for the Flutter framework dependency to use the correct [buildMode].
  static void updateFlutterFrameworkSymlink({
    required BuildMode buildMode,
    required FileSystem fileSystem,
    required FlutterDarwinPlatform platform,
    required XcodeBasedProject project,
    bool createIfNotFound = false,
  }) {
    final String frameworkName = platform.binaryName;
    final Link frameworkLink = fileSystem.link(
      project.flutterFrameworkSwiftPackageDirectory
          .childDirectory('$frameworkName.xcframework')
          .path,
    );
    if (frameworkLink.existsSync()) {
      frameworkLink.updateSync('./${buildMode.uppercaseName}/$frameworkName.xcframework');
    } else if (createIfNotFound) {
      frameworkLink.createSync(
        './${buildMode.uppercaseName}/$frameworkName.xcframework',
        recursive: true,
      );
    }
  }


  /// Ensures that the plugin Swift package is generated and up to date.
  ///
  /// This includes:
  /// 1. Updating the Flutter/FlutterMacOS framework symlink.
  /// 2. Checking if the project's deployment target requires updating the
  ///    plugin package's platform version.
  Future<void> ensurePluginsAreGenerated({
    required XcodeBasedProject project,
    required FlutterDarwinPlatform platform,
    required BuildInfo buildInfo,
    required Map<String, String> buildSettings,
    required List<Plugin> plugins,
  }) async {
    final String? deploymentTarget = buildSettings[platform.deploymentTargetBuildSetting];
    final Version? projectDeploymentTargetVersion = deploymentTarget != null
        ? Version.parse(deploymentTarget)
        : null;

    var generated = false;
    if (projectDeploymentTargetVersion != null &&
        projectDeploymentTargetVersion > platform.supportedPackagePlatform.version &&
        project.flutterPluginSwiftPackageManifest.existsSync()) {
      await generatePluginsSwiftPackage(
        plugins,
        platform,
        project,
        deploymentTarget: projectDeploymentTargetVersion,
        buildMode: buildInfo.mode,
      );
      generated = true;
    }

    if (!generated) {
      _symlinkFlutterFramework(
        platform: platform,
        project: project,
        frameworkName: platform.binaryName,
        buildMode: buildInfo.mode,
      );
    }
  }
}

/// Swift toolchain version included with Xcode 15.0.
const minimumSwiftToolchainVersion = '5.9';

/// The name of the Swift package that's generated by the Flutter tool to add
/// dependencies on Flutter plugin swift packages.
const kFlutterGeneratedPluginSwiftPackageName = 'FlutterGeneratedPluginSwiftPackage';

/// The name of the Swift pacakge that's generated by the Flutter tool to add
/// a dependency on the Flutter/FlutterMacOS framework.
const kFlutterGeneratedFrameworkSwiftPackageTargetName = 'FlutterFramework';

const _swiftPackageTemplate = '''
// swift-tools-version: {{swiftToolsVersion}}
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
//  Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "{{packageName}}",
    {{#platforms}}
    platforms: [
        {{platforms}}
    ],
    {{/platforms}}
    products: [
        {{products}}
    ],
    dependencies: [
        {{dependencies}}
    ],
    targets: [
        {{targets}}
    ]
)
''';

const _swiftPackageSourceTemplate = '''
//
//  Generated file. Do not edit.
//
''';

const _singleIndent = '    ';
const _doubleIndent = '$_singleIndent$_singleIndent';

/// A Swift Package is reusable code that can be shared across projects and
/// with other developers in iOS and macOS applications. A Swift Package
/// requires a Package.swift. This class handles the formatting and creation of
/// a Package.swift.
///
/// See https://developer.apple.com/documentation/packagedescription/package
/// for more information about Swift Packages and Package.swift.
class SwiftPackage {
  SwiftPackage({
    required File manifest,
    required String name,
    required List<SwiftPackageSupportedPlatform> platforms,
    required List<SwiftPackageProduct> products,
    required List<SwiftPackagePackageDependency> dependencies,
    required List<SwiftPackageTarget> targets,
    required TemplateRenderer templateRenderer,
  }) : _manifest = manifest,
       _name = name,
       _platforms = platforms,
       _products = products,
       _dependencies = dependencies,
       _targets = targets,
       _templateRenderer = templateRenderer;

  /// [File] for Package.swift.
  final File _manifest;

  /// The name of the Swift package.
  final String _name;

  /// The list of minimum versions for platforms supported by the package.
  final List<SwiftPackageSupportedPlatform> _platforms;

  /// The list of products that this package vends and that clients can use.
  final List<SwiftPackageProduct> _products;

  /// The list of package dependencies.
  final List<SwiftPackagePackageDependency> _dependencies;

  /// The list of targets that are part of this package.
  final List<SwiftPackageTarget> _targets;

  final TemplateRenderer _templateRenderer;

  /// Context for the [_swiftPackageTemplate] template.
  Map<String, Object> get _templateContext => <String, Object>{
    'swiftToolsVersion': minimumSwiftToolchainVersion,
    'packageName': _name,
    // Supported platforms can't be empty, so only include if not null.
    'platforms': _formatPlatforms() ?? false,
    'products': _formatProducts(),
    'dependencies': _formatDependencies(),
    'targets': _formatTargets(),
  };

  /// Create a Package.swift using settings from [_templateContext].
  void createSwiftPackage() {
    // Swift Packages require at least one source file per non-binary target,
    // whether it be in Swift or Objective C. If the target does not have any
    // files yet, create an empty Swift file.
    for (final SwiftPackageTarget target in _targets) {
      if (target.targetType == SwiftPackageTargetType.binaryTarget) {
        continue;
      }
      final Directory targetDirectory = _manifest.parent
          .childDirectory('Sources')
          .childDirectory(target.name);
      if (!targetDirectory.existsSync() || targetDirectory.listSync().isEmpty) {
        final File requiredSwiftFile = targetDirectory.childFile('${target.name}.swift');
        requiredSwiftFile.createSync(recursive: true);
        requiredSwiftFile.writeAsStringSync(_swiftPackageSourceTemplate);
      }
    }

    final String renderedTemplate = _templateRenderer.renderString(
      _swiftPackageTemplate,
      _templateContext,
    );
    _manifest.createSync(recursive: true);
    _manifest.writeAsStringSync(renderedTemplate);
  }

  String? _formatPlatforms() {
    if (_platforms.isEmpty) {
      return null;
    }
    final List<String> platformStrings = _platforms
        .map((SwiftPackageSupportedPlatform platform) => platform.format())
        .toList();
    return platformStrings.join(',\n$_doubleIndent');
  }

  String _formatProducts() {
    if (_products.isEmpty) {
      return '';
    }
    final List<String> libraries = _products
        .map((SwiftPackageProduct product) => product.format())
        .toList();
    return libraries.join(',\n$_doubleIndent');
  }

  String _formatDependencies() {
    if (_dependencies.isEmpty) {
      return '';
    }
    final List<String> packages = _dependencies
        .map((SwiftPackagePackageDependency dependency) => dependency.format())
        .toList();
    return packages.join(',\n$_doubleIndent');
  }

  String _formatTargets() {
    if (_targets.isEmpty) {
      return '';
    }
    final List<String> targetList = _targets
        .map((SwiftPackageTarget target) => target.format())
        .toList();
    return targetList.join(',\n$_doubleIndent');
  }
}

enum SwiftPackagePlatform {
  ios(displayName: '.iOS'),
  macos(displayName: '.macOS'),
  tvos(displayName: '.tvOS'),
  watchos(displayName: '.watchOS');

  const SwiftPackagePlatform({required this.displayName});

  final String displayName;
}

/// A platform that the Swift package supports.
///
/// Representation of SupportedPlatform from
/// https://developer.apple.com/documentation/packagedescription/supportedplatform.
class SwiftPackageSupportedPlatform {
  SwiftPackageSupportedPlatform({required this.platform, required this.version});

  final SwiftPackagePlatform platform;
  final Version version;

  String format() {
    // platforms: [
    //     .macOS("10.15"),
    //     .iOS("13.0"),
    // ],
    return '${platform.displayName}("$version")';
  }

  static SwiftPackageSupportedPlatform? fromJson(Map<String, Object?> json) {
    if (json case {
      'platformName': final String platformName,
      'version': final String versionString,
    }) {
      final Version? parsedVersion = Version.parse(versionString);
      if (parsedVersion != null) {
        switch (platformName) {
          case 'ios':
            return SwiftPackageSupportedPlatform(platform: .ios, version: parsedVersion);
          case 'macos':
            return SwiftPackageSupportedPlatform(platform: .macos, version: parsedVersion);
        }
      }
    }
    return null;
  }
}

/// Types of library linking.
///
/// Representation of Product.Library.LibraryType from
/// https://developer.apple.com/documentation/packagedescription/product/library/librarytype.
enum SwiftPackageLibraryType {
  dynamic(name: '.dynamic'),
  static(name: '.static');

  const SwiftPackageLibraryType({required this.name});

  final String name;
}

/// An externally visible build artifact that's available to clients of the
/// package.
///
/// Representation of Product from
/// https://developer.apple.com/documentation/packagedescription/product.
class SwiftPackageProduct {
  SwiftPackageProduct({required this.name, required this.targets, this.libraryType});

  final String name;
  final SwiftPackageLibraryType? libraryType;
  final List<String> targets;

  String format() {
    // products: [
    //     .library(name: "FlutterGeneratedPluginSwiftPackage", targets: ["FlutterGeneratedPluginSwiftPackage"]),
    //     .library(name: "FlutterDependenciesPackage", type: .dynamic, targets: ["FlutterDependenciesPackage"]),
    // ],
    var targetsString = '';
    if (targets.isNotEmpty) {
      final List<String> quotedTargets = targets.map((String target) => '"$target"').toList();
      targetsString = ', targets: [${quotedTargets.join(', ')}]';
    }
    var libraryTypeString = '';
    if (libraryType != null) {
      libraryTypeString = ', type: ${libraryType!.name}';
    }
    return '.library(name: "$name"$libraryTypeString$targetsString)';
  }
}

/// A package dependency of a Swift package.
///
/// Representation of Package.Dependency from
/// https://developer.apple.com/documentation/packagedescription/package/dependency.
class SwiftPackagePackageDependency {
  SwiftPackagePackageDependency({required this.name, required this.path});

  final String name;
  final String path;

  String format() {
    // dependencies: [
    //     .package(name: "image_picker_ios", path: "/path/to/packages/image_picker/image_picker_ios/ios/image_picker_ios"),
    // ],
    return '.package(name: "$name", path: "$path")';
  }
}

/// Type of Target constructor.
///
/// See https://developer.apple.com/documentation/packagedescription/target for
/// more information.
enum SwiftPackageTargetType {
  target(name: '.target'),
  binaryTarget(name: '.binaryTarget');

  const SwiftPackageTargetType({required this.name});

  final String name;
}

/// A building block of a Swift Package that contains a set of source files
/// that Swift Package Manager compiles into a module.
///
/// Representation of Target from
/// https://developer.apple.com/documentation/packagedescription/target.
class SwiftPackageTarget {
  SwiftPackageTarget.defaultTarget({required this.name, this.dependencies})
    : path = null,
      targetType = SwiftPackageTargetType.target;

  SwiftPackageTarget.binaryTarget({required this.name, required String relativePath})
    : path = relativePath,
      dependencies = null,
      targetType = SwiftPackageTargetType.binaryTarget;

  final String name;
  final String? path;
  final List<SwiftPackageTargetDependency>? dependencies;
  final SwiftPackageTargetType targetType;

  String format() {
    // targets: [
    //     .binaryTarget(
    //         name: "Flutter",
    //         path: "Flutter.xcframework"
    //     ),
    //     .target(
    //         name: "FlutterGeneratedPluginSwiftPackage",
    //         dependencies: [
    //             .target(name: "Flutter"),
    //             .product(name: "image_picker_ios", package: "image_picker_ios")
    //         ]
    //     ),
    // ]
    const String targetIndent = _doubleIndent;
    const targetDetailsIndent = '$_doubleIndent$_singleIndent';

    final targetDetails = <String>[];

    final nameString = 'name: "$name"';
    targetDetails.add(nameString);

    if (path != null) {
      final pathString = 'path: "$path"';
      targetDetails.add(pathString);
    }

    if (dependencies != null && dependencies!.isNotEmpty) {
      final List<String> targetDependencies = dependencies!
          .map((SwiftPackageTargetDependency dependency) => dependency.format())
          .toList();
      final dependenciesString =
          '''
dependencies: [
${targetDependencies.join(",\n")}
$targetDetailsIndent]''';
      targetDetails.add(dependenciesString);
    }

    return '''
${targetType.name}(
$targetDetailsIndent${targetDetails.join(",\n$targetDetailsIndent")}
$targetIndent)''';
  }
}

/// Type of Target.Dependency constructor.
///
/// See https://developer.apple.com/documentation/packagedescription/target/dependency
/// for more information.
enum SwiftPackageTargetDependencyType {
  product(name: '.product'),
  target(name: '.target');

  const SwiftPackageTargetDependencyType({required this.name});

  final String name;
}

/// A dependency for the Target on a product from a package dependency or from
/// another Target in the same package.
///
/// Representation of Target.Dependency from
/// https://developer.apple.com/documentation/packagedescription/target/dependency.
class SwiftPackageTargetDependency {
  SwiftPackageTargetDependency.product({required this.name, required String packageName})
    : package = packageName,
      dependencyType = SwiftPackageTargetDependencyType.product;

  SwiftPackageTargetDependency.target({required this.name})
    : package = null,
      dependencyType = SwiftPackageTargetDependencyType.target;

  final String name;
  final String? package;
  final SwiftPackageTargetDependencyType dependencyType;

  String format() {
    //         dependencies: [
    //             .target(name: "Flutter"),
    //             .product(name: "image_picker_ios", package: "image_picker_ios")
    //         ]
    if (dependencyType == SwiftPackageTargetDependencyType.product) {
      return '$_doubleIndent$_doubleIndent${dependencyType.name}(name: "$name", package: "$package")';
    }
    return '$_doubleIndent$_doubleIndent${dependencyType.name}(name: "$name")';
  }
}
