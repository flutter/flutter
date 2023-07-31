import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

void main() async {
  var resourceProvider = OverlayResourceProvider(
    PhysicalResourceProvider.INSTANCE,
  );

  var path = '/Users/scheglov/dart/test/lib/a.dart';

  var buffer = StringBuffer();
  const classCount = 100 * 1000;
  for (var i = 0; i < classCount; i++) {
    buffer.writeln('class A$i {}');
  }
  resourceProvider.setOverlay(
    path,
    content: buffer.toString(),
    modificationStamp: 0,
  );

  var collection = AnalysisContextCollectionImpl(
    resourceProvider: resourceProvider,
    includedPaths: [path],
  );
  var analysisContext = collection.contextFor(path);
  var unitResult = analysisContext.currentSession.getParsedUnit(path);
  unitResult as ParsedUnitResult;

  var classList = unitResult.unit.declarations
      .whereType<ClassDeclaration>()
      .toList(growable: false);

  var randomClassList = classList.toList();
  randomClassList.shuffle();

  for (var i = 0; i < 10; i++) {
    _iterateClassList(i, 'sequential', classList);
    _iterateClassList(i, '    random', randomClassList);
  }
}

void _iterateClassList(int i, String name, List<ClassDeclaration> classList) {
  var timer = Stopwatch()..start();
  var result = 0;
  for (var i = 0; i < 100; i++) {
    for (var i = 0; i < classList.length; i++) {
      var classDeclaration = classList[i];
      result = (result + classDeclaration.offset) & 0xFFFF;
      result = (result + classDeclaration.length) & 0xFFFF;
      result = (result + classDeclaration.name.length) & 0xFFFF;
    }
  }
  timer.stop();
  print(
    '[$i][$name][result: $result]'
    '[time: ${timer.elapsedMilliseconds} ms]',
  );
}
