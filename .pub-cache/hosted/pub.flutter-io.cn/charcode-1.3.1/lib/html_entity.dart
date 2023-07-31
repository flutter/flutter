// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Character codes based on HTML 4.01 character entity names.
///
/// For each entity name, e.g., `nbsp`,
/// a constant with that name prefixed by `$` is defined
/// for that entity's code point.
///
/// The HTML entities include the non-ASCII Latin-1 characters and
/// symbols, mathematical symbols and Greek litters.
///
/// The five characters that are ASCII
/// are exported from the `ascii.dart` library.
///
/// Three names conflict with `ascii.dart`: `$minus`, `$sub` and `$tilde`.
/// If importing both libraries, these three should be hidden from one of the
/// libraries.
library charcode.htmlentity.dollar_lowercase;

export "ascii.dart" show $quot, $amp, $apos, $lt, $gt;

/// no-break space (non-breaking space)
const int $nbsp = 0x00A0;

/// inverted exclamation mark ('¡')
const int $iexcl = 0x00A1;

/// cent sign ('¢')
const int $cent = 0x00A2;

/// pound sign ('£')
const int $pound = 0x00A3;

/// currency sign ('¤')
const int $curren = 0x00A4;

/// yen sign (yuan sign) ('¥')
const int $yen = 0x00A5;

/// broken bar (broken vertical bar) ('¦')
const int $brvbar = 0x00A6;

/// section sign ('§')
const int $sect = 0x00A7;

/// diaeresis (spacing diaeresis); see Germanic umlaut ('¨')
const int $uml = 0x00A8;

/// copyright symbol ('©')
const int $copy = 0x00A9;

/// feminine ordinal indicator ('ª')
const int $ordf = 0x00AA;

/// left-pointing double angle quotation mark (left pointing guillemet) ('«')
const int $laquo = 0x00AB;

/// not sign ('¬')
const int $not = 0x00AC;

/// soft hyphen (discretionary hyphen)
const int $shy = 0x00AD;

/// registered sign (registered trademark symbol) ('®')
const int $reg = 0x00AE;

/// macron (spacing macron, overline, APL overbar) ('¯')
const int $macr = 0x00AF;

/// degree symbol ('°')
const int $deg = 0x00B0;

/// plus-minus sign (plus-or-minus sign) ('±')
const int $plusmn = 0x00B1;

/// superscript two (superscript digit two, squared) ('²')
const int $sup2 = 0x00B2;

/// superscript three (superscript digit three, cubed) ('³')
const int $sup3 = 0x00B3;

/// acute accent (spacing acute) ('´')
const int $acute = 0x00B4;

/// micro sign ('µ')
const int $micro = 0x00B5;

/// pilcrow sign (paragraph sign) ('¶')
const int $para = 0x00B6;

/// middle dot (Georgian comma, Greek middle dot) ('·')
const int $middot = 0x00B7;

/// cedilla (spacing cedilla) ('¸')
const int $cedil = 0x00B8;

/// superscript one (superscript digit one) ('¹')
const int $sup1 = 0x00B9;

/// masculine ordinal indicator ('º')
const int $ordm = 0x00BA;

/// right-pointing double angle quotation mark (right pointing guillemet) ('»')
const int $raquo = 0x00BB;

/// vulgar fraction one quarter (fraction one quarter) ('¼')
const int $frac14 = 0x00BC;

/// vulgar fraction one half (fraction one half) ('½')
const int $frac12 = 0x00BD;

/// vulgar fraction three quarters (fraction three quarters) ('¾')
const int $frac34 = 0x00BE;

/// inverted question mark (turned question mark) ('¿')
const int $iquest = 0x00BF;

/// Latin capital letter A with grave accent (Latin capital letter A grave) ('À')
const int $Agrave = 0x00C0;

/// Latin capital letter A with acute accent ('Á')
const int $Aacute = 0x00C1;

/// Latin capital letter A with circumflex ('Â')
const int $Acirc = 0x00C2;

/// Latin capital letter A with tilde ('Ã')
const int $Atilde = 0x00C3;

/// Latin capital letter A with diaeresis ('Ä')
const int $Auml = 0x00C4;

/// Latin capital letter A with ring above (Latin capital letter A ring) ('Å')
const int $Aring = 0x00C5;

/// Latin capital letter AE (Latin capital ligature AE) ('Æ')
const int $AElig = 0x00C6;

/// Latin capital letter C with cedilla ('Ç')
const int $Ccedil = 0x00C7;

/// Latin capital letter E with grave accent ('È')
const int $Egrave = 0x00C8;

/// Latin capital letter E with acute accent ('É')
const int $Eacute = 0x00C9;

/// Latin capital letter E with circumflex ('Ê')
const int $Ecirc = 0x00CA;

/// Latin capital letter E with diaeresis ('Ë')
const int $Euml = 0x00CB;

/// Latin capital letter I with grave accent ('Ì')
const int $Igrave = 0x00CC;

/// Latin capital letter I with acute accent ('Í')
const int $Iacute = 0x00CD;

/// Latin capital letter I with circumflex ('Î')
const int $Icirc = 0x00CE;

/// Latin capital letter I with diaeresis ('Ï')
const int $Iuml = 0x00CF;

/// Latin capital letter Eth ('Ð')
const int $ETH = 0x00D0;

/// Latin capital letter N with tilde ('Ñ')
const int $Ntilde = 0x00D1;

/// Latin capital letter O with grave accent ('Ò')
const int $Ograve = 0x00D2;

/// Latin capital letter O with acute accent ('Ó')
const int $Oacute = 0x00D3;

/// Latin capital letter O with circumflex ('Ô')
const int $Ocirc = 0x00D4;

/// Latin capital letter O with tilde ('Õ')
const int $Otilde = 0x00D5;

/// Latin capital letter O with diaeresis ('Ö')
const int $Ouml = 0x00D6;

/// multiplication sign ('×')
const int $times = 0x00D7;

/// Latin capital letter O with stroke (Latin capital letter O slash) ('Ø')
const int $Oslash = 0x00D8;

/// Latin capital letter U with grave accent ('Ù')
const int $Ugrave = 0x00D9;

/// Latin capital letter U with acute accent ('Ú')
const int $Uacute = 0x00DA;

/// Latin capital letter U with circumflex ('Û')
const int $Ucirc = 0x00DB;

/// Latin capital letter U with diaeresis ('Ü')
const int $Uuml = 0x00DC;

/// Latin capital letter Y with acute accent ('Ý')
const int $Yacute = 0x00DD;

/// Latin capital letter THORN ('Þ')
const int $THORN = 0x00DE;

/// Latin small letter sharp s (ess-zed); see German Eszett ('ß')
const int $szlig = 0x00DF;

/// Latin small letter a with grave accent ('à')
const int $agrave = 0x00E0;

/// Latin small letter a with acute accent ('á')
const int $aacute = 0x00E1;

/// Latin small letter a with circumflex ('â')
const int $acirc = 0x00E2;

/// Latin small letter a with tilde ('ã')
const int $atilde = 0x00E3;

/// Latin small letter a with diaeresis ('ä')
const int $auml = 0x00E4;

/// Latin small letter a with ring above ('å')
const int $aring = 0x00E5;

/// Latin small letter ae (Latin small ligature ae) ('æ')
const int $aelig = 0x00E6;

/// Latin small letter c with cedilla ('ç')
const int $ccedil = 0x00E7;

/// Latin small letter e with grave accent ('è')
const int $egrave = 0x00E8;

/// Latin small letter e with acute accent ('é')
const int $eacute = 0x00E9;

/// Latin small letter e with circumflex ('ê')
const int $ecirc = 0x00EA;

/// Latin small letter e with diaeresis ('ë')
const int $euml = 0x00EB;

/// Latin small letter i with grave accent ('ì')
const int $igrave = 0x00EC;

/// Latin small letter i with acute accent ('í')
const int $iacute = 0x00ED;

/// Latin small letter i with circumflex ('î')
const int $icirc = 0x00EE;

/// Latin small letter i with diaeresis ('ï')
const int $iuml = 0x00EF;

/// Latin small letter eth ('ð')
const int $eth = 0x00F0;

/// Latin small letter n with tilde ('ñ')
const int $ntilde = 0x00F1;

/// Latin small letter o with grave accent ('ò')
const int $ograve = 0x00F2;

/// Latin small letter o with acute accent ('ó')
const int $oacute = 0x00F3;

/// Latin small letter o with circumflex ('ô')
const int $ocirc = 0x00F4;

/// Latin small letter o with tilde ('õ')
const int $otilde = 0x00F5;

/// Latin small letter o with diaeresis ('ö')
const int $ouml = 0x00F6;

/// division sign (obelus) ('÷')
const int $divide = 0x00F7;

/// Latin small letter o with stroke (Latin small letter o slash) ('ø')
const int $oslash = 0x00F8;

/// Latin small letter u with grave accent ('ù')
const int $ugrave = 0x00F9;

/// Latin small letter u with acute accent ('ú')
const int $uacute = 0x00FA;

/// Latin small letter u with circumflex ('û')
const int $ucirc = 0x00FB;

/// Latin small letter u with diaeresis ('ü')
const int $uuml = 0x00FC;

/// Latin small letter y with acute accent ('ý')
const int $yacute = 0x00FD;

/// Latin small letter thorn ('þ')
const int $thorn = 0x00FE;

/// Latin small letter y with diaeresis ('ÿ')
const int $yuml = 0x00FF;

/// Latin capital ligature oe ('Œ')
const int $OElig = 0x0152;

/// Latin small ligature oe ('œ')
const int $oelig = 0x0153;

/// Latin capital letter s with caron ('Š')
const int $Scaron = 0x0160;

/// Latin small letter s with caron ('š')
const int $scaron = 0x0161;

/// Latin capital letter y with diaeresis ('Ÿ')
const int $Yuml = 0x0178;

/// Latin small letter f with hook (function, florin) ('ƒ')
const int $fnof = 0x0192;

/// modifier letter circumflex accent ('ˆ')
const int $circ = 0x02C6;

/// small tilde ('˜')
const int $tilde = 0x02DC;

/// Greek capital letter Alpha ('Α')
const int $Alpha = 0x0391;

/// Greek capital letter Beta ('Β')
const int $Beta = 0x0392;

/// Greek capital letter Gamma ('Γ')
const int $Gamma = 0x0393;

/// Greek capital letter Delta ('Δ')
const int $Delta = 0x0394;

/// Greek capital letter Epsilon ('Ε')
const int $Epsilon = 0x0395;

/// Greek capital letter Zeta ('Ζ')
const int $Zeta = 0x0396;

/// Greek capital letter Eta ('Η')
const int $Eta = 0x0397;

/// Greek capital letter Theta ('Θ')
const int $Theta = 0x0398;

/// Greek capital letter Iota ('Ι')
const int $Iota = 0x0399;

/// Greek capital letter Kappa ('Κ')
const int $Kappa = 0x039A;

/// Greek capital letter Lambda ('Λ')
const int $Lambda = 0x039B;

/// Greek capital letter Mu ('Μ')
const int $Mu = 0x039C;

/// Greek capital letter Nu ('Ν')
const int $Nu = 0x039D;

/// Greek capital letter Xi ('Ξ')
const int $Xi = 0x039E;

/// Greek capital letter Omicron ('Ο')
const int $Omicron = 0x039F;

/// Greek capital letter Pi ('Π')
const int $Pi = 0x03A0;

/// Greek capital letter Rho ('Ρ')
const int $Rho = 0x03A1;

/// Greek capital letter Sigma ('Σ')
const int $Sigma = 0x03A3;

/// Greek capital letter Tau ('Τ')
const int $Tau = 0x03A4;

/// Greek capital letter Upsilon ('Υ')
const int $Upsilon = 0x03A5;

/// Greek capital letter Phi ('Φ')
const int $Phi = 0x03A6;

/// Greek capital letter Chi ('Χ')
const int $Chi = 0x03A7;

/// Greek capital letter Psi ('Ψ')
const int $Psi = 0x03A8;

/// Greek capital letter Omega ('Ω')
const int $Omega = 0x03A9;

/// Greek small letter alpha ('α')
const int $alpha = 0x03B1;

/// Greek small letter beta ('β')
const int $beta = 0x03B2;

/// Greek small letter gamma ('γ')
const int $gamma = 0x03B3;

/// Greek small letter delta ('δ')
const int $delta = 0x03B4;

/// Greek small letter epsilon ('ε')
const int $epsilon = 0x03B5;

/// Greek small letter zeta ('ζ')
const int $zeta = 0x03B6;

/// Greek small letter eta ('η')
const int $eta = 0x03B7;

/// Greek small letter theta ('θ')
const int $theta = 0x03B8;

/// Greek small letter iota ('ι')
const int $iota = 0x03B9;

/// Greek small letter kappa ('κ')
const int $kappa = 0x03BA;

/// Greek small letter lambda ('λ')
const int $lambda = 0x03BB;

/// Greek small letter mu ('μ')
const int $mu = 0x03BC;

/// Greek small letter nu ('ν')
const int $nu = 0x03BD;

/// Greek small letter xi ('ξ')
const int $xi = 0x03BE;

/// Greek small letter omicron ('ο')
const int $omicron = 0x03BF;

/// Greek small letter pi ('π')
const int $pi = 0x03C0;

/// Greek small letter rho ('ρ')
const int $rho = 0x03C1;

/// Greek small letter final sigma ('ς')
const int $sigmaf = 0x03C2;

/// Greek small letter sigma ('σ')
const int $sigma = 0x03C3;

/// Greek small letter tau ('τ')
const int $tau = 0x03C4;

/// Greek small letter upsilon ('υ')
const int $upsilon = 0x03C5;

/// Greek small letter phi ('φ')
const int $phi = 0x03C6;

/// Greek small letter chi ('χ')
const int $chi = 0x03C7;

/// Greek small letter psi ('ψ')
const int $psi = 0x03C8;

/// Greek small letter omega ('ω')
const int $omega = 0x03C9;

/// Greek theta symbol ('ϑ')
const int $thetasym = 0x03D1;

/// Greek Upsilon with hook symbol ('ϒ')
const int $upsih = 0x03D2;

/// Greek pi symbol ('ϖ')
const int $piv = 0x03D6;

/// en space
const int $ensp = 0x2002;

/// em space
const int $emsp = 0x2003;

/// thin space
const int $thinsp = 0x2009;

/// zero-width non-joiner
const int $zwnj = 0x200C;

/// zero-width joiner
const int $zwj = 0x200D;

/// left-to-right mark
const int $lrm = 0x200E;

/// right-to-left mark
const int $rlm = 0x200F;

/// en dash ('–')
const int $ndash = 0x2013;

/// em dash ('—')
const int $mdash = 0x2014;

/// left single quotation mark ('‘')
const int $lsquo = 0x2018;

/// right single quotation mark ('’')
const int $rsquo = 0x2019;

/// single low-9 quotation mark ('‚')
const int $sbquo = 0x201A;

/// left double quotation mark ('“')
const int $ldquo = 0x201C;

/// right double quotation mark ('”')
const int $rdquo = 0x201D;

/// double low-9 quotation mark ('„')
const int $bdquo = 0x201E;

/// dagger, obelisk ('†')
const int $dagger = 0x2020;

/// double dagger, double obelisk ('‡')
const int $Dagger = 0x2021;

/// bullet (black small circle) ('•')
const int $bull = 0x2022;

/// horizontal ellipsis (three dot leader) ('…')
const int $hellip = 0x2026;

/// per mille sign ('‰')
const int $permil = 0x2030;

/// prime (minutes, feet) ('′')
const int $prime = 0x2032;

/// double prime (seconds, inches) ('″')
const int $Prime = 0x2033;

/// single left-pointing angle quotation mark ('‹')
const int $lsaquo = 0x2039;

/// single right-pointing angle quotation mark ('›')
const int $rsaquo = 0x203A;

/// overline (spacing overscore) ('‾')
const int $oline = 0x203E;

/// fraction slash (solidus) ('⁄')
const int $frasl = 0x2044;

/// euro sign ('€')
const int $euro = 0x20AC;

/// black-letter capital I (imaginary part) ('ℑ')
const int $image = 0x2111;

/// script capital P (power set, Weierstrass p) ('℘')
const int $weierp = 0x2118;

/// black-letter capital R (real part symbol) ('ℜ')
const int $real = 0x211C;

/// trademark symbol ('™')
const int $trade = 0x2122;

/// alef symbol (first transfinite cardinal) ('ℵ')
const int $alefsym = 0x2135;

/// leftwards arrow ('←')
const int $larr = 0x2190;

/// upwards arrow ('↑')
const int $uarr = 0x2191;

/// rightwards arrow ('→')
const int $rarr = 0x2192;

/// downwards arrow ('↓')
const int $darr = 0x2193;

/// left right arrow ('↔')
const int $harr = 0x2194;

/// downwards arrow with corner leftwards (carriage return) ('↵')
const int $crarr = 0x21B5;

/// leftwards double arrow ('⇐')
const int $lArr = 0x21D0;

/// upwards double arrow ('⇑')
const int $uArr = 0x21D1;

/// rightwards double arrow ('⇒')
const int $rArr = 0x21D2;

/// downwards double arrow ('⇓')
const int $dArr = 0x21D3;

/// left right double arrow ('⇔')
const int $hArr = 0x21D4;

/// for all ('∀')
const int $forall = 0x2200;

/// partial differential ('∂')
const int $part = 0x2202;

/// there exists ('∃')
const int $exist = 0x2203;

/// empty set (null set); see also U+8960, ⌀ ('∅')
const int $empty = 0x2205;

/// del or nabla (vector differential operator) ('∇')
const int $nabla = 0x2207;

/// element of ('∈')
const int $isin = 0x2208;

/// not an element of ('∉')
const int $notin = 0x2209;

/// contains as member ('∋')
const int $ni = 0x220B;

/// n-ary product (product sign) ('∏')
const int $prod = 0x220F;

/// n-ary summation ('∑')
const int $sum = 0x2211;

/// minus sign ('−')
const int $minus = 0x2212;

/// asterisk operator ('∗')
const int $lowast = 0x2217;

/// square root (radical sign) ('√')
const int $radic = 0x221A;

/// proportional to ('∝')
const int $prop = 0x221D;

/// infinity ('∞')
const int $infin = 0x221E;

/// angle ('∠')
const int $ang = 0x2220;

/// logical and (wedge) ('∧')
const int $and = 0x2227;

/// logical or (vee) ('∨')
const int $or = 0x2228;

/// intersection (cap) ('∩')
const int $cap = 0x2229;

/// union (cup) ('∪')
const int $cup = 0x222A;

/// integral ('∫')
const int $int = 0x222B;

/// therefore sign ('∴')
const int $there4 = 0x2234;

/// tilde operator (varies with, similar to) ('∼')
const int $sim = 0x223C;

/// congruent to ('≅')
const int $cong = 0x2245;

/// almost equal to (asymptotic to) ('≈')
const int $asymp = 0x2248;

/// not equal to ('≠')
const int $ne = 0x2260;

/// identical to; sometimes used for 'equivalent to' ('≡')
const int $equiv = 0x2261;

/// less-than or equal to ('≤')
const int $le = 0x2264;

/// greater-than or equal to ('≥')
const int $ge = 0x2265;

/// subset of ('⊂')
const int $sub = 0x2282;

/// superset of ('⊃')
const int $sup = 0x2283;

/// not a subset of ('⊄')
const int $nsub = 0x2284;

/// subset of or equal to ('⊆')
const int $sube = 0x2286;

/// superset of or equal to ('⊇')
const int $supe = 0x2287;

/// circled plus (direct sum) ('⊕')
const int $oplus = 0x2295;

/// circled times (vector product) ('⊗')
const int $otimes = 0x2297;

/// up tack (orthogonal to, perpendicular) ('⊥')
const int $perp = 0x22A5;

/// dot operator ('⋅')
const int $sdot = 0x22C5;

/// vertical ellipsis ('⋮')
const int $vellip = 0x22EE;

/// left ceiling (APL upstile) ('⌈')
const int $lceil = 0x2308;

/// right ceiling ('⌉')
const int $rceil = 0x2309;

/// left floor (APL downstile) ('⌊')
const int $lfloor = 0x230A;

/// right floor ('⌋')
const int $rfloor = 0x230B;

/// left-pointing angle bracket (bra) ('〈')
const int $lang = 0x2329;

/// right-pointing angle bracket (ket) ('〉')
const int $rang = 0x232A;

/// lozenge ('◊')
const int $loz = 0x25CA;

/// black spade suit ('♠')
const int $spades = 0x2660;

/// black club suit (shamrock) ('♣')
const int $clubs = 0x2663;

/// black heart suit (valentine) ('♥')
const int $hearts = 0x2665;

/// black diamond suit ('♦')
const int $diams = 0x2666;
