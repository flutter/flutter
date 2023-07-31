// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Declare integer constants for each ASCII character.
///
/// The constants all start with "$" to avoid conflicting with other constants.
///
/// For characters that are valid in an identifier, the character itself
/// follows the "$". For other characters, a symbolic name is used.
/// In some cases, multiple alternative symbolic names are provided.
/// Please stick to using one name per character in your code.
///
/// The symbolic names are, where applicable, the name of the symbol without
/// any "mark", "symbol" "sign" or "accent" suffix.
/// Examples: [$exclamation], [$pipe], [$dollar] and [$grave].
/// For less common symbols, a selection of common names are used.
///
/// For parenthetical markers, there is both a short name, [$lparen]/[$rparen],
/// and a long name, [$openParen]/ [$closeParen].
///
/// For common HTML entities, the entity names are also usable as symbolic
/// names: [$apos], [$quot], [$lt], [$gt], and [$amp].
library charcode.ascii.dollar_lowercase;

// ignore_for_file: constant_identifier_names

// Control characters.

/// "Null character" control character.
const int $nul = 0x00;

/// "Start of Header" control character.
const int $soh = 0x01;

/// "Start of Text" control character.
const int $stx = 0x02;

/// "End of Text" control character.
const int $etx = 0x03;

/// "End of Transmission" control character.
const int $eot = 0x04;

/// "Enquiry" control character.
const int $enq = 0x05;

/// "Acknowledgment" control character.
const int $ack = 0x06;

/// "Bell" control character.
const int $bel = 0x07;

/// "Backspace" control character.
const int $bs = 0x08;

/// "Horizontal Tab" control character.
const int $ht = 0x09;

/// "Horizontal Tab" control character, common name.
const int $tab = 0x09;

/// "Line feed" control character.
const int $lf = 0x0A;

/// "Vertical Tab" control character.
const int $vt = 0x0B;

/// "Form feed" control character.
const int $ff = 0x0C;

/// "Carriage return" control character.
const int $cr = 0x0D;

/// "Shift Out" control character.
const int $so = 0x0E;

/// "Shift In" control character.
const int $si = 0x0F;

/// "Data Link Escape" control character.
const int $dle = 0x10;

/// "Device Control 1" control character (oft. XON).
const int $dc1 = 0x11;

/// "Device Control 2" control character.
const int $dc2 = 0x12;

/// "Device Control 3" control character (oft. XOFF).
const int $dc3 = 0x13;

/// "Device Control 4" control character.
const int $dc4 = 0x14;

/// "Negative Acknowledgment" control character.
const int $nak = 0x15;

/// "Synchronous idle" control character.
const int $syn = 0x16;

/// "End of Transmission Block" control character.
const int $etb = 0x17;

/// "Cancel" control character.
const int $can = 0x18;

/// "End of Medium" control character.
const int $em = 0x19;

/// "Substitute" control character.
const int $sub = 0x1A;

/// "Escape" control character.
const int $esc = 0x1B;

/// "File Separator" control character.
const int $fs = 0x1C;

/// "Group Separator" control character.
const int $gs = 0x1D;

/// "Record Separator" control character.
const int $rs = 0x1E;

/// "Unit Separator" control character.
const int $us = 0x1F;

/// "Delete" control character.
const int $del = 0x7F;

// Visible characters.

/// Space character.
const int $space = 0x20;

/// Character `!`.
const int $exclamation = 0x21;

/// Character `"', short nam`.
const int $quot = 0x22;

/// Character `"`.
const int $quote = 0x22;

/// Character `"`.
const int $double_quote = 0x22;

/// Character `"`.
const int $doubleQuote = 0x22;

/// Character `"`.
const int $quotation = 0x22;

/// Character `#`.
const int $hash = 0x23;

/// Character `$`.
const int $$ = 0x24;

/// Character `$`.
const int $dollar = 0x24;

/// Character `%`.
const int $percent = 0x25;

/// Character `&`, short name.
const int $amp = 0x26;

/// Character `&`.
const int $ampersand = 0x26;

/// Character `'`.
const int $apos = 0x27;

/// Character `'`.
const int $apostrophe = 0x27;

/// Character `'`.
const int $single_quote = 0x27;

/// Character `'`.
const int $singleQuote = 0x27;

/// Character `(`.
const int $lparen = 0x28;

/// Character `(`.
const int $open_paren = 0x28;

/// Character `(`.
const int $openParen = 0x28;

/// Character `(`.
const int $open_parenthesis = 0x28;

/// Character `(`.
const int $openParenthesis = 0x28;

/// Character `)`.
const int $rparen = 0x29;

/// Character `)`.
const int $close_paren = 0x29;

/// Character `)`.
const int $closeParen = 0x29;

/// Character `)`.
const int $close_parenthesis = 0x29;

/// Character `)`.
const int $closeParenthesis = 0x29;

/// Character `*`.
const int $asterisk = 0x2A;

/// Character `+`.
const int $plus = 0x2B;

/// Character `,`.
const int $comma = 0x2C;

/// Character `-`.
const int $minus = 0x2D;

/// Character `-`.
const int $dash = 0x2D;

/// Character `.`.
const int $dot = 0x2E;

/// Character `.`.
const int $fullstop = 0x2E;

/// Character `/`.
const int $slash = 0x2F;

/// Character `/`.
const int $solidus = 0x2F;

/// Character `/`.
const int $division = 0x2F;

/// Character `0`.
const int $0 = 0x30;

/// Character `1`.
const int $1 = 0x31;

/// Character `2`.
const int $2 = 0x32;

/// Character `3`.
const int $3 = 0x33;

/// Character `4`.
const int $4 = 0x34;

/// Character `5`.
const int $5 = 0x35;

/// Character `6`.
const int $6 = 0x36;

/// Character `7`.
const int $7 = 0x37;

/// Character `8`.
const int $8 = 0x38;

/// Character `9`.
const int $9 = 0x39;

/// Character `:`.
const int $colon = 0x3A;

/// Character `;`.
const int $semicolon = 0x3B;

/// Character `<`.
const int $lt = 0x3C;

/// Character `<`.
const int $less_than = 0x3C;

/// Character `<`.
const int $lessThan = 0x3C;

/// Character `<`.
const int $langle = 0x3C;

/// Character `<`.
const int $open_angle = 0x3C;

/// Character `<`.
const int $openAngle = 0x3C;

/// Character `=`.
const int $equal = 0x3D;

/// Character `>`.
const int $gt = 0x3E;

/// Character `>`.
const int $greater_than = 0x3E;

/// Character `>`.
const int $greaterThan = 0x3E;

/// Character `>`.
const int $rangle = 0x3E;

/// Character `>`.
const int $close_angle = 0x3E;

/// Character `>`.
const int $closeAngle = 0x3E;

/// Character `?`.
const int $question = 0x3F;

/// Character `@`.
const int $at = 0x40;

/// Character `A`.
const int $A = 0x41;

/// Character `B`.
const int $B = 0x42;

/// Character `C`.
const int $C = 0x43;

/// Character `D`.
const int $D = 0x44;

/// Character `E`.
const int $E = 0x45;

/// Character `F`.
const int $F = 0x46;

/// Character `G`.
const int $G = 0x47;

/// Character `H`.
const int $H = 0x48;

/// Character `I`.
const int $I = 0x49;

/// Character `J`.
const int $J = 0x4A;

/// Character `K`.
const int $K = 0x4B;

/// Character `L`.
const int $L = 0x4C;

/// Character `M`.
const int $M = 0x4D;

/// Character `N`.
const int $N = 0x4E;

/// Character `O`.
const int $O = 0x4F;

/// Character `P`.
const int $P = 0x50;

/// Character `Q`.
const int $Q = 0x51;

/// Character `R`.
const int $R = 0x52;

/// Character `S`.
const int $S = 0x53;

/// Character `T`.
const int $T = 0x54;

/// Character `U`.
const int $U = 0x55;

/// Character `V`.
const int $V = 0x56;

/// Character `W`.
const int $W = 0x57;

/// Character `X`.
const int $X = 0x58;

/// Character `Y`.
const int $Y = 0x59;

/// Character `Z`.
const int $Z = 0x5A;

/// Character `[`.
const int $lbracket = 0x5B;

/// Character `[`.
const int $open_bracket = 0x5B;

/// Character `[`.
const int $openBracket = 0x5B;

/// Character `\`.
const int $backslash = 0x5C;

/// Character `]`.
const int $rbracket = 0x5D;

/// Character `]`.
const int $close_bracket = 0x5D;

/// Character `]`.
const int $closeBracket = 0x5D;

/// Character `^`.
const int $circumflex = 0x5E;

/// Character `^`.
const int $caret = 0x5E;

/// Character `^`.
const int $hat = 0x5E;

/// Character `_`.
const int $_ = 0x5F;

/// Character `_`.
const int $underscore = 0x5F;

/// Character `_`.
const int $underline = 0x5F;

/// Character `` ` ``.
const int $backquote = 0x60;

/// Character `` ` ``.
const int $grave = 0x60;

/// Character `a`.
const int $a = 0x61;

/// Character `b`.
const int $b = 0x62;

/// Character `c`.
const int $c = 0x63;

/// Character `d`.
const int $d = 0x64;

/// Character `e`.
const int $e = 0x65;

/// Character `f`.
const int $f = 0x66;

/// Character `g`.
const int $g = 0x67;

/// Character `h`.
const int $h = 0x68;

/// Character `i`.
const int $i = 0x69;

/// Character `j`.
const int $j = 0x6A;

/// Character `k`.
const int $k = 0x6B;

/// Character `l`.
const int $l = 0x6C;

/// Character `m`.
const int $m = 0x6D;

/// Character `n`.
const int $n = 0x6E;

/// Character `o`.
const int $o = 0x6F;

/// Character `p`.
const int $p = 0x70;

/// Character `q`.
const int $q = 0x71;

/// Character `r`.
const int $r = 0x72;

/// Character `s`.
const int $s = 0x73;

/// Character `t`.
const int $t = 0x74;

/// Character `u`.
const int $u = 0x75;

/// Character `v`.
const int $v = 0x76;

/// Character `w`.
const int $w = 0x77;

/// Character `x`.
const int $x = 0x78;

/// Character `y`.
const int $y = 0x79;

/// Character `z`.
const int $z = 0x7A;

/// Character `{`.
const int $lbrace = 0x7B;

/// Character `{`.
const int $open_brace = 0x7B;

/// Character `{`.
const int $openBrace = 0x7B;

/// Character `|`.
const int $pipe = 0x7C;

/// Character `|`.
const int $bar = 0x7C;

/// Character `}`.
const int $rbrace = 0x7D;

/// Character `}`.
const int $close_brace = 0x7D;

/// Character `}`.
const int $closeBrace = 0x7D;

/// Character `~`.
const int $tilde = 0x7E;
