import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/sdk_ext.dart';
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/sdk/sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:analyzer/src/summary/summary_file_builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/summary/pub_summary.dart'; // ignore: implementation_imports
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:package_config/packages.dart';
import 'package:path/path.dart' as pathos;
import 'package:yaml/src/yaml_node.dart'; // ignore: implementation_imports

/// Given the [skyEnginePath] and [flutterServicesPath], locate corresponding
/// `_embedder.yaml` and `_sdkext`, compose the full embedded Dart SDK, and
/// build the [outBundleName] file with its linked summary.
void buildSkyEngineSdkSummary(
    String skyEnginePath, String flutterServicesPath, String outBundleName) {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  ContextBuilder builder = new ContextBuilder(resourceProvider, null, null);
  Packages packages = builder.createPackageMap(flutterServicesPath);
  Map<String, List<Folder>> packageMap = builder.convertPackagesToMap(packages);
  if (packageMap == null) {
    printError('The expected .packages was not found in $flutterServicesPath.');
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
  List<int> bytes = new SummaryBuilder(sources, sdk.context, true).build();
  String outputPath = pathos.join(skyEnginePath, outBundleName);
  new io.File(outputPath).writeAsBytesSync(bytes);
}

Future<Null> buildUnlinkedForPackages(String flutterPath) async {
  PhysicalResourceProvider provider = PhysicalResourceProvider.INSTANCE;
  PubSummaryManager manager =
      new PubSummaryManager(provider, '__unlinked_${io.pid}.ds');

  Folder flutterFolder = provider.getFolder(flutterPath);

  //
  // Build in packages/.
  //
  Folder packagesFolder = flutterFolder.getChildAssumingFolder('packages');
  await _buildUnlinkedForDirectChildren(manager, packagesFolder);

  //
  // Build in bin/cache/pkg/.
  //
  Folder pkgFolder = flutterFolder
      .getChildAssumingFolder('bin')
      .getChildAssumingFolder('cache')
      .getChildAssumingFolder('pkg');
  await _buildUnlinkedForDirectChildren(manager, pkgFolder);
}

Future<Null> _buildUnlinkedForDirectChildren(
    PubSummaryManager manager, Folder packagesFolder) async {
  for (Resource child in packagesFolder.getChildren()) {
    if (child is Folder) {
      await _buildUnlinkedForPackage(manager, child);
    }
  }
}

Future<Null> _buildUnlinkedForPackage(
    PubSummaryManager manager, Folder packageFolder) async {
  if (packageFolder.exists) {
    String name = packageFolder.shortName;
    File pubspecFile = packageFolder.getChildAssumingFile('pubspec.yaml');
    Folder libFolder = packageFolder.getChildAssumingFolder('lib');
    if (pubspecFile.exists && libFolder.exists) {
      await pubGet(directory: packageFolder.path);
      Status status =
          logger.startProgress('Building unlinked bundles for $name...');
      try {
        await manager.computeUnlinkedForFolder(name, libFolder);
      } finally {
        status.stop(showElapsedTime: true);
      }
    }
  }
}
