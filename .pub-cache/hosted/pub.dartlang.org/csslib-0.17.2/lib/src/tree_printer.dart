// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../visitor.dart';

// TODO(terry): Enable class for debug only; when conditional imports enabled.

/// Helper function to dump the CSS AST.
String treeToDebugString(StyleSheet styleSheet, [bool useSpan = false]) {
  var to = TreeOutput();
  _TreePrinter(to, useSpan).visitTree(styleSheet);
  return to.toString();
}

/// Tree dump for debug output of the CSS AST.
class _TreePrinter extends Visitor {
  final TreeOutput output;
  final bool useSpan;
  _TreePrinter(this.output, this.useSpan) {
    output.printer = this;
  }

  @override
  void visitTree(StyleSheet tree) => visitStylesheet(tree);

  void heading(String heading, TreeNode node) {
    if (useSpan) {
      output.heading(heading, node.span);
    } else {
      output.heading(heading);
    }
  }

  void visitStylesheet(StyleSheet node) {
    heading('Stylesheet', node);
    output.depth++;
    super.visitStyleSheet(node);
    output.depth--;
  }

  @override
  void visitTopLevelProduction(TopLevelProduction node) {
    heading('TopLevelProduction', node);
  }

  @override
  void visitDirective(Directive node) {
    heading('Directive', node);
  }

  @override
  void visitCalcTerm(CalcTerm node) {
    heading('CalcTerm', node);
    output.depth++;
    super.visitCalcTerm(node);
    output.depth--;
  }

  @override
  void visitCssComment(CssComment node) {
    heading('Comment', node);
    output.depth++;
    output.writeValue('comment value', node.comment);
    output.depth--;
  }

  @override
  void visitCommentDefinition(CommentDefinition node) {
    heading('CommentDefinition (CDO/CDC)', node);
    output.depth++;
    output.writeValue('comment value', node.comment);
    output.depth--;
  }

  @override
  void visitMediaExpression(MediaExpression node) {
    heading('MediaExpression', node);
    output.writeValue('feature', node.mediaFeature);
    if (node.andOperator) output.writeValue('AND operator', '');
    visitExpressions(node.exprs);
  }

  void visitMediaQueries(MediaQuery query) {
    output.heading('MediaQueries');
    output.writeValue('unary', query.unary);
    output.writeValue('media type', query.mediaType);
    output.writeNodeList('media expressions', query.expressions);
  }

  @override
  void visitMediaDirective(MediaDirective node) {
    heading('MediaDirective', node);
    output.depth++;
    output.writeNodeList('media queries', node.mediaQueries);
    output.writeNodeList('rule sets', node.rules);
    super.visitMediaDirective(node);
    output.depth--;
  }

  @override
  void visitDocumentDirective(DocumentDirective node) {
    heading('DocumentDirective', node);
    output.depth++;
    output.writeNodeList('functions', node.functions);
    output.writeNodeList('group rule body', node.groupRuleBody);
    output.depth--;
  }

  @override
  void visitSupportsDirective(SupportsDirective node) {
    heading('SupportsDirective', node);
    output.depth++;
    output.writeNode('condition', node.condition);
    output.writeNodeList('group rule body', node.groupRuleBody);
    output.depth--;
  }

  @override
  void visitSupportsConditionInParens(SupportsConditionInParens node) {
    heading('SupportsConditionInParens', node);
    output.depth++;
    output.writeNode('condition', node.condition);
    output.depth--;
  }

  @override
  void visitSupportsNegation(SupportsNegation node) {
    heading('SupportsNegation', node);
    output.depth++;
    output.writeNode('condition', node.condition);
    output.depth--;
  }

  @override
  void visitSupportsConjunction(SupportsConjunction node) {
    heading('SupportsConjunction', node);
    output.depth++;
    output.writeNodeList('conditions', node.conditions);
    output.depth--;
  }

  @override
  void visitSupportsDisjunction(SupportsDisjunction node) {
    heading('SupportsDisjunction', node);
    output.depth++;
    output.writeNodeList('conditions', node.conditions);
    output.depth--;
  }

  @override
  void visitViewportDirective(ViewportDirective node) {
    heading('ViewportDirective', node);
    output.depth++;
    super.visitViewportDirective(node);
    output.depth--;
  }

  @override
  void visitPageDirective(PageDirective node) {
    heading('PageDirective', node);
    output.depth++;
    output.writeValue('pseudo page', node._pseudoPage);
    super.visitPageDirective(node);
    output.depth;
  }

  @override
  void visitCharsetDirective(CharsetDirective node) {
    heading('Charset Directive', node);
    output.writeValue('charset encoding', node.charEncoding);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    heading('ImportDirective', node);
    output.depth++;
    output.writeValue('import', node.import);
    super.visitImportDirective(node);
    output.writeNodeList('media', node.mediaQueries);
    output.depth--;
  }

  @override
  void visitContentDirective(ContentDirective node) {
    print('ContentDirective not implemented');
  }

  @override
  void visitKeyFrameDirective(KeyFrameDirective node) {
    heading('KeyFrameDirective', node);
    output.depth++;
    output.writeValue('keyframe', node.keyFrameName);
    output.writeValue('name', node.name);
    output.writeNodeList('blocks', node._blocks);
    output.depth--;
  }

  @override
  void visitKeyFrameBlock(KeyFrameBlock node) {
    heading('KeyFrameBlock', node);
    output.depth++;
    super.visitKeyFrameBlock(node);
    output.depth--;
  }

  @override
  void visitFontFaceDirective(FontFaceDirective node) {
    // TODO(terry): To Be Implemented
  }

  @override
  void visitStyletDirective(StyletDirective node) {
    heading('StyletDirective', node);
    output.writeValue('dartClassName', node.dartClassName);
    output.depth++;
    output.writeNodeList('rulesets', node.rules);
    output.depth--;
  }

  @override
  void visitNamespaceDirective(NamespaceDirective node) {
    heading('NamespaceDirective', node);
    output.depth++;
    output.writeValue('prefix', node._prefix);
    output.writeValue('uri', node._uri);
    output.depth--;
  }

  @override
  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    heading('Less variable definition', node);
    output.depth++;
    visitVarDefinition(node.def);
    output.depth--;
  }

  @override
  void visitMixinRulesetDirective(MixinRulesetDirective node) {
    heading('Mixin top-level ${node.name}', node);
    output.writeNodeList('parameters', node.definedArgs);
    output.depth++;
    _visitNodeList(node.rulesets);
    output.depth--;
  }

  @override
  void visitMixinDeclarationDirective(MixinDeclarationDirective node) {
    heading('Mixin declaration ${node.name}', node);
    output.writeNodeList('parameters', node.definedArgs);
    output.depth++;
    visitDeclarationGroup(node.declarations);
    output.depth--;
  }

  /// Added optional newLine for handling @include at top-level vs/ inside of
  /// a declaration group.
  @override
  void visitIncludeDirective(IncludeDirective node) {
    heading('IncludeDirective ${node.name}', node);
    var flattened = node.args.expand((e) => e).toList();
    output.writeNodeList('parameters', flattened);
  }

  @override
  void visitIncludeMixinAtDeclaration(IncludeMixinAtDeclaration node) {
    heading('IncludeMixinAtDeclaration ${node.include.name}', node);
    output.depth++;
    visitIncludeDirective(node.include);
    output.depth--;
  }

  @override
  void visitExtendDeclaration(ExtendDeclaration node) {
    heading('ExtendDeclaration', node);
    output.depth++;
    _visitNodeList(node.selectors);
    output.depth--;
  }

  @override
  void visitRuleSet(RuleSet node) {
    heading('Ruleset', node);
    output.depth++;
    super.visitRuleSet(node);
    output.depth--;
  }

  @override
  void visitDeclarationGroup(DeclarationGroup node) {
    heading('DeclarationGroup', node);
    output.depth++;
    output.writeNodeList('declarations', node.declarations);
    output.depth--;
  }

  @override
  void visitMarginGroup(MarginGroup node) {
    heading('MarginGroup', node);
    output.depth++;
    output.writeValue('@directive', node.margin_sym);
    output.writeNodeList('declarations', node.declarations);
    output.depth--;
  }

  @override
  void visitDeclaration(Declaration node) {
    heading('Declaration', node);
    output.depth++;
    if (node.isIE7) output.write('IE7 property');
    output.write('property');
    super.visitDeclaration(node);
    output.writeNode('expression', node.expression);
    if (node.important) {
      output.writeValue('!important', 'true');
    }
    output.depth--;
  }

  @override
  void visitVarDefinition(VarDefinition node) {
    heading('Var', node);
    output.depth++;
    output.write('defintion');
    super.visitVarDefinition(node);
    output.writeNode('expression', node.expression);
    output.depth--;
  }

  @override
  void visitSelectorGroup(SelectorGroup node) {
    heading('Selector Group', node);
    output.depth++;
    output.writeNodeList('selectors', node.selectors);
    output.depth--;
  }

  @override
  void visitSelector(Selector node) {
    heading('Selector', node);
    output.depth++;
    output.writeNodeList(
        'simpleSelectorsSequences', node.simpleSelectorSequences);
    output.depth--;
  }

  @override
  void visitSimpleSelectorSequence(SimpleSelectorSequence node) {
    heading('SimpleSelectorSequence', node);
    output.depth++;
    if (node.isCombinatorNone) {
      output.writeValue('combinator', 'NONE');
    } else if (node.isCombinatorDescendant) {
      output.writeValue('combinator', 'descendant');
    } else if (node.isCombinatorPlus) {
      output.writeValue('combinator', '+');
    } else if (node.isCombinatorGreater) {
      output.writeValue('combinator', '>');
    } else if (node.isCombinatorTilde) {
      output.writeValue('combinator', '~');
    } else {
      output.writeValue('combinator', 'ERROR UNKNOWN');
    }

    super.visitSimpleSelectorSequence(node);

    output.depth--;
  }

  @override
  void visitNamespaceSelector(NamespaceSelector node) {
    heading('Namespace Selector', node);
    output.depth++;

    super.visitNamespaceSelector(node);

    visitSimpleSelector(node.nameAsSimpleSelector!);
    output.depth--;
  }

  @override
  void visitElementSelector(ElementSelector node) {
    heading('Element Selector', node);
    output.depth++;
    super.visitElementSelector(node);
    output.depth--;
  }

  @override
  void visitAttributeSelector(AttributeSelector node) {
    heading('AttributeSelector', node);
    output.depth++;
    super.visitAttributeSelector(node);
    var tokenStr = node.matchOperatorAsTokenString();
    output.writeValue('operator', '${node.matchOperator()} ($tokenStr)');
    output.writeValue('value', node.valueToString());
    output.depth--;
  }

  @override
  void visitIdSelector(IdSelector node) {
    heading('Id Selector', node);
    output.depth++;
    super.visitIdSelector(node);
    output.depth--;
  }

  @override
  void visitClassSelector(ClassSelector node) {
    heading('Class Selector', node);
    output.depth++;
    super.visitClassSelector(node);
    output.depth--;
  }

  @override
  void visitPseudoClassSelector(PseudoClassSelector node) {
    heading('Pseudo Class Selector', node);
    output.depth++;
    super.visitPseudoClassSelector(node);
    output.depth--;
  }

  @override
  void visitPseudoElementSelector(PseudoElementSelector node) {
    heading('Pseudo Element Selector', node);
    output.depth++;
    super.visitPseudoElementSelector(node);
    output.depth--;
  }

  @override
  void visitPseudoClassFunctionSelector(PseudoClassFunctionSelector node) {
    heading('Pseudo Class Function Selector', node);
    output.depth++;
    node.argument.visit(this);
    super.visitPseudoClassFunctionSelector(node);
    output.depth--;
  }

  @override
  void visitPseudoElementFunctionSelector(PseudoElementFunctionSelector node) {
    heading('Pseudo Element Function Selector', node);
    output.depth++;
    visitSelectorExpression(node.expression);
    super.visitPseudoElementFunctionSelector(node);
    output.depth--;
  }

  @override
  void visitSelectorExpression(SelectorExpression node) {
    heading('Selector Expression', node);
    output.depth++;
    output.writeNodeList('expressions', node.expressions);
    output.depth--;
  }

  @override
  void visitNegationSelector(NegationSelector node) {
    super.visitNegationSelector(node);
    output.depth++;
    heading('Negation Selector', node);
    output.writeNode('Negation arg', node.negationArg);
    output.depth--;
  }

  @override
  void visitUnicodeRangeTerm(UnicodeRangeTerm node) {
    heading('UnicodeRangeTerm', node);
    output.depth++;
    output.writeValue('1st value', node.first);
    output.writeValue('2nd value', node.second);
    output.depth--;
  }

  @override
  void visitLiteralTerm(LiteralTerm node) {
    heading('LiteralTerm', node);
    output.depth++;
    output.writeValue('value', node.text);
    output.depth--;
  }

  @override
  void visitHexColorTerm(HexColorTerm node) {
    heading('HexColorTerm', node);
    output.depth++;
    output.writeValue('hex value', node.text);
    output.writeValue('decimal value', node.value);
    output.depth--;
  }

  @override
  void visitNumberTerm(NumberTerm node) {
    heading('NumberTerm', node);
    output.depth++;
    output.writeValue('value', node.text);
    output.depth--;
  }

  @override
  void visitUnitTerm(UnitTerm node) {
    output.depth++;
    output.writeValue('value', node.text);
    output.writeValue('unit', node.unitToString());
    output.depth--;
  }

  @override
  void visitLengthTerm(LengthTerm node) {
    heading('LengthTerm', node);
    super.visitLengthTerm(node);
  }

  @override
  void visitPercentageTerm(PercentageTerm node) {
    heading('PercentageTerm', node);
    output.depth++;
    super.visitPercentageTerm(node);
    output.depth--;
  }

  @override
  void visitEmTerm(EmTerm node) {
    heading('EmTerm', node);
    output.depth++;
    super.visitEmTerm(node);
    output.depth--;
  }

  @override
  void visitExTerm(ExTerm node) {
    heading('ExTerm', node);
    output.depth++;
    super.visitExTerm(node);
    output.depth--;
  }

  @override
  void visitAngleTerm(AngleTerm node) {
    heading('AngleTerm', node);
    super.visitAngleTerm(node);
  }

  @override
  void visitTimeTerm(TimeTerm node) {
    heading('TimeTerm', node);
    super.visitTimeTerm(node);
  }

  @override
  void visitFreqTerm(FreqTerm node) {
    heading('FreqTerm', node);
    super.visitFreqTerm(node);
  }

  @override
  void visitFractionTerm(FractionTerm node) {
    heading('FractionTerm', node);
    output.depth++;
    super.visitFractionTerm(node);
    output.depth--;
  }

  @override
  void visitUriTerm(UriTerm node) {
    heading('UriTerm', node);
    output.depth++;
    super.visitUriTerm(node);
    output.depth--;
  }

  @override
  void visitFunctionTerm(FunctionTerm node) {
    heading('FunctionTerm', node);
    output.depth++;
    super.visitFunctionTerm(node);
    output.depth--;
  }

  @override
  void visitGroupTerm(GroupTerm node) {
    heading('GroupTerm', node);
    output.depth++;
    output.writeNodeList('grouped terms', node._terms);
    output.depth--;
  }

  @override
  void visitItemTerm(ItemTerm node) {
    heading('ItemTerm', node);
    super.visitItemTerm(node);
  }

  @override
  void visitIE8Term(IE8Term node) {
    heading('IE8Term', node);
    visitLiteralTerm(node);
  }

  @override
  void visitOperatorSlash(OperatorSlash node) {
    heading('OperatorSlash', node);
  }

  @override
  void visitOperatorComma(OperatorComma node) {
    heading('OperatorComma', node);
  }

  @override
  void visitOperatorPlus(OperatorPlus node) {
    heading('OperatorPlus', node);
  }

  @override
  void visitOperatorMinus(OperatorMinus node) {
    heading('OperatorMinus', node);
  }

  @override
  void visitVarUsage(VarUsage node) {
    heading('Var', node);
    output.depth++;
    output.write('usage ${node.name}');
    output.writeNodeList('default values', node.defaultValues);
    output.depth--;
  }

  @override
  void visitExpressions(Expressions node) {
    heading('Expressions', node);
    output.depth++;
    output.writeNodeList('expressions', node.expressions);
    output.depth--;
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    heading('BinaryExpression', node);
    // TODO(terry): TBD
  }

  @override
  void visitUnaryExpression(UnaryExpression node) {
    heading('UnaryExpression', node);
    // TODO(terry): TBD
  }

  @override
  void visitIdentifier(Identifier node) {
    heading('Identifier(${output.toValue(node.name)})', node);
  }

  @override
  void visitWildcard(Wildcard node) {
    heading('Wildcard(*)', node);
  }

  @override
  void visitDartStyleExpression(DartStyleExpression node) {
    heading('DartStyleExpression', node);
  }

  @override
  void visitFontExpression(FontExpression node) {
    heading('Dart Style FontExpression', node);
  }

  @override
  void visitBoxExpression(BoxExpression node) {
    heading('Dart Style BoxExpression', node);
  }

  @override
  void visitMarginExpression(MarginExpression node) {
    heading('Dart Style MarginExpression', node);
  }

  @override
  void visitBorderExpression(BorderExpression node) {
    heading('Dart Style BorderExpression', node);
  }

  @override
  void visitHeightExpression(HeightExpression node) {
    heading('Dart Style HeightExpression', node);
  }

  @override
  void visitPaddingExpression(PaddingExpression node) {
    heading('Dart Style PaddingExpression', node);
  }

  @override
  void visitWidthExpression(WidthExpression node) {
    heading('Dart Style WidthExpression', node);
  }
}
