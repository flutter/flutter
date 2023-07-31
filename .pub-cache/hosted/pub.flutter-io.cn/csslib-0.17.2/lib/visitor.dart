// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'parser.dart';

part 'src/css_printer.dart';
part 'src/tree.dart';
part 'src/tree_base.dart';
part 'src/tree_printer.dart';

abstract class VisitorBase {
  dynamic visitCalcTerm(CalcTerm node);
  dynamic visitCssComment(CssComment node);
  dynamic visitCommentDefinition(CommentDefinition node);
  dynamic visitStyleSheet(StyleSheet node);
  dynamic visitNoOp(NoOp node);
  dynamic visitTopLevelProduction(TopLevelProduction node);
  dynamic visitDirective(Directive node);
  dynamic visitDocumentDirective(DocumentDirective node);
  dynamic visitSupportsDirective(SupportsDirective node);
  dynamic visitSupportsConditionInParens(SupportsConditionInParens node);
  dynamic visitSupportsNegation(SupportsNegation node);
  dynamic visitSupportsConjunction(SupportsConjunction node);
  dynamic visitSupportsDisjunction(SupportsDisjunction node);
  dynamic visitViewportDirective(ViewportDirective node);
  dynamic visitMediaExpression(MediaExpression node);
  dynamic visitMediaQuery(MediaQuery node);
  dynamic visitMediaDirective(MediaDirective node);
  dynamic visitHostDirective(HostDirective node);
  dynamic visitPageDirective(PageDirective node);
  dynamic visitCharsetDirective(CharsetDirective node);
  dynamic visitImportDirective(ImportDirective node);
  dynamic visitKeyFrameDirective(KeyFrameDirective node);
  dynamic visitKeyFrameBlock(KeyFrameBlock node);
  dynamic visitFontFaceDirective(FontFaceDirective node);
  dynamic visitStyletDirective(StyletDirective node);
  dynamic visitNamespaceDirective(NamespaceDirective node);
  dynamic visitVarDefinitionDirective(VarDefinitionDirective node);
  dynamic visitMixinDefinition(MixinDefinition node);
  dynamic visitMixinRulesetDirective(MixinRulesetDirective node);
  dynamic visitMixinDeclarationDirective(MixinDeclarationDirective node);
  dynamic visitIncludeDirective(IncludeDirective node);
  dynamic visitContentDirective(ContentDirective node);

  dynamic visitRuleSet(RuleSet node);
  dynamic visitDeclarationGroup(DeclarationGroup node);
  dynamic visitMarginGroup(MarginGroup node);
  dynamic visitDeclaration(Declaration node);
  dynamic visitVarDefinition(VarDefinition node);
  dynamic visitIncludeMixinAtDeclaration(IncludeMixinAtDeclaration node);
  dynamic visitExtendDeclaration(ExtendDeclaration node);
  dynamic visitSelectorGroup(SelectorGroup node);
  dynamic visitSelector(Selector node);
  dynamic visitSimpleSelectorSequence(SimpleSelectorSequence node);
  dynamic visitSimpleSelector(SimpleSelector node);
  dynamic visitElementSelector(ElementSelector node);
  dynamic visitNamespaceSelector(NamespaceSelector node);
  dynamic visitAttributeSelector(AttributeSelector node);
  dynamic visitIdSelector(IdSelector node);
  dynamic visitClassSelector(ClassSelector node);
  dynamic visitPseudoClassSelector(PseudoClassSelector node);
  dynamic visitPseudoElementSelector(PseudoElementSelector node);
  dynamic visitPseudoClassFunctionSelector(PseudoClassFunctionSelector node);
  dynamic visitPseudoElementFunctionSelector(
      PseudoElementFunctionSelector node);
  dynamic visitNegationSelector(NegationSelector node);
  dynamic visitSelectorExpression(SelectorExpression node);

  dynamic visitUnicodeRangeTerm(UnicodeRangeTerm node);
  dynamic visitLiteralTerm(LiteralTerm node);
  dynamic visitHexColorTerm(HexColorTerm node);
  dynamic visitNumberTerm(NumberTerm node);
  dynamic visitUnitTerm(UnitTerm node);
  dynamic visitLengthTerm(LengthTerm node);
  dynamic visitPercentageTerm(PercentageTerm node);
  dynamic visitEmTerm(EmTerm node);
  dynamic visitExTerm(ExTerm node);
  dynamic visitAngleTerm(AngleTerm node);
  dynamic visitTimeTerm(TimeTerm node);
  dynamic visitFreqTerm(FreqTerm node);
  dynamic visitFractionTerm(FractionTerm node);
  dynamic visitUriTerm(UriTerm node);
  dynamic visitResolutionTerm(ResolutionTerm node);
  dynamic visitChTerm(ChTerm node);
  dynamic visitRemTerm(RemTerm node);
  dynamic visitViewportTerm(ViewportTerm node);
  dynamic visitFunctionTerm(FunctionTerm node);
  dynamic visitGroupTerm(GroupTerm node);
  dynamic visitItemTerm(ItemTerm node);
  dynamic visitIE8Term(IE8Term node);
  dynamic visitOperatorSlash(OperatorSlash node);
  dynamic visitOperatorComma(OperatorComma node);
  dynamic visitOperatorPlus(OperatorPlus node);
  dynamic visitOperatorMinus(OperatorMinus node);
  dynamic visitVarUsage(VarUsage node);

  dynamic visitExpressions(Expressions node);
  dynamic visitBinaryExpression(BinaryExpression node);
  dynamic visitUnaryExpression(UnaryExpression node);

  dynamic visitIdentifier(Identifier node);
  dynamic visitWildcard(Wildcard node);
  dynamic visitThisOperator(ThisOperator node);
  dynamic visitNegation(Negation node);

  dynamic visitDartStyleExpression(DartStyleExpression node);
  dynamic visitFontExpression(FontExpression node);
  dynamic visitBoxExpression(BoxExpression node);
  dynamic visitMarginExpression(MarginExpression node);
  dynamic visitBorderExpression(BorderExpression node);
  dynamic visitHeightExpression(HeightExpression node);
  dynamic visitPaddingExpression(PaddingExpression node);
  dynamic visitWidthExpression(WidthExpression node);
}

/// Base vistor class for the style sheet AST.
class Visitor implements VisitorBase {
  /// Helper function to walk a list of nodes.
  void _visitNodeList(List<TreeNode> list) {
    // Don't use iterable otherwise the list can't grow while using Visitor.
    // It certainly can't have items deleted before the index being iterated
    // but items could be added after the index.
    for (var index = 0; index < list.length; index++) {
      list[index].visit(this);
    }
  }

  dynamic visitTree(StyleSheet tree) => visitStyleSheet(tree);

  @override
  dynamic visitStyleSheet(StyleSheet ss) {
    _visitNodeList(ss.topLevels);
  }

  @override
  dynamic visitNoOp(NoOp node) {}

  @override
  dynamic visitTopLevelProduction(TopLevelProduction node) {}

  @override
  dynamic visitDirective(Directive node) {}

  @override
  dynamic visitCalcTerm(CalcTerm node) {
    visitLiteralTerm(node);
    visitLiteralTerm(node.expr);
  }

  @override
  dynamic visitCssComment(CssComment node) {}

  @override
  dynamic visitCommentDefinition(CommentDefinition node) {}

  @override
  dynamic visitMediaExpression(MediaExpression node) {
    visitExpressions(node.exprs);
  }

  @override
  dynamic visitMediaQuery(MediaQuery node) {
    for (var mediaExpr in node.expressions) {
      visitMediaExpression(mediaExpr);
    }
  }

  @override
  dynamic visitDocumentDirective(DocumentDirective node) {
    _visitNodeList(node.functions);
    _visitNodeList(node.groupRuleBody);
  }

  @override
  dynamic visitSupportsDirective(SupportsDirective node) {
    node.condition!.visit(this);
    _visitNodeList(node.groupRuleBody);
  }

  @override
  dynamic visitSupportsConditionInParens(SupportsConditionInParens node) {
    node.condition!.visit(this);
  }

  @override
  dynamic visitSupportsNegation(SupportsNegation node) {
    node.condition.visit(this);
  }

  @override
  dynamic visitSupportsConjunction(SupportsConjunction node) {
    _visitNodeList(node.conditions);
  }

  @override
  dynamic visitSupportsDisjunction(SupportsDisjunction node) {
    _visitNodeList(node.conditions);
  }

  @override
  dynamic visitViewportDirective(ViewportDirective node) {
    node.declarations.visit(this);
  }

  @override
  dynamic visitMediaDirective(MediaDirective node) {
    _visitNodeList(node.mediaQueries);
    _visitNodeList(node.rules);
  }

  @override
  dynamic visitHostDirective(HostDirective node) {
    _visitNodeList(node.rules);
  }

  @override
  dynamic visitPageDirective(PageDirective node) {
    for (var declGroup in node._declsMargin) {
      if (declGroup is MarginGroup) {
        visitMarginGroup(declGroup);
      } else {
        visitDeclarationGroup(declGroup);
      }
    }
  }

  @override
  dynamic visitCharsetDirective(CharsetDirective node) {}

  @override
  dynamic visitImportDirective(ImportDirective node) {
    for (var mediaQuery in node.mediaQueries) {
      visitMediaQuery(mediaQuery);
    }
  }

  @override
  dynamic visitKeyFrameDirective(KeyFrameDirective node) {
    visitIdentifier(node.name!);
    _visitNodeList(node._blocks);
  }

  @override
  dynamic visitKeyFrameBlock(KeyFrameBlock node) {
    visitExpressions(node._blockSelectors);
    visitDeclarationGroup(node._declarations);
  }

  @override
  dynamic visitFontFaceDirective(FontFaceDirective node) {
    visitDeclarationGroup(node._declarations);
  }

  @override
  dynamic visitStyletDirective(StyletDirective node) {
    _visitNodeList(node.rules);
  }

  @override
  dynamic visitNamespaceDirective(NamespaceDirective node) {}

  @override
  dynamic visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
  }

  @override
  dynamic visitMixinRulesetDirective(MixinRulesetDirective node) {
    _visitNodeList(node.rulesets);
  }

  @override
  dynamic visitMixinDefinition(MixinDefinition node) {}

  @override
  dynamic visitMixinDeclarationDirective(MixinDeclarationDirective node) {
    visitDeclarationGroup(node.declarations);
  }

  @override
  dynamic visitIncludeDirective(IncludeDirective node) {
    for (var index = 0; index < node.args.length; index++) {
      var param = node.args[index];
      _visitNodeList(param);
    }
  }

  @override
  dynamic visitContentDirective(ContentDirective node) {
    // TODO(terry): TBD
  }

  @override
  dynamic visitRuleSet(RuleSet node) {
    visitSelectorGroup(node.selectorGroup!);
    visitDeclarationGroup(node.declarationGroup);
  }

  @override
  dynamic visitDeclarationGroup(DeclarationGroup node) {
    _visitNodeList(node.declarations);
  }

  @override
  dynamic visitMarginGroup(MarginGroup node) => visitDeclarationGroup(node);

  @override
  dynamic visitDeclaration(Declaration node) {
    visitIdentifier(node._property!);
    if (node.expression != null) node.expression!.visit(this);
  }

  @override
  dynamic visitVarDefinition(VarDefinition node) {
    visitIdentifier(node._property!);
    if (node.expression != null) node.expression!.visit(this);
  }

  @override
  dynamic visitIncludeMixinAtDeclaration(IncludeMixinAtDeclaration node) {
    visitIncludeDirective(node.include);
  }

  @override
  dynamic visitExtendDeclaration(ExtendDeclaration node) {
    _visitNodeList(node.selectors);
  }

  @override
  dynamic visitSelectorGroup(SelectorGroup node) {
    _visitNodeList(node.selectors);
  }

  @override
  dynamic visitSelector(Selector node) {
    _visitNodeList(node.simpleSelectorSequences);
  }

  @override
  dynamic visitSimpleSelectorSequence(SimpleSelectorSequence node) {
    node.simpleSelector.visit(this);
  }

  @override
  dynamic visitSimpleSelector(SimpleSelector node) =>
      (node._name as TreeNode).visit(this);

  @override
  dynamic visitNamespaceSelector(NamespaceSelector node) {
    if (node._namespace != null) (node._namespace as TreeNode).visit(this);
    if (node.nameAsSimpleSelector != null) {
      node.nameAsSimpleSelector!.visit(this);
    }
  }

  @override
  dynamic visitElementSelector(ElementSelector node) =>
      visitSimpleSelector(node);

  @override
  dynamic visitAttributeSelector(AttributeSelector node) {
    visitSimpleSelector(node);
  }

  @override
  dynamic visitIdSelector(IdSelector node) => visitSimpleSelector(node);

  @override
  dynamic visitClassSelector(ClassSelector node) => visitSimpleSelector(node);

  @override
  dynamic visitPseudoClassSelector(PseudoClassSelector node) =>
      visitSimpleSelector(node);

  @override
  dynamic visitPseudoElementSelector(PseudoElementSelector node) =>
      visitSimpleSelector(node);

  @override
  dynamic visitPseudoClassFunctionSelector(PseudoClassFunctionSelector node) =>
      visitSimpleSelector(node);

  @override
  dynamic visitPseudoElementFunctionSelector(
          PseudoElementFunctionSelector node) =>
      visitSimpleSelector(node);

  @override
  dynamic visitNegationSelector(NegationSelector node) =>
      visitSimpleSelector(node);

  @override
  dynamic visitSelectorExpression(SelectorExpression node) {
    _visitNodeList(node.expressions);
  }

  @override
  dynamic visitUnicodeRangeTerm(UnicodeRangeTerm node) {}

  @override
  dynamic visitLiteralTerm(LiteralTerm node) {}

  @override
  dynamic visitHexColorTerm(HexColorTerm node) {}

  @override
  dynamic visitNumberTerm(NumberTerm node) {}

  @override
  dynamic visitUnitTerm(UnitTerm node) {}

  @override
  dynamic visitLengthTerm(LengthTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitPercentageTerm(PercentageTerm node) {
    visitLiteralTerm(node);
  }

  @override
  dynamic visitEmTerm(EmTerm node) {
    visitLiteralTerm(node);
  }

  @override
  dynamic visitExTerm(ExTerm node) {
    visitLiteralTerm(node);
  }

  @override
  dynamic visitAngleTerm(AngleTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitTimeTerm(TimeTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitFreqTerm(FreqTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitFractionTerm(FractionTerm node) {
    visitLiteralTerm(node);
  }

  @override
  dynamic visitUriTerm(UriTerm node) {
    visitLiteralTerm(node);
  }

  @override
  dynamic visitResolutionTerm(ResolutionTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitChTerm(ChTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitRemTerm(RemTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitViewportTerm(ViewportTerm node) {
    visitUnitTerm(node);
  }

  @override
  dynamic visitFunctionTerm(FunctionTerm node) {
    visitLiteralTerm(node);
    visitExpressions(node._params);
  }

  @override
  dynamic visitGroupTerm(GroupTerm node) {
    for (var term in node._terms) {
      term.visit(this);
    }
  }

  @override
  dynamic visitItemTerm(ItemTerm node) {
    visitNumberTerm(node);
  }

  @override
  dynamic visitIE8Term(IE8Term node) {}

  @override
  dynamic visitOperatorSlash(OperatorSlash node) {}

  @override
  dynamic visitOperatorComma(OperatorComma node) {}

  @override
  dynamic visitOperatorPlus(OperatorPlus node) {}

  @override
  dynamic visitOperatorMinus(OperatorMinus node) {}

  @override
  dynamic visitVarUsage(VarUsage node) {
    _visitNodeList(node.defaultValues);
  }

  @override
  dynamic visitExpressions(Expressions node) {
    _visitNodeList(node.expressions);
  }

  @override
  dynamic visitBinaryExpression(BinaryExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }

  @override
  dynamic visitUnaryExpression(UnaryExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }

  @override
  dynamic visitIdentifier(Identifier node) {}

  @override
  dynamic visitWildcard(Wildcard node) {}

  @override
  dynamic visitThisOperator(ThisOperator node) {}

  @override
  dynamic visitNegation(Negation node) {}

  @override
  dynamic visitDartStyleExpression(DartStyleExpression node) {}

  @override
  dynamic visitFontExpression(FontExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }

  @override
  dynamic visitBoxExpression(BoxExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }

  @override
  dynamic visitMarginExpression(MarginExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }

  @override
  dynamic visitBorderExpression(BorderExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }

  @override
  dynamic visitHeightExpression(HeightExpression node) {
    // TODO(terry): TB
    throw UnimplementedError();
  }

  @override
  dynamic visitPaddingExpression(PaddingExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }

  @override
  dynamic visitWidthExpression(WidthExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError();
  }
}
