import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:build_modules/build_modules.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../artifacts.dart';
import '../compile.dart';
import '../globals.dart';

/// A builder which creates a kernel file for a flutter entrypoint from dart
/// modules and an entrypoint.
class FlutterKernelBuilder implements Builder {
  const FlutterKernelBuilder({
    @required this.target,
    @required this.aot,
    @required this.trackWidgetCreation,
    @required this.targetProductVm,
    @required this.linkPlatformKernelIn,
    @required this.extraFrontEndOptions,
  });

  final String target;
  final bool aot;
  final bool trackWidgetCreation;
  final bool targetProductVm;
  final bool linkPlatformKernelIn;
  final List<String> extraFrontEndOptions;

  @override
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    '.dart': <String>['.app.dill', '.d'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    if (!buildStep.inputId.path.contains(target)) {
      return;
    }
    final AssetId moduleId = buildStep.inputId.changeExtension('.flutter.module');
    final Module module = Module.fromJson(json.decode(await buildStep.readAsString(moduleId)));
    final AssetId outputId = module.primarySource.changeExtension('.app.dill');
    final AssetId outputKernelDepId = module.primarySource.changeExtension('.d');
    final File outputFile = scratchSpace.fileFor(outputId);
    final File outputKernelDep = scratchSpace.fileFor(outputKernelDepId);
    final List<Module> transitiveDeps = await module.computeTransitiveDependencies(buildStep);
    final Set<AssetId> allAssetIds = Set<AssetId>();
    for (Module module in transitiveDeps) {
      allAssetIds.addAll(module.sources);
    }
    allAssetIds.addAll(module.sources);
    await scratchSpace.ensureAssets(allAssetIds, buildStep);
    final File packagesFile = await _createPackagesFile(allAssetIds);
    await kernelCompiler.compile(
      sdkRoot: artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
      mainPath: buildStep.inputId.path,
      packagesPath: packagesFile.path,
      outputFilePath: outputFile.path,
      depFilePath: outputKernelDep.path,
      extraFrontEndOptions: extraFrontEndOptions,
      linkPlatformKernelIn: linkPlatformKernelIn,
      aot: aot,
      trackWidgetCreation: trackWidgetCreation,
      targetProductVm: targetProductVm,
      fileSystemScheme: multiRootScheme,
    );
    await scratchSpace.copyOutput(outputId, buildStep);
    await scratchSpace.copyOutput(outputKernelDepId, buildStep);
    await packagesFile.parent.delete(recursive: true);
  }

  Future<File> _createPackagesFile(Iterable<AssetId> allAssets) async {
    final Set<String> allPackages = allAssets.map((AssetId id) => id.package).toSet();
    final Directory packagesFileDir = await Directory.systemTemp.createTemp('kernel_builder_');
    final File packagesFile = File(path.join(packagesFileDir.path, '.packages'));
    await packagesFile.create();
    await packagesFile.writeAsString(allPackages
        .map((String pkg) => '$pkg:$multiRootScheme:///packages/$pkg')
        .join('\r\n'));
    return packagesFile;
  }
}
