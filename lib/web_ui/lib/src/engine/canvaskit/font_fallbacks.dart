// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../util.dart';
import 'canvaskit_api.dart';
import 'fonts.dart';
import 'initialization.dart';
import 'interval_tree.dart';

/// Global static font fallback data.
class FontFallbackData {
  static FontFallbackData get instance => _instance;
  static FontFallbackData _instance = FontFallbackData();

  /// Resets the fallback font data.
  ///
  /// After calling this method fallback fonts will be loaded from scratch.
  ///
  /// Used for tests.
  static void debugReset() {
    _instance = FontFallbackData();
  }

  /// Whether or not "Noto Sans Symbols" and "Noto Color Emoji" fonts have been
  /// downloaded. We download these as fallbacks when no other font covers the
  /// given code units.
  bool registeredSymbolsAndEmoji = false;

  /// Code units that no known font has a glyph for.
  final Set<int> codeUnitsWithNoKnownFont = <int>{};

  /// Code units which are known to be covered by at least one fallback font.
  final Set<int> knownCoveredCodeUnits = <int>{};

  /// Index of all font families by code unit range.
  final IntervalTree<NotoFont> notoTree = createNotoFontTree();

  static IntervalTree<NotoFont> createNotoFontTree() {
    Map<NotoFont, List<CodeunitRange>> ranges =
        <NotoFont, List<CodeunitRange>>{};

    for (NotoFont font in _notoFonts) {
      // TODO(yjbanov): instead of mutating the font tree during reset, it's
      //                better to construct an immutable tree of resolved fonts
      //                pointing back to the original NotoFont objects. Then
      //                resetting the tree would be a matter of reconstructing
      //                the new resolved tree.
      font.reset();
      for (CodeunitRange range in font.approximateUnicodeRanges) {
        ranges.putIfAbsent(font, () => <CodeunitRange>[]).add(range);
      }
    }

    return IntervalTree<NotoFont>.createFromRanges(ranges);
  }

  /// Fallback fonts which have been registered and loaded.
  final List<RegisteredFont> registeredFallbackFonts = <RegisteredFont>[];

  final List<String> globalFontFallbacks = <String>['Roboto'];

  final Map<String, int> fontFallbackCounts = <String, int>{};

  /// A list of code units to check against the global fallback fonts.
  final Set<int> _codeUnitsToCheckAgainstFallbackFonts = <int>{};

  /// This is [true] if we have scheduled a check for missing code units.
  ///
  /// We only do this once a frame, since checking if a font supports certain
  /// code units is very expensive.
  bool _scheduledCodeUnitCheck = false;

  /// Determines if the given [text] contains any code points which are not
  /// supported by the current set of fonts.
  void ensureFontsSupportText(String text, List<String> fontFamilies) {
    // TODO(hterkelsen): Make this faster for the common case where the text
    // is supported by the given fonts.

    // If the text is ASCII, then skip this check.
    bool isAscii = true;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) >= 160) {
        isAscii = false;
        break;
      }
    }
    if (isAscii) {
      return;
    }

    // We have a cache of code units which are known to be covered by at least
    // one of our fallback fonts, and a cache of code units which are known not
    // to be covered by any fallback font. From the given text, construct a set
    // of code units which need to be checked.
    final Set<int> runesToCheck = <int>{};
    for (final int rune in text.runes) {
      // Filter out code units which ASCII, known to be covered, or known not
      // to be covered.
      if (!(rune < 160 ||
          knownCoveredCodeUnits.contains(rune) ||
          codeUnitsWithNoKnownFont.contains(rune))) {
        runesToCheck.add(rune);
      }
    }
    if (runesToCheck.isEmpty) {
      return;
    }

    final List<int> codeUnits = runesToCheck.toList();

    List<SkFont> fonts = <SkFont>[];
    for (var font in fontFamilies) {
      List<SkFont>? typefacesForFamily =
          skiaFontCollection.familyToFontMap[font];
      if (typefacesForFamily != null) {
        fonts.addAll(typefacesForFamily);
      }
    }
    List<bool> codeUnitsSupported = List<bool>.filled(codeUnits.length, false);
    String testString = String.fromCharCodes(codeUnits);
    for (SkFont font in fonts) {
      Uint8List glyphs = font.getGlyphIDs(testString);
      assert(glyphs.length == codeUnitsSupported.length);
      for (int i = 0; i < glyphs.length; i++) {
        codeUnitsSupported[i] |= glyphs[i] != 0 || _isControlCode(codeUnits[i]);
      }
    }

    if (codeUnitsSupported.any((x) => !x)) {
      List<int> missingCodeUnits = <int>[];
      for (int i = 0; i < codeUnitsSupported.length; i++) {
        if (!codeUnitsSupported[i]) {
          missingCodeUnits.add(codeUnits[i]);
        }
      }
      _codeUnitsToCheckAgainstFallbackFonts.addAll(missingCodeUnits);
      if (!_scheduledCodeUnitCheck) {
        _scheduledCodeUnitCheck = true;
        // ignore: invalid_use_of_visible_for_testing_member
        EnginePlatformDispatcher.instance.rasterizer!
            .addPostFrameCallback(_ensureFallbackFonts);
      }
    }
  }

  /// Returns [true] if [codepoint] is a Unicode control code.
  bool _isControlCode(int codepoint) {
    return codepoint < 32 || (codepoint > 127 && codepoint < 160);
  }

  /// Checks the missing code units against the current set of fallback fonts
  /// and starts downloading new fallback fonts if the current set can't cover
  /// the code units.
  void _ensureFallbackFonts() {
    _scheduledCodeUnitCheck = false;
    // We don't know if the remaining code units are covered by our fallback
    // fonts. Check them and update the cache.
    List<int> codeUnits = _codeUnitsToCheckAgainstFallbackFonts.toList();
    _codeUnitsToCheckAgainstFallbackFonts.clear();
    List<bool> codeUnitsSupported = List<bool>.filled(codeUnits.length, false);
    String testString = String.fromCharCodes(codeUnits);

    for (String font in globalFontFallbacks) {
      List<SkFont>? fontsForFamily = skiaFontCollection.familyToFontMap[font];
      if (fontsForFamily == null) {
        printWarning('A fallback font was registered but we '
            'cannot retrieve the typeface for it.');
        continue;
      }
      for (SkFont font in fontsForFamily) {
        Uint8List glyphs = font.getGlyphIDs(testString);
        assert(glyphs.length == codeUnitsSupported.length);
        for (int i = 0; i < glyphs.length; i++) {
          bool codeUnitSupported = glyphs[i] != 0;
          if (codeUnitSupported) {
            knownCoveredCodeUnits.add(codeUnits[i]);
          }
          codeUnitsSupported[i] |=
              codeUnitSupported || _isControlCode(codeUnits[i]);
        }
      }

      // Once we've checked every typeface for this family, check to see if
      // every code unit has been covered in order to avoid unnecessary checks.
      bool keepGoing = false;
      for (bool supported in codeUnitsSupported) {
        if (!supported) {
          keepGoing = true;
          break;
        }
      }

      if (!keepGoing) {
        return;
      }
    }

    // If we reached here, then there are some code units which aren't covered
    // by the global fallback fonts. Remove the ones which were covered and
    // try to find fallback fonts which cover them.
    for (int i = codeUnits.length - 1; i >= 0; i--) {
      if (codeUnitsSupported[i]) {
        codeUnits.removeAt(i);
      }
    }
    findFontsForMissingCodeunits(codeUnits);
  }

  void registerFallbackFont(String family, Uint8List bytes) {
    final SkTypeface? typeface =
        canvasKit.FontMgr.RefDefault().MakeTypefaceFromData(bytes);
    if (typeface == null) {
      printWarning('Failed to parse fallback font $family as a font.');
      return;
    }
    fontFallbackCounts.putIfAbsent(family, () => 0);
    int fontFallbackTag = fontFallbackCounts[family]!;
    fontFallbackCounts[family] = fontFallbackCounts[family]! + 1;
    String countedFamily = '$family $fontFallbackTag';
    registeredFallbackFonts.add(RegisteredFont(bytes, countedFamily, typeface));
    globalFontFallbacks.add(countedFamily);
  }
}

Future<void> findFontsForMissingCodeunits(List<int> codeUnits) async {
  final FontFallbackData data = FontFallbackData.instance;

  Set<NotoFont> fonts = <NotoFont>{};
  Set<int> coveredCodeUnits = <int>{};
  Set<int> missingCodeUnits = <int>{};
  for (int codeUnit in codeUnits) {
    List<NotoFont> fontsForUnit = data.notoTree.intersections(codeUnit);
    fonts.addAll(fontsForUnit);
    if (fontsForUnit.isNotEmpty) {
      coveredCodeUnits.add(codeUnit);
    } else {
      missingCodeUnits.add(codeUnit);
    }
  }

  for (NotoFont font in fonts) {
    await font.ensureResolved();
  }

  // The call to `findMinimumFontsForCodeUnits` will remove all code units that
  // were matched by `fonts` from `unmatchedCodeUnits`.
  final Set<int> unmatchedCodeUnits = Set<int>.from(coveredCodeUnits);
  fonts = findMinimumFontsForCodeUnits(unmatchedCodeUnits, fonts);

  Set<_ResolvedNotoSubset> resolvedFonts = <_ResolvedNotoSubset>{};
  for (int codeUnit in coveredCodeUnits) {
    for (NotoFont font in fonts) {
      if (font.resolvedFont == null) {
        // We failed to resolve the font earlier.
        continue;
      }
      resolvedFonts.addAll(font.resolvedFont!.tree.intersections(codeUnit));
    }
  }

  for (_ResolvedNotoSubset resolvedFont in resolvedFonts) {
    notoDownloadQueue.add(resolvedFont);
  }

  // We looked through the Noto font tree and didn't find any font families
  // covering some code units, or we did find a font family, but when we
  // downloaded the fonts we found that they actually didn't cover them. So
  // we try looking them up in the symbols and emojis fonts.
  if (missingCodeUnits.isNotEmpty || unmatchedCodeUnits.isNotEmpty) {
    if (!data.registeredSymbolsAndEmoji) {
      _registerSymbolsAndEmoji();
    } else {
      if (!notoDownloadQueue.isPending) {
        printWarning(
            'Could not find a set of Noto fonts to display all missing '
            'characters. Please add a font asset for the missing characters.'
            ' See: https://flutter.dev/docs/cookbook/design/fonts');
        data.codeUnitsWithNoKnownFont.addAll(missingCodeUnits);
      }
    }
  }
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
_ResolvedNotoFont? _makeResolvedNotoFontFromCss(String css, String name) {
  List<_ResolvedNotoSubset> subsets = <_ResolvedNotoSubset>[];
  bool resolvingFontFace = false;
  String? fontFaceUrl;
  List<CodeunitRange>? fontFaceUnicodeRanges;
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
          printWarning('Unable to resolve Noto font URL: $line');
          return null;
        }
        int urlEnd = line.indexOf(')');
        fontFaceUrl = line.substring(urlStart + 4, urlEnd);
      } else if (line.startsWith('  unicode-range:')) {
        fontFaceUnicodeRanges = <CodeunitRange>[];
        String rangeString = line.substring(17, line.length - 1);
        List<String> rawRanges = rangeString.split(', ');
        for (final String rawRange in rawRanges) {
          List<String> startEnd = rawRange.split('-');
          if (startEnd.length == 1) {
            String singleRange = startEnd.single;
            assert(singleRange.startsWith('U+'));
            int rangeValue = int.parse(singleRange.substring(2), radix: 16);
            fontFaceUnicodeRanges.add(CodeunitRange(rangeValue, rangeValue));
          } else {
            assert(startEnd.length == 2);
            String startRange = startEnd[0];
            String endRange = startEnd[1];
            assert(startRange.startsWith('U+'));
            int startValue = int.parse(startRange.substring(2), radix: 16);
            int endValue = int.parse(endRange, radix: 16);
            fontFaceUnicodeRanges.add(CodeunitRange(startValue, endValue));
          }
        }
      } else if (line == '}') {
        if (fontFaceUrl == null || fontFaceUnicodeRanges == null) {
          printWarning('Unable to parse Google Fonts CSS: $css');
          return null;
        }
        subsets
            .add(_ResolvedNotoSubset(fontFaceUrl, name, fontFaceUnicodeRanges));
        resolvingFontFace = false;
      } else {
        continue;
      }
    }
  }

  if (resolvingFontFace) {
    printWarning('Unable to parse Google Fonts CSS: $css');
    return null;
  }

  Map<_ResolvedNotoSubset, List<CodeunitRange>> rangesMap =
      <_ResolvedNotoSubset, List<CodeunitRange>>{};
  for (_ResolvedNotoSubset subset in subsets) {
    for (CodeunitRange range in subset.ranges) {
      rangesMap.putIfAbsent(subset, () => <CodeunitRange>[]).add(range);
    }
  }

  if (rangesMap.isEmpty) {
    printWarning('Parsed Google Fonts CSS was empty: $css');
    return null;
  }

  IntervalTree<_ResolvedNotoSubset> tree =
      IntervalTree<_ResolvedNotoSubset>.createFromRanges(rangesMap);

  return _ResolvedNotoFont(name, subsets, tree);
}

/// In the case where none of the known Noto Fonts cover a set of code units,
/// try the Symbols and Emoji fonts. We don't know the exact range of code units
/// that are covered by these fonts, so we download them and hope for the best.
Future<void> _registerSymbolsAndEmoji() async {
  final FontFallbackData data = FontFallbackData.instance;
  if (data.registeredSymbolsAndEmoji) {
    return;
  }
  data.registeredSymbolsAndEmoji = true;
  const String symbolsUrl =
      'https://fonts.googleapis.com/css2?family=Noto+Sans+Symbols';
  const String emojiUrl =
      'https://fonts.googleapis.com/css2?family=Noto+Color+Emoji+Compat';

  String symbolsCss =
      await notoDownloadQueue.downloader.downloadAsString(symbolsUrl);
  String emojiCss =
      await notoDownloadQueue.downloader.downloadAsString(emojiUrl);

  String? extractUrlFromCss(String css) {
    for (final String line in LineSplitter.split(css)) {
      if (line.startsWith('  src:')) {
        int urlStart = line.indexOf('url(');
        if (urlStart == -1) {
          printWarning('Unable to resolve Noto font URL: $line');
          return null;
        }
        int urlEnd = line.indexOf(')');
        return line.substring(urlStart + 4, urlEnd);
      }
    }
    printWarning('Unable to determine URL for Noto font');
    return null;
  }

  String? symbolsFontUrl = extractUrlFromCss(symbolsCss);
  String? emojiFontUrl = extractUrlFromCss(emojiCss);

  if (symbolsFontUrl != null) {
    notoDownloadQueue.add(_ResolvedNotoSubset(
        symbolsFontUrl, 'Noto Sans Symbols', const <CodeunitRange>[]));
  } else {
    printWarning('Error parsing CSS for Noto Symbols font.');
  }

  if (emojiFontUrl != null) {
    notoDownloadQueue.add(_ResolvedNotoSubset(
        emojiFontUrl, 'Noto Color Emoji Compat', const <CodeunitRange>[]));
  } else {
    printWarning('Error parsing CSS for Noto Emoji font.');
  }
}

/// Finds the minimum set of fonts which covers all of the [codeUnits].
///
/// Removes all code units covered by [fonts] from [codeUnits]. The code
/// units remaining in the [codeUnits] set after calling this function do not
/// have a font that covers them and can be omitted next time to avoid
/// searching for fonts unnecessarily.
///
/// Since set cover is NP-complete, we approximate using a greedy algorithm
/// which finds the font which covers the most code units. If multiple CJK
/// fonts match the same number of code units, we choose one based on the user's
/// locale.
Set<NotoFont> findMinimumFontsForCodeUnits(
    Set<int> codeUnits, Set<NotoFont> fonts) {
  assert(fonts.isNotEmpty || codeUnits.isEmpty);
  Set<NotoFont> minimumFonts = <NotoFont>{};
  List<NotoFont> bestFonts = <NotoFont>[];

  String language = html.window.navigator.language;

  while (codeUnits.isNotEmpty) {
    int maxCodeUnitsCovered = 0;
    bestFonts.clear();
    for (var font in fonts) {
      int codeUnitsCovered = 0;
      for (int codeUnit in codeUnits) {
        if (font.resolvedFont?.tree.containsDeep(codeUnit) == true) {
          codeUnitsCovered++;
        }
      }
      if (codeUnitsCovered > maxCodeUnitsCovered) {
        bestFonts.clear();
        bestFonts.add(font);
        maxCodeUnitsCovered = codeUnitsCovered;
      } else if (codeUnitsCovered == maxCodeUnitsCovered) {
        bestFonts.add(font);
      }
    }
    if (maxCodeUnitsCovered == 0) {
      // Fonts cannot cover remaining unmatched characters.
      break;
    }
    // If the list of best fonts are all CJK fonts, choose the best one based
    // on locale. Otherwise just choose the first font.
    NotoFont bestFont = bestFonts.first;
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
    codeUnits.removeWhere((codeUnit) {
      return bestFont.resolvedFont!.tree.containsDeep(codeUnit);
    });
    minimumFonts.addAll(bestFonts);
  }
  return minimumFonts;
}

class NotoFont {
  final String name;
  final List<CodeunitRange> approximateUnicodeRanges;

  Completer<void>? _decodingCompleter;
  _ResolvedNotoFont? resolvedFont;

  NotoFont(this.name, this.approximateUnicodeRanges);

  String get googleFontsCssUrl =>
      'https://fonts.googleapis.com/css2?family=${name.replaceAll(' ', '+')}';

  Future<void> ensureResolved() async {
    if (resolvedFont == null) {
      if (_decodingCompleter == null) {
        _decodingCompleter = Completer<void>();
        String googleFontCss = await notoDownloadQueue.downloader
            .downloadAsString(googleFontsCssUrl);
        final _ResolvedNotoFont? googleFont =
            _makeResolvedNotoFontFromCss(googleFontCss, name);
        resolvedFont = googleFont;
        _decodingCompleter!.complete();
      } else {
        await _decodingCompleter!.future;
      }
    }
  }

  void reset() {
    resolvedFont = null;
    _decodingCompleter = null;
  }
}

class CodeunitRange {
  final int start;
  final int end;

  const CodeunitRange(this.start, this.end);

  bool contains(int codeUnit) {
    return start <= codeUnit && codeUnit <= end;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! CodeunitRange) {
      return false;
    }
    CodeunitRange range = other;
    return range.start == start && range.end == end;
  }

  @override
  int get hashCode => ui.hashValues(start, end);

  @override
  String toString() => '[$start, $end]';
}

class _ResolvedNotoFont {
  final String name;
  final List<_ResolvedNotoSubset> subsets;
  final IntervalTree<_ResolvedNotoSubset> tree;

  const _ResolvedNotoFont(this.name, this.subsets, this.tree);
}

class _ResolvedNotoSubset {
  final String url;
  final String family;
  final List<CodeunitRange> ranges;

  _ResolvedNotoSubset(this.url, this.family, this.ranges);

  @override
  String toString() => '_ResolvedNotoSubset($family, $url)';
}

NotoFont _notoSansSC = NotoFont('Noto Sans SC', <CodeunitRange>[
  CodeunitRange(12288, 12591),
  CodeunitRange(12800, 13311),
  CodeunitRange(19968, 40959),
  CodeunitRange(65072, 65135),
  CodeunitRange(65280, 65519),
]);

NotoFont _notoSansTC = NotoFont('Noto Sans TC', <CodeunitRange>[
  CodeunitRange(12288, 12351),
  CodeunitRange(12549, 12585),
  CodeunitRange(19968, 40959),
]);

NotoFont _notoSansHK = NotoFont('Noto Sans HK', <CodeunitRange>[
  CodeunitRange(12288, 12351),
  CodeunitRange(12549, 12585),
  CodeunitRange(19968, 40959),
]);

NotoFont _notoSansJP = NotoFont('Noto Sans JP', <CodeunitRange>[
  CodeunitRange(12288, 12543),
  CodeunitRange(19968, 40959),
  CodeunitRange(65280, 65519),
]);

List<NotoFont> _cjkFonts = <NotoFont>[
  _notoSansSC,
  _notoSansTC,
  _notoSansHK,
  _notoSansJP,
];

List<NotoFont> _notoFonts = <NotoFont>[
  _notoSansSC,
  _notoSansTC,
  _notoSansHK,
  _notoSansJP,
  NotoFont('Noto Naskh Arabic UI', <CodeunitRange>[
    CodeunitRange(1536, 1791),
    CodeunitRange(8204, 8206),
    CodeunitRange(8208, 8209),
    CodeunitRange(8271, 8271),
    CodeunitRange(11841, 11841),
    CodeunitRange(64336, 65023),
    CodeunitRange(65132, 65276),
  ]),
  NotoFont('Noto Sans Armenian', <CodeunitRange>[
    CodeunitRange(1328, 1424),
    CodeunitRange(64275, 64279),
  ]),
  NotoFont('Noto Sans Bengali UI', <CodeunitRange>[
    CodeunitRange(2404, 2405),
    CodeunitRange(2433, 2555),
    CodeunitRange(8204, 8205),
    CodeunitRange(8377, 8377),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Myanmar UI', <CodeunitRange>[
    CodeunitRange(4096, 4255),
    CodeunitRange(8204, 8205),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Egyptian Hieroglyphs', <CodeunitRange>[
    CodeunitRange(77824, 78894),
  ]),
  NotoFont('Noto Sans Ethiopic', <CodeunitRange>[
    CodeunitRange(4608, 5017),
    CodeunitRange(11648, 11742),
    CodeunitRange(43777, 43822),
  ]),
  NotoFont('Noto Sans Georgian', <CodeunitRange>[
    CodeunitRange(1417, 1417),
    CodeunitRange(4256, 4351),
    CodeunitRange(11520, 11567),
  ]),
  NotoFont('Noto Sans Gujarati UI', <CodeunitRange>[
    CodeunitRange(2404, 2405),
    CodeunitRange(2688, 2815),
    CodeunitRange(8204, 8205),
    CodeunitRange(8377, 8377),
    CodeunitRange(9676, 9676),
    CodeunitRange(43056, 43065),
  ]),
  NotoFont('Noto Sans Gurmukhi UI', <CodeunitRange>[
    CodeunitRange(2404, 2405),
    CodeunitRange(2561, 2677),
    CodeunitRange(8204, 8205),
    CodeunitRange(8377, 8377),
    CodeunitRange(9676, 9676),
    CodeunitRange(9772, 9772),
    CodeunitRange(43056, 43065),
  ]),
  NotoFont('Noto Sans Hebrew', <CodeunitRange>[
    CodeunitRange(1424, 1535),
    CodeunitRange(8362, 8362),
    CodeunitRange(9676, 9676),
    CodeunitRange(64285, 64335),
  ]),
  NotoFont('Noto Sans Devanagari UI', <CodeunitRange>[
    CodeunitRange(2304, 2431),
    CodeunitRange(7376, 7414),
    CodeunitRange(7416, 7417),
    CodeunitRange(8204, 8205),
    CodeunitRange(8360, 8360),
    CodeunitRange(8377, 8377),
    CodeunitRange(9676, 9676),
    CodeunitRange(43056, 43065),
    CodeunitRange(43232, 43259),
  ]),
  NotoFont('Noto Sans Kannada UI', <CodeunitRange>[
    CodeunitRange(2404, 2405),
    CodeunitRange(3202, 3314),
    CodeunitRange(8204, 8205),
    CodeunitRange(8377, 8377),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Khmer UI', <CodeunitRange>[
    CodeunitRange(6016, 6143),
    CodeunitRange(8204, 8204),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans KR', <CodeunitRange>[
    CodeunitRange(12593, 12686),
    CodeunitRange(12800, 12828),
    CodeunitRange(12896, 12923),
    CodeunitRange(44032, 55215),
  ]),
  NotoFont('Noto Sans Lao UI', <CodeunitRange>[
    CodeunitRange(3713, 3807),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Malayalam UI', <CodeunitRange>[
    CodeunitRange(775, 775),
    CodeunitRange(803, 803),
    CodeunitRange(2404, 2405),
    CodeunitRange(3330, 3455),
    CodeunitRange(8204, 8205),
    CodeunitRange(8377, 8377),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Sinhala', <CodeunitRange>[
    CodeunitRange(2404, 2405),
    CodeunitRange(3458, 3572),
    CodeunitRange(8204, 8205),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Tamil UI', <CodeunitRange>[
    CodeunitRange(2404, 2405),
    CodeunitRange(2946, 3066),
    CodeunitRange(8204, 8205),
    CodeunitRange(8377, 8377),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Telugu UI', <CodeunitRange>[
    CodeunitRange(2385, 2386),
    CodeunitRange(2404, 2405),
    CodeunitRange(3072, 3199),
    CodeunitRange(7386, 7386),
    CodeunitRange(8204, 8205),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans Thai UI', <CodeunitRange>[
    CodeunitRange(3585, 3675),
    CodeunitRange(8204, 8205),
    CodeunitRange(9676, 9676),
  ]),
  NotoFont('Noto Sans', <CodeunitRange>[
    CodeunitRange(0, 255),
    CodeunitRange(305, 305),
    CodeunitRange(338, 339),
    CodeunitRange(699, 700),
    CodeunitRange(710, 710),
    CodeunitRange(730, 730),
    CodeunitRange(732, 732),
    CodeunitRange(8192, 8303),
    CodeunitRange(8308, 8308),
    CodeunitRange(8364, 8364),
    CodeunitRange(8482, 8482),
    CodeunitRange(8593, 8593),
    CodeunitRange(8595, 8595),
    CodeunitRange(8722, 8722),
    CodeunitRange(8725, 8725),
    CodeunitRange(65279, 65279),
    CodeunitRange(65533, 65533),
    CodeunitRange(1024, 1119),
    CodeunitRange(1168, 1169),
    CodeunitRange(1200, 1201),
    CodeunitRange(8470, 8470),
    CodeunitRange(1120, 1327),
    CodeunitRange(7296, 7304),
    CodeunitRange(8372, 8372),
    CodeunitRange(11744, 11775),
    CodeunitRange(42560, 42655),
    CodeunitRange(65070, 65071),
    CodeunitRange(880, 1023),
    CodeunitRange(7936, 8191),
    CodeunitRange(256, 591),
    CodeunitRange(601, 601),
    CodeunitRange(7680, 7935),
    CodeunitRange(8224, 8224),
    CodeunitRange(8352, 8363),
    CodeunitRange(8365, 8399),
    CodeunitRange(8467, 8467),
    CodeunitRange(11360, 11391),
    CodeunitRange(42784, 43007),
    CodeunitRange(258, 259),
    CodeunitRange(272, 273),
    CodeunitRange(296, 297),
    CodeunitRange(360, 361),
    CodeunitRange(416, 417),
    CodeunitRange(431, 432),
    CodeunitRange(7840, 7929),
    CodeunitRange(8363, 8363),
  ]),
];

class FallbackFontDownloadQueue {
  NotoDownloader downloader = NotoDownloader();

  final Set<_ResolvedNotoSubset> downloadedSubsets = <_ResolvedNotoSubset>{};
  final Map<String, _ResolvedNotoSubset> pendingSubsets =
      <String, _ResolvedNotoSubset>{};

  bool get isPending => pendingSubsets.isNotEmpty || _fontsLoading != null;

  Future<void>? _fontsLoading;
  bool get debugIsLoadingFonts => _fontsLoading != null;

  Future<void> debugWhenIdle() async {
    if (assertionsEnabled) {
      await Future<void>.delayed(Duration.zero);
      while (isPending) {
        if (_fontsLoading != null) {
          await _fontsLoading;
        }
        if (pendingSubsets.isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          if (pendingSubsets.isEmpty) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }
      }
    } else {
      throw UnimplementedError();
    }
  }

  void add(_ResolvedNotoSubset subset) {
    if (downloadedSubsets.contains(subset) ||
        pendingSubsets.containsKey(subset.url)) {
      return;
    }
    bool firstInBatch = pendingSubsets.isEmpty;
    pendingSubsets[subset.url] = subset;
    if (firstInBatch) {
      Timer.run(startDownloads);
    }
  }

  Future<void> startDownloads() async {
    final Map<String, Future<void>> downloads = <String, Future<void>>{};
    final Map<String, Uint8List> downloadedData = <String, Uint8List>{};
    for (_ResolvedNotoSubset subset in pendingSubsets.values) {
      downloads[subset.url] = Future<void>(() async {
        ByteBuffer buffer;
        try {
          buffer = await downloader.downloadAsBytes(subset.url,
              debugDescription: subset.family);
        } catch (e) {
          pendingSubsets.remove(subset.url);
          printWarning('Failed to load font ${subset.family} at ${subset.url}');
          printWarning(e.toString());
          return;
        }
        downloadedSubsets.add(subset);
        downloadedData[subset.url] = buffer.asUint8List();
      });
    }

    await Future.wait<void>(downloads.values);

    // Register fallback fonts in a predictable order. Otherwise, the fonts
    // change their precedence depending on the download order causing
    // visual differences between app reloads.
    final List<String> downloadOrder =
        (downloadedData.keys.toList()..sort()).reversed.toList();
    for (String url in downloadOrder) {
      final _ResolvedNotoSubset subset = pendingSubsets.remove(url)!;
      final Uint8List bytes = downloadedData[url]!;
      FontFallbackData.instance.registerFallbackFont(subset.family, bytes);
      if (pendingSubsets.isEmpty) {
        _fontsLoading = skiaFontCollection.ensureFontsLoaded();
        try {
          await _fontsLoading;
        } finally {
          _fontsLoading = null;
        }
        sendFontChangeMessage();
      }
    }

    if (pendingSubsets.isNotEmpty) {
      await startDownloads();
    }
  }
}

class NotoDownloader {
  int get debugActiveDownloadCount => _debugActiveDownloadCount;
  int _debugActiveDownloadCount = 0;

  /// Returns a future that resolves when there are no pending downloads.
  ///
  /// Useful in tests to make sure that fonts are loaded before working with
  /// text.
  Future<void> debugWhenIdle() async {
    if (assertionsEnabled) {
      // Some downloads begin asynchronously in a microtask or in a Timer.run.
      // Let those run before waiting for downloads to finish.
      await Future<void>.delayed(Duration.zero);
      while (_debugActiveDownloadCount > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        // If we started with a non-zero count and hit zero while waiting, wait a
        // little more to make sure another download doesn't get chained after
        // the last one (e.g. font file download after font CSS download).
        if (_debugActiveDownloadCount == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    } else {
      throw UnimplementedError();
    }
  }

  /// Downloads the [url] and returns it as a [ByteBuffer].
  ///
  /// Override this for testing.
  Future<ByteBuffer> downloadAsBytes(String url, {String? debugDescription}) {
    if (assertionsEnabled) {
      _debugActiveDownloadCount += 1;
    }
    final Future<ByteBuffer> result = html.window.fetch(url).then(
        (dynamic fetchResult) => fetchResult
            .arrayBuffer()
            .then<ByteBuffer>((dynamic x) => x as ByteBuffer));
    if (assertionsEnabled) {
      result.whenComplete(() {
        _debugActiveDownloadCount -= 1;
      });
    }
    return result;
  }

  /// Downloads the [url] and returns is as a [String].
  ///
  /// Override this for testing.
  Future<String> downloadAsString(String url, {String? debugDescription}) {
    if (assertionsEnabled) {
      _debugActiveDownloadCount += 1;
    }
    final Future<String> result = html.window.fetch(url).then(
        (dynamic response) =>
            response.text().then<String>((dynamic x) => x as String));
    if (assertionsEnabled) {
      result.whenComplete(() {
        _debugActiveDownloadCount -= 1;
      });
    }
    return result;
  }
}

FallbackFontDownloadQueue notoDownloadQueue = FallbackFontDownloadQueue();
