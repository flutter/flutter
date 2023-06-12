// @dart = 2.9
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/ast/token.dart';

main() async {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  var collection = AnalysisContextCollectionImpl(
    includedPaths: ['/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer'],
    resourceProvider: resourceProvider,
    sdkPath: '/Users/scheglov/Applications/dart-sdk',
  );

  for (var analysisContext in collection.contexts) {
    var session = analysisContext.currentSession;
    var analyzedFiles = analysisContext.contextRoot.analyzedFiles();
    for (var path in analyzedFiles) {
      if (path.endsWith('.dart')) {
        var parsedUnit = session.getParsedUnit(path) as ParsedUnitResult;
        parsedUnit.unit.accept(A());
      }
    }
  }

  // var path =
  //     '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer/lib/src/summary2/reference.dart';
  // var collection = AnalysisContextCollectionImpl(
  //   includedPaths: ['/Users/scheglov/dart/test'],
  //   resourceProvider: resourceProvider,
  //   sdkPath: '/Users/scheglov/Applications/dart-sdk',
  // );
  // var path = '/Users/scheglov/dart/test/bin/test.dart';

  // var context = collection.contextFor(path);
  // var session = context.currentSession;
  //
  // await session.getUnitElement(path);
  // print('After getUnitElement');
  // await Future.delayed(Duration(seconds: 1), () => 0);
  // print('After getUnitElement2');
  //
  // // AnalysisDriver.shouldCleanLibraryContext = false;
  // await session.getResolvedLibrary(path);
  // print('After getResolvedLibrary');
  //
  // await Future.delayed(Duration(days: 1), () => 0);
}

class A extends GeneralizingAstVisitor<void> {
  @override
  void visitNode(AstNode node) {
    var begin = node.beginToken;
    if (begin is CommentToken) {
      begin = (begin as CommentToken).parent;
    }

    var end = node.endToken;

    print(node.runtimeType);
    var token = begin;
    while (true) {
      if (token == end) {
        break;
      }

      var nextToken = token.next;

      // Stop if EOF.
      if (nextToken == token) {
        break;
      }

      token = nextToken;
    }
    // for (var token = begin;
    //     token != node.endToken;
    //     token = token.next) {
    //   if (token == null) {
    //     print('aaaaaaa');
    //   }
    // }

    super.visitNode(node);
  }
}
