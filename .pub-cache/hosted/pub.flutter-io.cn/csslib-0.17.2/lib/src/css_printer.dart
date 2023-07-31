// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../visitor.dart';

/// Visitor that produces a formatted string representation of the CSS tree.
class CssPrinter extends Visitor {
  StringBuffer _buff = StringBuffer();
  bool prettyPrint = true;
  bool _isInKeyframes = false;

  /// Walk the [tree] Stylesheet. [pretty] if true emits line breaks, extra
  /// spaces, friendly property values, etc., if false emits compacted output.
  @override
  void visitTree(StyleSheet tree, {bool pretty = false}) {
    prettyPrint = pretty;
    _buff = StringBuffer();
    visitStyleSheet(tree);
  }

  /// Appends [str] to the output buffer.
  void emit(String str) {
    _buff.write(str);
  }

  /// Returns the output buffer.
  @override
  String toString() => _buff.toString().trim();

  String get _newLine => prettyPrint ? '\n' : '';
  String get _sp => prettyPrint ? ' ' : '';

  // TODO(terry): When adding obfuscation we'll need isOptimized (compact w/
  //              obufuscation) and have isTesting (compact no obfuscation) and
  //              isCompact would be !prettyPrint.  We'll need another boolean
  //              flag for obfuscation.
  bool get _isTesting => !prettyPrint;

  @override
  void visitCalcTerm(CalcTerm node) {
    emit('${node.text}(');
    node.expr.visit(this);
    emit(')');
  }

  @override
  void visitCssComment(CssComment node) {
    emit('/* ${node.comment} */');
  }

  @override
  void visitCommentDefinition(CommentDefinition node) {
    emit('<!-- ${node.comment} -->');
  }

  @override
  void visitMediaExpression(MediaExpression node) {
    emit(node.andOperator ? ' AND ' : ' ');
    emit('(${node.mediaFeature}');
    if (node.exprs.expressions.isNotEmpty) {
      emit(':');
      visitExpressions(node.exprs);
    }
    emit(')');
  }

  @override
  void visitMediaQuery(MediaQuery query) {
    var unary = query.hasUnary ? ' ${query.unary}' : '';
    var mediaType = query.hasMediaType ? ' ${query.mediaType}' : '';
    emit('$unary$mediaType');
    for (var expression in query.expressions) {
      visitMediaExpression(expression);
    }
  }

  void emitMediaQueries(List<MediaQuery> queries) {
    var queriesLen = queries.length;
    for (var i = 0; i < queriesLen; i++) {
      var query = queries[i];
      if (i > 0) emit(',');
      visitMediaQuery(query);
    }
  }

  @override
  void visitDocumentDirective(DocumentDirective node) {
    emit('$_newLine@-moz-document ');
    node.functions.first.visit(this);
    for (var function in node.functions.skip(1)) {
      emit(',$_sp');
      function.visit(this);
    }
    emit('$_sp{');
    for (var ruleSet in node.groupRuleBody) {
      ruleSet.visit(this);
    }
    emit('$_newLine}');
  }

  @override
  void visitSupportsDirective(SupportsDirective node) {
    emit('$_newLine@supports ');
    node.condition!.visit(this);
    emit('$_sp{');
    for (var rule in node.groupRuleBody) {
      rule.visit(this);
    }
    emit('$_newLine}');
  }

  @override
  void visitSupportsConditionInParens(SupportsConditionInParens node) {
    emit('(');
    node.condition!.visit(this);
    emit(')');
  }

  @override
  void visitSupportsNegation(SupportsNegation node) {
    emit('not$_sp');
    node.condition.visit(this);
  }

  @override
  void visitSupportsConjunction(SupportsConjunction node) {
    node.conditions.first.visit(this);
    for (var condition in node.conditions.skip(1)) {
      emit('${_sp}and$_sp');
      condition.visit(this);
    }
  }

  @override
  void visitSupportsDisjunction(SupportsDisjunction node) {
    node.conditions.first.visit(this);
    for (var condition in node.conditions.skip(1)) {
      emit('${_sp}or$_sp');
      condition.visit(this);
    }
  }

  @override
  void visitViewportDirective(ViewportDirective node) {
    emit('@${node.name}$_sp{$_newLine');
    node.declarations.visit(this);
    emit('}');
  }

  @override
  void visitMediaDirective(MediaDirective node) {
    emit('$_newLine@media');
    emitMediaQueries(node.mediaQueries.cast<MediaQuery>());
    emit('$_sp{');
    for (var ruleset in node.rules) {
      ruleset.visit(this);
    }
    emit('$_newLine}');
  }

  @override
  void visitHostDirective(HostDirective node) {
    emit('$_newLine@host$_sp{');
    for (var ruleset in node.rules) {
      ruleset.visit(this);
    }
    emit('$_newLine}');
  }

  ///  @page : pseudoPage {
  ///    decls
  ///  }
  @override
  void visitPageDirective(PageDirective node) {
    emit('$_newLine@page');
    if (node.hasIdent || node.hasPseudoPage) {
      if (node.hasIdent) emit(' ');
      emit(node._ident!);
      emit(node.hasPseudoPage ? ':${node._pseudoPage}' : '');
    }

    var declsMargin = node._declsMargin;
    var declsMarginLength = declsMargin.length;
    emit('$_sp{$_newLine');
    for (var i = 0; i < declsMarginLength; i++) {
      declsMargin[i].visit(this);
    }
    emit('}');
  }

  /// @charset "charset encoding"
  @override
  void visitCharsetDirective(CharsetDirective node) {
    emit('$_newLine@charset "${node.charEncoding}";');
  }

  @override
  void visitImportDirective(ImportDirective node) {
    bool isStartingQuote(String ch) => ('\'"'.contains(ch[0]));

    if (_isTesting) {
      // Emit assuming url() was parsed; most suite tests use url function.
      emit(' @import url(${node.import})');
    } else if (isStartingQuote(node.import)) {
      emit(' @import ${node.import}');
    } else {
      // url(...) isn't needed only a URI can follow an @import directive; emit
      // url as a string.
      emit(' @import "${node.import}"');
    }
    emitMediaQueries(node.mediaQueries);
    emit(';');
  }

  @override
  void visitKeyFrameDirective(KeyFrameDirective node) {
    emit('$_newLine${node.keyFrameName} ');
    node.name!.visit(this);
    emit('$_sp{$_newLine');
    _isInKeyframes = true;
    for (final block in node._blocks) {
      block.visit(this);
    }
    _isInKeyframes = false;
    emit('}');
  }

  @override
  void visitFontFaceDirective(FontFaceDirective node) {
    emit('$_newLine@font-face ');
    emit('$_sp{$_newLine');
    node._declarations.visit(this);
    emit('}');
  }

  @override
  void visitKeyFrameBlock(KeyFrameBlock node) {
    emit('$_sp$_sp');
    node._blockSelectors.visit(this);
    emit('$_sp{$_newLine');
    node._declarations.visit(this);
    emit('$_sp$_sp}$_newLine');
  }

  @override
  void visitStyletDirective(StyletDirective node) {
    emit('/* @stylet export as ${node.dartClassName} */\n');
  }

  @override
  void visitNamespaceDirective(NamespaceDirective node) {
    bool isStartingQuote(String ch) => ('\'"'.contains(ch));

    if (isStartingQuote(node._uri!)) {
      emit(' @namespace ${node.prefix}"${node._uri}"');
    } else {
      if (_isTesting) {
        // Emit exactly was we parsed.
        emit(' @namespace ${node.prefix}url(${node._uri})');
      } else {
        // url(...) isn't needed only a URI can follow a:
        //    @namespace prefix directive.
        emit(' @namespace ${node.prefix}${node._uri}');
      }
    }
    emit(';');
  }

  @override
  void visitVarDefinitionDirective(VarDefinitionDirective node) {
    visitVarDefinition(node.def);
    emit(';$_newLine');
  }

  @override
  void visitMixinRulesetDirective(MixinRulesetDirective node) {
    emit('@mixin ${node.name} {');
    for (var ruleset in node.rulesets) {
      ruleset.visit(this);
    }
    emit('}');
  }

  @override
  void visitMixinDeclarationDirective(MixinDeclarationDirective node) {
    emit('@mixin ${node.name} {\n');
    visitDeclarationGroup(node.declarations);
    emit('}');
  }

  /// Added optional newLine for handling @include at top-level vs/ inside of
  /// a declaration group.
  @override
  void visitIncludeDirective(IncludeDirective node, [bool topLevel = true]) {
    if (topLevel) emit(_newLine);
    emit('@include ${node.name}');
    emit(';');
  }

  @override
  void visitContentDirective(ContentDirective node) {
    // TODO(terry): TBD
  }

  @override
  void visitRuleSet(RuleSet node) {
    emit('$_newLine');
    node.selectorGroup!.visit(this);
    emit('$_sp{$_newLine');
    node.declarationGroup.visit(this);
    emit('}');
  }

  @override
  void visitDeclarationGroup(DeclarationGroup node) {
    var declarations = node.declarations;
    var declarationsLength = declarations.length;
    for (var i = 0; i < declarationsLength; i++) {
      if (i > 0) emit(_newLine);
      emit('$_sp$_sp');
      declarations[i].visit(this);
      // Don't emit the last semicolon in compact mode.
      if (prettyPrint || i < declarationsLength - 1) {
        emit(';');
      }
    }
    if (declarationsLength > 0) emit(_newLine);
  }

  @override
  void visitMarginGroup(MarginGroup node) {
    var margin_sym_name =
        TokenKind.idToValue(TokenKind.MARGIN_DIRECTIVES, node.margin_sym);

    emit('@$margin_sym_name$_sp{$_newLine');

    visitDeclarationGroup(node);

    emit('}$_newLine');
  }

  @override
  void visitDeclaration(Declaration node) {
    emit('${node.property}:$_sp');
    node.expression!.visit(this);
    if (node.important) {
      emit('$_sp!important');
    }
  }

  @override
  void visitVarDefinition(VarDefinition node) {
    emit('var-${node.definedName}: ');
    node.expression!.visit(this);
  }

  @override
  void visitIncludeMixinAtDeclaration(IncludeMixinAtDeclaration node) {
    // Don't emit a new line we're inside of a declaration group.
    visitIncludeDirective(node.include, false);
  }

  @override
  void visitExtendDeclaration(ExtendDeclaration node) {
    emit('@extend ');
    for (var selector in node.selectors) {
      selector.visit(this);
    }
  }

  @override
  void visitSelectorGroup(SelectorGroup node) {
    var selectors = node.selectors;
    var selectorsLength = selectors.length;
    for (var i = 0; i < selectorsLength; i++) {
      if (i > 0) emit(',$_sp');
      selectors[i].visit(this);
    }
  }

  @override
  void visitSimpleSelectorSequence(SimpleSelectorSequence node) {
    emit('${node._combinatorToString}');
    node.simpleSelector.visit(this);
  }

  @override
  void visitSimpleSelector(SimpleSelector node) {
    emit(node.name);
  }

  @override
  void visitNamespaceSelector(NamespaceSelector node) {
    emit(node.toString());
  }

  @override
  void visitElementSelector(ElementSelector node) {
    emit(node.toString());
  }

  @override
  void visitAttributeSelector(AttributeSelector node) {
    emit(node.toString());
  }

  @override
  void visitIdSelector(IdSelector node) {
    emit(node.toString());
  }

  @override
  void visitClassSelector(ClassSelector node) {
    emit(node.toString());
  }

  @override
  void visitPseudoClassSelector(PseudoClassSelector node) {
    emit(node.toString());
  }

  @override
  void visitPseudoElementSelector(PseudoElementSelector node) {
    emit(node.toString());
  }

  @override
  void visitPseudoClassFunctionSelector(PseudoClassFunctionSelector node) {
    emit(':${node.name}(');
    node.argument.visit(this);
    emit(')');
  }

  @override
  void visitPseudoElementFunctionSelector(PseudoElementFunctionSelector node) {
    emit('::${node.name}(');
    node.expression.visit(this);
    emit(')');
  }

  @override
  void visitNegationSelector(NegationSelector node) {
    emit(':not(');
    node.negationArg!.visit(this);
    emit(')');
  }

  @override
  void visitSelectorExpression(SelectorExpression node) {
    var expressions = node.expressions;
    var expressionsLength = expressions.length;
    for (var i = 0; i < expressionsLength; i++) {
      // Add space seperator between terms without an operator.
      var expression = expressions[i];
      expression.visit(this);
    }
  }

  @override
  void visitUnicodeRangeTerm(UnicodeRangeTerm node) {
    if (node.hasSecond) {
      emit('U+${node.first}-${node.second}');
    } else {
      emit('U+${node.first}');
    }
  }

  @override
  void visitLiteralTerm(LiteralTerm node) {
    emit(node.text);
  }

  @override
  void visitHexColorTerm(HexColorTerm node) {
    String? mappedName;
    if (_isTesting && (node.value is! BAD_HEX_VALUE)) {
      mappedName = TokenKind.hexToColorName(node.value);
    }
    mappedName ??= '#${node.text}';

    emit(mappedName);
  }

  @override
  void visitNumberTerm(NumberTerm node) {
    visitLiteralTerm(node);
  }

  @override
  void visitUnitTerm(UnitTerm node) {
    emit(node.toString());
  }

  @override
  void visitLengthTerm(LengthTerm node) {
    emit(node.toString());
  }

  @override
  void visitPercentageTerm(PercentageTerm node) {
    emit('${node.text}%');
  }

  @override
  void visitEmTerm(EmTerm node) {
    emit('${node.text}em');
  }

  @override
  void visitExTerm(ExTerm node) {
    emit('${node.text}ex');
  }

  @override
  void visitAngleTerm(AngleTerm node) {
    emit(node.toString());
  }

  @override
  void visitTimeTerm(TimeTerm node) {
    emit(node.toString());
  }

  @override
  void visitFreqTerm(FreqTerm node) {
    emit(node.toString());
  }

  @override
  void visitFractionTerm(FractionTerm node) {
    emit('${node.text}fr');
  }

  @override
  void visitUriTerm(UriTerm node) {
    emit('url("${node.text}")');
  }

  @override
  void visitResolutionTerm(ResolutionTerm node) {
    emit(node.toString());
  }

  @override
  void visitViewportTerm(ViewportTerm node) {
    emit(node.toString());
  }

  @override
  void visitFunctionTerm(FunctionTerm node) {
    // TODO(terry): Optimize rgb to a hexcolor.
    emit('${node.text}(');
    node._params.visit(this);
    emit(')');
  }

  @override
  void visitGroupTerm(GroupTerm node) {
    emit('(');
    var terms = node._terms;
    var termsLength = terms.length;
    for (var i = 0; i < termsLength; i++) {
      if (i > 0) emit('$_sp');
      terms[i].visit(this);
    }
    emit(')');
  }

  @override
  void visitItemTerm(ItemTerm node) {
    emit('[${node.text}]');
  }

  @override
  void visitIE8Term(IE8Term node) {
    visitLiteralTerm(node);
  }

  @override
  void visitOperatorSlash(OperatorSlash node) {
    emit('/');
  }

  @override
  void visitOperatorComma(OperatorComma node) {
    emit(',');
  }

  @override
  void visitOperatorPlus(OperatorPlus node) {
    emit('+');
  }

  @override
  void visitOperatorMinus(OperatorMinus node) {
    emit('-');
  }

  @override
  void visitVarUsage(VarUsage node) {
    emit('var(${node.name}');
    if (node.defaultValues.isNotEmpty) {
      emit(',');
      for (var defaultValue in node.defaultValues) {
        emit(' ');
        defaultValue.visit(this);
      }
    }
    emit(')');
  }

  @override
  void visitExpressions(Expressions node) {
    var expressions = node.expressions;
    var expressionsLength = expressions.length;
    for (var i = 0; i < expressionsLength; i++) {
      // Add space seperator between terms without an operator.
      // TODO(terry): Should have a BinaryExpression to solve this problem.
      var expression = expressions[i];
      if (i > 0 &&
          !(expression is OperatorComma || expression is OperatorSlash)) {
        // If the previous expression is an operator, use `_sp` so the space is
        // collapsed when emitted in compact mode. If the previous expression
        // isn't an operator, the space is significant to delimit the two
        // expressions and can't be collapsed.
        var previous = expressions[i - 1];
        if (previous is OperatorComma || previous is OperatorSlash) {
          emit(_sp);
        } else if (previous is PercentageTerm &&
            expression is PercentageTerm &&
            _isInKeyframes) {
          emit(',');
          emit(_sp);
        } else {
          emit(' ');
        }
      }
      expression.visit(this);
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  @override
  void visitUnaryExpression(UnaryExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }

  @override
  void visitIdentifier(Identifier node) {
    emit(node.name);
  }

  @override
  void visitWildcard(Wildcard node) {
    emit('*');
  }

  @override
  void visitDartStyleExpression(DartStyleExpression node) {
    // TODO(terry): TBD
    throw UnimplementedError;
  }
}
