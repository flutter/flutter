import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/builder.dart'; // ignore: implementation_imports
import 'package:analyzer/src/dart/sdk/sdk.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/engine.dart'; // ignore: implementation_imports
import 'package:analyzer/src/generated/source.dart'; // ignore: implementation_imports
import 'package:analyzer/src/summary/summary_file_builder.dart'; // ignore: implementation_imports
import 'package:flutter_tools/src/globals.dart';
import 'package:path/path.dart' as pathos;
import 'package:yaml/src/yaml_node.dart'; // ignore: implementation_imports

import '../base/file_system.dart' as file;

/// Given the [skyEnginePath], locate corresponding `_embedder.yaml` and compose
/// the full embedded Dart SDK, and build the [outBundleName] file with its
/// linked [strong] or spec summary.
void buildSkyEngineSdkSummary(String skyEnginePath, String outBundleName, bool strong) {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;

  Map<String, List<Folder>> packageMap = <String, List<Folder>>{
    'sky_engine': <Folder>[
      resourceProvider.getFolder(pathos.join(skyEnginePath, 'lib'))
    ]
  };

  // Read the `_embedder.yaml` file.
  EmbedderYamlLocator yamlLocator = new EmbedderYamlLocator(packageMap);
  Map<Folder, YamlMap> embedderYamls = yamlLocator.embedderYamls;
  if (embedderYamls.length != 1) {
    printError('Exactly one _embedder.yaml was expected in $packageMap, '
        'but $embedderYamls found.');
    return;
  }

  // Create the EmbedderSdk instance.
  EmbedderSdk sdk = new EmbedderSdk(resourceProvider, embedderYamls);
  sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = true;

  // Gather sources.
  List<Source> sources = sdk.uris.map(sdk.mapDartUri).toList();

  // Build.
  List<int> bytes = new SummaryBuilder(sources, sdk.context, strong).build();
  String outputPath = pathos.join(skyEnginePath, outBundleName);
  file.fs.file(outputPath).writeAsBytesSync(bytes);
}
