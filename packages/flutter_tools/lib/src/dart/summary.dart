import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/sdk/sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:analyzer/src/summary/summary_file_builder.dart'; // ignore: implementation_imports
import 'package:flutter_tools/src/globals.dart';
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as pathos;
import 'package:yaml/src/yaml_node.dart'; // ignore: implementation_imports

/// Given the [skyEnginePath] and [skyServicesPath], locate corresponding
/// `_embedder.yaml` and `_sdkext`, compose the full embedded Dart SDK, and
/// build the [outBundleName] file with its linked summary.
void buildSkyEngineSdkSummary(
    String skyEnginePath, String skyServicesPath, String outBundleName) {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  ContextBuilder builder = new ContextBuilder(resourceProvider, null, null);
  Packages packages = builder.createPackageMap(skyServicesPath);
  Map<String, List<Folder>> packageMap = builder.convertPackagesToMap(packages);
  if (packageMap == null) {
    printError('The expected .packages was not found in $skyServicesPath.');
    return;
  }
  packageMap['sky_engine'] = <Folder>[
    resourceProvider.getFolder(pathos.join(skyEnginePath, 'lib'))
  ];

  //
  // Read the `_embedder.yaml` file.
  //
  EmbedderYamlLocator yamlLocator = new EmbedderYamlLocator(packageMap);
  Map<Folder, YamlMap> embedderYamls = yamlLocator.embedderYamls;
  if (embedderYamls.length != 1) {
    printError('Exactly one _embedder.yaml was expected in $packageMap, '
        'but $embedderYamls found.');
    return;
  }

  //
  // Read the `_sdkext` file.
  //
  SdkExtUriResolver extResolver = new SdkExtUriResolver(packageMap);
  Map<String, String> urlMappings = extResolver.urlMappings;
  if (embedderYamls.length != 1) {
    printError('Exactly one extension library was expected in $packageMap, '
        'but $urlMappings found.');
    return;
  }

  //
  // Create the EmbedderSdk instance.
  //
  EmbedderSdk sdk = new EmbedderSdk(resourceProvider, embedderYamls);
  sdk.addExtensions(urlMappings);
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
