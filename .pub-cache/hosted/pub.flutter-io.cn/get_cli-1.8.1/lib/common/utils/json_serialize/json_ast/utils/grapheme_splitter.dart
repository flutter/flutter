const int CR = 0;
const int LF = 1;
const int Control = 2;
const int Extend = 3;
const int Regional_Indicator = 4;
const int SpacingMark = 5;
const int L = 6;
const int V = 7;
const int T = 8;
const int LV = 9;
const int LVT = 10;
const int Other = 11;
const int Prepend = 12;
const int E_Base = 13;
const int E_Modifier = 14;
const int ZWJ = 15;
const int Glue_After_Zwj = 16;
const int E_Base_GAZ = 17;
const int NotBreak = 0;
const int BreakStart = 1;
const int Break = 2;
const int BreakLastRegional = 3;
const int BreakPenultimateRegional = 4;

bool _isSurrogate(String str, int pos) {
  return 0xd800 <= str.codeUnitAt(pos) &&
      str.codeUnitAt(pos) <= 0xdbff &&
      0xdc00 <= str.codeUnitAt(pos + 1) &&
      str.codeUnitAt(pos + 1) <= 0xdfff;
}

int _codePointAt(String str, [int? idx]) {
  idx ??= 0;
  var code = str.codeUnitAt(idx);
  if (0xD800 <= code && code <= 0xDBFF && idx < str.length - 1) {
    var hi = code;
    var low = str.codeUnitAt(idx + 1);
    if (0xDC00 <= low && low <= 0xDFFF) {
      return ((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000;
    }
    return hi;
  }
  if (0xDC00 <= code && code <= 0xDFFF && idx >= 1) {
    var hi = str.codeUnitAt(idx - 1);
    var low = code;
    if (0xD800 <= hi && hi <= 0xDBFF) {
      return ((hi - 0xD800) * 0x400) + (low - 0xDC00) + 0x10000;
    }
    return low;
  }
  return code;
}

List<int> sliceFromEnd(List<int> list, int idx) {
  return list.sublist(0, list.length - 1).sublist(idx);
}

int shouldBreak(int start, List<int> mid, int end) {
  final all = [start];
  all.addAll(mid);
  all.addAll([end]);
  final previous = all[all.length - 2];
  final next = end;
  final eModifierIndex = all.lastIndexOf(E_Modifier);
  if (eModifierIndex > 1 &&
      all.sublist(1, eModifierIndex).every((c) => c == Extend) &&
      ![Extend, E_Base, E_Base_GAZ].contains(start)) {
    return Break;
  }
  var rIIndex = all.lastIndexOf(Regional_Indicator);
  if (rIIndex > 0 &&
      all.sublist(1, rIIndex).every((c) => c == Regional_Indicator) &&
      ![Prepend, Regional_Indicator].contains(previous)) {
    if (all.where((c) => c == Regional_Indicator).length % 2 == 1) {
      return BreakLastRegional;
    } else {
      return BreakPenultimateRegional;
    }
  }
  if (previous == CR && next == LF) {
    return NotBreak;
  } else if (previous == Control || previous == CR || previous == LF) {
    if (next == E_Modifier && mid.every((c) => c == Extend)) {
      return Break;
    } else {
      return BreakStart;
    }
  } else if (next == Control || next == CR || next == LF) {
    return BreakStart;
  } else if (previous == L &&
      (next == L || next == V || next == LV || next == LVT)) {
    return NotBreak;
  } else if ((previous == LV || previous == V) && (next == V || next == T)) {
    return NotBreak;
  } else if ((previous == LVT || previous == T) && next == T) {
    return NotBreak;
  } else if (next == Extend || next == ZWJ) {
    return NotBreak;
  } else if (next == SpacingMark) {
    return NotBreak;
  } else if (previous == Prepend) {
    return NotBreak;
  }
  final previousNonExtendIndex =
      all.contains(Extend) ? all.lastIndexOf(Extend) - 1 : all.length - 2;
  if (previousNonExtendIndex != -1 &&
      [E_Base, E_Base_GAZ].contains(all[previousNonExtendIndex]) &&
      all.length > previousNonExtendIndex + 1 &&
      sliceFromEnd(all, previousNonExtendIndex + 1).every((c) => c == Extend) &&
      next == E_Modifier) {
    return NotBreak;
  }
  if (previous == ZWJ && [Glue_After_Zwj, E_Base_GAZ].contains(next)) {
    return NotBreak;
  }
  if (mid.contains(Regional_Indicator)) {
    return Break;
  }
  if (previous == Regional_Indicator && next == Regional_Indicator) {
    return NotBreak;
  }
  return BreakStart;
}

int getGraphemeBreakProperty(int code) {
  if ((0x0600 <= code && code <= 0x0605) ||
      0x06DD == code ||
      0x070F == code ||
      0x08E2 == code ||
      0x0D4E == code ||
      0x110BD == code ||
      (0x111C2 <= code && code <= 0x111C3) ||
      0x11A3A == code ||
      (0x11A86 <= code && code <= 0x11A89) ||
      0x11D46 == code) {
    return Prepend;
  }
  if (0x000D == code) {
    return CR;
  }
  if (0x000A == code) {
    return LF;
  }
  if ((0x0000 <= code && code <= 0x0009) ||
      (0x000B <= code && code <= 0x000C) ||
      (0x000E <= code && code <= 0x001F) ||
      (0x007F <= code && code <= 0x009F) ||
      0x00AD == code ||
      0x061C == code ||
      0x180E == code ||
      0x200B == code ||
      (0x200E <= code && code <= 0x200F) ||
      0x2028 == code ||
      0x2029 == code ||
      (0x202A <= code && code <= 0x202E) ||
      (0x2060 <= code && code <= 0x2064) ||
      0x2065 == code ||
      (0x2066 <= code && code <= 0x206F) ||
      (0xD800 <= code && code <= 0xDFFF) ||
      0xFEFF == code ||
      (0xFFF0 <= code && code <= 0xFFF8) ||
      (0xFFF9 <= code && code <= 0xFFFB) ||
      (0x1BCA0 <= code && code <= 0x1BCA3) ||
      (0x1D173 <= code && code <= 0x1D17A) ||
      0xE0000 == code ||
      0xE0001 == code ||
      (0xE0002 <= code && code <= 0xE001F) ||
      (0xE0080 <= code && code <= 0xE00FF) ||
      (0xE01F0 <= code && code <= 0xE0FFF)) {
    return Control;
  }
  if ((0x0300 <= code && code <= 0x036F) ||
      (0x0483 <= code && code <= 0x0487) ||
      (0x0488 <= code && code <= 0x0489) ||
      (0x0591 <= code && code <= 0x05BD) ||
      0x05BF == code ||
      (0x05C1 <= code && code <= 0x05C2) ||
      (0x05C4 <= code && code <= 0x05C5) ||
      0x05C7 == code ||
      (0x0610 <= code && code <= 0x061A) ||
      (0x064B <= code && code <= 0x065F) ||
      0x0670 == code ||
      (0x06D6 <= code && code <= 0x06DC) ||
      (0x06DF <= code && code <= 0x06E4) ||
      (0x06E7 <= code && code <= 0x06E8) ||
      (0x06EA <= code && code <= 0x06ED) ||
      0x0711 == code ||
      (0x0730 <= code && code <= 0x074A) ||
      (0x07A6 <= code && code <= 0x07B0) ||
      (0x07EB <= code && code <= 0x07F3) ||
      (0x0816 <= code && code <= 0x0819) ||
      (0x081B <= code && code <= 0x0823) ||
      (0x0825 <= code && code <= 0x0827) ||
      (0x0829 <= code && code <= 0x082D) ||
      (0x0859 <= code && code <= 0x085B) ||
      (0x08D4 <= code && code <= 0x08E1) ||
      (0x08E3 <= code && code <= 0x0902) ||
      0x093A == code ||
      0x093C == code ||
      (0x0941 <= code && code <= 0x0948) ||
      0x094D == code ||
      (0x0951 <= code && code <= 0x0957) ||
      (0x0962 <= code && code <= 0x0963) ||
      0x0981 == code ||
      0x09BC == code ||
      0x09BE == code ||
      (0x09C1 <= code && code <= 0x09C4) ||
      0x09CD == code ||
      0x09D7 == code ||
      (0x09E2 <= code && code <= 0x09E3) ||
      (0x0A01 <= code && code <= 0x0A02) ||
      0x0A3C == code ||
      (0x0A41 <= code && code <= 0x0A42) ||
      (0x0A47 <= code && code <= 0x0A48) ||
      (0x0A4B <= code && code <= 0x0A4D) ||
      0x0A51 == code ||
      (0x0A70 <= code && code <= 0x0A71) ||
      0x0A75 == code ||
      (0x0A81 <= code && code <= 0x0A82) ||
      0x0ABC == code ||
      (0x0AC1 <= code && code <= 0x0AC5) ||
      (0x0AC7 <= code && code <= 0x0AC8) ||
      0x0ACD == code ||
      (0x0AE2 <= code && code <= 0x0AE3) ||
      (0x0AFA <= code && code <= 0x0AFF) ||
      0x0B01 == code ||
      0x0B3C == code ||
      0x0B3E == code ||
      0x0B3F == code ||
      (0x0B41 <= code && code <= 0x0B44) ||
      0x0B4D == code ||
      0x0B56 == code ||
      0x0B57 == code ||
      (0x0B62 <= code && code <= 0x0B63) ||
      0x0B82 == code ||
      0x0BBE == code ||
      0x0BC0 == code ||
      0x0BCD == code ||
      0x0BD7 == code ||
      0x0C00 == code ||
      (0x0C3E <= code && code <= 0x0C40) ||
      (0x0C46 <= code && code <= 0x0C48) ||
      (0x0C4A <= code && code <= 0x0C4D) ||
      (0x0C55 <= code && code <= 0x0C56) ||
      (0x0C62 <= code && code <= 0x0C63) ||
      0x0C81 == code ||
      0x0CBC == code ||
      0x0CBF == code ||
      0x0CC2 == code ||
      0x0CC6 == code ||
      (0x0CCC <= code && code <= 0x0CCD) ||
      (0x0CD5 <= code && code <= 0x0CD6) ||
      (0x0CE2 <= code && code <= 0x0CE3) ||
      (0x0D00 <= code && code <= 0x0D01) ||
      (0x0D3B <= code && code <= 0x0D3C) ||
      0x0D3E == code ||
      (0x0D41 <= code && code <= 0x0D44) ||
      0x0D4D == code ||
      0x0D57 == code ||
      (0x0D62 <= code && code <= 0x0D63) ||
      0x0DCA == code ||
      0x0DCF == code ||
      (0x0DD2 <= code && code <= 0x0DD4) ||
      0x0DD6 == code ||
      0x0DDF == code ||
      0x0E31 == code ||
      (0x0E34 <= code && code <= 0x0E3A) ||
      (0x0E47 <= code && code <= 0x0E4E) ||
      0x0EB1 == code ||
      (0x0EB4 <= code && code <= 0x0EB9) ||
      (0x0EBB <= code && code <= 0x0EBC) ||
      (0x0EC8 <= code && code <= 0x0ECD) ||
      (0x0F18 <= code && code <= 0x0F19) ||
      0x0F35 == code ||
      0x0F37 == code ||
      0x0F39 == code ||
      (0x0F71 <= code && code <= 0x0F7E) ||
      (0x0F80 <= code && code <= 0x0F84) ||
      (0x0F86 <= code && code <= 0x0F87) ||
      (0x0F8D <= code && code <= 0x0F97) ||
      (0x0F99 <= code && code <= 0x0FBC) ||
      0x0FC6 == code ||
      (0x102D <= code && code <= 0x1030) ||
      (0x1032 <= code && code <= 0x1037) ||
      (0x1039 <= code && code <= 0x103A) ||
      (0x103D <= code && code <= 0x103E) ||
      (0x1058 <= code && code <= 0x1059) ||
      (0x105E <= code && code <= 0x1060) ||
      (0x1071 <= code && code <= 0x1074) ||
      0x1082 == code ||
      (0x1085 <= code && code <= 0x1086) ||
      0x108D == code ||
      0x109D == code ||
      (0x135D <= code && code <= 0x135F) ||
      (0x1712 <= code && code <= 0x1714) ||
      (0x1732 <= code && code <= 0x1734) ||
      (0x1752 <= code && code <= 0x1753) ||
      (0x1772 <= code && code <= 0x1773) ||
      (0x17B4 <= code && code <= 0x17B5) ||
      (0x17B7 <= code && code <= 0x17BD) ||
      0x17C6 == code ||
      (0x17C9 <= code && code <= 0x17D3) ||
      0x17DD == code ||
      (0x180B <= code && code <= 0x180D) ||
      (0x1885 <= code && code <= 0x1886) ||
      0x18A9 == code ||
      (0x1920 <= code && code <= 0x1922) ||
      (0x1927 <= code && code <= 0x1928) ||
      0x1932 == code ||
      (0x1939 <= code && code <= 0x193B) ||
      (0x1A17 <= code && code <= 0x1A18) ||
      0x1A1B == code ||
      0x1A56 == code ||
      (0x1A58 <= code && code <= 0x1A5E) ||
      0x1A60 == code ||
      0x1A62 == code ||
      (0x1A65 <= code && code <= 0x1A6C) ||
      (0x1A73 <= code && code <= 0x1A7C) ||
      0x1A7F == code ||
      (0x1AB0 <= code && code <= 0x1ABD) ||
      0x1ABE == code ||
      (0x1B00 <= code && code <= 0x1B03) ||
      0x1B34 == code ||
      (0x1B36 <= code && code <= 0x1B3A) ||
      0x1B3C == code ||
      0x1B42 == code ||
      (0x1B6B <= code && code <= 0x1B73) ||
      (0x1B80 <= code && code <= 0x1B81) ||
      (0x1BA2 <= code && code <= 0x1BA5) ||
      (0x1BA8 <= code && code <= 0x1BA9) ||
      (0x1BAB <= code && code <= 0x1BAD) ||
      0x1BE6 == code ||
      (0x1BE8 <= code && code <= 0x1BE9) ||
      0x1BED == code ||
      (0x1BEF <= code && code <= 0x1BF1) ||
      (0x1C2C <= code && code <= 0x1C33) ||
      (0x1C36 <= code && code <= 0x1C37) ||
      (0x1CD0 <= code && code <= 0x1CD2) ||
      (0x1CD4 <= code && code <= 0x1CE0) ||
      (0x1CE2 <= code && code <= 0x1CE8) ||
      0x1CED == code ||
      0x1CF4 == code ||
      (0x1CF8 <= code && code <= 0x1CF9) ||
      (0x1DC0 <= code && code <= 0x1DF9) ||
      (0x1DFB <= code && code <= 0x1DFF) ||
      0x200C == code ||
      (0x20D0 <= code && code <= 0x20DC) ||
      (0x20DD <= code && code <= 0x20E0) ||
      0x20E1 == code ||
      (0x20E2 <= code && code <= 0x20E4) ||
      (0x20E5 <= code && code <= 0x20F0) ||
      (0x2CEF <= code && code <= 0x2CF1) ||
      0x2D7F == code ||
      (0x2DE0 <= code && code <= 0x2DFF) ||
      (0x302A <= code && code <= 0x302D) ||
      (0x302E <= code && code <= 0x302F) ||
      (0x3099 <= code && code <= 0x309A) ||
      0xA66F == code ||
      (0xA670 <= code && code <= 0xA672) ||
      (0xA674 <= code && code <= 0xA67D) ||
      (0xA69E <= code && code <= 0xA69F) ||
      (0xA6F0 <= code && code <= 0xA6F1) ||
      0xA802 == code ||
      0xA806 == code ||
      0xA80B == code ||
      (0xA825 <= code && code <= 0xA826) ||
      (0xA8C4 <= code && code <= 0xA8C5) ||
      (0xA8E0 <= code && code <= 0xA8F1) ||
      (0xA926 <= code && code <= 0xA92D) ||
      (0xA947 <= code && code <= 0xA951) ||
      (0xA980 <= code && code <= 0xA982) ||
      0xA9B3 == code ||
      (0xA9B6 <= code && code <= 0xA9B9) ||
      0xA9BC == code ||
      0xA9E5 == code ||
      (0xAA29 <= code && code <= 0xAA2E) ||
      (0xAA31 <= code && code <= 0xAA32) ||
      (0xAA35 <= code && code <= 0xAA36) ||
      0xAA43 == code ||
      0xAA4C == code ||
      0xAA7C == code ||
      0xAAB0 == code ||
      (0xAAB2 <= code && code <= 0xAAB4) ||
      (0xAAB7 <= code && code <= 0xAAB8) ||
      (0xAABE <= code && code <= 0xAABF) ||
      0xAAC1 == code ||
      (0xAAEC <= code && code <= 0xAAED) ||
      0xAAF6 == code ||
      0xABE5 == code ||
      0xABE8 == code ||
      0xABED == code ||
      0xFB1E == code ||
      (0xFE00 <= code && code <= 0xFE0F) ||
      (0xFE20 <= code && code <= 0xFE2F) ||
      (0xFF9E <= code && code <= 0xFF9F) ||
      0x101FD == code ||
      0x102E0 == code ||
      (0x10376 <= code && code <= 0x1037A) ||
      (0x10A01 <= code && code <= 0x10A03) ||
      (0x10A05 <= code && code <= 0x10A06) ||
      (0x10A0C <= code && code <= 0x10A0F) ||
      (0x10A38 <= code && code <= 0x10A3A) ||
      0x10A3F == code ||
      (0x10AE5 <= code && code <= 0x10AE6) ||
      0x11001 == code ||
      (0x11038 <= code && code <= 0x11046) ||
      (0x1107F <= code && code <= 0x11081) ||
      (0x110B3 <= code && code <= 0x110B6) ||
      (0x110B9 <= code && code <= 0x110BA) ||
      (0x11100 <= code && code <= 0x11102) ||
      (0x11127 <= code && code <= 0x1112B) ||
      (0x1112D <= code && code <= 0x11134) ||
      0x11173 == code ||
      (0x11180 <= code && code <= 0x11181) ||
      (0x111B6 <= code && code <= 0x111BE) ||
      (0x111CA <= code && code <= 0x111CC) ||
      (0x1122F <= code && code <= 0x11231) ||
      0x11234 == code ||
      (0x11236 <= code && code <= 0x11237) ||
      0x1123E == code ||
      0x112DF == code ||
      (0x112E3 <= code && code <= 0x112EA) ||
      (0x11300 <= code && code <= 0x11301) ||
      0x1133C == code ||
      0x1133E == code ||
      0x11340 == code ||
      0x11357 == code ||
      (0x11366 <= code && code <= 0x1136C) ||
      (0x11370 <= code && code <= 0x11374) ||
      (0x11438 <= code && code <= 0x1143F) ||
      (0x11442 <= code && code <= 0x11444) ||
      0x11446 == code ||
      0x114B0 == code ||
      (0x114B3 <= code && code <= 0x114B8) ||
      0x114BA == code ||
      0x114BD == code ||
      (0x114BF <= code && code <= 0x114C0) ||
      (0x114C2 <= code && code <= 0x114C3) ||
      0x115AF == code ||
      (0x115B2 <= code && code <= 0x115B5) ||
      (0x115BC <= code && code <= 0x115BD) ||
      (0x115BF <= code && code <= 0x115C0) ||
      (0x115DC <= code && code <= 0x115DD) ||
      (0x11633 <= code && code <= 0x1163A) ||
      0x1163D == code ||
      (0x1163F <= code && code <= 0x11640) ||
      0x116AB == code ||
      0x116AD == code ||
      (0x116B0 <= code && code <= 0x116B5) ||
      0x116B7 == code ||
      (0x1171D <= code && code <= 0x1171F) ||
      (0x11722 <= code && code <= 0x11725) ||
      (0x11727 <= code && code <= 0x1172B) ||
      (0x11A01 <= code && code <= 0x11A06) ||
      (0x11A09 <= code && code <= 0x11A0A) ||
      (0x11A33 <= code && code <= 0x11A38) ||
      (0x11A3B <= code && code <= 0x11A3E) ||
      0x11A47 == code ||
      (0x11A51 <= code && code <= 0x11A56) ||
      (0x11A59 <= code && code <= 0x11A5B) ||
      (0x11A8A <= code && code <= 0x11A96) ||
      (0x11A98 <= code && code <= 0x11A99) ||
      (0x11C30 <= code && code <= 0x11C36) ||
      (0x11C38 <= code && code <= 0x11C3D) ||
      0x11C3F == code ||
      (0x11C92 <= code && code <= 0x11CA7) ||
      (0x11CAA <= code && code <= 0x11CB0) ||
      (0x11CB2 <= code && code <= 0x11CB3) ||
      (0x11CB5 <= code && code <= 0x11CB6) ||
      (0x11D31 <= code && code <= 0x11D36) ||
      0x11D3A == code ||
      (0x11D3C <= code && code <= 0x11D3D) ||
      (0x11D3F <= code && code <= 0x11D45) ||
      0x11D47 == code ||
      (0x16AF0 <= code && code <= 0x16AF4) ||
      (0x16B30 <= code && code <= 0x16B36) ||
      (0x16F8F <= code && code <= 0x16F92) ||
      (0x1BC9D <= code && code <= 0x1BC9E) ||
      0x1D165 == code ||
      (0x1D167 <= code && code <= 0x1D169) ||
      (0x1D16E <= code && code <= 0x1D172) ||
      (0x1D17B <= code && code <= 0x1D182) ||
      (0x1D185 <= code && code <= 0x1D18B) ||
      (0x1D1AA <= code && code <= 0x1D1AD) ||
      (0x1D242 <= code && code <= 0x1D244) ||
      (0x1DA00 <= code && code <= 0x1DA36) ||
      (0x1DA3B <= code && code <= 0x1DA6C) ||
      0x1DA75 == code ||
      0x1DA84 == code ||
      (0x1DA9B <= code && code <= 0x1DA9F) ||
      (0x1DAA1 <= code && code <= 0x1DAAF) ||
      (0x1E000 <= code && code <= 0x1E006) ||
      (0x1E008 <= code && code <= 0x1E018) ||
      (0x1E01B <= code && code <= 0x1E021) ||
      (0x1E023 <= code && code <= 0x1E024) ||
      (0x1E026 <= code && code <= 0x1E02A) ||
      (0x1E8D0 <= code && code <= 0x1E8D6) ||
      (0x1E944 <= code && code <= 0x1E94A) ||
      (0xE0020 <= code && code <= 0xE007F) ||
      (0xE0100 <= code && code <= 0xE01EF)) {
    return Extend;
  }
  if ((0x1F1E6 <= code && code <= 0x1F1FF)) {
    return Regional_Indicator;
  }
  if (0x0903 == code ||
      0x093B == code ||
      (0x093E <= code && code <= 0x0940) ||
      (0x0949 <= code && code <= 0x094C) ||
      (0x094E <= code && code <= 0x094F) ||
      (0x0982 <= code && code <= 0x0983) ||
      (0x09BF <= code && code <= 0x09C0) ||
      (0x09C7 <= code && code <= 0x09C8) ||
      (0x09CB <= code && code <= 0x09CC) ||
      0x0A03 == code ||
      (0x0A3E <= code && code <= 0x0A40) ||
      0x0A83 == code ||
      (0x0ABE <= code && code <= 0x0AC0) ||
      0x0AC9 == code ||
      (0x0ACB <= code && code <= 0x0ACC) ||
      (0x0B02 <= code && code <= 0x0B03) ||
      0x0B40 == code ||
      (0x0B47 <= code && code <= 0x0B48) ||
      (0x0B4B <= code && code <= 0x0B4C) ||
      0x0BBF == code ||
      (0x0BC1 <= code && code <= 0x0BC2) ||
      (0x0BC6 <= code && code <= 0x0BC8) ||
      (0x0BCA <= code && code <= 0x0BCC) ||
      (0x0C01 <= code && code <= 0x0C03) ||
      (0x0C41 <= code && code <= 0x0C44) ||
      (0x0C82 <= code && code <= 0x0C83) ||
      0x0CBE == code ||
      (0x0CC0 <= code && code <= 0x0CC1) ||
      (0x0CC3 <= code && code <= 0x0CC4) ||
      (0x0CC7 <= code && code <= 0x0CC8) ||
      (0x0CCA <= code && code <= 0x0CCB) ||
      (0x0D02 <= code && code <= 0x0D03) ||
      (0x0D3F <= code && code <= 0x0D40) ||
      (0x0D46 <= code && code <= 0x0D48) ||
      (0x0D4A <= code && code <= 0x0D4C) ||
      (0x0D82 <= code && code <= 0x0D83) ||
      (0x0DD0 <= code && code <= 0x0DD1) ||
      (0x0DD8 <= code && code <= 0x0DDE) ||
      (0x0DF2 <= code && code <= 0x0DF3) ||
      0x0E33 == code ||
      0x0EB3 == code ||
      (0x0F3E <= code && code <= 0x0F3F) ||
      0x0F7F == code ||
      0x1031 == code ||
      (0x103B <= code && code <= 0x103C) ||
      (0x1056 <= code && code <= 0x1057) ||
      0x1084 == code ||
      0x17B6 == code ||
      (0x17BE <= code && code <= 0x17C5) ||
      (0x17C7 <= code && code <= 0x17C8) ||
      (0x1923 <= code && code <= 0x1926) ||
      (0x1929 <= code && code <= 0x192B) ||
      (0x1930 <= code && code <= 0x1931) ||
      (0x1933 <= code && code <= 0x1938) ||
      (0x1A19 <= code && code <= 0x1A1A) ||
      0x1A55 == code ||
      0x1A57 == code ||
      (0x1A6D <= code && code <= 0x1A72) ||
      0x1B04 == code ||
      0x1B35 == code ||
      0x1B3B == code ||
      (0x1B3D <= code && code <= 0x1B41) ||
      (0x1B43 <= code && code <= 0x1B44) ||
      0x1B82 == code ||
      0x1BA1 == code ||
      (0x1BA6 <= code && code <= 0x1BA7) ||
      0x1BAA == code ||
      0x1BE7 == code ||
      (0x1BEA <= code && code <= 0x1BEC) ||
      0x1BEE == code ||
      (0x1BF2 <= code && code <= 0x1BF3) ||
      (0x1C24 <= code && code <= 0x1C2B) ||
      (0x1C34 <= code && code <= 0x1C35) ||
      0x1CE1 == code ||
      (0x1CF2 <= code && code <= 0x1CF3) ||
      0x1CF7 == code ||
      (0xA823 <= code && code <= 0xA824) ||
      0xA827 == code ||
      (0xA880 <= code && code <= 0xA881) ||
      (0xA8B4 <= code && code <= 0xA8C3) ||
      (0xA952 <= code && code <= 0xA953) ||
      0xA983 == code ||
      (0xA9B4 <= code && code <= 0xA9B5) ||
      (0xA9BA <= code && code <= 0xA9BB) ||
      (0xA9BD <= code && code <= 0xA9C0) ||
      (0xAA2F <= code && code <= 0xAA30) ||
      (0xAA33 <= code && code <= 0xAA34) ||
      0xAA4D == code ||
      0xAAEB == code ||
      (0xAAEE <= code && code <= 0xAAEF) ||
      0xAAF5 == code ||
      (0xABE3 <= code && code <= 0xABE4) ||
      (0xABE6 <= code && code <= 0xABE7) ||
      (0xABE9 <= code && code <= 0xABEA) ||
      0xABEC == code ||
      0x11000 == code ||
      0x11002 == code ||
      0x11082 == code ||
      (0x110B0 <= code && code <= 0x110B2) ||
      (0x110B7 <= code && code <= 0x110B8) ||
      0x1112C == code ||
      0x11182 == code ||
      (0x111B3 <= code && code <= 0x111B5) ||
      (0x111BF <= code && code <= 0x111C0) ||
      (0x1122C <= code && code <= 0x1122E) ||
      (0x11232 <= code && code <= 0x11233) ||
      0x11235 == code ||
      (0x112E0 <= code && code <= 0x112E2) ||
      (0x11302 <= code && code <= 0x11303) ||
      0x1133F == code ||
      (0x11341 <= code && code <= 0x11344) ||
      (0x11347 <= code && code <= 0x11348) ||
      (0x1134B <= code && code <= 0x1134D) ||
      (0x11362 <= code && code <= 0x11363) ||
      (0x11435 <= code && code <= 0x11437) ||
      (0x11440 <= code && code <= 0x11441) ||
      0x11445 == code ||
      (0x114B1 <= code && code <= 0x114B2) ||
      0x114B9 == code ||
      (0x114BB <= code && code <= 0x114BC) ||
      0x114BE == code ||
      0x114C1 == code ||
      (0x115B0 <= code && code <= 0x115B1) ||
      (0x115B8 <= code && code <= 0x115BB) ||
      0x115BE == code ||
      (0x11630 <= code && code <= 0x11632) ||
      (0x1163B <= code && code <= 0x1163C) ||
      0x1163E == code ||
      0x116AC == code ||
      (0x116AE <= code && code <= 0x116AF) ||
      0x116B6 == code ||
      (0x11720 <= code && code <= 0x11721) ||
      0x11726 == code ||
      (0x11A07 <= code && code <= 0x11A08) ||
      0x11A39 == code ||
      (0x11A57 <= code && code <= 0x11A58) ||
      0x11A97 == code ||
      0x11C2F == code ||
      0x11C3E == code ||
      0x11CA9 == code ||
      0x11CB1 == code ||
      0x11CB4 == code ||
      (0x16F51 <= code && code <= 0x16F7E) ||
      0x1D166 == code ||
      0x1D16D == code) {
    return SpacingMark;
  }
  if ((0x1100 <= code && code <= 0x115F) ||
      (0xA960 <= code && code <= 0xA97C)) {
    return L;
  }
  if ((0x1160 <= code && code <= 0x11A7) ||
      (0xD7B0 <= code && code <= 0xD7C6)) {
    return V;
  }
  if ((0x11A8 <= code && code <= 0x11FF) ||
      (0xD7CB <= code && code <= 0xD7FB)) {
    return T;
  }
  if (0xAC00 == code ||
      0xAC1C == code ||
      0xAC38 == code ||
      0xAC54 == code ||
      0xAC70 == code ||
      0xAC8C == code ||
      0xACA8 == code ||
      0xACC4 == code ||
      0xACE0 == code ||
      0xACFC == code ||
      0xAD18 == code ||
      0xAD34 == code ||
      0xAD50 == code ||
      0xAD6C == code ||
      0xAD88 == code ||
      0xADA4 == code ||
      0xADC0 == code ||
      0xADDC == code ||
      0xADF8 == code ||
      0xAE14 == code ||
      0xAE30 == code ||
      0xAE4C == code ||
      0xAE68 == code ||
      0xAE84 == code ||
      0xAEA0 == code ||
      0xAEBC == code ||
      0xAED8 == code ||
      0xAEF4 == code ||
      0xAF10 == code ||
      0xAF2C == code ||
      0xAF48 == code ||
      0xAF64 == code ||
      0xAF80 == code ||
      0xAF9C == code ||
      0xAFB8 == code ||
      0xAFD4 == code ||
      0xAFF0 == code ||
      0xB00C == code ||
      0xB028 == code ||
      0xB044 == code ||
      0xB060 == code ||
      0xB07C == code ||
      0xB098 == code ||
      0xB0B4 == code ||
      0xB0D0 == code ||
      0xB0EC == code ||
      0xB108 == code ||
      0xB124 == code ||
      0xB140 == code ||
      0xB15C == code ||
      0xB178 == code ||
      0xB194 == code ||
      0xB1B0 == code ||
      0xB1CC == code ||
      0xB1E8 == code ||
      0xB204 == code ||
      0xB220 == code ||
      0xB23C == code ||
      0xB258 == code ||
      0xB274 == code ||
      0xB290 == code ||
      0xB2AC == code ||
      0xB2C8 == code ||
      0xB2E4 == code ||
      0xB300 == code ||
      0xB31C == code ||
      0xB338 == code ||
      0xB354 == code ||
      0xB370 == code ||
      0xB38C == code ||
      0xB3A8 == code ||
      0xB3C4 == code ||
      0xB3E0 == code ||
      0xB3FC == code ||
      0xB418 == code ||
      0xB434 == code ||
      0xB450 == code ||
      0xB46C == code ||
      0xB488 == code ||
      0xB4A4 == code ||
      0xB4C0 == code ||
      0xB4DC == code ||
      0xB4F8 == code ||
      0xB514 == code ||
      0xB530 == code ||
      0xB54C == code ||
      0xB568 == code ||
      0xB584 == code ||
      0xB5A0 == code ||
      0xB5BC == code ||
      0xB5D8 == code ||
      0xB5F4 == code ||
      0xB610 == code ||
      0xB62C == code ||
      0xB648 == code ||
      0xB664 == code ||
      0xB680 == code ||
      0xB69C == code ||
      0xB6B8 == code ||
      0xB6D4 == code ||
      0xB6F0 == code ||
      0xB70C == code ||
      0xB728 == code ||
      0xB744 == code ||
      0xB760 == code ||
      0xB77C == code ||
      0xB798 == code ||
      0xB7B4 == code ||
      0xB7D0 == code ||
      0xB7EC == code ||
      0xB808 == code ||
      0xB824 == code ||
      0xB840 == code ||
      0xB85C == code ||
      0xB878 == code ||
      0xB894 == code ||
      0xB8B0 == code ||
      0xB8CC == code ||
      0xB8E8 == code ||
      0xB904 == code ||
      0xB920 == code ||
      0xB93C == code ||
      0xB958 == code ||
      0xB974 == code ||
      0xB990 == code ||
      0xB9AC == code ||
      0xB9C8 == code ||
      0xB9E4 == code ||
      0xBA00 == code ||
      0xBA1C == code ||
      0xBA38 == code ||
      0xBA54 == code ||
      0xBA70 == code ||
      0xBA8C == code ||
      0xBAA8 == code ||
      0xBAC4 == code ||
      0xBAE0 == code ||
      0xBAFC == code ||
      0xBB18 == code ||
      0xBB34 == code ||
      0xBB50 == code ||
      0xBB6C == code ||
      0xBB88 == code ||
      0xBBA4 == code ||
      0xBBC0 == code ||
      0xBBDC == code ||
      0xBBF8 == code ||
      0xBC14 == code ||
      0xBC30 == code ||
      0xBC4C == code ||
      0xBC68 == code ||
      0xBC84 == code ||
      0xBCA0 == code ||
      0xBCBC == code ||
      0xBCD8 == code ||
      0xBCF4 == code ||
      0xBD10 == code ||
      0xBD2C == code ||
      0xBD48 == code ||
      0xBD64 == code ||
      0xBD80 == code ||
      0xBD9C == code ||
      0xBDB8 == code ||
      0xBDD4 == code ||
      0xBDF0 == code ||
      0xBE0C == code ||
      0xBE28 == code ||
      0xBE44 == code ||
      0xBE60 == code ||
      0xBE7C == code ||
      0xBE98 == code ||
      0xBEB4 == code ||
      0xBED0 == code ||
      0xBEEC == code ||
      0xBF08 == code ||
      0xBF24 == code ||
      0xBF40 == code ||
      0xBF5C == code ||
      0xBF78 == code ||
      0xBF94 == code ||
      0xBFB0 == code ||
      0xBFCC == code ||
      0xBFE8 == code ||
      0xC004 == code ||
      0xC020 == code ||
      0xC03C == code ||
      0xC058 == code ||
      0xC074 == code ||
      0xC090 == code ||
      0xC0AC == code ||
      0xC0C8 == code ||
      0xC0E4 == code ||
      0xC100 == code ||
      0xC11C == code ||
      0xC138 == code ||
      0xC154 == code ||
      0xC170 == code ||
      0xC18C == code ||
      0xC1A8 == code ||
      0xC1C4 == code ||
      0xC1E0 == code ||
      0xC1FC == code ||
      0xC218 == code ||
      0xC234 == code ||
      0xC250 == code ||
      0xC26C == code ||
      0xC288 == code ||
      0xC2A4 == code ||
      0xC2C0 == code ||
      0xC2DC == code ||
      0xC2F8 == code ||
      0xC314 == code ||
      0xC330 == code ||
      0xC34C == code ||
      0xC368 == code ||
      0xC384 == code ||
      0xC3A0 == code ||
      0xC3BC == code ||
      0xC3D8 == code ||
      0xC3F4 == code ||
      0xC410 == code ||
      0xC42C == code ||
      0xC448 == code ||
      0xC464 == code ||
      0xC480 == code ||
      0xC49C == code ||
      0xC4B8 == code ||
      0xC4D4 == code ||
      0xC4F0 == code ||
      0xC50C == code ||
      0xC528 == code ||
      0xC544 == code ||
      0xC560 == code ||
      0xC57C == code ||
      0xC598 == code ||
      0xC5B4 == code ||
      0xC5D0 == code ||
      0xC5EC == code ||
      0xC608 == code ||
      0xC624 == code ||
      0xC640 == code ||
      0xC65C == code ||
      0xC678 == code ||
      0xC694 == code ||
      0xC6B0 == code ||
      0xC6CC == code ||
      0xC6E8 == code ||
      0xC704 == code ||
      0xC720 == code ||
      0xC73C == code ||
      0xC758 == code ||
      0xC774 == code ||
      0xC790 == code ||
      0xC7AC == code ||
      0xC7C8 == code ||
      0xC7E4 == code ||
      0xC800 == code ||
      0xC81C == code ||
      0xC838 == code ||
      0xC854 == code ||
      0xC870 == code ||
      0xC88C == code ||
      0xC8A8 == code ||
      0xC8C4 == code ||
      0xC8E0 == code ||
      0xC8FC == code ||
      0xC918 == code ||
      0xC934 == code ||
      0xC950 == code ||
      0xC96C == code ||
      0xC988 == code ||
      0xC9A4 == code ||
      0xC9C0 == code ||
      0xC9DC == code ||
      0xC9F8 == code ||
      0xCA14 == code ||
      0xCA30 == code ||
      0xCA4C == code ||
      0xCA68 == code ||
      0xCA84 == code ||
      0xCAA0 == code ||
      0xCABC == code ||
      0xCAD8 == code ||
      0xCAF4 == code ||
      0xCB10 == code ||
      0xCB2C == code ||
      0xCB48 == code ||
      0xCB64 == code ||
      0xCB80 == code ||
      0xCB9C == code ||
      0xCBB8 == code ||
      0xCBD4 == code ||
      0xCBF0 == code ||
      0xCC0C == code ||
      0xCC28 == code ||
      0xCC44 == code ||
      0xCC60 == code ||
      0xCC7C == code ||
      0xCC98 == code ||
      0xCCB4 == code ||
      0xCCD0 == code ||
      0xCCEC == code ||
      0xCD08 == code ||
      0xCD24 == code ||
      0xCD40 == code ||
      0xCD5C == code ||
      0xCD78 == code ||
      0xCD94 == code ||
      0xCDB0 == code ||
      0xCDCC == code ||
      0xCDE8 == code ||
      0xCE04 == code ||
      0xCE20 == code ||
      0xCE3C == code ||
      0xCE58 == code ||
      0xCE74 == code ||
      0xCE90 == code ||
      0xCEAC == code ||
      0xCEC8 == code ||
      0xCEE4 == code ||
      0xCF00 == code ||
      0xCF1C == code ||
      0xCF38 == code ||
      0xCF54 == code ||
      0xCF70 == code ||
      0xCF8C == code ||
      0xCFA8 == code ||
      0xCFC4 == code ||
      0xCFE0 == code ||
      0xCFFC == code ||
      0xD018 == code ||
      0xD034 == code ||
      0xD050 == code ||
      0xD06C == code ||
      0xD088 == code ||
      0xD0A4 == code ||
      0xD0C0 == code ||
      0xD0DC == code ||
      0xD0F8 == code ||
      0xD114 == code ||
      0xD130 == code ||
      0xD14C == code ||
      0xD168 == code ||
      0xD184 == code ||
      0xD1A0 == code ||
      0xD1BC == code ||
      0xD1D8 == code ||
      0xD1F4 == code ||
      0xD210 == code ||
      0xD22C == code ||
      0xD248 == code ||
      0xD264 == code ||
      0xD280 == code ||
      0xD29C == code ||
      0xD2B8 == code ||
      0xD2D4 == code ||
      0xD2F0 == code ||
      0xD30C == code ||
      0xD328 == code ||
      0xD344 == code ||
      0xD360 == code ||
      0xD37C == code ||
      0xD398 == code ||
      0xD3B4 == code ||
      0xD3D0 == code ||
      0xD3EC == code ||
      0xD408 == code ||
      0xD424 == code ||
      0xD440 == code ||
      0xD45C == code ||
      0xD478 == code ||
      0xD494 == code ||
      0xD4B0 == code ||
      0xD4CC == code ||
      0xD4E8 == code ||
      0xD504 == code ||
      0xD520 == code ||
      0xD53C == code ||
      0xD558 == code ||
      0xD574 == code ||
      0xD590 == code ||
      0xD5AC == code ||
      0xD5C8 == code ||
      0xD5E4 == code ||
      0xD600 == code ||
      0xD61C == code ||
      0xD638 == code ||
      0xD654 == code ||
      0xD670 == code ||
      0xD68C == code ||
      0xD6A8 == code ||
      0xD6C4 == code ||
      0xD6E0 == code ||
      0xD6FC == code ||
      0xD718 == code ||
      0xD734 == code ||
      0xD750 == code ||
      0xD76C == code ||
      0xD788 == code) {
    return LV;
  }
  if ((0xAC01 <= code && code <= 0xAC1B) ||
      (0xAC1D <= code && code <= 0xAC37) ||
      (0xAC39 <= code && code <= 0xAC53) ||
      (0xAC55 <= code && code <= 0xAC6F) ||
      (0xAC71 <= code && code <= 0xAC8B) ||
      (0xAC8D <= code && code <= 0xACA7) ||
      (0xACA9 <= code && code <= 0xACC3) ||
      (0xACC5 <= code && code <= 0xACDF) ||
      (0xACE1 <= code && code <= 0xACFB) ||
      (0xACFD <= code && code <= 0xAD17) ||
      (0xAD19 <= code && code <= 0xAD33) ||
      (0xAD35 <= code && code <= 0xAD4F) ||
      (0xAD51 <= code && code <= 0xAD6B) ||
      (0xAD6D <= code && code <= 0xAD87) ||
      (0xAD89 <= code && code <= 0xADA3) ||
      (0xADA5 <= code && code <= 0xADBF) ||
      (0xADC1 <= code && code <= 0xADDB) ||
      (0xADDD <= code && code <= 0xADF7) ||
      (0xADF9 <= code && code <= 0xAE13) ||
      (0xAE15 <= code && code <= 0xAE2F) ||
      (0xAE31 <= code && code <= 0xAE4B) ||
      (0xAE4D <= code && code <= 0xAE67) ||
      (0xAE69 <= code && code <= 0xAE83) ||
      (0xAE85 <= code && code <= 0xAE9F) ||
      (0xAEA1 <= code && code <= 0xAEBB) ||
      (0xAEBD <= code && code <= 0xAED7) ||
      (0xAED9 <= code && code <= 0xAEF3) ||
      (0xAEF5 <= code && code <= 0xAF0F) ||
      (0xAF11 <= code && code <= 0xAF2B) ||
      (0xAF2D <= code && code <= 0xAF47) ||
      (0xAF49 <= code && code <= 0xAF63) ||
      (0xAF65 <= code && code <= 0xAF7F) ||
      (0xAF81 <= code && code <= 0xAF9B) ||
      (0xAF9D <= code && code <= 0xAFB7) ||
      (0xAFB9 <= code && code <= 0xAFD3) ||
      (0xAFD5 <= code && code <= 0xAFEF) ||
      (0xAFF1 <= code && code <= 0xB00B) ||
      (0xB00D <= code && code <= 0xB027) ||
      (0xB029 <= code && code <= 0xB043) ||
      (0xB045 <= code && code <= 0xB05F) ||
      (0xB061 <= code && code <= 0xB07B) ||
      (0xB07D <= code && code <= 0xB097) ||
      (0xB099 <= code && code <= 0xB0B3) ||
      (0xB0B5 <= code && code <= 0xB0CF) ||
      (0xB0D1 <= code && code <= 0xB0EB) ||
      (0xB0ED <= code && code <= 0xB107) ||
      (0xB109 <= code && code <= 0xB123) ||
      (0xB125 <= code && code <= 0xB13F) ||
      (0xB141 <= code && code <= 0xB15B) ||
      (0xB15D <= code && code <= 0xB177) ||
      (0xB179 <= code && code <= 0xB193) ||
      (0xB195 <= code && code <= 0xB1AF) ||
      (0xB1B1 <= code && code <= 0xB1CB) ||
      (0xB1CD <= code && code <= 0xB1E7) ||
      (0xB1E9 <= code && code <= 0xB203) ||
      (0xB205 <= code && code <= 0xB21F) ||
      (0xB221 <= code && code <= 0xB23B) ||
      (0xB23D <= code && code <= 0xB257) ||
      (0xB259 <= code && code <= 0xB273) ||
      (0xB275 <= code && code <= 0xB28F) ||
      (0xB291 <= code && code <= 0xB2AB) ||
      (0xB2AD <= code && code <= 0xB2C7) ||
      (0xB2C9 <= code && code <= 0xB2E3) ||
      (0xB2E5 <= code && code <= 0xB2FF) ||
      (0xB301 <= code && code <= 0xB31B) ||
      (0xB31D <= code && code <= 0xB337) ||
      (0xB339 <= code && code <= 0xB353) ||
      (0xB355 <= code && code <= 0xB36F) ||
      (0xB371 <= code && code <= 0xB38B) ||
      (0xB38D <= code && code <= 0xB3A7) ||
      (0xB3A9 <= code && code <= 0xB3C3) ||
      (0xB3C5 <= code && code <= 0xB3DF) ||
      (0xB3E1 <= code && code <= 0xB3FB) ||
      (0xB3FD <= code && code <= 0xB417) ||
      (0xB419 <= code && code <= 0xB433) ||
      (0xB435 <= code && code <= 0xB44F) ||
      (0xB451 <= code && code <= 0xB46B) ||
      (0xB46D <= code && code <= 0xB487) ||
      (0xB489 <= code && code <= 0xB4A3) ||
      (0xB4A5 <= code && code <= 0xB4BF) ||
      (0xB4C1 <= code && code <= 0xB4DB) ||
      (0xB4DD <= code && code <= 0xB4F7) ||
      (0xB4F9 <= code && code <= 0xB513) ||
      (0xB515 <= code && code <= 0xB52F) ||
      (0xB531 <= code && code <= 0xB54B) ||
      (0xB54D <= code && code <= 0xB567) ||
      (0xB569 <= code && code <= 0xB583) ||
      (0xB585 <= code && code <= 0xB59F) ||
      (0xB5A1 <= code && code <= 0xB5BB) ||
      (0xB5BD <= code && code <= 0xB5D7) ||
      (0xB5D9 <= code && code <= 0xB5F3) ||
      (0xB5F5 <= code && code <= 0xB60F) ||
      (0xB611 <= code && code <= 0xB62B) ||
      (0xB62D <= code && code <= 0xB647) ||
      (0xB649 <= code && code <= 0xB663) ||
      (0xB665 <= code && code <= 0xB67F) ||
      (0xB681 <= code && code <= 0xB69B) ||
      (0xB69D <= code && code <= 0xB6B7) ||
      (0xB6B9 <= code && code <= 0xB6D3) ||
      (0xB6D5 <= code && code <= 0xB6EF) ||
      (0xB6F1 <= code && code <= 0xB70B) ||
      (0xB70D <= code && code <= 0xB727) ||
      (0xB729 <= code && code <= 0xB743) ||
      (0xB745 <= code && code <= 0xB75F) ||
      (0xB761 <= code && code <= 0xB77B) ||
      (0xB77D <= code && code <= 0xB797) ||
      (0xB799 <= code && code <= 0xB7B3) ||
      (0xB7B5 <= code && code <= 0xB7CF) ||
      (0xB7D1 <= code && code <= 0xB7EB) ||
      (0xB7ED <= code && code <= 0xB807) ||
      (0xB809 <= code && code <= 0xB823) ||
      (0xB825 <= code && code <= 0xB83F) ||
      (0xB841 <= code && code <= 0xB85B) ||
      (0xB85D <= code && code <= 0xB877) ||
      (0xB879 <= code && code <= 0xB893) ||
      (0xB895 <= code && code <= 0xB8AF) ||
      (0xB8B1 <= code && code <= 0xB8CB) ||
      (0xB8CD <= code && code <= 0xB8E7) ||
      (0xB8E9 <= code && code <= 0xB903) ||
      (0xB905 <= code && code <= 0xB91F) ||
      (0xB921 <= code && code <= 0xB93B) ||
      (0xB93D <= code && code <= 0xB957) ||
      (0xB959 <= code && code <= 0xB973) ||
      (0xB975 <= code && code <= 0xB98F) ||
      (0xB991 <= code && code <= 0xB9AB) ||
      (0xB9AD <= code && code <= 0xB9C7) ||
      (0xB9C9 <= code && code <= 0xB9E3) ||
      (0xB9E5 <= code && code <= 0xB9FF) ||
      (0xBA01 <= code && code <= 0xBA1B) ||
      (0xBA1D <= code && code <= 0xBA37) ||
      (0xBA39 <= code && code <= 0xBA53) ||
      (0xBA55 <= code && code <= 0xBA6F) ||
      (0xBA71 <= code && code <= 0xBA8B) ||
      (0xBA8D <= code && code <= 0xBAA7) ||
      (0xBAA9 <= code && code <= 0xBAC3) ||
      (0xBAC5 <= code && code <= 0xBADF) ||
      (0xBAE1 <= code && code <= 0xBAFB) ||
      (0xBAFD <= code && code <= 0xBB17) ||
      (0xBB19 <= code && code <= 0xBB33) ||
      (0xBB35 <= code && code <= 0xBB4F) ||
      (0xBB51 <= code && code <= 0xBB6B) ||
      (0xBB6D <= code && code <= 0xBB87) ||
      (0xBB89 <= code && code <= 0xBBA3) ||
      (0xBBA5 <= code && code <= 0xBBBF) ||
      (0xBBC1 <= code && code <= 0xBBDB) ||
      (0xBBDD <= code && code <= 0xBBF7) ||
      (0xBBF9 <= code && code <= 0xBC13) ||
      (0xBC15 <= code && code <= 0xBC2F) ||
      (0xBC31 <= code && code <= 0xBC4B) ||
      (0xBC4D <= code && code <= 0xBC67) ||
      (0xBC69 <= code && code <= 0xBC83) ||
      (0xBC85 <= code && code <= 0xBC9F) ||
      (0xBCA1 <= code && code <= 0xBCBB) ||
      (0xBCBD <= code && code <= 0xBCD7) ||
      (0xBCD9 <= code && code <= 0xBCF3) ||
      (0xBCF5 <= code && code <= 0xBD0F) ||
      (0xBD11 <= code && code <= 0xBD2B) ||
      (0xBD2D <= code && code <= 0xBD47) ||
      (0xBD49 <= code && code <= 0xBD63) ||
      (0xBD65 <= code && code <= 0xBD7F) ||
      (0xBD81 <= code && code <= 0xBD9B) ||
      (0xBD9D <= code && code <= 0xBDB7) ||
      (0xBDB9 <= code && code <= 0xBDD3) ||
      (0xBDD5 <= code && code <= 0xBDEF) ||
      (0xBDF1 <= code && code <= 0xBE0B) ||
      (0xBE0D <= code && code <= 0xBE27) ||
      (0xBE29 <= code && code <= 0xBE43) ||
      (0xBE45 <= code && code <= 0xBE5F) ||
      (0xBE61 <= code && code <= 0xBE7B) ||
      (0xBE7D <= code && code <= 0xBE97) ||
      (0xBE99 <= code && code <= 0xBEB3) ||
      (0xBEB5 <= code && code <= 0xBECF) ||
      (0xBED1 <= code && code <= 0xBEEB) ||
      (0xBEED <= code && code <= 0xBF07) ||
      (0xBF09 <= code && code <= 0xBF23) ||
      (0xBF25 <= code && code <= 0xBF3F) ||
      (0xBF41 <= code && code <= 0xBF5B) ||
      (0xBF5D <= code && code <= 0xBF77) ||
      (0xBF79 <= code && code <= 0xBF93) ||
      (0xBF95 <= code && code <= 0xBFAF) ||
      (0xBFB1 <= code && code <= 0xBFCB) ||
      (0xBFCD <= code && code <= 0xBFE7) ||
      (0xBFE9 <= code && code <= 0xC003) ||
      (0xC005 <= code && code <= 0xC01F) ||
      (0xC021 <= code && code <= 0xC03B) ||
      (0xC03D <= code && code <= 0xC057) ||
      (0xC059 <= code && code <= 0xC073) ||
      (0xC075 <= code && code <= 0xC08F) ||
      (0xC091 <= code && code <= 0xC0AB) ||
      (0xC0AD <= code && code <= 0xC0C7) ||
      (0xC0C9 <= code && code <= 0xC0E3) ||
      (0xC0E5 <= code && code <= 0xC0FF) ||
      (0xC101 <= code && code <= 0xC11B) ||
      (0xC11D <= code && code <= 0xC137) ||
      (0xC139 <= code && code <= 0xC153) ||
      (0xC155 <= code && code <= 0xC16F) ||
      (0xC171 <= code && code <= 0xC18B) ||
      (0xC18D <= code && code <= 0xC1A7) ||
      (0xC1A9 <= code && code <= 0xC1C3) ||
      (0xC1C5 <= code && code <= 0xC1DF) ||
      (0xC1E1 <= code && code <= 0xC1FB) ||
      (0xC1FD <= code && code <= 0xC217) ||
      (0xC219 <= code && code <= 0xC233) ||
      (0xC235 <= code && code <= 0xC24F) ||
      (0xC251 <= code && code <= 0xC26B) ||
      (0xC26D <= code && code <= 0xC287) ||
      (0xC289 <= code && code <= 0xC2A3) ||
      (0xC2A5 <= code && code <= 0xC2BF) ||
      (0xC2C1 <= code && code <= 0xC2DB) ||
      (0xC2DD <= code && code <= 0xC2F7) ||
      (0xC2F9 <= code && code <= 0xC313) ||
      (0xC315 <= code && code <= 0xC32F) ||
      (0xC331 <= code && code <= 0xC34B) ||
      (0xC34D <= code && code <= 0xC367) ||
      (0xC369 <= code && code <= 0xC383) ||
      (0xC385 <= code && code <= 0xC39F) ||
      (0xC3A1 <= code && code <= 0xC3BB) ||
      (0xC3BD <= code && code <= 0xC3D7) ||
      (0xC3D9 <= code && code <= 0xC3F3) ||
      (0xC3F5 <= code && code <= 0xC40F) ||
      (0xC411 <= code && code <= 0xC42B) ||
      (0xC42D <= code && code <= 0xC447) ||
      (0xC449 <= code && code <= 0xC463) ||
      (0xC465 <= code && code <= 0xC47F) ||
      (0xC481 <= code && code <= 0xC49B) ||
      (0xC49D <= code && code <= 0xC4B7) ||
      (0xC4B9 <= code && code <= 0xC4D3) ||
      (0xC4D5 <= code && code <= 0xC4EF) ||
      (0xC4F1 <= code && code <= 0xC50B) ||
      (0xC50D <= code && code <= 0xC527) ||
      (0xC529 <= code && code <= 0xC543) ||
      (0xC545 <= code && code <= 0xC55F) ||
      (0xC561 <= code && code <= 0xC57B) ||
      (0xC57D <= code && code <= 0xC597) ||
      (0xC599 <= code && code <= 0xC5B3) ||
      (0xC5B5 <= code && code <= 0xC5CF) ||
      (0xC5D1 <= code && code <= 0xC5EB) ||
      (0xC5ED <= code && code <= 0xC607) ||
      (0xC609 <= code && code <= 0xC623) ||
      (0xC625 <= code && code <= 0xC63F) ||
      (0xC641 <= code && code <= 0xC65B) ||
      (0xC65D <= code && code <= 0xC677) ||
      (0xC679 <= code && code <= 0xC693) ||
      (0xC695 <= code && code <= 0xC6AF) ||
      (0xC6B1 <= code && code <= 0xC6CB) ||
      (0xC6CD <= code && code <= 0xC6E7) ||
      (0xC6E9 <= code && code <= 0xC703) ||
      (0xC705 <= code && code <= 0xC71F) ||
      (0xC721 <= code && code <= 0xC73B) ||
      (0xC73D <= code && code <= 0xC757) ||
      (0xC759 <= code && code <= 0xC773) ||
      (0xC775 <= code && code <= 0xC78F) ||
      (0xC791 <= code && code <= 0xC7AB) ||
      (0xC7AD <= code && code <= 0xC7C7) ||
      (0xC7C9 <= code && code <= 0xC7E3) ||
      (0xC7E5 <= code && code <= 0xC7FF) ||
      (0xC801 <= code && code <= 0xC81B) ||
      (0xC81D <= code && code <= 0xC837) ||
      (0xC839 <= code && code <= 0xC853) ||
      (0xC855 <= code && code <= 0xC86F) ||
      (0xC871 <= code && code <= 0xC88B) ||
      (0xC88D <= code && code <= 0xC8A7) ||
      (0xC8A9 <= code && code <= 0xC8C3) ||
      (0xC8C5 <= code && code <= 0xC8DF) ||
      (0xC8E1 <= code && code <= 0xC8FB) ||
      (0xC8FD <= code && code <= 0xC917) ||
      (0xC919 <= code && code <= 0xC933) ||
      (0xC935 <= code && code <= 0xC94F) ||
      (0xC951 <= code && code <= 0xC96B) ||
      (0xC96D <= code && code <= 0xC987) ||
      (0xC989 <= code && code <= 0xC9A3) ||
      (0xC9A5 <= code && code <= 0xC9BF) ||
      (0xC9C1 <= code && code <= 0xC9DB) ||
      (0xC9DD <= code && code <= 0xC9F7) ||
      (0xC9F9 <= code && code <= 0xCA13) ||
      (0xCA15 <= code && code <= 0xCA2F) ||
      (0xCA31 <= code && code <= 0xCA4B) ||
      (0xCA4D <= code && code <= 0xCA67) ||
      (0xCA69 <= code && code <= 0xCA83) ||
      (0xCA85 <= code && code <= 0xCA9F) ||
      (0xCAA1 <= code && code <= 0xCABB) ||
      (0xCABD <= code && code <= 0xCAD7) ||
      (0xCAD9 <= code && code <= 0xCAF3) ||
      (0xCAF5 <= code && code <= 0xCB0F) ||
      (0xCB11 <= code && code <= 0xCB2B) ||
      (0xCB2D <= code && code <= 0xCB47) ||
      (0xCB49 <= code && code <= 0xCB63) ||
      (0xCB65 <= code && code <= 0xCB7F) ||
      (0xCB81 <= code && code <= 0xCB9B) ||
      (0xCB9D <= code && code <= 0xCBB7) ||
      (0xCBB9 <= code && code <= 0xCBD3) ||
      (0xCBD5 <= code && code <= 0xCBEF) ||
      (0xCBF1 <= code && code <= 0xCC0B) ||
      (0xCC0D <= code && code <= 0xCC27) ||
      (0xCC29 <= code && code <= 0xCC43) ||
      (0xCC45 <= code && code <= 0xCC5F) ||
      (0xCC61 <= code && code <= 0xCC7B) ||
      (0xCC7D <= code && code <= 0xCC97) ||
      (0xCC99 <= code && code <= 0xCCB3) ||
      (0xCCB5 <= code && code <= 0xCCCF) ||
      (0xCCD1 <= code && code <= 0xCCEB) ||
      (0xCCED <= code && code <= 0xCD07) ||
      (0xCD09 <= code && code <= 0xCD23) ||
      (0xCD25 <= code && code <= 0xCD3F) ||
      (0xCD41 <= code && code <= 0xCD5B) ||
      (0xCD5D <= code && code <= 0xCD77) ||
      (0xCD79 <= code && code <= 0xCD93) ||
      (0xCD95 <= code && code <= 0xCDAF) ||
      (0xCDB1 <= code && code <= 0xCDCB) ||
      (0xCDCD <= code && code <= 0xCDE7) ||
      (0xCDE9 <= code && code <= 0xCE03) ||
      (0xCE05 <= code && code <= 0xCE1F) ||
      (0xCE21 <= code && code <= 0xCE3B) ||
      (0xCE3D <= code && code <= 0xCE57) ||
      (0xCE59 <= code && code <= 0xCE73) ||
      (0xCE75 <= code && code <= 0xCE8F) ||
      (0xCE91 <= code && code <= 0xCEAB) ||
      (0xCEAD <= code && code <= 0xCEC7) ||
      (0xCEC9 <= code && code <= 0xCEE3) ||
      (0xCEE5 <= code && code <= 0xCEFF) ||
      (0xCF01 <= code && code <= 0xCF1B) ||
      (0xCF1D <= code && code <= 0xCF37) ||
      (0xCF39 <= code && code <= 0xCF53) ||
      (0xCF55 <= code && code <= 0xCF6F) ||
      (0xCF71 <= code && code <= 0xCF8B) ||
      (0xCF8D <= code && code <= 0xCFA7) ||
      (0xCFA9 <= code && code <= 0xCFC3) ||
      (0xCFC5 <= code && code <= 0xCFDF) ||
      (0xCFE1 <= code && code <= 0xCFFB) ||
      (0xCFFD <= code && code <= 0xD017) ||
      (0xD019 <= code && code <= 0xD033) ||
      (0xD035 <= code && code <= 0xD04F) ||
      (0xD051 <= code && code <= 0xD06B) ||
      (0xD06D <= code && code <= 0xD087) ||
      (0xD089 <= code && code <= 0xD0A3) ||
      (0xD0A5 <= code && code <= 0xD0BF) ||
      (0xD0C1 <= code && code <= 0xD0DB) ||
      (0xD0DD <= code && code <= 0xD0F7) ||
      (0xD0F9 <= code && code <= 0xD113) ||
      (0xD115 <= code && code <= 0xD12F) ||
      (0xD131 <= code && code <= 0xD14B) ||
      (0xD14D <= code && code <= 0xD167) ||
      (0xD169 <= code && code <= 0xD183) ||
      (0xD185 <= code && code <= 0xD19F) ||
      (0xD1A1 <= code && code <= 0xD1BB) ||
      (0xD1BD <= code && code <= 0xD1D7) ||
      (0xD1D9 <= code && code <= 0xD1F3) ||
      (0xD1F5 <= code && code <= 0xD20F) ||
      (0xD211 <= code && code <= 0xD22B) ||
      (0xD22D <= code && code <= 0xD247) ||
      (0xD249 <= code && code <= 0xD263) ||
      (0xD265 <= code && code <= 0xD27F) ||
      (0xD281 <= code && code <= 0xD29B) ||
      (0xD29D <= code && code <= 0xD2B7) ||
      (0xD2B9 <= code && code <= 0xD2D3) ||
      (0xD2D5 <= code && code <= 0xD2EF) ||
      (0xD2F1 <= code && code <= 0xD30B) ||
      (0xD30D <= code && code <= 0xD327) ||
      (0xD329 <= code && code <= 0xD343) ||
      (0xD345 <= code && code <= 0xD35F) ||
      (0xD361 <= code && code <= 0xD37B) ||
      (0xD37D <= code && code <= 0xD397) ||
      (0xD399 <= code && code <= 0xD3B3) ||
      (0xD3B5 <= code && code <= 0xD3CF) ||
      (0xD3D1 <= code && code <= 0xD3EB) ||
      (0xD3ED <= code && code <= 0xD407) ||
      (0xD409 <= code && code <= 0xD423) ||
      (0xD425 <= code && code <= 0xD43F) ||
      (0xD441 <= code && code <= 0xD45B) ||
      (0xD45D <= code && code <= 0xD477) ||
      (0xD479 <= code && code <= 0xD493) ||
      (0xD495 <= code && code <= 0xD4AF) ||
      (0xD4B1 <= code && code <= 0xD4CB) ||
      (0xD4CD <= code && code <= 0xD4E7) ||
      (0xD4E9 <= code && code <= 0xD503) ||
      (0xD505 <= code && code <= 0xD51F) ||
      (0xD521 <= code && code <= 0xD53B) ||
      (0xD53D <= code && code <= 0xD557) ||
      (0xD559 <= code && code <= 0xD573) ||
      (0xD575 <= code && code <= 0xD58F) ||
      (0xD591 <= code && code <= 0xD5AB) ||
      (0xD5AD <= code && code <= 0xD5C7) ||
      (0xD5C9 <= code && code <= 0xD5E3) ||
      (0xD5E5 <= code && code <= 0xD5FF) ||
      (0xD601 <= code && code <= 0xD61B) ||
      (0xD61D <= code && code <= 0xD637) ||
      (0xD639 <= code && code <= 0xD653) ||
      (0xD655 <= code && code <= 0xD66F) ||
      (0xD671 <= code && code <= 0xD68B) ||
      (0xD68D <= code && code <= 0xD6A7) ||
      (0xD6A9 <= code && code <= 0xD6C3) ||
      (0xD6C5 <= code && code <= 0xD6DF) ||
      (0xD6E1 <= code && code <= 0xD6FB) ||
      (0xD6FD <= code && code <= 0xD717) ||
      (0xD719 <= code && code <= 0xD733) ||
      (0xD735 <= code && code <= 0xD74F) ||
      (0xD751 <= code && code <= 0xD76B) ||
      (0xD76D <= code && code <= 0xD787) ||
      (0xD789 <= code && code <= 0xD7A3)) {
    return LVT;
  }
  if (0x261D == code ||
      0x26F9 == code ||
      (0x270A <= code && code <= 0x270D) ||
      0x1F385 == code ||
      (0x1F3C2 <= code && code <= 0x1F3C4) ||
      0x1F3C7 == code ||
      (0x1F3CA <= code && code <= 0x1F3CC) ||
      (0x1F442 <= code && code <= 0x1F443) ||
      (0x1F446 <= code && code <= 0x1F450) ||
      0x1F46E == code ||
      (0x1F470 <= code && code <= 0x1F478) ||
      0x1F47C == code ||
      (0x1F481 <= code && code <= 0x1F483) ||
      (0x1F485 <= code && code <= 0x1F487) ||
      0x1F4AA == code ||
      (0x1F574 <= code && code <= 0x1F575) ||
      0x1F57A == code ||
      0x1F590 == code ||
      (0x1F595 <= code && code <= 0x1F596) ||
      (0x1F645 <= code && code <= 0x1F647) ||
      (0x1F64B <= code && code <= 0x1F64F) ||
      0x1F6A3 == code ||
      (0x1F6B4 <= code && code <= 0x1F6B6) ||
      0x1F6C0 == code ||
      0x1F6CC == code ||
      (0x1F918 <= code && code <= 0x1F91C) ||
      (0x1F91E <= code && code <= 0x1F91F) ||
      0x1F926 == code ||
      (0x1F930 <= code && code <= 0x1F939) ||
      (0x1F93D <= code && code <= 0x1F93E) ||
      (0x1F9D1 <= code && code <= 0x1F9DD)) {
    return E_Base;
  }
  if ((0x1F3FB <= code && code <= 0x1F3FF)) {
    return E_Modifier;
  }
  if (0x200D == code) {
    return ZWJ;
  }
  if (0x2640 == code ||
      0x2642 == code ||
      (0x2695 <= code && code <= 0x2696) ||
      0x2708 == code ||
      0x2764 == code ||
      0x1F308 == code ||
      0x1F33E == code ||
      0x1F373 == code ||
      0x1F393 == code ||
      0x1F3A4 == code ||
      0x1F3A8 == code ||
      0x1F3EB == code ||
      0x1F3ED == code ||
      0x1F48B == code ||
      (0x1F4BB <= code && code <= 0x1F4BC) ||
      0x1F527 == code ||
      0x1F52C == code ||
      0x1F5E8 == code ||
      0x1F680 == code ||
      0x1F692 == code) {
    return Glue_After_Zwj;
  }
  if ((0x1F466 <= code && code <= 0x1F469)) {
    return E_Base_GAZ;
  }
  return Other;
}

class GraphemeSplitter {
  int nextBreak(String string, [int? index]) {
    index ??= 0;
    if (index < 0) {
      return 0;
    }
    if (index >= string.length - 1) {
      return string.length;
    }
    final prev = getGraphemeBreakProperty(_codePointAt(string, index));
    final mid = <int>[];
    for (var i = index + 1; i < string.length; i++) {
      if (_isSurrogate(string, i - 1)) {
        continue;
      }
      final next = getGraphemeBreakProperty(_codePointAt(string, i));
      if (shouldBreak(prev, mid, next) != 0) {
        return i;
      }
      mid.add(next);
    }
    return string.length;
  }

  Iterable<String> splitGraphemes(String str) {
    final res = <String>[];
    var index = 0;
    int brk;
    while ((brk = nextBreak(str, index)) < str.length) {
      res.add(str.substring(index, brk));
      index = brk;
    }
    if (index < str.length) {
      res.add(str.substring(index));
    }
    return res;
  }

  Iterable<String> iterateGraphemes(String str) sync* {
    var index = 0;
    String value;
    int brk;
    while (true) {
      if ((brk = nextBreak(str, index)) < str.length) {
        value = str.substring(index, brk);
        index = brk;
        yield value;
      } else if (index < str.length) {
        value = str.substring(index);
        index = str.length;
        yield value;
      } else {
        break;
      }
    }
  }

  int countGraphemes(String str) {
    var count = 0;
    var index = 0;
    int brk;
    while ((brk = nextBreak(str, index)) < str.length) {
      index = brk;
      count++;
    }
    if (index < str.length) {
      count++;
    }
    return count;
  }
}
