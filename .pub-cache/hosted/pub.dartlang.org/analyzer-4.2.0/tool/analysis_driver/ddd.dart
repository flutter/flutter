import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

main() async {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  var collection = AnalysisContextCollectionImpl(
    includedPaths: ['/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer'],
    resourceProvider: resourceProvider,
    sdkPath: '/Users/scheglov/Applications/dart-sdk',
  );
  var path =
      '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer/lib/src/summary2/reference.dart';
  // var collection = AnalysisContextCollectionImpl(
  //   includedPaths: ['/Users/scheglov/dart/test'],
  //   resourceProvider: resourceProvider,
  //   sdkPath: '/Users/scheglov/Applications/dart-sdk',
  // );
  // var path = '/Users/scheglov/dart/test/bin/test.dart';

  var context = collection.contextFor(path);
  var session = context.currentSession;

  await session.getUnitElement(path);
  print('After getUnitElement');
  await Future.delayed(Duration(seconds: 1), () => 0);
  print('After getUnitElement2');

  // AnalysisDriver.shouldCleanLibraryContext = false;
  await session.getResolvedLibrary(path);
  print('After getResolvedLibrary');

  await Future.delayed(Duration(days: 1), () => 0);
}
