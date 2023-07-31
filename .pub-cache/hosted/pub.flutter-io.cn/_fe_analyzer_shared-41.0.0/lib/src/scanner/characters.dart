// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.characters;

const int $EOF = 0;
const int $STX = 2;
const int $BS = 8;
const int $TAB = 9;
const int $LF = 10;
const int $VTAB = 11;
const int $FF = 12;
const int $CR = 13;
const int $SPACE = 32;
const int $BANG = 33;
const int $DQ = 34;
const int $HASH = 35;
const int $$ = 36;
const int $PERCENT = 37;
const int $AMPERSAND = 38;
const int $SQ = 39;
const int $OPEN_PAREN = 40;
const int $CLOSE_PAREN = 41;
const int $STAR = 42;
const int $PLUS = 43;
const int $COMMA = 44;
const int $MINUS = 45;
const int $PERIOD = 46;
const int $SLASH = 47;
const int $0 = 48;
const int $1 = 49;
const int $2 = 50;
const int $3 = 51;
const int $4 = 52;
const int $5 = 53;
const int $6 = 54;
const int $7 = 55;
const int $8 = 56;
const int $9 = 57;
const int $COLON = 58;
const int $SEMICOLON = 59;
const int $LT = 60;
const int $EQ = 61;
const int $GT = 62;
const int $QUESTION = 63;
const int $AT = 64;
const int $A = 65;
const int $B = 66;
const int $C = 67;
const int $D = 68;
const int $E = 69;
const int $F = 70;
const int $G = 71;
const int $H = 72;
const int $I = 73;
const int $J = 74;
const int $K = 75;
const int $L = 76;
const int $M = 77;
const int $N = 78;
const int $O = 79;
const int $P = 80;
const int $Q = 81;
const int $R = 82;
const int $S = 83;
const int $T = 84;
const int $U = 85;
const int $V = 86;
const int $W = 87;
const int $X = 88;
const int $Y = 89;
const int $Z = 90;
const int $OPEN_SQUARE_BRACKET = 91;
const int $BACKSLASH = 92;
const int $CLOSE_SQUARE_BRACKET = 93;
const int $CARET = 94;
const int $_ = 95;
const int $BACKPING = 96;
const int $a = 97;
const int $b = 98;
const int $c = 99;
const int $d = 100;
const int $e = 101;
const int $f = 102;
const int $g = 103;
const int $h = 104;
const int $i = 105;
const int $j = 106;
const int $k = 107;
const int $l = 108;
const int $m = 109;
const int $n = 110;
const int $o = 111;
const int $p = 112;
const int $q = 113;
const int $r = 114;
const int $s = 115;
const int $t = 116;
const int $u = 117;
const int $v = 118;
const int $w = 119;
const int $x = 120;
const int $y = 121;
const int $z = 122;
const int $OPEN_CURLY_BRACKET = 123;
const int $BAR = 124;
const int $CLOSE_CURLY_BRACKET = 125;
const int $TILDE = 126;
const int $DEL = 127;
const int $NBSP = 160;
const int $LS = 0x2028;
const int $PS = 0x2029;

const int $FIRST_SURROGATE = 0xd800;
const int $LAST_SURROGATE = 0xdfff;
const int $LAST_CODE_POINT = 0x10ffff;

bool isDigit(int characterCode) {
  return $0 <= characterCode && characterCode <= $9;
}

bool isHexDigit(int characterCode) {
  if (characterCode <= $9) return $0 <= characterCode;
  characterCode |= $a ^ $A;
  return ($a <= characterCode && characterCode <= $f);
}

int hexDigitValue(int hexDigit) {
  assert(isHexDigit(hexDigit));
  // hexDigit is one of '0'..'9', 'A'..'F' and 'a'..'f'.
  if (hexDigit <= $9) return hexDigit - $0;
  return (hexDigit | ($a ^ $A)) - ($a - 10);
}
