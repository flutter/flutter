import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';

main() async {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  var analyzer = '/Users/scheglov/Source/Dart/sdk.git/sdk/pkg/analyzer';
  var collection = AnalysisContextCollectionImpl(
    includedPaths: [analyzer],
    resourceProvider: resourceProvider,
    sdkPath: '/Users/scheglov/Applications/dart-sdk',
  );

  var session = collection.contextFor(analyzer).currentSession;
  var unitResult = await session
      .getResolvedUnit('$analyzer/lib/dart/ast/ast.dart') as ResolvedUnitResult;
  unitResult.unit.accept(_MyVisitor());

  // var nodeType = unitResult!.element.getType('AstNode')!.instantiate(
  //     typeArguments: [], nullabilitySuffix: NullabilitySuffix.none);
  //
  // var result2 =
  //     await session.getResolvedUnit('$analyzer/lib/src/dart/ast/ast.dart');
  // result2!.unit!.accept(_MyVisitor(result2.typeSystem, nodeType));
}

class _MyVisitor extends RecursiveAstVisitor<void> {
  // final TypeSystem _typeSystem;
  // final DartType _nodeType;
  //
  // _MyVisitor(this._typeSystem, this._nodeType);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isSetter && node.metadata.isEmpty) {
      // print('${(node.parent as dynamic).name}.${node.name}');
    }
    // if (node.isGetter) {
    //   var returnType = node.returnType;
    //   if (returnType != null &&
    //       _typeSystem.isSubtypeOf(returnType.type!, _nodeType) &&
    //       !'$returnType'.endsWith('Impl')) {
    //     print('$returnType get ${node.name}');
    //   }
    // }
  }
}
