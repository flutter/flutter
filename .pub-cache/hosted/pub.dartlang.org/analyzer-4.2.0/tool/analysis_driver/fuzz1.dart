import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

main(List<String> args) async {
  final input = args[0];

  var resourceProvider = MemoryResourceProvider();

  // createMockSdk(
  //   resourceProvider: resourceProvider,
  //   root: resourceProvider.newFolder('/sdk'),
  // );

  var path = '/home/test/lib/test.dart';
  resourceProvider.newFile(path, input);

  var collection = AnalysisContextCollectionImpl(
    resourceProvider: resourceProvider,
    includedPaths: [path],
    sdkPath: '/sdk',
  );
  var session = collection.contextFor(path).currentSession;
  await session.getResolvedLibrary(path);
//  print(result.units[0].errors);
//  print(input.length);
}
