import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

main() async {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  // var analyzer = '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer';
  var analyzer = '/Users/scheglov/Source/flutter/examples/hello_world';
  var collection = AnalysisContextCollectionImpl(
    includedPaths: [analyzer],
    resourceProvider: resourceProvider,
    sdkPath: '/Users/scheglov/Applications/dart-sdk',
  );

  var analysisContext = collection.contextFor(analyzer);

  // var filePath = '$analyzer/lib/src/dart/element/class_hierarchy.dart';
  // var filePath = '$analyzer/lib/src/dart/analysis/testing_data.dart';
  // var filePath = '$analyzer/lib/test.dart';
  var filePath =
      '/Users/scheglov/Source/flutter/packages/flutter/lib/src/material/chip.dart';
  for (var i = 0; i < 1000000; i++) {
    var timer = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      analysisContext.driver.changeFile('/1.dart');
      // analysisContext.driver.changeFile(filePath);
      var session = analysisContext.currentSession;
      await session.getResolvedUnit(filePath);
    }
    print('[$i] time: ${timer.elapsedMilliseconds} ms.');
  }
}
