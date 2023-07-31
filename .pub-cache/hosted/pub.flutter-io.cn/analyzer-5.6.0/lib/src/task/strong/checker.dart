// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart' show CompileTimeErrorCode;
import 'package:collection/collection.dart';

Element? _getKnownElement(SyntacticEntity expression) {
  if (expression is ParenthesizedExpression) {
    return _getKnownElement(expression.expression);
  } else if (expression is NamedExpression) {
    return _getKnownElement(expression.expression);
  } else if (expression is FunctionExpression) {
    return expression.declaredElement;
  } else if (expression is PropertyAccess) {
    return expression.propertyName.staticElement;
  } else if (expression is Identifier) {
    return expression.staticElement;
  }
  return null;
}

/// Checks the body of functions and properties for implicit cast errors in
/// pre-null safe libraries.
class CodeChecker extends RecursiveAstVisitor {
  final TypeSystemImpl _typeSystem;
  final TypeProvider _typeProvider;
  final ErrorReporter _errorReporter;

  CodeChecker(this._typeProvider, this._typeSystem, this._errorReporter);

  void checkArgument(Expression arg, DartType expectedType) {
    // Preserve named argument structure, so their immediate parent is the
    // method invocation.
    Expression baseExpression = arg is NamedExpression ? arg.expression : arg;
    checkAssignment(baseExpression, expectedType);
  }

  void checkArgumentList(ArgumentList node, FunctionType type) {
    NodeList<Expression> list = node.arguments;
    int len = list.length;
    for (int i = 0; i < len; ++i) {
      Expression arg = list[i];
      var element = arg.staticParameterElement;
      if (element == null) {
        // We found an argument mismatch, the analyzer will report this too,
        // so no need to insert an error for this here.
        continue;
      }
      checkArgument(arg, element.type);
    }
  }

  void checkAssignment(Expression expr, DartType to) {
    _checkImplicitCast(expr, from: expr.typeOrThrow, to: to);
  }

  void checkCollectionElement(
      CollectionElement? element, DartType expectedType) {
    if (element is ForElement) {
      checkCollectionElement(element.body, expectedType);
    } else if (element is IfElement) {
      checkCollectionElement(element.thenElement, expectedType);
      checkCollectionElement(element.elseElement, expectedType);
    } else if (element is Expression) {
      checkAssignment(element, expectedType);
    } else if (element is SpreadElement) {
      // Spread expression may be dynamic in which case it's implicitly downcast
      // to Iterable<dynamic>
      DartType expressionCastType = _typeProvider.iterableDynamicType;
      checkAssignment(element.expression, expressionCastType);

      var exprType = element.expression.typeOrThrow;
      var asIterableType = exprType.asInstanceOf(_typeProvider.iterableElement);

      if (asIterableType != null) {
        var elementType = asIterableType.typeArguments[0];
        // Items in the spread will then potentially be downcast to the expected
        // type.
        _checkImplicitCast(element.expression,
            to: expectedType, from: elementType, forSpread: true);
      }
    }
  }

  void checkMapElement(CollectionElement? element, DartType expectedKeyType,
      DartType expectedValueType) {
    if (element is ForElement) {
      checkMapElement(element.body, expectedKeyType, expectedValueType);
    } else if (element is IfElement) {
      checkMapElement(element.thenElement, expectedKeyType, expectedValueType);
      checkMapElement(element.elseElement, expectedKeyType, expectedValueType);
    } else if (element is MapLiteralEntry) {
      checkAssignment(element.key, expectedKeyType);
      checkAssignment(element.value, expectedValueType);
    } else if (element is SpreadElement) {
      // Spread expression may be dynamic in which case it's implicitly downcast
      // to Map<dynamic, dynamic>
      DartType expressionCastType = _typeProvider.mapType(
          DynamicTypeImpl.instance, DynamicTypeImpl.instance);
      checkAssignment(element.expression, expressionCastType);

      var exprType = element.expression.typeOrThrow;
      var asMapType = exprType.asInstanceOf(_typeProvider.mapElement);

      if (asMapType != null) {
        var elementKeyType = asMapType.typeArguments[0];
        var elementValueType = asMapType.typeArguments[1];
        // Keys and values in the spread will then potentially be downcast to
        // the expected types.
        _checkImplicitCast(element.expression,
            to: expectedKeyType, from: elementKeyType, forSpreadKey: true);
        _checkImplicitCast(element.expression,
            to: expectedValueType,
            from: elementValueType,
            forSpreadValue: true);
      }
    }
  }

  @override
  void visitAsExpression(AsExpression node) {
    // We could do the same check as the IsExpression below, but that is
    // potentially too conservative.  Instead, at runtime, we must fail hard
    // if the Dart as and the DDC as would return different values.
    node.visitChildren(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    if (operatorType == TokenType.EQ ||
        operatorType == TokenType.QUESTION_QUESTION_EQ) {
      var right = node.rightHandSide;
      _checkImplicitCast(right, from: right.typeOrThrow, to: node.writeType!);
    } else {
      _checkCompoundAssignment(node);
    }
    node.visitChildren(this);
  }

  @override
  void visitComment(Comment node) {
    // skip, no need to do typechecking inside comments (they may contain
    // comment references which would require resolution).
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.visitChildren(this);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var field = node.fieldName;
    var element = field.staticElement;
    if (element != null) {
      checkAssignment(node.expression, _elementType(element));
    }
    node.visitChildren(this);
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    // Check that defaults have the proper subtype.
    var parameter = node.parameter;
    var defaultValue = node.defaultValue;
    var element = parameter.declaredElement;
    if (defaultValue != null && element != null) {
      var parameterType = _elementType(element);
      checkAssignment(defaultValue, parameterType);
    }

    node.visitChildren(this);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    _checkReturnOrYield(node.expression, node);
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    _visitForEachParts(
      node,
      node.loopVariable.name,
      node.loopVariable.declaredElement,
    );
    node.visitChildren(this);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    _visitForEachParts(
      node,
      node.identifier.token,
      node.identifier.staticElement,
    );
    node.visitChildren(this);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _checkFunctionApplication(node);
    node.visitChildren(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    var element = node.writeOrReadElement;
    if (element is MethodElement) {
      var type = element.type;
      // Analyzer should enforce number of parameter types, but check in
      // case we have erroneous input.
      if (type.normalParameterTypes.isNotEmpty) {
        checkArgument(node.index, type.normalParameterTypes[0]);
      }
    } else {
      // TODO(vsm): Assert that the analyzer found an error here?
    }
    node.visitChildren(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var arguments = node.argumentList;
    var element = node.constructorName.staticElement;
    if (element != null) {
      var type = element.type;
      checkArgumentList(arguments, type);
    }
    node.visitChildren(this);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    DartType type = DynamicTypeImpl.instance;
    var typeArgumentList = node.typeArguments;
    if (typeArgumentList != null) {
      var typeArguments = typeArgumentList.arguments;
      if (typeArguments.isNotEmpty) {
        type = typeArguments[0].typeOrThrow;
      }
    } else {
      DartType staticType = node.typeOrThrow;
      if (staticType is InterfaceType) {
        type = staticType.typeArguments[0];
      }
    }
    NodeList<CollectionElement> elements = node.elements;
    for (int i = 0; i < elements.length; i++) {
      checkCollectionElement(elements[i], type);
    }
    super.visitListLiteral(node);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    var element = node.methodName.staticElement;
    if (element != null) {
      _checkFunctionApplication(node);
    }
    // Don't visit methodName, we already checked things related to the call.
    node.target?.accept(this);
    node.typeArguments?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _checkUnary(node, node.operand, node.operator, node.staticElement);
    node.visitChildren(this);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _checkUnary(node, node.operand, node.operator, node.staticElement);
    node.visitChildren(this);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    var type = node.staticElement?.type;
    // TODO(leafp): There's a TODO in visitRedirectingConstructorInvocation
    // in the element_resolver to handle the case that the element is null
    // and emit an error.  In the meantime, just be defensive here.
    if (type != null) {
      checkArgumentList(node.argumentList, type);
    }
    node.visitChildren(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    _checkReturnOrYield(node.expression, node);
    node.visitChildren(this);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    var typeArgumentsList = node.typeArguments;
    if (node.isMap) {
      DartType keyType = DynamicTypeImpl.instance;
      DartType valueType = DynamicTypeImpl.instance;
      if (typeArgumentsList != null) {
        NodeList<TypeAnnotation> typeArguments = typeArgumentsList.arguments;
        if (typeArguments.isNotEmpty) {
          keyType = typeArguments[0].typeOrThrow;
        }
        if (typeArguments.length > 1) {
          valueType = typeArguments[1].typeOrThrow;
        }
      } else {
        DartType staticType = node.typeOrThrow;
        if (staticType is InterfaceType) {
          keyType = staticType.typeArguments[0];
        }
      }
      NodeList<CollectionElement> elements = node.elements;
      for (int i = 0; i < elements.length; i++) {
        checkMapElement(elements[i], keyType, valueType);
      }
    } else if (node.isSet) {
      DartType type = DynamicTypeImpl.instance;
      if (typeArgumentsList != null) {
        NodeList<TypeAnnotation> typeArguments = typeArgumentsList.arguments;
        if (typeArguments.isNotEmpty) {
          type = typeArguments[0].typeOrThrow;
        }
      } else {
        DartType staticType = node.typeOrThrow;
        if (staticType is InterfaceType) {
          type = staticType.typeArguments[0];
        }
      }
      NodeList<CollectionElement> elements = node.elements;
      for (int i = 0; i < elements.length; i++) {
        checkCollectionElement(elements[i], type);
      }
    }
    super.visitSetOrMapLiteral(node);
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var element = node.staticElement;
    if (element != null) {
      var type = element.type;
      checkArgumentList(node.argumentList, type);
    }
    node.visitChildren(this);
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    // SwitchStatement defines a boolean conversion to check the result of the
    // case value == the switch value, but in dev_compiler we require a boolean
    // return type from an overridden == operator (because Object.==), so
    // checking in SwitchStatement shouldn't be necessary.
    node.visitChildren(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    var type = node.type;
    if (type != null) {
      for (VariableDeclaration variable in node.variables) {
        var initializer = variable.initializer;
        if (initializer != null) {
          _checkImplicitCast(initializer,
              from: initializer.typeOrThrow, to: type.typeOrThrow);
        }
      }
    }

    node.visitChildren(this);
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    _checkReturnOrYield(node.expression, node, yieldStar: node.star != null);
    node.visitChildren(this);
  }

  void _checkCompoundAssignment(AssignmentExpression expr) {
    var op = expr.operator.type;
    assert(op.isAssignmentOperator && op != TokenType.EQ);
    var methodElement = expr.staticElement;
    if (methodElement != null) {
      // Sanity check the operator.
      assert(methodElement.isOperator);
      var functionType = methodElement.type;
      var paramTypes = functionType.normalParameterTypes;
      var paramType = paramTypes.firstOrNull ?? _typeProvider.dynamicType;

      // Refine the return type.
      var rhsType = expr.rightHandSide.typeOrThrow;
      var returnType = _typeSystem.refineBinaryExpressionType(
        expr.readType!,
        op,
        rhsType,
        functionType.returnType,
        methodElement,
      );

      // Check the argument for an implicit cast.
      _checkImplicitCast(expr.rightHandSide, to: paramType, from: rhsType);

      // Check the return type for an implicit cast.
      //
      // If needed, mark the assignment to indicate a down cast when we assign
      // back to it. So these two implicit casts are equivalent:
      //
      //     y = /*implicit cast*/(y + 42);
      //     /*implicit assignment cast*/y += 42;
      //
      _checkImplicitCast(expr.leftHandSide,
          to: expr.writeType!, from: returnType, opAssign: true);
    }
  }

  void _checkFunctionApplication(InvocationExpression node) {
    var ft = _getTypeAsCaller(node);

    if (ft != null) {
      checkArgumentList(node.argumentList, ft);
    }
  }

  /// Returns true if an implicit downcast is required to assign an expression
  /// of type [fromType] to type [to], false if it is not, or null if the
  /// types are unrelated.
  bool? _checkFunctionTypeCasts(FunctionType to, DartType fromType) {
    bool callTearoff = false;
    FunctionType? from;
    if (fromType is FunctionType) {
      from = fromType;
    } else if (fromType is InterfaceType) {
      from = _typeSystem.getCallMethodType(fromType);
      callTearoff = true;
    }
    if (from == null) {
      return null; // unrelated
    }

    if (_typeSystem.isSubtypeOf(from, to)) {
      // Sound subtype.
      // However we may still need cast if we have a call tearoff.
      return callTearoff;
    }

    if (_typeSystem.isSubtypeOf(to, from)) {
      // Assignable, but needs cast.
      return true;
    }

    return null;
  }

  /// Checks if an implicit cast of [expr] from [from] type to [to] type is
  /// needed, and if so records it.
  ///
  /// If [from] is omitted, uses the static type of [expr].
  ///
  /// If [expr] does not require an implicit cast because it is not related to
  /// [to] or is already a subtype of it, does nothing.
  void _checkImplicitCast(SyntacticEntity expr,
      {required DartType to,
      required DartType from,
      bool opAssign = false,
      bool forSpread = false,
      bool forSpreadKey = false,
      bool forSpreadValue = false}) {
    if (expr is Expression) {
      expr = expr.unParenthesized;
    }
    if (_needsImplicitCast(expr, to: to, from: from) == true) {
      _recordImplicitCast(expr, to,
          from: from,
          opAssign: opAssign,
          forSpread: forSpread,
          forSpreadKey: forSpreadKey,
          forSpreadValue: forSpreadValue);
    }
  }

  void _checkReturnOrYield(Expression? expression, AstNode node,
      {bool yieldStar = false}) {
    var body = node.thisOrAncestorOfType<FunctionBody>()!;
    var type = _getExpectedReturnType(body, yieldStar: yieldStar);
    if (type == null) {
      // We have a type mismatch: the async/async*/sync* modifier does
      // not match the return or yield type.  We should have already gotten an
      // analyzer error in this case.
      return;
    }
    // TODO(vsm): Enforce void or dynamic (to void?) when expression is null.
    if (expression != null) checkAssignment(expression, type);
  }

  void _checkUnary(CompoundAssignmentExpression node, Expression operand,
      Token op, MethodElement? element) {
    bool isIncrementAssign = op.type.isIncrementOperator;
    if (element != null && isIncrementAssign) {
      // For ++ and --, even if it is not dynamic, we still need to check
      // that the user defined method accepts an `int` as the RHS.
      //
      // We assume Analyzer has done this already (in ErrorVerifier).
      //
      // However, we also need to check the return type.

      // Refine the return type.
      var functionType = element.type;
      var rhsType = _typeProvider.intType;
      var returnType = _typeSystem.refineBinaryExpressionType(
        node.readType!,
        TokenType.PLUS,
        rhsType,
        functionType.returnType,
        element,
      );

      // Skip the argument check - `int` cannot be downcast.
      //
      // Check the return type for an implicit cast.
      //
      // If needed, mark the assignment to indicate a down cast when we assign
      // back to it. So these two implicit casts are equivalent:
      //
      //     y = /*implicit cast*/(y + 1);
      //     /*implicit assignment cast*/y++;
      //
      _checkImplicitCast(operand,
          to: node.writeType!, from: returnType, opAssign: true);
    }
  }

  /// Gets the expected return type of the given function [body], either from
  /// a normal return/yield, or from a yield*.
  DartType? _getExpectedReturnType(FunctionBody body,
      {bool yieldStar = false}) {
    FunctionType functionType;
    var parent = body.parent;
    if (parent is Declaration) {
      functionType = _elementType(parent.declaredElement!) as FunctionType;
    } else {
      assert(parent is FunctionExpression);
      functionType = (parent as FunctionExpression).staticType as FunctionType;
    }

    var type = functionType.returnType;

    ClassElement expectedElement;
    if (body.isAsynchronous) {
      if (body.isGenerator) {
        // Stream<T> -> T
        expectedElement = _typeProvider.streamElement;
      } else {
        // Future<T> -> FutureOr<T>
        var typeArg = (type is InterfaceType &&
                type.element == _typeProvider.futureElement)
            ? type.typeArguments[0]
            : _typeProvider.dynamicType;
        return _typeProvider.futureOrType(typeArg);
      }
    } else {
      if (body.isGenerator) {
        // Iterable<T> -> T
        expectedElement = _typeProvider.iterableElement;
      } else {
        // T -> T
        return type;
      }
    }
    if (yieldStar) {
      if (type.isDynamic) {
        // Ensure it's at least a Stream / Iterable.
        return expectedElement.instantiate(
          typeArguments: [_typeProvider.dynamicType],
          nullabilitySuffix: NullabilitySuffix.star,
        );
      } else {
        // Analyzer will provide a separate error if expected type
        // is not compatible with type.
        return type;
      }
    }
    if (type.isDynamic) {
      return type;
    } else if (type is InterfaceType && type.element == expectedElement) {
      return type.typeArguments[0];
    } else {
      // Malformed type - fallback on analyzer error.
      return null;
    }
  }

  DartType? _getInstanceTypeArgument(
      DartType expressionType, ClassElement instanceType) {
    var asInstanceType = expressionType.asInstanceOf(instanceType);
    if (asInstanceType != null) {
      return asInstanceType.typeArguments[0];
    }
    return null;
  }

  /// Given an expression, return its type assuming it is
  /// in the caller position of a call (that is, accounting
  /// for the possibility of a call method).  Returns null
  /// if expression is not statically callable.
  FunctionType? _getTypeAsCaller(InvocationExpression node) {
    var type = node.staticInvokeType;
    if (type is FunctionType) {
      return type;
    } else if (type is InterfaceType) {
      return _typeSystem.getCallMethodType(type);
    }
    return null;
  }

  /// Returns true if we need an implicit cast of [expr] from [from] type to
  /// [to] type, returns false if no cast is needed, and returns null if the
  /// types are statically incompatible, or the types are compatible but don't
  /// allow implicit cast (ie, void, which is one form of Top which will not
  /// downcast implicitly).
  ///
  /// If [from] is omitted, uses the static type of [expr]
  bool? _needsImplicitCast(SyntacticEntity expr,
      {required DartType from, required DartType to}) {
    // Void is considered Top, but may only be *explicitly* cast.
    if (from.isVoid) return null;

    if (to is FunctionType) {
      var needsCast = _checkFunctionTypeCasts(to, from);
      if (needsCast != null) return needsCast;
    }

    // fromT <: toT, no coercion needed.
    if (_typeSystem.isSubtypeOf(from, to)) {
      return false;
    }

    // Down cast or legal sideways cast, coercion needed.
    if (_typeSystem.isAssignableTo(from, to)) {
      return true;
    }

    // Special case for FutureOr to handle returned values from async functions.
    // In this case, we're more permissive than assignability.
    if (to.isDartAsyncFutureOr) {
      var to1 = (to as InterfaceType).typeArguments[0];
      var to2 = _typeProvider.futureType(to1);
      return _needsImplicitCast(expr, to: to1, from: from) == true ||
          _needsImplicitCast(expr, to: to2, from: from) == true;
    }

    // Anything else is an illegal sideways cast.
    // However, these will have been reported already in error_verifier, so we
    // don't need to report them again.
    return null;
  }

  /// Records an implicit cast for the [expr] from [from] to [to].
  ///
  /// This will emit the appropriate error/warning/hint message as well as mark
  /// the AST node.
  void _recordImplicitCast(SyntacticEntity expr, DartType to,
      {required DartType from,
      bool opAssign = false,
      bool forSpread = false,
      bool forSpreadKey = false,
      bool forSpreadValue = false}) {
    // If this is an implicit tearoff, we need to mark the cast, but we don't
    // want to warn if it's a legal subtype.
    if (from is InterfaceType && _typeSystem.acceptsFunctionType(to)) {
      var type = _typeSystem.getCallMethodType(from);
      if (type != null && _typeSystem.isSubtypeOf(type, to)) {
        return;
      }
    }

    if (!forSpread && !forSpreadKey && !forSpreadValue) {
      // Spreads are special in that they may create downcasts at runtime but
      // those casts are implied so we don't treat them as strictly.

      // Inference "casts":
      if (expr is Literal) {
        // fromT should be an exact type - this will almost certainly fail at
        // runtime.
        if (expr is ListLiteral) {
          _recordMessage(
              expr, CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST, [from, to]);
        } else if (expr is SetOrMapLiteral) {
          if (expr.isMap) {
            _recordMessage(expr, CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP,
                [from, to]);
          } else if (expr.isSet) {
            _recordMessage(expr, CompileTimeErrorCode.INVALID_CAST_LITERAL_SET,
                [from, to]);
          } else {
            // This should only happen when the code is invalid, in which case
            // the error should have been reported elsewhere.
          }
        } else {
          _recordMessage(expr, CompileTimeErrorCode.INVALID_CAST_LITERAL,
              [expr, from, to]);
        }
        return;
      }

      if (expr is FunctionExpression) {
        // TODO(srawlins): Add _any_ test that shows this code is reported.
        _recordMessage(
            expr, CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR, [from, to]);
        return;
      }

      if (expr is InstanceCreationExpression) {
        var e = expr.constructorName.staticElement;
        if (e == null || !e.isFactory) {
          // fromT should be an exact type - this will almost certainly fail at
          // runtime.
          _recordMessage(
              expr, CompileTimeErrorCode.INVALID_CAST_NEW_EXPR, [from, to]);
          return;
        }
      }

      var e = _getKnownElement(expr);
      if (e is FunctionElement) {
        _recordMessage(expr, CompileTimeErrorCode.INVALID_CAST_FUNCTION,
            [e.name, from, to]);
      } else if (e is MethodElement && e.isStatic) {
        _recordMessage(
            expr, CompileTimeErrorCode.INVALID_CAST_METHOD, [e.name, from, to]);
      }
    }
  }

  void _recordMessage(
      SyntacticEntity node, ErrorCode errorCode, List<Object> arguments) {
    var argumentStrings = [
      for (var argument in arguments)
        if (argument is DartType)
          argument.getDisplayString(withNullability: false)
        else
          argument.toString(),
    ];

    int begin = node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    int length = node.end - begin;
    _errorReporter.reportErrorForOffset(
        errorCode, begin, length, argumentStrings);
  }

  void _visitForEachParts(
    ForEachParts node,
    Token loopVariable,
    Element? loopVariableElement,
  ) {
    if (loopVariableElement is! VariableElement) {
      return;
    }

    // Safely handle malformed statements.
    Token? awaitKeyword;
    var parent = node.parent;
    if (parent is ForStatement) {
      awaitKeyword = parent.awaitKeyword;
    } else if (parent is ForElement) {
      awaitKeyword = parent.awaitKeyword;
    } else {
      throw StateError(
          'Unexpected parent of ForEachParts: ${parent.runtimeType}');
    }
    // Find the element type of the sequence.
    var sequenceElement = awaitKeyword != null
        ? _typeProvider.streamElement
        : _typeProvider.iterableElement;
    var iterableType = node.iterable.typeOrThrow;
    var elementType = _getInstanceTypeArgument(iterableType, sequenceElement);

    // If the sequence is not an Iterable (or Stream for await for) but is a
    // supertype of it, do an implicit downcast to Iterable<dynamic>. Then
    // we'll do a separate cast of the dynamic element to the variable's type.
    if (elementType == null) {
      var sequenceType = sequenceElement.instantiate(
        typeArguments: [_typeProvider.dynamicType],
        nullabilitySuffix: NullabilitySuffix.star,
      );

      if (_typeSystem.isSubtypeOf(sequenceType, iterableType)) {
        _recordImplicitCast(node.iterable, sequenceType, from: iterableType);
        elementType = DynamicTypeImpl.instance;
      }
    }
    // If the sequence doesn't implement the interface at all, [ErrorVerifier]
    // will report the error, so ignore it here.
    if (elementType != null) {
      // Insert a cast from the sequence's element type to the loop variable's
      // if needed.
      _checkImplicitCast(loopVariable,
          to: loopVariableElement.type, from: elementType);
    }
  }

  static DartType _elementType(Element e) {
    if (e is ConstructorElement) {
      return e.type;
    } else if (e is FieldElement) {
      return e.type;
    } else if (e is MethodElement) {
      return e.type;
    } else if (e is ParameterElement) {
      return e.type;
    } else if (e is PropertyAccessorElement) {
      return e.type;
    }
    throw StateError('${e.runtimeType} is unhandled type');
  }
}
