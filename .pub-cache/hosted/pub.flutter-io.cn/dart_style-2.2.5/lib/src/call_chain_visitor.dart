// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';

import 'argument_list_visitor.dart';
import 'ast_extensions.dart';
import 'rule/argument.dart';
import 'rule/rule.dart';
import 'source_visitor.dart';

/// Helper class for [SourceVisitor] that handles visiting and writing a
/// chained series of "selectors": method invocations, property accesses,
/// prefixed identifiers, index expressions, and null-assertion operators.
///
/// In the AST, selectors are nested bottom up such that this expression:
///
///     obj.a(1)[2].c(3)
///
/// Is structured like:
///
///           .c()
///           /  \
///          []   3
///         /  \
///       .a()  2
///       /  \
///     obj   1
///
/// This means visiting the AST from top down visits the selectors from right
/// to left. It's easier to format that if we organize them as a linear series
/// of selectors from left to right. Further, we want to organize it into a
/// two-tier hierarchy. We have an outer list of method calls and property
/// accesses. Then each of those may have one or more postfix selectors
/// attached: indexers, null-assertions, or invocations. This mirrors how they
/// are formatted.
class CallChainVisitor {
  final SourceVisitor _visitor;

  /// The initial target of the call chain.
  ///
  /// This may be any expression except [MethodInvocation], [PropertyAccess] or
  /// [PrefixedIdentifier].
  final Expression _target;

  /// The list of dotted names ([PropertyAccess] and [PrefixedIdentifier]) at
  /// the start of the call chain.
  ///
  /// This will be empty if the [_target] is not a [SimpleIdentifier].
  final List<_Selector> _properties;

  /// The mixed method calls and property accesses in the call chain in the
  /// order that they appear in the source reading from left to right.
  final List<_Selector> _calls;

  /// The method calls containing block function literals that break the method
  /// chain and escape its indentation.
  ///
  ///     receiver.a().b().c(() {
  ///       ;
  ///     }).d(() {
  ///       ;
  ///     }).e();
  ///
  /// Here, it will contain `c` and `d`.
  ///
  /// The block calls must be contiguous and must be a suffix of the list of
  /// calls (except for the one allowed hanging call). Otherwise, none of them
  /// are treated as block calls:
  ///
  ///     receiver
  ///         .a()
  ///         .b(() {
  ///           ;
  ///         })
  ///         .c(() {
  ///           ;
  ///         })
  ///         .d()
  ///         .e();
  final List<_MethodSelector>? _blockCalls;

  /// If there is one or more block calls and a single chained expression after
  /// that, this will be that expression.
  ///
  ///     receiver.a().b().c(() {
  ///       ;
  ///     }).d(() {
  ///       ;
  ///     }).e();
  ///
  /// We allow a single hanging call after the blocks because it will never
  /// need to split before its `.` and this accommodates the common pattern of
  /// a trailing `toList()` or `toSet()` after a series of higher-order methods
  /// on an iterable.
  final _Selector? _hangingCall;

  /// Whether or not a [Rule] is currently active for the call chain.
  bool _ruleEnabled = false;

  /// Whether or not the span wrapping the call chain is currently active.
  bool _spanEnded = false;

  /// After the properties are visited (if there are any), this will be the
  /// rule used to split between them.
  PositionalRule? _propertyRule;

  /// Creates a new call chain visitor for [visitor] for the method chain
  /// contained in [node].
  ///
  /// The [node] is the outermost expression containing the chained "."
  /// operators and must be a [MethodInvocation], [PropertyAccess] or
  /// [PrefixedIdentifier].
  factory CallChainVisitor(SourceVisitor visitor, Expression node) {
    // Flatten the call chain tree to a list of selectors with postfix
    // expressions.
    var calls = <_Selector>[];
    var target = _unwrapTarget(node, calls);

    // An expression that starts with a series of dotted names gets treated a
    // little specially. We don't force leading properties to split with the
    // rest of the chain. Allows code like:
    //
    //     address.street.number
    //       .toString()
    //       .length;
    var properties = <_Selector>[];
    if (_unwrapNullAssertion(target) is SimpleIdentifier) {
      properties = calls.takeWhile((call) => call.isProperty).toList();
    }

    calls.removeRange(0, properties.length);

    // Separate out the block calls, if there are any.
    List<_MethodSelector>? blockCalls;
    _Selector? hangingCall;

    var inBlockCalls = false;
    for (var call in calls) {
      if (call.isBlockCall(visitor)) {
        inBlockCalls = true;
        blockCalls ??= [];
        blockCalls.add(call as _MethodSelector);
      } else if (inBlockCalls) {
        // We found a non-block call after a block call.
        if (call == calls.last) {
          // It's the one allowed hanging one, so it's OK.
          hangingCall = call;
          break;
        }

        // Don't allow any of the calls to be block formatted.
        blockCalls = null;
        break;
      }
    }

    if (blockCalls != null) {
      for (var blockCall in blockCalls) {
        calls.remove(blockCall);
      }
    }

    if (hangingCall != null) {
      calls.remove(hangingCall);
    }

    return CallChainVisitor._(
        visitor, target, properties, calls, blockCalls, hangingCall);
  }

  CallChainVisitor._(this._visitor, this._target, this._properties, this._calls,
      this._blockCalls, this._hangingCall);

  /// Builds chunks for the call chain.
  void visit() {
    _visitor.builder.nestExpression();

    // Try to keep the entire method invocation one line.
    _visitor.builder.startSpan();

    // If a split in the target expression forces the first `.` to split, then
    // start the rule now so that it surrounds the target.
    var splitOnTarget = _forcesSplit(_target);

    if (splitOnTarget) {
      if (_properties.length > 1) {
        _propertyRule = PositionalRule(null, argumentCount: _properties.length);
        _visitor.builder.startLazyRule(_propertyRule);
      } else {
        _enableRule(lazy: true);
      }
    }

    _visitor.visit(_target);

    // Leading properties split like positional arguments: either not at all,
    // before one ".", or before all of them.
    if (_properties.length == 1) {
      _visitor.soloZeroSplit();
      _properties.single.write(this);
    } else if (_properties.length > 1) {
      if (!splitOnTarget) {
        _propertyRule = PositionalRule(null, argumentCount: _properties.length);
        _visitor.builder.startRule(_propertyRule);
      }

      for (var property in _properties) {
        _propertyRule!.beforeArgument(_visitor.zeroSplit());
        property.write(this);
      }

      _visitor.builder.endRule();
    }

    // Indent any block arguments in the chain that don't get special formatting
    // below. Only do this if there is more than one argument to avoid spurious
    // indentation in cases like:
    //
    //     object.method(wrapper(() {
    //       body;
    //     });
    // TODO(rnystrom): Come up with a less arbitrary way to express this?
    if (_calls.length > 1) _visitor.builder.startBlockArgumentNesting();

    // The chain of calls splits atomically (either all or none). Any block
    // arguments inside them get indented to line up with the `.`.
    for (var call in _calls) {
      _enableRule();
      _visitor.zeroSplit();
      call.write(this);
    }

    if (_calls.length > 1) _visitor.builder.endBlockArgumentNesting();

    // If there are block calls, end the chain and write those without any
    // extra indentation.
    var blockCalls = _blockCalls;
    if (blockCalls != null) {
      _enableRule();
      _visitor.zeroSplit();
      _disableRule();

      for (var blockCall in blockCalls) {
        blockCall.write(this);
      }

      // If there is a hanging call after the last block, write it without any
      // split before the ".".
      _hangingCall?.write(this);
    }

    _disableRule();
    _endSpan();
    _visitor.builder.unnest();
  }

  /// Returns `true` if the method chain should split if a split occurs inside
  /// [expression].
  ///
  /// In most cases, splitting in a method chain's target forces the chain to
  /// split too:
  ///
  ///      receiver(very, long, argument,
  ///              list)                    // <-- Split here...
  ///          .method();                   //     ...forces split here.
  ///
  /// However, if the target is a collection or function literal (or an
  /// argument list ending in one of those), we don't want to split:
  ///
  ///      receiver(inner(() {
  ///        ;
  ///      }).method();                     // <-- Unsplit.
  bool _forcesSplit(Expression expression) {
    // TODO(rnystrom): Other cases we may want to consider handling and
    // recursing into:
    // * The right operand in an infix operator call.
    // * The body of a `=>` function.

    // Unwrap parentheses.
    while (expression is ParenthesizedExpression) {
      expression = expression.expression;
    }

    // Don't split right after a collection literal.
    if (expression is ListLiteral) return false;
    if (expression is SetOrMapLiteral) return false;

    // Don't split right after a non-empty curly-bodied function.
    if (expression is FunctionExpression) {
      if (expression.body is! BlockFunctionBody) return false;

      return (expression.body as BlockFunctionBody).block.statements.isEmpty;
    }

    // If the expression ends in an argument list, base the splitting on the
    // last argument.
    ArgumentList? argumentList;
    if (expression is MethodInvocation) {
      argumentList = expression.argumentList;
    } else if (expression is InstanceCreationExpression) {
      argumentList = expression.argumentList;
    } else if (expression is FunctionExpressionInvocation) {
      argumentList = expression.argumentList;
    }

    // Any other kind of expression always splits.
    if (argumentList == null) return true;
    if (argumentList.arguments.isEmpty) return true;

    var argument = argumentList.arguments.last;

    // If the argument list has a trailing comma, treat it like a collection.
    if (argument.hasCommaAfter) return false;

    if (argument is NamedExpression) {
      argument = argument.expression;
    }

    // TODO(rnystrom): This logic is similar (but not identical) to
    // ArgumentListVisitor.hasBlockArguments. They overlap conceptually and
    // both have their own peculiar heuristics. It would be good to unify and
    // rationalize them.

    return _forcesSplit(argument);
  }

  /// Called when a [_MethodSelector] has written its name and is about to
  /// write the argument list.
  void _beforeMethodArguments(_MethodSelector selector) {
    // If we don't have any block calls, stop the rule after the last method
    // call name, but before its arguments. This allows unsplit chains where
    // the last argument list wraps, like:
    //
    //     foo().bar().baz(
    //         argument, list);
    if (_blockCalls == null && _calls.isNotEmpty && selector == _calls.last) {
      _disableRule();
    }

    // For a single method call on an identifier, stop the span before the
    // arguments to make it easier to keep the call name with the target. In
    // other words, prefer:
    //
    //     target.method(
    //         argument, list);
    //
    // Over:
    //
    //     target
    //         .method(argument, list);
    //
    // Alternatively, the way to think of this is try to avoid splitting on the
    // "." when calling a single method on a single name. This is especially
    // important because the identifier is often a library prefix, and splitting
    // there looks really odd.
    if (_properties.isEmpty &&
        _calls.length == 1 &&
        _blockCalls == null &&
        _target is SimpleIdentifier) {
      _endSpan();
    }
  }

  /// If a [Rule] for the method chain is currently active, ends it.
  void _disableRule() {
    if (_ruleEnabled == false) return;

    _visitor.builder.endRule();
    _ruleEnabled = false;
  }

  /// Creates a new method chain [Rule] if one is not already active.
  void _enableRule({bool lazy = false}) {
    if (_ruleEnabled) return;

    // If the properties split, force the calls to split too.
    var rule = Rule();
    _propertyRule?.addNamedArgsConstraints(rule);

    if (lazy) {
      _visitor.builder.startLazyRule(rule);
    } else {
      _visitor.builder.startRule(rule);
    }

    _ruleEnabled = true;
  }

  /// Ends the span wrapping the call chain if it hasn't ended already.
  void _endSpan() {
    if (_spanEnded) return;

    _visitor.builder.endSpan();
    _spanEnded = true;
  }
}

/// One "selector" in a method call chain.
///
/// Each selector is a method call or property access. It may be followed by
/// one or more postfix expressions, which can be index expressions or
/// null-assertion operators. These are not treated like their own selectors
/// because the formatter attaches them to the previous method call or property
/// access:
///
///     receiver
///         .method(arg)[index]
///         .another()!
///         .third();
abstract class _Selector {
  /// The series of index and/or null-assertion postfix selectors that follow
  /// and are attached to this one.
  ///
  /// Elements in this list will either be [IndexExpression] or
  /// [PostfixExpression].
  final List<Expression> _postfixes = [];

  /// Whether this selector is a property access as opposed to a method call.
  bool get isProperty => true;

  /// Whether this selector is a method call whose arguments are block
  /// formatted.
  bool isBlockCall(SourceVisitor visitor) => false;

  /// Write the selector portion of the expression wrapped by this [_Selector]
  /// using [visitor], followed by any postfix selectors.
  void write(CallChainVisitor visitor) {
    writeSelector(visitor);

    // Write any trailing index and null-assertion operators.
    visitor._visitor.builder.nestExpression();
    for (var postfix in _postfixes) {
      if (postfix is FunctionExpressionInvocation) {
        // Allow splitting between the invocations if needed.
        visitor._visitor.soloZeroSplit();

        visitor._visitor.visit(postfix.typeArguments);
        visitor._visitor.visitArgumentList(postfix.argumentList);
      } else if (postfix is IndexExpression) {
        visitor._visitor.finishIndexExpression(postfix);
      } else if (postfix is PostfixExpression) {
        assert(postfix.operator.type == TokenType.BANG);
        visitor._visitor.token(postfix.operator);
      } else {
        // Unexpected type.
        assert(false);
      }
    }
    visitor._visitor.builder.unnest();
  }

  /// Subclasses implement this to write their selector.
  void writeSelector(CallChainVisitor visitor);
}

class _MethodSelector extends _Selector {
  final MethodInvocation _node;

  _MethodSelector(this._node);

  @override
  bool get isProperty => false;

  @override
  bool isBlockCall(SourceVisitor visitor) =>
      ArgumentListVisitor(visitor, _node.argumentList).hasBlockArguments;

  @override
  void writeSelector(CallChainVisitor visitor) {
    visitor._visitor.token(_node.operator);
    visitor._visitor.token(_node.methodName.token);

    visitor._beforeMethodArguments(this);

    visitor._visitor.builder.nestExpression();
    visitor._visitor.visit(_node.typeArguments);
    visitor._visitor
        .visitArgumentList(_node.argumentList, nestExpression: false);
    visitor._visitor.builder.unnest();
  }
}

class _PrefixedSelector extends _Selector {
  final PrefixedIdentifier _node;

  _PrefixedSelector(this._node);

  @override
  void writeSelector(CallChainVisitor visitor) {
    visitor._visitor.token(_node.period);
    visitor._visitor.visit(_node.identifier);
  }
}

class _PropertySelector extends _Selector {
  final PropertyAccess _node;

  _PropertySelector(this._node);

  @override
  void writeSelector(CallChainVisitor visitor) {
    visitor._visitor.token(_node.operator);
    visitor._visitor.visit(_node.propertyName);
  }
}

/// If [expression] is a null-assertion operator, returns its operand.
Expression _unwrapNullAssertion(Expression expression) {
  if (expression is PostfixExpression &&
      expression.operator.type == TokenType.BANG) {
    return expression.operand;
  }

  return expression;
}

/// Given [node], which is the outermost expression for some call chain,
/// recursively traverses the selectors to fill in the list of [calls].
///
/// Returns the remaining target expression that precedes the method chain.
/// For example, given:
///
///     foo.bar()!.baz[0][1].bang()
///
/// This returns `foo` and fills calls with:
///
///     selector  postfixes
///     --------  ---------
///     .bar()    !
///     .baz      [0], [1]
///     .bang()
Expression _unwrapTarget(Expression node, List<_Selector> calls) {
  // Don't include things that look like static method or constructor
  // calls in the call chain because that tends to split up named
  // constructors from their class.
  if (node.looksLikeStaticCall) return node;

  // Selectors.
  if (node is MethodInvocation && node.target != null) {
    return _unwrapSelector(node.target!, _MethodSelector(node), calls);
  }

  if (node is PropertyAccess && node.target != null) {
    return _unwrapSelector(node.target!, _PropertySelector(node), calls);
  }

  if (node is PrefixedIdentifier) {
    return _unwrapSelector(node.prefix, _PrefixedSelector(node), calls);
  }

  // Postfix expressions.
  if (node is IndexExpression && node.target != null) {
    return _unwrapPostfix(node, node.target!, calls);
  }

  if (node is FunctionExpressionInvocation) {
    return _unwrapPostfix(node, node.function, calls);
  }

  if (node is PostfixExpression && node.operator.type == TokenType.BANG) {
    return _unwrapPostfix(node, node.operand, calls);
  }

  // Otherwise, it isn't a selector so we're done.
  return node;
}

Expression _unwrapPostfix(
    Expression node, Expression target, List<_Selector> calls) {
  target = _unwrapTarget(target, calls);

  // If we don't have a preceding selector to hang the postfix expression off
  // of, don't unwrap it and leave it attached to the target expression. For
  // example:
  //
  //     (list + another)[index]
  if (calls.isEmpty) return node;

  calls.last._postfixes.add(node);
  return target;
}

Expression _unwrapSelector(
    Expression target, _Selector selector, List<_Selector> calls) {
  target = _unwrapTarget(target, calls);
  calls.add(selector);
  return target;
}
