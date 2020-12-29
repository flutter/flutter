// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// Whether or not "Noto Sans Symbols" and "Noto Color Emoji" fonts have been
/// downloaded. We download these as fallbacks when no other font covers the
/// given code units.
bool _downloadedSymbolsAndEmoji = false;

final Set<int> codeUnitsWithNoKnownFont = <int>{};

Future<void> _findFontsForMissingCodeunits(List<int> codeunits) async {
  _ensureNotoFontTreeCreated();
  // If all of the code units are known to have no Noto Font which covers them,
  // then just give up. We have already logged a warning.
  if (codeunits.every((u) => codeUnitsWithNoKnownFont.contains(u))) {
    return;
  }
  Set<_NotoFont> fonts = <_NotoFont>{};
  Set<int> coveredCodeUnits = <int>{};
  Set<int> missingCodeUnits = <int>{};
  for (int codeunit in codeunits) {
    List<_NotoFont> fontsForUnit = _lookupNotoFontsForCodeunit(codeunit);
    fonts.addAll(fontsForUnit);
    if (fontsForUnit.isNotEmpty) {
      coveredCodeUnits.add(codeunit);
    } else {
      missingCodeUnits.add(codeunit);
    }
  }
  fonts = _findMinimumFontsForCodeunits(coveredCodeUnits, fonts);
  for (_NotoFont font in fonts) {
    if (_resolvedNotoFonts[font] == null) {
      String googleFontCss = await html.window
          .fetch(font.googleFontsCssUrl)
          .then((dynamic response) =>
              response.text().then<String>((dynamic x) => x as String));
      final _ResolvedNotoFont resolvedFont =
          _makeResolvedNotoFontFromCss(googleFontCss, font.name);
      _registerResolvedFont(font, resolvedFont);
    }
  }

  Set<_ResolvedNotoSubset> resolvedFonts = <_ResolvedNotoSubset>{};
  for (int codeunit in coveredCodeUnits) {
    resolvedFonts.addAll(_lookupResolvedFontsForCodeunit(codeunit));
  }

  for (_ResolvedNotoSubset resolvedFont in resolvedFonts) {
    skiaFontCollection.registerFallbackFont(
        resolvedFont.url, resolvedFont.name);
  }

  if (missingCodeUnits.isNotEmpty) {
    if (!_downloadedSymbolsAndEmoji) {
      await _registerSymbolsAndEmoji();
    } else {
      html.window.console
          .log('Could not find a Noto font to display all missing characters. '
              'Please add a font asset for the missing characters.');
      codeUnitsWithNoKnownFont.addAll(missingCodeUnits);
    }
  }
  await skiaFontCollection.ensureFontsLoaded();
  sendFontChangeMessage();
}

/// Parse the CSS file for a font and make a list of resolved subsets.
///
/// A CSS file from Google Fonts looks like this:
///
///     /* [0] */
///     @font-face {
///       font-family: 'Noto Sans KR';
///       font-style: normal;
///       font-weight: 400;
///       src: url(https://fonts.gstatic.com/s/notosanskr/v13/PbykFmXiEBPT4ITbgNA5Cgm20xz64px_1hVWr0wuPNGmlQNMEfD4.0.woff2) format('woff2');
///       unicode-range: U+f9ca-fa0b, U+ff03-ff05, U+ff07, U+ff0a-ff0b, U+ff0d-ff19, U+ff1b, U+ff1d, U+ff20-ff5b, U+ff5d, U+ffe0-ffe3, U+ffe5-ffe6;
///     }
///     /* [1] */
///     @font-face {
///       font-family: 'Noto Sans KR';
///       font-style: normal;
///       font-weight: 400;
///       src: url(https://fonts.gstatic.com/s/notosanskr/v13/PbykFmXiEBPT4ITbgNA5Cgm20xz64px_1hVWr0wuPNGmlQNMEfD4.1.woff2) format('woff2');
///       unicode-range: U+f92f-f980, U+f982-f9c9;
///     }
///     /* [2] */
///     @font-face {
///       font-family: 'Noto Sans KR';
///       font-style: normal;
///       font-weight: 400;
///       src: url(https://fonts.gstatic.com/s/notosanskr/v13/PbykFmXiEBPT4ITbgNA5Cgm20xz64px_1hVWr0wuPNGmlQNMEfD4.2.woff2) format('woff2');
///       unicode-range: U+d723-d728, U+d72a-d733, U+d735-d748, U+d74a-d74f, U+d752-d753, U+d755-d757, U+d75a-d75f, U+d762-d764, U+d766-d768, U+d76a-d76b, U+d76d-d76f, U+d771-d787, U+d789-d78b, U+d78d-d78f, U+d791-d797, U+d79a, U+d79c, U+d79e-d7a3, U+f900-f909, U+f90b-f92e;
///     }
_ResolvedNotoFont _makeResolvedNotoFontFromCss(String css, String name) {
  List<_ResolvedNotoSubset> subsets = <_ResolvedNotoSubset>[];
  bool resolvingFontFace = false;
  String? fontFaceUrl;
  List<_UnicodeRange>? fontFaceUnicodeRanges;
  for (final String line in LineSplitter.split(css)) {
    // Search for the beginning of a @font-face.
    if (!resolvingFontFace) {
      if (line == '@font-face {') {
        resolvingFontFace = true;
      } else {
        continue;
      }
    } else {
      // We are resolving a @font-face, read out the url and ranges.
      if (line.startsWith('  src:')) {
        int urlStart = line.indexOf('url(');
        if (urlStart == -1) {
          throw new Exception('Unable to resolve Noto font URL: $line');
        }
        int urlEnd = line.indexOf(')');
        fontFaceUrl = line.substring(urlStart + 4, urlEnd);
      } else if (line.startsWith('  unicode-range:')) {
        fontFaceUnicodeRanges = <_UnicodeRange>[];
        String rangeString = line.substring(17, line.length - 1);
        List<String> rawRanges = rangeString.split(', ');
        for (final String rawRange in rawRanges) {
          List<String> startEnd = rawRange.split('-');
          if (startEnd.length == 1) {
            String singleRange = startEnd.single;
            assert(singleRange.startsWith('U+'));
            int rangeValue = int.parse(singleRange.substring(2), radix: 16);
            fontFaceUnicodeRanges.add(_UnicodeRange(rangeValue, rangeValue));
          } else {
            assert(startEnd.length == 2);
            String startRange = startEnd[0];
            String endRange = startEnd[1];
            assert(startRange.startsWith('U+'));
            int startValue = int.parse(startRange.substring(2), radix: 16);
            int endValue = int.parse(endRange, radix: 16);
            fontFaceUnicodeRanges.add(_UnicodeRange(startValue, endValue));
          }
        }
      } else if (line == '}') {
        subsets.add(
            _ResolvedNotoSubset(fontFaceUrl!, name, fontFaceUnicodeRanges!));
        resolvingFontFace = false;
      } else {
        continue;
      }
    }
  }

  return _ResolvedNotoFont(name, subsets);
}

void _registerResolvedFont(_NotoFont font, _ResolvedNotoFont resolvedFont) {
  _resolvedNotoFonts[font] = resolvedFont;

  for (_ResolvedNotoSubset subset in resolvedFont.subsets) {
    for (_UnicodeRange range in subset.ranges) {
      _resolvedNotoTreeRoot = _insertNotoFontRange<_ResolvedNotoSubset>(
          range, subset, _resolvedNotoTreeRoot);
    }
  }

  assert(
      _verifyNotoTree(_resolvedNotoTreeRoot),
      'Resolved Noto tree is invalid: '
      '${_verifyNotoSubtree(_resolvedNotoTreeRoot).reason}');
}

/// In the case where none of the known Noto Fonts cover a set of code units,
/// try the Symbols and Emoji fonts. We don't know the exact range of code units
/// that are covered by these fonts, so we download them and hope for the best.
Future<void> _registerSymbolsAndEmoji() async {
  const String symbolsUrl =
      'https://fonts.googleapis.com/css2?family=Noto+Sans+Symbols';
  const String emojiUrl =
      'https://fonts.googleapis.com/css2?family=Noto+Color+Emoji+Compat';

  String symbolsCss = await html.window.fetch(symbolsUrl).then(
      (dynamic response) =>
          response.text().then<String>((dynamic x) => x as String));
  String emojiCss = await html.window.fetch(emojiUrl).then((dynamic response) =>
      response.text().then<String>((dynamic x) => x as String));

  String extractUrlFromCss(String css) {
    for (final String line in LineSplitter.split(css)) {
      if (line.startsWith('  src:')) {
        int urlStart = line.indexOf('url(');
        if (urlStart == -1) {
          throw new Exception('Unable to resolve Noto font URL: $line');
        }
        int urlEnd = line.indexOf(')');
        return line.substring(urlStart + 4, urlEnd);
      }
    }
    throw Exception('Unable to determine URL for Noto font');
  }

  String symbolsFontUrl = extractUrlFromCss(symbolsCss);
  String emojiFontUrl = extractUrlFromCss(emojiCss);

  skiaFontCollection.registerFallbackFont(symbolsFontUrl, 'Noto Sans Symbols');
  skiaFontCollection.registerFallbackFont(
      emojiFontUrl, 'Noto Color Emoji Compat');
  _downloadedSymbolsAndEmoji = true;
}

/// Finds the minimum set of fonts which covers all of the [codeunits].
///
/// Since set cover is NP-complete, we approximate using a greedy algorithm
/// which finds the font which covers the most codeunits. If multiple CJK
/// fonts match the same number of codeunits, we choose one based on the user's
/// locale.
Set<_NotoFont> _findMinimumFontsForCodeunits(
    Iterable<int> codeunits, Set<_NotoFont> fonts) {
  List<int> unmatchedCodeunits = List<int>.from(codeunits);
  Set<_NotoFont> minimumFonts = <_NotoFont>{};
  List<_NotoFont> bestFonts = <_NotoFont>[];
  int maxCodeunitsCovered = 0;

  String language = html.window.navigator.language;

  // This is guaranteed to terminate because [codeunits] is a list of fonts
  // which we've already determined are covered by [fonts].
  while (unmatchedCodeunits.isNotEmpty) {
    for (var font in fonts) {
      int codeunitsCovered = 0;
      for (int codeunit in unmatchedCodeunits) {
        if (font.matchesCodeunit(codeunit)) {
          codeunitsCovered++;
        }
      }
      if (codeunitsCovered > maxCodeunitsCovered) {
        bestFonts.clear();
        bestFonts.add(font);
        maxCodeunitsCovered = codeunitsCovered;
      } else if (codeunitsCovered == maxCodeunitsCovered) {
        bestFonts.add(font);
      }
    }
    assert(bestFonts.isNotEmpty);
    // If the list of best fonts are all CJK fonts, choose the best one based
    // on locale. Otherwise just choose the first font.
    _NotoFont bestFont = bestFonts.first;
    if (bestFonts.length > 1) {
      if (bestFonts.every((font) => _cjkFonts.contains(font))) {
        if (language == 'zh-Hans' ||
            language == 'zh-CN' ||
            language == 'zh-SG' ||
            language == 'zh-MY') {
          if (bestFonts.contains(_notoSansSC)) {
            bestFont = _notoSansSC;
          }
        } else if (language == 'zh-Hant' ||
            language == 'zh-TW' ||
            language == 'zh-MO') {
          if (bestFonts.contains(_notoSansTC)) {
            bestFont = _notoSansTC;
          }
        } else if (language == 'zh-HK') {
          if (bestFonts.contains(_notoSansHK)) {
            bestFont = _notoSansHK;
          }
        } else if (language == 'ja') {
          if (bestFonts.contains(_notoSansJP)) {
            bestFont = _notoSansJP;
          }
        }
      }
    }
    unmatchedCodeunits
        .removeWhere((codeunit) => bestFont.matchesCodeunit(codeunit));
    minimumFonts.add(bestFont);
  }
  return minimumFonts;
}

void _ensureNotoFontTreeCreated() {
  if (_notoTreeRoot != null) {
    return;
  }

  for (_NotoFont font in _notoFonts) {
    for (_UnicodeRange range in font.unicodeRanges) {
      _notoTreeRoot =
          _insertNotoFontRange<_NotoFont>(range, font, _notoTreeRoot);
    }
  }

  assert(
      _verifyNotoTree(_notoTreeRoot),
      'The Noto font tree is invalid: '
      '${_verifyNotoSubtree(_notoTreeRoot).reason}');
}

List<_NotoFont> _lookupNotoFontsForCodeunit(int codeunit) {
  List<_NotoFont> lookupHelper(_NotoTreeNode<_NotoFont> node) {
    if (node.range.contains(codeunit)) {
      return node.fonts;
    }
    if (node.range.start > codeunit) {
      if (node.left != null) {
        return lookupHelper(node.left!);
      } else {
        return const <_NotoFont>[];
      }
    } else {
      if (node.right != null) {
        return lookupHelper(node.right!);
      } else {
        return const <_NotoFont>[];
      }
    }
  }

  return lookupHelper(_notoTreeRoot!);
}

List<_ResolvedNotoSubset> _lookupResolvedFontsForCodeunit(int codeunit) {
  List<_ResolvedNotoSubset> lookupHelper(
      _NotoTreeNode<_ResolvedNotoSubset> node) {
    if (node.range.contains(codeunit)) {
      return node.fonts;
    }
    if (node.range.start > codeunit) {
      if (node.left != null) {
        return lookupHelper(node.left!);
      } else {
        return const <_ResolvedNotoSubset>[];
      }
    } else {
      if (node.right != null) {
        return lookupHelper(node.right!);
      } else {
        return const <_ResolvedNotoSubset>[];
      }
    }
  }

  return lookupHelper(_resolvedNotoTreeRoot!);
}

class _NotoFont {
  final String name;
  final List<_UnicodeRange> unicodeRanges;

  const _NotoFont(this.name, this.unicodeRanges);

  bool matchesCodeunit(int codeunit) {
    for (_UnicodeRange range in unicodeRanges) {
      if (range.contains(codeunit)) {
        return true;
      }
    }
    return false;
  }

  String get googleFontsCssUrl =>
      'https://fonts.googleapis.com/css2?family=${name.replaceAll(' ', '+')}';
}

class _UnicodeRange {
  final int start;
  final int end;

  const _UnicodeRange(this.start, this.end);

  bool contains(int codeUnit) {
    return start <= codeUnit && codeUnit <= end;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! _UnicodeRange) {
      return false;
    }
    _UnicodeRange range = other;
    return range.start == start && range.end == end;
  }

  @override
  int get hashCode => ui.hashValues(start, end);
}

class _ResolvedNotoFont {
  final String name;
  final List<_ResolvedNotoSubset> subsets;

  const _ResolvedNotoFont(this.name, this.subsets);
}

class _ResolvedNotoSubset {
  final String url;
  final String name;
  final List<_UnicodeRange> ranges;

  const _ResolvedNotoSubset(this.url, this.name, this.ranges);
}

const _NotoFont _notoSansSC = _NotoFont('Noto Sans SC', <_UnicodeRange>[
  _UnicodeRange(12288, 12591),
  _UnicodeRange(12800, 13311),
  _UnicodeRange(19968, 40959),
  _UnicodeRange(65072, 65135),
  _UnicodeRange(65280, 65519),
]);

const _NotoFont _notoSansTC = _NotoFont('Noto Sans TC', <_UnicodeRange>[
  _UnicodeRange(12288, 12351),
  _UnicodeRange(12549, 12585),
  _UnicodeRange(19968, 40959),
]);

const _NotoFont _notoSansHK = _NotoFont('Noto Sans HK', <_UnicodeRange>[
  _UnicodeRange(12288, 12351),
  _UnicodeRange(12549, 12585),
  _UnicodeRange(19968, 40959),
]);

const _NotoFont _notoSansJP = _NotoFont('Noto Sans JP', <_UnicodeRange>[
  _UnicodeRange(12288, 12543),
  _UnicodeRange(19968, 40959),
  _UnicodeRange(65280, 65519),
]);

const List<_NotoFont> _cjkFonts = <_NotoFont>[
  _notoSansSC,
  _notoSansTC,
  _notoSansHK,
  _notoSansJP,
];

const List<_NotoFont> _notoFonts = <_NotoFont>[
  _notoSansSC,
  _notoSansTC,
  _notoSansHK,
  _notoSansJP,
  _NotoFont('Noto Naskh Arabic UI', <_UnicodeRange>[
    _UnicodeRange(1536, 1791),
    _UnicodeRange(8204, 8206),
    _UnicodeRange(8208, 8209),
    _UnicodeRange(8271, 8271),
    _UnicodeRange(11841, 11841),
    _UnicodeRange(64336, 65023),
    _UnicodeRange(65132, 65276),
  ]),
  _NotoFont('Noto Sans Armenian', <_UnicodeRange>[
    _UnicodeRange(1328, 1424),
    _UnicodeRange(64275, 64279),
  ]),
  _NotoFont('Noto Sans Bengali UI', <_UnicodeRange>[
    _UnicodeRange(2404, 2405),
    _UnicodeRange(2433, 2555),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(8377, 8377),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Myanmar UI', <_UnicodeRange>[
    _UnicodeRange(4096, 4255),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Egyptian Hieroglyphs', <_UnicodeRange>[
    _UnicodeRange(77824, 78894),
  ]),
  _NotoFont('Noto Sans Ethiopic', <_UnicodeRange>[
    _UnicodeRange(4608, 5017),
    _UnicodeRange(11648, 11742),
    _UnicodeRange(43777, 43822),
  ]),
  _NotoFont('Noto Sans Georgian', <_UnicodeRange>[
    _UnicodeRange(1417, 1417),
    _UnicodeRange(4256, 4351),
    _UnicodeRange(11520, 11567),
  ]),
  _NotoFont('Noto Sans Gujarati UI', <_UnicodeRange>[
    _UnicodeRange(2404, 2405),
    _UnicodeRange(2688, 2815),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(8377, 8377),
    _UnicodeRange(9676, 9676),
    _UnicodeRange(43056, 43065),
  ]),
  _NotoFont('Noto Sans Gurmukhi UI', <_UnicodeRange>[
    _UnicodeRange(2404, 2405),
    _UnicodeRange(2561, 2677),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(8377, 8377),
    _UnicodeRange(9676, 9676),
    _UnicodeRange(9772, 9772),
    _UnicodeRange(43056, 43065),
  ]),
  _NotoFont('Noto Sans Hebrew', <_UnicodeRange>[
    _UnicodeRange(1424, 1535),
    _UnicodeRange(8362, 8362),
    _UnicodeRange(9676, 9676),
    _UnicodeRange(64285, 64335),
  ]),
  _NotoFont('Noto Sans Devanagari UI', <_UnicodeRange>[
    _UnicodeRange(2304, 2431),
    _UnicodeRange(7376, 7414),
    _UnicodeRange(7416, 7417),
    _UnicodeRange(8204, 9205),
    _UnicodeRange(8360, 8360),
    _UnicodeRange(8377, 8377),
    _UnicodeRange(9676, 9676),
    _UnicodeRange(43056, 43065),
    _UnicodeRange(43232, 43259),
  ]),
  _NotoFont('Noto Sans Kannada UI', <_UnicodeRange>[
    _UnicodeRange(2404, 2405),
    _UnicodeRange(3202, 3314),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(8377, 8377),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Khmer UI', <_UnicodeRange>[
    _UnicodeRange(6016, 6143),
    _UnicodeRange(8204, 8204),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans KR', <_UnicodeRange>[
    _UnicodeRange(12593, 12686),
    _UnicodeRange(12800, 12828),
    _UnicodeRange(12896, 12923),
    _UnicodeRange(44032, 55215),
  ]),
  _NotoFont('Noto Sans Lao UI', <_UnicodeRange>[
    _UnicodeRange(3713, 3807),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Malayalam UI', <_UnicodeRange>[
    _UnicodeRange(775, 775),
    _UnicodeRange(803, 803),
    _UnicodeRange(2404, 2405),
    _UnicodeRange(3330, 3455),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(8377, 8377),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Sinhala', <_UnicodeRange>[
    _UnicodeRange(2404, 2405),
    _UnicodeRange(3458, 3572),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Tamil UI', <_UnicodeRange>[
    _UnicodeRange(2404, 2405),
    _UnicodeRange(2946, 3066),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(8377, 8377),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Telugu UI', <_UnicodeRange>[
    _UnicodeRange(2385, 2386),
    _UnicodeRange(2404, 2405),
    _UnicodeRange(3072, 3199),
    _UnicodeRange(7386, 7386),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans Thai UI', <_UnicodeRange>[
    _UnicodeRange(3585, 3675),
    _UnicodeRange(8204, 8205),
    _UnicodeRange(9676, 9676),
  ]),
  _NotoFont('Noto Sans', <_UnicodeRange>[
    _UnicodeRange(0, 255),
    _UnicodeRange(305, 305),
    _UnicodeRange(338, 339),
    _UnicodeRange(699, 700),
    _UnicodeRange(710, 710),
    _UnicodeRange(730, 730),
    _UnicodeRange(732, 732),
    _UnicodeRange(8192, 8303),
    _UnicodeRange(8308, 8308),
    _UnicodeRange(8364, 8364),
    _UnicodeRange(8482, 8482),
    _UnicodeRange(8593, 8593),
    _UnicodeRange(8595, 8595),
    _UnicodeRange(8722, 8722),
    _UnicodeRange(8725, 8725),
    _UnicodeRange(65279, 65279),
    _UnicodeRange(65533, 65533),
    _UnicodeRange(1024, 1119),
    _UnicodeRange(1168, 1169),
    _UnicodeRange(1200, 1201),
    _UnicodeRange(8470, 8470),
    _UnicodeRange(1120, 1327),
    _UnicodeRange(7296, 7304),
    _UnicodeRange(8372, 8372),
    _UnicodeRange(11744, 11775),
    _UnicodeRange(42560, 42655),
    _UnicodeRange(65070, 65071),
    _UnicodeRange(880, 1023),
    _UnicodeRange(7936, 8191),
    _UnicodeRange(256, 591),
    _UnicodeRange(601, 601),
    _UnicodeRange(7680, 7935),
    _UnicodeRange(8224, 8224),
    _UnicodeRange(8352, 8363),
    _UnicodeRange(8365, 8399),
    _UnicodeRange(8467, 8467),
    _UnicodeRange(11360, 11391),
    _UnicodeRange(42784, 43007),
    _UnicodeRange(258, 259),
    _UnicodeRange(272, 273),
    _UnicodeRange(296, 297),
    _UnicodeRange(360, 361),
    _UnicodeRange(416, 417),
    _UnicodeRange(431, 432),
    _UnicodeRange(7840, 7929),
    _UnicodeRange(8363, 8363),
  ]),
];

// TODO(hterkelsen): Add unit tests for the Red-Black tree code.

/// A node in a red-black tree for Noto Fonts.
class _NotoTreeNode<T> {
  _NotoTreeNode<T>? parent;
  _NotoTreeNode<T>? left;
  _NotoTreeNode<T>? right;

  /// If `true`, then this node is black. Otherwise it is red.
  bool isBlack = false;
  bool get isRed => !isBlack;

  final _UnicodeRange range;
  final List<T> fonts;

  _NotoTreeNode(this.range) : this.fonts = <T>[];
}

/// Associates [range] with [font] in the Noto Font tree.
///
/// Returns the root node.
_NotoTreeNode<T> _insertNotoFontRange<T>(
    _UnicodeRange range, T font, _NotoTreeNode<T>? root) {
  _NotoTreeNode<T>? newNode = _insertNotoFontRangeHelper(root, range, font);
  if (newNode != null) {
    _repairNotoFontTree(newNode);

    // Make sure the root node is correctly set.
    _NotoTreeNode<T> newRoot = newNode;
    while (newRoot.parent != null) {
      newRoot = newRoot.parent!;
    }

    return newRoot;
  }
  return root!;
}

/// Recurses the font tree and associates [range] with [font].
///
/// If a new node is created, it is returned so we can repair the tree.
_NotoTreeNode<T>? _insertNotoFontRangeHelper<T>(
    _NotoTreeNode<T>? root, _UnicodeRange range, T font) {
  if (root != null) {
    if (root.range == range) {
      // The root node range is the same as the range we're inserting.
      root.fonts.add(font);
      return null;
    }
    if (range.start < root.range.start) {
      assert(range.end < root.range.start,
          'Overlapping Unicode range in Noto Tree');
      if (root.left != null) {
        return _insertNotoFontRangeHelper<T>(root.left, range, font);
      } else {
        _NotoTreeNode<T> newNode = _NotoTreeNode<T>(range);
        newNode.fonts.add(font);
        newNode.parent = root;
        root.left = newNode;
        return newNode;
      }
    } else {
      assert(root.range.end < range.start,
          'Overlapping Unicode range in Noto Tree');
      if (root.right != null) {
        return _insertNotoFontRangeHelper<T>(root.right, range, font);
      } else {
        _NotoTreeNode<T> newNode = _NotoTreeNode<T>(range);
        newNode.fonts.add(font);
        newNode.parent = root;
        root.right = newNode;
        return newNode;
      }
    }
  } else {
    // If [root] is null, then the tree is empty. Create a new root.
    _NotoTreeNode<T> newRoot = _NotoTreeNode<T>(range);
    newRoot.fonts.add(font);
    return newRoot;
  }
}

void _rotateLeft(_NotoTreeNode node) {
  // We will only ever call this on nodes which have a right child.
  _NotoTreeNode newNode = node.right!;
  _NotoTreeNode? parent = node.parent;

  node.right = newNode.left;
  newNode.left = node;
  node.parent = newNode;
  if (node.right != null) {
    node.right!.parent = node;
  }

  if (parent != null) {
    if (node == parent.left) {
      parent.left = newNode;
    } else {
      parent.right = newNode;
    }
  }

  newNode.parent = parent;
}

void _rotateRight(_NotoTreeNode node) {
  // We will only ever call this on nodes which have a left child.
  _NotoTreeNode newNode = node.left!;
  _NotoTreeNode? parent = node.parent;

  node.left = newNode.right;
  newNode.right = node;
  node.parent = newNode;

  if (node.left != null) {
    node.left!.parent = node;
  }

  if (parent != null) {
    if (node == parent.left) {
      parent.left = newNode;
    } else {
      parent.right = newNode;
    }
  }

  newNode.parent = parent;
}

void _repairNotoFontTree(_NotoTreeNode node) {
  if (node.parent == null) {
    // This is the root node. The root node must be black.
    node.isBlack = true;
    return;
  } else if (node.parent!.isBlack) {
    // Do nothing.
    return;
  }

  // If we've reached here, then (1) node's parent is non-null and (2) node's
  // parent is red, which means that node's parent is not the root node and
  // therefore (3) node's grandparent is not null;

  _NotoTreeNode parent = node.parent!;
  _NotoTreeNode grandparent = parent.parent!;

  _NotoTreeNode? uncle;
  if (parent == grandparent.left) {
    uncle = grandparent.right;
  } else {
    uncle = grandparent.left;
  }
  if (uncle != null && uncle.isRed) {
    parent.isBlack = true;
    uncle.isBlack = true;
    grandparent.isBlack = false;
    _repairNotoFontTree(grandparent);
    return;
  }

  if (node == parent.right && parent == grandparent.left) {
    _rotateLeft(parent);
    node = node.left!;
  } else if (node == parent.left && parent == grandparent.right) {
    _rotateRight(parent);
    node = node.right!;
  }

  parent = node.parent!;
  grandparent = parent.parent!;

  if (node == parent.left) {
    _rotateRight(grandparent);
  } else {
    _rotateLeft(grandparent);
  }

  parent.isBlack = true;
  grandparent.isBlack = false;
}

bool _verifyNotoTree(_NotoTreeNode? root) {
  _VerifyNotoTreeResult result = _verifyNotoSubtree(root);
  return result.isValid;
}

_VerifyNotoTreeResult _verifyNotoSubtree(_NotoTreeNode? node) {
  if (node == null) {
    // Leaves of the tree are represented as null nodes. Leaf nodes are black.
    return _VerifyNotoTreeResult(true, 1);
  }
  if (node.parent == null) {
    // This is the root node of the tree. The root node must be black.
    if (!node.isBlack) {
      return _VerifyNotoTreeResult(false, 0, 'Root node is red');
    }
  }

  int blackNodesOnPath = 0;
  if (node.isRed) {
    // Both of a red tree node's children must be black.
    if ((node.left != null && !node.left!.isBlack) ||
        (node.right != null && !node.right!.isBlack)) {
      return _VerifyNotoTreeResult(false, -1, 'Red node has a red child');
    }
  } else {
    blackNodesOnPath = 1;
  }

  _VerifyNotoTreeResult leftResult = _verifyNotoSubtree(node.left);
  _VerifyNotoTreeResult rightResult = _verifyNotoSubtree(node.right);

  if (!leftResult.isValid) {
    return leftResult;
  } else if (!rightResult.isValid) {
    return rightResult;
  } else if (leftResult.blackNodesOnPath != rightResult.blackNodesOnPath) {
    return _VerifyNotoTreeResult(
        false,
        -1,
        "The number of black nodes on the path from "
        "root to leaf isn't the same for all leaves");
  }

  return _VerifyNotoTreeResult(
      true, blackNodesOnPath + leftResult.blackNodesOnPath);
}

class _VerifyNotoTreeResult {
  /// Whether or not the tree conforms to the Red-Black tree invariants.
  final bool isValid;

  /// The number of black nodes on the path from the node to the root.
  final int blackNodesOnPath;

  /// A human-readable reason why the tree is invalid.
  final String? reason;

  const _VerifyNotoTreeResult(this.isValid, this.blackNodesOnPath,
      [this.reason]);
}

/// The root of the unresolved Noto font Red-Black Tree.
_NotoTreeNode<_NotoFont>? _notoTreeRoot;

/// The root of the resolved Noto font Red-Black Tree.
_NotoTreeNode<_ResolvedNotoSubset>? _resolvedNotoTreeRoot;

Map<_NotoFont, _ResolvedNotoFont> _resolvedNotoFonts =
    <_NotoFont, _ResolvedNotoFont>{};
