/// This library has a parser for HTML5 documents, that lets you parse HTML
/// easily from a script or server side application:
///
///     import 'package:html/parser.dart' show parse;
///     import 'package:html/dom.dart';
///     main() {
///       var document = parse(
///           '<body>Hello world! <a href="www.html5rocks.com">HTML5 rocks!');
///       print(document.outerHtml);
///     }
///
/// The resulting document you get back has a DOM-like API for easy tree
/// traversal and manipulation.
library parser;

import 'dart:collection';
import 'dart:math';
import 'package:source_span/source_span.dart';

import 'dom.dart';
import 'src/constants.dart';
import 'src/encoding_parser.dart';
import 'src/token.dart';
import 'src/tokenizer.dart';
import 'src/treebuilder.dart';
import 'src/utils.dart';

/// Parse the [input] html5 document into a tree. The [input] can be
/// a [String], [List<int>] of bytes or an [HtmlTokenizer].
///
/// If [input] is not a [HtmlTokenizer], you can optionally specify the file's
/// [encoding], which must be a string. If specified that encoding will be
/// used regardless of any BOM or later declaration (such as in a meta element).
///
/// Set [generateSpans] if you want to generate [SourceSpan]s, otherwise the
/// [Node.sourceSpan] property will be `null`. When using [generateSpans] you
/// can additionally pass [sourceUrl] to indicate where the [input] was
/// extracted from.
Document parse(input,
    {String? encoding, bool generateSpans = false, String? sourceUrl}) {
  final p = HtmlParser(input,
      encoding: encoding, generateSpans: generateSpans, sourceUrl: sourceUrl);
  return p.parse();
}

/// Parse the [input] html5 document fragment into a tree. The [input] can be
/// a [String], [List<int>] of bytes or an [HtmlTokenizer]. The [container]
/// element can optionally be specified, otherwise it defaults to "div".
///
/// If [input] is not a [HtmlTokenizer], you can optionally specify the file's
/// [encoding], which must be a string. If specified, that encoding will be used,
/// regardless of any BOM or later declaration (such as in a meta element).
///
/// Set [generateSpans] if you want to generate [SourceSpan]s, otherwise the
/// [Node.sourceSpan] property will be `null`. When using [generateSpans] you can
/// additionally pass [sourceUrl] to indicate where the [input] was extracted
/// from.
DocumentFragment parseFragment(input,
    {String container = 'div',
    String? encoding,
    bool generateSpans = false,
    String? sourceUrl}) {
  final p = HtmlParser(input,
      encoding: encoding, generateSpans: generateSpans, sourceUrl: sourceUrl);
  return p.parseFragment(container);
}

/// Parser for HTML, which generates a tree structure from a stream of
/// (possibly malformed) characters.
class HtmlParser {
  /// Raise an exception on the first error encountered.
  final bool strict;

  /// True to generate [SourceSpan]s for the [Node.sourceSpan] property.
  final bool generateSpans;

  final HtmlTokenizer tokenizer;

  final TreeBuilder tree;

  final List<ParseError> errors = <ParseError>[];

  bool firstStartTag = false;

  // TODO(jmesserly): use enum?
  /// "quirks" / "limited quirks" / "no quirks"
  String compatMode = 'no quirks';

  /// innerHTML container when parsing document fragment.
  String? innerHTML;

  late Phase phase = _initialPhase;

  Phase? originalPhase;

  var framesetOK = true;

  // These fields hold the different phase singletons. At any given time one
  // of them will be active.
  late final _initialPhase = InitialPhase(this);
  late final _beforeHtmlPhase = BeforeHtmlPhase(this);
  late final _beforeHeadPhase = BeforeHeadPhase(this);
  late final _inHeadPhase = InHeadPhase(this);
  // TODO: html5lib did not implement the no script parsing mode
  // More information here:
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/parsing.html#scripting-flag
  // http://www.whatwg.org/specs/web-apps/current-work/multipage/tree-construction.html#parsing-main-inheadnoscript
  // late final _inHeadNoscript = InHeadNoScriptPhase(this);
  late final _afterHeadPhase = AfterHeadPhase(this);
  late final _inBodyPhase = InBodyPhase(this);
  late final _textPhase = TextPhase(this);
  late final _inTablePhase = InTablePhase(this);
  late final _inTableTextPhase = InTableTextPhase(this);
  late final _inCaptionPhase = InCaptionPhase(this);
  late final _inColumnGroupPhase = InColumnGroupPhase(this);
  late final _inTableBodyPhase = InTableBodyPhase(this);
  late final _inRowPhase = InRowPhase(this);
  late final _inCellPhase = InCellPhase(this);
  late final _inSelectPhase = InSelectPhase(this);
  late final _inSelectInTablePhase = InSelectInTablePhase(this);
  late final _inForeignContentPhase = InForeignContentPhase(this);
  late final _afterBodyPhase = AfterBodyPhase(this);
  late final _inFramesetPhase = InFramesetPhase(this);
  late final _afterFramesetPhase = AfterFramesetPhase(this);
  late final _afterAfterBodyPhase = AfterAfterBodyPhase(this);
  late final _afterAfterFramesetPhase = AfterAfterFramesetPhase(this);

  /// Create an HtmlParser and configure the [tree] builder and [strict] mode.
  /// The [input] can be a [String], [List<int>] of bytes or an [HtmlTokenizer].
  ///
  /// If [input] is not a [HtmlTokenizer], you can specify a few more arguments.
  ///
  /// The [encoding] must be a string that indicates the encoding. If specified,
  /// that encoding will be used, regardless of any BOM or later declaration
  /// (such as in a meta element).
  ///
  /// Set [parseMeta] to false if you want to disable parsing the meta element.
  ///
  /// Set [lowercaseElementName] or [lowercaseAttrName] to false to disable the
  /// automatic conversion of element and attribute names to lower case. Note
  /// that standard way to parse HTML is to lowercase, which is what the browser
  /// DOM will do if you request `Element.outerHTML`, for example.
  HtmlParser(input,
      {String? encoding,
      bool parseMeta = true,
      bool lowercaseElementName = true,
      bool lowercaseAttrName = true,
      this.strict = false,
      this.generateSpans = false,
      String? sourceUrl,
      TreeBuilder? tree})
      : tree = tree ?? TreeBuilder(true),
        tokenizer = (input is HtmlTokenizer
            ? input
            : HtmlTokenizer(input,
                encoding: encoding,
                parseMeta: parseMeta,
                lowercaseElementName: lowercaseElementName,
                lowercaseAttrName: lowercaseAttrName,
                generateSpans: generateSpans,
                sourceUrl: sourceUrl)) {
    tokenizer.parser = this;
  }

  bool get innerHTMLMode => innerHTML != null;

  /// Parse an html5 document into a tree.
  /// After parsing, [errors] will be populated with parse errors, if any.
  Document parse() {
    innerHTML = null;
    _parse();
    return tree.getDocument();
  }

  /// Parse an html5 document fragment into a tree.
  /// Pass a [container] to change the type of the containing element.
  /// After parsing, [errors] will be populated with parse errors, if any.
  DocumentFragment parseFragment([String container = 'div']) {
    ArgumentError.checkNotNull(container, 'container');
    innerHTML = container.toLowerCase();
    _parse();
    return tree.getFragment();
  }

  void _parse() {
    reset();

    while (true) {
      try {
        mainLoop();
        break;
      } on ReparseException catch (_) {
        // Note: this happens if we start parsing but the character encoding
        // changes. So we should only need to restart very early in the parse.
        reset();
      }
    }
  }

  void reset() {
    tokenizer.reset();

    tree.reset();
    firstStartTag = false;
    errors.clear();
    // "quirks" / "limited quirks" / "no quirks"
    compatMode = 'no quirks';

    if (innerHTMLMode) {
      if (cdataElements.contains(innerHTML)) {
        tokenizer.state = tokenizer.rcdataState;
      } else if (rcdataElements.contains(innerHTML)) {
        tokenizer.state = tokenizer.rawtextState;
      } else if (innerHTML == 'plaintext') {
        tokenizer.state = tokenizer.plaintextState;
      } else {
        // state already is data state
        // tokenizer.state = tokenizer.dataState;
      }
      phase = _beforeHtmlPhase;
      _beforeHtmlPhase.insertHtmlElement();
      resetInsertionMode();
    } else {
      phase = _initialPhase;
    }

    framesetOK = true;
  }

  bool isHTMLIntegrationPoint(Element element) {
    if (element.localName == 'annotation-xml' &&
        element.namespaceUri == Namespaces.mathml) {
      final enc = element.attributes['encoding']?.toAsciiLowerCase();
      return enc == 'text/html' || enc == 'application/xhtml+xml';
    } else {
      return htmlIntegrationPointElements
          .contains(Pair(element.namespaceUri, element.localName));
    }
  }

  bool isMathMLTextIntegrationPoint(Element element) {
    return mathmlTextIntegrationPointElements
        .contains(Pair(element.namespaceUri, element.localName));
  }

  bool inForeignContent(Token token, int type) {
    if (tree.openElements.isEmpty) return false;

    final node = tree.openElements.last;
    if (node.namespaceUri == tree.defaultNamespace) return false;

    if (isMathMLTextIntegrationPoint(node)) {
      if (type == TokenKind.startTag &&
          (token as StartTagToken).name != 'mglyph' &&
          token.name != 'malignmark') {
        return false;
      }
      if (type == TokenKind.characters || type == TokenKind.spaceCharacters) {
        return false;
      }
    }

    if (node.localName == 'annotation-xml' &&
        type == TokenKind.startTag &&
        (token as StartTagToken).name == 'svg') {
      return false;
    }

    if (isHTMLIntegrationPoint(node)) {
      if (type == TokenKind.startTag ||
          type == TokenKind.characters ||
          type == TokenKind.spaceCharacters) {
        return false;
      }
    }

    return true;
  }

  void mainLoop() {
    while (tokenizer.moveNext()) {
      final token = tokenizer.current;
      Token? newToken = token;
      int type;
      while (newToken != null) {
        type = newToken.kind;

        // Note: avoid "is" test here, see http://dartbug.com/4795
        if (type == TokenKind.parseError) {
          final error = newToken as ParseErrorToken;
          parseError(error.span, error.data, error.messageParams);
          newToken = null;
        } else {
          var localPhase = phase;
          if (inForeignContent(token, type)) {
            localPhase = _inForeignContentPhase;
          }

          switch (type) {
            case TokenKind.characters:
              newToken =
                  localPhase.processCharacters(newToken as CharactersToken);
              break;
            case TokenKind.spaceCharacters:
              newToken = localPhase
                  .processSpaceCharacters(newToken as SpaceCharactersToken);
              break;
            case TokenKind.startTag:
              newToken = localPhase.processStartTag(newToken as StartTagToken);
              break;
            case TokenKind.endTag:
              newToken = localPhase.processEndTag(newToken as EndTagToken);
              break;
            case TokenKind.comment:
              newToken = localPhase.processComment(newToken as CommentToken);
              break;
            case TokenKind.doctype:
              newToken = localPhase.processDoctype(newToken as DoctypeToken);
              break;
          }
        }
      }

      if (token is StartTagToken) {
        if (token.selfClosing && !token.selfClosingAcknowledged) {
          parseError(token.span, 'non-void-element-with-trailing-solidus',
              {'name': token.name});
        }
      }
    }

    // When the loop finishes it's EOF
    var reprocess = true;
    final reprocessPhases = <Phase>[];
    while (reprocess) {
      reprocessPhases.add(phase);
      reprocess = phase.processEOF();
      if (reprocess) {
        assert(!reprocessPhases.contains(phase));
      }
    }
  }

  /// The last span available. Used for EOF errors if we don't have something
  /// better.
  SourceSpan? get _lastSpan => tokenizer.stream.fileInfo
      ?.location(tokenizer.stream.position)
      .pointSpan();

  void parseError(SourceSpan? span, String errorcode,
      [Map? datavars = const {}]) {
    if (!generateSpans && span == null) {
      span = _lastSpan;
    }

    final err = ParseError(errorcode, span, datavars);
    errors.add(err);
    if (strict) throw err;
  }

  void adjustMathMLAttributes(StartTagToken token) {
    final orig = token.data.remove('definitionurl');
    if (orig != null) {
      token.data['definitionURL'] = orig;
    }
  }

  void adjustSVGAttributes(StartTagToken token) {
    final replacements = const {
      'attributename': 'attributeName',
      'attributetype': 'attributeType',
      'basefrequency': 'baseFrequency',
      'baseprofile': 'baseProfile',
      'calcmode': 'calcMode',
      'clippathunits': 'clipPathUnits',
      'contentscripttype': 'contentScriptType',
      'contentstyletype': 'contentStyleType',
      'diffuseconstant': 'diffuseConstant',
      'edgemode': 'edgeMode',
      'externalresourcesrequired': 'externalResourcesRequired',
      'filterres': 'filterRes',
      'filterunits': 'filterUnits',
      'glyphref': 'glyphRef',
      'gradienttransform': 'gradientTransform',
      'gradientunits': 'gradientUnits',
      'kernelmatrix': 'kernelMatrix',
      'kernelunitlength': 'kernelUnitLength',
      'keypoints': 'keyPoints',
      'keysplines': 'keySplines',
      'keytimes': 'keyTimes',
      'lengthadjust': 'lengthAdjust',
      'limitingconeangle': 'limitingConeAngle',
      'markerheight': 'markerHeight',
      'markerunits': 'markerUnits',
      'markerwidth': 'markerWidth',
      'maskcontentunits': 'maskContentUnits',
      'maskunits': 'maskUnits',
      'numoctaves': 'numOctaves',
      'pathlength': 'pathLength',
      'patterncontentunits': 'patternContentUnits',
      'patterntransform': 'patternTransform',
      'patternunits': 'patternUnits',
      'pointsatx': 'pointsAtX',
      'pointsaty': 'pointsAtY',
      'pointsatz': 'pointsAtZ',
      'preservealpha': 'preserveAlpha',
      'preserveaspectratio': 'preserveAspectRatio',
      'primitiveunits': 'primitiveUnits',
      'refx': 'refX',
      'refy': 'refY',
      'repeatcount': 'repeatCount',
      'repeatdur': 'repeatDur',
      'requiredextensions': 'requiredExtensions',
      'requiredfeatures': 'requiredFeatures',
      'specularconstant': 'specularConstant',
      'specularexponent': 'specularExponent',
      'spreadmethod': 'spreadMethod',
      'startoffset': 'startOffset',
      'stddeviation': 'stdDeviation',
      'stitchtiles': 'stitchTiles',
      'surfacescale': 'surfaceScale',
      'systemlanguage': 'systemLanguage',
      'tablevalues': 'tableValues',
      'targetx': 'targetX',
      'targety': 'targetY',
      'textlength': 'textLength',
      'viewbox': 'viewBox',
      'viewtarget': 'viewTarget',
      'xchannelselector': 'xChannelSelector',
      'ychannelselector': 'yChannelSelector',
      'zoomandpan': 'zoomAndPan'
    };
    for (var originalName in token.data.keys.toList(growable: false)) {
      final svgName = replacements[originalName as String];
      if (svgName != null) {
        token.data[svgName] = token.data.remove(originalName)!;
      }
    }
  }

  void adjustForeignAttributes(StartTagToken token) {
    // TODO(jmesserly): I don't like mixing non-string objects with strings in
    // the Node.attributes Map. Is there another solution?
    final replacements = const {
      'xlink:actuate': AttributeName('xlink', 'actuate', Namespaces.xlink),
      'xlink:arcrole': AttributeName('xlink', 'arcrole', Namespaces.xlink),
      'xlink:href': AttributeName('xlink', 'href', Namespaces.xlink),
      'xlink:role': AttributeName('xlink', 'role', Namespaces.xlink),
      'xlink:show': AttributeName('xlink', 'show', Namespaces.xlink),
      'xlink:title': AttributeName('xlink', 'title', Namespaces.xlink),
      'xlink:type': AttributeName('xlink', 'type', Namespaces.xlink),
      'xml:base': AttributeName('xml', 'base', Namespaces.xml),
      'xml:lang': AttributeName('xml', 'lang', Namespaces.xml),
      'xml:space': AttributeName('xml', 'space', Namespaces.xml),
      'xmlns': AttributeName(null, 'xmlns', Namespaces.xmlns),
      'xmlns:xlink': AttributeName('xmlns', 'xlink', Namespaces.xmlns)
    };

    for (var originalName in token.data.keys.toList(growable: false)) {
      final foreignName = replacements[originalName as String];
      if (foreignName != null) {
        token.data[foreignName] = token.data.remove(originalName)!;
      }
    }
  }

  void resetInsertionMode() {
    // The name of this method is mostly historical. (It's also used in the
    // specification.)
    for (var node in tree.openElements.reversed) {
      var nodeName = node.localName;
      final last = node == tree.openElements[0];
      if (last) {
        assert(innerHTMLMode);
        nodeName = innerHTML;
      }
      // Check for conditions that should only happen in the innerHTML
      // case
      switch (nodeName) {
        case 'select':
        case 'colgroup':
        case 'head':
        case 'html':
          assert(innerHTMLMode);
          break;
      }
      if (!last && node.namespaceUri != tree.defaultNamespace) {
        continue;
      }
      switch (nodeName) {
        case 'select':
          phase = _inSelectPhase;
          return;
        case 'td':
          phase = _inCellPhase;
          return;
        case 'th':
          phase = _inCellPhase;
          return;
        case 'tr':
          phase = _inRowPhase;
          return;
        case 'tbody':
          phase = _inTableBodyPhase;
          return;
        case 'thead':
          phase = _inTableBodyPhase;
          return;
        case 'tfoot':
          phase = _inTableBodyPhase;
          return;
        case 'caption':
          phase = _inCaptionPhase;
          return;
        case 'colgroup':
          phase = _inColumnGroupPhase;
          return;
        case 'table':
          phase = _inTablePhase;
          return;
        case 'head':
          phase = _inBodyPhase;
          return;
        case 'body':
          phase = _inBodyPhase;
          return;
        case 'frameset':
          phase = _inFramesetPhase;
          return;
        case 'html':
          phase = _beforeHeadPhase;
          return;
      }
    }
    phase = _inBodyPhase;
  }

  /// Generic RCDATA/RAWTEXT Parsing algorithm
  /// [contentType] - RCDATA or RAWTEXT
  void parseRCDataRawtext(Token token, String contentType) {
    assert(contentType == 'RAWTEXT' || contentType == 'RCDATA');

    tree.insertElement(token as StartTagToken);

    if (contentType == 'RAWTEXT') {
      tokenizer.state = tokenizer.rawtextState;
    } else {
      tokenizer.state = tokenizer.rcdataState;
    }

    originalPhase = phase;
    phase = _textPhase;
  }
}

/// Base class for helper object that implements each phase of processing.
class Phase {
  // Order should be (they can be omitted):
  // * EOF
  // * Comment
  // * Doctype
  // * SpaceCharacters
  // * Characters
  // * StartTag
  //   - startTag* methods
  // * EndTag
  //   - endTag* methods

  final HtmlParser parser;

  final TreeBuilder tree;

  Phase(this.parser) : tree = parser.tree;

  bool processEOF() {
    throw UnimplementedError();
  }

  Token? processComment(CommentToken token) {
    // For most phases the following is correct. Where it's not it will be
    // overridden.
    tree.insertComment(token, tree.openElements.last);
    return null;
  }

  Token? processDoctype(DoctypeToken token) {
    parser.parseError(token.span, 'unexpected-doctype');
    return null;
  }

  Token? processCharacters(CharactersToken token) {
    tree.insertText(token.data, token.span);
    return null;
  }

  Token? processSpaceCharacters(SpaceCharactersToken token) {
    tree.insertText(token.data, token.span);
    return null;
  }

  Token? processStartTag(StartTagToken token) {
    throw UnimplementedError();
  }

  Token? startTagHtml(StartTagToken token) {
    if (parser.firstStartTag == false && token.name == 'html') {
      parser.parseError(token.span, 'non-html-root');
    }
    // XXX Need a check here to see if the first start tag token emitted is
    // this token... If it's not, invoke parser.parseError().
    tree.openElements[0].sourceSpan = token.span;
    token.data.forEach((attr, value) {
      tree.openElements[0].attributes.putIfAbsent(attr, () => value);
    });
    parser.firstStartTag = false;
    return null;
  }

  Token? processEndTag(EndTagToken token) {
    throw UnimplementedError();
  }

  /// Helper method for popping openElements.
  void popOpenElementsUntil(EndTagToken token) {
    final name = token.name;
    var node = tree.openElements.removeLast();
    while (node.localName != name) {
      node = tree.openElements.removeLast();
    }
    node.endSourceSpan = token.span;
  }
}

class InitialPhase extends Phase {
  InitialPhase(HtmlParser parser) : super(parser);

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    return null;
  }

  @override
  Token? processComment(CommentToken token) {
    tree.insertComment(token, tree.document);
    return null;
  }

  @override
  Token? processDoctype(DoctypeToken token) {
    final name = token.name;
    var publicId = token.publicId?.toAsciiLowerCase();
    final systemId = token.systemId;
    final correct = token.correct;

    if ((name != 'html' ||
        publicId != null ||
        systemId != null && systemId != 'about:legacy-compat')) {
      parser.parseError(token.span, 'unknown-doctype');
    }

    publicId ??= '';

    tree.insertDoctype(token);

    if (!correct ||
        token.name != 'html' ||
        startsWithAny(publicId, const [
          '+//silmaril//dtd html pro v0r11 19970101//',
          '-//advasoft ltd//dtd html 3.0 aswedit + extensions//',
          '-//as//dtd html 3.0 aswedit + extensions//',
          '-//ietf//dtd html 2.0 level 1//',
          '-//ietf//dtd html 2.0 level 2//',
          '-//ietf//dtd html 2.0 strict level 1//',
          '-//ietf//dtd html 2.0 strict level 2//',
          '-//ietf//dtd html 2.0 strict//',
          '-//ietf//dtd html 2.0//',
          '-//ietf//dtd html 2.1e//',
          '-//ietf//dtd html 3.0//',
          '-//ietf//dtd html 3.2 final//',
          '-//ietf//dtd html 3.2//',
          '-//ietf//dtd html 3//',
          '-//ietf//dtd html level 0//',
          '-//ietf//dtd html level 1//',
          '-//ietf//dtd html level 2//',
          '-//ietf//dtd html level 3//',
          '-//ietf//dtd html strict level 0//',
          '-//ietf//dtd html strict level 1//',
          '-//ietf//dtd html strict level 2//',
          '-//ietf//dtd html strict level 3//',
          '-//ietf//dtd html strict//',
          '-//ietf//dtd html//',
          '-//metrius//dtd metrius presentational//',
          '-//microsoft//dtd internet explorer 2.0 html strict//',
          '-//microsoft//dtd internet explorer 2.0 html//',
          '-//microsoft//dtd internet explorer 2.0 tables//',
          '-//microsoft//dtd internet explorer 3.0 html strict//',
          '-//microsoft//dtd internet explorer 3.0 html//',
          '-//microsoft//dtd internet explorer 3.0 tables//',
          '-//netscape comm. corp.//dtd html//',
          '-//netscape comm. corp.//dtd strict html//',
          "-//o'reilly and associates//dtd html 2.0//",
          "-//o'reilly and associates//dtd html extended 1.0//",
          "-//o'reilly and associates//dtd html extended relaxed 1.0//",
          '-//softquad software//dtd hotmetal pro 6.0::19990601::extensions to html 4.0//',
          '-//softquad//dtd hotmetal pro 4.0::19971010::extensions to html 4.0//',
          '-//spyglass//dtd html 2.0 extended//',
          '-//sq//dtd html 2.0 hotmetal + extensions//',
          '-//sun microsystems corp.//dtd hotjava html//',
          '-//sun microsystems corp.//dtd hotjava strict html//',
          '-//w3c//dtd html 3 1995-03-24//',
          '-//w3c//dtd html 3.2 draft//',
          '-//w3c//dtd html 3.2 final//',
          '-//w3c//dtd html 3.2//',
          '-//w3c//dtd html 3.2s draft//',
          '-//w3c//dtd html 4.0 frameset//',
          '-//w3c//dtd html 4.0 transitional//',
          '-//w3c//dtd html experimental 19960712//',
          '-//w3c//dtd html experimental 970421//',
          '-//w3c//dtd w3 html//',
          '-//w3o//dtd w3 html 3.0//',
          '-//webtechs//dtd mozilla html 2.0//',
          '-//webtechs//dtd mozilla html//'
        ]) ||
        const [
          '-//w3o//dtd w3 html strict 3.0//en//',
          '-/w3c/dtd html 4.0 transitional/en',
          'html'
        ].contains(publicId) ||
        startsWithAny(publicId, const [
              '-//w3c//dtd html 4.01 frameset//',
              '-//w3c//dtd html 4.01 transitional//'
            ]) &&
            systemId == null ||
        systemId != null &&
            systemId.toLowerCase() ==
                'http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd') {
      parser.compatMode = 'quirks';
    } else if (startsWithAny(publicId, const [
          '-//w3c//dtd xhtml 1.0 frameset//',
          '-//w3c//dtd xhtml 1.0 transitional//'
        ]) ||
        startsWithAny(publicId, const [
              '-//w3c//dtd html 4.01 frameset//',
              '-//w3c//dtd html 4.01 transitional//'
            ]) &&
            systemId != null) {
      parser.compatMode = 'limited quirks';
    }
    parser.phase = parser._beforeHtmlPhase;
    return null;
  }

  void anythingElse() {
    parser.compatMode = 'quirks';
    parser.phase = parser._beforeHtmlPhase;
  }

  @override
  Token processCharacters(CharactersToken token) {
    parser.parseError(token.span, 'expected-doctype-but-got-chars');
    anythingElse();
    return token;
  }

  @override
  Token processStartTag(StartTagToken token) {
    parser.parseError(
        token.span, 'expected-doctype-but-got-start-tag', {'name': token.name});
    anythingElse();
    return token;
  }

  @override
  Token processEndTag(EndTagToken token) {
    parser.parseError(
        token.span, 'expected-doctype-but-got-end-tag', {'name': token.name});
    anythingElse();
    return token;
  }

  @override
  bool processEOF() {
    parser.parseError(parser._lastSpan, 'expected-doctype-but-got-eof');
    anythingElse();
    return true;
  }
}

class BeforeHtmlPhase extends Phase {
  BeforeHtmlPhase(HtmlParser parser) : super(parser);

  // helper methods
  void insertHtmlElement() {
    tree.insertRoot(
        StartTagToken('html', data: LinkedHashMap<Object, String>()));
    parser.phase = parser._beforeHeadPhase;
  }

  // other
  @override
  bool processEOF() {
    insertHtmlElement();
    return true;
  }

  @override
  Token? processComment(CommentToken token) {
    tree.insertComment(token, tree.document);
    return null;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    return null;
  }

  @override
  Token processCharacters(CharactersToken token) {
    insertHtmlElement();
    return token;
  }

  @override
  @override
  Token processStartTag(StartTagToken token) {
    if (token.name == 'html') {
      parser.firstStartTag = true;
    }
    insertHtmlElement();
    return token;
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'head':
      case 'body':
      case 'html':
      case 'br':
        insertHtmlElement();
        return token;
      default:
        parser.parseError(
            token.span, 'unexpected-end-tag-before-html', {'name': token.name});
        return null;
    }
  }
}

class BeforeHeadPhase extends Phase {
  BeforeHeadPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'head':
        startTagHead(token);
        return null;
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'head':
      case 'body':
      case 'html':
      case 'br':
        return endTagImplyHead(token);
      default:
        endTagOther(token);
        return null;
    }
  }

  @override
  bool processEOF() {
    startTagHead(StartTagToken('head', data: LinkedHashMap<Object, String>()));
    return true;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    return null;
  }

  @override
  Token processCharacters(CharactersToken token) {
    startTagHead(StartTagToken('head', data: LinkedHashMap<Object, String>()));
    return token;
  }

  @override
  Token? startTagHtml(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  void startTagHead(StartTagToken token) {
    tree.insertElement(token);
    tree.headPointer = tree.openElements.last;
    parser.phase = parser._inHeadPhase;
  }

  Token startTagOther(StartTagToken token) {
    startTagHead(StartTagToken('head', data: LinkedHashMap<Object, String>()));
    return token;
  }

  Token endTagImplyHead(EndTagToken token) {
    startTagHead(StartTagToken('head', data: LinkedHashMap<Object, String>()));
    return token;
  }

  void endTagOther(EndTagToken token) {
    parser.parseError(
        token.span, 'end-tag-after-implied-root', {'name': token.name});
  }
}

class InHeadPhase extends Phase {
  InHeadPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'title':
        startTagTitle(token);
        return null;
      case 'noscript':
      case 'noframes':
      case 'style':
        startTagNoScriptNoFramesStyle(token);
        return null;
      case 'script':
        startTagScript(token);
        return null;
      case 'base':
      case 'basefont':
      case 'bgsound':
      case 'command':
      case 'link':
        startTagBaseLinkCommand(token);
        return null;
      case 'meta':
        startTagMeta(token);
        return null;
      case 'head':
        startTagHead(token);
        return null;
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'head':
        endTagHead(token);
        return null;
      case 'br':
      case 'html':
      case 'body':
        return endTagHtmlBodyBr(token);
      default:
        endTagOther(token);
        return null;
    }
  }

  // the real thing
  @override
  bool processEOF() {
    anythingElse();
    return true;
  }

  @override
  Token processCharacters(CharactersToken token) {
    anythingElse();
    return token;
  }

  @override
  Token? startTagHtml(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  void startTagHead(StartTagToken token) {
    parser.parseError(token.span, 'two-heads-are-not-better-than-one');
  }

  void startTagBaseLinkCommand(StartTagToken token) {
    tree.insertElement(token);
    tree.openElements.removeLast();
    token.selfClosingAcknowledged = true;
  }

  void startTagMeta(StartTagToken token) {
    tree.insertElement(token);
    tree.openElements.removeLast();
    token.selfClosingAcknowledged = true;

    final attributes = token.data;
    if (!parser.tokenizer.stream.charEncodingCertain) {
      final charset = attributes['charset'];
      final content = attributes['content'];
      if (charset != null) {
        parser.tokenizer.stream.changeEncoding(charset);
      } else if (content != null) {
        final data = EncodingBytes(content);
        final codec = ContentAttrParser(data).parse();
        parser.tokenizer.stream.changeEncoding(codec);
      }
    }
  }

  void startTagTitle(StartTagToken token) {
    parser.parseRCDataRawtext(token, 'RCDATA');
  }

  void startTagNoScriptNoFramesStyle(StartTagToken token) {
    // Need to decide whether to implement the scripting-disabled case
    parser.parseRCDataRawtext(token, 'RAWTEXT');
  }

  void startTagScript(StartTagToken token) {
    tree.insertElement(token);
    parser.tokenizer.state = parser.tokenizer.scriptDataState;
    parser.originalPhase = parser.phase;
    parser.phase = parser._textPhase;
  }

  Token startTagOther(StartTagToken token) {
    anythingElse();
    return token;
  }

  void endTagHead(EndTagToken token) {
    final node = parser.tree.openElements.removeLast();
    assert(node.localName == 'head');
    node.endSourceSpan = token.span;
    parser.phase = parser._afterHeadPhase;
  }

  Token endTagHtmlBodyBr(EndTagToken token) {
    anythingElse();
    return token;
  }

  void endTagOther(EndTagToken token) {
    parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
  }

  void anythingElse() {
    endTagHead(EndTagToken('head'));
  }
}

// XXX If we implement a parser for which scripting is disabled we need to
// implement this phase.
//
// class InHeadNoScriptPhase extends Phase {

class AfterHeadPhase extends Phase {
  AfterHeadPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'body':
        startTagBody(token);
        return null;
      case 'frameset':
        startTagFrameset(token);
        return null;
      case 'base':
      case 'basefont':
      case 'bgsound':
      case 'link':
      case 'meta':
      case 'noframes':
      case 'script':
      case 'style':
      case 'title':
        startTagFromHead(token);
        return null;
      case 'head':
        startTagHead(token);
        return null;
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'body':
      case 'html':
      case 'br':
        return endTagHtmlBodyBr(token);
      default:
        endTagOther(token);
        return null;
    }
  }

  @override
  bool processEOF() {
    anythingElse();
    return true;
  }

  @override
  Token processCharacters(CharactersToken token) {
    anythingElse();
    return token;
  }

  @override
  Token? startTagHtml(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  void startTagBody(StartTagToken token) {
    parser.framesetOK = false;
    tree.insertElement(token);
    parser.phase = parser._inBodyPhase;
  }

  void startTagFrameset(StartTagToken token) {
    tree.insertElement(token);
    parser.phase = parser._inFramesetPhase;
  }

  void startTagFromHead(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-start-tag-out-of-my-head',
        {'name': token.name});
    tree.openElements.add(tree.headPointer as Element);
    parser._inHeadPhase.processStartTag(token);
    for (var node in tree.openElements.reversed) {
      if (node.localName == 'head') {
        tree.openElements.remove(node);
        break;
      }
    }
  }

  void startTagHead(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-start-tag', {'name': token.name});
  }

  Token startTagOther(StartTagToken token) {
    anythingElse();
    return token;
  }

  Token endTagHtmlBodyBr(EndTagToken token) {
    anythingElse();
    return token;
  }

  void endTagOther(EndTagToken token) {
    parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
  }

  void anythingElse() {
    tree.insertElement(
        StartTagToken('body', data: LinkedHashMap<Object, String>()));
    parser.phase = parser._inBodyPhase;
    parser.framesetOK = true;
  }
}

typedef TokenProccessor = Token Function(Token token);

class InBodyPhase extends Phase {
  bool dropNewline = false;

  // http://www.whatwg.org/specs/web-apps/current-work///parsing-main-inbody
  // the really-really-really-very crazy mode
  InBodyPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'base':
      case 'basefont':
      case 'bgsound':
      case 'command':
      case 'link':
      case 'meta':
      case 'noframes':
      case 'script':
      case 'style':
      case 'title':
        return startTagProcessInHead(token);
      case 'body':
        startTagBody(token);
        return null;
      case 'frameset':
        startTagFrameset(token);
        return null;
      case 'address':
      case 'article':
      case 'aside':
      case 'blockquote':
      case 'center':
      case 'details':
      case 'dir':
      case 'div':
      case 'dl':
      case 'fieldset':
      case 'figcaption':
      case 'figure':
      case 'footer':
      case 'header':
      case 'hgroup':
      case 'menu':
      case 'nav':
      case 'ol':
      case 'p':
      case 'section':
      case 'summary':
      case 'ul':
        startTagCloseP(token);
        return null;
      // headingElements
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        startTagHeading(token);
        return null;
      case 'pre':
      case 'listing':
        startTagPreListing(token);
        return null;
      case 'form':
        startTagForm(token);
        return null;
      case 'li':
      case 'dd':
      case 'dt':
        startTagListItem(token);
        return null;
      case 'plaintext':
        startTagPlaintext(token);
        return null;
      case 'a':
        startTagA(token);
        return null;
      case 'b':
      case 'big':
      case 'code':
      case 'em':
      case 'font':
      case 'i':
      case 's':
      case 'small':
      case 'strike':
      case 'strong':
      case 'tt':
      case 'u':
        startTagFormatting(token);
        return null;
      case 'nobr':
        startTagNobr(token);
        return null;
      case 'button':
        return startTagButton(token);
      case 'applet':
      case 'marquee':
      case 'object':
        startTagAppletMarqueeObject(token);
        return null;
      case 'xmp':
        startTagXmp(token);
        return null;
      case 'table':
        startTagTable(token);
        return null;
      case 'area':
      case 'br':
      case 'embed':
      case 'img':
      case 'keygen':
      case 'wbr':
        startTagVoidFormatting(token);
        return null;
      case 'param':
      case 'source':
      case 'track':
        startTagParamSource(token);
        return null;
      case 'input':
        startTagInput(token);
        return null;
      case 'hr':
        startTagHr(token);
        return null;
      case 'image':
        startTagImage(token);
        return null;
      case 'isindex':
        startTagIsIndex(token);
        return null;
      case 'textarea':
        startTagTextarea(token);
        return null;
      case 'iframe':
        startTagIFrame(token);
        return null;
      case 'noembed':
      case 'noscript':
        startTagRawtext(token);
        return null;
      case 'select':
        startTagSelect(token);
        return null;
      case 'rp':
      case 'rt':
        startTagRpRt(token);
        return null;
      case 'option':
      case 'optgroup':
        startTagOpt(token);
        return null;
      case 'math':
        startTagMath(token);
        return null;
      case 'svg':
        startTagSvg(token);
        return null;
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'frame':
      case 'head':
      case 'tbody':
      case 'td':
      case 'tfoot':
      case 'th':
      case 'thead':
      case 'tr':
        startTagMisplaced(token);
        return null;
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'body':
        endTagBody(token);
        return null;
      case 'html':
        return endTagHtml(token);
      case 'address':
      case 'article':
      case 'aside':
      case 'blockquote':
      case 'button':
      case 'center':
      case 'details':
      case 'dir':
      case 'div':
      case 'dl':
      case 'fieldset':
      case 'figcaption':
      case 'figure':
      case 'footer':
      case 'header':
      case 'hgroup':
      case 'listing':
      case 'menu':
      case 'nav':
      case 'ol':
      case 'pre':
      case 'section':
      case 'summary':
      case 'ul':
        endTagBlock(token);
        return null;
      case 'form':
        endTagForm(token);
        return null;
      case 'p':
        endTagP(token);
        return null;
      case 'dd':
      case 'dt':
      case 'li':
        endTagListItem(token);
        return null;
      // headingElements
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        endTagHeading(token);
        return null;
      case 'a':
      case 'b':
      case 'big':
      case 'code':
      case 'em':
      case 'font':
      case 'i':
      case 'nobr':
      case 's':
      case 'small':
      case 'strike':
      case 'strong':
      case 'tt':
      case 'u':
        endTagFormatting(token);
        return null;
      case 'applet':
      case 'marquee':
      case 'object':
        endTagAppletMarqueeObject(token);
        return null;
      case 'br':
        endTagBr(token);
        return null;
      default:
        endTagOther(token);
        return null;
    }
  }

  bool isMatchingFormattingElement(Element node1, Element node2) {
    if (node1.localName != node2.localName ||
        node1.namespaceUri != node2.namespaceUri) {
      return false;
    } else if (node1.attributes.length != node2.attributes.length) {
      return false;
    } else {
      for (var key in node1.attributes.keys) {
        if (node1.attributes[key] != node2.attributes[key]) {
          return false;
        }
      }
    }
    return true;
  }

  // helper
  void addFormattingElement(StartTagToken token) {
    tree.insertElement(token);
    final element = tree.openElements.last;

    final matchingElements = <Node?>[];
    for (Node? node in tree.activeFormattingElements.reversed) {
      if (node == null) {
        break;
      } else if (isMatchingFormattingElement(node as Element, element)) {
        matchingElements.add(node);
      }
    }

    assert(matchingElements.length <= 3);
    if (matchingElements.length == 3) {
      tree.activeFormattingElements.remove(matchingElements.last);
    }
    tree.activeFormattingElements.add(element);
  }

  // the real deal
  @override
  bool processEOF() {
    for (var node in tree.openElements.reversed) {
      switch (node.localName) {
        case 'dd':
        case 'dt':
        case 'li':
        case 'p':
        case 'tbody':
        case 'td':
        case 'tfoot':
        case 'th':
        case 'thead':
        case 'tr':
        case 'body':
        case 'html':
          continue;
      }
      parser.parseError(node.sourceSpan, 'expected-closing-tag-but-got-eof');
      break;
    }
    //Stop parsing
    return false;
  }

  void processSpaceCharactersDropNewline(StringToken token) {
    // Sometimes (start of <pre>, <listing>, and <textarea> blocks) we
    // want to drop leading newlines
    var data = token.data;
    dropNewline = false;
    if (data.startsWith('\n')) {
      final lastOpen = tree.openElements.last;
      if (const ['pre', 'listing', 'textarea'].contains(lastOpen.localName) &&
          !lastOpen.hasContent()) {
        data = data.substring(1);
      }
    }
    if (data.isNotEmpty) {
      tree.reconstructActiveFormattingElements();
      tree.insertText(data, token.span);
    }
  }

  @override
  Token? processCharacters(CharactersToken token) {
    if (token.data == '\u0000') {
      //The tokenizer should always emit null on its own
      return null;
    }
    tree.reconstructActiveFormattingElements();
    tree.insertText(token.data, token.span);
    if (parser.framesetOK && !allWhitespace(token.data)) {
      parser.framesetOK = false;
    }
    return null;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    if (dropNewline) {
      processSpaceCharactersDropNewline(token);
    } else {
      tree.reconstructActiveFormattingElements();
      tree.insertText(token.data, token.span);
    }
    return null;
  }

  Token? startTagProcessInHead(StartTagToken token) {
    return parser._inHeadPhase.processStartTag(token);
  }

  void startTagBody(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-start-tag', {'name': 'body'});
    if (tree.openElements.length == 1 ||
        tree.openElements[1].localName != 'body') {
      assert(parser.innerHTMLMode);
    } else {
      parser.framesetOK = false;
      token.data.forEach((attr, value) {
        tree.openElements[1].attributes.putIfAbsent(attr, () => value);
      });
    }
  }

  void startTagFrameset(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-start-tag', {'name': 'frameset'});
    if ((tree.openElements.length == 1 ||
        tree.openElements[1].localName != 'body')) {
      assert(parser.innerHTMLMode);
    } else if (parser.framesetOK) {
      if (tree.openElements[1].parentNode != null) {
        tree.openElements[1].parentNode!.nodes.remove(tree.openElements[1]);
      }
      while (tree.openElements.last.localName != 'html') {
        tree.openElements.removeLast();
      }
      tree.insertElement(token);
      parser.phase = parser._inFramesetPhase;
    }
  }

  void startTagCloseP(StartTagToken token) {
    if (tree.elementInScope('p', variant: 'button')) {
      endTagP(EndTagToken('p'));
    }
    tree.insertElement(token);
  }

  void startTagPreListing(StartTagToken token) {
    if (tree.elementInScope('p', variant: 'button')) {
      endTagP(EndTagToken('p'));
    }
    tree.insertElement(token);
    parser.framesetOK = false;
    dropNewline = true;
  }

  void startTagForm(StartTagToken token) {
    if (tree.formPointer != null) {
      parser.parseError(token.span, 'unexpected-start-tag', {'name': 'form'});
    } else {
      if (tree.elementInScope('p', variant: 'button')) {
        endTagP(EndTagToken('p'));
      }
      tree.insertElement(token);
      tree.formPointer = tree.openElements.last;
    }
  }

  void startTagListItem(StartTagToken token) {
    parser.framesetOK = false;

    final stopNamesMap = const {
      'li': ['li'],
      'dt': ['dt', 'dd'],
      'dd': ['dt', 'dd']
    };
    final stopNames = stopNamesMap[token.name!]!;
    for (var node in tree.openElements.reversed) {
      if (stopNames.contains(node.localName)) {
        parser.phase.processEndTag(EndTagToken(node.localName));
        break;
      }
      if (specialElements.contains(getElementNameTuple(node)) &&
          !const ['address', 'div', 'p'].contains(node.localName)) {
        break;
      }
    }

    if (tree.elementInScope('p', variant: 'button')) {
      parser.phase.processEndTag(EndTagToken('p'));
    }

    tree.insertElement(token);
  }

  void startTagPlaintext(StartTagToken token) {
    if (tree.elementInScope('p', variant: 'button')) {
      endTagP(EndTagToken('p'));
    }
    tree.insertElement(token);
    parser.tokenizer.state = parser.tokenizer.plaintextState;
  }

  void startTagHeading(StartTagToken token) {
    if (tree.elementInScope('p', variant: 'button')) {
      endTagP(EndTagToken('p'));
    }
    if (headingElements.contains(tree.openElements.last.localName)) {
      parser
          .parseError(token.span, 'unexpected-start-tag', {'name': token.name});
      tree.openElements.removeLast();
    }
    tree.insertElement(token);
  }

  void startTagA(StartTagToken token) {
    final afeAElement = tree.elementInActiveFormattingElements('a');
    if (afeAElement != null) {
      parser.parseError(token.span, 'unexpected-start-tag-implies-end-tag',
          {'startName': 'a', 'endName': 'a'});
      endTagFormatting(EndTagToken('a'));
      tree.openElements.remove(afeAElement);
      tree.activeFormattingElements.remove(afeAElement);
    }
    tree.reconstructActiveFormattingElements();
    addFormattingElement(token);
  }

  void startTagFormatting(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    addFormattingElement(token);
  }

  void startTagNobr(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    if (tree.elementInScope('nobr')) {
      parser.parseError(token.span, 'unexpected-start-tag-implies-end-tag',
          {'startName': 'nobr', 'endName': 'nobr'});
      processEndTag(EndTagToken('nobr'));
      // XXX Need tests that trigger the following
      tree.reconstructActiveFormattingElements();
    }
    addFormattingElement(token);
  }

  Token? startTagButton(StartTagToken token) {
    if (tree.elementInScope('button')) {
      parser.parseError(token.span, 'unexpected-start-tag-implies-end-tag',
          {'startName': 'button', 'endName': 'button'});
      processEndTag(EndTagToken('button'));
      return token;
    } else {
      tree.reconstructActiveFormattingElements();
      tree.insertElement(token);
      parser.framesetOK = false;
    }
    return null;
  }

  void startTagAppletMarqueeObject(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    tree.insertElement(token);
    tree.activeFormattingElements.add(null);
    parser.framesetOK = false;
  }

  void startTagXmp(StartTagToken token) {
    if (tree.elementInScope('p', variant: 'button')) {
      endTagP(EndTagToken('p'));
    }
    tree.reconstructActiveFormattingElements();
    parser.framesetOK = false;
    parser.parseRCDataRawtext(token, 'RAWTEXT');
  }

  void startTagTable(StartTagToken token) {
    if (parser.compatMode != 'quirks') {
      if (tree.elementInScope('p', variant: 'button')) {
        processEndTag(EndTagToken('p'));
      }
    }
    tree.insertElement(token);
    parser.framesetOK = false;
    parser.phase = parser._inTablePhase;
  }

  void startTagVoidFormatting(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    tree.insertElement(token);
    tree.openElements.removeLast();
    token.selfClosingAcknowledged = true;
    parser.framesetOK = false;
  }

  void startTagInput(StartTagToken token) {
    final savedFramesetOK = parser.framesetOK;
    startTagVoidFormatting(token);
    if (token.data['type']?.toAsciiLowerCase() == 'hidden') {
      //input type=hidden doesn't change framesetOK
      parser.framesetOK = savedFramesetOK;
    }
  }

  void startTagParamSource(StartTagToken token) {
    tree.insertElement(token);
    tree.openElements.removeLast();
    token.selfClosingAcknowledged = true;
  }

  void startTagHr(StartTagToken token) {
    if (tree.elementInScope('p', variant: 'button')) {
      endTagP(EndTagToken('p'));
    }
    tree.insertElement(token);
    tree.openElements.removeLast();
    token.selfClosingAcknowledged = true;
    parser.framesetOK = false;
  }

  void startTagImage(StartTagToken token) {
    // No really...
    parser.parseError(token.span, 'unexpected-start-tag-treated-as',
        {'originalName': 'image', 'newName': 'img'});
    processStartTag(
        StartTagToken('img', data: token.data, selfClosing: token.selfClosing));
  }

  void startTagIsIndex(StartTagToken token) {
    parser.parseError(token.span, 'deprecated-tag', {'name': 'isindex'});
    if (tree.formPointer != null) {
      return;
    }
    final formAttrs = LinkedHashMap<Object, String>();
    final dataAction = token.data['action'];
    if (dataAction != null) {
      formAttrs['action'] = dataAction;
    }
    processStartTag(StartTagToken('form', data: formAttrs));
    processStartTag(StartTagToken('hr', data: LinkedHashMap<Object, String>()));
    processStartTag(
        StartTagToken('label', data: LinkedHashMap<Object, String>()));
    // XXX Localization ...
    var prompt = token.data['prompt'];
    prompt ??= 'This is a searchable index. Enter search keywords: ';
    processCharacters(CharactersToken(prompt));
    final attributes = LinkedHashMap<Object, String>.from(token.data);
    attributes.remove('action');
    attributes.remove('prompt');
    attributes['name'] = 'isindex';
    processStartTag(StartTagToken('input',
        data: attributes, selfClosing: token.selfClosing));
    processEndTag(EndTagToken('label'));
    processStartTag(StartTagToken('hr', data: LinkedHashMap<Object, String>()));
    processEndTag(EndTagToken('form'));
  }

  void startTagTextarea(StartTagToken token) {
    tree.insertElement(token);
    parser.tokenizer.state = parser.tokenizer.rcdataState;
    dropNewline = true;
    parser.framesetOK = false;
  }

  void startTagIFrame(StartTagToken token) {
    parser.framesetOK = false;
    startTagRawtext(token);
  }

  /// iframe, noembed noframes, noscript(if scripting enabled).
  void startTagRawtext(StartTagToken token) {
    parser.parseRCDataRawtext(token, 'RAWTEXT');
  }

  void startTagOpt(StartTagToken token) {
    if (tree.openElements.last.localName == 'option') {
      parser.phase.processEndTag(EndTagToken('option'));
    }
    tree.reconstructActiveFormattingElements();
    parser.tree.insertElement(token);
  }

  void startTagSelect(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    tree.insertElement(token);
    parser.framesetOK = false;

    if (parser._inTablePhase == parser.phase ||
        parser._inCaptionPhase == parser.phase ||
        parser._inColumnGroupPhase == parser.phase ||
        parser._inTableBodyPhase == parser.phase ||
        parser._inRowPhase == parser.phase ||
        parser._inCellPhase == parser.phase) {
      parser.phase = parser._inSelectInTablePhase;
    } else {
      parser.phase = parser._inSelectPhase;
    }
  }

  void startTagRpRt(StartTagToken token) {
    if (tree.elementInScope('ruby')) {
      tree.generateImpliedEndTags();
      final last = tree.openElements.last;
      if (last.localName != 'ruby') {
        parser.parseError(last.sourceSpan, 'undefined-error');
      }
    }
    tree.insertElement(token);
  }

  void startTagMath(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    parser.adjustMathMLAttributes(token);
    parser.adjustForeignAttributes(token);
    token.namespace = Namespaces.mathml;
    tree.insertElement(token);
    //Need to get the parse error right for the case where the token
    //has a namespace not equal to the xmlns attribute
    if (token.selfClosing) {
      tree.openElements.removeLast();
      token.selfClosingAcknowledged = true;
    }
  }

  void startTagSvg(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    parser.adjustSVGAttributes(token);
    parser.adjustForeignAttributes(token);
    token.namespace = Namespaces.svg;
    tree.insertElement(token);
    //Need to get the parse error right for the case where the token
    //has a namespace not equal to the xmlns attribute
    if (token.selfClosing) {
      tree.openElements.removeLast();
      token.selfClosingAcknowledged = true;
    }
  }

  /// Elements that should be children of other elements that have a
  /// different insertion mode; here they are ignored
  /// "caption", "col", "colgroup", "frame", "frameset", "head",
  /// "option", "optgroup", "tbody", "td", "tfoot", "th", "thead",
  /// "tr", "noscript"
  void startTagMisplaced(StartTagToken token) {
    parser.parseError(
        token.span, 'unexpected-start-tag-ignored', {'name': token.name});
  }

  Token? startTagOther(StartTagToken token) {
    tree.reconstructActiveFormattingElements();
    tree.insertElement(token);
    return null;
  }

  void endTagP(EndTagToken token) {
    if (!tree.elementInScope('p', variant: 'button')) {
      startTagCloseP(StartTagToken('p', data: LinkedHashMap<Object, String>()));
      parser.parseError(token.span, 'unexpected-end-tag', {'name': 'p'});
      endTagP(EndTagToken('p'));
    } else {
      tree.generateImpliedEndTags('p');
      if (tree.openElements.last.localName != 'p') {
        parser.parseError(token.span, 'unexpected-end-tag', {'name': 'p'});
      }
      popOpenElementsUntil(token);
    }
  }

  void endTagBody(EndTagToken token) {
    if (!tree.elementInScope('body')) {
      parser.parseError(token.span, 'undefined-error');
      return;
    } else if (tree.openElements.last.localName == 'body') {
      tree.openElements.last.endSourceSpan = token.span;
    } else {
      for (var node in slice(tree.openElements, 2)) {
        switch (node.localName) {
          case 'dd':
          case 'dt':
          case 'li':
          case 'optgroup':
          case 'option':
          case 'p':
          case 'rp':
          case 'rt':
          case 'tbody':
          case 'td':
          case 'tfoot':
          case 'th':
          case 'thead':
          case 'tr':
          case 'body':
          case 'html':
            continue;
        }
        // Not sure this is the correct name for the parse error
        parser.parseError(token.span, 'expected-one-end-tag-but-got-another',
            {'gotName': 'body', 'expectedName': node.localName});
        break;
      }
    }
    parser.phase = parser._afterBodyPhase;
  }

  Token? endTagHtml(EndTagToken token) {
    //We repeat the test for the body end tag token being ignored here
    if (tree.elementInScope('body')) {
      endTagBody(EndTagToken('body'));
      return token;
    }
    return null;
  }

  void endTagBlock(EndTagToken token) {
    //Put us back in the right whitespace handling mode
    if (token.name == 'pre') {
      dropNewline = false;
    }
    final inScope = tree.elementInScope(token.name);
    if (inScope) {
      tree.generateImpliedEndTags();
    }
    if (tree.openElements.last.localName != token.name) {
      parser.parseError(token.span, 'end-tag-too-early', {'name': token.name});
    }
    if (inScope) {
      popOpenElementsUntil(token);
    }
  }

  void endTagForm(EndTagToken token) {
    final node = tree.formPointer;
    tree.formPointer = null;
    if (node == null || !tree.elementInScope(node)) {
      parser.parseError(token.span, 'unexpected-end-tag', {'name': 'form'});
    } else {
      tree.generateImpliedEndTags();
      if (tree.openElements.last != node) {
        parser.parseError(
            token.span, 'end-tag-too-early-ignored', {'name': 'form'});
      }
      tree.openElements.remove(node);
      node.endSourceSpan = token.span;
    }
  }

  void endTagListItem(EndTagToken token) {
    String? variant;
    if (token.name == 'li') {
      variant = 'list';
    } else {
      variant = null;
    }
    if (!tree.elementInScope(token.name, variant: variant)) {
      parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
    } else {
      tree.generateImpliedEndTags(token.name);
      if (tree.openElements.last.localName != token.name) {
        parser
            .parseError(token.span, 'end-tag-too-early', {'name': token.name});
      }
      popOpenElementsUntil(token);
    }
  }

  void endTagHeading(EndTagToken token) {
    for (var item in headingElements) {
      if (tree.elementInScope(item)) {
        tree.generateImpliedEndTags();
        break;
      }
    }
    if (tree.openElements.last.localName != token.name) {
      parser.parseError(token.span, 'end-tag-too-early', {'name': token.name});
    }

    for (var item in headingElements) {
      if (tree.elementInScope(item)) {
        var node = tree.openElements.removeLast();
        while (!headingElements.contains(node.localName)) {
          node = tree.openElements.removeLast();
        }
        node.endSourceSpan = token.span;
        break;
      }
    }
  }

  /// The much-feared adoption agency algorithm.
  void endTagFormatting(EndTagToken token) {
    // http://www.whatwg.org/specs/web-apps/current-work/multipage/tree-construction.html#adoptionAgency
    // TODO(jmesserly): the comments here don't match the numbered steps in the
    // updated spec. This needs a pass over it to verify that it still matches.
    // In particular the html5lib Python code skiped "step 4", I'm not sure why.
    // XXX Better parseError messages appreciated.
    var outerLoopCounter = 0;
    while (outerLoopCounter < 8) {
      outerLoopCounter += 1;

      // Step 1 paragraph 1
      final formattingElement =
          tree.elementInActiveFormattingElements(token.name);
      if (formattingElement == null ||
          (tree.openElements.contains(formattingElement) &&
              !tree.elementInScope(formattingElement.localName))) {
        parser.parseError(
            token.span, 'adoption-agency-1.1', {'name': token.name});
        return;
        // Step 1 paragraph 2
      } else if (!tree.openElements.contains(formattingElement)) {
        parser.parseError(
            token.span, 'adoption-agency-1.2', {'name': token.name});
        tree.activeFormattingElements.remove(formattingElement);
        return;
      }

      // Step 1 paragraph 3
      if (formattingElement != tree.openElements.last) {
        parser.parseError(
            token.span, 'adoption-agency-1.3', {'name': token.name});
      }

      // Step 2
      // Start of the adoption agency algorithm proper
      final afeIndex = tree.openElements.indexOf(formattingElement);
      Element? furthestBlock;
      for (var element in slice(tree.openElements, afeIndex)) {
        if (specialElements.contains(getElementNameTuple(element))) {
          furthestBlock = element;
          break;
        }
      }
      // Step 3
      if (furthestBlock == null) {
        var element = tree.openElements.removeLast();
        while (element != formattingElement) {
          element = tree.openElements.removeLast();
        }
        element.endSourceSpan = token.span;
        tree.activeFormattingElements.remove(element);
        return;
      }

      final commonAncestor = tree.openElements[afeIndex - 1];

      // Step 5
      // The bookmark is supposed to help us identify where to reinsert
      // nodes in step 12. We have to ensure that we reinsert nodes after
      // the node before the active formatting element. Note the bookmark
      // can move in step 7.4
      var bookmark = tree.activeFormattingElements.indexOf(formattingElement);

      // Step 6
      var lastNode = furthestBlock;
      var node = furthestBlock;
      var innerLoopCounter = 0;

      var index = tree.openElements.indexOf(node);
      while (innerLoopCounter < 3) {
        innerLoopCounter += 1;

        // Node is element before node in open elements
        index -= 1;
        node = tree.openElements[index];
        if (!tree.activeFormattingElements.contains(node)) {
          tree.openElements.remove(node);
          continue;
        }
        // Step 6.3
        if (node == formattingElement) {
          break;
        }
        // Step 6.4
        if (lastNode == furthestBlock) {
          bookmark = (tree.activeFormattingElements.indexOf(node) + 1);
        }
        // Step 6.5
        //cite = node.parent
        final clone = node.clone(false);
        // Replace node with clone
        tree.activeFormattingElements[
            tree.activeFormattingElements.indexOf(node)] = clone;
        tree.openElements[tree.openElements.indexOf(node)] = clone;
        node = clone;

        // Step 6.6
        // Remove lastNode from its parents, if any
        if (lastNode.parentNode != null) {
          lastNode.parentNode!.nodes.remove(lastNode);
        }
        node.nodes.add(lastNode);
        // Step 7.7
        lastNode = node;
        // End of inner loop
      }

      // Step 7
      // Foster parent lastNode if commonAncestor is a
      // table, tbody, tfoot, thead, or tr we need to foster parent the
      // lastNode
      if (lastNode.parentNode != null) {
        lastNode.parentNode!.nodes.remove(lastNode);
      }

      if (const ['table', 'tbody', 'tfoot', 'thead', 'tr']
          .contains(commonAncestor.localName)) {
        final nodePos = tree.getTableMisnestedNodePosition();
        nodePos[0]!.insertBefore(lastNode, nodePos[1]);
      } else {
        commonAncestor.nodes.add(lastNode);
      }

      // Step 8
      final clone = formattingElement.clone(false);

      // Step 9
      furthestBlock.reparentChildren(clone);

      // Step 10
      furthestBlock.nodes.add(clone);

      // Step 11
      tree.activeFormattingElements.remove(formattingElement);
      tree.activeFormattingElements
          .insert(min(bookmark, tree.activeFormattingElements.length), clone);

      // Step 12
      tree.openElements.remove(formattingElement);
      tree.openElements
          .insert(tree.openElements.indexOf(furthestBlock) + 1, clone);
    }
  }

  void endTagAppletMarqueeObject(EndTagToken token) {
    if (tree.elementInScope(token.name)) {
      tree.generateImpliedEndTags();
    }
    if (tree.openElements.last.localName != token.name) {
      parser.parseError(token.span, 'end-tag-too-early', {'name': token.name});
    }
    if (tree.elementInScope(token.name)) {
      popOpenElementsUntil(token);
      tree.clearActiveFormattingElements();
    }
  }

  void endTagBr(EndTagToken token) {
    parser.parseError(token.span, 'unexpected-end-tag-treated-as',
        {'originalName': 'br', 'newName': 'br element'});
    tree.reconstructActiveFormattingElements();
    tree.insertElement(
        StartTagToken('br', data: LinkedHashMap<Object, String>()));
    tree.openElements.removeLast();
  }

  void endTagOther(EndTagToken token) {
    for (var node in tree.openElements.reversed) {
      if (node.localName == token.name) {
        tree.generateImpliedEndTags(token.name);
        if (tree.openElements.last.localName != token.name) {
          parser.parseError(
              token.span, 'unexpected-end-tag', {'name': token.name});
        }
        while (tree.openElements.removeLast() != node) {
          // noop
        }
        node.endSourceSpan = token.span;
        break;
      } else {
        if (specialElements.contains(getElementNameTuple(node))) {
          parser.parseError(
              token.span, 'unexpected-end-tag', {'name': token.name});
          break;
        }
      }
    }
  }
}

class TextPhase extends Phase {
  TextPhase(HtmlParser parser) : super(parser);

  // "Tried to process start tag %s in RCDATA/RAWTEXT mode"%token.name
  @override
  Token processStartTag(StartTagToken token) {
    throw StateError('Cannot process start stag in text phase');
  }

  @override
  Token? processEndTag(EndTagToken token) {
    if (token.name == 'script') {
      endTagScript(token);
      return null;
    }
    endTagOther(token);
    return null;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    tree.insertText(token.data, token.span);
    return null;
  }

  @override
  bool processEOF() {
    final last = tree.openElements.last;
    parser.parseError(last.sourceSpan, 'expected-named-closing-tag-but-got-eof',
        {'name': last.localName});
    tree.openElements.removeLast();
    parser.phase = parser.originalPhase!;
    return true;
  }

  void endTagScript(EndTagToken token) {
    final node = tree.openElements.removeLast();
    assert(node.localName == 'script');
    parser.phase = parser.originalPhase!;
    //The rest of this method is all stuff that only happens if
    //document.write works
  }

  void endTagOther(EndTagToken token) {
    tree.openElements.removeLast();
    parser.phase = parser.originalPhase!;
  }
}

class InTablePhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///in-table
  InTablePhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'caption':
        startTagCaption(token);
        return null;
      case 'colgroup':
        startTagColgroup(token);
        return null;
      case 'col':
        return startTagCol(token);
      case 'tbody':
      case 'tfoot':
      case 'thead':
        startTagRowGroup(token);
        return null;
      case 'td':
      case 'th':
      case 'tr':
        return startTagImplyTbody(token);
      case 'table':
        return startTagTable(token);
      case 'style':
      case 'script':
        return startTagStyleScript(token);
      case 'input':
        startTagInput(token);
        return null;
      case 'form':
        startTagForm(token);
        return null;
      default:
        startTagOther(token);
        return null;
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'table':
        endTagTable(token);
        return null;
      case 'body':
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'html':
      case 'tbody':
      case 'td':
      case 'tfoot':
      case 'th':
      case 'thead':
      case 'tr':
        endTagIgnore(token);
        return null;
      default:
        endTagOther(token);
        return null;
    }
  }

  // helper methods
  void clearStackToTableContext() {
    // 'clear the stack back to a table context'
    while (tree.openElements.last.localName != 'table' &&
        tree.openElements.last.localName != 'html') {
      //parser.parseError(token.span, "unexpected-implied-end-tag-in-table",
      //  {"name":  tree.openElements.last.name})
      tree.openElements.removeLast();
    }
    // When the current node is <html> it's an innerHTML case
  }

  // processing methods
  @override
  bool processEOF() {
    final last = tree.openElements.last;
    if (last.localName != 'html') {
      parser.parseError(last.sourceSpan, 'eof-in-table');
    } else {
      assert(parser.innerHTMLMode);
    }
    //Stop parsing
    return false;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    final originalPhase = parser.phase;
    parser.phase = parser._inTableTextPhase;
    parser._inTableTextPhase.originalPhase = originalPhase;
    parser.phase.processSpaceCharacters(token);
    return null;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    final originalPhase = parser.phase;
    parser.phase = parser._inTableTextPhase;
    parser._inTableTextPhase.originalPhase = originalPhase;
    parser.phase.processCharacters(token);
    return null;
  }

  void insertText(CharactersToken token) {
    // If we get here there must be at least one non-whitespace character
    // Do the table magic!
    tree.insertFromTable = true;
    parser._inBodyPhase.processCharacters(token);
    tree.insertFromTable = false;
  }

  void startTagCaption(StartTagToken token) {
    clearStackToTableContext();
    tree.activeFormattingElements.add(null);
    tree.insertElement(token);
    parser.phase = parser._inCaptionPhase;
  }

  void startTagColgroup(StartTagToken token) {
    clearStackToTableContext();
    tree.insertElement(token);
    parser.phase = parser._inColumnGroupPhase;
  }

  Token startTagCol(StartTagToken token) {
    startTagColgroup(
        StartTagToken('colgroup', data: LinkedHashMap<Object, String>()));
    return token;
  }

  void startTagRowGroup(StartTagToken token) {
    clearStackToTableContext();
    tree.insertElement(token);
    parser.phase = parser._inTableBodyPhase;
  }

  Token startTagImplyTbody(StartTagToken token) {
    startTagRowGroup(
        StartTagToken('tbody', data: LinkedHashMap<Object, String>()));
    return token;
  }

  Token? startTagTable(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-start-tag-implies-end-tag',
        {'startName': 'table', 'endName': 'table'});
    parser.phase.processEndTag(EndTagToken('table'));
    if (!parser.innerHTMLMode) {
      return token;
    }
    return null;
  }

  Token? startTagStyleScript(StartTagToken token) {
    return parser._inHeadPhase.processStartTag(token);
  }

  void startTagInput(StartTagToken token) {
    if (token.data['type']?.toAsciiLowerCase() == 'hidden') {
      parser.parseError(token.span, 'unexpected-hidden-input-in-table');
      tree.insertElement(token);
      // XXX associate with form
      tree.openElements.removeLast();
    } else {
      startTagOther(token);
    }
  }

  void startTagForm(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-form-in-table');
    if (tree.formPointer == null) {
      tree.insertElement(token);
      tree.formPointer = tree.openElements.last;
      tree.openElements.removeLast();
    }
  }

  void startTagOther(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-start-tag-implies-table-voodoo',
        {'name': token.name});
    // Do the table magic!
    tree.insertFromTable = true;
    parser._inBodyPhase.processStartTag(token);
    tree.insertFromTable = false;
  }

  void endTagTable(EndTagToken token) {
    if (tree.elementInScope('table', variant: 'table')) {
      tree.generateImpliedEndTags();
      final last = tree.openElements.last;
      if (last.localName != 'table') {
        parser.parseError(token.span, 'end-tag-too-early-named',
            {'gotName': 'table', 'expectedName': last.localName});
      }
      while (tree.openElements.last.localName != 'table') {
        tree.openElements.removeLast();
      }
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
      parser.resetInsertionMode();
    } else {
      // innerHTML case
      assert(parser.innerHTMLMode);
      parser.parseError(token.span, 'undefined-error');
    }
  }

  void endTagIgnore(EndTagToken token) {
    parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
  }

  void endTagOther(EndTagToken token) {
    parser.parseError(token.span, 'unexpected-end-tag-implies-table-voodoo',
        {'name': token.name});
    // Do the table magic!
    tree.insertFromTable = true;
    parser._inBodyPhase.processEndTag(token);
    tree.insertFromTable = false;
  }
}

class InTableTextPhase extends Phase {
  Phase? originalPhase;
  List<StringToken> characterTokens;

  InTableTextPhase(HtmlParser parser)
      : characterTokens = <StringToken>[],
        super(parser);

  void flushCharacters() {
    if (characterTokens.isEmpty) return;

    // TODO(sigmund,jmesserly): remove '' (dartbug.com/8480)
    final data = characterTokens.map((t) => t.data).join('');
    FileSpan? span;

    if (parser.generateSpans) {
      span = characterTokens[0].span!.expand(characterTokens.last.span!);
    }

    if (!allWhitespace(data)) {
      parser._inTablePhase.insertText(CharactersToken(data)..span = span);
    } else if (data.isNotEmpty) {
      tree.insertText(data, span);
    }
    characterTokens = <StringToken>[];
  }

  @override
  Token processComment(CommentToken token) {
    flushCharacters();
    parser.phase = originalPhase!;
    return token;
  }

  @override
  bool processEOF() {
    flushCharacters();
    parser.phase = originalPhase!;
    return true;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    if (token.data == '\u0000') {
      return null;
    }
    characterTokens.add(token);
    return null;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    //pretty sure we should never reach here
    characterTokens.add(token);
    // XXX assert(false);
    return null;
  }

  @override
  Token processStartTag(StartTagToken token) {
    flushCharacters();
    parser.phase = originalPhase!;
    return token;
  }

  @override
  Token processEndTag(EndTagToken token) {
    flushCharacters();
    parser.phase = originalPhase!;
    return token;
  }
}

class InCaptionPhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///in-caption
  InCaptionPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'tbody':
      case 'td':
      case 'tfoot':
      case 'th':
      case 'thead':
      case 'tr':
        return startTagTableElement(token);
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'caption':
        endTagCaption(token);
        return null;
      case 'table':
        return endTagTable(token);
      case 'body':
      case 'col':
      case 'colgroup':
      case 'html':
      case 'tbody':
      case 'td':
      case 'tfoot':
      case 'th':
      case 'thead':
      case 'tr':
        endTagIgnore(token);
        return null;
      default:
        return endTagOther(token);
    }
  }

  bool ignoreEndTagCaption() {
    return !tree.elementInScope('caption', variant: 'table');
  }

  @override
  bool processEOF() {
    parser._inBodyPhase.processEOF();
    return false;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    return parser._inBodyPhase.processCharacters(token);
  }

  Token? startTagTableElement(StartTagToken token) {
    parser.parseError(token.span, 'undefined-error');
    //XXX Have to duplicate logic here to find out if the tag is ignored
    final ignoreEndTag = ignoreEndTagCaption();
    parser.phase.processEndTag(EndTagToken('caption'));
    if (!ignoreEndTag) {
      return token;
    }
    return null;
  }

  Token? startTagOther(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  void endTagCaption(EndTagToken token) {
    if (!ignoreEndTagCaption()) {
      // AT this code is quite similar to endTagTable in "InTable"
      tree.generateImpliedEndTags();
      if (tree.openElements.last.localName != 'caption') {
        parser.parseError(token.span, 'expected-one-end-tag-but-got-another', {
          'gotName': 'caption',
          'expectedName': tree.openElements.last.localName
        });
      }
      while (tree.openElements.last.localName != 'caption') {
        tree.openElements.removeLast();
      }
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
      tree.clearActiveFormattingElements();
      parser.phase = parser._inTablePhase;
    } else {
      // innerHTML case
      assert(parser.innerHTMLMode);
      parser.parseError(token.span, 'undefined-error');
    }
  }

  Token? endTagTable(EndTagToken token) {
    parser.parseError(token.span, 'undefined-error');
    final ignoreEndTag = ignoreEndTagCaption();
    parser.phase.processEndTag(EndTagToken('caption'));
    if (!ignoreEndTag) {
      return token;
    }
    return null;
  }

  void endTagIgnore(EndTagToken token) {
    parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
  }

  Token? endTagOther(EndTagToken token) {
    return parser._inBodyPhase.processEndTag(token);
  }
}

class InColumnGroupPhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///in-column
  InColumnGroupPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'col':
        startTagCol(token);
        return null;
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'colgroup':
        endTagColgroup(token);
        return null;
      case 'col':
        endTagCol(token);
        return null;
      default:
        return endTagOther(token);
    }
  }

  bool ignoreEndTagColgroup() {
    return tree.openElements.last.localName == 'html';
  }

  @override
  bool processEOF() {
    final ignoreEndTag = ignoreEndTagColgroup();
    if (ignoreEndTag) {
      assert(parser.innerHTMLMode);
      return false;
    } else {
      endTagColgroup(EndTagToken('colgroup'));
      return true;
    }
  }

  @override
  Token? processCharacters(CharactersToken token) {
    final ignoreEndTag = ignoreEndTagColgroup();
    endTagColgroup(EndTagToken('colgroup'));
    return ignoreEndTag ? null : token;
  }

  void startTagCol(StartTagToken token) {
    tree.insertElement(token);
    tree.openElements.removeLast();
  }

  Token? startTagOther(StartTagToken token) {
    final ignoreEndTag = ignoreEndTagColgroup();
    endTagColgroup(EndTagToken('colgroup'));
    return ignoreEndTag ? null : token;
  }

  void endTagColgroup(EndTagToken token) {
    if (ignoreEndTagColgroup()) {
      // innerHTML case
      assert(parser.innerHTMLMode);
      parser.parseError(token.span, 'undefined-error');
    } else {
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
      parser.phase = parser._inTablePhase;
    }
  }

  void endTagCol(EndTagToken token) {
    parser.parseError(token.span, 'no-end-tag', {'name': 'col'});
  }

  Token? endTagOther(EndTagToken token) {
    final ignoreEndTag = ignoreEndTagColgroup();
    endTagColgroup(EndTagToken('colgroup'));
    return ignoreEndTag ? null : token;
  }
}

class InTableBodyPhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///in-table0
  InTableBodyPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'tr':
        startTagTr(token);
        return null;
      case 'td':
      case 'th':
        return startTagTableCell(token);
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'tbody':
      case 'tfoot':
      case 'thead':
        return startTagTableOther(token);
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'tbody':
      case 'tfoot':
      case 'thead':
        endTagTableRowGroup(token);
        return null;
      case 'table':
        return endTagTable(token);
      case 'body':
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'html':
      case 'td':
      case 'th':
      case 'tr':
        endTagIgnore(token);
        return null;
      default:
        return endTagOther(token);
    }
  }

  // helper methods
  void clearStackToTableBodyContext() {
    final tableTags = const ['tbody', 'tfoot', 'thead', 'html'];
    while (!tableTags.contains(tree.openElements.last.localName)) {
      //XXX parser.parseError(token.span, "unexpected-implied-end-tag-in-table",
      //  {"name": tree.openElements.last.name})
      tree.openElements.removeLast();
    }
    if (tree.openElements.last.localName == 'html') {
      assert(parser.innerHTMLMode);
    }
  }

  // the rest
  @override
  bool processEOF() {
    parser._inTablePhase.processEOF();
    return false;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    return parser._inTablePhase.processSpaceCharacters(token);
  }

  @override
  Token? processCharacters(CharactersToken token) {
    return parser._inTablePhase.processCharacters(token);
  }

  void startTagTr(StartTagToken token) {
    clearStackToTableBodyContext();
    tree.insertElement(token);
    parser.phase = parser._inRowPhase;
  }

  Token startTagTableCell(StartTagToken token) {
    parser.parseError(
        token.span, 'unexpected-cell-in-table-body', {'name': token.name});
    startTagTr(StartTagToken('tr', data: LinkedHashMap<Object, String>()));
    return token;
  }

  Token? startTagTableOther(TagToken token) => endTagTable(token);

  Token? startTagOther(StartTagToken token) {
    return parser._inTablePhase.processStartTag(token);
  }

  void endTagTableRowGroup(EndTagToken token) {
    if (tree.elementInScope(token.name, variant: 'table')) {
      clearStackToTableBodyContext();
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
      parser.phase = parser._inTablePhase;
    } else {
      parser.parseError(
          token.span, 'unexpected-end-tag-in-table-body', {'name': token.name});
    }
  }

  Token? endTagTable(TagToken token) {
    // XXX AT Any ideas on how to share this with endTagTable?
    if (tree.elementInScope('tbody', variant: 'table') ||
        tree.elementInScope('thead', variant: 'table') ||
        tree.elementInScope('tfoot', variant: 'table')) {
      clearStackToTableBodyContext();
      endTagTableRowGroup(EndTagToken(tree.openElements.last.localName));
      return token;
    } else {
      // innerHTML case
      assert(parser.innerHTMLMode);
      parser.parseError(token.span, 'undefined-error');
    }
    return null;
  }

  void endTagIgnore(EndTagToken token) {
    parser.parseError(
        token.span, 'unexpected-end-tag-in-table-body', {'name': token.name});
  }

  Token? endTagOther(EndTagToken token) {
    return parser._inTablePhase.processEndTag(token);
  }
}

class InRowPhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///in-row
  InRowPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'td':
      case 'th':
        startTagTableCell(token);
        return null;
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'tbody':
      case 'tfoot':
      case 'thead':
      case 'tr':
        return startTagTableOther(token);
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'tr':
        endTagTr(token);
        return null;
      case 'table':
        return endTagTable(token);
      case 'tbody':
      case 'tfoot':
      case 'thead':
        return endTagTableRowGroup(token);
      case 'body':
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'html':
      case 'td':
      case 'th':
        endTagIgnore(token);
        return null;
      default:
        return endTagOther(token);
    }
  }

  // helper methods (XXX unify this with other table helper methods)
  void clearStackToTableRowContext() {
    while (true) {
      final last = tree.openElements.last;
      if (last.localName == 'tr' || last.localName == 'html') break;

      parser.parseError(
          last.sourceSpan,
          'unexpected-implied-end-tag-in-table-row',
          {'name': tree.openElements.last.localName});
      tree.openElements.removeLast();
    }
  }

  bool ignoreEndTagTr() {
    return !tree.elementInScope('tr', variant: 'table');
  }

  // the rest
  @override
  bool processEOF() {
    parser._inTablePhase.processEOF();
    return false;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    return parser._inTablePhase.processSpaceCharacters(token);
  }

  @override
  Token? processCharacters(CharactersToken token) {
    return parser._inTablePhase.processCharacters(token);
  }

  void startTagTableCell(StartTagToken token) {
    clearStackToTableRowContext();
    tree.insertElement(token);
    parser.phase = parser._inCellPhase;
    tree.activeFormattingElements.add(null);
  }

  Token? startTagTableOther(StartTagToken token) {
    final ignoreEndTag = ignoreEndTagTr();
    endTagTr(EndTagToken('tr'));
    // XXX how are we sure it's always ignored in the innerHTML case?
    return ignoreEndTag ? null : token;
  }

  Token? startTagOther(StartTagToken token) {
    return parser._inTablePhase.processStartTag(token);
  }

  void endTagTr(EndTagToken token) {
    if (!ignoreEndTagTr()) {
      clearStackToTableRowContext();
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
      parser.phase = parser._inTableBodyPhase;
    } else {
      // innerHTML case
      assert(parser.innerHTMLMode);
      parser.parseError(token.span, 'undefined-error');
    }
  }

  Token? endTagTable(EndTagToken token) {
    final ignoreEndTag = ignoreEndTagTr();
    endTagTr(EndTagToken('tr'));
    // Reprocess the current tag if the tr end tag was not ignored
    // XXX how are we sure it's always ignored in the innerHTML case?
    return ignoreEndTag ? null : token;
  }

  Token? endTagTableRowGroup(EndTagToken token) {
    if (tree.elementInScope(token.name, variant: 'table')) {
      endTagTr(EndTagToken('tr'));
      return token;
    } else {
      parser.parseError(token.span, 'undefined-error');
      return null;
    }
  }

  void endTagIgnore(EndTagToken token) {
    parser.parseError(
        token.span, 'unexpected-end-tag-in-table-row', {'name': token.name});
  }

  Token? endTagOther(EndTagToken token) {
    return parser._inTablePhase.processEndTag(token);
  }
}

class InCellPhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///in-cell
  InCellPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'tbody':
      case 'td':
      case 'tfoot':
      case 'th':
      case 'thead':
      case 'tr':
        return startTagTableOther(token);
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'td':
      case 'th':
        endTagTableCell(token);
        return null;
      case 'body':
      case 'caption':
      case 'col':
      case 'colgroup':
      case 'html':
        endTagIgnore(token);
        return null;
      case 'table':
      case 'tbody':
      case 'tfoot':
      case 'thead':
      case 'tr':
        return endTagImply(token);
      default:
        return endTagOther(token);
    }
  }

  // helper
  void closeCell() {
    if (tree.elementInScope('td', variant: 'table')) {
      endTagTableCell(EndTagToken('td'));
    } else if (tree.elementInScope('th', variant: 'table')) {
      endTagTableCell(EndTagToken('th'));
    }
  }

  // the rest
  @override
  bool processEOF() {
    parser._inBodyPhase.processEOF();
    return false;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    return parser._inBodyPhase.processCharacters(token);
  }

  Token? startTagTableOther(StartTagToken token) {
    if (tree.elementInScope('td', variant: 'table') ||
        tree.elementInScope('th', variant: 'table')) {
      closeCell();
      return token;
    } else {
      // innerHTML case
      assert(parser.innerHTMLMode);
      parser.parseError(token.span, 'undefined-error');
      return null;
    }
  }

  Token? startTagOther(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  void endTagTableCell(EndTagToken token) {
    if (tree.elementInScope(token.name, variant: 'table')) {
      tree.generateImpliedEndTags(token.name);
      if (tree.openElements.last.localName != token.name) {
        parser.parseError(
            token.span, 'unexpected-cell-end-tag', {'name': token.name});
        popOpenElementsUntil(token);
      } else {
        final node = tree.openElements.removeLast();
        node.endSourceSpan = token.span;
      }
      tree.clearActiveFormattingElements();
      parser.phase = parser._inRowPhase;
    } else {
      parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
    }
  }

  void endTagIgnore(EndTagToken token) {
    parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
  }

  Token? endTagImply(EndTagToken token) {
    if (tree.elementInScope(token.name, variant: 'table')) {
      closeCell();
      return token;
    } else {
      // sometimes innerHTML case
      parser.parseError(token.span, 'undefined-error');
    }
    return null;
  }

  Token? endTagOther(EndTagToken token) {
    return parser._inBodyPhase.processEndTag(token);
  }
}

class InSelectPhase extends Phase {
  InSelectPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'option':
        startTagOption(token);
        return null;
      case 'optgroup':
        startTagOptgroup(token);
        return null;
      case 'select':
        startTagSelect(token);
        return null;
      case 'input':
      case 'keygen':
      case 'textarea':
        return startTagInput(token);
      case 'script':
        return startTagScript(token);
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'option':
        endTagOption(token);
        return null;
      case 'optgroup':
        endTagOptgroup(token);
        return null;
      case 'select':
        endTagSelect(token);
        return null;
      default:
        endTagOther(token);
        return null;
    }
  }

  // http://www.whatwg.org/specs/web-apps/current-work///in-select
  @override
  bool processEOF() {
    final last = tree.openElements.last;
    if (last.localName != 'html') {
      parser.parseError(last.sourceSpan, 'eof-in-select');
    } else {
      assert(parser.innerHTMLMode);
    }
    return false;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    if (token.data == '\u0000') {
      return null;
    }
    tree.insertText(token.data, token.span);
    return null;
  }

  void startTagOption(StartTagToken token) {
    // We need to imply </option> if <option> is the current node.
    if (tree.openElements.last.localName == 'option') {
      tree.openElements.removeLast();
    }
    tree.insertElement(token);
  }

  void startTagOptgroup(StartTagToken token) {
    if (tree.openElements.last.localName == 'option') {
      tree.openElements.removeLast();
    }
    if (tree.openElements.last.localName == 'optgroup') {
      tree.openElements.removeLast();
    }
    tree.insertElement(token);
  }

  void startTagSelect(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-select-in-select');
    endTagSelect(EndTagToken('select'));
  }

  Token? startTagInput(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-input-in-select');
    if (tree.elementInScope('select', variant: 'select')) {
      endTagSelect(EndTagToken('select'));
      return token;
    } else {
      assert(parser.innerHTMLMode);
    }
    return null;
  }

  Token? startTagScript(StartTagToken token) {
    return parser._inHeadPhase.processStartTag(token);
  }

  Token? startTagOther(StartTagToken token) {
    parser.parseError(
        token.span, 'unexpected-start-tag-in-select', {'name': token.name});
    return null;
  }

  void endTagOption(EndTagToken token) {
    if (tree.openElements.last.localName == 'option') {
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
    } else {
      parser.parseError(
          token.span, 'unexpected-end-tag-in-select', {'name': 'option'});
    }
  }

  void endTagOptgroup(EndTagToken token) {
    // </optgroup> implicitly closes <option>
    if (tree.openElements.last.localName == 'option' &&
        tree.openElements[tree.openElements.length - 2].localName ==
            'optgroup') {
      tree.openElements.removeLast();
    }
    // It also closes </optgroup>
    if (tree.openElements.last.localName == 'optgroup') {
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
      // But nothing else
    } else {
      parser.parseError(
          token.span, 'unexpected-end-tag-in-select', {'name': 'optgroup'});
    }
  }

  void endTagSelect(EndTagToken token) {
    if (tree.elementInScope('select', variant: 'select')) {
      popOpenElementsUntil(token);
      parser.resetInsertionMode();
    } else {
      // innerHTML case
      assert(parser.innerHTMLMode);
      parser.parseError(token.span, 'undefined-error');
    }
  }

  void endTagOther(EndTagToken token) {
    parser.parseError(
        token.span, 'unexpected-end-tag-in-select', {'name': token.name});
  }
}

class InSelectInTablePhase extends Phase {
  InSelectInTablePhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'caption':
      case 'table':
      case 'tbody':
      case 'tfoot':
      case 'thead':
      case 'tr':
      case 'td':
      case 'th':
        return startTagTable(token);
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'caption':
      case 'table':
      case 'tbody':
      case 'tfoot':
      case 'thead':
      case 'tr':
      case 'td':
      case 'th':
        return endTagTable(token);
      default:
        return endTagOther(token);
    }
  }

  @override
  bool processEOF() {
    parser._inSelectPhase.processEOF();
    return false;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    return parser._inSelectPhase.processCharacters(token);
  }

  Token startTagTable(StartTagToken token) {
    parser.parseError(
        token.span,
        'unexpected-table-element-start-tag-in-select-in-table',
        {'name': token.name});
    endTagOther(EndTagToken('select'));
    return token;
  }

  Token? startTagOther(StartTagToken token) {
    return parser._inSelectPhase.processStartTag(token);
  }

  Token? endTagTable(EndTagToken token) {
    parser.parseError(
        token.span,
        'unexpected-table-element-end-tag-in-select-in-table',
        {'name': token.name});
    if (tree.elementInScope(token.name, variant: 'table')) {
      endTagOther(EndTagToken('select'));
      return token;
    }
    return null;
  }

  Token? endTagOther(EndTagToken token) {
    return parser._inSelectPhase.processEndTag(token);
  }
}

class InForeignContentPhase extends Phase {
  // TODO(jmesserly): this is sorted so we could binary search.
  static const breakoutElements = [
    'b',
    'big',
    'blockquote',
    'body',
    'br',
    'center',
    'code',
    'dd',
    'div',
    'dl',
    'dt',
    'em',
    'embed',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'head',
    'hr',
    'i',
    'img',
    'li',
    'listing',
    'menu',
    'meta',
    'nobr',
    'ol',
    'p',
    'pre',
    'ruby',
    's',
    'small',
    'span',
    'strike',
    'strong',
    'sub',
    'sup',
    'table',
    'tt',
    'u',
    'ul',
    'var'
  ];

  InForeignContentPhase(HtmlParser parser) : super(parser);

  void adjustSVGTagNames(StartTagToken token) {
    final replacements = const {
      'altglyph': 'altGlyph',
      'altglyphdef': 'altGlyphDef',
      'altglyphitem': 'altGlyphItem',
      'animatecolor': 'animateColor',
      'animatemotion': 'animateMotion',
      'animatetransform': 'animateTransform',
      'clippath': 'clipPath',
      'feblend': 'feBlend',
      'fecolormatrix': 'feColorMatrix',
      'fecomponenttransfer': 'feComponentTransfer',
      'fecomposite': 'feComposite',
      'feconvolvematrix': 'feConvolveMatrix',
      'fediffuselighting': 'feDiffuseLighting',
      'fedisplacementmap': 'feDisplacementMap',
      'fedistantlight': 'feDistantLight',
      'feflood': 'feFlood',
      'fefunca': 'feFuncA',
      'fefuncb': 'feFuncB',
      'fefuncg': 'feFuncG',
      'fefuncr': 'feFuncR',
      'fegaussianblur': 'feGaussianBlur',
      'feimage': 'feImage',
      'femerge': 'feMerge',
      'femergenode': 'feMergeNode',
      'femorphology': 'feMorphology',
      'feoffset': 'feOffset',
      'fepointlight': 'fePointLight',
      'fespecularlighting': 'feSpecularLighting',
      'fespotlight': 'feSpotLight',
      'fetile': 'feTile',
      'feturbulence': 'feTurbulence',
      'foreignobject': 'foreignObject',
      'glyphref': 'glyphRef',
      'lineargradient': 'linearGradient',
      'radialgradient': 'radialGradient',
      'textpath': 'textPath'
    };

    final replace = replacements[token.name];
    if (replace != null) {
      token.name = replace;
    }
  }

  @override
  Token? processCharacters(CharactersToken token) {
    if (token.data == '\u0000') {
      token.replaceData('\uFFFD');
    } else if (parser.framesetOK && !allWhitespace(token.data)) {
      parser.framesetOK = false;
    }
    return super.processCharacters(token);
  }

  @override
  Token? processStartTag(StartTagToken token) {
    final currentNode = tree.openElements.last;
    if (breakoutElements.contains(token.name) ||
        (token.name == 'font' &&
            (token.data.containsKey('color') ||
                token.data.containsKey('face') ||
                token.data.containsKey('size')))) {
      parser.parseError(token.span,
          'unexpected-html-element-in-foreign-content', {'name': token.name});
      while (tree.openElements.last.namespaceUri != tree.defaultNamespace &&
          !parser.isHTMLIntegrationPoint(tree.openElements.last) &&
          !parser.isMathMLTextIntegrationPoint(tree.openElements.last)) {
        tree.openElements.removeLast();
      }
      return token;
    } else {
      if (currentNode.namespaceUri == Namespaces.mathml) {
        parser.adjustMathMLAttributes(token);
      } else if (currentNode.namespaceUri == Namespaces.svg) {
        adjustSVGTagNames(token);
        parser.adjustSVGAttributes(token);
      }
      parser.adjustForeignAttributes(token);
      token.namespace = currentNode.namespaceUri;
      tree.insertElement(token);
      if (token.selfClosing) {
        tree.openElements.removeLast();
        token.selfClosingAcknowledged = true;
      }
      return null;
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    var nodeIndex = tree.openElements.length - 1;
    var node = tree.openElements.last;
    if (node.localName?.toAsciiLowerCase() != token.name) {
      parser.parseError(token.span, 'unexpected-end-tag', {'name': token.name});
    }

    Token? newToken;
    while (true) {
      if (node.localName?.toAsciiLowerCase() == token.name) {
        //XXX this isn't in the spec but it seems necessary
        if (parser.phase == parser._inTableTextPhase) {
          final inTableText = parser.phase as InTableTextPhase;
          inTableText.flushCharacters();
          parser.phase = inTableText.originalPhase!;
        }
        while (tree.openElements.removeLast() != node) {
          assert(tree.openElements.isNotEmpty);
        }
        newToken = null;
        break;
      }
      nodeIndex -= 1;

      node = tree.openElements[nodeIndex];
      if (node.namespaceUri != tree.defaultNamespace) {
        continue;
      } else {
        newToken = parser.phase.processEndTag(token);
        break;
      }
    }
    return newToken;
  }
}

class AfterBodyPhase extends Phase {
  AfterBodyPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    if (token.name == 'html') return startTagHtml(token);
    return startTagOther(token);
  }

  @override
  Token? processEndTag(EndTagToken token) {
    if (token.name == 'html') {
      endTagHtml(token);
      return null;
    }
    return endTagOther(token);
  }

  //Stop parsing
  @override
  bool processEOF() => false;

  @override
  Token? processComment(CommentToken token) {
    // This is needed because data is to be appended to the <html> element
    // here and not to whatever is currently open.
    tree.insertComment(token, tree.openElements[0]);
    return null;
  }

  @override
  Token processCharacters(CharactersToken token) {
    parser.parseError(token.span, 'unexpected-char-after-body');
    parser.phase = parser._inBodyPhase;
    return token;
  }

  @override
  Token? startTagHtml(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  Token startTagOther(StartTagToken token) {
    parser.parseError(
        token.span, 'unexpected-start-tag-after-body', {'name': token.name});
    parser.phase = parser._inBodyPhase;
    return token;
  }

  void endTagHtml(Token token) {
    for (var node in tree.openElements.reversed) {
      if (node.localName == 'html') {
        node.endSourceSpan = token.span;
        break;
      }
    }
    if (parser.innerHTMLMode) {
      parser.parseError(token.span, 'unexpected-end-tag-after-body-innerhtml');
    } else {
      parser.phase = parser._afterAfterBodyPhase;
    }
  }

  Token endTagOther(EndTagToken token) {
    parser.parseError(
        token.span, 'unexpected-end-tag-after-body', {'name': token.name});
    parser.phase = parser._inBodyPhase;
    return token;
  }
}

class InFramesetPhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///in-frameset
  InFramesetPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'frameset':
        startTagFrameset(token);
        return null;
      case 'frame':
        startTagFrame(token);
        return null;
      case 'noframes':
        return startTagNoframes(token);
      default:
        return startTagOther(token);
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'frameset':
        endTagFrameset(token);
        return null;
      default:
        endTagOther(token);
        return null;
    }
  }

  @override
  bool processEOF() {
    final last = tree.openElements.last;
    if (last.localName != 'html') {
      parser.parseError(last.sourceSpan, 'eof-in-frameset');
    } else {
      assert(parser.innerHTMLMode);
    }
    return false;
  }

  @override
  Token? processCharacters(CharactersToken token) {
    parser.parseError(token.span, 'unexpected-char-in-frameset');
    return null;
  }

  void startTagFrameset(StartTagToken token) {
    tree.insertElement(token);
  }

  void startTagFrame(StartTagToken token) {
    tree.insertElement(token);
    tree.openElements.removeLast();
  }

  Token? startTagNoframes(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  Token? startTagOther(StartTagToken token) {
    parser.parseError(
        token.span, 'unexpected-start-tag-in-frameset', {'name': token.name});
    return null;
  }

  void endTagFrameset(EndTagToken token) {
    if (tree.openElements.last.localName == 'html') {
      // innerHTML case
      parser.parseError(
          token.span, 'unexpected-frameset-in-frameset-innerhtml');
    } else {
      final node = tree.openElements.removeLast();
      node.endSourceSpan = token.span;
    }
    if (!parser.innerHTMLMode &&
        tree.openElements.last.localName != 'frameset') {
      // If we're not in innerHTML mode and the the current node is not a
      // "frameset" element (anymore) then switch.
      parser.phase = parser._afterFramesetPhase;
    }
  }

  void endTagOther(EndTagToken token) {
    parser.parseError(
        token.span, 'unexpected-end-tag-in-frameset', {'name': token.name});
  }
}

class AfterFramesetPhase extends Phase {
  // http://www.whatwg.org/specs/web-apps/current-work///after3
  AfterFramesetPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'noframes':
        return startTagNoframes(token);
      default:
        startTagOther(token);
        return null;
    }
  }

  @override
  Token? processEndTag(EndTagToken token) {
    switch (token.name) {
      case 'html':
        endTagHtml(token);
        return null;
      default:
        endTagOther(token);
        return null;
    }
  }

  // Stop parsing
  @override
  bool processEOF() => false;

  @override
  Token? processCharacters(CharactersToken token) {
    parser.parseError(token.span, 'unexpected-char-after-frameset');
    return null;
  }

  Token? startTagNoframes(StartTagToken token) {
    return parser._inHeadPhase.processStartTag(token);
  }

  void startTagOther(StartTagToken token) {
    parser.parseError(token.span, 'unexpected-start-tag-after-frameset',
        {'name': token.name});
  }

  void endTagHtml(EndTagToken token) {
    parser.phase = parser._afterAfterFramesetPhase;
  }

  void endTagOther(EndTagToken token) {
    parser.parseError(
        token.span, 'unexpected-end-tag-after-frameset', {'name': token.name});
  }
}

class AfterAfterBodyPhase extends Phase {
  AfterAfterBodyPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    if (token.name == 'html') return startTagHtml(token);
    return startTagOther(token);
  }

  @override
  bool processEOF() => false;

  @override
  Token? processComment(CommentToken token) {
    tree.insertComment(token, tree.document);
    return null;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    return parser._inBodyPhase.processSpaceCharacters(token);
  }

  @override
  Token processCharacters(CharactersToken token) {
    parser.parseError(token.span, 'expected-eof-but-got-char');
    parser.phase = parser._inBodyPhase;
    return token;
  }

  @override
  Token? startTagHtml(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  Token startTagOther(StartTagToken token) {
    parser.parseError(
        token.span, 'expected-eof-but-got-start-tag', {'name': token.name});
    parser.phase = parser._inBodyPhase;
    return token;
  }

  @override
  Token processEndTag(EndTagToken token) {
    parser.parseError(
        token.span, 'expected-eof-but-got-end-tag', {'name': token.name});
    parser.phase = parser._inBodyPhase;
    return token;
  }
}

class AfterAfterFramesetPhase extends Phase {
  AfterAfterFramesetPhase(HtmlParser parser) : super(parser);

  @override
  Token? processStartTag(StartTagToken token) {
    switch (token.name) {
      case 'html':
        return startTagHtml(token);
      case 'noframes':
        return startTagNoFrames(token);
      default:
        startTagOther(token);
        return null;
    }
  }

  @override
  bool processEOF() => false;

  @override
  Token? processComment(CommentToken token) {
    tree.insertComment(token, tree.document);
    return null;
  }

  @override
  Token? processSpaceCharacters(SpaceCharactersToken token) {
    return parser._inBodyPhase.processSpaceCharacters(token);
  }

  @override
  Token? processCharacters(CharactersToken token) {
    parser.parseError(token.span, 'expected-eof-but-got-char');
    return null;
  }

  @override
  Token? startTagHtml(StartTagToken token) {
    return parser._inBodyPhase.processStartTag(token);
  }

  Token? startTagNoFrames(StartTagToken token) {
    return parser._inHeadPhase.processStartTag(token);
  }

  void startTagOther(StartTagToken token) {
    parser.parseError(
        token.span, 'expected-eof-but-got-start-tag', {'name': token.name});
  }

  @override
  Token? processEndTag(EndTagToken token) {
    parser.parseError(
        token.span, 'expected-eof-but-got-end-tag', {'name': token.name});
    return null;
  }
}

/// Error in parsed document.
class ParseError implements SourceSpanException {
  final String errorCode;
  @override
  final SourceSpan? span;
  final Map? data;

  ParseError(this.errorCode, this.span, this.data);

  int get line => span!.start.line;

  int get column => span!.start.column;

  /// Returns the human readable error message for this error.
  ///
  /// Use [SourceSpan.message] or the [toString] from the [span] field to get a
  /// message including span information
  @override
  String get message => formatStr(errorMessages[errorCode]!, data);

  @override
  String toString({color}) {
    final res = span!.message(message, color: color);
    return span!.sourceUrl == null ? 'ParserError on $res' : 'On $res';
  }
}

/// Convenience function to get the pair of namespace and localName.
Pair<String, String?> getElementNameTuple(Element e) {
  final ns = e.namespaceUri ?? Namespaces.html;
  return Pair(ns, e.localName);
}
