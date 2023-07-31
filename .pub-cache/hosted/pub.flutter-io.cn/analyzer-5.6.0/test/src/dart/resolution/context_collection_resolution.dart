// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/summary2/kernel_compilation_service.dart';
import 'package:analyzer/src/test_utilities/mock_packages.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';
import '../../summary/macros_environment.dart';
import '../analysis/analyzer_state_printer.dart';
import 'context_collection_resolution_caching.dart';
import 'node_text_expectations.dart';
import 'resolution.dart';

export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final bool implicitCasts;
  final bool implicitDynamic;
  final List<String> lints;
  final bool strictCasts;
  final bool strictInference;
  final bool strictRawTypes;
  final List<String> unignorableNames;

  AnalysisOptionsFileConfig({
    this.experiments = const [],
    this.implicitCasts = true,
    this.implicitDynamic = true,
    this.lints = const [],
    this.strictCasts = false,
    this.strictInference = false,
    this.strictRawTypes = false,
    this.unignorableNames = const [],
  });

  String toContent() {
    var buffer = StringBuffer();

    buffer.writeln('analyzer:');
    buffer.writeln('  enable-experiment:');
    for (var experiment in experiments) {
      buffer.writeln('    - $experiment');
    }
    buffer.writeln('  language:');
    buffer.writeln('    strict-casts: $strictCasts');
    buffer.writeln('    strict-inference: $strictInference');
    buffer.writeln('    strict-raw-types: $strictRawTypes');
    buffer.writeln('  strong-mode:');
    buffer.writeln('    implicit-casts: $implicitCasts');
    buffer.writeln('    implicit-dynamic: $implicitDynamic');
    buffer.writeln('  cannot-ignore:');
    for (var name in unignorableNames) {
      buffer.writeln('    - $name');
    }

    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    for (var lint in lints) {
      buffer.writeln('    - $lint');
    }

    return buffer.toString();
  }
}

class BlazeWorkspaceResolutionTest extends ContextResolutionTest {
  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/dart/my';

  @override
  File get testFile => getFile('$myPackageLibPath/my.dart');

  String get workspaceRootPath => '/workspace';

  String get workspaceThirdPartyDartPath {
    return '$workspaceRootPath/third_party/dart';
  }

  @override
  void setUp() {
    super.setUp();
    newFile('$workspaceRootPath/${file_paths.blazeWorkspaceMarker}', '');
    newFile('$myPackageRootPath/BUILD', '');
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertBlazeWorkspaceFor(testFile);
  }
}

/// [AnalysisContextCollection] based implementation of [ResolutionTest].
abstract class ContextResolutionTest
    with ResourceProviderMixin, ResolutionTest {
  static bool _lintRulesAreRegistered = false;

  MemoryByteStore _byteStore = getContextResolutionTestByteStore();

  Map<String, String> _declaredVariables = {};
  AnalysisContextCollectionImpl? _analysisContextCollection;

  /// If not `null`, [resolveFile] will use the context that corresponds
  /// to this file, instead of the given file.
  File? fileForContextSelection;

  /// Optional Dart SDK summary file, to be used instead of [sdkRoot].
  File? sdkSummaryFile;

  /// Optional summaries to provide for the collection.
  List<File>? librarySummaryFiles;

  final IdProvider _idProvider = IdProvider();

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  List<String> get collectionIncludedPaths;

  set declaredVariables(Map<String, String> map) {
    if (_analysisContextCollection != null) {
      throw StateError('Declared variables cannot be changed after analysis.');
    }

    _declaredVariables = map;
  }

  bool get retainDataForTesting => false;

  Folder get sdkRoot => newFolder('/sdk');

  void assertBasicWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<BasicWorkspace>());
  }

  void assertBlazeWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<BlazeWorkspace>());
  }

  void assertDriverStateString(
    File file,
    String expected, {
    bool omitSdkFiles = true,
  }) {
    final analysisDriver = driverFor(file);

    final buffer = StringBuffer();
    AnalyzerStatePrinter(
      byteStore: _byteStore,
      idProvider: _idProvider,
      libraryContext: analysisDriver.libraryContext,
      omitSdkFiles: omitSdkFiles,
      resourceProvider: resourceProvider,
      sink: buffer,
      withKeysGetPut: false,
    ).writeAnalysisDriver(analysisDriver.testView!);
    final actual = buffer.toString();

    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertGnWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<GnWorkspace>());
  }

  void assertPackageBuildWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<PackageBuildWorkspace>());
  }

  void assertPubWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<PubWorkspace>());
  }

  AnalysisContext contextFor(File file) {
    return _contextFor(file);
  }

  Future<void> disposeAnalysisContextCollection() async {
    final analysisContextCollection = _analysisContextCollection;
    if (analysisContextCollection != null) {
      await analysisContextCollection.dispose(
        forTesting: true,
      );
      _analysisContextCollection = null;
    }
  }

  AnalysisDriver driverFor(File file) {
    return _contextFor(file).driver;
  }

  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content);
  }

  @override
  Future<ResolvedUnitResult> resolveFile(String path) async {
    final file = getFile(path); // TODO(scheglov) migrate to File
    var analysisContext = contextFor(fileForContextSelection ?? file);
    var session = analysisContext.currentSession;
    return await session.getResolvedUnit(path) as ResolvedUnitResult;
  }

  @mustCallSuper
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
      additionalLibraries: additionalMockSdkLibraries,
    );
  }

  @mustCallSuper
  Future<void> tearDown() async {
    noSoundNullSafety = true;
    await disposeAnalysisContextCollection();
    KernelCompilationService.disposeDelayed(
      const Duration(milliseconds: 500),
    );
  }

  /// Override this method to update [analysisOptions] for every context root,
  /// the default or already updated with `analysis_options.yaml` file.
  void updateAnalysisOptions({
    required AnalysisOptionsImpl analysisOptions,
    required ContextRoot contextRoot,
    required DartSdk sdk,
  }) {}

  /// Call this method if the test needs to use the empty byte store, without
  /// any information cached.
  void useEmptyByteStore() {
    _byteStore = MemoryByteStore();
  }

  void verifyCreatedCollection() {}

  DriverBasedAnalysisContext _contextFor(File file) {
    _createAnalysisContexts();

    return _analysisContextCollection!.contextFor(file.path);
  }

  /// Create all analysis contexts in [collectionIncludedPaths].
  void _createAnalysisContexts() {
    if (_analysisContextCollection != null) {
      return;
    }

    _analysisContextCollection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: _declaredVariables,
      enableIndex: true,
      includedPaths: collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      retainDataForTesting: retainDataForTesting,
      sdkPath: sdkRoot.path,
      sdkSummaryPath: sdkSummaryFile?.path,
      librarySummaryPaths: librarySummaryFiles?.map((e) => e.path).toList(),
      updateAnalysisOptions2: updateAnalysisOptions,
    );

    verifyCreatedCollection();
  }
}

class PubPackageResolutionTest extends ContextResolutionTest {
  AnalysisOptionsImpl get analysisOptions {
    return contextFor(testFile).analysisOptions as AnalysisOptionsImpl;
  }

  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  List<String> get experiments => [
        EnableString.class_modifiers,
        EnableString.inference_update_2,
        EnableString.macros,
        EnableString.patterns,
        EnableString.records,
        EnableString.sealed_class,
      ];

  @override
  bool get isNullSafetyEnabled => true;

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  @override
  File get testFile => getFile('$testPackageLibPath/test.dart');

  /// The language version to use by default for `package:test`.
  String? get testPackageLanguageVersion => null;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  /// Build summary bundle for a single URI `package:foo/foo.dart`.
  Future<File> buildPackageFooSummary({
    required Map<String, String> files,
  }) async {
    final rootFolder = getFolder('$workspaceRootPath/foo');

    final packageConfigFile = getFile(
      '${rootFolder.path}/.dart_tool/package_config.json',
    );

    writePackageConfig(
      packageConfigFile.path,
      PackageConfigFileBuilder()..add(name: 'foo', rootPath: rootFolder.path),
    );

    for (final entry in files.entries) {
      newFile('${rootFolder.path}/${entry.key}', entry.value);
    }

    final targetFile = getFile(rootFolder.path);
    final analysisDriver = driverFor(targetFile);
    final bundleBytes = await analysisDriver.buildPackageBundle(
      uriList: [
        Uri.parse('package:foo/foo.dart'),
      ],
    );

    final bundleFile = getFile('/home/summaries/packages.sum');
    bundleFile.writeAsBytesSync(bundleBytes);

    // Delete, so it is not available as a file.
    // We don't have a package config for it anyway, but just to be sure.
    rootFolder.delete();

    await disposeAnalysisContextCollection();

    return bundleFile;
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: experiments,
      ),
    );
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
    );
  }

  void writePackageConfig(String path, PackageConfigFileBuilder config) {
    newFile(
      path,
      config.toContent(
        toUriStr: toUriStr,
      ),
    );
  }

  Future<File> writeSdkSummary() async {
    final file = getFile('/home/summaries/sdk.sum');
    final bytes = await buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );
    file.writeAsBytesSync(bytes);
    return file;
  }

  void writeTestPackageAnalysisOptionsFile(AnalysisOptionsFileConfig config) {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      config.toContent(),
    );
  }

  void writeTestPackageConfig(
    PackageConfigFileBuilder config, {
    String? languageVersion,
    bool ffi = false,
    bool js = false,
    bool meta = false,
    MacrosEnvironment? macrosEnvironment,
  }) {
    config = config.copy();

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (ffi) {
      var ffiPath = '/packages/ffi';
      MockPackages.addFfiPackageFiles(
        getFolder(ffiPath),
      );
      config.add(name: 'ffi', rootPath: ffiPath);
    }

    if (js) {
      var jsPath = '/packages/js';
      MockPackages.addJsPackageFiles(
        getFolder(jsPath),
      );
      config.add(name: 'js', rootPath: jsPath);
    }

    if (meta) {
      var metaPath = '/packages/meta';
      MockPackages.addMetaPackageFiles(
        getFolder(metaPath),
      );
      config.add(name: 'meta', rootPath: metaPath);
    }

    if (macrosEnvironment != null) {
      var packagesRootFolder = getFolder(packagesRootPath);
      macrosEnvironment.packageSharedFolder.copyTo(packagesRootFolder);
      config.add(
        name: '_fe_analyzer_shared',
        rootPath: getFolder('$packagesRootPath/_fe_analyzer_shared').path,
      );
    }

    var path = '$testPackageRootPath/.dart_tool/package_config.json';
    writePackageConfig(path, config);
  }

  void writeTestPackageConfigWithMeta() {
    writeTestPackageConfig(PackageConfigFileBuilder(), meta: true);
  }

  void writeTestPackagePubspecYamlFile(PubspecYamlFileConfig config) {
    newPubspecYamlFile(testPackageRootPath, config.toContent());
  }
}

class PubspecYamlFileConfig {
  final String? name;
  final String? sdkVersion;
  final List<PubspecYamlFileDependency> dependencies;

  PubspecYamlFileConfig({
    this.name,
    this.sdkVersion,
    this.dependencies = const [],
  });

  String toContent() {
    var buffer = StringBuffer();

    if (name != null) {
      buffer.writeln('name: $name');
    }

    if (sdkVersion != null) {
      buffer.writeln('environment:');
      buffer.writeln("  sdk: '$sdkVersion'");
    }

    if (dependencies.isNotEmpty) {
      buffer.writeln('dependencies:');
      for (var dependency in dependencies) {
        buffer.writeln('  ${dependency.name}: ${dependency.version}');
      }
    }

    return buffer.toString();
  }
}

class PubspecYamlFileDependency {
  final String name;
  final String version;

  PubspecYamlFileDependency({
    required this.name,
    this.version = 'any',
  });
}

mixin WithLanguage218Mixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.18';
}

mixin WithNoImplicitCastsMixin on PubPackageResolutionTest {
  /// Asserts that no errors are reported in [code] when implicit casts are
  /// allowed, and that [expectedErrors] are reported for the same [code] when
  /// implicit casts are not allowed.
  Future<void> assertErrorsWithNoImplicitCasts(
    String code,
    List<ExpectedError> expectedErrors,
  ) async {
    await resolveTestCode(code);
    assertNoErrorsInResult();

    await disposeAnalysisContextCollection();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        implicitCasts: false,
      ),
    );

    await resolveTestFile();
    assertErrorsInResult(expectedErrors);
  }

  /// Asserts that no errors are reported in [code], both when implicit casts
  /// are allowed and when implicit casts are not allowed.
  Future<void> assertNoErrorsWithNoImplicitCasts(String code) async =>
      assertErrorsWithNoImplicitCasts(code, []);
}

mixin WithoutConstructorTearoffsMixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.14';
}

mixin WithoutEnhancedEnumsMixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.16';
}

mixin WithoutNullSafetyMixin on PubPackageResolutionTest {
  @override
  bool get isNullSafetyEnabled => false;

  @override
  String? get testPackageLanguageVersion => '2.9';
}

mixin WithStrictCastsMixin on PubPackageResolutionTest {
  /// Asserts that no errors are reported in [code] when implicit casts are
  /// allowed, and that [expectedErrors] are reported for the same [code] when
  /// implicit casts are not allowed.
  Future<void> assertErrorsWithStrictCasts(
    String code,
    List<ExpectedError> expectedErrors,
  ) async {
    await resolveTestCode(code);
    assertNoErrorsInResult();

    await disposeAnalysisContextCollection();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        strictCasts: true,
      ),
    );

    await resolveTestFile();
    assertErrorsInResult(expectedErrors);
  }

  /// Asserts that no errors are reported in [code], both when implicit casts
  /// are allowed and when implicit casts are not allowed.
  Future<void> assertNoErrorsWithStrictCasts(String code) async =>
      assertErrorsWithStrictCasts(code, []);
}
