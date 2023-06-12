// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../visitor.dart';

/////////////////////////////////////////////////////////////////////////
// CSS specific types:
/////////////////////////////////////////////////////////////////////////

class Identifier extends TreeNode {
  String name;

  Identifier(this.name, SourceSpan? span) : super(span);

  @override
  Identifier clone() => Identifier(name, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitIdentifier(this);

  @override
  String toString() {
    // Try to use the identifier's original lexeme to preserve any escape codes
    // as authored. The name, which may include escaped values, may no longer be
    // a valid identifier.
    return span?.text ?? name;
  }
}

class Wildcard extends TreeNode {
  Wildcard(SourceSpan? span) : super(span);
  @override
  Wildcard clone() => Wildcard(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitWildcard(this);

  String get name => '*';
}

class ThisOperator extends TreeNode {
  ThisOperator(SourceSpan? span) : super(span);
  @override
  ThisOperator clone() => ThisOperator(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitThisOperator(this);

  String get name => '&';
}

class Negation extends TreeNode {
  Negation(SourceSpan? span) : super(span);
  @override
  Negation clone() => Negation(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitNegation(this);

  String get name => 'not';
}

// calc(...)
// TODO(terry): Hack to handle calc however the expressions should be fully
//              parsed and in the AST.
class CalcTerm extends LiteralTerm {
  final LiteralTerm expr;

  CalcTerm(var value, String t, this.expr, SourceSpan? span)
      : super(value, t, span);

  @override
  CalcTerm clone() => CalcTerm(value, text, expr.clone(), span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitCalcTerm(this);

  @override
  String toString() => '$text($expr)';
}

// /*  ....   */
class CssComment extends TreeNode {
  final String comment;

  CssComment(this.comment, SourceSpan? span) : super(span);
  @override
  CssComment clone() => CssComment(comment, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitCssComment(this);
}

// CDO/CDC (Comment Definition Open <!-- and Comment Definition Close -->).
class CommentDefinition extends CssComment {
  CommentDefinition(String comment, SourceSpan? span) : super(comment, span);
  @override
  CommentDefinition clone() => CommentDefinition(comment, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitCommentDefinition(this);
}

class SelectorGroup extends TreeNode {
  final List<Selector> selectors;

  SelectorGroup(this.selectors, SourceSpan? span) : super(span);

  @override
  SelectorGroup clone() => SelectorGroup(selectors, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSelectorGroup(this);
}

class Selector extends TreeNode {
  final List<SimpleSelectorSequence> simpleSelectorSequences;

  Selector(this.simpleSelectorSequences, SourceSpan? span) : super(span);

  void add(SimpleSelectorSequence seq) => simpleSelectorSequences.add(seq);

  int get length => simpleSelectorSequences.length;

  @override
  Selector clone() {
    var simpleSequences =
        simpleSelectorSequences.map((ss) => ss.clone()).toList();

    return Selector(simpleSequences, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSelector(this);
}

class SimpleSelectorSequence extends TreeNode {
  /// +, >, ~, NONE
  int combinator;
  final SimpleSelector simpleSelector;

  SimpleSelectorSequence(this.simpleSelector, SourceSpan? span,
      [int combinator = TokenKind.COMBINATOR_NONE])
      : combinator = combinator,
        super(span);

  bool get isCombinatorNone => combinator == TokenKind.COMBINATOR_NONE;
  bool get isCombinatorPlus => combinator == TokenKind.COMBINATOR_PLUS;
  bool get isCombinatorGreater => combinator == TokenKind.COMBINATOR_GREATER;
  bool get isCombinatorTilde => combinator == TokenKind.COMBINATOR_TILDE;
  bool get isCombinatorDescendant =>
      combinator == TokenKind.COMBINATOR_DESCENDANT;

  String get _combinatorToString {
    switch (combinator) {
      case TokenKind.COMBINATOR_DESCENDANT:
        return ' ';
      case TokenKind.COMBINATOR_GREATER:
        return ' > ';
      case TokenKind.COMBINATOR_PLUS:
        return ' + ';
      case TokenKind.COMBINATOR_TILDE:
        return ' ~ ';
      default:
        return '';
    }
  }

  @override
  SimpleSelectorSequence clone() =>
      SimpleSelectorSequence(simpleSelector, span, combinator);

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitSimpleSelectorSequence(this);

  @override
  String toString() => simpleSelector.name;
}

// All other selectors (element, #id, .class, attribute, pseudo, negation,
// namespace, *) are derived from this selector.
abstract class SimpleSelector extends TreeNode {
  final dynamic _name; // Wildcard, ThisOperator, Identifier, Negation, others?

  SimpleSelector(this._name, SourceSpan? span) : super(span);

  // TOOD(srawlins): Figure this one out.
  // ignore: avoid_dynamic_calls
  String get name => _name.name as String;

  bool get isWildcard => _name is Wildcard;

  bool get isThis => _name is ThisOperator;

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSimpleSelector(this);
}

// element name
class ElementSelector extends SimpleSelector {
  ElementSelector(name, SourceSpan? span) : super(name, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitElementSelector(this);

  @override
  ElementSelector clone() => ElementSelector(_name, span);

  @override
  String toString() => name;
}

// namespace|element
class NamespaceSelector extends SimpleSelector {
  final dynamic _namespace; // null, Wildcard or Identifier

  NamespaceSelector(this._namespace, var name, SourceSpan? span)
      : super(name, span);

  String get namespace => _namespace is Wildcard
      ? '*'
      : _namespace == null
          ? ''
          : (_namespace as Identifier).name;

  bool get isNamespaceWildcard => _namespace is Wildcard;

  SimpleSelector? get nameAsSimpleSelector => _name as SimpleSelector?;

  @override
  NamespaceSelector clone() => NamespaceSelector(_namespace, '', span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitNamespaceSelector(this);

  @override
  String toString() => '$namespace|${nameAsSimpleSelector!.name}';
}

// [attr op value]
class AttributeSelector extends SimpleSelector {
  final int _op;
  final dynamic value;

  AttributeSelector(Identifier name, this._op, this.value, SourceSpan? span)
      : super(name, span);

  int get operatorKind => _op;

  String? matchOperator() {
    switch (_op) {
      case TokenKind.EQUALS:
        return '=';
      case TokenKind.INCLUDES:
        return '~=';
      case TokenKind.DASH_MATCH:
        return '|=';
      case TokenKind.PREFIX_MATCH:
        return '^=';
      case TokenKind.SUFFIX_MATCH:
        return '\$=';
      case TokenKind.SUBSTRING_MATCH:
        return '*=';
      case TokenKind.NO_MATCH:
        return '';
    }
    return null;
  }

  // Return the TokenKind for operator used by visitAttributeSelector.
  String? matchOperatorAsTokenString() {
    switch (_op) {
      case TokenKind.EQUALS:
        return 'EQUALS';
      case TokenKind.INCLUDES:
        return 'INCLUDES';
      case TokenKind.DASH_MATCH:
        return 'DASH_MATCH';
      case TokenKind.PREFIX_MATCH:
        return 'PREFIX_MATCH';
      case TokenKind.SUFFIX_MATCH:
        return 'SUFFIX_MATCH';
      case TokenKind.SUBSTRING_MATCH:
        return 'SUBSTRING_MATCH';
    }
    return null;
  }

  String valueToString() {
    if (value != null) {
      if (value is Identifier) {
        return value.toString();
      } else {
        return '"$value"';
      }
    } else {
      return '';
    }
  }

  @override
  AttributeSelector clone() =>
      AttributeSelector(_name as Identifier, _op, value, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitAttributeSelector(this);

  @override
  String toString() => '[$name${matchOperator()}${valueToString()}]';
}

// #id
class IdSelector extends SimpleSelector {
  IdSelector(Identifier name, SourceSpan? span) : super(name, span);
  @override
  IdSelector clone() => IdSelector(_name as Identifier, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitIdSelector(this);

  @override
  String toString() => '#$_name';
}

// .class
class ClassSelector extends SimpleSelector {
  ClassSelector(Identifier name, SourceSpan? span) : super(name, span);
  @override
  ClassSelector clone() => ClassSelector(_name as Identifier, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitClassSelector(this);

  @override
  String toString() => '.$_name';
}

// :pseudoClass
class PseudoClassSelector extends SimpleSelector {
  PseudoClassSelector(Identifier name, SourceSpan? span) : super(name, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitPseudoClassSelector(this);

  @override
  PseudoClassSelector clone() => PseudoClassSelector(_name as Identifier, span);

  @override
  String toString() => ':$name';
}

// ::pseudoElement
class PseudoElementSelector extends SimpleSelector {
  // If true, this is a CSS2.1 pseudo-element with only a single ':'.
  final bool isLegacy;

  PseudoElementSelector(Identifier name, SourceSpan? span,
      {this.isLegacy = false})
      : super(name, span);
  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitPseudoElementSelector(this);

  @override
  PseudoElementSelector clone() =>
      PseudoElementSelector(_name as Identifier, span);

  @override
  String toString() => "${isLegacy ? ':' : '::'}$name";
}

// :pseudoClassFunction(argument)
class PseudoClassFunctionSelector extends PseudoClassSelector {
  final TreeNode argument; // Selector, SelectorExpression

  PseudoClassFunctionSelector(Identifier name, this.argument, SourceSpan? span)
      : super(name, span);

  @override
  PseudoClassFunctionSelector clone() =>
      PseudoClassFunctionSelector(_name as Identifier, argument, span);

  Selector get selector => argument as Selector;
  SelectorExpression get expression => argument as SelectorExpression;

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitPseudoClassFunctionSelector(this);
}

// ::pseudoElementFunction(expression)
class PseudoElementFunctionSelector extends PseudoElementSelector {
  final SelectorExpression expression;

  PseudoElementFunctionSelector(
      Identifier name, this.expression, SourceSpan? span)
      : super(name, span);

  @override
  PseudoElementFunctionSelector clone() =>
      PseudoElementFunctionSelector(_name as Identifier, expression, span);

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitPseudoElementFunctionSelector(this);
}

class SelectorExpression extends TreeNode {
  final List<Expression> expressions;

  SelectorExpression(this.expressions, SourceSpan? span) : super(span);

  @override
  SourceSpan get span => super.span!;

  @override
  SelectorExpression clone() {
    return SelectorExpression(expressions.map((e) => e.clone()).toList(), span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSelectorExpression(this);
}

// :NOT(negation_arg)
class NegationSelector extends SimpleSelector {
  final SimpleSelector? negationArg;

  NegationSelector(this.negationArg, SourceSpan? span)
      : super(Negation(span), span);

  @override
  NegationSelector clone() => NegationSelector(negationArg, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitNegationSelector(this);
}

class NoOp extends TreeNode {
  NoOp() : super(null);

  @override
  NoOp clone() => NoOp();

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitNoOp(this);
}

class StyleSheet extends TreeNode {
  /// Contains charset, ruleset, directives (media, page, etc.), and selectors.
  final List<TreeNode> topLevels;

  StyleSheet(this.topLevels, SourceSpan? span) : super(span) {
    for (final node in topLevels) {
      assert(node is TopLevelProduction || node is Directive);
    }
  }

  /// Selectors only in this tree.
  StyleSheet.selector(this.topLevels, SourceSpan? span) : super(span);

  @override
  SourceSpan get span => super.span!;

  @override
  StyleSheet clone() {
    var clonedTopLevels = topLevels.map((e) => e.clone()).toList();
    return StyleSheet(clonedTopLevels, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitStyleSheet(this);
}

class TopLevelProduction extends TreeNode {
  TopLevelProduction(SourceSpan? span) : super(span);
  @override
  SourceSpan get span => super.span!;
  @override
  TopLevelProduction clone() => TopLevelProduction(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitTopLevelProduction(this);
}

class RuleSet extends TopLevelProduction {
  final SelectorGroup? selectorGroup;
  final DeclarationGroup declarationGroup;

  RuleSet(this.selectorGroup, this.declarationGroup, SourceSpan? span)
      : super(span);

  @override
  RuleSet clone() {
    var cloneSelectorGroup = selectorGroup!.clone();
    var cloneDeclarationGroup = declarationGroup.clone();
    return RuleSet(cloneSelectorGroup, cloneDeclarationGroup, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitRuleSet(this);
}

class Directive extends TreeNode {
  Directive(SourceSpan? span) : super(span);

  bool get isBuiltIn => true; // Known CSS directive?
  bool get isExtension => false; // SCSS extension?

  @override
  SourceSpan get span => super.span!;

  @override
  Directive clone() => Directive(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitDirective(this);
}

class DocumentDirective extends Directive {
  final List<LiteralTerm> functions;
  final List<TreeNode> groupRuleBody;

  DocumentDirective(this.functions, this.groupRuleBody, SourceSpan? span)
      : super(span);

  @override
  DocumentDirective clone() {
    var clonedFunctions = <LiteralTerm>[];
    for (var function in functions) {
      clonedFunctions.add(function.clone());
    }
    var clonedGroupRuleBody = <TreeNode>[];
    for (var rule in groupRuleBody) {
      clonedGroupRuleBody.add(rule.clone());
    }
    return DocumentDirective(clonedFunctions, clonedGroupRuleBody, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitDocumentDirective(this);
}

class SupportsDirective extends Directive {
  final SupportsCondition? condition;
  final List<TreeNode> groupRuleBody;

  SupportsDirective(this.condition, this.groupRuleBody, SourceSpan? span)
      : super(span);

  @override
  SupportsDirective clone() {
    var clonedCondition = condition!.clone() as SupportsCondition;
    var clonedGroupRuleBody = <TreeNode>[];
    for (var rule in groupRuleBody) {
      clonedGroupRuleBody.add(rule.clone());
    }
    return SupportsDirective(clonedCondition, clonedGroupRuleBody, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSupportsDirective(this);
}

abstract class SupportsCondition extends TreeNode {
  SupportsCondition(SourceSpan? span) : super(span);
  @override
  SourceSpan get span => super.span!;
}

class SupportsConditionInParens extends SupportsCondition {
  /// A [Declaration] or nested [SupportsCondition].
  final TreeNode? condition;

  SupportsConditionInParens(Declaration? declaration, SourceSpan? span)
      : condition = declaration,
        super(span);

  SupportsConditionInParens.nested(
      SupportsCondition condition, SourceSpan? span)
      : condition = condition,
        super(span);

  @override
  SupportsConditionInParens clone() =>
      SupportsConditionInParens(condition!.clone() as Declaration, span);

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitSupportsConditionInParens(this);
}

class SupportsNegation extends SupportsCondition {
  final SupportsConditionInParens condition;

  SupportsNegation(this.condition, SourceSpan? span) : super(span);

  @override
  SupportsNegation clone() => SupportsNegation(condition.clone(), span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSupportsNegation(this);
}

class SupportsConjunction extends SupportsCondition {
  final List<SupportsConditionInParens> conditions;

  SupportsConjunction(this.conditions, SourceSpan? span) : super(span);

  @override
  SupportsConjunction clone() {
    var clonedConditions = <SupportsConditionInParens>[];
    for (var condition in conditions) {
      clonedConditions.add(condition.clone());
    }
    return SupportsConjunction(clonedConditions, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSupportsConjunction(this);
}

class SupportsDisjunction extends SupportsCondition {
  final List<SupportsConditionInParens> conditions;

  SupportsDisjunction(this.conditions, SourceSpan? span) : super(span);

  @override
  SupportsDisjunction clone() {
    var clonedConditions = <SupportsConditionInParens>[];
    for (var condition in conditions) {
      clonedConditions.add(condition.clone());
    }
    return SupportsDisjunction(clonedConditions, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitSupportsDisjunction(this);
}

class ViewportDirective extends Directive {
  final String name;
  final DeclarationGroup declarations;

  ViewportDirective(this.name, this.declarations, SourceSpan? span)
      : super(span);

  @override
  ViewportDirective clone() =>
      ViewportDirective(name, declarations.clone(), span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitViewportDirective(this);
}

class ImportDirective extends Directive {
  /// import name specified.
  final String import;

  /// Any media queries for this import.
  final List<MediaQuery> mediaQueries;

  ImportDirective(this.import, this.mediaQueries, SourceSpan? span)
      : super(span);

  @override
  ImportDirective clone() {
    var cloneMediaQueries = <MediaQuery>[];
    for (var mediaQuery in mediaQueries) {
      cloneMediaQueries.add(mediaQuery.clone());
    }
    return ImportDirective(import, cloneMediaQueries, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitImportDirective(this);
}

/// MediaExpression grammar:
///
///     '(' S* media_feature S* [ ':' S* expr ]? ')' S*
class MediaExpression extends TreeNode {
  final bool andOperator;
  final Identifier _mediaFeature;
  final Expressions exprs;

  MediaExpression(
      this.andOperator, this._mediaFeature, this.exprs, SourceSpan? span)
      : super(span);

  String get mediaFeature => _mediaFeature.name;

  @override
  SourceSpan get span => super.span!;

  @override
  MediaExpression clone() {
    var clonedExprs = exprs.clone();
    return MediaExpression(andOperator, _mediaFeature, clonedExprs, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitMediaExpression(this);
}

/// MediaQuery grammar:
///
///      : [ONLY | NOT]? S* media_type S* [ AND S* media_expression ]*
///      | media_expression [ AND S* media_expression ]*
///     media_type
///      : IDENT
///     media_expression
///      : '(' S* media_feature S* [ ':' S* expr ]? ')' S*
///     media_feature
///      : IDENT
class MediaQuery extends TreeNode {
  /// not, only or no operator.
  final int _mediaUnary;
  final Identifier? _mediaType;
  final List<MediaExpression> expressions;

  MediaQuery(
      this._mediaUnary, this._mediaType, this.expressions, SourceSpan? span)
      : super(span);

  bool get hasMediaType => _mediaType != null;
  String get mediaType => _mediaType!.name;

  bool get hasUnary => _mediaUnary != -1;
  String get unary =>
      TokenKind.idToValue(TokenKind.MEDIA_OPERATORS, _mediaUnary)!
          .toUpperCase();

  @override
  SourceSpan get span => super.span!;

  @override
  MediaQuery clone() {
    var cloneExpressions = <MediaExpression>[];
    for (var expr in expressions) {
      cloneExpressions.add(expr.clone());
    }
    return MediaQuery(_mediaUnary, _mediaType, cloneExpressions, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitMediaQuery(this);
}

class MediaDirective extends Directive {
  final List<MediaQuery> mediaQueries;
  final List<TreeNode> rules;

  MediaDirective(this.mediaQueries, this.rules, SourceSpan? span) : super(span);

  @override
  MediaDirective clone() {
    var cloneQueries = <MediaQuery>[];
    for (var mediaQuery in mediaQueries) {
      cloneQueries.add(mediaQuery.clone());
    }
    var cloneRules = <TreeNode>[];
    for (var rule in rules) {
      cloneRules.add(rule.clone());
    }
    return MediaDirective(cloneQueries, cloneRules, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitMediaDirective(this);
}

class HostDirective extends Directive {
  final List<TreeNode> rules;

  HostDirective(this.rules, SourceSpan? span) : super(span);

  @override
  HostDirective clone() {
    var cloneRules = <TreeNode>[];
    for (var rule in rules) {
      cloneRules.add(rule.clone());
    }
    return HostDirective(cloneRules, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitHostDirective(this);
}

class PageDirective extends Directive {
  final String? _ident;
  final String? _pseudoPage;
  final List<DeclarationGroup> _declsMargin;

  PageDirective(
      this._ident, this._pseudoPage, this._declsMargin, SourceSpan? span)
      : super(span);

  @override
  PageDirective clone() {
    var cloneDeclsMargin = <DeclarationGroup>[];
    for (var declMargin in _declsMargin) {
      cloneDeclsMargin.add(declMargin.clone());
    }
    return PageDirective(_ident, _pseudoPage, cloneDeclsMargin, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitPageDirective(this);

  bool get hasIdent => _ident?.isNotEmpty ?? false;
  bool get hasPseudoPage => _pseudoPage?.isNotEmpty ?? false;
}

class CharsetDirective extends Directive {
  final String charEncoding;

  CharsetDirective(this.charEncoding, SourceSpan? span) : super(span);
  @override
  CharsetDirective clone() => CharsetDirective(charEncoding, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitCharsetDirective(this);
}

class KeyFrameDirective extends Directive {
  // Either @keyframe or keyframe prefixed with @-webkit-, @-moz-, @-ms-, @-o-.
  final int _keyframeName;
  final Identifier? name;
  final List<KeyFrameBlock> _blocks;

  KeyFrameDirective(this._keyframeName, this.name, SourceSpan? span)
      : _blocks = [],
        super(span);

  void add(KeyFrameBlock block) {
    _blocks.add(block);
  }

  String? get keyFrameName {
    switch (_keyframeName) {
      case TokenKind.DIRECTIVE_KEYFRAMES:
      case TokenKind.DIRECTIVE_MS_KEYFRAMES:
        return '@keyframes';
      case TokenKind.DIRECTIVE_WEB_KIT_KEYFRAMES:
        return '@-webkit-keyframes';
      case TokenKind.DIRECTIVE_MOZ_KEYFRAMES:
        return '@-moz-keyframes';
      case TokenKind.DIRECTIVE_O_KEYFRAMES:
        return '@-o-keyframes';
    }
    return null;
  }

  @override
  KeyFrameDirective clone() {
    var directive = KeyFrameDirective(_keyframeName, name!.clone(), span);
    for (var block in _blocks) {
      directive.add(block.clone());
    }
    return directive;
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitKeyFrameDirective(this);
}

class KeyFrameBlock extends Expression {
  final Expressions _blockSelectors;
  final DeclarationGroup _declarations;

  KeyFrameBlock(this._blockSelectors, this._declarations, SourceSpan? span)
      : super(span);

  @override
  KeyFrameBlock clone() =>
      KeyFrameBlock(_blockSelectors.clone(), _declarations.clone(), span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitKeyFrameBlock(this);
}

class FontFaceDirective extends Directive {
  final DeclarationGroup _declarations;

  FontFaceDirective(this._declarations, SourceSpan? span) : super(span);

  @override
  FontFaceDirective clone() => FontFaceDirective(_declarations.clone(), span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitFontFaceDirective(this);
}

class StyletDirective extends Directive {
  final String dartClassName;
  final List<TreeNode> rules;

  StyletDirective(this.dartClassName, this.rules, SourceSpan? span)
      : super(span);

  @override
  bool get isBuiltIn => false;
  @override
  bool get isExtension => true;

  @override
  StyletDirective clone() {
    var cloneRules = <TreeNode>[];
    for (var rule in rules) {
      cloneRules.add(rule.clone());
    }
    return StyletDirective(dartClassName, cloneRules, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitStyletDirective(this);
}

class NamespaceDirective extends Directive {
  /// Namespace prefix.
  final String _prefix;

  /// URI associated with this namespace.
  final String? _uri;

  NamespaceDirective(this._prefix, this._uri, SourceSpan? span) : super(span);

  @override
  NamespaceDirective clone() => NamespaceDirective(_prefix, _uri, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitNamespaceDirective(this);

  String get prefix => _prefix.isNotEmpty ? '$_prefix ' : '';
}

/// To support Less syntax @name: expression
class VarDefinitionDirective extends Directive {
  final VarDefinition def;

  VarDefinitionDirective(this.def, SourceSpan? span) : super(span);

  @override
  VarDefinitionDirective clone() => VarDefinitionDirective(def.clone(), span);

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitVarDefinitionDirective(this);
}

class MixinDefinition extends Directive {
  final String name;
  final List<TreeNode> definedArgs;
  final bool varArgs;

  MixinDefinition(this.name, this.definedArgs, this.varArgs, SourceSpan? span)
      : super(span);

  @override
  MixinDefinition clone() {
    var cloneDefinedArgs = <TreeNode>[];
    for (var definedArg in definedArgs) {
      cloneDefinedArgs.add(definedArg.clone());
    }
    return MixinDefinition(name, cloneDefinedArgs, varArgs, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitMixinDefinition(this);
}

/// Support a Sass @mixin. See http://sass-lang.com for description.
class MixinRulesetDirective extends MixinDefinition {
  final List<TreeNode> rulesets;

  MixinRulesetDirective(String name, List<TreeNode> args, bool varArgs,
      this.rulesets, SourceSpan? span)
      : super(name, args, varArgs, span);

  @override
  MixinRulesetDirective clone() {
    var clonedArgs = <VarDefinition>[];
    for (var arg in definedArgs) {
      clonedArgs.add(arg.clone() as VarDefinition);
    }
    var clonedRulesets = <TreeNode>[];
    for (var ruleset in rulesets) {
      clonedRulesets.add(ruleset.clone());
    }
    return MixinRulesetDirective(
        name, clonedArgs, varArgs, clonedRulesets, span);
  }

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitMixinRulesetDirective(this);
}

class MixinDeclarationDirective extends MixinDefinition {
  final DeclarationGroup declarations;

  MixinDeclarationDirective(String name, List<TreeNode> args, bool varArgs,
      this.declarations, SourceSpan? span)
      : super(name, args, varArgs, span);

  @override
  MixinDeclarationDirective clone() {
    var clonedArgs = <TreeNode>[];
    for (var arg in definedArgs) {
      clonedArgs.add(arg.clone());
    }
    return MixinDeclarationDirective(
        name, clonedArgs, varArgs, declarations.clone(), span);
  }

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitMixinDeclarationDirective(this);
}

/// To support consuming a Sass mixin @include.
class IncludeDirective extends Directive {
  final String name;
  final List<List<Expression>> args;

  IncludeDirective(this.name, this.args, SourceSpan? span) : super(span);

  @override
  IncludeDirective clone() {
    var cloneArgs = <List<Expression>>[];
    for (var arg in args) {
      cloneArgs.add(arg.map((term) => term.clone()).toList());
    }
    return IncludeDirective(name, cloneArgs, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitIncludeDirective(this);
}

/// To support Sass @content.
class ContentDirective extends Directive {
  ContentDirective(SourceSpan? span) : super(span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitContentDirective(this);
}

class Declaration extends TreeNode {
  final Identifier? _property;
  final Expression? expression;

  /// Style exposed to Dart.
  DartStyleExpression? dartStyle;
  final bool important;

  /// IE CSS hacks that can only be read by a particular IE version.
  /// 7 implies IE 7 or older property (e.g., `*background: blue;`)
  ///
  /// * Note:  IE 8 or older property (e.g., `background: green\9;`) is handled
  ///   by IE8Term in declaration expression handling.
  /// * Note:  IE 6 only property with a leading underscore is a valid IDENT
  ///   since an ident can start with underscore (e.g., `_background: red;`)
  final bool isIE7;

  Declaration(this._property, this.expression, this.dartStyle, SourceSpan? span,
      {this.important = false, bool ie7 = false})
      : isIE7 = ie7,
        super(span);

  String get property => isIE7 ? '*${_property!.name}' : _property!.name;

  bool get hasDartStyle => dartStyle != null;

  @override
  SourceSpan get span => super.span!;

  @override
  Declaration clone() =>
      Declaration(_property!.clone(), expression!.clone(), dartStyle, span,
          important: important);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitDeclaration(this);
}

// TODO(terry): Consider 2 kinds of VarDefinitions static at top-level and
//              dynamic when in a declaration.  Currently, Less syntax
//              '@foo: expression' and 'var-foo: expression' in a declaration
//              are statically resolved. Better solution, if @foo or var-foo
//              are top-level are then statically resolved and var-foo in a
//              declaration group (surrounded by a selector) would be dynamic.
class VarDefinition extends Declaration {
  bool badUsage = false;

  VarDefinition(Identifier? definedName, Expression? expr, SourceSpan? span)
      : super(definedName, expr, null, span);

  String get definedName => _property!.name;

  @override
  VarDefinition clone() =>
      VarDefinition(_property!.clone(), expression?.clone(), span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitVarDefinition(this);
}

/// Node for usage of @include mixin[(args,...)] found in a declaration group
/// instead of at a ruleset (toplevel) e.g.,
///
///     div {
///       @include mixin1;
///     }
class IncludeMixinAtDeclaration extends Declaration {
  final IncludeDirective include;

  IncludeMixinAtDeclaration(this.include, SourceSpan? span)
      : super(null, null, null, span);

  @override
  IncludeMixinAtDeclaration clone() =>
      IncludeMixinAtDeclaration(include.clone(), span);

  @override
  dynamic visit(VisitorBase visitor) =>
      visitor.visitIncludeMixinAtDeclaration(this);
}

class ExtendDeclaration extends Declaration {
  final List<TreeNode> selectors;

  ExtendDeclaration(this.selectors, SourceSpan? span)
      : super(null, null, null, span);

  @override
  ExtendDeclaration clone() {
    var newSelector = selectors.map((s) => s.clone()).toList();
    return ExtendDeclaration(newSelector, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitExtendDeclaration(this);
}

class DeclarationGroup extends TreeNode {
  /// Can be either Declaration or RuleSet (if nested selector).
  final List<TreeNode> declarations;

  DeclarationGroup(this.declarations, SourceSpan? span) : super(span);

  @override
  SourceSpan get span => super.span!;

  @override
  DeclarationGroup clone() {
    var clonedDecls = declarations.map((d) => d.clone()).toList();
    return DeclarationGroup(clonedDecls, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitDeclarationGroup(this);
}

class MarginGroup extends DeclarationGroup {
  final int margin_sym; // TokenType for for @margin sym.

  MarginGroup(this.margin_sym, List<TreeNode> decls, SourceSpan? span)
      : super(decls, span);
  @override
  MarginGroup clone() =>
      MarginGroup(margin_sym, super.clone().declarations, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitMarginGroup(this);
}

class VarUsage extends Expression {
  final String name;
  final List<Expression> defaultValues;

  VarUsage(this.name, this.defaultValues, SourceSpan? span) : super(span);

  @override
  VarUsage clone() {
    var clonedValues = <Expression>[];
    for (var expr in defaultValues) {
      clonedValues.add(expr.clone());
    }
    return VarUsage(name, clonedValues, span);
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitVarUsage(this);
}

class OperatorSlash extends Expression {
  OperatorSlash(SourceSpan? span) : super(span);
  @override
  OperatorSlash clone() => OperatorSlash(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitOperatorSlash(this);
}

class OperatorComma extends Expression {
  OperatorComma(SourceSpan? span) : super(span);
  @override
  OperatorComma clone() => OperatorComma(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitOperatorComma(this);
}

class OperatorPlus extends Expression {
  OperatorPlus(SourceSpan? span) : super(span);
  @override
  OperatorPlus clone() => OperatorPlus(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitOperatorPlus(this);
}

class OperatorMinus extends Expression {
  OperatorMinus(SourceSpan? span) : super(span);
  @override
  OperatorMinus clone() => OperatorMinus(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitOperatorMinus(this);
}

class UnicodeRangeTerm extends Expression {
  final String? first;
  final String? second;

  UnicodeRangeTerm(this.first, this.second, SourceSpan? span) : super(span);

  bool get hasSecond => second != null;

  @override
  UnicodeRangeTerm clone() => UnicodeRangeTerm(first, second, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitUnicodeRangeTerm(this);
}

class LiteralTerm extends Expression {
  // TODO(terry): value and text fields can be made final once all CSS resources
  //              are copied/symlink'd in the build tool and UriVisitor in
  //              web_ui is removed.
  dynamic value;
  String text;

  LiteralTerm(this.value, this.text, SourceSpan? span) : super(span);

  @override
  LiteralTerm clone() => LiteralTerm(value, text, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitLiteralTerm(this);
}

class NumberTerm extends LiteralTerm {
  NumberTerm(value, String t, SourceSpan? span) : super(value, t, span);
  @override
  NumberTerm clone() => NumberTerm(value, text, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitNumberTerm(this);
}

class UnitTerm extends LiteralTerm {
  final int unit;

  UnitTerm(value, String t, SourceSpan? span, this.unit)
      : super(value, t, span);

  @override
  UnitTerm clone() => UnitTerm(value, text, span, unit);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitUnitTerm(this);

  String? unitToString() => TokenKind.unitToString(unit);

  @override
  String toString() => '$text${unitToString()}';
}

class LengthTerm extends UnitTerm {
  LengthTerm(value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(this.unit == TokenKind.UNIT_LENGTH_PX ||
        this.unit == TokenKind.UNIT_LENGTH_CM ||
        this.unit == TokenKind.UNIT_LENGTH_MM ||
        this.unit == TokenKind.UNIT_LENGTH_IN ||
        this.unit == TokenKind.UNIT_LENGTH_PT ||
        this.unit == TokenKind.UNIT_LENGTH_PC);
  }
  @override
  LengthTerm clone() => LengthTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitLengthTerm(this);
}

class PercentageTerm extends LiteralTerm {
  PercentageTerm(value, String t, SourceSpan? span) : super(value, t, span);
  @override
  PercentageTerm clone() => PercentageTerm(value, text, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitPercentageTerm(this);
}

class EmTerm extends LiteralTerm {
  EmTerm(value, String t, SourceSpan? span) : super(value, t, span);
  @override
  EmTerm clone() => EmTerm(value, text, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitEmTerm(this);
}

class ExTerm extends LiteralTerm {
  ExTerm(value, String t, SourceSpan? span) : super(value, t, span);
  @override
  ExTerm clone() => ExTerm(value, text, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitExTerm(this);
}

class AngleTerm extends UnitTerm {
  AngleTerm(var value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(this.unit == TokenKind.UNIT_ANGLE_DEG ||
        this.unit == TokenKind.UNIT_ANGLE_RAD ||
        this.unit == TokenKind.UNIT_ANGLE_GRAD ||
        this.unit == TokenKind.UNIT_ANGLE_TURN);
  }

  @override
  AngleTerm clone() => AngleTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitAngleTerm(this);
}

class TimeTerm extends UnitTerm {
  TimeTerm(var value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(this.unit == TokenKind.UNIT_ANGLE_DEG ||
        this.unit == TokenKind.UNIT_TIME_MS ||
        this.unit == TokenKind.UNIT_TIME_S);
  }

  @override
  TimeTerm clone() => TimeTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitTimeTerm(this);
}

class FreqTerm extends UnitTerm {
  FreqTerm(var value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(unit == TokenKind.UNIT_FREQ_HZ || unit == TokenKind.UNIT_FREQ_KHZ);
  }

  @override
  FreqTerm clone() => FreqTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitFreqTerm(this);
}

class FractionTerm extends LiteralTerm {
  FractionTerm(var value, String t, SourceSpan? span) : super(value, t, span);

  @override
  FractionTerm clone() => FractionTerm(value, text, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitFractionTerm(this);
}

class UriTerm extends LiteralTerm {
  UriTerm(String value, SourceSpan? span) : super(value, value, span);

  @override
  UriTerm clone() => UriTerm(value as String, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitUriTerm(this);
}

class ResolutionTerm extends UnitTerm {
  ResolutionTerm(var value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(unit == TokenKind.UNIT_RESOLUTION_DPI ||
        unit == TokenKind.UNIT_RESOLUTION_DPCM ||
        unit == TokenKind.UNIT_RESOLUTION_DPPX);
  }

  @override
  ResolutionTerm clone() => ResolutionTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitResolutionTerm(this);
}

class ChTerm extends UnitTerm {
  ChTerm(var value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(unit == TokenKind.UNIT_CH);
  }

  @override
  ChTerm clone() => ChTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitChTerm(this);
}

class RemTerm extends UnitTerm {
  RemTerm(var value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(unit == TokenKind.UNIT_REM);
  }

  @override
  RemTerm clone() => RemTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitRemTerm(this);
}

class ViewportTerm extends UnitTerm {
  ViewportTerm(var value, String t, SourceSpan? span,
      [int unit = TokenKind.UNIT_LENGTH_PX])
      : super(value, t, span, unit) {
    assert(unit == TokenKind.UNIT_VIEWPORT_VW ||
        unit == TokenKind.UNIT_VIEWPORT_VH ||
        unit == TokenKind.UNIT_VIEWPORT_VMIN ||
        unit == TokenKind.UNIT_VIEWPORT_VMAX);
  }

  @override
  ViewportTerm clone() => ViewportTerm(value, text, span, unit);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitViewportTerm(this);
}

/// Type to signal a bad hex value for HexColorTerm.value.
class BAD_HEX_VALUE {}

class HexColorTerm extends LiteralTerm {
  HexColorTerm(var value, String t, SourceSpan? span) : super(value, t, span);

  @override
  HexColorTerm clone() => HexColorTerm(value, text, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitHexColorTerm(this);
}

class FunctionTerm extends LiteralTerm {
  final Expressions _params;

  FunctionTerm(var value, String t, this._params, SourceSpan? span)
      : super(value, t, span);

  @override
  FunctionTerm clone() => FunctionTerm(value, text, _params.clone(), span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitFunctionTerm(this);
}

/// A "\9" was encountered at the end of the expression and before a semi-colon.
/// This is an IE trick to ignore a property or value except by IE 8 and older
/// browsers.
class IE8Term extends LiteralTerm {
  IE8Term(SourceSpan? span) : super('\\9', '\\9', span);
  @override
  IE8Term clone() => IE8Term(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitIE8Term(this);
}

class GroupTerm extends Expression {
  final List<LiteralTerm> _terms;

  GroupTerm(SourceSpan? span)
      : _terms = [],
        super(span);

  void add(LiteralTerm term) {
    _terms.add(term);
  }

  @override
  GroupTerm clone() => GroupTerm(span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitGroupTerm(this);
}

class ItemTerm extends NumberTerm {
  ItemTerm(dynamic value, String t, SourceSpan? span) : super(value, t, span);

  @override
  ItemTerm clone() => ItemTerm(value, text, span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitItemTerm(this);
}

class Expressions extends Expression {
  final List<Expression> expressions = [];

  Expressions(SourceSpan? span) : super(span);

  void add(Expression expression) {
    expressions.add(expression);
  }

  @override
  Expressions clone() {
    var clonedExprs = Expressions(span);
    for (var expr in expressions) {
      clonedExprs.add(expr.clone());
    }
    return clonedExprs;
  }

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitExpressions(this);
}

class BinaryExpression extends Expression {
  final Token op;
  final Expression x;
  final Expression y;

  BinaryExpression(this.op, this.x, this.y, SourceSpan? span) : super(span);

  @override
  BinaryExpression clone() => BinaryExpression(op, x.clone(), y.clone(), span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitBinaryExpression(this);
}

class UnaryExpression extends Expression {
  final Token op;
  final Expression self;

  UnaryExpression(this.op, this.self, SourceSpan? span) : super(span);

  @override
  UnaryExpression clone() => UnaryExpression(op, self.clone(), span);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitUnaryExpression(this);
}

abstract class DartStyleExpression extends TreeNode {
  static const int unknownType = 0;
  static const int fontStyle = 1;
  static const int marginStyle = 2;
  static const int borderStyle = 3;
  static const int paddingStyle = 4;
  static const int heightStyle = 5;
  static const int widthStyle = 6;

  final int? _styleType;
  int? priority;

  DartStyleExpression(this._styleType, SourceSpan? span) : super(span);

  // Merges give 2 DartStyleExpression (or derived from DartStyleExpression,
  // e.g., FontExpression, etc.) will merge if the two expressions are of the
  // same property name (implies same exact type e.g, FontExpression).
  DartStyleExpression? merged(DartStyleExpression newDartExpr);

  bool get isUnknown => _styleType == 0 || _styleType == null;
  bool get isFont => _styleType == fontStyle;
  bool get isMargin => _styleType == marginStyle;
  bool get isBorder => _styleType == borderStyle;
  bool get isPadding => _styleType == paddingStyle;
  bool get isHeight => _styleType == heightStyle;
  bool get isWidth => _styleType == widthStyle;
  bool get isBoxExpression => isMargin || isBorder || isPadding;

  bool isSame(DartStyleExpression other) => _styleType == other._styleType;

  @override
  SourceSpan get span => super.span!;

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitDartStyleExpression(this);
}

class FontExpression extends DartStyleExpression {
  final Font font;

  //   font-style font-variant font-weight font-size/line-height font-family
  // TODO(terry): Only px/pt for now need to handle all possible units to
  //              support calc expressions on units.
  FontExpression(SourceSpan? span,
      {Object? /* LengthTerm | num */ size,
      List<String>? family,
      int? weight,
      String? style,
      String? variant,
      LineHeight? lineHeight})
      : font = Font(
            size: (size is LengthTerm ? size.value : size) as num?,
            family: family,
            weight: weight,
            style: style,
            variant: variant,
            lineHeight: lineHeight),
        super(DartStyleExpression.fontStyle, span);

  @override
  FontExpression? merged(DartStyleExpression newFontExpr) {
    if (newFontExpr is FontExpression && isFont && newFontExpr.isFont) {
      return FontExpression.merge(this, newFontExpr);
    }
    return null;
  }

  /// Merge the two FontExpression and return the result.
  factory FontExpression.merge(FontExpression x, FontExpression y) {
    return FontExpression._merge(x, y, y.span);
  }

  FontExpression._merge(FontExpression x, FontExpression y, SourceSpan? span)
      : font = Font.merge(x.font, y.font)!,
        super(DartStyleExpression.fontStyle, span);

  @override
  FontExpression clone() => FontExpression(span,
      size: font.size,
      family: font.family,
      weight: font.weight,
      style: font.style,
      variant: font.variant,
      lineHeight: font.lineHeight);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitFontExpression(this);
}

abstract class BoxExpression extends DartStyleExpression {
  final BoxEdge? box;

  BoxExpression(int? styleType, SourceSpan? span, this.box)
      : super(styleType, span);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitBoxExpression(this);

  String get formattedBoxEdge {
    if (box!.top == box!.left &&
        box!.top == box!.bottom &&
        box!.top == box!.right) {
      return '.uniform(${box!.top})';
    } else {
      var left = box!.left ?? 0;
      var top = box!.top ?? 0;
      var right = box!.right ?? 0;
      var bottom = box!.bottom ?? 0;
      return '.clockwiseFromTop($top,$right,$bottom,$left)';
    }
  }
}

class MarginExpression extends BoxExpression {
  // TODO(terry): Does auto for margin need to be exposed to Dart UI framework?
  /// Margin expression ripped apart.
  MarginExpression(SourceSpan? span,
      {num? top, num? right, num? bottom, num? left})
      : super(DartStyleExpression.marginStyle, span,
            BoxEdge(left, top, right, bottom));

  MarginExpression.boxEdge(SourceSpan? span, BoxEdge? box)
      : super(DartStyleExpression.marginStyle, span, box);

  @override
  MarginExpression? merged(DartStyleExpression newMarginExpr) {
    if (newMarginExpr is MarginExpression &&
        isMargin &&
        newMarginExpr.isMargin) {
      return MarginExpression.merge(this, newMarginExpr);
    }

    return null;
  }

  /// Merge the two MarginExpressions and return the result.
  factory MarginExpression.merge(MarginExpression x, MarginExpression y) {
    return MarginExpression._merge(x, y, y.span);
  }

  MarginExpression._merge(
      MarginExpression x, MarginExpression y, SourceSpan? span)
      : super(x._styleType, span, BoxEdge.merge(x.box, y.box));

  @override
  MarginExpression clone() => MarginExpression(span,
      top: box!.top, right: box!.right, bottom: box!.bottom, left: box!.left);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitMarginExpression(this);
}

class BorderExpression extends BoxExpression {
  /// Border expression ripped apart.
  BorderExpression(SourceSpan? span,
      {num? top, num? right, num? bottom, num? left})
      : super(DartStyleExpression.borderStyle, span,
            BoxEdge(left, top, right, bottom));

  BorderExpression.boxEdge(SourceSpan? span, BoxEdge box)
      : super(DartStyleExpression.borderStyle, span, box);

  @override
  BorderExpression? merged(DartStyleExpression newBorderExpr) {
    if (newBorderExpr is BorderExpression &&
        isBorder &&
        newBorderExpr.isBorder) {
      return BorderExpression.merge(this, newBorderExpr);
    }

    return null;
  }

  /// Merge the two BorderExpression and return the result.
  factory BorderExpression.merge(BorderExpression x, BorderExpression y) {
    return BorderExpression._merge(x, y, y.span);
  }

  BorderExpression._merge(
      BorderExpression x, BorderExpression y, SourceSpan? span)
      : super(
            DartStyleExpression.borderStyle, span, BoxEdge.merge(x.box, y.box));

  @override
  BorderExpression clone() => BorderExpression(span,
      top: box!.top, right: box!.right, bottom: box!.bottom, left: box!.left);

  @override
  dynamic visit(VisitorBase visitor) => visitor.visitBorderExpression(this);
}

class HeightExpression extends DartStyleExpression {
  final dynamic height;

  HeightExpression(SourceSpan? span, this.height)
      : super(DartStyleExpression.heightStyle, span);

  @override
  HeightExpression? merged(DartStyleExpression newHeightExpr) {
    if (isHeight && newHeightExpr.isHeight) {
      return newHeightExpr as HeightExpression;
    }

    return null;
  }

  @override
  HeightExpression clone() => HeightExpression(span, height);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitHeightExpression(this);
}

class WidthExpression extends DartStyleExpression {
  final dynamic width;

  WidthExpression(SourceSpan? span, this.width)
      : super(DartStyleExpression.widthStyle, span);

  @override
  WidthExpression? merged(DartStyleExpression newWidthExpr) {
    if (newWidthExpr is WidthExpression && isWidth && newWidthExpr.isWidth) {
      return newWidthExpr;
    }

    return null;
  }

  @override
  WidthExpression clone() => WidthExpression(span, width);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitWidthExpression(this);
}

class PaddingExpression extends BoxExpression {
  /// Padding expression ripped apart.
  PaddingExpression(SourceSpan? span,
      {num? top, num? right, num? bottom, num? left})
      : super(DartStyleExpression.paddingStyle, span,
            BoxEdge(left, top, right, bottom));

  PaddingExpression.boxEdge(SourceSpan? span, BoxEdge? box)
      : super(DartStyleExpression.paddingStyle, span, box);

  @override
  PaddingExpression? merged(DartStyleExpression newPaddingExpr) {
    if (newPaddingExpr is PaddingExpression &&
        isPadding &&
        newPaddingExpr.isPadding) {
      return PaddingExpression.merge(this, newPaddingExpr);
    }

    return null;
  }

  /// Merge the two PaddingExpression and return the result.
  factory PaddingExpression.merge(PaddingExpression x, PaddingExpression y) {
    return PaddingExpression._merge(x, y, y.span);
  }

  PaddingExpression._merge(
      PaddingExpression x, PaddingExpression y, SourceSpan? span)
      : super(DartStyleExpression.paddingStyle, span,
            BoxEdge.merge(x.box, y.box));

  @override
  PaddingExpression clone() => PaddingExpression(span,
      top: box!.top, right: box!.right, bottom: box!.bottom, left: box!.left);
  @override
  dynamic visit(VisitorBase visitor) => visitor.visitPaddingExpression(this);
}
