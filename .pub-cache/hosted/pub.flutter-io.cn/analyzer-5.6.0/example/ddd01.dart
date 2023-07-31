import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

void main() async {
  var path = '/Users/scheglov/dart/issue50962/br_table.0.dart';
  var collection = AnalysisContextCollectionImpl(includedPaths: [
    path,
  ]);
  var analysisContext = collection.contextFor(path);
  var unitResult = await analysisContext.currentSession.getResolvedUnit(path);
  unitResult as ResolvedUnitResult;

  // await Future<void>.delayed(const Duration(days: 1));
}
