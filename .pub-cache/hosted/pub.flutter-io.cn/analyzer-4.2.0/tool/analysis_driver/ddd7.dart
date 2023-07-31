import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

void main() async {
  final resourceProvider = PhysicalResourceProvider.INSTANCE;

  // var rootPath = '/Users/scheglov/Source/flutter/packages/flutter/lib';
  var rootPath = '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer/lib';
  final collection = AnalysisContextCollectionImpl(
    includedPaths: [rootPath],
    resourceProvider: resourceProvider,
  );

  final analysisContext = collection.contextFor(rootPath);
  final analysisSession = analysisContext.currentSession;

  var classCount = 0;
  var staticFieldCount = 0;
  for (final path in analysisContext.contextRoot.analyzedFiles()) {
    print(path);
    var uri = analysisSession.uriConverter.pathToUri(path);
    var libraryResult = await analysisSession.getLibraryByUri('$uri');
    print(libraryResult);
    if (libraryResult is LibraryElementResult) {
      for (final unitElement in libraryResult.element.units) {
        for (final classElement in unitElement.classes) {
          if (classElement.isPrivate) continue;
          print(classElement.name);
          classCount++;
          for (final field in classElement.fields) {
            if (field.isPrivate) continue;
            if (!field.isSynthetic && field.isStatic) {
              print('  $field');
              staticFieldCount++;
            }
          }
        }
      }
    }
  }
  print('classCount: $classCount');
  print('staticFieldCount: $staticFieldCount');
}
