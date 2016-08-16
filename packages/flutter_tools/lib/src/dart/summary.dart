import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/sdk/sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:analyzer/src/summary/summary_file_builder.dart'; // ignore: implementation_imports
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as pathos;

/// Given the [skyEnginePath] and [skyServicesPath], locate corresponding
/// `_embedder.yaml` and `_sdkext`, compose the full embedded Dart SDK, and
/// build the [outBundleName] file with its linked summary.
void buildSkyEngineSdkSummary(
    String skyEnginePath, String skyServicesPath, String outBundleName) {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  ContextBuilder builder = new ContextBuilder(resourceProvider, null, null);
  Packages packages = builder.createPackageMap(skyServicesPath);
  Map<String, List<Folder>> packageMap = builder.convertPackagesToMap(packages);
  packageMap['sky_engine'] = <Folder>[
    resourceProvider.getFolder(pathos.join(skyEnginePath, 'lib'))
  ];

  //
  // Read the `_embedder.yaml` file.
  //
  EmbedderYamlLocator yamlLocator = new EmbedderYamlLocator(packageMap);
  assert(yamlLocator.embedderYamls.length == 1);

  //
  // Read the `_sdkext` file.
  //
  SdkExtUriResolver extResolver = new SdkExtUriResolver(packageMap);
  assert(extResolver.urlMappings.length == 1);

  //
  // Create the EmbedderSdk instance.
  //
  EmbedderSdk sdk =
      new EmbedderSdk(resourceProvider, yamlLocator.embedderYamls);
  sdk.addExtensions(extResolver.urlMappings);
  sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = true;

  //
  // Gather sources.
  //
  List<Source> sources = sdk.uris.map(sdk.mapDartUri).toList();

  //
  // Build.
  //
  SummaryBuildConfig config = new SummaryBuildConfig(strongMode: true);
  BuilderOutput output =
      new SummaryBuilder(sources, sdk.context, config).build();
  String outputPath = pathos.join(skyEnginePath, outBundleName);
  new io.File(outputPath).writeAsBytesSync(output.sum);
}
