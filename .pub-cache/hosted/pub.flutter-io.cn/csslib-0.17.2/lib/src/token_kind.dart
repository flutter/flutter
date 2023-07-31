// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../parser.dart';

// TODO(terry): Need to be consistent with tokens either they're ASCII tokens
//              e.g., ASTERISK or they're CSS e.g., PSEUDO, COMBINATOR_*.
class TokenKind {
  // Common shared tokens used in TokenizerBase.
  static const int UNUSED = 0; // Unused place holder...
  static const int END_OF_FILE = 1; // EOF
  static const int LPAREN = 2; // (
  static const int RPAREN = 3; // )
  static const int LBRACK = 4; // [
  static const int RBRACK = 5; // ]
  static const int LBRACE = 6; // {
  static const int RBRACE = 7; // }
  static const int DOT = 8; // .
  static const int SEMICOLON = 9; // ;

  // Unique tokens for CSS.
  static const int AT = 10; // @
  static const int HASH = 11; // #
  static const int PLUS = 12; // +
  static const int GREATER = 13; // >
  static const int TILDE = 14; // ~
  static const int ASTERISK = 15; // *
  static const int NAMESPACE = 16; // |
  static const int COLON = 17; // :
  static const int PRIVATE_NAME = 18; // _ prefix private class or id
  static const int COMMA = 19; // ,
  static const int SPACE = 20;
  static const int TAB = 21; // /t
  static const int NEWLINE = 22; // /n
  static const int RETURN = 23; // /r
  static const int PERCENT = 24; // %
  static const int SINGLE_QUOTE = 25; // '
  static const int DOUBLE_QUOTE = 26; // "
  static const int SLASH = 27; // /
  static const int EQUALS = 28; // =
  static const int CARET = 30; // ^
  static const int DOLLAR = 31; // $
  static const int LESS = 32; // <
  static const int BANG = 33; // !
  static const int MINUS = 34; // -
  static const int BACKSLASH = 35; // \
  static const int AMPERSAND = 36; // &

  // WARNING: Tokens from this point and above must have the corresponding ASCII
  //          character in the TokenChar list at the bottom of this file.  The
  //          order of the above tokens should be the same order as TokenChar.

  /// [TokenKind] representing integer tokens.
  static const int INTEGER = 60;

  /// [TokenKind] representing hex integer tokens.
  static const int HEX_INTEGER = 61;

  /// [TokenKind] representing double tokens.
  static const int DOUBLE = 62;

  /// [TokenKind] representing whitespace tokens.
  static const int WHITESPACE = 63;

  /// [TokenKind] representing comment tokens.
  static const int COMMENT = 64;

  /// [TokenKind] representing error tokens.
  static const int ERROR = 65;

  /// [TokenKind] representing incomplete string tokens.
  static const int INCOMPLETE_STRING = 66;

  /// [TokenKind] representing incomplete comment tokens.
  static const int INCOMPLETE_COMMENT = 67;

  static const int VAR_DEFINITION = 400; // var-NNN-NNN
  static const int VAR_USAGE = 401; // var(NNN-NNN [,default])

  // Synthesized Tokens (no character associated with TOKEN).
  static const int STRING = 500;
  static const int STRING_PART = 501;
  static const int NUMBER = 502;
  static const int HEX_NUMBER = 503;
  static const int HTML_COMMENT = 504; // <!--
  static const int IMPORTANT = 505; // !important
  static const int CDATA_START = 506; // <![CDATA[
  static const int CDATA_END = 507; // ]]>
  // U+uNumber[-U+uNumber]
  // uNumber = 0..10FFFF | ?[?]*
  static const int UNICODE_RANGE = 508;
  static const int HEX_RANGE = 509; // ? in the hex range
  static const int IDENTIFIER = 511;

  // Uniquely synthesized tokens for CSS.
  static const int SELECTOR_EXPRESSION = 512;
  static const int COMBINATOR_NONE = 513;
  static const int COMBINATOR_DESCENDANT = 514; // Space combinator
  static const int COMBINATOR_PLUS = 515; // + combinator
  static const int COMBINATOR_GREATER = 516; // > combinator
  static const int COMBINATOR_TILDE = 517; // ~ combinator

  static const int UNARY_OP_NONE = 518; // No unary operator present.

  // Attribute match types:
  static const int INCLUDES = 530; // '~='
  static const int DASH_MATCH = 531; // '|='
  static const int PREFIX_MATCH = 532; // '^='
  static const int SUFFIX_MATCH = 533; // '$='
  static const int SUBSTRING_MATCH = 534; // '*='
  static const int NO_MATCH = 535; // No operator.

  // Unit types:
  static const int UNIT_EM = 600;
  static const int UNIT_EX = 601;
  static const int UNIT_LENGTH_PX = 602;
  static const int UNIT_LENGTH_CM = 603;
  static const int UNIT_LENGTH_MM = 604;
  static const int UNIT_LENGTH_IN = 605;
  static const int UNIT_LENGTH_PT = 606;
  static const int UNIT_LENGTH_PC = 607;
  static const int UNIT_ANGLE_DEG = 608;
  static const int UNIT_ANGLE_RAD = 609;
  static const int UNIT_ANGLE_GRAD = 610;
  static const int UNIT_ANGLE_TURN = 611;
  static const int UNIT_TIME_MS = 612;
  static const int UNIT_TIME_S = 613;
  static const int UNIT_FREQ_HZ = 614;
  static const int UNIT_FREQ_KHZ = 615;
  static const int UNIT_PERCENT = 616;
  static const int UNIT_FRACTION = 617;
  static const int UNIT_RESOLUTION_DPI = 618;
  static const int UNIT_RESOLUTION_DPCM = 619;
  static const int UNIT_RESOLUTION_DPPX = 620;
  static const int UNIT_CH = 621; // Measure of "0" U+0030 glyph.
  static const int UNIT_REM = 622; // computed value ‘font-size’ on root elem.
  static const int UNIT_VIEWPORT_VW = 623;
  static const int UNIT_VIEWPORT_VH = 624;
  static const int UNIT_VIEWPORT_VMIN = 625;
  static const int UNIT_VIEWPORT_VMAX = 626;

  // Directives (@nnnn)
  static const int DIRECTIVE_NONE = 640;
  static const int DIRECTIVE_IMPORT = 641;
  static const int DIRECTIVE_MEDIA = 642;
  static const int DIRECTIVE_PAGE = 643;
  static const int DIRECTIVE_CHARSET = 644;
  static const int DIRECTIVE_STYLET = 645;
  static const int DIRECTIVE_KEYFRAMES = 646;
  static const int DIRECTIVE_WEB_KIT_KEYFRAMES = 647;
  static const int DIRECTIVE_MOZ_KEYFRAMES = 648;
  static const int DIRECTIVE_MS_KEYFRAMES = 649;
  static const int DIRECTIVE_O_KEYFRAMES = 650;
  static const int DIRECTIVE_FONTFACE = 651;
  static const int DIRECTIVE_NAMESPACE = 652;
  static const int DIRECTIVE_HOST = 653;
  static const int DIRECTIVE_MIXIN = 654;
  static const int DIRECTIVE_INCLUDE = 655;
  static const int DIRECTIVE_CONTENT = 656;
  static const int DIRECTIVE_EXTEND = 657;
  static const int DIRECTIVE_MOZ_DOCUMENT = 658;
  static const int DIRECTIVE_SUPPORTS = 659;
  static const int DIRECTIVE_VIEWPORT = 660;
  static const int DIRECTIVE_MS_VIEWPORT = 661;

  // Media query operators
  static const int MEDIA_OP_ONLY = 665; // Unary.
  static const int MEDIA_OP_NOT = 666; // Unary.
  static const int MEDIA_OP_AND = 667; // Binary.

  // Directives inside of a @page (margin sym).
  static const int MARGIN_DIRECTIVE_TOPLEFTCORNER = 670;
  static const int MARGIN_DIRECTIVE_TOPLEFT = 671;
  static const int MARGIN_DIRECTIVE_TOPCENTER = 672;
  static const int MARGIN_DIRECTIVE_TOPRIGHT = 673;
  static const int MARGIN_DIRECTIVE_TOPRIGHTCORNER = 674;
  static const int MARGIN_DIRECTIVE_BOTTOMLEFTCORNER = 675;
  static const int MARGIN_DIRECTIVE_BOTTOMLEFT = 676;
  static const int MARGIN_DIRECTIVE_BOTTOMCENTER = 677;
  static const int MARGIN_DIRECTIVE_BOTTOMRIGHT = 678;
  static const int MARGIN_DIRECTIVE_BOTTOMRIGHTCORNER = 679;
  static const int MARGIN_DIRECTIVE_LEFTTOP = 680;
  static const int MARGIN_DIRECTIVE_LEFTMIDDLE = 681;
  static const int MARGIN_DIRECTIVE_LEFTBOTTOM = 682;
  static const int MARGIN_DIRECTIVE_RIGHTTOP = 683;
  static const int MARGIN_DIRECTIVE_RIGHTMIDDLE = 684;
  static const int MARGIN_DIRECTIVE_RIGHTBOTTOM = 685;

  // Simple selector type.
  static const int CLASS_NAME = 700; // .class
  static const int ELEMENT_NAME = 701; // tagName
  static const int HASH_NAME = 702; // #elementId
  static const int ATTRIBUTE_NAME = 703; // [attrib]
  static const int PSEUDO_ELEMENT_NAME = 704; // ::pseudoElement
  static const int PSEUDO_CLASS_NAME = 705; // :pseudoClass
  static const int NEGATION = 706; // NOT

  static const List<Map<String, dynamic>> _DIRECTIVES = [
    {'type': TokenKind.DIRECTIVE_IMPORT, 'value': 'import'},
    {'type': TokenKind.DIRECTIVE_MEDIA, 'value': 'media'},
    {'type': TokenKind.DIRECTIVE_PAGE, 'value': 'page'},
    {'type': TokenKind.DIRECTIVE_CHARSET, 'value': 'charset'},
    {'type': TokenKind.DIRECTIVE_STYLET, 'value': 'stylet'},
    {'type': TokenKind.DIRECTIVE_KEYFRAMES, 'value': 'keyframes'},
    {
      'type': TokenKind.DIRECTIVE_WEB_KIT_KEYFRAMES,
      'value': '-webkit-keyframes'
    },
    {'type': TokenKind.DIRECTIVE_MOZ_KEYFRAMES, 'value': '-moz-keyframes'},
    {'type': TokenKind.DIRECTIVE_MS_KEYFRAMES, 'value': '-ms-keyframes'},
    {'type': TokenKind.DIRECTIVE_O_KEYFRAMES, 'value': '-o-keyframes'},
    {'type': TokenKind.DIRECTIVE_FONTFACE, 'value': 'font-face'},
    {'type': TokenKind.DIRECTIVE_NAMESPACE, 'value': 'namespace'},
    {'type': TokenKind.DIRECTIVE_HOST, 'value': 'host'},
    {'type': TokenKind.DIRECTIVE_MIXIN, 'value': 'mixin'},
    {'type': TokenKind.DIRECTIVE_INCLUDE, 'value': 'include'},
    {'type': TokenKind.DIRECTIVE_CONTENT, 'value': 'content'},
    {'type': TokenKind.DIRECTIVE_EXTEND, 'value': 'extend'},
    {'type': TokenKind.DIRECTIVE_MOZ_DOCUMENT, 'value': '-moz-document'},
    {'type': TokenKind.DIRECTIVE_SUPPORTS, 'value': 'supports'},
    {'type': TokenKind.DIRECTIVE_VIEWPORT, 'value': 'viewport'},
    {'type': TokenKind.DIRECTIVE_MS_VIEWPORT, 'value': '-ms-viewport'},
  ];

  static const List<Map<String, dynamic>> MEDIA_OPERATORS = [
    {'type': TokenKind.MEDIA_OP_ONLY, 'value': 'only'},
    {'type': TokenKind.MEDIA_OP_NOT, 'value': 'not'},
    {'type': TokenKind.MEDIA_OP_AND, 'value': 'and'},
  ];

  static const List<Map<String, dynamic>> MARGIN_DIRECTIVES = [
    {
      'type': TokenKind.MARGIN_DIRECTIVE_TOPLEFTCORNER,
      'value': 'top-left-corner'
    },
    {'type': TokenKind.MARGIN_DIRECTIVE_TOPLEFT, 'value': 'top-left'},
    {'type': TokenKind.MARGIN_DIRECTIVE_TOPCENTER, 'value': 'top-center'},
    {'type': TokenKind.MARGIN_DIRECTIVE_TOPRIGHT, 'value': 'top-right'},
    {
      'type': TokenKind.MARGIN_DIRECTIVE_TOPRIGHTCORNER,
      'value': 'top-right-corner'
    },
    {
      'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMLEFTCORNER,
      'value': 'bottom-left-corner'
    },
    {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMLEFT, 'value': 'bottom-left'},
    {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMCENTER, 'value': 'bottom-center'},
    {'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMRIGHT, 'value': 'bottom-right'},
    {
      'type': TokenKind.MARGIN_DIRECTIVE_BOTTOMRIGHTCORNER,
      'value': 'bottom-right-corner'
    },
    {'type': TokenKind.MARGIN_DIRECTIVE_LEFTTOP, 'value': 'left-top'},
    {'type': TokenKind.MARGIN_DIRECTIVE_LEFTMIDDLE, 'value': 'left-middle'},
    {'type': TokenKind.MARGIN_DIRECTIVE_LEFTBOTTOM, 'value': 'right-bottom'},
    {'type': TokenKind.MARGIN_DIRECTIVE_RIGHTTOP, 'value': 'right-top'},
    {'type': TokenKind.MARGIN_DIRECTIVE_RIGHTMIDDLE, 'value': 'right-middle'},
    {'type': TokenKind.MARGIN_DIRECTIVE_RIGHTBOTTOM, 'value': 'right-bottom'},
  ];

  static const List<Map<String, dynamic>> _UNITS = [
    {'unit': TokenKind.UNIT_EM, 'value': 'em'},
    {'unit': TokenKind.UNIT_EX, 'value': 'ex'},
    {'unit': TokenKind.UNIT_LENGTH_PX, 'value': 'px'},
    {'unit': TokenKind.UNIT_LENGTH_CM, 'value': 'cm'},
    {'unit': TokenKind.UNIT_LENGTH_MM, 'value': 'mm'},
    {'unit': TokenKind.UNIT_LENGTH_IN, 'value': 'in'},
    {'unit': TokenKind.UNIT_LENGTH_PT, 'value': 'pt'},
    {'unit': TokenKind.UNIT_LENGTH_PC, 'value': 'pc'},
    {'unit': TokenKind.UNIT_ANGLE_DEG, 'value': 'deg'},
    {'unit': TokenKind.UNIT_ANGLE_RAD, 'value': 'rad'},
    {'unit': TokenKind.UNIT_ANGLE_GRAD, 'value': 'grad'},
    {'unit': TokenKind.UNIT_ANGLE_TURN, 'value': 'turn'},
    {'unit': TokenKind.UNIT_TIME_MS, 'value': 'ms'},
    {'unit': TokenKind.UNIT_TIME_S, 'value': 's'},
    {'unit': TokenKind.UNIT_FREQ_HZ, 'value': 'hz'},
    {'unit': TokenKind.UNIT_FREQ_KHZ, 'value': 'khz'},
    {'unit': TokenKind.UNIT_FRACTION, 'value': 'fr'},
    {'unit': TokenKind.UNIT_RESOLUTION_DPI, 'value': 'dpi'},
    {'unit': TokenKind.UNIT_RESOLUTION_DPCM, 'value': 'dpcm'},
    {'unit': TokenKind.UNIT_RESOLUTION_DPPX, 'value': 'dppx'},
    {'unit': TokenKind.UNIT_CH, 'value': 'ch'},
    {'unit': TokenKind.UNIT_REM, 'value': 'rem'},
    {'unit': TokenKind.UNIT_VIEWPORT_VW, 'value': 'vw'},
    {'unit': TokenKind.UNIT_VIEWPORT_VH, 'value': 'vh'},
    {'unit': TokenKind.UNIT_VIEWPORT_VMIN, 'value': 'vmin'},
    {'unit': TokenKind.UNIT_VIEWPORT_VMAX, 'value': 'vmax'},
  ];

  // Some more constants:
  static const int ASCII_UPPER_A = 65; // ASCII value for uppercase A
  static const int ASCII_UPPER_Z = 90; // ASCII value for uppercase Z

  // Extended color keywords:
  static const List<Map> _EXTENDED_COLOR_NAMES = [
    {'name': 'aliceblue', 'value': 0xF08FF},
    {'name': 'antiquewhite', 'value': 0xFAEBD7},
    {'name': 'aqua', 'value': 0x00FFFF},
    {'name': 'aquamarine', 'value': 0x7FFFD4},
    {'name': 'azure', 'value': 0xF0FFFF},
    {'name': 'beige', 'value': 0xF5F5DC},
    {'name': 'bisque', 'value': 0xFFE4C4},
    {'name': 'black', 'value': 0x000000},
    {'name': 'blanchedalmond', 'value': 0xFFEBCD},
    {'name': 'blue', 'value': 0x0000FF},
    {'name': 'blueviolet', 'value': 0x8A2BE2},
    {'name': 'brown', 'value': 0xA52A2A},
    {'name': 'burlywood', 'value': 0xDEB887},
    {'name': 'cadetblue', 'value': 0x5F9EA0},
    {'name': 'chartreuse', 'value': 0x7FFF00},
    {'name': 'chocolate', 'value': 0xD2691E},
    {'name': 'coral', 'value': 0xFF7F50},
    {'name': 'cornflowerblue', 'value': 0x6495ED},
    {'name': 'cornsilk', 'value': 0xFFF8DC},
    {'name': 'crimson', 'value': 0xDC143C},
    {'name': 'cyan', 'value': 0x00FFFF},
    {'name': 'darkblue', 'value': 0x00008B},
    {'name': 'darkcyan', 'value': 0x008B8B},
    {'name': 'darkgoldenrod', 'value': 0xB8860B},
    {'name': 'darkgray', 'value': 0xA9A9A9},
    {'name': 'darkgreen', 'value': 0x006400},
    {'name': 'darkgrey', 'value': 0xA9A9A9},
    {'name': 'darkkhaki', 'value': 0xBDB76B},
    {'name': 'darkmagenta', 'value': 0x8B008B},
    {'name': 'darkolivegreen', 'value': 0x556B2F},
    {'name': 'darkorange', 'value': 0xFF8C00},
    {'name': 'darkorchid', 'value': 0x9932CC},
    {'name': 'darkred', 'value': 0x8B0000},
    {'name': 'darksalmon', 'value': 0xE9967A},
    {'name': 'darkseagreen', 'value': 0x8FBC8F},
    {'name': 'darkslateblue', 'value': 0x483D8B},
    {'name': 'darkslategray', 'value': 0x2F4F4F},
    {'name': 'darkslategrey', 'value': 0x2F4F4F},
    {'name': 'darkturquoise', 'value': 0x00CED1},
    {'name': 'darkviolet', 'value': 0x9400D3},
    {'name': 'deeppink', 'value': 0xFF1493},
    {'name': 'deepskyblue', 'value': 0x00BFFF},
    {'name': 'dimgray', 'value': 0x696969},
    {'name': 'dimgrey', 'value': 0x696969},
    {'name': 'dodgerblue', 'value': 0x1E90FF},
    {'name': 'firebrick', 'value': 0xB22222},
    {'name': 'floralwhite', 'value': 0xFFFAF0},
    {'name': 'forestgreen', 'value': 0x228B22},
    {'name': 'fuchsia', 'value': 0xFF00FF},
    {'name': 'gainsboro', 'value': 0xDCDCDC},
    {'name': 'ghostwhite', 'value': 0xF8F8FF},
    {'name': 'gold', 'value': 0xFFD700},
    {'name': 'goldenrod', 'value': 0xDAA520},
    {'name': 'gray', 'value': 0x808080},
    {'name': 'green', 'value': 0x008000},
    {'name': 'greenyellow', 'value': 0xADFF2F},
    {'name': 'grey', 'value': 0x808080},
    {'name': 'honeydew', 'value': 0xF0FFF0},
    {'name': 'hotpink', 'value': 0xFF69B4},
    {'name': 'indianred', 'value': 0xCD5C5C},
    {'name': 'indigo', 'value': 0x4B0082},
    {'name': 'ivory', 'value': 0xFFFFF0},
    {'name': 'khaki', 'value': 0xF0E68C},
    {'name': 'lavender', 'value': 0xE6E6FA},
    {'name': 'lavenderblush', 'value': 0xFFF0F5},
    {'name': 'lawngreen', 'value': 0x7CFC00},
    {'name': 'lemonchiffon', 'value': 0xFFFACD},
    {'name': 'lightblue', 'value': 0xADD8E6},
    {'name': 'lightcoral', 'value': 0xF08080},
    {'name': 'lightcyan', 'value': 0xE0FFFF},
    {'name': 'lightgoldenrodyellow', 'value': 0xFAFAD2},
    {'name': 'lightgray', 'value': 0xD3D3D3},
    {'name': 'lightgreen', 'value': 0x90EE90},
    {'name': 'lightgrey', 'value': 0xD3D3D3},
    {'name': 'lightpink', 'value': 0xFFB6C1},
    {'name': 'lightsalmon', 'value': 0xFFA07A},
    {'name': 'lightseagreen', 'value': 0x20B2AA},
    {'name': 'lightskyblue', 'value': 0x87CEFA},
    {'name': 'lightslategray', 'value': 0x778899},
    {'name': 'lightslategrey', 'value': 0x778899},
    {'name': 'lightsteelblue', 'value': 0xB0C4DE},
    {'name': 'lightyellow', 'value': 0xFFFFE0},
    {'name': 'lime', 'value': 0x00FF00},
    {'name': 'limegreen', 'value': 0x32CD32},
    {'name': 'linen', 'value': 0xFAF0E6},
    {'name': 'magenta', 'value': 0xFF00FF},
    {'name': 'maroon', 'value': 0x800000},
    {'name': 'mediumaquamarine', 'value': 0x66CDAA},
    {'name': 'mediumblue', 'value': 0x0000CD},
    {'name': 'mediumorchid', 'value': 0xBA55D3},
    {'name': 'mediumpurple', 'value': 0x9370DB},
    {'name': 'mediumseagreen', 'value': 0x3CB371},
    {'name': 'mediumslateblue', 'value': 0x7B68EE},
    {'name': 'mediumspringgreen', 'value': 0x00FA9A},
    {'name': 'mediumturquoise', 'value': 0x48D1CC},
    {'name': 'mediumvioletred', 'value': 0xC71585},
    {'name': 'midnightblue', 'value': 0x191970},
    {'name': 'mintcream', 'value': 0xF5FFFA},
    {'name': 'mistyrose', 'value': 0xFFE4E1},
    {'name': 'moccasin', 'value': 0xFFE4B5},
    {'name': 'navajowhite', 'value': 0xFFDEAD},
    {'name': 'navy', 'value': 0x000080},
    {'name': 'oldlace', 'value': 0xFDF5E6},
    {'name': 'olive', 'value': 0x808000},
    {'name': 'olivedrab', 'value': 0x6B8E23},
    {'name': 'orange', 'value': 0xFFA500},
    {'name': 'orangered', 'value': 0xFF4500},
    {'name': 'orchid', 'value': 0xDA70D6},
    {'name': 'palegoldenrod', 'value': 0xEEE8AA},
    {'name': 'palegreen', 'value': 0x98FB98},
    {'name': 'paleturquoise', 'value': 0xAFEEEE},
    {'name': 'palevioletred', 'value': 0xDB7093},
    {'name': 'papayawhip', 'value': 0xFFEFD5},
    {'name': 'peachpuff', 'value': 0xFFDAB9},
    {'name': 'peru', 'value': 0xCD853F},
    {'name': 'pink', 'value': 0xFFC0CB},
    {'name': 'plum', 'value': 0xDDA0DD},
    {'name': 'powderblue', 'value': 0xB0E0E6},
    {'name': 'purple', 'value': 0x800080},
    {'name': 'red', 'value': 0xFF0000},
    {'name': 'rosybrown', 'value': 0xBC8F8F},
    {'name': 'royalblue', 'value': 0x4169E1},
    {'name': 'saddlebrown', 'value': 0x8B4513},
    {'name': 'salmon', 'value': 0xFA8072},
    {'name': 'sandybrown', 'value': 0xF4A460},
    {'name': 'seagreen', 'value': 0x2E8B57},
    {'name': 'seashell', 'value': 0xFFF5EE},
    {'name': 'sienna', 'value': 0xA0522D},
    {'name': 'silver', 'value': 0xC0C0C0},
    {'name': 'skyblue', 'value': 0x87CEEB},
    {'name': 'slateblue', 'value': 0x6A5ACD},
    {'name': 'slategray', 'value': 0x708090},
    {'name': 'slategrey', 'value': 0x708090},
    {'name': 'snow', 'value': 0xFFFAFA},
    {'name': 'springgreen', 'value': 0x00FF7F},
    {'name': 'steelblue', 'value': 0x4682B4},
    {'name': 'tan', 'value': 0xD2B48C},
    {'name': 'teal', 'value': 0x008080},
    {'name': 'thistle', 'value': 0xD8BFD8},
    {'name': 'tomato', 'value': 0xFF6347},
    {'name': 'turquoise', 'value': 0x40E0D0},
    {'name': 'violet', 'value': 0xEE82EE},
    {'name': 'wheat', 'value': 0xF5DEB3},
    {'name': 'white', 'value': 0xFFFFFF},
    {'name': 'whitesmoke', 'value': 0xF5F5F5},
    {'name': 'yellow', 'value': 0xFFFF00},
    {'name': 'yellowgreen', 'value': 0x9ACD32},
  ];

  // TODO(terry): Should used Dart mirroring for parameter values and types
  //              especially for enumeration (e.g., counter's second parameter
  //              is list-style-type which is an enumerated list for ordering
  //              of a list 'circle', 'decimal', 'lower-roman', 'square', etc.
  //              see http://www.w3schools.com/cssref/pr_list-style-type.asp
  //              for list of possible values.

  /// Check if name is a pre-defined CSS name.  Used by error handler to report
  /// if name is unknown or used improperly.
  static bool isPredefinedName(String name) {
    var nameLen = name.length;
    // TODO(terry): Add more pre-defined names (hidden, bolder, inherit, etc.).
    if (matchUnits(name, 0, nameLen) == -1 ||
        matchDirectives(name, 0, nameLen) == -1 ||
        matchMarginDirectives(name, 0, nameLen) == -1 ||
        matchColorName(name) == null) {
      return false;
    }

    return true;
  }

  /// Return the token that matches the unit ident found.
  static int matchList(Iterable<Map<String, dynamic>> identList,
      String tokenField, String text, int offset, int length) {
    for (final entry in identList) {
      final ident = entry['value'] as String;

      if (length == ident.length) {
        var idx = offset;
        var match = true;
        for (var i = 0; i < ident.length; i++) {
          var identChar = ident.codeUnitAt(i);
          var char = text.codeUnitAt(idx++);
          // Compare lowercase to lowercase then check if char is uppercase.
          match = match &&
              (char == identChar ||
                  ((char >= ASCII_UPPER_A && char <= ASCII_UPPER_Z) &&
                      (char + 32) == identChar));
          if (!match) {
            break;
          }
        }

        if (match) {
          // Completely matched; return the token for this unit.
          return entry[tokenField] as int;
        }
      }
    }

    return -1; // Not a unit token.
  }

  /// Return the token that matches the unit ident found.
  static int matchUnits(String text, int offset, int length) {
    return matchList(_UNITS, 'unit', text, offset, length);
  }

  /// Return the token that matches the directive name found.
  static int matchDirectives(String text, int offset, int length) {
    return matchList(_DIRECTIVES, 'type', text, offset, length);
  }

  /// Return the token that matches the margin directive name found.
  static int matchMarginDirectives(String text, int offset, int length) {
    return matchList(MARGIN_DIRECTIVES, 'type', text, offset, length);
  }

  /// Return the token that matches the media operator found.
  static int matchMediaOperator(String text, int offset, int length) {
    return matchList(MEDIA_OPERATORS, 'type', text, offset, length);
  }

  static String? idToValue(Iterable<Object?> identList, int tokenId) {
    for (var entry in identList) {
      entry as Map<String, Object?>;
      if (tokenId == entry['type']) {
        return entry['value'] as String?;
      }
    }

    return null;
  }

  /// Return the unit token as its pretty name.
  static String? unitToString(int unitTokenToFind) {
    if (unitTokenToFind == TokenKind.PERCENT) {
      return '%';
    } else {
      for (final entry in _UNITS) {
        final unit = entry['unit'] as int;
        if (unit == unitTokenToFind) {
          return entry['value'] as String?;
        }
      }
    }

    return '<BAD UNIT>'; // Not a unit token.
  }

  /// Match color name, case insensitive match and return the associated color
  /// entry from _EXTENDED_COLOR_NAMES list, return [:null:] if not found.
  static Map? matchColorName(String text) {
    var name = text.toLowerCase();
    for (var color in _EXTENDED_COLOR_NAMES) {
      if (color['name'] == name) return color;
    }
    return null;
  }

  /// Return RGB value as [int] from a color entry in _EXTENDED_COLOR_NAMES.
  static int colorValue(Map entry) {
    return entry['value'] as int;
  }

  static String? hexToColorName(hexValue) {
    for (final entry in _EXTENDED_COLOR_NAMES) {
      if (entry['value'] == hexValue) {
        return entry['name'] as String?;
      }
    }

    return null;
  }

  static String decimalToHex(int number, [int minDigits = 1]) {
    final _HEX_DIGITS = '0123456789abcdef';

    var result = <String>[];

    var dividend = number >> 4;
    var remain = number % 16;
    result.add(_HEX_DIGITS[remain]);
    while (dividend != 0) {
      remain = dividend % 16;
      dividend >>= 4;
      result.add(_HEX_DIGITS[remain]);
    }

    var invertResult = StringBuffer();
    var paddings = minDigits - result.length;
    while (paddings-- > 0) {
      invertResult.write('0');
    }
    for (var i = result.length - 1; i >= 0; i--) {
      invertResult.write(result[i]);
    }

    return invertResult.toString();
  }

  static String kindToString(int kind) {
    switch (kind) {
      case TokenKind.UNUSED:
        return 'ERROR';
      case TokenKind.END_OF_FILE:
        return 'end of file';
      case TokenKind.LPAREN:
        return '(';
      case TokenKind.RPAREN:
        return ')';
      case TokenKind.LBRACK:
        return '[';
      case TokenKind.RBRACK:
        return ']';
      case TokenKind.LBRACE:
        return '{';
      case TokenKind.RBRACE:
        return '}';
      case TokenKind.DOT:
        return '.';
      case TokenKind.SEMICOLON:
        return ';';
      case TokenKind.AT:
        return '@';
      case TokenKind.HASH:
        return '#';
      case TokenKind.PLUS:
        return '+';
      case TokenKind.GREATER:
        return '>';
      case TokenKind.TILDE:
        return '~';
      case TokenKind.ASTERISK:
        return '*';
      case TokenKind.NAMESPACE:
        return '|';
      case TokenKind.COLON:
        return ':';
      case TokenKind.PRIVATE_NAME:
        return '_';
      case TokenKind.COMMA:
        return ',';
      case TokenKind.SPACE:
        return ' ';
      case TokenKind.TAB:
        return '\t';
      case TokenKind.NEWLINE:
        return '\n';
      case TokenKind.RETURN:
        return '\r';
      case TokenKind.PERCENT:
        return '%';
      case TokenKind.SINGLE_QUOTE:
        return "'";
      case TokenKind.DOUBLE_QUOTE:
        return '\"';
      case TokenKind.SLASH:
        return '/';
      case TokenKind.EQUALS:
        return '=';
      case TokenKind.CARET:
        return '^';
      case TokenKind.DOLLAR:
        return '\$';
      case TokenKind.LESS:
        return '<';
      case TokenKind.BANG:
        return '!';
      case TokenKind.MINUS:
        return '-';
      case TokenKind.BACKSLASH:
        return '\\';
      default:
        throw 'Unknown TOKEN';
    }
  }

  static bool isKindIdentifier(int kind) {
    switch (kind) {
      // Synthesized tokens.
      case TokenKind.DIRECTIVE_IMPORT:
      case TokenKind.DIRECTIVE_MEDIA:
      case TokenKind.DIRECTIVE_PAGE:
      case TokenKind.DIRECTIVE_CHARSET:
      case TokenKind.DIRECTIVE_STYLET:
      case TokenKind.DIRECTIVE_KEYFRAMES:
      case TokenKind.DIRECTIVE_WEB_KIT_KEYFRAMES:
      case TokenKind.DIRECTIVE_MOZ_KEYFRAMES:
      case TokenKind.DIRECTIVE_MS_KEYFRAMES:
      case TokenKind.DIRECTIVE_O_KEYFRAMES:
      case TokenKind.DIRECTIVE_FONTFACE:
      case TokenKind.DIRECTIVE_NAMESPACE:
      case TokenKind.DIRECTIVE_HOST:
      case TokenKind.DIRECTIVE_MIXIN:
      case TokenKind.DIRECTIVE_INCLUDE:
      case TokenKind.DIRECTIVE_CONTENT:
      case TokenKind.UNIT_EM:
      case TokenKind.UNIT_EX:
      case TokenKind.UNIT_LENGTH_PX:
      case TokenKind.UNIT_LENGTH_CM:
      case TokenKind.UNIT_LENGTH_MM:
      case TokenKind.UNIT_LENGTH_IN:
      case TokenKind.UNIT_LENGTH_PT:
      case TokenKind.UNIT_LENGTH_PC:
      case TokenKind.UNIT_ANGLE_DEG:
      case TokenKind.UNIT_ANGLE_RAD:
      case TokenKind.UNIT_ANGLE_GRAD:
      case TokenKind.UNIT_TIME_MS:
      case TokenKind.UNIT_TIME_S:
      case TokenKind.UNIT_FREQ_HZ:
      case TokenKind.UNIT_FREQ_KHZ:
      case TokenKind.UNIT_FRACTION:
        return true;
      default:
        return false;
    }
  }

  static bool isIdentifier(int kind) {
    return kind == IDENTIFIER;
  }
}

// Note: these names should match TokenKind names
class TokenChar {
  static const int UNUSED = -1;
  static const int END_OF_FILE = 0;
  static const int LPAREN = 0x28; // "(".codeUnitAt(0)
  static const int RPAREN = 0x29; // ")".codeUnitAt(0)
  static const int LBRACK = 0x5b; // "[".codeUnitAt(0)
  static const int RBRACK = 0x5d; // "]".codeUnitAt(0)
  static const int LBRACE = 0x7b; // "{".codeUnitAt(0)
  static const int RBRACE = 0x7d; // "}".codeUnitAt(0)
  static const int DOT = 0x2e; // ".".codeUnitAt(0)
  static const int SEMICOLON = 0x3b; // ";".codeUnitAt(0)
  static const int AT = 0x40; // "@".codeUnitAt(0)
  static const int HASH = 0x23; // "#".codeUnitAt(0)
  static const int PLUS = 0x2b; // "+".codeUnitAt(0)
  static const int GREATER = 0x3e; // ">".codeUnitAt(0)
  static const int TILDE = 0x7e; // "~".codeUnitAt(0)
  static const int ASTERISK = 0x2a; // "*".codeUnitAt(0)
  static const int NAMESPACE = 0x7c; // "|".codeUnitAt(0)
  static const int COLON = 0x3a; // ":".codeUnitAt(0)
  static const int PRIVATE_NAME = 0x5f; // "_".codeUnitAt(0)
  static const int COMMA = 0x2c; // ",".codeUnitAt(0)
  static const int SPACE = 0x20; // " ".codeUnitAt(0)
  static const int TAB = 0x9; // "\t".codeUnitAt(0)
  static const int NEWLINE = 0xa; // "\n".codeUnitAt(0)
  static const int RETURN = 0xd; // "\r".codeUnitAt(0)
  static const int BACKSPACE = 0x8; // "/b".codeUnitAt(0)
  static const int FF = 0xc; // "/f".codeUnitAt(0)
  static const int VT = 0xb; // "/v".codeUnitAt(0)
  static const int PERCENT = 0x25; // "%".codeUnitAt(0)
  static const int SINGLE_QUOTE = 0x27; // "'".codeUnitAt(0)
  static const int DOUBLE_QUOTE = 0x22; // '"'.codeUnitAt(0)
  static const int SLASH = 0x2f; // "/".codeUnitAt(0)
  static const int EQUALS = 0x3d; // "=".codeUnitAt(0)
  static const int OR = 0x7c; // "|".codeUnitAt(0)
  static const int CARET = 0x5e; // "^".codeUnitAt(0)
  static const int DOLLAR = 0x24; // "\$".codeUnitAt(0)
  static const int LESS = 0x3c; // "<".codeUnitAt(0)
  static const int BANG = 0x21; // "!".codeUnitAt(0)
  static const int MINUS = 0x2d; // "-".codeUnitAt(0)
  static const int BACKSLASH = 0x5c; // "\".codeUnitAt(0)
  static const int AMPERSAND = 0x26; // "&".codeUnitAt(0)
}
